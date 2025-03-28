# Description: Image processing aliases for resizing, conversion, effects, manipulation and batch operations.

# --------------------------------
# Helper Functions
# --------------------------------

# Helper function for resizing images
_image_resize() {
  local source_path="$1"
  local size="$2"
  local quality="$3"

  if [ ! -f "$source_path" ]; then
    echo "Error: File \"$source_path\" not found." >&2
    return 1
  fi

  local target_path="${source_path%.*}_${size}_q${quality}.${source_path##*.}"

  if magick convert "$source_path" -resize "$size" -quality "$quality" "$target_path"; then
    echo "Resized image saved to $target_path"
    return 0
  else
    echo "Error: Failed to resize image." >&2
    return 1
  fi
}

# Helper function to validate image file existence
_image_validate_file() {
  if [ ! -f "$1" ]; then
    echo "Error: File \"$1\" not found." >&2
    return 1
  fi
  return 0
}

# Helper function to validate directory existence
_image_validate_dir() {
  if [ ! -d "$1" ]; then
    echo "Error: Directory \"$1\" not found." >&2
    return 1
  fi
  return 0
}

# --------------------------------
# Basic Image Processing
# --------------------------------

alias img_resize='() {
  if [ $# -eq 0 ]; then
    echo "Resize image to specified dimensions."
    echo "Usage: img_resize <image_path> [size:200x] [quality:80]"
    return 0
  fi

  _image_validate_file "$1" || return 1
  _image_resize "$1" "${2:-200x}" "${3:-80}"
}'  # Resize image to specified dimensions

alias img_resize_dir='() {
  if [ $# -lt 2 ]; then
    echo "Batch resize images in directory."
    echo "Usage: img_resize_dir <source_dir> <size> [quality:100]"
    return 0
  fi

  _image_validate_dir "$1" || return 1

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

alias img_resize_24='() {
  if [ $# -eq 0 ]; then
    echo "Resize image(s) to 24px width."
    echo "Usage: img_resize_24 <image_path> [more_files...]"
    return 0
  fi

  local status=0
  for img in "$@"; do
    _image_validate_file "$img" || { status=1; continue; }
    _image_resize "$img" "24x" "90"
  done
  return $status
}'  # Resize image(s) to 24px width

alias img_resize_28='() {
  if [ $# -eq 0 ]; then
    echo "Resize image(s) to 28px width."
    echo "Usage: img_resize_28 <image_path> [more_files...]"
    return 0
  fi

  local status=0
  for img in "$@"; do
    _image_validate_file "$img" || { status=1; continue; }
    _image_resize "$img" "28x" "90"
  done
  return $status
}'  # Resize image(s) to 28px width

alias img_resize_50='() {
  if [ $# -eq 0 ]; then
    echo "Resize image(s) to 50px width."
    echo "Usage: img_resize_50 <image_path> [more_files...]"
    return 0
  fi

  local status=0
  for img in "$@"; do
    _image_validate_file "$img" || { status=1; continue; }
    _image_resize "$img" "50x" "90"
  done
  return $status
}'  # Resize image(s) to 50px width

alias img_resize_100='() {
  if [ $# -eq 0 ]; then
    echo "Resize image(s) to 100px width."
    echo "Usage: img_resize_100 <image_path> [more_files...]"
    return 0
  fi

  local status=0
  for img in "$@"; do
    _image_validate_file "$img" || { status=1; continue; }
    _image_resize "$img" "100x" "90"
  done
  return $status
}'  # Resize image(s) to 100px width

alias img_resize_200='() {
  if [ $# -eq 0 ]; then
    echo "Resize image(s) to 200px width."
    echo "Usage: img_resize_200 <image_path> [more_files...]"
    return 0
  fi

  local status=0
  for img in "$@"; do
    _image_validate_file "$img" || { status=1; continue; }
    _image_resize "$img" "200x" "90"
  done
  return $status
}'  # Resize image(s) to 200px width

alias img_resize_512='() {
  if [ $# -eq 0 ]; then
    echo "Resize image(s) to 512px width."
    echo "Usage: img_resize_512 <image_path> [more_files...]"
    return 0
  fi

  local status=0
  for img in "$@"; do
    _image_validate_file "$img" || { status=1; continue; }
    _image_resize "$img" "512x" "90"
  done
  return $status
}'  # Resize image(s) to 512px width

alias img_resize_1024='() {
  if [ $# -eq 0 ]; then
    echo "Resize image(s) to 1024px width."
    echo "Usage: img_resize_1024 <image_path> [more_files...]"
    return 0
  fi

  local status=0
  for img in "$@"; do
    _image_validate_file "$img" || { status=1; continue; }
    _image_resize "$img" "1024x" "85"
  done
  return $status
}'  # Resize image(s) to 1024px width

# --------------------------------
# Format Conversion
# --------------------------------

alias img_convert_format='() {
  if [ $# -lt 2 ]; then
    echo "Convert image files to different format."
    echo "Usage: img_convert_format <source_dir> <new_extension>"
    return 0
  fi

  _image_validate_dir "$1" || return 1

  local source_dir="$1"
  local new_ext="$2"
  local count=0
  local errors=0

  for img in "$source_dir"/*.(jpg|png|jpeg|bmp|heic|tif|tiff); do
    if [ -f "$img" ]; then
      if magick convert "$img" "${img%.*}.$new_ext"; then
        echo "Converted: $img -> ${img%.*}.$new_ext"
        count=$((count+1))
      else
        echo "Error converting: $img" >&2
        errors=$((errors+1))
      fi
    fi
  done

  echo "Conversion complete: $count files converted, $errors errors"
  [ $errors -eq 0 ] || return 1
}'  # Convert image files to different format

# --------------------------------
# Image Effects
# --------------------------------

alias img_opacity='() {
  if [ $# -lt 2 ]; then
    echo "Adjust image opacity."
    echo "Usage: img_opacity <source_image> <opacity_percent:50>"
    return 0
  fi

  _image_validate_file "$1" || return 1

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

alias img_rotate='() {
  if [ $# -lt 2 ]; then
    echo "Rotate image."
    echo "Usage: img_rotate <source_image> <rotation_degrees:90>"
    return 0
  fi

  _image_validate_file "$1" || return 1

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

alias img_grayscale_binary='() {
  if [ $# -eq 0 ]; then
    echo "Convert image to grayscale and binarize."
    echo "Usage: img_grayscale_binary <source_image>"
    return 0
  fi

  _image_validate_file "$1" || return 1

  local source_path="$1"
  local target_path="${source_path%.*}_gray_binary.${source_path##*.}"

  if magick convert "$source_path" -colorspace Gray -threshold 50% "$target_path"; then
    echo "Grayscale and binarization complete, exported to $target_path"
  else
    echo "Error: Failed to convert image." >&2
    return 1
  fi
}'  # Convert image to grayscale and binarize

alias img_grayscale='() {
  if [ $# -eq 0 ]; then
    echo "Convert image to grayscale."
    echo "Usage: img_grayscale <source_image>"
    return 0
  fi

  _image_validate_file "$1" || return 1

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

alias img_grayscale_binary_dir='() {
  if [ $# -eq 0 ]; then
    echo "Convert directory of images to grayscale and binarize."
    echo "Usage: img_grayscale_binary_dir <source_dir>"
    return 0
  fi

  _image_validate_dir "$1" || return 1

  local source_dir="$1"
  local output_dir="$source_dir/gray_binary"

  mkdir -p "$output_dir"

  if magick mogrify -colorspace Gray -threshold 50% -path "$output_dir" "$source_dir"/*.(jpg|png|jpeg|bmp|heic) 2>/dev/null; then
    echo "Grayscale and binarization complete, exported to $output_dir"
  else
    echo "Warning: Some images may not have been processed correctly." >&2
  fi
}'  # Convert directory of images to grayscale and binarize

alias img_grayscale_dir='() {
  if [ $# -eq 0 ]; then
    echo "Convert directory of images to grayscale."
    echo "Usage: img_grayscale_dir <source_dir>"
    return 0
  fi

  _image_validate_dir "$1" || return 1

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

alias img_split_horizontal='() {
  if [ $# -eq 0 ]; then
    echo "Split image into left and right halves."
    echo "Usage: img_split_horizontal <source_image>"
    return 0
  fi

  _image_validate_file "$1" || return 1

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

alias img_split_vertical='() {
  if [ $# -eq 0 ]; then
    echo "Split image into top and bottom halves."
    echo "Usage: img_split_vertical <source_image>"
    return 0
  fi

  _image_validate_file "$1" || return 1

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

alias img_split_horizontal_dir='() {
  if [ $# -eq 0 ]; then
    echo "Split directory of images into left and right halves."
    echo "Usage: img_split_horizontal_dir <source_dir>"
    return 0
  fi

  _image_validate_dir "$1" || return 1

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

alias img_split_vertical_dir='() {
  if [ $# -eq 0 ]; then
    echo "Split directory of images into top and bottom halves."
    echo "Usage: img_split_vertical_dir <source_dir>"
    return 0
  fi

  _image_validate_dir "$1" || return 1

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

alias img_dir_to_pdf='() {
  if [ $# -eq 0 ]; then
    echo "Merge directory of images into PDF."
    echo "Usage: img_dir_to_pdf <source_dir> [output_pdf_name]"
    return 0
  fi

  _image_validate_dir "$1" || return 1

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

alias img_to_pdf='() {
  if [ $# -eq 0 ]; then
    echo "Convert single image to PDF."
    echo "Usage: img_to_pdf <source_image> [output_pdf_name]"
    return 0
  fi

  _image_validate_file "$1" || return 1

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

alias img_watermark='() {
  if [ $# -lt 2 ]; then
    echo "Add watermark to image."
    echo "Usage: img_watermark <source_image> <watermark_image> [position:southeast]"
    return 0
  fi

  _image_validate_file "$1" || return 1
  _image_validate_file "$2" || return 1

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

alias img_watermark_dir='() {
  if [ $# -lt 2 ]; then
    echo "Batch add watermark to images."
    echo "Usage: img_watermark_dir <watermark_image> <source_dir> [position:southeast] [opacity:100]"
    return 0
  fi

  _image_validate_file "$1" || return 1
  _image_validate_dir "$2" || return 1

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

alias img_optimize_batch='() {
  if [ $# -eq 0 ]; then
    echo "Batch optimize images by size."
    echo "Usage: img_optimize_batch [directory:.] [width:1024] [quality:85]"
    return 0
  fi

  local dir="${1:-.}"
  local width="${2:-1024}"
  local quality="${3:-85}"
  local processed=0
  local errors=0

  _image_validate_dir "$dir" || return 1

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
