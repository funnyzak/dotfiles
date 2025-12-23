# Description: Image processing aliases for resizing, conversion, effects, manipulation and batch operations.

# --------------------------------
# Help Function
# --------------------------------

# --------------------------------
# Helper Functions
# --------------------------------

# Helper function for resizing images
alias _image_resize='() {
  echo "Resize an image to specified dimensions."
  echo "Usage: _image_resize <source_path> <size> <quality>"

  if [ $# -lt 3 ]; then
    echo "Error: Insufficient parameters for image resize." >&2
    return 1
  fi

  local source_path="$1"
  local size="$2"
  local quality="$3"

  if [ ! -f "$source_path" ]; then
    echo "Error: File \"$source_path\" not found." >&2
    return 1
  fi

  local target_path="${source_path%.*}_${size}_q${quality}.${source_path##*.}"

  local magick_cmd=$(_image_aliases_magick_cmd)

  if $magick_cmd convert "$source_path" -resize "$size" -quality "$quality" "$target_path"; then
    echo "Resized image saved to $target_path"
    return 0
  else
    echo "Error: Failed to resize image. Check if ImageMagick is properly installed." >&2
    return 1
  fi
}' # Helper function for resizing images

# Helper function to validate image file existence
alias _image_aliases_validate_file='() {
  if [ $# -lt 1 ]; then
    echo "Error: No file path provided for validation." >&2
    return 1
  fi

  if [ ! -f "$1" ]; then
    echo "Error: File \"$1\" not found." >&2
    return 1
  fi
  return 0
}' # Helper function to validate image file existence

# Helper function to validate directory existence
alias _image_aliases_validate_dir='() {
  if [ $# -lt 1 ]; then
    echo "Error: No directory path provided for validation." >&2
    return 1
  fi

  if [ ! -d "$1" ]; then
    echo "Error: Directory \"$1\" not found." >&2
    return 1
  fi
  return 0
}' # Helper function to validate directory existence

# Helper function to check if ImageMagick is installed
alias _image_aliases_check_imagemagick='() {
  if ! command -v magick &> /dev/null && ! command -v convert &> /dev/null; then
    echo "Error: ImageMagick is not installed. Please install it first." >&2
    echo "  macOS: brew install imagemagick" >&2
    echo "  Linux: sudo apt-get install imagemagick" >&2
    return 1
  fi
  return 0
}' # Helper function to check if ImageMagick is installed

# Helper function to use correct ImageMagick command based on platform
alias _image_aliases_magick_cmd='() {
  if command -v magick &> /dev/null; then
    echo "magick"
  else
    echo "convert"
  fi
}' # Helper function to determine the correct ImageMagick command

# --------------------------------
# Basic Image Processing
# --------------------------------

alias img-resize='() {
  if [ $# -eq 0 ]; then
    echo "Resize image to specified dimensions."
    echo "Usage: img-resize <image_path> [options]"
    echo "Options:"
    echo "  -s, --size <dimensions>   Target dimensions (default: 200x)"
    echo "  -q, --quality <percent>   Image quality (default: 80)"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  img-resize photo.jpg"
    echo "  img-resize photo.jpg --size 300x300"
    echo "  img-resize photo.jpg -s 800x600 -q 90"
    return 0
  fi

  # Parse arguments
  local image_path=""
  local size="200x"
  local quality="80"

  while [[ $# -gt 0 ]]; do
    case $1 in
      -s|--size)
        size="$2"
        shift 2
        ;;
      -q|--quality)
        quality="$2"
        shift 2
        ;;
      -h|--help)
        echo "Resize image to specified dimensions."
        echo "Usage: img-resize <image_path> [options]"
        echo "Options:"
        echo "  -s, --size <dimensions>   Target dimensions (default: 200x)"
        echo "  -q, --quality <percent>   Image quality (default: 80)"
        echo "  -h, --help               Show this help message"
        echo ""
        echo "Examples:"
        echo "  img-resize photo.jpg"
        echo "  img-resize photo.jpg --size 300x300"
        echo "  img-resize photo.jpg -s 800x600 -q 90"
        return 0
        ;;
      *)
        if [ -z "$image_path" ]; then
          image_path="$1"
        else
          echo "Error: Unknown option or multiple image paths provided: \"$1\"" >&2
          echo "Use --help to see usage information" >&2
          return 1
        fi
        shift
        ;;
    esac
  done

  if [ -z "$image_path" ]; then
    echo "Error: Image path is required" >&2
    echo "Use --help to see usage information" >&2
    return 1
  fi

  _image_aliases_validate_file "$image_path" || return 1
  _image_resize "$image_path" "$size" "$quality"
}' # Resize image to specified dimensions with named parameters

alias img-resize-dir='() {
  echo -e "Batch resize images in directory and all subdirectories.\nUsage:\n img-resize-dir <source_dir> <size> [quality:100]\nAll output images will be saved in a mirrored subfolder structure under <source_dir>/<size>/"
  # 参数校验
  if [ $# -lt 2 ]; then
    return 0
  fi

  _image_aliases_validate_dir "$1" || return 1

  local source_dir="$1"
  local size="$2"
  local quality="${3:-100}"
  local output_root="$source_dir/$size"
  local magick_cmd=$(_image_aliases_magick_cmd)
  local total_files=0
  local processed=0
  local errors=0

  # 递归查找所有图片文件
  while IFS= read -r file; do
    total_files=$((total_files+1))
  done < <(find "$source_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" -o -iname "*.heic" -o -iname "*.tif" -o -iname "*.tiff" \))

  echo "Found $total_files images to process..."

  find "$source_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" -o -iname "*.heic" -o -iname "*.tif" -o -iname "*.tiff" \) | while IFS= read -r file; do
    # 计算相对路径
    local rel_path="${file#$source_dir/}"
    local out_dir="$output_root/$(dirname "$rel_path")"
    mkdir -p "$out_dir"
    local out_file="$out_dir/$(basename "$file")"
    echo "Processing: $file -> $out_file"
    if $magick_cmd "$file" -resize "$size" -quality "$quality" "$out_file"; then
      processed=$((processed+1))
    else
      echo "Error: Failed to resize $file" >&2
      errors=$((errors+1))
    fi
  done

  echo "Resize complete, exported $processed images to $output_root, $errors errors."
  [ $errors -eq 0 ] || return 1
}' # Batch resize images in directory and all subdirectories, output to mirrored structure


# --------------------------------
# Format Conversion
# --------------------------------

alias img-convert-format='() {
  echo "Convert image files to different format."
  echo "Usage: img-convert-format <source_path> <new_extension>"
  echo "       img-convert-format <source_dir> <new_extension>"
  echo "Examples:"
  echo "  img-convert-format image.jpg png -> Converts single file to PNG"
  echo "  img-convert-format ./photos webp -> Converts all images in directory to WebP"

  if [ $# -lt 2 ]; then
    return 0
  fi

  _image_aliases_check_imagemagick || return 1
  local magick_cmd=$(_image_aliases_magick_cmd)

  local source_path="$1"
  local new_ext="$2"
  local count=0
  local errors=0

  # Remove leading dot from extension if present
  new_ext="${new_ext#.}"

  # Check if source is a file or directory
  if [ -f "$source_path" ]; then
    # Single file conversion
    local output_path="${source_path%.*}.${new_ext}"
    if $magick_cmd "$source_path" "$output_path"; then
      echo "Converted: $source_path -> $output_path"
      count=1
    else
      echo "Error: Failed to convert $source_path to $new_ext format." >&2
      errors=1
    fi
  elif [ -d "$source_path" ]; then
    # Directory conversion
    local output_dir="$source_path/$new_ext"
    mkdir -p "$output_dir"

    while IFS= read -r img; do
      if [ -f "$img" ]; then
        local filename=$(basename "$img")
        local output_path="$output_dir/${filename%.*}.${new_ext}"
        if $magick_cmd "$img" "$output_path"; then
          echo "Converted: $img -> $output_path"
          count=$((count+1))
        else
          echo "Error: Failed to convert $img to $new_ext format." >&2
          errors=$((errors+1))
        fi
      fi
    done < <(find "$source_path" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" -o -iname "*.heic" -o -iname "*.tif" -o -iname "*.tiff" -o -iname "*.gif" -o -iname "*.webp" \))

    echo "Converted files saved to: $output_dir"
  else
    echo "Error: Source path \"$source_path\" is neither a valid file nor a directory." >&2
    return 1
  fi

  echo "Conversion complete: $count file(s) converted, $errors error(s)"
  [ $errors -eq 0 ] || return 1
}' # Convert image files to different format

# --------------------------------
# Image Effects
# --------------------------------

alias img-opacity='() {
  if [ $# -lt 2 ]; then
    echo "Adjust image opacity."
    echo "Usage: img-opacity <source_image> <opacity_percent:50>"
    return 0
  fi

  _image_aliases_validate_file "$1" || return 1

  local source_path="$1"
  local opacity="${2:-50}"
  local target_path="${source_path%.*}_opacity${opacity}.${source_path##*.}"

  if magick convert "$source_path" -alpha set -channel A -evaluate set "${opacity}%" "$target_path"; then
    echo "Opacity adjustment complete, exported to $target_path"
  else
    echo "Error: Failed to adjust image opacity." >&2
    return 1
  fi
}' # Adjust image opacity

alias img-rotate='() {
  if [ $# -lt 2 ]; then
    echo "Rotate image."
    echo "Usage: img-rotate <source_image> <rotation_degrees:90>"
    return 0
  fi

  _image_aliases_validate_file "$1" || return 1

  local source_path="$1"
  local degrees="${2:-90}"
  local target_path="${source_path%.*}_rotate${degrees}.${source_path##*.}"

  if magick convert -rotate "$degrees" -background none "$source_path" "$target_path"; then
    echo "Rotation complete, exported to $target_path"
  else
    echo "Error: Failed to rotate image." >&2
    return 1
  fi
}' # Rotate image

alias img-grayscale-binary='() {
  if [ $# -eq 0 ]; then
    echo "Convert image to grayscale and binarize."
    echo "Usage: img-grayscale-binary <source_image>"
    return 0
  fi

  _image_aliases_validate_file "$1" || return 1

  local source_path="$1"
  local target_path="${source_path%.*}_gray_binary.${source_path##*.}"

  if magick convert "$source_path" -colorspace Gray -threshold 50% "$target_path"; then
    echo "Grayscale and binarization complete, exported to $target_path"
  else
    echo "Error: Failed to convert image." >&2
    return 1
  fi
}' # Convert image to grayscale and binarize

alias img-grayscale='() {
  if [ $# -eq 0 ]; then
    echo "Convert image to grayscale."
    echo "Usage: img-grayscale <source_image>"
    return 0
  fi

  _image_aliases_validate_file "$1" || return 1

  local source_path="$1"
  local target_path="${source_path%.*}_gray.${source_path##*.}"

  if magick convert "$source_path" -colorspace Gray "$target_path"; then
    echo "Grayscale conversion complete, exported to $target_path"
  else
    echo "Error: Failed to convert image to grayscale." >&2
    return 1
  fi
}' # Convert image to grayscale

# --------------------------------
# Batch Processing
# --------------------------------

alias img-grayscale-binary-dir='() {
  if [ $# -eq 0 ]; then
    echo "Convert directory of images to grayscale and binarize."
    echo "Usage: img-grayscale-binary-dir <source_dir>"
    return 0
  fi

  _image_aliases_validate_dir "$1" || return 1

  local source_dir="$1"
  local output_dir="$source_dir/gray_binary"

  mkdir -p "$output_dir"

  if magick mogrify -colorspace Gray -threshold 50% -path "$output_dir" "$(find "$source_dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" -o -iname "*.heic" \))" 2>/dev/null; then
    echo "Grayscale and binarization complete, exported to $output_dir"
  else
    echo "Warning: Some images may not have been processed correctly." >&2
  fi
}' # Convert directory of images to grayscale and binarize

alias img-grayscale-dir='() {
  if [ $# -eq 0 ]; then
    echo "Convert directory of images to grayscale."
    echo "Usage: img-grayscale-dir <source_dir>"
    return 0
  fi

  _image_aliases_validate_dir "$1" || return 1

  local source_dir="$1"
  local output_dir="$source_dir/gray"

  mkdir -p "$output_dir"

  if magick mogrify -colorspace Gray -path "$output_dir" "$(find "$source_dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" -o -iname "*.heic" \))" 2>/dev/null; then
    echo "Grayscale conversion complete, exported to $output_dir"
  else
    echo "Warning: Some images may not have been processed correctly." >&2
  fi
}' # Convert directory of images to grayscale

# --------------------------------
# Image Splitting
# --------------------------------

alias img-split='() {
  echo "Split image into multiple parts based on grid dimensions."
  echo "Usage: img-split <image_file> [grid_dimensions:2x1] [output_format] [more_files...]"
  echo "Options:"
  echo "  -o, --output <dir>    Output directory (default: same as input)"
  echo "  -f, --format <ext>    Output format (default: same as input)"
  echo "  -g, --grid <dim>      Grid dimensions (default: 2x1)"
  echo "Examples:"
  echo "  img-split image.jpg"
  echo "  img-split image.jpg 3x2"
  echo "  img-split image.jpg -g 3x2 -f png"
  echo "  img-split image1.jpg image2.jpg -g 2x2 -o ./output"

  if [ $# -eq 0 ]; then
    return 0
  fi

  _image_aliases_check_imagemagick || return 1
  local magick_cmd=$(_image_aliases_magick_cmd)

  # Default values
  local grid_dim="2x1"
  local output_format=""
  local output_dir=""
  local files=()
  local result_status=0

  # Parse arguments
  while [ $# -gt 0 ]; do
    case "$1" in
      -o|--output)
        output_dir="$2"
        shift 2
        ;;
      -f|--format)
        output_format="$2"
        shift 2
        ;;
      -g|--grid)
        grid_dim="$2"
        shift 2
        ;;
      *)
        files+=("$1")
        shift
        ;;
    esac
  done

  # Validate grid dimensions
  if ! echo "$grid_dim" | grep -qE "^[0-9]+x[0-9]+$"; then
    echo "Error: Invalid grid dimensions format. Use format: NxM (e.g., 2x1)" >&2
    return 1
  fi

  # Process each file
  for img in "${files[@]}"; do
    _image_aliases_validate_file "$img" || { result_status=1; continue; }

    # Get image dimensions
    local dimensions=$($magick_cmd identify -format "%wx%h" "$img" 2>/dev/null)
    if [ $? -ne 0 ]; then
      echo "Error: Failed to get dimensions of $img" >&2
      result_status=1
      continue
    fi

    # Calculate tile dimensions
    local width=$(echo "$dimensions" | cut -d'x' -f1)
    local height=$(echo "$dimensions" | cut -d'x' -f2)
    local grid_x=$(echo "$grid_dim" | cut -d'x' -f1)
    local grid_y=$(echo "$grid_dim" | cut -d'x' -f2)
    local tile_width=$((width / grid_x))
    local tile_height=$((height / grid_y))

    # Set output directory
    local img_output_dir="${output_dir:-$(dirname "$img")/split-$(basename "$img" ".${img##*.}")}"
    mkdir -p "$img_output_dir"

    # Set output format
    local img_output_format="${output_format:-${img##*.}}"
    img_output_format="${img_output_format#.}"

    # Get base filename without extension
    local base_name=$(basename "$img" ".${img##*.}")

    # Split image
    if $magick_cmd "$img" -crop "${tile_width}x${tile_height}" \
       -set filename:tile "%[fx:page.x/${tile_width}+1]_%[fx:page.y/${tile_height}+1]" \
       "$img_output_dir/${base_name}_%[filename:tile].$img_output_format"; then
      echo "Split $img into ${grid_x}x${grid_y} parts, saved to $img_output_dir"
    else
      echo "Error: Failed to split $img" >&2
      result_status=1
    fi
  done

  return $result_status
}' # Split image into multiple parts based on grid dimensions

alias img-split-dir='() {
  echo "Split multiple images in a directory into parts based on grid dimensions."
  echo "Usage: img-split-dir <source_dir> [grid_dimensions:2x1]"
  echo "Options:"
  echo "  -o, --output <dir>    Output directory (default: split_output)"
  echo "  -f, --format <ext>    Output format (default: same as input)"
  echo "  -g, --grid <dim>      Grid dimensions (default: 2x1)"
  echo "  -p, --pattern <ext>   File pattern (default: jpg|jpeg|png|gif|bmp|webp)"
  echo "  -r, --recursive       Search subdirectories"
  echo "Examples:"
  echo "  img-split-dir ./images"
  echo "  img-split-dir ./images -g 3x2 -f png"
  echo "  img-split-dir ./images -p \"jpg|png\" -r"

  if [ $# -eq 0 ]; then
    return 0
  fi

  _image_aliases_check_imagemagick || return 1
  local magick_cmd=$(_image_aliases_magick_cmd)

  # Default values
  local source_dir="$1"
  local grid_dim="2x1"
  local output_format=""
  local output_dir="split_output"
  local pattern="jpg|jpeg|png|gif|bmp|webp"
  local recursive=false
  shift

  # Parse arguments
  while [ $# -gt 0 ]; do
    case "$1" in
      -o|--output)
        output_dir="$2"
        shift 2
        ;;
      -f|--format)
        output_format="$2"
        shift 2
        ;;
      -g|--grid)
        grid_dim="$2"
        shift 2
        ;;
      -p|--pattern)
        pattern="$2"
        shift 2
        ;;
      -r|--recursive)
        recursive=true
        shift
        ;;
      *)
        echo "Error: Unknown option $1" >&2
        return 1
        ;;
    esac
  done

  # Validate source directory
  _image_aliases_validate_dir "$source_dir" || return 1

  # Validate grid dimensions
  if ! echo "$grid_dim" | grep -qE "^[0-9]+x[0-9]+$"; then
    echo "Error: Invalid grid dimensions format. Use format: NxM (e.g., 2x1)" >&2
    return 1
  fi

  # Create output directory
  mkdir -p "$output_dir"

  # Find all image files
  local find_cmd="find \"$source_dir\""
  if [ "$recursive" = false ]; then
    find_cmd="$find_cmd -maxdepth 1"
  fi
  find_cmd="$find_cmd -type f -iregex \".*\\.($pattern)$\""

  local processed=0
  local errors=0

  # Process each file
  while IFS= read -r img; do
    # Get image dimensions
    local dimensions=$($magick_cmd identify -format "%wx%h" "$img" 2>/dev/null)
    if [ $? -ne 0 ]; then
      echo "Error: Failed to get dimensions of $img" >&2
      errors=$((errors+1))
      continue
    fi

    # Calculate tile dimensions
    local width=$(echo "$dimensions" | cut -d'x' -f1)
    local height=$(echo "$dimensions" | cut -d'x' -f2)
    local grid_x=$(echo "$grid_dim" | cut -d'x' -f1)
    local grid_y=$(echo "$grid_dim" | cut -d'x' -f2)
    local tile_width=$((width / grid_x))
    local tile_height=$((height / grid_y))

    # Set output format
    local img_output_format="${output_format:-${img##*.}}"
    img_output_format="${img_output_format#.}"

    # Get base filename without extension
    local base_name=$(basename "$img" ".${img##*.}")

    # Split image
    if $magick_cmd "$img" -crop "${tile_width}x${tile_height}" \
       -set filename:tile "%[fx:page.x/${tile_width}+1]_%[fx:page.y/${tile_height}+1]" \
       "$output_dir/${base_name}_%[filename:tile].$img_output_format"; then
      echo "Split $img into ${grid_x}x${grid_y} parts"
      processed=$((processed+1))
    else
      echo "Error: Failed to split $img" >&2
      errors=$((errors+1))
    fi
  done < <(eval "$find_cmd")

  echo "Processing complete: $processed files processed, $errors errors"
  echo "Output saved to: $output_dir"
  [ $errors -eq 0 ] || return 1
}' # Split multiple images in a directory into parts based on grid dimensions

# --------------------------------
# Image Merging
# --------------------------------

alias img-dir-to-pdf='() {
  if [ $# -eq 0 ]; then
    echo "Merge directory of images into PDF."
    echo "Usage: img-dir-to-pdf <source_dir> [output_pdf_name] [page_size]"
    echo "Page sizes: A4 (default), A3, A5, Letter, Legal, Tabloid"
    echo "Examples:"
    echo "  img-dir-to-pdf /path/to/images"
    echo "  img-dir-to-pdf /path/to/images output.pdf"
    echo "  img-dir-to-pdf /path/to/images output.pdf A4"
    echo "  img-dir-to-pdf /path/to/images output.pdf Letter"
    return 0
  fi

  _image_aliases_validate_dir "$1" || return 1
  _image_aliases_check_imagemagick || return 1

  local source_dir="$1"
  local folder_name="$(basename "$source_dir")"
  local output_pdf="${2:-$folder_name.pdf}"
  local page_size="${3:-A4}"
  local magick_cmd=$(_image_aliases_magick_cmd)

  # Convert page size to ImageMagick format
  local page_geometry=""
  case "$page_size" in
    A4|a4)
      page_geometry="595x842"
      ;;
    A3|a3)
      page_geometry="842x1191"
      ;;
    A5|a5)
      page_geometry="420x595"
      ;;
    Letter|letter)
      page_geometry="612x792"
      ;;
    Legal|legal)
      page_geometry="612x1008"
      ;;
    Tabloid|tabloid)
      page_geometry="792x1224"
      ;;
    *)
      echo "Warning: Unknown page size \"$page_size\", using A4 as default"
      page_geometry="595x842"
      ;;
  esac

  # Find all image files and store in array
  local image_files=()
  while IFS= read -r img; do
    image_files+=("$img")
  done < <(find "$source_dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" -o -iname "*.heic" \) | sort)

  if [ ${#image_files[@]} -eq 0 ]; then
    echo "Error: No image files found in $source_dir" >&2
    return 1
  fi

  echo "Found ${#image_files[@]} images to merge..."
  echo "Using page size: $page_size ($page_geometry)"

  # Create array with page geometry for each image
  local magick_args=()
  for img in "${image_files[@]}"; do
    magick_args+=("$img" -resize "${page_geometry}>" -gravity center -extent "$page_geometry" -background white)
  done

  if $magick_cmd "${magick_args[@]}" "$output_pdf"; then
    echo "Merged directory of images into PDF complete, exported to $output_pdf"
  else
    echo "Error: Failed to merge images to PDF." >&2
    return 1
  fi
}' # Merge directory of images into PDF

alias img-to-pdf='() {
  if [ $# -eq 0 ]; then
    echo "Convert single image to PDF."
    echo "Usage: img-to-pdf <source_image> [output_pdf_name] [page_size]"
    echo "Page sizes: A4 (default), A3, A5, Letter, Legal, Tabloid"
    echo "Examples:"
    echo "  img-to-pdf image.jpg"
    echo "  img-to-pdf image.jpg output.pdf"
    echo "  img-to-pdf image.jpg output.pdf A4"
    echo "  img-to-pdf image.jpg output.pdf Letter"
    return 0
  fi

  _image_aliases_validate_file "$1" || return 1

  local source_path="$1"
  local output_pdf="${2:-${source_path%.*}.pdf}"
  local page_size="${3:-A4}"

  # Convert page size to ImageMagick format
  local page_geometry=""
  case "$page_size" in
    A4|a4)
      page_geometry="595x842"
      ;;
    A3|a3)
      page_geometry="842x1191"
      ;;
    A5|a5)
      page_geometry="420x595"
      ;;
    Letter|letter)
      page_geometry="612x792"
      ;;
    Legal|legal)
      page_geometry="612x1008"
      ;;
    Tabloid|tabloid)
      page_geometry="792x1224"
      ;;
    *)
      echo "Warning: Unknown page size \"$page_size\", using A4 as default"
      page_geometry="595x842"
      ;;
  esac

  echo "Using page size: $page_size ($page_geometry)"

  if magick convert "$source_path" -resize "${page_geometry}>" -gravity center -extent "$page_geometry" -background white "$output_pdf"; then
    echo "Single image to PDF conversion complete, exported to $output_pdf"
  else
    echo "Error: Failed to convert image to PDF." >&2
    return 1
  fi
}' # Convert single image to PDF

# --------------------------------
# Watermarking
# --------------------------------

alias img-watermark='() {
  echo -e "Add watermark to image.\nUsage: img-watermark <source_image> <watermark_image> [position:southeast]\n\nExamples:\n  img-watermark photo.jpg logo.png\n  -> Adds logo.png as watermark to photo.jpg in southeast position\n  img-watermark image.png watermark.png center\n  -> Adds watermark.png to center of image.png"

  if [ $# -lt 2 ]; then
    return 0
  fi

  _image_aliases_validate_file "$1" || return 1
  _image_aliases_validate_file "$2" || return 1

  local source_path="$1"
  local watermark_path="$2"
  local position="${3:-southeast}"
  local output_path="${source_path%.*}_watermarked.${source_path##*.}"

  if magick convert "$source_path" "$watermark_path" -gravity "$position" -geometry +10+10 -composite "$output_path"; then
    echo "Watermark added, exported to $output_path"
  else
    echo "Error: Failed to add watermark." >&2
    return 1
  fi
}' # Add watermark to image

alias img-watermark-dir='() {
  if [ $# -lt 2 ]; then
    echo "Batch add watermark to images."
    echo "Usage: img-watermark-dir <watermark_image> <source_dir> [position:southeast] [opacity:100]"
    return 0
  fi

  _image_aliases_validate_file "$1" || return 1
  _image_aliases_validate_dir "$2" || return 1

  local watermark_path="$1"
  local source_dir="$2"
  local position="${3:-southeast}"
  local opacity="${4:-100}"
  local output_dir="$source_dir/watermarked"

  mkdir -p "$output_dir"
  local errors=0

  while IFS= read -r img; do
    if [ -f "$img" ]; then
      local base_name="$(basename "$img")"
      if ! magick composite -dissolve "$opacity" -gravity "$position" "$watermark_path" "$img" "$output_dir/$base_name"; then
        echo "Error: Failed to add watermark to $img" >&2
        errors=$((errors+1))
      fi
    fi
  done < <(find "$source_dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" -o -iname "*.heic" \))

  echo "Batch watermarking complete, exported to $output_dir"
  [ $errors -eq 0 ] || return 1
}' # Batch add watermark to images

# --------------------------------
# Image Optimization
# --------------------------------

alias img-optimize-batch='() {
  if [ $# -eq 0 ]; then
    echo "Batch optimize images by size."
    echo "Usage: img-optimize-batch [directory:.] [width:1024] [quality:85]"
    return 0
  fi

  local dir="${1:-.}"
  local width="${2:-1024}"
  local quality="${3:-85}"
  local processed=0
  local errors=0

  _image_aliases_validate_dir "$dir" || return 1

  find "$dir" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.gif" \) | while IFS= read -r file; do
    local output="${file%.*}_opt_${width}_q${quality}.${file##*.}"
    if magick "$file" -resize "${width}x" -quality "$quality" "$output"; then
      echo "Processed: $file -> $output"
      processed=$((processed+1))
    else
      echo "Error processing: $file" >&2
      errors=$((errors+1))
    fi
  done

  echo "Batch image optimization complete: $processed files processed, $errors errors"
  [ $errors -eq 0 ] || return 1
}' # Batch optimize images by size

# --------------------------------
# New Image Information Functions
# --------------------------------

alias img-info='() {
  echo "Display basic information about image files."
  echo "Usage: img-info <image_file> [more_files...]"

  if [ $# -eq 0 ]; then
    return 0
  fi

  _image_aliases_check_imagemagick || return 1
  local magick_cmd=$(_image_aliases_magick_cmd)

  local result_status=0
  for img in "$@"; do
    _image_aliases_validate_file "$img" || { result_status=1; continue; }

    echo "====== $img ======"
    if ! $magick_cmd identify -verbose "$img" | grep -E "(Image:|Geometry:|Resolution:|Filesize:|Format:|Depth:)"; then
      echo "Error: Failed to get image info for $img" >&2
      result_status=1
    fi
    echo ""
  done

  return $result_status
}' # Display basic information about image files

alias img-metadata='() {
  echo "Extract EXIF metadata from image files."
  echo "Usage: img-metadata <image_file> [more_files...]"

  if [ $# -eq 0 ]; then
    return 0
  fi

  if ! command -v exiftool &> /dev/null; then
    echo "Error: exiftool is not installed. Please install it first." >&2
    echo "  macOS: brew install exiftool" >&2
    echo "  Linux: sudo apt-get install libimage-exiftool-perl" >&2
    return 1
  fi

  local result_status=0
  for img in "$@"; do
    _image_aliases_validate_file "$img" || { result_status=1; continue; }

    echo "====== $img ======"
    if ! exiftool "$img"; then
      echo "Error: Failed to extract metadata from $img" >&2
      result_status=1
    fi
    echo ""
  done

  return $result_status
}' # Extract EXIF metadata from image files

# --------------------------------
# Image Cropping Functions
# --------------------------------

alias img-crop='() {
  echo "Crop an image to specified dimensions."
  echo "Usage: img-crop <image_file> <width>x<height>+<x_offset>+<y_offset>"
  echo "Example: img-crop photo.jpg 300x200+50+30"

  if [ $# -lt 2 ]; then
    return 0
  fi

  _image_aliases_check_imagemagick || return 1
  _image_aliases_validate_file "$1" || return 1

  local source_path="$1"
  local crop_spec="$2"
  local target_path="${source_path%.*}_cropped.${source_path##*.}"
  local magick_cmd=$(_image_aliases_magick_cmd)

  if $magick_cmd "$source_path" -crop "$crop_spec" +repage "$target_path"; then
    echo "Cropped image saved to $target_path"
    return 0
  else
    echo "Error: Failed to crop image." >&2
    return 1
  fi
}' # Crop an image to specified dimensions

alias img-crop-center='() {
  echo "Crop an image from the center."
  echo "Usage: img-crop-center <image_file> <width>x<height>"
  echo "Example: img-crop-center photo.jpg 300x200"

  if [ $# -lt 2 ]; then
    return 0
  fi

  _image_aliases_check_imagemagick || return 1
  _image_aliases_validate_file "$1" || return 1

  local source_path="$1"
  local crop_size="$2"
  local target_path="${source_path%.*}_center_crop.${source_path##*.}"
  local magick_cmd=$(_image_aliases_magick_cmd)

  if $magick_cmd "$source_path" -gravity center -crop "$crop_size" +repage "$target_path"; then
    echo "Center-cropped image saved to $target_path"
    return 0
  else
    echo "Error: Failed to crop image from center." >&2
    return 1
  fi
}' # Crop an image from the center

# --------------------------------
# Image Compression Functions
# --------------------------------

alias img-compress='() {
  echo "Compress an image while preserving dimensions."
  echo "Usage: img-compress <image_file> [quality:75] [more_files...]"

  if [ $# -eq 0 ]; then
    return 0
  fi

  _image_aliases_check_imagemagick || return 1
  local quality="75"
  local magick_cmd=$(_image_aliases_magick_cmd)

  # If first arg is a number, its the quality
  if [[ "$1" =~ ^[0-9]+$ ]]; then
    quality="$1"
    shift
  fi

  local result_status=0
  for img in "$@"; do
    _image_aliases_validate_file "$img" || { result_status=1; continue; }

    local target_path="${img%.*}_compressed_q${quality}.${img##*.}"
    if $magick_cmd "$img" -quality "$quality" "$target_path"; then
      echo "Compressed image saved to $target_path"
    else
      echo "Error: Failed to compress $img" >&2
      result_status=1
    fi
  done

  return $result_status
}' # Compress an image while preserving dimensions

alias img-compress-dir='() {
  echo -e "Batch compress all images in a directory and all subdirectories.\nUsage:\n img-compress-dir [directory:.] [quality:75]\nAll output images will be saved in a mirrored subfolder structure under <directory>/compressed_q<quality>/"

  local dir="${1:-.}"
  local quality="${2:-75}"

  _image_aliases_check_imagemagick || return 1
  _image_aliases_validate_dir "$dir" || return 1

  local output_root="$dir/compressed_q${quality}"
  local magick_cmd=$(_image_aliases_magick_cmd)
  local total_files=0
  local processed=0
  local errors=0

  # 递归查找所有图片文件
  while IFS= read -r file; do
    total_files=$((total_files+1))
  done < <(find "$dir" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \))

  echo "Found $total_files images to compress..."

  find "$dir" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | while IFS= read -r img; do
    # 计算相对路径
    local rel_path="${img#$dir/}"
    local out_dir="$output_root/$(dirname "$rel_path")"
    mkdir -p "$out_dir"
    local out_file="$out_dir/$(basename "$img")"
    echo "Processing: $img -> $out_file"
    if ! $magick_cmd "$img" -quality "$quality" "$out_file"; then
      echo "Error: Failed to compress $img" >&2
      errors=$((errors+1))
    else
      processed=$((processed+1))
    fi
  done

  echo "Batch compression complete, $processed files processed, $errors errors"
  echo "Files saved to: $output_root"
  [ $errors -eq 0 ] || return 1
}' # Batch compress all images in a directory and all subdirectories, output to mirrored structure

# --------------------------------
# Image Joining Functions
# --------------------------------

alias img-join-horizontal='() {
  echo "Join multiple images horizontally."
  echo "Usage: img-join-horizontal <output_file> <image1> <image2> [more_images...]"

  if [ $# -lt 3 ]; then
    return 0
  fi

  _image_aliases_check_imagemagick || return 1
  local magick_cmd=$(_image_aliases_magick_cmd)

  local output_file="$1"
  shift

  local images=()
  local result_status=0

  for img in "$@"; do
    _image_aliases_validate_file "$img" || { result_status=1; continue; }
    images+=("$img")
  done

  if [ ${#images[@]} -lt 2 ]; then
    echo "Error: At least 2 valid images are required for joining." >&2
    return 1
  fi

  if $magick_cmd "${images[@]}" +append "$output_file"; then
    echo "Images joined horizontally, saved to $output_file"
  else
    echo "Error: Failed to join images horizontally." >&2
    return 1
  fi
}' # Join multiple images horizontally

alias img-join-vertical='() {
  echo "Join multiple images vertically."
  echo "Usage: img-join-vertical <output_file> <image1> <image2> [more_images...]"

  if [ $# -lt 3 ]; then
    return 0
  fi

  _image_aliases_check_imagemagick || return 1
  local magick_cmd=$(_image_aliases_magick_cmd)

  local output_file="$1"
  shift

  local images=()
  local result_status=0

  for img in "$@"; do
    _image_aliases_validate_file "$img" || { result_status=1; continue; }
    images+=("$img")
  done

  if [ ${#images[@]} -lt 2 ]; then
    echo "Error: At least 2 valid images are required for joining." >&2
    return 1
  fi

  if $magick_cmd "${images[@]}" -append "$output_file"; then
    echo "Images joined vertically, saved to $output_file"
  else
    echo "Error: Failed to join images vertically." >&2
    return 1
  fi
}' # Join multiple images vertically

# --------------------------------
# Image Special Effects
# --------------------------------

alias img-sepia='() {
  echo "Apply sepia tone effect to an image."
  echo "Usage: img-sepia <image_file> [more_files...]"

  if [ $# -eq 0 ]; then
    return 0
  fi

  _image_aliases_check_imagemagick || return 1
  local magick_cmd=$(_image_aliases_magick_cmd)

  local result_status=0
  for img in "$@"; do
    _image_aliases_validate_file "$img" || { result_status=1; continue; }

    local target_path="${img%.*}_sepia.${img##*.}"
    if $magick_cmd "$img" -sepia-tone 80% "$target_path"; then
      echo "Sepia effect applied, saved to $target_path"
    else
      echo "Error: Failed to apply sepia effect to $img" >&2
      result_status=1
    fi
  done

  return $result_status
}' # Apply sepia tone effect to an image

alias img-blur='() {
  echo "Apply blur effect to an image."
  echo "Usage: img-blur <image_file> [radius:5] [more_files...]"

  if [ $# -eq 0 ]; then
    return 0
  fi

  _image_aliases_check_imagemagick || return 1
  local magick_cmd=$(_image_aliases_magick_cmd)

  # Check if second parameter is a number (radius)
  local radius="5"
  local start_idx=1

  if [ $# -gt 1 ] && echo "$2" | grep -qE "^[0-9]+(\.[0-9]+)?$"; then
    radius="$2"
    start_idx=2
  fi

  local result_status=0
  local i=$start_idx
  while [ $i -le $# ]; do
    local var="$i"
    local img="${!var}"
    _image_aliases_validate_file "$img" || { result_status=1; i=$((i+1)); continue; }

    local target_path="${img%.*}_blur_${radius}.${img##*.}"
    if $magick_cmd "$img" -blur 0x"$radius" "$target_path"; then
      echo "Blur effect applied with radius $radius, saved to $target_path"
    else
      echo "Error: Failed to apply blur effect to $img" >&2
      result_status=1
    fi
    i=$((i+1))
  done

  return $result_status
}' # Apply blur effect to an image

# --------------------------------
# Image Background Functions
# --------------------------------

alias img-add-bg='() {
  echo "Add background image to foreground image(s)."
  echo "Usage: img-add-bg <foreground_image> <background_image> [output_path]"
  echo "Example: img-add-bg image.png background.jpg"
  echo "         img-add-bg image.png background.jpg output.png"

  if [ $# -lt 2 ]; then
    return 0
  fi

  _image_aliases_check_imagemagick || return 1

  local foreground_path="$1"
  local background_path="$2"
  local output_path="${3:-${foreground_path%.*}_with_bg.${foreground_path##*.}}"

  _image_aliases_validate_file "$foreground_path" || return 1
  _image_aliases_validate_file "$background_path" || return 1

  local magick_cmd=$(_image_aliases_magick_cmd)

  # Get the dimensions of the foreground image
  local dimensions=$($magick_cmd identify -format "%wx%h" "$foreground_path" 2>/dev/null)
  if [ $? -ne 0 ]; then
    echo "Error: Failed to get dimensions of foreground image." >&2
    return 1
  fi

  # Resize background to match foreground dimensions while maintaining aspect ratio
  # Then composite foreground on top of background
  if $magick_cmd "$background_path" -resize "$dimensions^" -gravity center -extent "$dimensions" \
     "$foreground_path" -gravity center -composite "$output_path"; then
    echo "Background added successfully, saved to $output_path"
    return 0
  else
    echo "Error: Failed to add background to image." >&2
    return 1
  fi
}' # Add background image to foreground image

alias img-add-bg-dir='() {
  echo "Add background image to all images in a directory."
  echo "Usage: img-add-bg-dir <foreground_dir> <background_image> [output_dir]"
  echo "Example: img-add-bg-dir images/ background.jpg"
  echo "         img-add-bg-dir images/ background.jpg output_dir"

  if [ $# -lt 2 ]; then
    return 0
  fi

  _image_aliases_check_imagemagick || return 1

  local foreground_dir="$1"
  local background_path="$2"
  local output_dir="${3:-$foreground_dir/with_background}"

  _image_aliases_validate_dir "$foreground_dir" || return 1
  _image_aliases_validate_file "$background_path" || return 1

  mkdir -p "$output_dir"

  local magick_cmd=$(_image_aliases_magick_cmd)
  local errors=0
  local processed=0

  find "$foreground_dir" -maxdepth 5 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" \) | while IFS= read -r img; do
    local base_name="$(basename "$img")"
    local output_path="$output_dir/$base_name"

    # Get the dimensions of the current foreground image
    local dimensions=$($magick_cmd identify -format "%wx%h" "$img" 2>/dev/null)
    if [ $? -ne 0 ]; then
      echo "Error: Failed to get dimensions of image $img" >&2
      errors=$((errors+1))
      continue
    fi

    # Apply background to each image
    if $magick_cmd "$background_path" -resize "$dimensions^" -gravity center -extent "$dimensions" \
       "$img" -gravity center -composite "$output_path"; then
      echo "Processed: $base_name"
      processed=$((processed+1))
    else
      echo "Error: Failed to add background to $base_name" >&2
      errors=$((errors+1))
    fi
  done

  echo "Background addition complete: $processed files processed, $errors errors"
  echo "Output saved to: $output_dir"
  [ $errors -eq 0 ] || return 1
}' # Add background image to all images in a directory

alias img-add-color-background='() {
  echo "Add solid color background to image(s)."
  echo "Usage: img-add-color-background <foreground_image> <color> [output_path]"
  echo "Examples:"
  echo "  img-add-color-background image.png \"#FF0000\"   # Red background"
  echo "  img-add-color-background logo.png white         # White background"

  if [ $# -lt 2 ]; then
    return 0
  fi

  _image_aliases_check_imagemagick || return 1

  local foreground_path="$1"
  local background_color="$2"
  local output_path="${3:-${foreground_path%.*}_with_${background_color}_bg.${foreground_path##*.}}"

  _image_aliases_validate_file "$foreground_path" || return 1

  local magick_cmd=$(_image_aliases_magick_cmd)

  # Get the dimensions of the foreground image
  local dimensions=$($magick_cmd identify -format "%wx%h" "$foreground_path" 2>/dev/null)
  if [ $? -ne 0 ]; then
    echo "Error: Failed to get dimensions of foreground image." >&2
    return 1
  fi

  # Create a solid color background and composite foreground on top
  if $magick_cmd -size "$dimensions" "canvas:$background_color" \
     "$foreground_path" -gravity center -composite "$output_path"; then
    echo "Color background added successfully, saved to $output_path"
    return 0
  else
    echo "Error: Failed to add color background to image." >&2
    return 1
  fi
}' # Add solid color background to image(s)

# --------------------------------
# Sprite Generation Functions
# --------------------------------

alias img-sprite='() {
  echo "Generate sprite sheet from images in a directory."
  echo "Usage: img-sprite <source_dir> [columns:6] [resize_spec:original]"
  echo "Note: Output sprite will be saved at the same level as the source directory."
  echo "Examples:"
  echo "  img-sprite ./icons                    # 6 columns, original size"
  echo "  img-sprite ./icons 4                 # 4 columns, original size"
  echo "  img-sprite ./icons 8 50x             # 8 columns, resize to 50px width"
  echo "  img-sprite ./icons 6 50x100          # 6 columns, resize to 50x100"

  if [ $# -eq 0 ]; then
    return 0
  fi

  _image_aliases_check_imagemagick || return 1
  _image_aliases_validate_dir "$1" || return 1

  local source_dir="$1"
  local columns="${2:-6}"
  local resize_spec="${3:-original}"
  local magick_cmd=$(_image_aliases_magick_cmd)

  # Validate columns parameter
  if ! echo "$columns" | grep -qE "^[1-9][0-9]*$"; then
    echo "Error: Columns must be a positive integer." >&2
    return 1
  fi

  # Get all image files
  local temp_files=()
  local original_files=()
  local cleanup_needed=false

  while IFS= read -r img; do
    original_files+=("$img")
  done < <(find "$source_dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.webp" \) | sort)

  if [ ${#original_files[@]} -eq 0 ]; then
    echo "Error: No image files found in $source_dir" >&2
    return 1
  fi

  echo "Found ${#original_files[@]} images to process..."

  # Prepare files (resize if needed)
  local files_to_use=()
  if [ "$resize_spec" != "original" ]; then
    cleanup_needed=true
    local temp_dir=$(mktemp -d)
    echo "Resizing images to $resize_spec..."

    for img in "${original_files[@]}"; do
      local base_name=$(basename "$img")
      local temp_file="$temp_dir/$base_name"
      if $magick_cmd "$img" -resize "$resize_spec" "$temp_file"; then
        temp_files+=("$temp_file")
        files_to_use+=("$temp_file")
      else
        echo "Warning: Failed to resize $img, using original" >&2
        files_to_use+=("$img")
      fi
    done
  else
    files_to_use=("${original_files[@]}")
  fi

  # Generate sprite sheet
  local dir_name=$(basename "$source_dir")
  local parent_dir=$(dirname "$source_dir")
  local output_name="${dir_name}_sprite_${columns}col"
  if [ "$resize_spec" != "original" ]; then
    output_name="${output_name}_${resize_spec}"
  fi
  local output_file="$parent_dir/${output_name}.png"

  echo "Generating sprite sheet with $columns columns..."
  if $magick_cmd montage "${files_to_use[@]}" -tile "${columns}x" -geometry +0+0 -background transparent "$output_file"; then
    echo "Sprite sheet generated successfully: $output_file"
  else
    echo "Error: Failed to generate sprite sheet." >&2
    # Cleanup temp files if needed
    if [ "$cleanup_needed" = true ] && [ ${#temp_files[@]} -gt 0 ]; then
      rm -rf "$temp_dir"
    fi
    return 1
  fi

  # Cleanup temp files if needed
  if [ "$cleanup_needed" = true ] && [ ${#temp_files[@]} -gt 0 ]; then
    rm -rf "$temp_dir"
  fi

  return 0
}' # Generate sprite sheet from images in a directory

alias img-sprite-multi='() {
  echo "Generate sprite sheets from multiple directories (subdirectories of parent directory)."
  echo "Usage: img-sprite-multi <parent_dir> [columns:6] [resize_spec:original]"
  echo "Note: Each sprite will be saved at the same level as its source subdirectory."
  echo "Examples:"
  echo "  img-sprite-multi ./assets             # Process all subdirs, 6 columns, original size"
  echo "  img-sprite-multi ./assets 4          # Process all subdirs, 4 columns, original size"
  echo "  img-sprite-multi ./assets 8 50x      # Process all subdirs, 8 columns, resize to 50px width"

  if [ $# -eq 0 ]; then
    return 0
  fi

  _image_aliases_check_imagemagick || return 1
  _image_aliases_validate_dir "$1" || return 1

  local parent_dir="$1"
  local columns="${2:-6}"
  local resize_spec="${3:-original}"
  local processed=0
  local errors=0

  # Validate columns parameter
  if ! echo "$columns" | grep -qE "^[1-9][0-9]*$"; then
    echo "Error: Columns must be a positive integer." >&2
    return 1
  fi

  # Find all subdirectories
  local subdirs=()
  while IFS= read -r subdir; do
    subdirs+=("$subdir")
  done < <(find "$parent_dir" -maxdepth 1 -type d ! -path "$parent_dir" | sort)

  if [ ${#subdirs[@]} -eq 0 ]; then
    echo "Error: No subdirectories found in $parent_dir" >&2
    return 1
  fi

  echo "Found ${#subdirs[@]} subdirectories to process..."

  # Process each subdirectory
  for subdir in "${subdirs[@]}"; do
    echo "Processing directory: $(basename "$subdir")"

    # Check if directory contains images
    local img_count=$(find "$subdir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.webp" \) | wc -l)

    if [ "$img_count" -eq 0 ]; then
      echo "  Skipping $(basename "$subdir"): No image files found"
      continue
    fi

    # Generate sprite for this directory
    if img-sprite "$subdir" "$columns" "$resize_spec" >/dev/null 2>&1; then
      echo "  ✓ Generated sprite for $(basename "$subdir") ($img_count images)"
      processed=$((processed+1))
    else
      echo "  ✗ Failed to generate sprite for $(basename "$subdir")" >&2
      errors=$((errors+1))
    fi
  done

  echo ""
  echo "Multi-directory sprite generation complete:"
  echo "  Processed: $processed directories"
  echo "  Errors: $errors directories"
  echo "  Columns: $columns"
  echo "  Resize: $resize_spec"

  [ $errors -eq 0 ] || return 1
}' # Generate sprite sheets from multiple directories

alias img-sprite-batch='() {
  echo "Generate sprite sheets with different configurations from a directory."
  echo "Usage: img-sprite-batch <source_dir> [resize_specs...]"
  echo "Note: All sprites will be saved at the same level as the source directory."
  echo "Examples:"
  echo "  img-sprite-batch ./icons              # Generate with default settings"
  echo "  img-sprite-batch ./icons 50x 100x    # Generate sprites with 50px and 100px widths"
  echo "  img-sprite-batch ./icons 32x32 64x64 # Generate sprites with fixed dimensions"

  if [ $# -eq 0 ]; then
    return 0
  fi

  _image_aliases_check_imagemagick || return 1
  _image_aliases_validate_dir "$1" || return 1

  local source_dir="$1"
  shift
  local resize_specs=("$@")
  local processed=0
  local errors=0

  # If no resize specs provided, use default configurations
  if [ ${#resize_specs[@]} -eq 0 ]; then
    resize_specs=("original" "50x" "100x")
  fi

  # Check if directory contains images
  local img_count=$(find "$source_dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.webp" \) | wc -l)

  if [ "$img_count" -eq 0 ]; then
    echo "Error: No image files found in $source_dir" >&2
    return 1
  fi

  echo "Generating sprite sheets for $(basename "$source_dir") with $img_count images..."

  # Generate sprites with different configurations
  for resize_spec in "${resize_specs[@]}"; do
    echo "Creating sprite with resize: $resize_spec"

    if img-sprite "$source_dir" 6 "$resize_spec" >/dev/null 2>&1; then
      echo "  ✓ Generated sprite with resize: $resize_spec"
      processed=$((processed+1))
    else
      echo "  ✗ Failed to generate sprite with resize: $resize_spec" >&2
      errors=$((errors+1))
    fi
  done

  echo ""
  echo "Batch sprite generation complete:"
  echo "  Generated: $processed sprites"
  echo "  Errors: $errors sprites"

  [ $errors -eq 0 ] || return 1
}' # Generate sprite sheets with different configurations

# --------------------------------
# Batch Rename Functions
# --------------------------------

alias img-rename-sequential='() {
  echo "Rename images in a directory with sequential numbering."
  echo "Usage: img-rename-sequential <directory> <prefix>"
  echo "Example: img-rename-sequential vacation_photos vacation"

  if [ $# -lt 2 ]; then
    return 0
  fi

  _image_aliases_validate_dir "$1" || return 1

  local dir="$1"
  local prefix="$2"
  local count=1
  local errors=0

  # Collect all image files first
  local files=()
  while IFS= read -r file; do
    files+=("$file")
  done < <(find "$dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" \) | sort)

  if [ ${#files[@]} -eq 0 ]; then
    echo "No image files found in $dir" >&2
    return 1
  fi

  echo "Found ${#files[@]} images to rename."

  for file in "${files[@]}"; do
    local ext="${file##*.}"
    local new_name=$(printf "%s_%03d.%s" "$prefix" "$count" "$ext")
    local new_path="$dir/$new_name"

    if [ -f "$new_path" ] && [ "$file" != "$new_path" ]; then
      echo "Error: Target file $new_name already exists, skipping" >&2
      errors=$((errors+1))
    else
      if mv "$file" "$new_path"; then
        echo "Renamed $(basename "$file") -> $new_name"
      else
        echo "Error: Failed to rename $(basename "$file")" >&2
        errors=$((errors+1))
      fi
    fi

    count=$((count+1))
  done

  echo "Renamed $((count-1-errors)) files with prefix \"$prefix\""
  [ $errors -eq 0 ] || return 1
}' # Rename images in a directory with sequential numbering

alias image-help='() {
  echo "Image Processing Aliases Help"
  echo "============================"
  echo "This module provides aliases for common image processing operations."
  echo
  echo "Basic Image Processing:"
  echo "  img-resize           - Resize image to specified dimensions"
  echo "  img-resize-dir       - Batch resize images in directory"
  echo
  echo "Format Conversion:"
  echo "  img-convert-format   - Convert image files to different format"
  echo
  echo "Image Effects:"
  echo "  img-opacity          - Adjust image opacity"
  echo "  img-rotate           - Rotate image"
  echo "  img-grayscale        - Convert image to grayscale"
  echo "  img-grayscale-binary - Convert image to grayscale and binarize"
  echo "  img-grayscale-dir    - Convert directory of images to grayscale"
  echo "  img-grayscale-binary-dir - Convert directory of images to grayscale and binarize"
  echo "  img-sepia            - Apply sepia tone effect to an image"
  echo "  img-blur             - Apply blur effect to an image"
  echo "  img-add-bg    - Add background image to foreground image"
  echo "  img-add-bg-dir - Add background image to all images in a directory"
  echo
  echo "Image Information:"
  echo "  img-info             - Display basic information about image files"
  echo "  img-metadata         - Extract EXIF metadata from image files"
  echo
  echo "Image Cropping:"
  echo "  img-crop             - Crop an image to specified dimensions"
  echo "  img-crop-center      - Crop an image from the center"
  echo
  echo "Image Compression:"
  echo "  img-compress         - Compress an image while preserving dimensions"
  echo "  img-compress-dir     - Batch compress all images in a directory"
  echo
  echo "Image Splitting:"
  echo "  img-split            - Split image into multiple parts based on grid dimensions"
  echo "  img-split-dir        - Split multiple images in a directory into parts based on grid dimensions"
  echo
  echo "Image Joining:"
  echo "  img-join-horizontal  - Join multiple images horizontally"
  echo "  img-join-vertical    - Join multiple images vertically"
  echo
  echo "Image Merging:"
  echo "  img-to-pdf           - Convert single image to PDF"
  echo "  img-dir-to-pdf       - Merge directory of images into PDF"
  echo
  echo "Watermarking:"
  echo "  img-watermark        - Add watermark to image"
  echo "  img-watermark-dir    - Batch add watermark to images"
  echo
  echo "Image Optimization:"
  echo "  img-optimize-batch   - Batch optimize images by size"
  echo
  echo "Sprite Generation:"
  echo "  img-sprite           - Generate sprite sheet from images in a directory"
  echo "  img-sprite-multi     - Generate sprite sheets from multiple directories"
  echo "  img-sprite-batch     - Generate sprite sheets with different configurations"
  echo
  echo "Batch Rename:"
  echo "  img-rename-sequential - Rename images in a directory with sequential numbering"
  echo
  echo "For more details about a specific command, just run the command without arguments."
}' # Help function showing all available image processing aliases

alias img-help='() {
  image-help
}' # Alias to call the help function

alias img-aliases='() {
  image-help
}' # Alias to call the help function
