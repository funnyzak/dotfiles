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
  echo "Resize image to specified dimensions."
  echo "Usage: img-resize <image_path> [size:200x] [quality:80]"

  if [ $# -eq 0 ]; then
    return 0
  fi

  _image_aliases_validate_file "$1" || return 1
  _image_resize "$1" "${2:-200x}" "${3:-80}"
}'  # Resize image to specified dimensions

alias img-resize-dir='() {
  if [ $# -lt 2 ]; then
    echo "Batch resize images in directory."
    echo "Usage: img-resize-dir <source_dir> <size> [quality:100]"
    return 0
  fi

  _image_aliases_validate_dir "$1" || return 1

  local source_dir="$1"
  local size="$2"
  local quality="${3:-100}"
  local output_dir="$source_dir/$size"

  mkdir -p "$output_dir"

  if magick mogrify -resize "$size" -quality "$quality" -path "$output_dir" "$source_dir"/*.(jpg|png|jpeg|bmp|heic|tif|tiff) 2>/dev/null; then
    echo "Resize complete, exported to $output_dir"
  else
    echo "Warning: Some images may not have been processed correctly." >&2
  fi
}'  # Batch resize images in directory

# --------------------------------
# Preset Image Sizes
# --------------------------------

alias img-resize-24='() {
  if [ $# -eq 0 ]; then
    echo "Resize image(s) to 24px width."
    echo "Usage: img-resize-24 <image_path> [more_files...]"
    return 0
  fi

  local result_status=0
  for img in "$@"; do
    _image_aliases_validate_file "$img" || { result_status=1; continue; }
    _image_resize "$img" "24x" "90"
  done
  return $result_status
}'  # Resize image(s) to 24px width

alias img-resize-28='() {
  if [ $# -eq 0 ]; then
    echo "Resize image(s) to 28px width."
    echo "Usage: img-resize-28 <image_path> [more_files...]"
    return 0
  fi

  local result_status=0
  for img in "$@"; do
    _image_aliases_validate_file "$img" || { result_status=1; continue; }
    _image_resize "$img" "28x" "90"
  done
  return $result_status
}'  # Resize image(s) to 28px width

alias img-resize-50='() {
  if [ $# -eq 0 ]; then
    echo "Resize image(s) to 50px width."
    echo "Usage: img-resize-50 <image_path> [more_files...]"
    return 0
  fi

  local result_status=0
  for img in "$@"; do
    _image_aliases_validate_file "$img" || { result_status=1; continue; }
    _image_resize "$img" "50x" "90"
  done
  return $result_status
}'  # Resize image(s) to 50px width

alias img-resize-100='() {
  if [ $# -eq 0 ]; then
    echo "Resize image(s) to 100px width."
    echo "Usage: img-resize-100 <image_path> [more_files...]"
    return 0
  fi

  local result_status=0
  for img in "$@"; do
    _image_aliases_validate_file "$img" || { result_status=1; continue; }
    _image_resize "$img" "100x" "90"
  done
  return $result_status
}'  # Resize image(s) to 100px width

alias img-resize-200='() {
  if [ $# -eq 0 ]; then
    echo "Resize image(s) to 200px width."
    echo "Usage: img-resize-200 <image_path> [more_files...]"
    return 0
  fi

  local result_status=0
  for img in "$@"; do
    _image_aliases_validate_file "$img" || { result_status=1; continue; }
    _image_resize "$img" "200x" "90"
  done
  return $result_status
}'  # Resize image(s) to 200px width

alias img-resize-512='() {
  if [ $# -eq 0 ]; then
    echo "Resize image(s) to 512px width."
    echo "Usage: img-resize-512 <image_path> [more_files...]"
    return 0
  fi

  local result_status=0
  for img in "$@"; do
    _image_aliases_validate_file "$img" || { result_status=1; continue; }
    _image_resize "$img" "512x" "90"
  done
  return $result_status
}'  # Resize image(s) to 512px width

alias img-resize-1024='() {
  if [ $# -eq 0 ]; then
    echo "Resize image(s) to 1024px width."
    echo "Usage: img-resize-1024 <image_path> [more_files...]"
    return 0
  fi

  local result_status=0
  for img in "$@"; do
    _image_aliases_validate_file "$img" || { result_status=1; continue; }
    _image_resize "$img" "1024x" "85"
  done
  return $result_status
}'  # Resize image(s) to 1024px width

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
    if $magick_cmd convert "$source_path" "$output_path"; then
      echo "Converted: $source_path -> $output_path"
      count=1
    else
      echo "Error: Failed to convert $source_path to $new_ext format." >&2
      errors=1
    fi
  elif [ -d "$source_path" ]; then
    # Directory conversion
    for img in "$source_path"/*.(jpg|png|jpeg|bmp|heic|tif|tiff|gif|webp); do
      if [ -f "$img" ]; then
        local output_path="${img%.*}.${new_ext}"
        if $magick_cmd convert "$img" "$output_path"; then
          echo "Converted: $img -> $output_path"
          count=$((count+1))
        else
          echo "Error: Failed to convert $img to $new_ext format." >&2
          errors=$((errors+1))
        fi
      fi
    done
  else
    echo "Error: Source path \"$source_path\" is neither a valid file nor a directory." >&2
    return 1
  fi

  echo "Conversion complete: $count file(s) converted, $errors error(s)"
  [ $errors -eq 0 ] || return 1
}'  # Convert image files to different format

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
}'  # Adjust image opacity

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
}'  # Rotate image

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
}'  # Convert image to grayscale and binarize

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
}'  # Convert image to grayscale

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

  if magick mogrify -colorspace Gray -threshold 50% -path "$output_dir" "$source_dir"/*.(jpg|png|jpeg|bmp|heic) 2>/dev/null; then
    echo "Grayscale and binarization complete, exported to $output_dir"
  else
    echo "Warning: Some images may not have been processed correctly." >&2
  fi
}'  # Convert directory of images to grayscale and binarize

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

  if magick mogrify -colorspace Gray -path "$output_dir" "$source_dir"/*.(jpg|png|jpeg|bmp|heic) 2>/dev/null; then
    echo "Grayscale conversion complete, exported to $output_dir"
  else
    echo "Warning: Some images may not have been processed correctly." >&2
  fi
}'  # Convert directory of images to grayscale

# --------------------------------
# Image Splitting
# --------------------------------

alias img-split-horizontal='() {
  if [ $# -eq 0 ]; then
    echo "Split image into left and right halves."
    echo "Usage: img-split-horizontal <source_image>"
    return 0
  fi

  _image_aliases_validate_file "$1" || return 1

  local source_path="$1"
  local base_name="${source_path%.*}"
  local ext="${source_path##*.}"

  if magick convert "$source_path" -crop 50%x100% +repage "${base_name}_%d.${ext}"; then
    echo "Split image into left and right halves complete, exported to ${base_name}_0.${ext} and ${base_name}_1.${ext}"
  else
    echo "Error: Failed to split image." >&2
    return 1
  fi
}'  # Split image into left and right halves

alias img-split-vertical='() {
  if [ $# -eq 0 ]; then
    echo "Split image into top and bottom halves."
    echo "Usage: img-split-vertical <source_image>"
    return 0
  fi

  _image_aliases_validate_file "$1" || return 1

  local source_path="$1"
  local base_name="${source_path%.*}"
  local ext="${source_path##*.}"

  if magick convert "$source_path" -crop 100%x50% +repage "${base_name}_%d.${ext}"; then
    echo "Split image into top and bottom halves complete, exported to ${base_name}_0.${ext} and ${base_name}_1.${ext}"
  else
    echo "Error: Failed to split image." >&2
    return 1
  fi
}'  # Split image into top and bottom halves

alias img-split-horizontal-dir='() {
  if [ $# -eq 0 ]; then
    echo "Split directory of images into left and right halves."
    echo "Usage: img-split-horizontal-dir <source_dir>"
    return 0
  fi

  _image_aliases_validate_dir "$1" || return 1

  local source_dir="$1"
  local output_dir="$source_dir/horizontal_split"

  mkdir -p "$output_dir"
  local errors=0

  for img in "$source_dir"/*.(jpg|png|jpeg|bmp|heic); do
    if [ -f "$img" ]; then
      local base_name="$(basename "${img%.*}")"
      local ext="${img##*.}"
      if ! magick convert "$img" -crop 50%x100% +repage "$output_dir/${base_name}_%d.${ext}"; then
        echo "Error: Failed to split $img" >&2
        errors=$((errors+1))
      fi
    fi
  done

  echo "Split directory of images into left and right halves complete, exported to $output_dir"
  [ $errors -eq 0 ] || return 1
}'  # Split directory of images into left and right halves

alias img-split-vertical-dir='() {
  if [ $# -eq 0 ]; then
    echo "Split directory of images into top and bottom halves."
    echo "Usage: img-split-vertical-dir <source_dir>"
    return 0
  fi

  _image_aliases_validate_dir "$1" || return 1

  local source_dir="$1"
  local output_dir="$source_dir/vertical_split"

  mkdir -p "$output_dir"
  local errors=0

  for img in "$source_dir"/*.(jpg|png|jpeg|bmp|heic); do
    if [ -f "$img" ]; then
      local base_name="$(basename "${img%.*}")"
      local ext="${img##*.}"
      if ! magick convert "$img" -crop 100%x50% +repage "$output_dir/${base_name}_%d.${ext}"; then
        echo "Error: Failed to split $img" >&2
        errors=$((errors+1))
      fi
    fi
  done

  echo "Split directory of images into top and bottom halves complete, exported to $output_dir"
  [ $errors -eq 0 ] || return 1
}'  # Split directory of images into top and bottom halves

# --------------------------------
# Image Merging
# --------------------------------

alias img-dir-to-pdf='() {
  if [ $# -eq 0 ]; then
    echo "Merge directory of images into PDF."
    echo "Usage: img-dir-to-pdf <source_dir> [output_pdf_name]"
    return 0
  fi

  _image_aliases_validate_dir "$1" || return 1

  local source_dir="$1"
  local folder_name="$(basename "$source_dir")"
  local output_pdf="${2:-$folder_name.pdf}"

  if magick convert "$source_dir"/*.(jpg|png|jpeg|bmp|heic) "$output_pdf"; then
    echo "Merged directory of images into PDF complete, exported to $output_pdf"
  else
    echo "Error: Failed to merge images to PDF." >&2
    return 1
  fi
}'  # Merge directory of images into PDF

alias img-to-pdf='() {
  if [ $# -eq 0 ]; then
    echo "Convert single image to PDF."
    echo "Usage: img-to-pdf <source_image> [output_pdf_name]"
    return 0
  fi

  _image_aliases_validate_file "$1" || return 1

  local source_path="$1"
  local output_pdf="${2:-${source_path%.*}.pdf}"

  if magick convert "$source_path" "$output_pdf"; then
    echo "Single image to PDF conversion complete, exported to $output_pdf"
  else
    echo "Error: Failed to convert image to PDF." >&2
    return 1
  fi
}'  # Convert single image to PDF

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
}'  # Add watermark to image

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

  for img in "$source_dir"/*.(jpg|png|jpeg|bmp|heic); do
    if [ -f "$img" ]; then
      local base_name="$(basename "$img")"
      if ! magick composite -dissolve "$opacity" -gravity "$position" "$watermark_path" "$img" "$output_dir/$base_name"; then
        echo "Error: Failed to add watermark to $img" >&2
        errors=$((errors+1))
      fi
    fi
  done

  echo "Batch watermarking complete, exported to $output_dir"
  [ $errors -eq 0 ] || return 1
}'  # Batch add watermark to images

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
}'  # Batch optimize images by size

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
}'  # Display basic information about image files

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
}'  # Extract EXIF metadata from image files

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
}'  # Crop an image to specified dimensions

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
}'  # Crop an image from the center

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
}'  # Compress an image while preserving dimensions

alias img-compress-dir='() {
  echo "Batch compress all images in a directory."
  echo "Usage: img-compress-dir [directory:.] [quality:75]"

  local dir="${1:-.}"
  local quality="${2:-75}"

  _image_aliases_check_imagemagick || return 1
  _image_aliases_validate_dir "$dir" || return 1

  local output_dir="$dir/compressed_q${quality}"
  local magick_cmd=$(_image_aliases_magick_cmd)

  mkdir -p "$output_dir"
  local errors=0

  find "$dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | while IFS= read -r img; do
    local base_name="$(basename "$img")"
    if ! $magick_cmd "$img" -quality "$quality" "$output_dir/$base_name"; then
      echo "Error: Failed to compress $img" >&2
      errors=$((errors+1))
    fi
  done

  echo "Batch compression complete, files saved to $output_dir"
  [ $errors -eq 0 ] || return 1
}'  # Batch compress all images in a directory

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
}'  # Join multiple images horizontally

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
}'  # Join multiple images vertically

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
}'  # Apply sepia tone effect to an image

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
}'  # Apply blur effect to an image

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

  echo "Renamed $((count-1-errors)) files with prefix '$prefix'"
  [ $errors -eq 0 ] || return 1
}'  # Rename images in a directory with sequential numbering

alias image-help='() {
  echo "Image Processing Aliases Help"
  echo "============================"
  echo "This module provides aliases for common image processing operations."
  echo
  echo "Basic Image Processing:"
  echo "  img-resize           - Resize image to specified dimensions"
  echo "  img-resize-dir       - Batch resize images in directory"
  echo
  echo "Preset Image Sizes:"
  echo "  img-resize-24        - Resize image(s) to 24px width"
  echo "  img-resize-28        - Resize image(s) to 28px width"
  echo "  img-resize-50        - Resize image(s) to 50px width"
  echo "  img-resize-100       - Resize image(s) to 100px width"
  echo "  img-resize-200       - Resize image(s) to 200px width"
  echo "  img-resize-512       - Resize image(s) to 512px width"
  echo "  img-resize-1024      - Resize image(s) to 1024px width"
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
  echo "  img-split-horizontal - Split image into left and right halves"
  echo "  img-split-vertical   - Split image into top and bottom halves"
  echo "  img-split-horizontal-dir - Split directory of images into left and right halves"
  echo "  img-split-vertical-dir - Split directory of images into top and bottom halves"
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
  echo "Batch Rename:"
  echo "  img-rename-sequential - Rename images in a directory with sequential numbering"
  echo
  echo "For more details about a specific command, just run the command without arguments."
}'  # Help function showing all available image processing aliases

alias img-help='() {
  image-help
}'  # Alias to call the help function

alias img-aliases='() {
  image-help
}'  # Alias to call the help function
