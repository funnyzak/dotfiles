# Description: Image processing aliases for resizing, conversion, effects, manipulation and batch operations.

# --------------------------------
# Help Function
# --------------------------------

# --------------------------------
# Helper Functions
# --------------------------------

# Helper function to validate image file existence
_image_aliases_validate_file() {
  if [ $# -lt 1 ] || [ -z "$1" ]; then
    echo "Error: No file path provided for validation." >&2
    return 1
  fi

  if [ ! -f "$1" ]; then
    echo "Error: File \"$1\" not found." >&2
    return 1
  fi

  return 0
}

# Helper function to validate directory existence
_image_aliases_validate_dir() {
  if [ $# -lt 1 ] || [ -z "$1" ]; then
    echo "Error: No directory path provided for validation." >&2
    return 1
  fi

  if [ ! -d "$1" ]; then
    echo "Error: Directory \"$1\" not found." >&2
    return 1
  fi

  return 0
}

# Helper function to validate file or directory existence
_image_aliases_validate_path() {
  if [ $# -lt 1 ] || [ -z "$1" ]; then
    echo "Error: No path provided." >&2
    return 1
  fi

  if [ ! -e "$1" ]; then
    echo "Error: Path \"$1\" not found." >&2
    return 1
  fi

  return 0
}

# Helper function to check if ImageMagick is installed
_image_aliases_check_imagemagick() {
  if ! command -v magick > /dev/null 2>&1 && ! command -v convert > /dev/null 2>&1; then
    echo "Error: ImageMagick is not installed. Please install it first." >&2
    echo "  macOS: brew install imagemagick" >&2
    echo "  Linux: sudo apt-get install imagemagick" >&2
    return 1
  fi

  return 0
}

# Helper function to use correct ImageMagick command based on platform
_image_aliases_magick_cmd() {
  if command -v magick > /dev/null 2>&1; then
    echo "magick"
  else
    echo "convert"
  fi
}

# Print image paths as NUL-delimited entries for safe iteration.
_image_aliases_print_image_paths() {
  local source_path="$1"
  local recursive="${2:-false}"
  local exclude_dir="${3:-}"
  local -a find_args

  if [ -f "$source_path" ]; then
    printf "%s\0" "$source_path"
    return 0
  fi

  if [ ! -d "$source_path" ]; then
    echo "Error: Path \"$source_path\" is neither a valid file nor a directory." >&2
    return 1
  fi

  find_args=("$source_path")
  if [ "$recursive" != "true" ]; then
    find_args+=(-maxdepth 1)
  fi

  if [ -n "$exclude_dir" ]; then
    find_args+=("(" -path "$exclude_dir" -o -path "$exclude_dir/*" ")" -prune -o)
  fi

  find_args+=(
    -type f
    "("
    -iname "*.jpg" -o
    -iname "*.jpeg" -o
    -iname "*.png" -o
    -iname "*.bmp" -o
    -iname "*.heic" -o
    -iname "*.tif" -o
    -iname "*.tiff" -o
    -iname "*.gif" -o
    -iname "*.webp"
    ")"
    -print0
  )

  find "${find_args[@]}"
}

# Build mirrored output file path for directory processing.
_image_aliases_dir_output_file() {
  local source_dir="$1"
  local image_path="$2"
  local output_root="$3"
  local output_ext="${4:-${image_path##*.}}"
  local suffix="${5:-}"
  local rel_path="${image_path#$source_dir/}"
  local rel_dir="$(dirname "$rel_path")"
  local base_name="$(basename "$image_path")"
  local stem="${base_name%.*}"
  local target_dir="$output_root"

  if [ "$rel_dir" != "." ]; then
    target_dir="$target_dir/$rel_dir"
  fi

  if ! mkdir -p "$target_dir"; then
    echo "Error: Failed to create output directory \"$target_dir\"." >&2
    return 1
  fi

  printf "%s/%s%s.%s\n" "$target_dir" "$stem" "$suffix" "${output_ext#.}"
}

# Build mirrored output directory path for per-image folder output.
_image_aliases_dir_output_dir() {
  local source_dir="$1"
  local image_path="$2"
  local output_root="$3"
  local leaf_dir="${4:-}"
  local rel_path="${image_path#$source_dir/}"
  local rel_dir="$(dirname "$rel_path")"
  local target_dir="$output_root"

  if [ "$rel_dir" != "." ]; then
    target_dir="$target_dir/$rel_dir"
  fi

  if [ -n "$leaf_dir" ]; then
    target_dir="$target_dir/$leaf_dir"
  fi

  if ! mkdir -p "$target_dir"; then
    echo "Error: Failed to create output directory \"$target_dir\"." >&2
    return 1
  fi

  printf "%s\n" "$target_dir"
}

# Convert page size name to geometry. Returns 1 on unknown size while still falling back to A4.
_image_aliases_page_geometry() {
  local page_size="${1:-A4}"

  case "$page_size" in
    A4|a4)
      echo "595x842"
      ;;
    A3|a3)
      echo "842x1191"
      ;;
    A5|a5)
      echo "420x595"
      ;;
    Letter|letter)
      echo "612x792"
      ;;
    Legal|legal)
      echo "612x1008"
      ;;
    Tabloid|tabloid)
      echo "792x1224"
      ;;
    *)
      echo "595x842"
      return 1
      ;;
  esac

  return 0
}

# Convert arbitrary labels into safe path fragments.
_image_aliases_safe_label() {
  printf "%s" "$1" | tr "[:upper:]" "[:lower:]" | sed "s/[^[:alnum:]]\+/_/g; s/^_//; s/_$//"
}

_image_aliases_resize_image() {
  local source_path="$1"
  local size="$2"
  local quality="$3"
  local target_path="$4"
  local magick_cmd=$(_image_aliases_magick_cmd)

  $magick_cmd "$source_path" -resize "$size" -quality "$quality" "$target_path"
}

_image_aliases_split_file() {
  local image_path="$1"
  local grid_dim="$2"
  local output_dir="$3"
  local output_format="${4:-${image_path##*.}}"
  local magick_cmd=$(_image_aliases_magick_cmd)
  local dimensions
  local width
  local height
  local grid_x
  local grid_y
  local tile_width
  local tile_height
  local base_name

  dimensions=$($magick_cmd identify -format "%wx%h" "$image_path" 2>/dev/null)
  if [ $? -ne 0 ] || [ -z "$dimensions" ]; then
    echo "Error: Failed to get dimensions of $image_path" >&2
    return 1
  fi

  width="${dimensions%x*}"
  height="${dimensions#*x}"
  grid_x="${grid_dim%x*}"
  grid_y="${grid_dim#*x}"
  tile_width=$((width / grid_x))
  tile_height=$((height / grid_y))
  base_name="$(basename "$image_path" ".${image_path##*.}")"

  if ! mkdir -p "$output_dir"; then
    echo "Error: Failed to create output directory \"$output_dir\"." >&2
    return 1
  fi

  $magick_cmd "$image_path" -crop "${tile_width}x${tile_height}" \
    -set filename:tile "%[fx:page.x/${tile_width}+1]_%[fx:page.y/${tile_height}+1]" \
    "$output_dir/${base_name}_%[filename:tile].${output_format#.}"
}

_image_aliases_apply_background() {
  local source_path="$1"
  local mode="$2"
  local background_value="$3"
  local target_path="$4"
  local magick_cmd=$(_image_aliases_magick_cmd)
  local dimensions

  dimensions=$($magick_cmd identify -format "%wx%h" "$source_path" 2>/dev/null)
  if [ $? -ne 0 ] || [ -z "$dimensions" ]; then
    echo "Error: Failed to get dimensions of \"$source_path\"." >&2
    return 1
  fi

  if [ "$mode" = "image" ]; then
    $magick_cmd "$background_value" -resize "$dimensions^" -gravity center -extent "$dimensions" \
      "$source_path" -gravity center -composite "$target_path"
    return $?
  fi

  $magick_cmd -size "$dimensions" "canvas:$background_value" \
    "$source_path" -gravity center -composite "$target_path"
}

_image_aliases_trim_geometry() {
  local source_path="$1"
  local trim_mode="${2:-auto}"
  local fuzz_value="${3:-8%}"
  local magick_cmd=$(_image_aliases_magick_cmd)
  local effective_mode="$trim_mode"
  local image_opaque=""
  local crop_geometry=""

  if [ "$effective_mode" = "auto" ]; then
    image_opaque=$($magick_cmd identify -format "%[opaque]" "$source_path" 2>/dev/null)
    if [ "$image_opaque" = "False" ]; then
      effective_mode="transparent"
    else
      effective_mode="white"
    fi
  fi

  case "$effective_mode" in
    white)
      crop_geometry=$(
        $magick_cmd "$source_path" \
          -alpha off \
          -fuzz "$fuzz_value" \
          -transparent white \
          -alpha extract \
          -morphology Open Diamond:1 \
          -trim \
          -format "%wx%h%X%Y" \
          info: 2>/dev/null
      )
      ;;
    transparent)
      crop_geometry=$(
        $magick_cmd "$source_path" \
          -alpha extract \
          -morphology Open Diamond:1 \
          -trim \
          -format "%wx%h%X%Y" \
          info: 2>/dev/null
      )
      ;;
    *)
      echo "Error: Unsupported trim mode \"$trim_mode\"." >&2
      return 1
      ;;
  esac

  if ! echo "$crop_geometry" | grep -qE "^[0-9]+x[0-9]+[+][0-9]+[+][0-9]+$"; then
    crop_geometry=$($magick_cmd identify -format "%wx%h+0+0" "$source_path" 2>/dev/null)
  fi

  if [ -z "$crop_geometry" ]; then
    echo "Error: Failed to determine crop geometry for \"$source_path\"." >&2
    return 1
  fi

  printf "%s\n" "$crop_geometry"
}

_image_aliases_trim_apply() {
  local source_path="$1"
  local target_path="$2"
  local trim_mode="${3:-auto}"
  local fuzz_value="${4:-8%}"
  local margin_size="${5:-0}"
  local margin_color="${6:-white}"
  local magick_cmd=$(_image_aliases_magick_cmd)
  local crop_geometry=""
  local -a trim_args

  crop_geometry=$(_image_aliases_trim_geometry "$source_path" "$trim_mode" "$fuzz_value") || return 1

  trim_args=("$source_path" -crop "$crop_geometry" +repage)
  if [ "$margin_size" -gt 0 ]; then
    trim_args+=(-bordercolor "$margin_color" -border "${margin_size}x${margin_size}")
  fi

  $magick_cmd "${trim_args[@]}" "$target_path"
}

_image_aliases_trim_types_pattern() {
  local types_value="${1:-jpg,jpeg,png,gif,bmp,webp,heic,tif,tiff}"

  printf "%s" "$types_value" \
    | tr "[:upper:]" "[:lower:]" \
    | sed "s/[[:space:]]//g; s/[.]//g; s/^,*//; s/,*$//; s/,,*/,/g; s/,/|/g"
}

_image_aliases_trim_command() {
  if [ $# -eq 0 ]; then
    echo "Automatically trim white or transparent borders from a file or directory of images."
    echo "Usage: img-autocrop <image_or_dir> [options]"
    echo "Options:"
    echo "  -m, --mode <auto|white|transparent>  Trim mode (default: auto)"
    echo "  -f, --fuzz <percent>                 Color tolerance for trim (default: 8%)"
    echo "  -b, --margin <pixels>                Add margin after trim (default: 0)"
    echo "  -c, --margin-color <color>           Margin color (default: white or none)"
    echo "  -t, --types <exts>                   Directory source extensions, comma-separated"
    echo "  -F, --format <ext>                   Output format override, for example png"
    echo "  -s, --suffix <text>                  Output filename suffix"
    echo "  -o, --output <path>                  File output path or directory output root"
    echo "  -r, --recursive                      Include subdirectories when source is a directory"
    echo "  -h, --help                           Show this help message"
    echo ""
    echo "Examples:"
    echo "  img-autocrop logo.png"
    echo "  img-autocrop scan.jpg -m white -f 12%"
    echo "  img-autocrop ./screenshots -t png,webp -r"
    echo "  img-autocrop ./assets -m transparent -b 12 -F png -o ./trimmed"
    return 0
  fi

  local source_path=""
  local trim_mode="auto"
  local fuzz_value="8"
  local margin_size="0"
  local margin_color=""
  local types_value="jpg,jpeg,png,gif,bmp,webp,heic,tif,tiff"
  local output_format=""
  local suffix=""
  local output_path=""
  local recursive=false
  local processed=0
  local errors=0
  local found=0
  local target_path=""
  local output_root=""
  local types_pattern=""
  local normalized_source_path=""
  local normalized_output_root=""
  local -a find_args

  while [ $# -gt 0 ]; do
    case "$1" in
      -m|--mode)
        if [ $# -lt 2 ]; then
          echo "Error: Missing value for $1." >&2
          return 1
        fi
        trim_mode="$2"
        shift 2
        ;;
      -f|--fuzz)
        if [ $# -lt 2 ]; then
          echo "Error: Missing value for $1." >&2
          return 1
        fi
        fuzz_value="$2"
        shift 2
        ;;
      -b|--margin)
        if [ $# -lt 2 ]; then
          echo "Error: Missing value for $1." >&2
          return 1
        fi
        margin_size="$2"
        shift 2
        ;;
      -c|--margin-color)
        if [ $# -lt 2 ]; then
          echo "Error: Missing value for $1." >&2
          return 1
        fi
        margin_color="$2"
        shift 2
        ;;
      -t|--types)
        if [ $# -lt 2 ]; then
          echo "Error: Missing value for $1." >&2
          return 1
        fi
        types_value="$2"
        shift 2
        ;;
      -F|--format)
        if [ $# -lt 2 ]; then
          echo "Error: Missing value for $1." >&2
          return 1
        fi
        output_format="$2"
        shift 2
        ;;
      -s|--suffix)
        if [ $# -lt 2 ]; then
          echo "Error: Missing value for $1." >&2
          return 1
        fi
        suffix="$2"
        shift 2
        ;;
      -o|--output)
        if [ $# -lt 2 ]; then
          echo "Error: Missing value for $1." >&2
          return 1
        fi
        output_path="$2"
        shift 2
        ;;
      -r|--recursive)
        recursive=true
        shift
        ;;
      -h|--help)
        _image_aliases_trim_command
        return 0
        ;;
      *)
        if [ -z "$source_path" ]; then
          source_path="$1"
        else
          echo "Error: Unknown argument \"$1\"." >&2
          return 1
        fi
        shift
        ;;
    esac
  done

  if [ -z "$source_path" ]; then
    echo "Error: Image or directory path is required." >&2
    return 1
  fi

  case "$trim_mode" in
    auto|white|transparent)
      ;;
    *)
      echo "Error: Unsupported trim mode \"$trim_mode\". Use auto, white, or transparent." >&2
      return 1
      ;;
  esac

  if ! echo "$fuzz_value" | grep -qE "^[0-9]+([.][0-9]+)?%?$"; then
    echo "Error: Invalid fuzz value \"$fuzz_value\". Use values like 5, 8%, or 12.5%." >&2
    return 1
  fi
  if [[ "$fuzz_value" != *% ]]; then
    fuzz_value="${fuzz_value}%"
  fi

  if ! echo "$margin_size" | grep -qE "^[0-9]+$"; then
    echo "Error: Margin must be a non-negative integer." >&2
    return 1
  fi

  if [ -n "$output_format" ]; then
    output_format="$(printf "%s" "$output_format" | tr "[:upper:]" "[:lower:]")"
    output_format="${output_format#.}"
    if ! echo "$output_format" | grep -qE "^[a-z0-9]+$"; then
      echo "Error: Invalid output format \"$output_format\"." >&2
      return 1
    fi
  fi

  types_pattern=$(_image_aliases_trim_types_pattern "$types_value")
  if [ -z "$types_pattern" ]; then
    echo "Error: At least one file extension is required for --types." >&2
    return 1
  fi

  _image_aliases_check_imagemagick || return 1
  _image_aliases_validate_path "$source_path" || return 1

  if [ -z "$margin_color" ]; then
    if [ "$trim_mode" = "transparent" ]; then
      margin_color="none"
    else
      margin_color="white"
    fi
  fi

  if [ -f "$source_path" ]; then
    local file_suffix="${suffix:-_trimmed}"
    local source_name="$(basename "$source_path")"
    local source_stem="${source_name%.*}"
    local file_ext="${output_format:-${source_path##*.}}"

    if [ -n "$output_path" ]; then
      if [ -d "$output_path" ] || [ "${output_path%/}" != "$output_path" ]; then
        local output_dir="${output_path%/}"
        if [ -z "$output_dir" ]; then
          output_dir="$output_path"
        fi

        if ! mkdir -p "$output_dir"; then
          echo "Error: Failed to create output directory \"$output_dir\"." >&2
          return 1
        fi

        target_path="$output_dir/${source_stem}${file_suffix}.${file_ext#.}"
      else
        target_path="$output_path"
      fi
    else
      target_path="${source_path%.*}${file_suffix}.${file_ext#.}"
    fi

    if _image_aliases_trim_apply "$source_path" "$target_path" "$trim_mode" "$fuzz_value" "$margin_size" "$margin_color"; then
      echo "Trimmed image saved to $target_path"
      return 0
    fi

    echo "Error: Failed to trim \"$source_path\"." >&2
    return 1
  fi

  output_root="${output_path:-$source_path/trimmed_${trim_mode}}"
  normalized_source_path="${source_path:A}"
  normalized_output_root="${output_root:A}"
  if [ "$normalized_output_root" = "$normalized_source_path" ]; then
    echo "Error: Output directory must be different from source directory." >&2
    return 1
  fi

  find_args=("$source_path")
  if [ "$recursive" != "true" ]; then
    find_args+=(-maxdepth 1)
  fi
  find_args+=("(" -path "$output_root" -o -path "$output_root/*" ")" -prune -o -type f -print0)

  while IFS= read -r -d "" img; do
    local img_ext="${img##*.}"
    local normalized_ext="$(printf "%s" "$img_ext" | tr "[:upper:]" "[:lower:]")"

    if ! echo "$normalized_ext" | grep -qE "^(${types_pattern})$"; then
      continue
    fi

    found=$((found + 1))
    target_path=$(_image_aliases_dir_output_file "$source_path" "$img" "$output_root" "$output_format" "$suffix") || {
      errors=$((errors + 1))
      continue
    }

    if _image_aliases_trim_apply "$img" "$target_path" "$trim_mode" "$fuzz_value" "$margin_size" "$margin_color"; then
      echo "Processed: $img -> $target_path"
      processed=$((processed + 1))
    else
      echo "Error: Failed to trim $img" >&2
      errors=$((errors + 1))
    fi
  done < <(find "${find_args[@]}")

  if [ "$found" -eq 0 ]; then
    echo "Error: No image files matched the requested input." >&2
    return 1
  fi

  echo "Trim complete: $processed file(s) processed, $errors error(s)"
  echo "Output saved to: $output_root"
  [ "$errors" -eq 0 ]
}

_image_aliases_resize_command() {
  if [ $# -eq 0 ]; then
    echo "Resize image or directory of images."
    echo "Usage: img-resize <image_or_dir> [options]"
    echo "Options:"
    echo "  -s, --size <dimensions>   Target dimensions (default: 200x)"
    echo "  -q, --quality <percent>   Output quality (default: 80)"
    echo "  -o, --output <path>       File output path or directory output root"
    echo "  -r, --recursive           Include subdirectories when source is a directory"
    echo "  -h, --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  img-resize photo.jpg -s 800x600 -q 90"
    echo "  img-resize ./photos -s 1600x -r"
    echo "  img-resize ./photos -s 1200x -o ./exports/resized"
    return 0
  fi

  local source_path=""
  local size="200x"
  local quality="80"
  local output_path=""
  local recursive=false
  local processed=0
  local errors=0
  local found=0
  local target_path=""

  while [ $# -gt 0 ]; do
    case "$1" in
      -s|--size)
        if [ $# -lt 2 ]; then
          echo "Error: Missing value for $1." >&2
          return 1
        fi
        size="$2"
        shift 2
        ;;
      -q|--quality)
        if [ $# -lt 2 ]; then
          echo "Error: Missing value for $1." >&2
          return 1
        fi
        quality="$2"
        shift 2
        ;;
      -o|--output)
        if [ $# -lt 2 ]; then
          echo "Error: Missing value for $1." >&2
          return 1
        fi
        output_path="$2"
        shift 2
        ;;
      -r|--recursive)
        recursive=true
        shift
        ;;
      -h|--help)
        _image_aliases_resize_command
        return 0
        ;;
      *)
        if [ -z "$source_path" ]; then
          source_path="$1"
        else
          echo "Error: Unknown argument \"$1\"." >&2
          return 1
        fi
        shift
        ;;
    esac
  done

  if [ -z "$source_path" ]; then
    echo "Error: Image or directory path is required." >&2
    return 1
  fi

  _image_aliases_check_imagemagick || return 1
  _image_aliases_validate_path "$source_path" || return 1

  if [ -f "$source_path" ]; then
    target_path="${output_path:-${source_path%.*}_${size}_q${quality}.${source_path##*.}}"
    if _image_aliases_resize_image "$source_path" "$size" "$quality" "$target_path"; then
      echo "Resized image saved to $target_path"
      return 0
    fi

    echo "Error: Failed to resize image \"$source_path\"." >&2
    return 1
  fi

  local output_root="${output_path:-$source_path/resized_${size}_q${quality}}"
  if [ "$output_root" = "$source_path" ]; then
    echo "Error: Output directory must be different from source directory." >&2
    return 1
  fi

  if ! mkdir -p "$output_root"; then
    echo "Error: Failed to create output directory \"$output_root\"." >&2
    return 1
  fi

  while IFS= read -r -d "" img; do
    found=$((found + 1))
    target_path=$(_image_aliases_dir_output_file "$source_path" "$img" "$output_root") || {
      errors=$((errors + 1))
      continue
    }

    if _image_aliases_resize_image "$img" "$size" "$quality" "$target_path"; then
      echo "Processed: $img -> $target_path"
      processed=$((processed + 1))
    else
      echo "Error: Failed to resize $img" >&2
      errors=$((errors + 1))
    fi
  done < <(_image_aliases_print_image_paths "$source_path" "$recursive" "$output_root")

  if [ "$found" -eq 0 ]; then
    echo "Error: No image files found in $source_path" >&2
    return 1
  fi

  echo "Resize complete: $processed file(s) processed, $errors error(s)"
  echo "Output saved to: $output_root"
  [ "$errors" -eq 0 ]
}

_image_aliases_grayscale_command() {
  local mode="$1"
  shift

  local help_name="img-grayscale"
  local output_dir_name="gray"
  local suffix="_gray"
  local -a magick_args
  if [ "$mode" = "binary" ]; then
    help_name="img-grayscale-binary"
    output_dir_name="gray_binary"
    suffix="_gray_binary"
    magick_args=(-colorspace Gray -threshold 50%)
  else
    magick_args=(-colorspace Gray)
  fi

  if [ $# -eq 0 ]; then
    echo "Convert image or directory of images to grayscale."
    if [ "$mode" = "binary" ]; then
      echo "Binary thresholding is enabled for this command."
    fi
    echo "Usage: $help_name <image_or_dir> [options]"
    echo "Options:"
    echo "  -o, --output <path>       File output path or directory output root"
    echo "  -r, --recursive           Include subdirectories when source is a directory"
    echo "  -h, --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $help_name photo.jpg"
    echo "  $help_name ./photos"
    echo "  $help_name ./photos -r -o ./exports/$output_dir_name"
    return 0
  fi

  local source_path=""
  local output_path=""
  local recursive=false
  local processed=0
  local errors=0
  local found=0
  local target_path=""
  local magick_cmd=$(_image_aliases_magick_cmd)

  while [ $# -gt 0 ]; do
    case "$1" in
      -o|--output)
        if [ $# -lt 2 ]; then
          echo "Error: Missing value for $1." >&2
          return 1
        fi
        output_path="$2"
        shift 2
        ;;
      -r|--recursive)
        recursive=true
        shift
        ;;
      -h|--help)
        _image_aliases_grayscale_command "$mode"
        return 0
        ;;
      *)
        if [ -z "$source_path" ]; then
          source_path="$1"
        else
          echo "Error: Unknown argument \"$1\"." >&2
          return 1
        fi
        shift
        ;;
    esac
  done

  if [ -z "$source_path" ]; then
    echo "Error: Image or directory path is required." >&2
    return 1
  fi

  _image_aliases_check_imagemagick || return 1
  _image_aliases_validate_path "$source_path" || return 1

  if [ -f "$source_path" ]; then
    target_path="${output_path:-${source_path%.*}${suffix}.${source_path##*.}}"
    if $magick_cmd "$source_path" "${magick_args[@]}" "$target_path"; then
      echo "Converted image saved to $target_path"
      return 0
    fi

    echo "Error: Failed to convert \"$source_path\"." >&2
    return 1
  fi

  local output_root="${output_path:-$source_path/$output_dir_name}"
  if [ "$output_root" = "$source_path" ]; then
    echo "Error: Output directory must be different from source directory." >&2
    return 1
  fi

  if ! mkdir -p "$output_root"; then
    echo "Error: Failed to create output directory \"$output_root\"." >&2
    return 1
  fi

  while IFS= read -r -d "" img; do
    found=$((found + 1))
    target_path=$(_image_aliases_dir_output_file "$source_path" "$img" "$output_root") || {
      errors=$((errors + 1))
      continue
    }

    if $magick_cmd "$img" "${magick_args[@]}" "$target_path"; then
      echo "Processed: $img -> $target_path"
      processed=$((processed + 1))
    else
      echo "Error: Failed to convert $img" >&2
      errors=$((errors + 1))
    fi
  done < <(_image_aliases_print_image_paths "$source_path" "$recursive" "$output_root")

  if [ "$found" -eq 0 ]; then
    echo "Error: No image files found in $source_path" >&2
    return 1
  fi

  echo "Conversion complete: $processed file(s) processed, $errors error(s)"
  echo "Output saved to: $output_root"
  [ "$errors" -eq 0 ]
}

_image_aliases_split_command() {
  if [ $# -eq 0 ]; then
    echo "Split image files using a grid definition."
    echo "Usage: img-split <image_or_dir> [more_sources...] [options]"
    echo "Options:"
    echo "  -g, --grid <NxM>         Grid dimensions (default: 2x1)"
    echo "  -f, --format <ext>       Output format (default: keep source format)"
    echo "  -o, --output <dir>       Output root directory"
    echo "  -p, --pattern <regex>    File extension filter for directory sources"
    echo "  -r, --recursive          Include subdirectories when source is a directory"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  img-split image.jpg -g 3x2"
    echo "  img-split ./images -g 3x2 -r"
    echo "  img-split image1.jpg ./icons -o ./split_output"
    return 0
  fi

  _image_aliases_check_imagemagick || return 1

  local grid_dim="2x1"
  local output_dir=""
  local output_format=""
  local pattern="jpg|jpeg|png|gif|bmp|webp|heic|tif|tiff"
  local recursive=false
  local -a sources
  local processed=0
  local errors=0
  local found=0
  local img=""
  local source=""
  local output_root=""
  local image_output_dir=""

  sources=()
  while [ $# -gt 0 ]; do
    case "$1" in
      -g|--grid)
        if [ $# -lt 2 ]; then
          echo "Error: Missing value for $1." >&2
          return 1
        fi
        grid_dim="$2"
        shift 2
        ;;
      -f|--format)
        if [ $# -lt 2 ]; then
          echo "Error: Missing value for $1." >&2
          return 1
        fi
        output_format="$2"
        shift 2
        ;;
      -o|--output)
        if [ $# -lt 2 ]; then
          echo "Error: Missing value for $1." >&2
          return 1
        fi
        output_dir="$2"
        shift 2
        ;;
      -p|--pattern)
        if [ $# -lt 2 ]; then
          echo "Error: Missing value for $1." >&2
          return 1
        fi
        pattern="$2"
        shift 2
        ;;
      -r|--recursive)
        recursive=true
        shift
        ;;
      -h|--help)
        _image_aliases_split_command
        return 0
        ;;
      *)
        sources+=("$1")
        shift
        ;;
    esac
  done

  if ! echo "$grid_dim" | grep -qE "^[0-9]+x[0-9]+$"; then
    echo "Error: Invalid grid dimensions format. Use NxM, for example 2x1." >&2
    return 1
  fi

  if [ ${#sources[@]} -eq 0 ]; then
    echo "Error: At least one image file or directory is required." >&2
    return 1
  fi

  for source in "${sources[@]}"; do
    _image_aliases_validate_path "$source" || {
      errors=$((errors + 1))
      continue
    }

    if [ -f "$source" ]; then
      found=$((found + 1))
      if [ -n "$output_dir" ]; then
        image_output_dir="$output_dir"
        if [ ${#sources[@]} -gt 1 ]; then
          image_output_dir="$output_dir/$(basename "$source" ".${source##*.}")"
        fi
      else
        image_output_dir="$(dirname "$source")/split-$(basename "$source" ".${source##*.}")"
      fi

      if _image_aliases_split_file "$source" "$grid_dim" "$image_output_dir" "$output_format"; then
        echo "Split $source into $grid_dim parts, saved to $image_output_dir"
        processed=$((processed + 1))
      else
        errors=$((errors + 1))
      fi
      continue
    fi

    output_root="${output_dir:-$source/split_${grid_dim}}"
    if [ -n "$output_dir" ] && [ ${#sources[@]} -gt 1 ]; then
      output_root="$output_dir/$(basename "$source")"
    fi

    while IFS= read -r -d "" img; do
      local img_ext="${img##*.}"
      local img_name="$(printf "%s" "$img_ext" | tr "[:upper:]" "[:lower:]")"
      if ! echo "$img_name" | grep -qE "^(${pattern})$"; then
        continue
      fi

      found=$((found + 1))
      image_output_dir=$(_image_aliases_dir_output_dir "$source" "$img" "$output_root" "$(basename "$img" ".${img##*.}")") || {
        errors=$((errors + 1))
        continue
      }

      if _image_aliases_split_file "$img" "$grid_dim" "$image_output_dir" "$output_format"; then
        echo "Split $img into $grid_dim parts, saved to $image_output_dir"
        processed=$((processed + 1))
      else
        errors=$((errors + 1))
      fi
    done < <(_image_aliases_print_image_paths "$source" "$recursive" "$output_root")
  done

  if [ "$found" -eq 0 ]; then
    echo "Error: No image files matched the requested input." >&2
    return 1
  fi

  echo "Split complete: $processed source image(s) processed, $errors error(s)"
  [ "$errors" -eq 0 ]
}

_image_aliases_to_pdf_command() {
  if [ $# -eq 0 ]; then
    echo "Convert a single image or a directory of images to PDF."
    echo "Usage: img-to-pdf <image_or_dir> [options] [output_pdf] [page_size]"
    echo "Options:"
    echo "  -o, --output <pdf_path>   Output PDF path"
    echo "  -p, --page-size <size>    A4, A3, A5, Letter, Legal, Tabloid (default: A4)"
    echo "  -r, --recursive           Include subdirectories when source is a directory"
    echo "  -h, --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  img-to-pdf image.jpg"
    echo "  img-to-pdf ./photos -o photos.pdf"
    echo "  img-to-pdf ./photos -r -p Letter"
    return 0
  fi

  local source_path=""
  local output_pdf=""
  local page_size="A4"
  local recursive=false
  local -a positional
  local -a image_files
  local -a magick_args
  local page_geometry=""
  local magick_cmd=$(_image_aliases_magick_cmd)

  positional=()
  while [ $# -gt 0 ]; do
    case "$1" in
      -o|--output)
        if [ $# -lt 2 ]; then
          echo "Error: Missing value for $1." >&2
          return 1
        fi
        output_pdf="$2"
        shift 2
        ;;
      -p|--page-size)
        if [ $# -lt 2 ]; then
          echo "Error: Missing value for $1." >&2
          return 1
        fi
        page_size="$2"
        shift 2
        ;;
      -r|--recursive)
        recursive=true
        shift
        ;;
      -h|--help)
        _image_aliases_to_pdf_command
        return 0
        ;;
      *)
        positional+=("$1")
        shift
        ;;
    esac
  done

  if [ ${#positional[@]} -lt 1 ]; then
    echo "Error: Image file or directory path is required." >&2
    return 1
  fi

  source_path="${positional[1]}"
  if [ -z "$output_pdf" ] && [ ${#positional[@]} -ge 2 ]; then
    output_pdf="${positional[2]}"
  fi
  if [ ${#positional[@]} -ge 3 ]; then
    page_size="${positional[3]}"
  fi

  _image_aliases_check_imagemagick || return 1
  _image_aliases_validate_path "$source_path" || return 1

  page_geometry=$(_image_aliases_page_geometry "$page_size")
  if [ $? -ne 0 ]; then
    echo "Warning: Unknown page size \"$page_size\", using A4 as default."
    page_size="A4"
  fi

  if [ -f "$source_path" ]; then
    output_pdf="${output_pdf:-${source_path%.*}.pdf}"
    echo "Using page size: $page_size ($page_geometry)"
    if $magick_cmd "$source_path" -resize "${page_geometry}>" -gravity center -extent "$page_geometry" -background white "$output_pdf"; then
      echo "PDF saved to $output_pdf"
      return 0
    fi

    echo "Error: Failed to convert \"$source_path\" to PDF." >&2
    return 1
  fi

  output_pdf="${output_pdf:-$(basename "$source_path").pdf}"
  image_files=()
  while IFS= read -r -d "" img; do
    image_files+=("$img")
  done < <(_image_aliases_print_image_paths "$source_path" "$recursive")

  if [ ${#image_files[@]} -eq 0 ]; then
    echo "Error: No image files found in $source_path" >&2
    return 1
  fi

  image_files=("${(on)image_files[@]}")
  magick_args=()
  for img in "${image_files[@]}"; do
    magick_args+=("$img" -resize "${page_geometry}>" -gravity center -extent "$page_geometry" -background white)
  done

  echo "Found ${#image_files[@]} images to merge."
  echo "Using page size: $page_size ($page_geometry)"
  if $magick_cmd "${magick_args[@]}" "$output_pdf"; then
    echo "PDF saved to $output_pdf"
    return 0
  fi

  echo "Error: Failed to merge images into PDF." >&2
  return 1
}

_image_aliases_watermark_command() {
  if [ $# -eq 0 ]; then
    echo "Add a watermark to a single image or a directory of images."
    echo "Usage: img-watermark <image_or_dir> <watermark_image> [options]"
    echo "Options:"
    echo "  -p, --position <gravity>  Watermark position (default: southeast)"
    echo "  -a, --opacity <percent>   Watermark opacity (default: 100)"
    echo "  -o, --output <path>       File output path or directory output root"
    echo "  -r, --recursive           Include subdirectories when source is a directory"
    echo "  -h, --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  img-watermark photo.jpg logo.png"
    echo "  img-watermark ./photos logo.png -a 60 -r"
    return 0
  fi

  local source_path=""
  local watermark_path=""
  local position="southeast"
  local opacity="100"
  local output_path=""
  local recursive=false
  local processed=0
  local errors=0
  local found=0
  local target_path=""
  local magick_cmd=$(_image_aliases_magick_cmd)

  while [ $# -gt 0 ]; do
    case "$1" in
      -p|--position)
        if [ $# -lt 2 ]; then
          echo "Error: Missing value for $1." >&2
          return 1
        fi
        position="$2"
        shift 2
        ;;
      -a|--opacity)
        if [ $# -lt 2 ]; then
          echo "Error: Missing value for $1." >&2
          return 1
        fi
        opacity="$2"
        shift 2
        ;;
      -o|--output)
        if [ $# -lt 2 ]; then
          echo "Error: Missing value for $1." >&2
          return 1
        fi
        output_path="$2"
        shift 2
        ;;
      -r|--recursive)
        recursive=true
        shift
        ;;
      -h|--help)
        _image_aliases_watermark_command
        return 0
        ;;
      *)
        if [ -z "$source_path" ]; then
          source_path="$1"
        elif [ -z "$watermark_path" ]; then
          watermark_path="$1"
        else
          echo "Error: Unknown argument \"$1\"." >&2
          return 1
        fi
        shift
        ;;
    esac
  done

  if [ -z "$source_path" ] || [ -z "$watermark_path" ]; then
    echo "Error: Source path and watermark image are required." >&2
    return 1
  fi

  _image_aliases_check_imagemagick || return 1
  _image_aliases_validate_path "$source_path" || return 1
  _image_aliases_validate_file "$watermark_path" || return 1

  if [ -f "$source_path" ]; then
    target_path="${output_path:-${source_path%.*}_watermarked.${source_path##*.}}"
    if $magick_cmd composite -dissolve "$opacity" -gravity "$position" "$watermark_path" "$source_path" "$target_path"; then
      echo "Watermarked image saved to $target_path"
      return 0
    fi

    echo "Error: Failed to add watermark to \"$source_path\"." >&2
    return 1
  fi

  local output_root="${output_path:-$source_path/watermarked}"
  if [ "$output_root" = "$source_path" ]; then
    echo "Error: Output directory must be different from source directory." >&2
    return 1
  fi

  if ! mkdir -p "$output_root"; then
    echo "Error: Failed to create output directory \"$output_root\"." >&2
    return 1
  fi

  while IFS= read -r -d "" img; do
    found=$((found + 1))
    target_path=$(_image_aliases_dir_output_file "$source_path" "$img" "$output_root") || {
      errors=$((errors + 1))
      continue
    }

    if $magick_cmd composite -dissolve "$opacity" -gravity "$position" "$watermark_path" "$img" "$target_path"; then
      echo "Processed: $img -> $target_path"
      processed=$((processed + 1))
    else
      echo "Error: Failed to add watermark to $img" >&2
      errors=$((errors + 1))
    fi
  done < <(_image_aliases_print_image_paths "$source_path" "$recursive" "$output_root")

  if [ "$found" -eq 0 ]; then
    echo "Error: No image files found in $source_path" >&2
    return 1
  fi

  echo "Watermarking complete: $processed file(s) processed, $errors error(s)"
  echo "Output saved to: $output_root"
  [ "$errors" -eq 0 ]
}

_image_aliases_compress_command() {
  if [ $# -eq 0 ]; then
    echo "Compress image files or directories while preserving dimensions."
    echo "Usage: img-compress [quality] <image_or_dir> [more_sources...] [options]"
    echo "Options:"
    echo "  -q, --quality <percent>   Output quality (default: 75)"
    echo "  -o, --output <path>       File output path or directory output root"
    echo "  -r, --recursive           Include subdirectories when source is a directory"
    echo "  -h, --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  img-compress photo.jpg"
    echo "  img-compress 80 photo.jpg"
    echo "  img-compress ./photos -q 70 -r"
    return 0
  fi

  _image_aliases_check_imagemagick || return 1

  local quality="75"
  local output_path=""
  local recursive=false
  local -a sources
  local processed=0
  local errors=0
  local found=0
  local source=""
  local target_path=""
  local output_root=""
  local magick_cmd=$(_image_aliases_magick_cmd)

  sources=()
  if [ $# -gt 0 ] && echo "$1" | grep -qE "^[0-9]+$"; then
    quality="$1"
    shift
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
      -q|--quality)
        if [ $# -lt 2 ]; then
          echo "Error: Missing value for $1." >&2
          return 1
        fi
        quality="$2"
        shift 2
        ;;
      -o|--output)
        if [ $# -lt 2 ]; then
          echo "Error: Missing value for $1." >&2
          return 1
        fi
        output_path="$2"
        shift 2
        ;;
      -r|--recursive)
        recursive=true
        shift
        ;;
      -h|--help)
        _image_aliases_compress_command
        return 0
        ;;
      *)
        sources+=("$1")
        shift
        ;;
    esac
  done

  if [ ${#sources[@]} -eq 0 ]; then
    echo "Error: At least one image file or directory is required." >&2
    return 1
  fi

  if [ -n "$output_path" ] && [ ${#sources[@]} -gt 1 ]; then
    echo "Error: Use --output only with a single source." >&2
    return 1
  fi

  for source in "${sources[@]}"; do
    _image_aliases_validate_path "$source" || {
      errors=$((errors + 1))
      continue
    }

    if [ -f "$source" ]; then
      found=$((found + 1))
      target_path="${output_path:-${source%.*}_compressed_q${quality}.${source##*.}}"
      if $magick_cmd "$source" -quality "$quality" "$target_path"; then
        echo "Compressed image saved to $target_path"
        processed=$((processed + 1))
      else
        echo "Error: Failed to compress $source" >&2
        errors=$((errors + 1))
      fi
      continue
    fi

    output_root="${output_path:-$source/compressed_q${quality}}"
    if [ "$output_root" = "$source" ]; then
      echo "Error: Output directory must be different from source directory." >&2
      return 1
    fi

    while IFS= read -r -d "" img; do
      found=$((found + 1))
      target_path=$(_image_aliases_dir_output_file "$source" "$img" "$output_root") || {
        errors=$((errors + 1))
        continue
      }

      if $magick_cmd "$img" -quality "$quality" "$target_path"; then
        echo "Processed: $img -> $target_path"
        processed=$((processed + 1))
      else
        echo "Error: Failed to compress $img" >&2
        errors=$((errors + 1))
      fi
    done < <(_image_aliases_print_image_paths "$source" "$recursive" "$output_root")
  done

  if [ "$found" -eq 0 ]; then
    echo "Error: No image files found for compression." >&2
    return 1
  fi

  echo "Compression complete: $processed file(s) processed, $errors error(s)"
  [ "$errors" -eq 0 ]
}

_image_aliases_background_command() {
  if [ $# -eq 0 ]; then
    echo "Add an image or solid-color background to a single image or a directory of images."
    echo "Usage: img-bg <image_or_dir> (--image <background_image> | --color <color>) [options]"
    echo "Options:"
    echo "  -o, --output <path>       File output path or directory output root"
    echo "  -r, --recursive           Include subdirectories when source is a directory"
    echo "  -h, --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  img-bg logo.png --image background.jpg"
    echo "  img-bg logo.png --color white"
    echo "  img-bg ./icons --color \"#111111\" -r"
    return 0
  fi

  local source_path=""
  local background_mode=""
  local background_value=""
  local output_path=""
  local recursive=false
  local processed=0
  local errors=0
  local found=0
  local target_path=""
  local output_root=""
  local safe_value=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --image)
        if [ $# -lt 2 ]; then
          echo "Error: Missing value for $1." >&2
          return 1
        fi
        background_mode="image"
        background_value="$2"
        shift 2
        ;;
      --color)
        if [ $# -lt 2 ]; then
          echo "Error: Missing value for $1." >&2
          return 1
        fi
        background_mode="color"
        background_value="$2"
        shift 2
        ;;
      -o|--output)
        if [ $# -lt 2 ]; then
          echo "Error: Missing value for $1." >&2
          return 1
        fi
        output_path="$2"
        shift 2
        ;;
      -r|--recursive)
        recursive=true
        shift
        ;;
      -h|--help)
        _image_aliases_background_command
        return 0
        ;;
      *)
        if [ -z "$source_path" ]; then
          source_path="$1"
        else
          echo "Error: Unknown argument \"$1\"." >&2
          return 1
        fi
        shift
        ;;
    esac
  done

  if [ -z "$source_path" ] || [ -z "$background_mode" ] || [ -z "$background_value" ]; then
    echo "Error: Source path and one of --image/--color are required." >&2
    return 1
  fi

  _image_aliases_check_imagemagick || return 1
  _image_aliases_validate_path "$source_path" || return 1
  if [ "$background_mode" = "image" ]; then
    _image_aliases_validate_file "$background_value" || return 1
  fi

  safe_value=$(_image_aliases_safe_label "$background_value")
  if [ -z "$safe_value" ]; then
    safe_value="background"
  fi

  if [ -f "$source_path" ]; then
    if [ "$background_mode" = "image" ]; then
      target_path="${output_path:-${source_path%.*}_with_bg.${source_path##*.}}"
    else
      target_path="${output_path:-${source_path%.*}_with_${safe_value}_bg.${source_path##*.}}"
    fi

    if _image_aliases_apply_background "$source_path" "$background_mode" "$background_value" "$target_path"; then
      echo "Background added successfully, saved to $target_path"
      return 0
    fi

    echo "Error: Failed to add background to \"$source_path\"." >&2
    return 1
  fi

  if [ "$background_mode" = "image" ]; then
    output_root="${output_path:-$source_path/with_background}"
  else
    output_root="${output_path:-$source_path/with_${safe_value}_background}"
  fi

  if [ "$output_root" = "$source_path" ]; then
    echo "Error: Output directory must be different from source directory." >&2
    return 1
  fi

  while IFS= read -r -d "" img; do
    found=$((found + 1))
    target_path=$(_image_aliases_dir_output_file "$source_path" "$img" "$output_root") || {
      errors=$((errors + 1))
      continue
    }

    if _image_aliases_apply_background "$img" "$background_mode" "$background_value" "$target_path"; then
      echo "Processed: $img -> $target_path"
      processed=$((processed + 1))
    else
      echo "Error: Failed to add background to $img" >&2
      errors=$((errors + 1))
    fi
  done < <(_image_aliases_print_image_paths "$source_path" "$recursive" "$output_root")

  if [ "$found" -eq 0 ]; then
    echo "Error: No image files found in $source_path" >&2
    return 1
  fi

  echo "Background processing complete: $processed file(s) processed, $errors error(s)"
  echo "Output saved to: $output_root"
  [ "$errors" -eq 0 ]
}

# --------------------------------
# Basic Image Processing
# --------------------------------

_image_aliases_cmd_img_resize() {
  _image_aliases_resize_command "$@"
}

alias img-resize='_image_aliases_cmd_img_resize' # Resize image to specified dimensions with named parameters

_image_aliases_cmd_img_resize_dir() {
  if [ $# -eq 0 ]; then
    echo "Compatibility wrapper for img-resize."
    echo "Usage: img-resize-dir <source_dir> <size> [quality:100]"
    return 0
  fi

  local source_dir="$1"
  local size="${2:-200x}"
  local quality="${3:-100}"
  _image_aliases_resize_command "$source_dir" -s "$size" -q "$quality" -r -o "$source_dir/$size"
}

alias img-resize-dir='_image_aliases_cmd_img_resize_dir' # Batch resize images in directory and all subdirectories, output to mirrored structure


# --------------------------------
# Format Conversion
# --------------------------------

_image_aliases_cmd_img_convert_format() {
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
}

alias img-convert-format='_image_aliases_cmd_img_convert_format' # Convert image files to different format

# --------------------------------
# Image Effects
# --------------------------------

_image_aliases_cmd_img_opacity() {
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
}

alias img-opacity='_image_aliases_cmd_img_opacity' # Adjust image opacity

_image_aliases_cmd_img_rotate() {
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
}

alias img-rotate='_image_aliases_cmd_img_rotate' # Rotate image

_image_aliases_cmd_img_grayscale_binary() {
  _image_aliases_grayscale_command binary "$@"
}

alias img-grayscale-binary='_image_aliases_cmd_img_grayscale_binary' # Convert image to grayscale and binarize

_image_aliases_cmd_img_grayscale() {
  _image_aliases_grayscale_command normal "$@"
}

alias img-grayscale='_image_aliases_cmd_img_grayscale' # Convert image to grayscale

# --------------------------------
# Batch Processing
# --------------------------------

_image_aliases_cmd_img_grayscale_binary_dir() {
  if [ $# -eq 0 ]; then
    echo "Compatibility wrapper for img-grayscale-binary."
    echo "Usage: img-grayscale-binary-dir <source_dir>"
    return 0
  fi

  _image_aliases_grayscale_command binary "$1" -o "$1/gray_binary"
}

alias img-grayscale-binary-dir='_image_aliases_cmd_img_grayscale_binary_dir' # Convert directory of images to grayscale and binarize

_image_aliases_cmd_img_grayscale_dir() {
  if [ $# -eq 0 ]; then
    echo "Compatibility wrapper for img-grayscale."
    echo "Usage: img-grayscale-dir <source_dir>"
    return 0
  fi

  _image_aliases_grayscale_command normal "$1" -o "$1/gray"
}

alias img-grayscale-dir='_image_aliases_cmd_img_grayscale_dir' # Convert directory of images to grayscale

# --------------------------------
# Image Splitting
# --------------------------------

_image_aliases_cmd_img_split() {
  _image_aliases_split_command "$@"
}

alias img-split='_image_aliases_cmd_img_split' # Split image into multiple parts based on grid dimensions

_image_aliases_cmd_img_split_dir() {
  if [ $# -eq 0 ]; then
    echo "Compatibility wrapper for img-split."
    echo "Usage: img-split-dir <source_dir> [options]"
    return 0
  fi

  local source_dir="$1"
  shift
  _image_aliases_split_command "$source_dir" -o "split_output" "$@"
}

alias img-split-dir='_image_aliases_cmd_img_split_dir' # Split multiple images in a directory into parts based on grid dimensions

# --------------------------------
# Image Merging
# --------------------------------

_image_aliases_cmd_img_dir_to_pdf() {
  _image_aliases_to_pdf_command "$@"
}

alias img-dir-to-pdf='_image_aliases_cmd_img_dir_to_pdf' # Merge directory of images into PDF

_image_aliases_cmd_img_to_pdf() {
  _image_aliases_to_pdf_command "$@"
}

alias img-to-pdf='_image_aliases_cmd_img_to_pdf' # Convert single image to PDF

# --------------------------------
# Watermarking
# --------------------------------

_image_aliases_cmd_img_watermark() {
  _image_aliases_watermark_command "$@"
}

alias img-watermark='_image_aliases_cmd_img_watermark' # Add watermark to image

_image_aliases_cmd_img_watermark_dir() {
  if [ $# -lt 2 ]; then
    echo "Compatibility wrapper for img-watermark."
    echo "Usage: img-watermark-dir <watermark_image> <source_dir> [position:southeast] [opacity:100]"
    return 0
  fi

  local watermark_path="$1"
  local source_dir="$2"
  local position="${3:-southeast}"
  local opacity="${4:-100}"
  _image_aliases_watermark_command "$source_dir" "$watermark_path" -p "$position" -a "$opacity" -o "$source_dir/watermarked"
}

alias img-watermark-dir='_image_aliases_cmd_img_watermark_dir' # Batch add watermark to images

# --------------------------------
# Image Optimization
# --------------------------------

_image_aliases_cmd_img_optimize_batch() {
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
}

alias img-optimize-batch='_image_aliases_cmd_img_optimize_batch' # Batch optimize images by size

# --------------------------------
# New Image Information Functions
# --------------------------------

_image_aliases_cmd_img_info() {
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
}

alias img-info='_image_aliases_cmd_img_info' # Display basic information about image files

_image_aliases_cmd_img_metadata() {
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
}

alias img-metadata='_image_aliases_cmd_img_metadata' # Extract EXIF metadata from image files

# --------------------------------
# Image Cropping Functions
# --------------------------------

_image_aliases_cmd_img_autocrop() {
  _image_aliases_trim_command "$@"
}

alias img-autocrop='_image_aliases_cmd_img_autocrop' # Auto-trim white or transparent borders from a file or directory

_image_aliases_cmd_img_trim() {
  _image_aliases_trim_command "$@"
}

alias img-trim='_image_aliases_cmd_img_trim' # Short alias for automatic border trimming

_image_aliases_cmd_img_crop() {
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
}

alias img-crop='_image_aliases_cmd_img_crop' # Crop an image to specified dimensions

_image_aliases_cmd_img_crop_center() {
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
}

alias img-crop-center='_image_aliases_cmd_img_crop_center' # Crop an image from the center

# --------------------------------
# Image Compression Functions
# --------------------------------

_image_aliases_cmd_img_compress() {
  _image_aliases_compress_command "$@"
}

alias img-compress='_image_aliases_cmd_img_compress' # Compress an image while preserving dimensions

_image_aliases_cmd_img_compress_dir() {
  local dir="${1:-.}"
  local quality="${2:-75}"
  _image_aliases_compress_command "$dir" -q "$quality" -r -o "$dir/compressed_q${quality}"
}

alias img-compress-dir='_image_aliases_cmd_img_compress_dir' # Batch compress all images in a directory and all subdirectories, output to mirrored structure

# --------------------------------
# Image Joining Functions
# --------------------------------

_image_aliases_cmd_img_join_horizontal() {
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
}

alias img-join-horizontal='_image_aliases_cmd_img_join_horizontal' # Join multiple images horizontally

_image_aliases_cmd_img_join_vertical() {
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
}

alias img-join-vertical='_image_aliases_cmd_img_join_vertical' # Join multiple images vertically

# --------------------------------
# Image Special Effects
# --------------------------------

_image_aliases_cmd_img_sepia() {
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
}

alias img-sepia='_image_aliases_cmd_img_sepia' # Apply sepia tone effect to an image

_image_aliases_cmd_img_blur() {
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
}

alias img-blur='_image_aliases_cmd_img_blur' # Apply blur effect to an image

# --------------------------------
# Image Background Functions
# --------------------------------

_image_aliases_cmd_img_add_bg() {
  if [ $# -lt 2 ]; then
    _image_aliases_background_command
    return 0
  fi

  local source_path="$1"
  local background_path="$2"
  shift 2
  _image_aliases_background_command "$source_path" --image "$background_path" "$@"
}

alias img-add-bg='_image_aliases_cmd_img_add_bg' # Add background image to foreground image

_image_aliases_cmd_img_add_bg_dir() {
  if [ $# -lt 2 ]; then
    echo "Compatibility wrapper for img-add-bg."
    echo "Usage: img-add-bg-dir <foreground_dir> <background_image> [output_dir]"
    return 0
  fi

  local source_dir="$1"
  local background_path="$2"
  local output_dir="${3:-$source_dir/with_background}"
  _image_aliases_background_command "$source_dir" --image "$background_path" -r -o "$output_dir"
}

alias img-add-bg-dir='_image_aliases_cmd_img_add_bg_dir' # Add background image to all images in a directory

_image_aliases_cmd_img_add_color_background() {
  if [ $# -lt 2 ]; then
    _image_aliases_background_command
    return 0
  fi

  local source_path="$1"
  local background_color="$2"
  shift 2
  _image_aliases_background_command "$source_path" --color "$background_color" "$@"
}

alias img-add-color-background='_image_aliases_cmd_img_add_color_background' # Add solid color background to image(s)

# --------------------------------
# Sprite Generation Functions
# --------------------------------

_image_aliases_cmd_img_sprite() {
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
}

alias img-sprite='_image_aliases_cmd_img_sprite' # Generate sprite sheet from images in a directory

_image_aliases_cmd_img_sprite_multi() {
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
    if _image_aliases_cmd_img_sprite "$subdir" "$columns" "$resize_spec" >/dev/null 2>&1; then
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
}

alias img-sprite-multi='_image_aliases_cmd_img_sprite_multi' # Generate sprite sheets from multiple directories

_image_aliases_cmd_img_sprite_batch() {
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

    if _image_aliases_cmd_img_sprite "$source_dir" 6 "$resize_spec" >/dev/null 2>&1; then
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
}

alias img-sprite-batch='_image_aliases_cmd_img_sprite_batch' # Generate sprite sheets with different configurations

# --------------------------------
# Batch Rename Functions
# --------------------------------

_image_aliases_cmd_img_rename_sequential() {
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
}

alias img-rename-sequential='_image_aliases_cmd_img_rename_sequential' # Rename images in a directory with sequential numbering

_image_aliases_cmd_img_gray() {
  _image_aliases_grayscale_command normal "$@"
}

alias img-gray='_image_aliases_cmd_img_gray' # Short alias for grayscale conversion

_image_aliases_cmd_img_graybin() {
  _image_aliases_grayscale_command binary "$@"
}

alias img-graybin='_image_aliases_cmd_img_graybin' # Short alias for grayscale binary conversion

_image_aliases_cmd_img_pdf() {
  _image_aliases_to_pdf_command "$@"
}

alias img-pdf='_image_aliases_cmd_img_pdf' # Short alias for image-to-pdf conversion

_image_aliases_cmd_img_wm() {
  _image_aliases_watermark_command "$@"
}

alias img-wm='_image_aliases_cmd_img_wm' # Short alias for watermarking

_image_aliases_cmd_img_bg() {
  _image_aliases_background_command "$@"
}

alias img-bg='_image_aliases_cmd_img_bg' # Generic background command with image or color mode

_image_aliases_cmd_image_help() {
  echo "Image Processing Aliases Help"
  echo "============================"
  echo "This module provides aliases for common image processing operations."
  echo "Core commands auto-detect single file or directory input."
  echo
  echo "Unified Core Commands:"
  echo "  img-resize           - Resize a file or directory of images"
  echo "  img-grayscale        - Convert a file or directory to grayscale"
  echo "  img-grayscale-binary - Convert a file or directory to grayscale + binary"
  echo "  img-split            - Split file or directory images by grid"
  echo "  img-to-pdf           - Convert a file or directory of images to PDF"
  echo "  img-watermark        - Add watermark to a file or directory"
  echo "  img-compress         - Compress a file or directory"
  echo "  img-bg               - Add image or color background to a file or directory"
  echo
  echo "Format Conversion:"
  echo "  img-convert-format   - Convert image files to different format"
  echo
  echo "Image Effects:"
  echo "  img-opacity          - Adjust image opacity"
  echo "  img-rotate           - Rotate image"
  echo "  img-gray             - Short alias of img-grayscale"
  echo "  img-graybin          - Short alias of img-grayscale-binary"
  echo "  img-sepia            - Apply sepia tone effect to an image"
  echo "  img-blur             - Apply blur effect to an image"
  echo "  img-add-bg           - Compatibility alias for image background mode"
  echo "  img-add-color-background - Compatibility alias for color background mode"
  echo
  echo "Image Information:"
  echo "  img-info             - Display basic information about image files"
  echo "  img-metadata         - Extract EXIF metadata from image files"
  echo
  echo "Image Cropping:"
  echo "  img-autocrop         - Auto-trim white or transparent borders"
  echo "  img-trim             - Short alias of img-autocrop"
  echo "  img-crop             - Crop an image to specified dimensions"
  echo "  img-crop-center      - Crop an image from the center"
  echo
  echo "Image Compression:"
  echo "  img-compress-dir     - Compatibility wrapper for recursive directory compression"
  echo
  echo "Image Joining:"
  echo "  img-join-horizontal  - Join multiple images horizontally"
  echo "  img-join-vertical    - Join multiple images vertically"
  echo
  echo "Image Merging:"
  echo "  img-pdf              - Short alias of img-to-pdf"
  echo "  img-dir-to-pdf       - Compatibility wrapper for directory-to-pdf"
  echo
  echo "Watermarking:"
  echo "  img-wm               - Short alias of img-watermark"
  echo "  img-watermark-dir    - Compatibility wrapper for legacy parameter order"
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
  echo "Compatibility Wrappers:"
  echo "  img-resize-dir, img-grayscale-dir, img-grayscale-binary-dir"
  echo "  img-split-dir, img-compress-dir, img-dir-to-pdf"
  echo "  img-watermark-dir, img-add-bg-dir"
  echo
  echo "For more details about a specific command, just run the command without arguments."
}

alias image-help='_image_aliases_cmd_image_help' # Help function showing all available image processing aliases

_image_aliases_cmd_img_help() {
  _image_aliases_cmd_image_help
}

alias img-help='_image_aliases_cmd_img_help' # Alias to call the help function

_image_aliases_cmd_img_aliases() {
  _image_aliases_cmd_image_help
}

alias img-aliases='_image_aliases_cmd_img_aliases' # Alias to call the help function
