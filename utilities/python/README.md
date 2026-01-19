# Python Utilities

This directory contains Python-related utility scripts to enhance your workflow.

## Contents
- [Background Remover](#background-remover)
- [Image Background Overlay Processor](#image-background-overlay-processor)
- [MTranServer Model Downloader](#mtranserver-model-downloader)

## Background Remover

`background_remover.py` is a versatile Python script designed to automate background removal from images using the Bria API. It supports both local image files and URL-based images, with configurable batch processing capabilities.

### Features
- **Multiple Processing Modes**: Process single URL images, URL lists from text files, single local images, or entire folders of images.
- **Concurrent Processing**: Configurable multi-threading for efficient batch processing.
- **Interactive Mode**: User-friendly command-line interface for guided operation.
- **Non-Interactive Mode**: Direct command-line arguments for automation and scripting.
- **Flexible Output Options**: Customizable output paths and file naming.
- **Overwrite Control**: Option to skip or overwrite existing processed files.
- **Comprehensive Logging**: Detailed progress and error reporting.

### Requirements
- Python 3.x installed on your system
- `requests` library (`pip install requests`)
- Bria API Token (obtain from https://platform.bria.ai/console)

### Usage

#### Command-Line Mode
Process images directly using command-line arguments:

```bash
# Process a single URL image
python background_remover.py --api_token YOUR_API_TOKEN --url https://example.com/image.jpg --output_path ./output

# Process images from a URL text file
python background_remover.py --api_token YOUR_API_TOKEN --url_file ./urls.txt --output_path ./output

# Process a single local image
python background_remover.py --api_token YOUR_API_TOKEN --file ./image.jpg

# Batch process a folder of images
python background_remover.py --api_token YOUR_API_TOKEN --batch_folder ./images --max_workers 8 --overwrite
```

#### Interactive Mode
Run the script without arguments for an interactive guided experience:

```bash
python background_remover.py
```

#### Remote Execution
Execute the script directly from the repository without downloading:

```bash
# Interactive mode (Linux/MacOS)
python3 <(curl -s https://gitee.com/funnyzak/dotfiles/raw/main/utilities/python/bria/background_remover.py)

# Command-line mode
python3 <(curl -s https://gitee.com/funnyzak/dotfiles/raw/main/utilities/python/bria/background_remover.py) --api_token YOUR_API_TOKEN --url https://example.com/image.jpg --output_path ./output
```

### Options
- **`--api_token, -t`**: Bria API Token (required)
- **`--output_path, -o`**: Output directory path (required for URL processing)
- **`--batch_folder, -b`**: Directory containing images to process
- **`--url_file, -u`**: Text file containing image URLs (one per line)
- **`--overwrite, -w`**: Overwrite existing processed files
- **`--max_workers, -m`**: Maximum number of concurrent processing threads (default: 4)
- **`--url`**: Single image URL to process
- **`--file, -f`**: Single local image file to process

### Installation
1. **Install Python Dependencies**:
   ```bash
   pip install requests
   ```

2. **Download the Script**:
   Place `background_remover.py` in a directory of your choice:
   ```bash
   curl -o background_remover.py https://gitee.com/funnyzak/dotfiles/raw/main/utilities/python/bria/background_remover.py
   chmod +x background_remover.py
   ```

3. **Verify**:
   Test the script:
   ```bash
   python background_remover.py --help
   ```

### Example Workflow
1. Obtain a Bria API Token from https://platform.bria.ai/console
2. Prepare your images (local files or URLs)
3. Run the script in your preferred mode:
   ```bash
   # For a folder of images
   python background_remover.py --api_token YOUR_API_TOKEN --batch_folder ./my_images --max_workers 4
   ```

### Notes
- **Supported Image Formats**: JPG, JPEG, PNG, WEBP, BMP, GIF, TIFF
- **Output Format**: All processed images are saved in PNG format with transparent backgrounds
- **Naming Convention**: Processed files are saved with an "_rmbg" suffix
- **API Limitations**: Be aware of any rate limits or quotas associated with your Bria API Token
- **Large Batches**: For very large batches, consider adjusting the `max_workers` parameter based on your system's capabilities

## Image Background Overlay Processor

`image-background-overlay-processor.py` is a versatile utility for overlaying foreground images onto background images with intelligent scaling, centering, and margin adjustments. It supports batch processing, remote URLs, and customizable output formats.

### Features
- **Multiple Processing Modes**: Process single images or batch process multiple images
- **Flexible Image Sources**: Support for local files and remote URLs
- **Customizable Output**: Control image size, padding, and stretching options
- **Multi-threaded Processing**: Efficient batch processing with progress tracking
- **Interactive Mode**: User-friendly command-line interface
- **Library Usage**: Can be imported and used programmatically

### Requirements
- Python 3.x
- Required packages (automatically installed if missing):
  - Pillow (PIL)
  - requests
  - tqdm
  - rich

### Usage

#### Command-Line Mode
Process images directly using command-line arguments:

```bash
# Process a single image
python image-background-overlay-processor.py --foreground image.jpg --background bg.jpg --output result.jpg

# Batch process images from a directory
python image-background-overlay-processor.py --batch --foreground-dir images/ --background bg.jpg --output-dir results/

# Process images from a URL list
python image-background-overlay-processor.py --batch --url-list urls.txt --background bg.jpg --output-dir results/

# With custom settings
python image-background-overlay-processor.py --foreground image.jpg --background bg.jpg --output result.jpg --padding "5%" --stretch --quality 90
```

#### Interactive Mode
Run the script in interactive mode for a guided experience:

```bash
python image-background-overlay-processor.py --interactive
```

#### As a Library
Import and use programmatically in your Python code:

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

### Options
- **`--foreground`**: Path or URL to foreground image
- **`--background`**: Path or URL to background image
- **`--output`**: Output file path for single image processing
- **`--batch`**: Enable batch processing mode
- **`--foreground-dir`**: Directory containing foreground images
- **`--url-list`**: File containing list of image URLs (one per line)
- **`--output-dir`**: Directory for saving processed images
- **`--output-pattern`**: Pattern for output filenames (default: "{original_name}_processed")
- **`--padding`**: Padding around foreground image (e.g., "10px" or "5%")
- **`--stretch`**: Stretch small foreground images to fill available area
- **`--width`**, **`--height`**: Custom output dimensions in pixels
- **`--quality`**: Output image quality (1-100, JPEG only)
- **`--recursive`**: Process subdirectories recursively
- **`--max-workers`**: Maximum number of concurrent processing threads
- **`--verbose`**: Enable detailed logging

### Output Files
- Supports common image formats: JPG, JPEG, PNG, GIF, BMP, TIFF
- Format is determined by the output file extension
- For JPEG output, alpha channels are automatically converted to RGB
- Maintains transparency for PNG and other formats that support it
- File naming follows the specified pattern or defaults to "{original_name}_processed"

### Example Workflows

#### Wedding Photo Processing
```bash
# Add a decorative frame to all wedding photos
python image-background-overlay-processor.py --batch --foreground-dir wedding_photos/ --background fancy_frame.png --output-dir framed_photos/ --padding "3%" --quality 95
```

#### Product Catalog Images
```bash
# Place product images on a consistent branded background
python image-background-overlay-processor.py --batch --url-list product_urls.txt --background brand_background.jpg --output-dir catalog/ --width 800 --height 800 --stretch
```

#### Profile Picture Standardization
```bash
# Standardize team profile pictures with consistent background
python image-background-overlay-processor.py --batch --foreground-dir team_photos/ --background company_bg.png --output-dir standardized/ --padding "10px" --output-pattern "team_{original_name}"
```

### Notes
- For batch processing of large image collections, adjust `max-workers` based on your system capabilities
- When using percentage-based padding, the percentage is relative to the smallest dimension of the background image
- For JPEG output files, transparency is automatically converted to solid background
- The processor automatically handles aspect ratio preservation by default
- When using URLs, ensure proper internet connectivity and be mindful of image download sizes

## MTranServer Model Downloader

`download_models.py` is a utility for downloading MTranServer translation model files from Mozilla Firefox Translation Services. It supports both command-line arguments and interactive mode, with automatic file verification, decompression, and retry mechanisms.

### Features
- **Automatic Record Fetching**: Retrieves the latest model records from Mozilla CDN
- **Architecture Filtering**: Support for base-memory, base, and tiny architectures
- **SHA256 Verification**: Validates both compressed and decompressed files
- **Resume & Retry**: Automatic retry mechanism for failed downloads
- **Concurrent Downloads**: Multi-threaded downloading with configurable workers
- **Progress Display**: Visual progress bar (requires tqdm)
- **Smart Skip**: Automatically skips already downloaded and verified files

### Requirements
- Python 3.x
- Decompression support (one of the following):
  - `zstandard` library: `pip install zstandard` (recommended)
  - System command: `brew install zstd` (macOS) / `apt install zstd` (Linux)
- Optional: `tqdm` for progress bar display: `pip install tqdm`

### Usage

#### Command-Line Mode
Download models directly using command-line arguments:

```bash
# Download models with default settings (base-memory architecture)
python download_models.py --model-dir ./models

# Specify architecture type
python download_models.py --model-dir ./models --arch-filter base

# Use 8 concurrent threads for faster downloads
python download_models.py --model-dir ./models --workers 8

# Download tiny architecture (smallest size)
python download_models.py --model-dir ./models --arch-filter tiny
```

#### Interactive Mode
Run the script without arguments or with `-i` flag for a guided experience:

```bash
python download_models.py
python download_models.py -i
```

#### Remote Execution
Execute the script directly without downloading:

```bash
# Interactive mode (Linux/macOS)
python3 <(curl -s https://cdn.jsdelivr.net/gh/funnyzak/dotfiles@main/utilities/python/mtran-server/download_models.py)

# Command-line mode
python3 <(curl -s https://cdn.jsdelivr.net/gh/funnyzak/dotfiles@main/utilities/python/mtran-server/download_models.py) --model-dir ./models --arch-filter base-memory
```

### Options
- **`--model-dir, -m`**: Model storage directory (default: ./models)
- **`--arch-filter, -a`**: Architecture filter (base-memory/base/tiny, default: base-memory)
- **`--workers, -w`**: Number of concurrent download threads (default: 4)
- **`-i, --interactive`**: Use interactive mode

### Architecture Types
| Architecture | Description |
|--------------|-------------|
| `base-memory` | Memory-optimized version (default, recommended for amd64 servers) |
| `base` | Standard version (balanced performance and resource usage) |
| `tiny` | Compact version (smallest size, suitable for resource-limited environments) |

### Example Workflow
1. Ensure Python 3.x is installed
2. Install decompression support:
   ```bash
   pip install zstandard tqdm
   ```
3. Run the downloader:
   ```bash
   # Download all base-memory models with 8 threads
   python download_models.py --model-dir ./models --arch-filter base-memory --workers 8
   ```
4. Models will be organized by language pair (e.g., `en_cs/`, `en_de/`)

### Notes
- **File Organization**: Models are stored in subdirectories named by language pair (source_target)
- **Verification**: Files are verified using SHA256 checksums before and after decompression
- **Incremental Downloads**: Already downloaded and verified files are automatically skipped
- **Cleanup**: Compressed `.zst` files are automatically removed after successful decompression
- **Network**: Requires internet access to Mozilla CDN servers
- **MTranServer**: For more information, visit https://github.com/xxnuo/MTranServer
