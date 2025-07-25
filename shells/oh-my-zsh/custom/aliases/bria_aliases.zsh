# Description: Bria AI image editing API aliases for image processing and manipulation.

# Common helper functions for Bria API operations
_bria_check_token() {
  if [ -z "$BRIA_TOKEN" ]; then
    echo "Error: BRIA_TOKEN environment variable is not set" >&2
    echo "Please set it by running: export BRIA_TOKEN=\"your_api_token\"" >&2
    return 1
  fi
  return 0
}

# Common function to handle API errors
_bria_handle_error() {
  local status_code=$1
  case $status_code in
    400) echo "Error: Bad request - check your parameters" >&2 ;;
    401) echo "Error: Unauthorized - check your API token" >&2 ;;
    404) echo "Error: Not found - the requested resource doesn't exist" >&2 ;;
    413) echo "Error: Payload too large - file size exceeds the limit" >&2 ;;
    415) echo "Error: Unsupported media type - only JPEG and PNG files in RGB, RGBA, or CMYK color modes are supported" >&2 ;;
    422) echo "Error: Unprocessable entity - invalid parameters" >&2 ;;
    429) echo "Error: Too many requests - rate limit exceeded" >&2 ;;
    460) echo "Error: Content moderation failed" >&2 ;;
    500) echo "Error: Internal server error" >&2 ;;
    *) echo "Error: Unknown error (status code: $status_code)" >&2 ;;
  esac
  return 1
}

_bria_check_dependencies() {
  # Check if required commands are available
  for cmd in curl jq; do
    if ! command -v $cmd &> /dev/null; then
      echo "Error: $cmd is not installed. Please install it to use this script." >&2
      return 1
    fi
  done
  return 0
}

# Function to process an image URL or file and download the result
_bria_process_and_download() {
  local endpoint=$1
  local input=$2
  local output=$3
  local api_url="https://engine.prod.bria-api.com/v1/$endpoint"
  local response=""
  local result_url=""

  echo "Processing image: $input"

  # Check if input is URL or local file
  if [[ $input == http* ]]; then
    # Use URL
    # If output not specified, use default
    if [ -z "$output" ]; then
      output="./output.png"
    fi

    response=$(curl -s -X POST "$api_url" \
      -H "api_token: $BRIA_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"image_url\":\"$input\"}")

  else
    # Use local file
    if [ ! -f "$input" ]; then
      echo "Error: File not found: $input" >&2
      return 1
    fi

    # Get file directory, name and extension for output path
    local filename=$(basename "$input")
    local dirname=$(dirname "$input")
    local name="${filename%.*}"
    local ext="${filename##*.}"

    # If output not specified, generate default output path
    if [ -z "$output" ]; then
      output="$dirname/${name}_${endpoint/\//_}.$ext"
    fi

    # Get content type based on file extension
    local content_type="image/jpeg"
    if [[ "$ext" == "png" ]]; then
      content_type="image/png"
    fi

    response=$(curl -s -X POST "$api_url" \
      -H "api_token: $BRIA_TOKEN" \
      -F "file=@$input;type=$content_type")
  fi

  # Extract result_url from JSON response
  result_url=$(echo "$response" | jq -r ".result_url")

  if [ -z "$result_url" ]; then
    echo "Error: Failed to get result URL from API response" >&2
    echo "Response: $response" >&2
    return 1
  fi

  # Download the result image
  if curl -s "$result_url" -o "$output"; then
    echo "Image processed successfully. Output saved to: $output"
    return 0
  else
    echo "Error: Failed to download result image" >&2
    return 1
  fi
}

# Function to validate aspect ratio parameter
_bria_validate_aspect_ratio() {
  local aspect_ratio=$1
  
  # Check if it's a predefined ratio
  case "$aspect_ratio" in
    "1:1"|"2:3"|"3:2"|"3:4"|"4:3"|"4:5"|"5:4"|"9:16"|"16:9")
      return 0
      ;;
    *)
      # Check if it's a custom float between 0.5 and 3.0
      if [[ "$aspect_ratio" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        # Use bc for floating point comparison if available, otherwise use awk
        if command -v bc &> /dev/null; then
          if (( $(echo "$aspect_ratio >= 0.5 && $aspect_ratio <= 3.0" | bc -l) )); then
            return 0
          fi
        else
          if awk "BEGIN {exit !($aspect_ratio >= 0.5 && $aspect_ratio <= 3.0)}"; then
            return 0
          fi
        fi
      fi
      return 1
      ;;
  esac
}

# Function to generate output filename with aspect ratio information
_bria_generate_output_filename() {
  local input_url_or_path=$1
  local aspect_ratio=$2
  local output_dir=${3:-"./"}
  
  # Extract filename from URL or file path
  local filename=$(basename "$input_url_or_path")
  local name="${filename%.*}"
  
  # Convert aspect ratio to filename-safe format
  local ratio_suffix=""
  if [[ "$aspect_ratio" == *":"* ]]; then
    # Handle ratio like "2:3" -> "2x3"
    ratio_suffix="${aspect_ratio//:/x}"
  else
    # Handle float like "1.5" -> "1.5x"
    ratio_suffix="${aspect_ratio}x"
  fi
  
  # Generate output filename with aspect ratio info
  echo "${output_dir}/${name}_${ratio_suffix}.png"
}

# Background Operations
# -------------------

alias bria-bg-remove='() {
  echo -e "Remove background from an image.\nUsage:\n bria-bg-remove <image_path_or_url> [output_path]\n\nExamples:\n bria-bg-remove photo.jpg\n -> Creates photo_background_remove.jpg with transparent background\n\n bria-bg-remove https://example.com/image.png output.png\n -> Downloads image, removes background and saves as output.png\n"

  if [ -z "$1" ]; then
    echo "Error: Missing required parameter - image path or URL" >&2
    return 1
  fi

  _bria_check_token || return 1
  _bria_check_dependencies || return 1

  _bria_process_and_download "background/remove" "$1" "$2"
}' # Remove background from image

alias bria-batch-bg-remove='() {
  echo -e "Remove background from multiple images in a directory.\nUsage:\n bria-batch-bg-remove <directory_path> [file_extension:jpg]\n\nExamples:\n bria-batch-bg-remove ./photos jpg\n -> Removes background from all jpg files in ./photos directory\n -> Saves results in ./photos/bg_removed/ directory\n\n bria-batch-bg-remove ./product_images png\n -> Processes all png files in ./product_images directory"

  if [ -z "$1" ]; then
    echo "Error: Missing required parameter - directory path" >&2
    return 1
  fi

  local dir_path="$1"
  local file_ext="${2:-jpg}"

  if [ ! -d "$dir_path" ]; then
    echo "Error: Directory not found: $dir_path" >&2
    return 1
  fi

  _bria_check_token || return 1
  _bria_check_dependencies || return 1

  # Check if files exist
  local file_count=$(find "$dir_path" -maxdepth 1 -type f -name "*.${file_ext}" | wc -l)
  if [ "$file_count" -eq 0 ]; then
    echo "Error: No ${file_ext} files found in $dir_path" >&2
    return 1
  fi

  # Create output directory
  local output_dir="$dir_path/bg_removed"
  mkdir -p "$output_dir"

  local processed=0
  local errors=0

  echo "Processing $file_count files from $dir_path..."

  for img in "$dir_path"/*.$file_ext; do
    if [ ! -f "$img" ]; then
      continue
    fi

    local filename=$(basename "$img")
    local output_path="$output_dir/${filename%.*}_nobg.png"

    echo "Processing $filename..."

    if _bria_process_and_download "background/remove" "$img" "$output_path"; then
      processed=$((processed+1))
    else
      errors=$((errors+1))
    fi
  done

  echo "Batch processing complete: $processed files processed successfully, $errors errors"
  if [ "$errors" -gt 0 ]; then
    return 1
  fi
  return 0
}' # Remove background from multiple images in a directory

alias bria-bg-replace='() {
  echo -e "Replace image background with a generated one.\nUsage:\n bria-bg-replace <image_path_or_url> [output_path] [\"prompt:nature scene\"]\n\nExamples:\n bria-bg-replace portrait.jpg\n -> Replaces background with default nature scene, saves as portrait_bg_replaced.jpg\n\n bria-bg-replace photo.png new_photo.png \"city skyline at night\"\n -> Replaces background with city skyline, saves as new_photo.png\n"

  if [ -z "$1" ]; then
    echo "Error: Missing required parameter - image path or URL" >&2
    return 1
  fi

  local input=$1
  local output=$2
  local prompt=${3:-"nature scene"}
  local api_url="https://engine.prod.bria-api.com/v1/background/replace"
  local response=""
  local result_url=""

  _bria_check_token || return 1
  _bria_check_dependencies || return 1

  echo "Processing image: $input with prompt: $prompt"

  # Check if input is URL or local file
  if [[ $input == http* ]]; then
    # Use URL
    # If output not specified, use default
    if [ -z "$output" ]; then
      output="./output_bg_replaced.png"
    fi

    response=$(curl -s -X POST "$api_url" \
      -H "api_token: $BRIA_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"image_url\":\"$input\", \"prompt\":\"$prompt\"}")

  else
    # Use local file
    if [ ! -f "$input" ]; then
      echo "Error: File not found: $input" >&2
      return 1
    fi

    # Generate default output path if not specified
    if [ -z "$output" ]; then
      local filename=$(basename "$input")
      local dirname=$(dirname "$input")
      local name="${filename%.*}"
      local ext="${filename##*.}"
      output="$dirname/${name}_bg_replaced.$ext"
    fi

    # Get content type based on file extension
    local content_type="image/jpeg"
    if [[ "${input##*.}" == "png" ]]; then
      content_type="image/png"
    fi

    response=$(curl -s -X POST "$api_url" \
      -H "api_token: $BRIA_TOKEN" \
      -F "file=@$input;type=$content_type" \
      -F "prompt=$prompt")
  fi

  # Extract result_url from JSON response
  result_url=$(echo "$response" | jq -r ".result_url")

  if [ -z "$result_url" ]; then
    echo "Error: Failed to get result URL from API response" >&2
    echo "Response: $response" >&2
    return 1
  fi

  # Download the result image
  if curl -s "$result_url" -o "$output"; then
    echo "Background replaced successfully. Output saved to: $output"
    return 0
  else
    echo "Error: Failed to download result image" >&2
    return 1
  fi
}' # Replace background with generated content

alias bria-bg-blur='() {
  echo -e "Blur background in an image.\nUsage:\n bria-bg-blur <image_path_or_url> [output_path]\n\nExamples:\n bria-bg-blur portrait.jpg\n -> Blurs the background while preserving the subject, saves as portrait_background_blur.jpg\n\n bria-bg-blur https://example.com/photo.png blurred.png\n -> Downloads image, blurs background and saves as blurred.png\n"

  if [ -z "$1" ]; then
    echo "Error: Missing required parameter - image path or URL" >&2
    return 1
  fi

  _bria_check_token || return 1
  _bria_check_dependencies || return 1
  _bria_process_and_download "background/blur" "$1" "$2"
}' # Blur image background

alias bria-erase-fg='() {
  echo -e "Erase foreground from an image.\nUsage:\n bria-erase-fg <image_path_or_url> [output_path]\n\nExamples:\n bria-erase-fg scene.jpg\n -> Removes foreground objects, saves as scene_erase_foreground.jpg\n\n bria-erase-fg photo.png bg_only.png\n -> Erases foreground objects and saves just the background as bg_only.png\n"

  if [ -z "$1" ]; then
    echo "Error: Missing required parameter - image path or URL" >&2
    return 1
  fi

  _bria_check_token || return 1
  _bria_check_dependencies || return 1
  _bria_process_and_download "erase_foreground" "$1" "$2"
}' # Erase foreground from image

# Image Editing Operations
# -----------------------

alias bria-eraser='() {
  echo -e "Erase parts of an image (requires mask).\nUsage:\n bria-eraser <image_path_or_url> <mask_path_or_url> [output_path]\n\nExamples:\n bria-eraser photo.jpg mask.png\n -> Erases areas defined by white regions in mask.png from photo.jpg\n -> Saves result as photo_erased.jpg\n\n bria-eraser https://example.com/image.jpg https://example.com/mask.png result.jpg\n -> Downloads image and mask, applies erasure, saves as result.jpg\n"

  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Error: Missing required parameters - image path/URL and mask path/URL" >&2
    return 1
  fi

  local input=$1
  local mask=$2
  local output=$3
  local api_url="https://engine.prod.bria-api.com/v1/eraser"
  local response=""
  local result_url=""

  _bria_check_token || return 1
  _bria_check_dependencies || return 1

  echo "Processing image: $input with mask: $mask"

  # Check if input is URL or local file
  if [[ $input == http* ]] && [[ $mask == http* ]]; then
    # Both are URLs
    if [ -z "$output" ]; then
      output="./output_eraser.png"
    fi

    response=$(curl -s -X POST "$api_url" \
      -H "api_token: $BRIA_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"image_url\":\"$input\", \"mask_url\":\"$mask\"}")

  elif [[ $input != http* ]] && [[ $mask != http* ]]; then
    # Both are local files
    if [ ! -f "$input" ]; then
      echo "Error: Image file not found: $input" >&2
      return 1
    fi

    if [ ! -f "$mask" ]; then
      echo "Error: Mask file not found: $mask" >&2
      return 1
    fi

    # Generate default output path if not specified
    if [ -z "$output" ]; then
      local filename=$(basename "$input")
      local dirname=$(dirname "$input")
      local name="${filename%.*}"
      local ext="${filename##*.}"
      output="$dirname/${name}_erased.$ext"
    fi

    # Get content type based on file extension
    local image_content_type="image/jpeg"
    local mask_content_type="image/png"

    if [[ "${input##*.}" == "png" ]]; then
      image_content_type="image/png"
    fi

    if [[ "${mask##*.}" == "jpeg" ]] || [[ "${mask##*.}" == "jpg" ]]; then
      mask_content_type="image/jpeg"
    fi

    response=$(curl -s -X POST "$api_url" \
      -H "api_token: $BRIA_TOKEN" \
      -F "file=@$input;type=$image_content_type" \
      -F "mask=@$mask;type=$mask_content_type")
  else
    echo "Error: Both inputs must be of the same type (URLs or local files)" >&2
    return 1
  fi

  # Extract result_url from JSON response
  result_url=$(echo "$response" | jq -r ".result_url")

  if [ -z "$result_url" ]; then
    echo "Error: Failed to get result URL from API response" >&2
    echo "Response: $response" >&2
    return 1
  fi

  # Download the result image
  if curl -s "$result_url" -o "$output"; then
    echo "Image erased successfully. Output saved to: $output"
    return 0
  else
    echo "Error: Failed to download result image" >&2
    return 1
  fi
}' # Erase parts of image using mask

alias bria-gen-fill='() {
  echo -e "Fill masked area with generated content.\nUsage:\n bria-gen-fill <image_path_or_url> <mask_path_or_url> [output_path] [\"prompt:matching content\"]\n\nExamples:\n bria-gen-fill photo.jpg mask.png\n -> Fills areas defined by white regions in mask.png with AI-generated content\n -> Saves result as photo_gen_fill.jpg\n\n bria-gen-fill photo.png mask.png output.png \"mountains and sky\"\n -> Fills masked areas with generated mountains and sky content\n -> Saves as output.png\n"

  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Error: Missing required parameters - image path/URL and mask path/URL" >&2
    return 1
  fi

  local input=$1
  local mask=$2
  local output=$3
  local prompt=${4:-"matching content"}
  local api_url="https://engine.prod.bria-api.com/v1/gen_fill"
  local response=""
  local result_url=""

  _bria_check_token || return 1
  _bria_check_dependencies || return 1

  echo "Processing image: $input with mask: $mask and prompt: $prompt"

  # Check if input is URL or local file
  if [[ $input == http* ]] && [[ $mask == http* ]]; then
    # Both are URLs
    if [ -z "$output" ]; then
      output="./output_gen_fill.png"
    fi

    response=$(curl -s -X POST "$api_url" \
      -H "api_token: $BRIA_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"image_url\":\"$input\", \"mask_url\":\"$mask\", \"prompt\":\"$prompt\"}")

  elif [[ $input != http* ]] && [[ $mask != http* ]]; then
    # Both are local files
    if [ ! -f "$input" ]; then
      echo "Error: Image file not found: $input" >&2
      return 1
    fi

    if [ ! -f "$mask" ]; then
      echo "Error: Mask file not found: $mask" >&2
      return 1
    fi

    # Generate default output path if not specified
    if [ -z "$output" ]; then
      local filename=$(basename "$input")
      local dirname=$(dirname "$input")
      local name="${filename%.*}"
      local ext="${filename##*.}"
      output="$dirname/${name}_gen_fill.$ext"
    fi

    # Get content type based on file extension
    local image_content_type="image/jpeg"
    local mask_content_type="image/png"

    if [[ "${input##*.}" == "png" ]]; then
      image_content_type="image/png"
    fi

    if [[ "${mask##*.}" == "jpeg" ]] || [[ "${mask##*.}" == "jpg" ]]; then
      mask_content_type="image/jpeg"
    fi

    response=$(curl -s -X POST "$api_url" \
      -H "api_token: $BRIA_TOKEN" \
      -F "file=@$input;type=$image_content_type" \
      -F "mask=@$mask;type=$mask_content_type" \
      -F "prompt=$prompt")
  else
    echo "Error: Both inputs must be of the same type (URLs or local files)" >&2
    return 1
  fi

  # Extract result_url from JSON response
  result_url=$(echo "$response" | jq -r ".result_url")

  if [ -z "$result_url" ]; then
    echo "Error: Failed to get result URL from API response" >&2
    echo "Response: $response" >&2
    return 1
  fi

  # Download the result image
  if curl -s "$result_url" -o "$output"; then
    echo "Image filled successfully. Output saved to: $output"
    return 0
  else
    echo "Error: Failed to download result image" >&2
    return 1
  fi
}' # Fill masked area with generated content

# Image Enhancement Operations
# --------------------------

alias bria-expand-img='() {
  echo -e "Expand image canvas with AI generated content by aspect ratio.\nUsage:\n bria-expand-img <image_path_or_url> [aspect_ratio:16:9] [output_path]\n\nExamples:\n bria-expand-img portrait.jpg 2:3\n -> Expands portrait.jpg to 2:3 aspect ratio with AI generated content around the edges\n -> Saves as portrait_2x3.png\n\n bria-expand-img photo.png 1:1 square.png\n -> Expands photo.png to square (1:1) aspect ratio\n -> Saves as square.png\n\n bria-expand-img https://example.com/image.jpg 1.5\n -> Expands image using custom ratio 1.5 (between 0.5 and 3.0)\n -> Saves as image_1.5x.png\n\nSupported aspect ratios:\n - Predefined: \"1:1\", \"2:3\", \"3:2\", \"3:4\", \"4:3\", \"4:5\", \"5:4\", \"9:16\", \"16:9\"\n - Custom float: between 0.5 and 3.0\n"

  if [ -z "$1" ]; then
    echo "Error: Missing required parameter - image path or URL" >&2
    return 1
  fi

  local input=$1
  local aspect_ratio=${2:-"16:9"}
  local output=$3
  local api_url="https://engine.prod.bria-api.com/v1/image_expansion"
  local response=""
  local result_url=""

  _bria_check_token || return 1
  _bria_check_dependencies || return 1

  # Validate aspect ratio
  if ! _bria_validate_aspect_ratio "$aspect_ratio"; then
    echo "Error: Invalid aspect ratio: $aspect_ratio" >&2
    echo "Supported ratios: \"1:1\", \"2:3\", \"3:2\", \"3:4\", \"4:3\", \"4:5\", \"5:4\", \"9:16\", \"16:9\" or custom float between 0.5 and 3.0" >&2
    return 1
  fi

  echo "Expanding image: $input to aspect ratio: $aspect_ratio"

  # Check if input is URL or local file
  if [[ $input == http* ]]; then
    # Use URL
    # If output not specified, use default with aspect ratio info
    if [ -z "$output" ]; then
      output=$(_bria_generate_output_filename "$input" "$aspect_ratio" "./")
    fi

    response=$(curl -s -X POST "$api_url" \
      -H "api_token: $BRIA_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"image_url\":\"$input\", \"aspect_ratio\":\"$aspect_ratio\"}")

  else
    # Use local file
    if [ ! -f "$input" ]; then
      echo "Error: File not found: $input" >&2
      return 1
    fi

    # Generate default output path if not specified
    if [ -z "$output" ]; then
      local dirname=$(dirname "$input")
      output=$(_bria_generate_output_filename "$input" "$aspect_ratio" "$dirname")
    fi

    # Get content type based on file extension
    local content_type="image/jpeg"
    if [[ "${input##*.}" == "png" ]]; then
      content_type="image/png"
    fi

    response=$(curl -s -X POST "$api_url" \
      -H "api_token: $BRIA_TOKEN" \
      -F "file=@$input;type=$content_type" \
      -F "aspect_ratio=$aspect_ratio")
  fi

  # Extract result_url from JSON response
  result_url=$(echo "$response" | jq -r ".result_url")

  if [ -z "$result_url" ]; then
    echo "Error: Failed to get result URL from API response" >&2
    echo "Response: $response" >&2
    return 1
  fi

  # Download the result image
  if curl -s "$result_url" -o "$output"; then
    echo "Image expanded successfully. Output saved to: $output"
    return 0
  else
    echo "Error: Failed to download result image" >&2
    return 1
  fi
}' # Expand image canvas with AI generated content by aspect ratio

alias bria-batch-expand-img='() {
  echo -e "Expand multiple images from URLs with AI generated content by aspect ratio.\nUsage:\n bria-batch-expand-img <urls_file> [aspect_ratio:16:9] [output_directory:./expanded]\n\nExamples:\n bria-batch-expand-img image_urls.txt 2:3\n -> Expands all images from URLs in image_urls.txt to 2:3 aspect ratio\n -> Saves results like image1_2x3.png, image2_2x3.png in ./expanded/ directory\n\n bria-batch-expand-img urls.txt 1:1 ./results\n -> Expands all images from URLs in urls.txt to square (1:1) aspect ratio\n -> Saves results like photo_1x1.png in ./results/ directory\n\nURL file format:\n Each line should contain one image URL:\n https://example.com/image1.jpg\n https://example.com/image2.png\n https://example.com/image3.jpg\n\nSupported aspect ratios:\n - Predefined: \"1:1\", \"2:3\", \"3:2\", \"3:4\", \"4:3\", \"4:5\", \"5:4\", \"9:16\", \"16:9\"\n - Custom float: between 0.5 and 3.0\n"

  if [ -z "$1" ]; then
    echo "Error: Missing required parameter - URLs file path" >&2
    return 1
  fi

  local urls_file="$1"
  local aspect_ratio="${2:-16:9}"
  local output_dir="${3:-./expanded}"

  if [ ! -f "$urls_file" ]; then
    echo "Error: URLs file not found: $urls_file" >&2
    return 1
  fi

  _bria_check_token || return 1
  _bria_check_dependencies || return 1

  # Validate aspect ratio
  if ! _bria_validate_aspect_ratio "$aspect_ratio"; then
    echo "Error: Invalid aspect ratio: $aspect_ratio" >&2
    echo "Supported ratios: \"1:1\", \"2:3\", \"3:2\", \"3:4\", \"4:3\", \"4:5\", \"5:4\", \"9:16\", \"16:9\" or custom float between 0.5 and 3.0" >&2
    return 1
  fi

  # Count URLs in file (excluding empty lines and comments)
  local url_count=$(grep -v "^#" "$urls_file" | grep -v "^$" | wc -l)
  if [ "$url_count" -eq 0 ]; then
    echo "Error: No valid URLs found in $urls_file" >&2
    return 1
  fi

  # Create output directory
  mkdir -p "$output_dir"

  local processed=0
  local errors=0
  local line_number=0

  echo "Processing $url_count URLs from $urls_file with aspect ratio: $aspect_ratio..."

  # Process each URL
  while IFS= read -r image_url; do
    line_number=$((line_number + 1))
    
    # Skip empty lines and comments
    if [[ -z "$image_url" ]] || [[ "$image_url" =~ ^#.* ]]; then
      continue
    fi

    # Validate URL format
    if ! [[ "$image_url" =~ ^https?:// ]]; then
      echo "✗ Line $line_number: Invalid URL format: $image_url" >&2
      errors=$((errors + 1))
      continue
    fi

    # Generate output filename from URL with aspect ratio info
    local output_path=$(_bria_generate_output_filename "$image_url" "$aspect_ratio" "$output_dir")

    echo "Processing URL $processed/$url_count: $image_url"

    # Call Bria API
    local api_url="https://engine.prod.bria-api.com/v1/image_expansion"
    local response=""
    local result_url=""

    response=$(curl -s -X POST "$api_url" \
      -H "api_token: $BRIA_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"image_url\":\"$image_url\", \"aspect_ratio\":\"$aspect_ratio\"}")

    # Extract result_url from JSON response
    result_url=$(echo "$response" | jq -r ".result_url")

    if [ -z "$result_url" ] || [ "$result_url" = "null" ]; then
      echo "✗ Failed to get result URL for $image_url" >&2
      echo "Response: $response" >&2
      errors=$((errors + 1))
      continue
    fi

    # Download the result image
    if curl -s "$result_url" -o "$output_path"; then
      echo "✓ $filename expanded successfully -> $output_path"
      processed=$((processed + 1))
    else
      echo "✗ Failed to download result for $image_url" >&2
      errors=$((errors + 1))
    fi
  done < "$urls_file"

  echo "Batch processing complete: $processed images processed successfully, $errors errors"
  if [ "$errors" -gt 0 ]; then
    return 1
  fi
  return 0
}' # Expand multiple images from URLs with AI generated content by aspect ratio

alias bria-increase-res='() {
  echo -e "Increase image resolution.\nUsage:\n bria-increase-res <image_path_or_url> [scale_factor:2] [output_path]\n\nExamples:\n bria-increase-res photo.jpg\n -> Doubles the resolution of photo.jpg using AI upscaling\n -> Saves as photo_upscaled.jpg\n\n bria-increase-res image.png 4 highres.png\n -> Increases resolution by 4x\n -> Saves as highres.png\n"

  if [ -z "$1" ]; then
    echo "Error: Missing required parameter - image path or URL" >&2
    return 1
  fi

  local input=$1
  local scale=${2:-2}
  local output=$3
  local api_url="https://engine.prod.bria-api.com/v1/image/increase_resolution"
  local response=""
  local result_url=""

  _bria_check_token || return 1
  _bria_check_dependencies || return 1

  # Validate scale factor (must be a positive number)
  if ! [[ "$scale" =~ ^[0-9]+(\.[0-9]+)?$ ]] || (( $(echo "$scale <= 0" | bc -l) )); then
    echo "Error: Scale factor must be a positive number" >&2
    return 1
  fi

  echo "Increasing resolution of image: $input with scale factor: $scale"

  # Check if input is URL or local file
  if [[ $input == http* ]]; then
    # Use URL
    # If output not specified, use default
    if [ -z "$output" ]; then
      output="./output_upscaled.png"
    fi

    response=$(curl -s -X POST "$api_url?desired_increase=$scale" \
      -H "api_token: $BRIA_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"image_url\":\"$input\"}")

  else
    # Use local file
    if [ ! -f "$input" ]; then
      echo "Error: File not found: $input" >&2
      return 1
    fi

    # Generate default output path if not specified
    if [ -z "$output" ]; then
      local filename=$(basename "$input")
      local dirname=$(dirname "$input")
      local name="${filename%.*}"
      local ext="${filename##*.}"
      output="$dirname/${name}_upscaled.$ext"
    fi

    # Get content type based on file extension
    local content_type="image/jpeg"
    if [[ "${input##*.}" == "png" ]]; then
      content_type="image/png"
    fi

    response=$(curl -s -X POST "$api_url?desired_increase=$scale" \
      -H "api_token: $BRIA_TOKEN" \
      -F "file=@$input;type=$content_type")
  fi

  # Extract result_url from JSON response
  result_url=$(echo "$response" | jq -r ".result_url")

  if [ -z "$result_url" ]; then
    echo "Error: Failed to get result URL from API response" >&2
    echo "Response: $response" >&2
    return 1
  fi

  # Download the result image
  if curl -s "$result_url" -o "$output"; then
    echo "Image resolution increased successfully. Output saved to: $output"
    return 0
  else
    echo "Error: Failed to download result image" >&2
    return 1
  fi
}' # Increase image resolution

# Advanced Image Processing Operations
# -------------------------------

alias bria-auto-crop='() {
  echo -e "Automatically crop image with AI.\nUsage:\n bria-auto-crop <image_path_or_url> [output_path]\n\nExamples:\n bria-auto-crop photo.jpg\n -> Intelligently identifies the best composition and crops the image\n -> Saves as photo_crop.jpg\n\n bria-auto-crop https://example.com/image.png cropped.png\n -> Downloads image, intelligently crops it and saves as cropped.png\n"

  if [ -z "$1" ]; then
    echo "Error: Missing required parameter - image path or URL" >&2
    return 1
  fi

  _bria_check_token || return 1
  _bria_check_dependencies || return 1
  _bria_process_and_download "crop" "$1" "$2"
}' # Automatically crop image using AI

alias bria-gen-mask='() {
  echo -e "Generate masks for objects in image.\nUsage:\n bria-gen-mask <image_path_or_url> [output_path]\n\nExamples:\n bria-gen-mask photo.jpg\n -> Identifies all objects in the image and creates individual masks for each\n -> Saves masks as a ZIP file at photo_masks.zip\n\n bria-gen-mask https://example.com/image.jpg objects_masks.zip\n -> Processes the online image and saves object masks to objects_masks.zip\n"

  if [ -z "$1" ]; then
    echo "Error: Missing required parameter - image path or URL" >&2
    return 1
  fi

  _bria_check_token || return 1
  _bria_check_dependencies || return 1

  local input=$1
  local output=$2
  local api_url="https://engine.prod.bria-api.com/v1/objects/mask_generator"
  local response=""
  local result_url=""

  echo "Generating masks for image: $input"

  # Check if input is URL or local file
  if [[ $input == http* ]]; then
    # Use URL
    # If output not specified, use default
    if [ -z "$output" ]; then
      output="./masks.zip"
    fi

    response=$(curl -s -X POST "$api_url" \
      -H "api_token: $BRIA_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"image_url\":\"$input\"}")

  else
    # Use local file
    if [ ! -f "$input" ]; then
      echo "Error: File not found: $input" >&2
      return 1
    fi

    # Generate default output path if not specified
    if [ -z "$output" ]; then
      local filename=$(basename "$input")
      local dirname=$(dirname "$input")
      local name="${filename%.*}"
      output="$dirname/${name}_masks.zip"
    fi

    # Get content type based on file extension
    local content_type="image/jpeg"
    if [[ "${input##*.}" == "png" ]]; then
      content_type="image/png"
    fi

    response=$(curl -s -X POST "$api_url" \
      -H "api_token: $BRIA_TOKEN" \
      -F "file=@$input;type=$content_type")
  fi

  # Extract result_url from JSON response
  result_url=$(echo "$response" | jq -r ".result_url")

  if [ -z "$result_url" ]; then
    echo "Error: Failed to get result URL from API response" >&2
    echo "Response: $response" >&2
    return 1
  fi

  # Download the result masks zip file
  if curl -s "$result_url" -o "$output"; then
    echo "Masks generated successfully. Output saved to: $output"
    echo "The ZIP file contains individual PNG masks for each detected object."
    return 0
  else
    echo "Error: Failed to download result masks" >&2
    return 1
  fi
}' # Generate masks for objects in image

# Image to PSD Conversion
# ----------------------

alias bria-to-psd='() {
  echo -e "Convert image to PSD file with layers.\nUsage:\n bria-to-psd <image_path_or_url> <visual_id> [output_path]\n\nExamples:\n bria-to-psd photo.jpg 12345\n -> Converts photo.jpg to a PSD file with layers using visual ID 12345\n -> Saves as photo.psd\n\n bria-to-psd https://example.com/image.png 67890 layers.psd\n -> Downloads image, converts to layered PSD and saves as layers.psd\n"

  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Error: Missing required parameters - image path/URL and visual ID" >&2
    return 1
  fi

  local input=$1
  local visual_id=$2
  local output=$3
  local api_url="https://engine.prod.bria-api.com/v1/$visual_id/image_to_psd"
  local response=""
  local result_url=""

  _bria_check_token || return 1
  _bria_check_dependencies || return 1

  echo "Converting image to PSD: $input with visual ID: $visual_id"

  # Default output path if not specified
  if [ -z "$output" ]; then
    if [[ $input == http* ]]; then
      output="./output.psd"
    else
      local filename=$(basename "$input")
      local dirname=$(dirname "$input")
      local name="${filename%.*}"
      output="$dirname/${name}.psd"
    fi
  fi

  # Make API request
  response=$(curl -s -X POST "$api_url" \
    -H "api_token: $BRIA_TOKEN")

  # Extract result_url from JSON response
  result_url=$(echo "$response" | jq -r ".result_url")

  if [ -z "$result_url" ]; then
    echo "Error: Failed to get result URL from API response" >&2
    echo "Response: $response" >&2
    return 1
  fi

  # Download the result PSD file
  if curl -s "$result_url" -o "$output"; then
    echo "Image converted to PSD successfully. Output saved to: $output"
    return 0
  else
    echo "Error: Failed to download result PSD" >&2
    return 1
  fi
}' # Convert image to PSD file with layers

# Video Operations
# ---------------

alias bria-vid-bg-remove='() {
  echo -e "Remove background from a video.\nUsage:\n bria-vid-bg-remove <video_path_or_url> [output_path]\n\nExamples:\n bria-vid-bg-remove https://example.com/video.mp4\n -> Removes background from online video\n -> Saves as output_nobg.webm with transparent background\n\n bria-vid-bg-remove https://example.com/clip.mov transparent_clip.webm\n -> Removes background and saves as transparent_clip.webm\n\nNote: Processing time depends on video length. A 10-second video takes ~5 minutes.\n"

  if [ -z "$1" ]; then
    echo "Error: Missing required parameter - video path or URL" >&2
    return 1
  fi

  local input=$1
  local output=$2
  local api_url="https://engine.prod.bria-api.com/v1/video/background/remove"
  local response=""
  local result_url=""

  _bria_check_token || return 1
  _bria_check_dependencies || return 1

  echo "Processing video: $input (this may take several minutes)"
  echo "Note: A 10-second video typically takes ~5 minutes to process"

  # Check if input is URL or local file
  if [[ $input == http* ]]; then
    # Use URL
    # If output not specified, use default
    if [ -z "$output" ]; then
      output="./output_nobg.webm"
    fi

    response=$(curl -s -X POST "$api_url" \
      -H "api_token: $BRIA_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"video_url\":\"$input\"}")

  else
    # Use local file
    if [ ! -f "$input" ]; then
      echo "Error: File not found: $input" >&2
      return 1
    fi

    # Check file type - supported formats are mp4, avi, mov, gif, webm
    local ext="${input##*.}"
    if ! [[ "$ext" =~ ^(mp4|avi|mov|gif|webm)$ ]]; then
      echo "Error: Unsupported file format: $ext. Supported formats: mp4, avi, mov, gif, webm" >&2
      return 1
    fi

    # Check file size and duration - Input video time limit is up to 1 minute
    local file_size=$(stat -f%z "$input" 2>/dev/null || stat --format="%s" "$input" 2>/dev/null)
    if [ -z "$file_size" ]; then
      echo "Warning: Could not determine file size" >&2
    elif [ "$file_size" -gt 104857600 ]; then # 100MB limit as a rough estimate
      echo "Warning: File size is large ($(echo "scale=2; $file_size/1048576" | bc) MB). Videos should be under 1 minute duration." >&2
    fi

    # Generate default output path if not specified
    if [ -z "$output" ]; then
      local filename=$(basename "$input")
      local dirname=$(dirname "$input")
      local name="${filename%.*}"
      output="$dirname/${name}_nobg.webm"
    fi

    # Get public URL for the video
    echo "Uploading video..."
    # This is a placeholder - in a real implementation you would upload the video to a temporary storage
    # and get a public URL. This might require additional tools/services.
    echo "Error: Local file support requires a method to create a publicly accessible URL for the video" >&2
    echo "Please use a publicly accessible URL directly" >&2
    return 1

    # The following code would be used if we had a way to upload and get a URL
    # response=$(curl -s -X POST "$api_url" \
    #  -H "api_token: $BRIA_TOKEN" \
    #  -H "Content-Type: application/json" \
    #  -d "{\"video_url\":\"$uploaded_url\"}")
  fi

  # Extract result_url from JSON response
  result_url=$(echo "$response" | jq -r ".result_url")

  if [ -z "$result_url" ]; then
    echo "Error: Failed to get result URL from API response" >&2
    echo "Response: $response" >&2
    return 1
  fi

  echo "Video processing started. The background will be removed asynchronously."
  echo "Result will be available at: $result_url"
  echo "To download the result when processing is complete, run:"
  echo "curl -s \"$result_url\" -o \"$output\""

  # Optionally, we could poll the result URL until the video is ready
  # but that might take too long for an interactive shell function

  return 0
}' # Remove background from video

# Help Function
# ------------

alias bria-help='() {
  echo -e "Bria AI Image & Video Editing API Aliases\n======================================"
  echo -e "\nBackground Operations:"
  echo -e "  bria-bg-remove      - Remove background from an image"
  echo -e "  bria-bg-replace     - Replace background with generated content"
  echo -e "  bria-bg-blur        - Blur background in an image"
  echo -e "  bria-erase-fg       - Erase foreground from an image"
  echo -e "  bria-batch-bg-remove - Remove background from multiple images in a directory"

  echo -e "\nImage Editing Operations:"
  echo -e "  bria-eraser         - Erase parts of an image (requires mask)"
  echo -e "  bria-gen-fill       - Fill masked area with generated content"

  echo -e "\nImage Enhancement Operations:"
  echo -e "  bria-expand-img     - Expand image canvas with AI generated content by aspect ratio"
  echo -e "  bria-batch-expand-img - Expand multiple images from URLs with AI generated content by aspect ratio"
  echo -e "  bria-increase-res   - Increase image resolution"

  echo -e "\nAdvanced Image Processing Operations:"
  echo -e "  bria-auto-crop      - Automatically crop image with AI"
  echo -e "  bria-gen-mask       - Generate masks for objects in image"
  echo -e "  bria-to-psd         - Convert image to PSD file with layers"

  echo -e "\nVideo Operations:"
  echo -e "  bria-vid-bg-remove  - Remove background from a video"

  echo -e "\nFor detailed usage of each command, run the command without arguments."
  echo -e "Example: bria-bg-remove"

  echo -e "\nBefore using any command, make sure to set your API token:"
  echo -e "export BRIA_TOKEN=\"your_api_token\""
  echo -e "\nFor more information, visit the official documentation at: https://docs.bria.ai/"
  echo -e "\nNote: Some operations may take time to process, especially for large images or videos."
  echo -e "\nFor detailed usage of each command, run the command without arguments."
  echo -e "Example: bria-bg-remove"
  echo -e "\nBefore using any command, make sure to set your API token:"
  echo -e "export BRIA_TOKEN=\"your_api_token\""
}' # Show help for all Bria aliases
