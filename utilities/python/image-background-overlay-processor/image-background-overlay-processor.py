#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Image Background Overlay Processor (image-background-overlay-processor.py)
===========================================================================

A versatile image processing tool that overlays foreground images onto background images
with intelligent scaling, centering, and margin adjustments.

Features:
- Process single images or batch process multiple images
- Support for local files and remote URLs as image sources
- Customizable output size, padding, and stretching options
- Multi-threaded batch processing with progress tracking
- Flexible output naming and organization
- Interactive command-line interface
- Can be used as a standalone tool or imported as a library

Usage:
------
1. As a command-line tool:
   $ python image-background-overlay-processor.py --foreground path/to/foreground.jpg --background path/to/background.jpg --output output.jpg

2. Batch processing:
   $ python image-background-overlay-processor.py --batch --foreground-dir path/to/foregrounds --background path/to/background.jpg --output-dir path/to/output

3. Interactive mode:
   $ python image-background-overlay-processor.py --interactive

4. As a library:
   ```python
   from image-background-overlay-processor import ImageBackdropProcessor

   processor = ImageBackdropProcessor()
   processor.process(
       foreground="path/to/foreground.jpg",
       background="path/to/background.jpg",
       output="output.jpg",
       padding="5%",
       stretch=False
   )
   ```

For more details and options, run:
$ python image-background-overlay-processor.py --help
"""

import os
import sys
import re
import argparse
import logging
import concurrent.futures
import threading
import time
import urllib.parse
from datetime import datetime
from pathlib import Path
from typing import Union, List, Dict, Tuple, Optional, Any, Callable

try:
    import requests
    from PIL import Image, ImageOps
    from tqdm import tqdm
    from rich.console import Console
    from rich.prompt import Prompt, Confirm
    from rich import print as rich_print
except ImportError:
    print("Required packages not found. Installing dependencies...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install",
                          "pillow", "requests", "tqdm", "rich"])
    import requests
    from PIL import Image, ImageOps
    from tqdm import tqdm
    from rich.console import Console
    from rich.prompt import Prompt, Confirm
    from rich import print as rich_print

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler("image_processor.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("ImageBackdropProcessor")

class ImageSource:
    """Class to handle loading images from various sources (local files or URLs)."""

    @staticmethod
    def is_url(source: str) -> bool:
        """Check if the source is a URL."""
        try:
            result = urllib.parse.urlparse(source)
            return all([result.scheme, result.netloc])
        except ValueError:
            return False

    @staticmethod
    def load_image(source: str) -> Optional[Image.Image]:
        """
        Load an image from a local file path or URL.

        Args:
            source: Path to a local file or a URL to an image

        Returns:
            PIL Image object or None if loading fails
        """
        try:
            if ImageSource.is_url(source):
                logger.info(f"Downloading image from URL: {source}")
                response = requests.get(source, timeout=30, stream=True)
                if response.status_code != 200:
                    logger.error(f"Failed to download image from {source}: HTTP {response.status_code}")
                    return None
                return Image.open(requests.get(source, stream=True).raw)
            else:
                logger.info(f"Loading image from local file: {source}")
                return Image.open(source)
        except Exception as e:
            logger.error(f"Error loading image from {source}: {str(e)}")
            return None

class ImageBackdropProcessor:
    """
    Main processor class that handles combining foreground and background images
    with various customization options.
    """

    def __init__(self, log_level: int = logging.INFO):
        """
        Initialize the processor with optional custom log level.

        Args:
            log_level: Logging level (default: logging.INFO)
        """
        self.logger = logging.getLogger(f"{__name__}.ImageBackdropProcessor")
        self.logger.setLevel(log_level)
        self.console = Console()

    def _parse_size_value(self, value: str, reference_size: int) -> int:
        """
        Parse a size value that can be in pixels or percentage.

        Args:
            value: Size value as string (e.g., "10px" or "5%")
            reference_size: Reference size to calculate percentage values

        Returns:
            Calculated size in pixels
        """
        if not value:
            return 0

        if isinstance(value, int):
            return value

        if isinstance(value, str):
            if value.endswith("px"):
                try:
                    return int(value[:-2])
                except ValueError:
                    self.logger.warning(f"Invalid pixel value: {value}, using 0")
                    return 0

            elif value.endswith("%"):
                try:
                    percentage = float(value[:-1]) / 100.0
                    return int(reference_size * percentage)
                except ValueError:
                    self.logger.warning(f"Invalid percentage value: {value}, using 0")
                    return 0

            else:
                try:
                    return int(value)
                except ValueError:
                    self.logger.warning(f"Invalid size value: {value}, using 0")
                    return 0

        return 0

    def process(self,
                foreground: str,
                background: str,
                output: str,
                output_size: Optional[Tuple[int, int]] = None,
                padding: str = "0px",
                stretch: bool = False,
                quality: int = 95) -> bool:
        """
        Process a single image combination.

        Args:
            foreground: Path or URL to foreground image
            background: Path or URL to background image
            output: Path to save the output image
            output_size: Optional custom output size as (width, height)
            padding: Padding value as pixels or percentage (e.g., "10px" or "5%")
            stretch: Whether to stretch small foreground images
            quality: Output image quality (1-100, JPEG only)

        Returns:
            True if processing was successful, False otherwise
        """
        try:
            # Load images
            fg_img = ImageSource.load_image(foreground)
            bg_img = ImageSource.load_image(background)

            if fg_img is None or bg_img is None:
                return False

            # Convert to RGBA to handle transparency
            if fg_img.mode != "RGBA":
                fg_img = fg_img.convert("RGBA")

            if bg_img.mode != "RGBA":
                bg_img = bg_img.convert("RGBA")

            # Use custom output size or background size
            if output_size:
                bg_width, bg_height = output_size
                # Resize background to match output size
                bg_img = bg_img.resize((bg_width, bg_height), Image.LANCZOS)
            else:
                bg_width, bg_height = bg_img.size

            # Calculate padding
            padding_pixels = self._parse_size_value(padding, min(bg_width, bg_height))

            # Calculate available area for foreground image
            available_width = bg_width - (2 * padding_pixels)
            available_height = bg_height - (2 * padding_pixels)

            if available_width <= 0 or available_height <= 0:
                self.logger.error(f"Padding too large for background image size: {padding}")
                return False

            fg_width, fg_height = fg_img.size

            # Calculate scaling factor
            width_ratio = available_width / fg_width
            height_ratio = available_height / fg_height

            # Determine if we need to scale down (foreground larger than available area)
            needs_scale_down = width_ratio < 1 or height_ratio < 1

            # Determine if we need to scale up (stretch=True and foreground smaller than available area)
            needs_scale_up = stretch and (width_ratio > 1 and height_ratio > 1)

            # Apply scaling if needed
            if needs_scale_down or needs_scale_up:
                # Use the smallest ratio to maintain aspect ratio
                scale_ratio = min(width_ratio, height_ratio)

                new_width = int(fg_width * scale_ratio)
                new_height = int(fg_height * scale_ratio)

                fg_img = fg_img.resize((new_width, new_height), Image.LANCZOS)
                fg_width, fg_height = fg_img.size

            # Calculate position to center the foreground image
            x_position = (bg_width - fg_width) // 2
            y_position = (bg_height - fg_height) // 2

            # Create a new image with the same size as the background
            result = Image.new("RGBA", bg_img.size, (0, 0, 0, 0))

            # Paste the background image
            result.paste(bg_img, (0, 0))

            # Paste the foreground image on top
            result.paste(fg_img, (x_position, y_position), fg_img)

            # Ensure the output directory exists
            output_dir = os.path.dirname(output)
            if output_dir and not os.path.exists(output_dir):
                os.makedirs(output_dir)

            # Save the result
            if result.mode == "RGBA" and output.lower().endswith((".jpg", ".jpeg")):
                # Convert to RGB for JPEG (which doesn't support alpha)
                result = result.convert("RGB")

            result.save(output, quality=quality)
            self.logger.info(f"Successfully saved processed image to: {output}")
            return True

        except Exception as e:
            self.logger.error(f"Error processing images: {str(e)}")
            return False

    def batch_process(self,
                      foreground_sources: List[str],
                      background: str,
                      output_dir: str,
                      output_pattern: str = "{original_name}_processed",
                      output_size: Optional[Tuple[int, int]] = None,
                      padding: str = "0px",
                      stretch: bool = False,
                      quality: int = 95,
                      max_workers: int = None,
                      show_progress: bool = True) -> Dict[str, bool]:
        """
        Process multiple foreground images with the same background.

        Args:
            foreground_sources: List of paths or URLs to foreground images
            background: Path or URL to the background image
            output_dir: Directory to save output images
            output_pattern: Pattern for output filenames
            output_size: Optional custom output size as (width, height)
            padding: Padding value as pixels or percentage
            stretch: Whether to stretch small foreground images
            quality: Output image quality (1-100, JPEG only)
            max_workers: Maximum number of worker threads (None = auto)
            show_progress: Whether to show a progress bar

        Returns:
            Dictionary mapping input sources to processing success status
        """
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)

        results = {}

        # Function to process a single item for use with ThreadPoolExecutor
        def process_item(index: int, fg_source: str) -> Tuple[str, bool]:
            # Extract original filename without extension
            if ImageSource.is_url(fg_source):
                original_name = os.path.basename(urllib.parse.urlparse(fg_source).path)
                original_name = os.path.splitext(original_name)[0]
            else:
                original_name = os.path.splitext(os.path.basename(fg_source))[0]

            # Format the output filename
            output_filename = output_pattern.format(
                original_name=original_name,
                index=index,
                date=datetime.now().strftime("%Y%m%d"),
                time=datetime.now().strftime("%H%M%S")
            )

            # Add extension if not present in pattern
            if not any(output_filename.lower().endswith(ext) for ext in
                      (".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff")):
                if ImageSource.is_url(fg_source):
                    # Get extension from the URL
                    ext = os.path.splitext(urllib.parse.urlparse(fg_source).path)[1]
                    if not ext:
                        ext = ".jpg"  # Default extension
                else:
                    # Get extension from the local file
                    ext = os.path.splitext(fg_source)[1]

                output_filename += ext

            output_path = os.path.join(output_dir, output_filename)

            success = self.process(
                foreground=fg_source,
                background=background,
                output=output_path,
                output_size=output_size,
                padding=padding,
                stretch=stretch,
                quality=quality
            )

            return fg_source, success

        # Set up a ThreadPoolExecutor for parallel processing
        with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
            # Submit all tasks
            future_to_source = {
                executor.submit(process_item, i, source): source
                for i, source in enumerate(foreground_sources)
            }

            # Process results as they complete
            if show_progress:
                with tqdm(total=len(foreground_sources), desc="Processing images") as progress_bar:
                    for future in concurrent.futures.as_completed(future_to_source):
                        source, success = future.result()
                        results[source] = success
                        progress_bar.update(1)
            else:
                for future in concurrent.futures.as_completed(future_to_source):
                    source, success = future.result()
                    results[source] = success

        # Log summary
        successful = sum(1 for success in results.values() if success)
        self.logger.info(f"Batch processing complete: {successful}/{len(results)} images processed successfully")

        return results

    def process_directory(self,
                         foreground_dir: str,
                         background: str,
                         output_dir: str,
                         output_pattern: str = "{original_name}_processed",
                         output_size: Optional[Tuple[int, int]] = None,
                         padding: str = "0px",
                         stretch: bool = False,
                         quality: int = 95,
                         recursive: bool = False,
                         file_extensions: List[str] = None,
                         max_workers: int = None,
                         show_progress: bool = True) -> Dict[str, bool]:
        """
        Process all images in a directory or multiple directories.

        Args:
            foreground_dir: Directory or directories containing foreground images (separated by '|')
            background: Path or URL to the background image
            output_dir: Directory to save output images
            output_pattern: Pattern for output filenames
            output_size: Optional custom output size as (width, height)
            padding: Padding value as pixels or percentage
            stretch: Whether to stretch small foreground images
            quality: Output image quality (1-100, JPEG only)
            recursive: Whether to process subdirectories recursively
            file_extensions: List of file extensions to process (default: common image formats)
            max_workers: Maximum number of worker threads (None = auto)
            show_progress: Whether to show a progress bar

        Returns:
            Dictionary mapping input files to processing success status
        """
        if file_extensions is None:
            file_extensions = [".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff"]

        foreground_sources = []

        # Split directories if multiple are provided (separated by '|')
        directories = [dir.strip() for dir in foreground_dir.split('|') if dir.strip()]

        # Collect all image files from all specified directories
        for directory in directories:
            self.logger.info(f"Processing directory: {directory}")

            # Collect all image files in the directory
            if recursive:
                for root, _, files in os.walk(directory):
                    for file in files:
                        if any(file.lower().endswith(ext) for ext in file_extensions):
                            foreground_sources.append(os.path.join(root, file))
            else:
                # Only process files in the top-level directory
                try:
                    for file in os.listdir(directory):
                        file_path = os.path.join(directory, file)
                        if os.path.isfile(file_path) and any(file.lower().endswith(ext) for ext in file_extensions):
                            foreground_sources.append(file_path)
                except FileNotFoundError:
                    self.logger.error(f"Directory not found: {directory}")
                    continue

        self.logger.info(f"Found {len(foreground_sources)} images to process in {len(directories)} directories")

        return self.batch_process(
            foreground_sources=foreground_sources,
            background=background,
            output_dir=output_dir,
            output_pattern=output_pattern,
            output_size=output_size,
            padding=padding,
            stretch=stretch,
            quality=quality,
            max_workers=max_workers,
            show_progress=show_progress
        )

    def process_url_list(self,
                        url_file: str,
                        background: str,
                        output_dir: str,
                        output_pattern: str = "{original_name}_processed",
                        output_size: Optional[Tuple[int, int]] = None,
                        padding: str = "0px",
                        stretch: bool = False,
                        quality: int = 95,
                        max_workers: int = None,
                        show_progress: bool = True) -> Dict[str, bool]:
        """
        Process images from a list of URLs in a text file.

        Args:
            url_file: Path to a text file containing image URLs (one per line)
            background: Path or URL to the background image
            output_dir: Directory to save output images
            output_pattern: Pattern for output filenames
            output_size: Optional custom output size as (width, height)
            padding: Padding value as pixels or percentage
            stretch: Whether to stretch small foreground images
            quality: Output image quality (1-100, JPEG only)
            max_workers: Maximum number of worker threads (None = auto)
            show_progress: Whether to show a progress bar

        Returns:
            Dictionary mapping input URLs to processing success status
        """
        try:
            with open(url_file, "r") as f:
                urls = [line.strip() for line in f if line.strip()]

            self.logger.info(f"Found {len(urls)} URLs in {url_file}")

            return self.batch_process(
                foreground_sources=urls,
                background=background,
                output_dir=output_dir,
                output_pattern=output_pattern,
                output_size=output_size,
                padding=padding,
                stretch=stretch,
                quality=quality,
                max_workers=max_workers,
                show_progress=show_progress
            )
        except Exception as e:
            self.logger.error(f"Error processing URL list: {str(e)}")
            return {}

class InteractiveProcessor:
    """Class to handle interactive command-line interface for the processor."""

    def __init__(self):
        self.console = Console()
        self.processor = ImageBackdropProcessor()

    def run(self):
        """Run the interactive CLI."""
        self.console.print("[bold green]Image Background Overlay Processor - Interactive Mode[/bold green]")
        self.console.print("Follow the prompts to process your images\n")

        # Ask for processing type
        process_type = Prompt.ask(
            "Select processing type",
            choices=["single", "batch_directory", "batch_url_list"],
            default="single"
        )

        # Common parameters
        background = Prompt.ask("Background image path or URL")
        padding = Prompt.ask("Padding (e.g., '10px' or '5%')", default="0px")
        stretch = Confirm.ask("Stretch small foreground images?", default=False)
        quality = int(Prompt.ask("Output quality (1-100)", default="95"))

        # Custom output size
        use_custom_size = Confirm.ask("Use custom output size?", default=False)
        output_size = None
        if use_custom_size:
            width = int(Prompt.ask("Width in pixels"))
            height = int(Prompt.ask("Height in pixels"))
            output_size = (width, height)

        if process_type == "single":
            foreground = Prompt.ask("Foreground image path or URL")
            output = Prompt.ask("Output file path", default="output.jpg")

            with self.console.status("Processing image..."):
                success = self.processor.process(
                    foreground=foreground,
                    background=background,
                    output=output,
                    output_size=output_size,
                    padding=padding,
                    stretch=stretch,
                    quality=quality
                )

            if success:
                self.console.print(f"[bold green]Success![/bold green] Image saved to: {output}")
            else:
                self.console.print("[bold red]Failed to process image.[/bold red]")

        elif process_type == "batch_directory":
            foreground_dir = Prompt.ask("Directory containing foreground images")
            output_dir = Prompt.ask("Output directory", default="output")
            output_pattern = Prompt.ask("Output filename pattern", default="{original_name}_processed")
            recursive = Confirm.ask("Process subdirectories recursively?", default=False)

            with self.console.status("Processing images..."):
                results = self.processor.process_directory(
                    foreground_dir=foreground_dir,
                    background=background,
                    output_dir=output_dir,
                    output_pattern=output_pattern,
                    output_size=output_size,
                    padding=padding,
                    stretch=stretch,
                    quality=quality,
                    recursive=recursive,
                    show_progress=False
                )

            successful = sum(1 for success in results.values() if success)
            self.console.print(f"[bold green]Batch processing complete![/bold green]")
            self.console.print(f"Successfully processed: {successful}/{len(results)} images")
            self.console.print(f"Output directory: {output_dir}")

        elif process_type == "batch_url_list":
            url_file = Prompt.ask("Path to file containing image URLs")
            output_dir = Prompt.ask("Output directory", default="output")
            output_pattern = Prompt.ask("Output filename pattern", default="{original_name}_processed")

            with self.console.status("Processing images..."):
                results = self.processor.process_url_list(
                    url_file=url_file,
                    background=background,
                    output_dir=output_dir,
                    output_pattern=output_pattern,
                    output_size=output_size,
                    padding=padding,
                    stretch=stretch,
                    quality=quality,
                    show_progress=False
                )

            successful = sum(1 for success in results.values() if success)
            self.console.print(f"[bold green]Batch processing complete![/bold green]")
            self.console.print(f"Successfully processed: {successful}/{len(results)} images")
            self.console.print(f"Output directory: {output_dir}")

def parse_arguments():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description="Image Background Overlay Processor",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Process a single image
  python image-background-overlay-processor.py --foreground image.jpg --background bg.jpg --output result.jpg

  # Batch process a directory
  python image-background-overlay-processor.py --batch --foreground-dir images/ --background bg.jpg --output-dir results/

  # Process images from a URL list
  python image-background-overlay-processor.py --batch --url-list urls.txt --background bg.jpg --output-dir results/

  # Use interactive mode
  python image-background-overlay-processor.py --interactive
        """
    )

    # Main operation mode
    mode_group = parser.add_mutually_exclusive_group(required=True)
    mode_group.add_argument("--interactive", action="store_true", help="Run in interactive mode")
    mode_group.add_argument("--batch", action="store_true", help="Run in batch processing mode")
    mode_group.add_argument("--foreground", help="Path or URL to foreground image (for single image processing)")

    # Batch processing options
    batch_group = parser.add_argument_group("Batch processing options")
    batch_source = batch_group.add_mutually_exclusive_group()
    batch_source.add_argument("--foreground-dir", help="Directory containing foreground images")
    batch_source.add_argument("--url-list", help="File containing list of image URLs")
    batch_group.add_argument("--recursive", action="store_true", help="Process subdirectories recursively")
    batch_group.add_argument("--max-workers", type=int, default=None,
                            help="Maximum number of worker threads (default: auto)")

    # Common options
    parser.add_argument("--background", help="Path or URL to background image")
    parser.add_argument("--output", help="Output file path (for single image processing)")
    parser.add_argument("--output-dir", help="Output directory (for batch processing)")
    parser.add_argument("--output-pattern", default="{original_name}_processed",
                       help="Output filename pattern (default: {original_name}_processed)")
    parser.add_argument("--width", type=int, help="Custom output width in pixels")
    parser.add_argument("--height", type=int, help="Custom output height in pixels")
    parser.add_argument("--padding", default="0px",
                       help="Padding value (e.g., '10px' or '5%', default: 0px)")
    parser.add_argument("--stretch", action="store_true",
                       help="Stretch small foreground images to fill available area")
    parser.add_argument("--quality", type=int, default=95,
                       help="Output image quality (1-100, JPEG only, default: 95)")
    parser.add_argument("--verbose", action="store_true", help="Enable verbose logging")

    return parser.parse_args()

def main():
    """Main entry point for the script."""
    args = parse_arguments()

    # Set up logging level
    if args.verbose:
        logger.setLevel(logging.DEBUG)

    # Create processor
    processor = ImageBackdropProcessor(log_level=logging.DEBUG if args.verbose else logging.INFO)

    # Determine output size if specified
    output_size = None
    if args.width and args.height:
        output_size = (args.width, args.height)

    # Interactive mode
    if args.interactive:
        interactive = InteractiveProcessor()
        interactive.run()
        return

    # Check required arguments based on mode
    if args.batch:
        if not (args.foreground_dir or args.url_list):
            logger.error("Batch processing requires --foreground-dir or --url-list")
            return

        if not args.background:
            logger.error("Background image is required (--background)")
            return

        if not args.output_dir:
            logger.error("Output directory is required for batch processing (--output-dir)")
            return

        # Process from directory
        if args.foreground_dir:
            results = processor.process_directory(
                foreground_dir=args.foreground_dir,
                background=args.background,
                output_dir=args.output_dir,
                output_pattern=args.output_pattern,
                output_size=output_size,
                padding=args.padding,
                stretch=args.stretch,
                quality=args.quality,
                recursive=args.recursive,
                max_workers=args.max_workers
            )

            successful = sum(1 for success in results.values() if success)
            print(f"Batch processing complete: {successful}/{len(results)} images processed successfully")

        # Process from URL list
        elif args.url_list:
            results = processor.process_url_list(
                url_file=args.url_list,
                background=args.background,
                output_dir=args.output_dir,
                output_pattern=args.output_pattern,
                output_size=output_size,
                padding=args.padding,
                stretch=args.stretch,
                quality=args.quality,
                max_workers=args.max_workers
            )

            successful = sum(1 for success in results.values() if success)
            print(f"Batch processing complete: {successful}/{len(results)} images processed successfully")

    # Single image processing mode
    else:
        if not args.foreground or not args.background or not args.output:
            logger.error("Single image processing requires --foreground, --background, and --output")
            return

        success = processor.process(
            foreground=args.foreground,
            background=args.background,
            output=args.output,
            output_size=output_size,
            padding=args.padding,
            stretch=args.stretch,
            quality=args.quality
        )

        if success:
            print(f"Image successfully processed and saved to: {args.output}")
        else:
            print("Failed to process image")

if __name__ == "__main__":
    main()
