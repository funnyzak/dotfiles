# Python Utilities

This directory contains Python-related utility scripts to enhance your workflow.

## Contents
- [Background Remover](#background-remover)

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
python3 <(curl -s https://raw.gitcode.com/funnyzak/dotfiles/raw/main/utilities/python/bria/background_remover.py)

# Command-line mode
python3 <(curl -s https://raw.gitcode.com/funnyzak/dotfiles/raw/main/utilities/python/bria/background_remover.py) --api_token YOUR_API_TOKEN --url https://example.com/image.jpg --output_path ./output
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
   curl -o background_remover.py https://raw.gitcode.com/funnyzak/dotfiles/raw/main/utilities/python/bria/background_remover.py
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