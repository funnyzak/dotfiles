# Description: Bria AI image editing API aliases for image processing and manipulation.

# Check if BRIA_TOKEN environment variable is set
alias bria_check='() {
  if [ -z "$BRIA_TOKEN" ]; then
    echo "Error: BRIA_TOKEN environment variable is not set"
    echo "Please set it by running: export BRIA_TOKEN=\"your_api_token"
    return 1
  fi
  echo "Bria API token is configured"
  return 0
}' # Check Bria API token configuration

# Common function to handle API errors
bria_handle_error() {
  local status_code=$1
  case $status_code in
    400) echo "Error: Bad request - check your parameters" ;;
    401) echo "Error: Unauthorized - check your API token" ;;
    404) echo "Error: Not found - the requested resource doesn't exist" ;;
    413) echo "Error: Payload too large - file size exceeds the limit" ;;
    415) echo "Error: Unsupported media type - only JPEG and PNG files in RGB, RGBA, or CMYK color modes are supported" ;;
    422) echo "Error: Unprocessable entity - invalid parameters" ;;
    429) echo "Error: Too many requests - rate limit exceeded" ;;
    460) echo "Error: Content moderation failed" ;;
    500) echo "Error: Internal server error" ;;
    *) echo "Error: Unknown error (status code: $status_code)" ;;
  esac
}

# Remove background from an image
alias bria_rmbg='() {
  bria_check || return 1

  if [ $# -eq 0 ]; then
    echo "Remove background from an image.\nUsage:\n bria_rmbg <image_path_or_url> [output_path]"
    echo "Options:"
    echo "  image_path_or_url: Path to local image file or URL of the image"
    echo "  output_path: Optional path to save the output image (default: [input_dir]/[filename]_rmbg.[ext] for local files or ./output.png for URLs)"
    return 1
  fi

  local input=$1
  local output=$2
  local url="https://engine.prod.bria-api.com/v1/background/remove"

  echo "Removing background from image: $input"

  # Check if input is URL or local file
  if [[ $input == http* ]]; then
    # Use URL
    # If output not specified, use default
    if [ -z "$output" ]; then
      output="./output.png"
    fi

    local response=$(curl -s -X POST "$url" \
      -H "api_token: $BRIA_TOKEN" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      --data "image_url=$input")

    # Extract result_url from JSON response
    local result_url=$(echo "$response" | jq -r ".result_url")

    if [ -z "$result_url" ] || [[ "$result_url" == "null" ]]; then
      echo "Error: Failed to get result URL from API response"
      echo "Response: $response"
      return 1
    fi

    # Download the result image
    curl -s "$result_url" -o "$output" && \
    echo "Background removed successfully. Output saved to: $output"
  else
    # Use local file
    if [ ! -f "$input" ]; then
      echo "Error: File not found: $input"
      return 1
    fi

    # Get file directory, name and extension for output path
    local filename=$(basename "$input")
    local dirname=$(dirname "$input")
    local name="${filename%.*}"
    local ext="${filename##*.}"

    # If output not specified, generate default output path
    if [ -z "$output" ]; then
      output="$dirname/${name}_rmbg.$ext"
    fi

    # Get content type based on file extension
    local content_type="image/jpeg"
    if [[ "$ext" == "png" ]]; then
      content_type="image/png"
    fi

    local response=$(curl -s -X POST "$url" \
      -H "api_token: $BRIA_TOKEN" \
      -F "file=@$input;type=$content_type")

    # Extract result_url from JSON response
    local result_url=$(echo "$response" | jq -r ".result_url")

    if [ -z "$result_url" ] || [[ "$result_url" == "null" ]]; then
      echo "Error: Failed to get result URL from API response"
      echo "Response: $response"
      return 1
    fi

    # Download the result image
    curl -s "$result_url" -o "$output" && \
    echo "Background removed successfully. Output saved to: $output"
  fi
}' # Remove background from an image

# Remove backgrounds from a list of image URLs
alias bria_rmbg_list='() {
  bria_check || return 1

  if [ $# -lt 2 ]; then
    echo "Remove background from a list of image URLs.\nUsage:\n bria_rmbg_list <url_list_file> <output_dir>"
    echo "Options:"
    echo "  url_list_file: Path to a text file containing image URLs (one per line)"
    echo "  output_dir: Directory to save the processed images"
    return 1
  fi

  local url_file=$1
  local output_dir=$2

  if [ ! -f "$url_file" ]; then
    echo "Error: URL list file not found: $url_file"
    return 1
  fi

  # Create output directory if it doesnt exist
  mkdir -p "$output_dir"

  echo "Processing images from URL list: $url_file"
  echo "Saving results to: $output_dir"

  # Process each URL in the file
  local count=0
  local success=0
  local line_num=0

  while IFS= read -r img_url || [ -n "$img_url" ]; do
    # Skip empty lines
    if [ -z "$img_url" ]; then
      continue
    fi

    ((line_num++))

    # Skip lines that start with # (comments)
    if [[ "$img_url" == \#* ]]; then
      continue
    fi

    local filename=$(basename "$img_url")
    # If filename extraction failed or is empty, use a generic name
    if [ -z "$filename" ] || [ "$filename" = "$img_url" ]; then
      filename="image_${line_num}.png"
    fi

    local output="$output_dir/$filename"

    echo "Processing ($((++count))): $img_url"
    bria_rmbg "$img_url" "$output" && ((success++))
  done < "$url_file"

  echo "Batch processing complete. Processed $count URLs, $success successful."
}' # Remove backgrounds from a list of image URLs

# Batch remove background from all images in a directory
alias bria_rmbg_dir='() {
  bria_check || return 1

  if [ $# -eq 0 ]; then
    echo "Remove background from all images in a directory.\nUsage:\n bria_rmbg_dir <input_dir> [output_dir]"
    echo "Options:"
    echo "  input_dir: Directory containing images to process"
    echo "  output_dir: Optional directory to save output images (default: [input_dir]/rmbg_output)"
    return 1
  fi

  local input_dir=$1
  local output_dir=${2:-"$input_dir/rmbg_output"}

  if [ ! -d "$input_dir" ]; then
    echo "Error: Directory not found: $input_dir"
    return 1
  fi

  # Create output directory if it doesnt exist
  mkdir -p "$output_dir"

  echo "Processing all images in: $input_dir"
  echo "Saving results to: $output_dir"

  # Find all image files and process them
  local count=0
  local success=0

  find "$input_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | while read -r img; do
    # Skip if no matches found (when no files with the extensions exist)
    if [ ! -f "$img" ]; then
      continue
    fi

    local filename=$(basename "$img")
    local name="${filename%.*}"
    local ext="${filename##*.}"
    local output="$output_dir/${name}_rmbg.$ext"

    echo "Processing ($((++count))): $filename"
    bria_rmbg "$img" "$output" && ((success++))
  done

  echo "Batch processing complete. Processed $count images, $success successful."
}' # Batch remove background from all images in a directory

# Remote execution of Bria background remover
alias bria_bgremover='() {
  bria_check || return 1

  if [ $# -eq 0 ]; then
    echo "Remote execution of Bria background removal tool."
    echo "\nUsage:"
    echo "  bria_bgremover [options]"
    echo "\nOptions:"
    echo "  --interactive, -i      : Run in interactive mode"
    echo "  --url URL              : Process a single URL"
    echo "  --file, -f FILE        : Process a single local image file"
    echo "  --url_file, -u FILE    : Process URLs from a text file"
    echo "  --batch_folder, -b DIR : Process all images in a folder"
    echo "  --output_path, -o DIR  : Output directory for processed images"
    echo "  --max_workers, -m NUM  : Maximum concurrent workers (default: 4)"
    echo "  --overwrite, -w        : Overwrite existing files"
    echo "\nExamples:"
    echo "  bria_bgremover -i                                          # Interactive mode"
    echo "  bria_bgremover --url https://example.com/image.jpg -o ./output"
    echo "  bria_bgremover -f ./image.jpg -o ./output"
    echo "  bria_bgremover -u ./urls.txt -o ./output"
    echo "  bria_bgremover -b ./images -m 8 -w"
    return 0
  fi
  local script_remote="https://raw.githubusercontent.com/funnyzak/dotfiles/main/utilities/python/bria/background_remover.py"
  if [[ "$CN" == "true" ]]; then
    script_remote="https://raw.gitcode.com/funnyzak/dotfiles/raw/main/utilities/python/bria/background_remover.py"
  fi

  # Build the command based on provided arguments
  local cmd="python3 <(curl -s $script_remote)"

  # Add API token
  cmd+=" --api_token $BRIA_TOKEN"

  # Process arguments and build command
  local i=1
  while [ $i -le $# ]; do
    local arg=${(P)i}

    case "$arg" in
      --interactive|-i)
        echo "启动交互式背景移除工具..."
        python3 <(curl -s $script_remote)
        return $?
        ;;
      --url)
        i=$((i+1))
        cmd+=" --url ${(P)i}"
        ;;
      --file|-f)
        i=$((i+1))
        cmd+=" --file ${(P)i}"
        ;;
      --url_file|-u)
        i=$((i+1))
        cmd+=" --url_file ${(P)i}"
        ;;
      --batch_folder|-b)
        i=$((i+1))
        cmd+=" --batch_folder ${(P)i}"
        ;;
      --output_path|-o)
        i=$((i+1))
        cmd+=" --output_path ${(P)i}"
        ;;
      --max_workers|-m)
        i=$((i+1))
        cmd+=" --max_workers ${(P)i}"
        ;;
      --overwrite|-w)
        cmd+=" --overwrite"
        ;;
      *)
        echo "Error: Unknown option: $arg"
        return 1
        ;;
    esac

    i=$((i+1))
  done

  echo "执行背景移除工具命令..."
  echo "$cmd"
  eval "$cmd"
}' # Remote execution of Bria background remover tool

