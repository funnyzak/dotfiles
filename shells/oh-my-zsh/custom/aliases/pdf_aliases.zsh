# Description: PDF related aliases for inspection, export, compression, watermarking, encryption, merge, split, and batch manipulation.

_PDF_COLLECTED_ITEMS_PDF_ALIASES=()

# Core Helpers
# ### --- ###
_pdf_show_error_pdf_aliases() {
  printf "%s\n" "$1" >&2
  return 1
}

_pdf_show_warning_pdf_aliases() {
  printf "%s\n" "$1" >&2
  return 0
}

_pdf_show_usage_pdf_aliases() {
  printf "%b\n" "$1"
  return 0
}

_pdf_require_commands_pdf_aliases() {
  local command_name=""

  for command_name in "$@"; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
      _pdf_show_error_pdf_aliases "Error: Required command \"$command_name\" not found. Please install it first."
      return 1
    fi
  done

  return 0
}

_pdf_is_pdf_pdf_aliases() {
  local source_name="$1"
  local extension_name="${source_name##*.}"

  extension_name="$(printf "%s" "$extension_name" | tr "[:upper:]" "[:lower:]")"
  [[ "$extension_name" == "pdf" ]]
}

_pdf_validate_pdf_path_pdf_aliases() {
  local source_pdf="$1"

  if [[ ! -f "$source_pdf" ]]; then
    _pdf_show_error_pdf_aliases "Error: File \"$source_pdf\" does not exist or is not a regular file."
    return 1
  fi

  if ! _pdf_is_pdf_pdf_aliases "$source_pdf"; then
    _pdf_show_error_pdf_aliases "Error: File \"$source_pdf\" is not a PDF file."
    return 1
  fi

  return 0
}

_pdf_ensure_directory_pdf_aliases() {
  local target_root="$1"

  if [[ -z "$target_root" ]]; then
    _pdf_show_error_pdf_aliases "Error: Output directory cannot be empty."
    return 1
  fi

  if ! mkdir -p "$target_root"; then
    _pdf_show_error_pdf_aliases "Error: Failed to create directory \"$target_root\"."
    return 1
  fi

  return 0
}

_pdf_ensure_parent_directory_pdf_aliases() {
  local target_name="$1"
  local parent_root=""

  parent_root="$(dirname "$target_name")"
  _pdf_ensure_directory_pdf_aliases "$parent_root"
}

_pdf_unique_target_pdf_aliases() {
  local target_name="$1"
  local stem_name=""
  local suffix_name=""
  local sequence_id="1"
  local unique_name=""

  if [[ ! -e "$target_name" ]]; then
    printf "%s\n" "$target_name"
    return 0
  fi

  if [[ "$target_name" == *.* ]]; then
    stem_name="${target_name%.*}"
    suffix_name=".${target_name##*.}"
  else
    stem_name="$target_name"
    suffix_name=""
  fi

  unique_name="${stem_name}_${sequence_id}${suffix_name}"
  while [[ -e "$unique_name" ]]; do
    sequence_id=$((sequence_id + 1))
    unique_name="${stem_name}_${sequence_id}${suffix_name}"
  done

  printf "%s\n" "$unique_name"
  return 0
}

_pdf_output_target_seen_pdf_aliases() {
  local target_name="$1"
  local existing_name=""

  shift
  for existing_name in "$@"; do
    if [[ "$existing_name" == "$target_name" ]]; then
      return 0
    fi
  done

  return 1
}

_pdf_unique_target_with_planned_pdf_aliases() {
  local target_name="$1"
  local stem_name=""
  local suffix_name=""
  local sequence_id="1"
  local unique_name=""

  shift
  if [[ ! -e "$target_name" ]] && ! _pdf_output_target_seen_pdf_aliases "$target_name" "$@"; then
    printf "%s\n" "$target_name"
    return 0
  fi

  if [[ "$target_name" == *.* ]]; then
    stem_name="${target_name%.*}"
    suffix_name=".${target_name##*.}"
  else
    stem_name="$target_name"
    suffix_name=""
  fi

  unique_name="${stem_name}_${sequence_id}${suffix_name}"
  while [[ -e "$unique_name" ]] || _pdf_output_target_seen_pdf_aliases "$unique_name" "$@"; do
    sequence_id=$((sequence_id + 1))
    unique_name="${stem_name}_${sequence_id}${suffix_name}"
  done

  printf "%s\n" "$unique_name"
  return 0
}

_pdf_build_output_path_pdf_aliases() {
  local source_pdf="$1"
  local suffix_name="$2"
  local target_ext="$3"
  local output_root="$4"
  local base_name=""

  base_name="$(basename "$source_pdf")"
  base_name="${base_name%.*}"

  if [[ -n "$output_root" ]]; then
    printf "%s\n" "${output_root}/${base_name}${suffix_name}${target_ext}"
  else
    printf "%s\n" "$(dirname "$source_pdf")/${base_name}${suffix_name}${target_ext}"
  fi
}

_pdf_build_output_pdf_aliases() {
  local source_pdf="$1"
  local suffix_name="$2"
  local target_ext="$3"
  local output_root="$4"
  local base_name=""
  local target_name=""

  base_name="$(basename "$source_pdf")"
  base_name="${base_name%.*}"

  if [[ -n "$output_root" ]]; then
    if ! _pdf_ensure_directory_pdf_aliases "$output_root"; then
      return 1
    fi
    target_name="${output_root}/${base_name}${suffix_name}${target_ext}"
  else
    target_name="$(dirname "$source_pdf")/${base_name}${suffix_name}${target_ext}"
  fi

  _pdf_unique_target_pdf_aliases "$target_name"
}

_pdf_build_output_bundle_pdf_aliases() {
  local source_pdf="$1"
  local suffix_name="$2"
  local output_root="$3"
  local base_name=""
  local bundle_root=""

  base_name="$(basename "$source_pdf")"
  base_name="${base_name%.*}"

  if [[ -n "$output_root" ]]; then
    if ! _pdf_ensure_directory_pdf_aliases "$output_root"; then
      return 1
    fi
    bundle_root="${output_root}/${base_name}${suffix_name}"
  else
    bundle_root="$(dirname "$source_pdf")/${base_name}${suffix_name}"
  fi

  _pdf_unique_target_pdf_aliases "$bundle_root"
}

_pdf_collect_pdf_files_pdf_aliases() {
  local input_name=""
  local source_pdf=""
  local found_any="0"

  for input_name in "$@"; do
    if [[ -f "$input_name" ]]; then
      if ! _pdf_validate_pdf_path_pdf_aliases "$input_name"; then
        return 1
      fi
      printf "%s\0" "$input_name"
      found_any="1"
      continue
    fi

    if [[ -d "$input_name" ]]; then
      while IFS= read -r -d "" source_pdf; do
        printf "%s\0" "$source_pdf"
        found_any="1"
      done < <(find "$input_name" -type f \( -iname "*.pdf" \) -print0 2>/dev/null)
      continue
    fi

    _pdf_show_error_pdf_aliases "Error: Input \"$input_name\" does not exist."
    return 1
  done

  if [[ "$found_any" != "1" ]]; then
    _pdf_show_error_pdf_aliases "Error: No PDF files found in the provided inputs."
    return 1
  fi

  return 0
}

_pdf_human_size_pdf_aliases() {
  local source_name="$1"
  local size_name=""

  size_name="$(du -h "$source_name" 2>/dev/null | awk "{print \$1; exit}")"
  if [[ -z "$size_name" ]]; then
    size_name="unknown"
  fi

  printf "%s\n" "$size_name"
  return 0
}

_pdf_validate_positive_integer_pdf_aliases() {
  local value_name="$1"
  local label_name="$2"

  if [[ ! "$value_name" =~ ^[0-9]+$ ]] || [[ "$value_name" -le 0 ]]; then
    _pdf_show_error_pdf_aliases "Error: $label_name must be a positive integer."
    return 1
  fi

  return 0
}

_pdf_validate_image_format_pdf_aliases() {
  local format_name="$1"

  case "$format_name" in
    png|jpg|jpeg)
      return 0
      ;;
    *)
      _pdf_show_error_pdf_aliases "Error: Invalid image format \"$format_name\". Use png, jpg, or jpeg."
      return 1
      ;;
  esac
}

_pdf_validate_compression_level_pdf_aliases() {
  local level_name="$1"

  case "$level_name" in
    screen|ebook|printer|prepress)
      return 0
      ;;
    *)
      _pdf_show_error_pdf_aliases "Error: Invalid compression level \"$level_name\". Use screen, ebook, printer, or prepress."
      return 1
      ;;
  esac
}

_pdf_validate_decimal_range_pdf_aliases() {
  local value_name="$1"
  local label_name="$2"
  local min_value="$3"
  local max_value="$4"

  if ! python3 - "$value_name" "$min_value" "$max_value" <<PYTHON_VALIDATE_DECIMAL
import math
import sys

try:
    value = float(sys.argv[1])
    min_value = float(sys.argv[2])
    max_value = float(sys.argv[3])
except ValueError:
    sys.exit(1)

if not math.isfinite(value) or value < min_value or value > max_value:
    sys.exit(1)
PYTHON_VALIDATE_DECIMAL
  then
    _pdf_show_error_pdf_aliases "Error: $label_name must be a number between ${min_value} and ${max_value}."
    return 1
  fi

  return 0
}

_pdf_validate_integer_pdf_aliases() {
  local value_name="$1"
  local label_name="$2"

  if [[ ! "$value_name" =~ ^-?[0-9]+$ ]]; then
    _pdf_show_error_pdf_aliases "Error: $label_name must be an integer."
    return 1
  fi

  return 0
}

_pdf_validate_watermark_mode_pdf_aliases() {
  local mode_name="$1"

  case "$mode_name" in
    single|repeat)
      return 0
      ;;
    *)
      _pdf_show_error_pdf_aliases "Error: Invalid watermark mode \"$mode_name\". Use single or repeat."
      return 1
      ;;
  esac
}

_pdf_validate_watermark_layer_pdf_aliases() {
  local layer_name="$1"

  case "$layer_name" in
    over|under)
      return 0
      ;;
    *)
      _pdf_show_error_pdf_aliases "Error: Invalid watermark layer \"$layer_name\". Use over or under."
      return 1
      ;;
  esac
}

_pdf_validate_watermark_position_pdf_aliases() {
  local position_name="$1"

  case "$position_name" in
    center|top-left|top|top-right|left|right|bottom-left|bottom|bottom-right)
      return 0
      ;;
    *)
      _pdf_show_error_pdf_aliases "Error: Invalid watermark position \"$position_name\". Use center, top-left, top, top-right, left, right, bottom-left, bottom, or bottom-right."
      return 1
      ;;
  esac
}

_pdf_validate_watermark_pages_pdf_aliases() {
  local pages_name="$1"

  if [[ -z "$pages_name" ]]; then
    _pdf_show_error_pdf_aliases "Error: Pages value cannot be empty."
    return 1
  fi

  case "$pages_name" in
    all|odd|even|first|last)
      return 0
      ;;
  esac

  if [[ "$pages_name" =~ ^[0-9]+(-[0-9]+)?(,[0-9]+(-[0-9]+)?)*$ ]]; then
    return 0
  fi

  _pdf_show_error_pdf_aliases "Error: Invalid pages value \"$pages_name\". Use all, odd, even, first, last, or ranges like 1,3,5-8."
  return 1
}

_pdf_validate_watermark_color_pdf_aliases() {
  local color_name="$1"

  case "$color_name" in
    black|white|gray|grey|red|green|blue|yellow|orange|purple)
      return 0
      ;;
  esac

  if [[ "$color_name" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
    return 0
  fi

  _pdf_show_error_pdf_aliases "Error: Invalid font color \"$color_name\". Use #RRGGBB or a basic color name."
  return 1
}

_pdf_validate_watermark_image_pdf_aliases() {
  local image_name="$1"
  local extension_name=""

  if [[ ! -f "$image_name" ]]; then
    _pdf_show_error_pdf_aliases "Error: Watermark image \"$image_name\" does not exist or is not a regular file."
    return 1
  fi

  extension_name="${image_name##*.}"
  extension_name="$(printf "%s" "$extension_name" | tr "[:upper:]" "[:lower:]")"
  case "$extension_name" in
    png|jpg|jpeg)
      return 0
      ;;
    *)
      _pdf_show_error_pdf_aliases "Error: Watermark image must be png, jpg, or jpeg."
      return 1
      ;;
  esac
}

_pdf_rotation_token_pdf_aliases() {
  local degree_name="$1"

  case "$degree_name" in
    90)
      printf "%s\n" "1-endright"
      return 0
      ;;
    180)
      printf "%s\n" "1-enddown"
      return 0
      ;;
    270)
      printf "%s\n" "1-endleft"
      return 0
      ;;
    *)
      _pdf_show_error_pdf_aliases "Error: Rotation degrees must be 90, 180, or 270."
      return 1
      ;;
  esac
}

_pdf_summary_pdf_aliases() {
  local action_name="$1"
  local total_count="$2"
  local success_count="$3"

  if [[ "$total_count" -gt 1 ]]; then
    printf "%s\n" "$action_name: ${success_count}/${total_count} completed."
  fi

  if [[ "$success_count" -ne "$total_count" ]]; then
    return 1
  fi

  return 0
}

_pdf_read_inputs_pdf_aliases() {
  local source_pdf=""

  _PDF_COLLECTED_ITEMS_PDF_ALIASES=()
  while IFS= read -r -d "" source_pdf; do
    _PDF_COLLECTED_ITEMS_PDF_ALIASES+=("$source_pdf")
  done < <(_pdf_collect_pdf_files_pdf_aliases "$@")

  if [[ "${#_PDF_COLLECTED_ITEMS_PDF_ALIASES[@]}" -eq 0 ]]; then
    _pdf_show_error_pdf_aliases "Error: No PDF files found in the provided inputs."
    return 1
  fi

  return 0
}

# PDF Command Helpers
# ### --- ###
_pdf_info_pdf_aliases() {
  local -a input_items=()
  local -a pdf_items=()
  local source_pdf=""
  local total_count="0"
  local success_count="0"

  if [[ "$#" -eq 0 ]]; then
    _pdf_show_usage_pdf_aliases "Display PDF information.\nUsage:\n  pdf-info <pdf_or_dir> [more_pdfs_or_dirs...]\n\nExamples:\n  pdf-info report.pdf\n  pdf-info ./docs ./archive/notes.pdf"
    return 1
  fi

  if ! _pdf_require_commands_pdf_aliases pdfinfo; then
    return 1
  fi

  input_items=("$@")
  if ! _pdf_read_inputs_pdf_aliases "${input_items[@]}"; then
    return 1
  fi
  pdf_items=("${_PDF_COLLECTED_ITEMS_PDF_ALIASES[@]}")

  total_count="${#pdf_items[@]}"
  for source_pdf in "${pdf_items[@]}"; do
    if [[ "$total_count" -gt 1 ]]; then
      printf "%s\n" "==> $source_pdf"
    fi

    if pdfinfo "$source_pdf"; then
      success_count=$((success_count + 1))
    else
      _pdf_show_warning_pdf_aliases "Warning: Failed to read PDF information for \"$source_pdf\"."
    fi

    if [[ "$total_count" -gt 1 ]]; then
      printf "%s\n" ""
    fi
  done

  _pdf_summary_pdf_aliases "PDF info" "$total_count" "$success_count"
}

_pdf_to_images_pdf_aliases() {
  local density_value="300"
  local format_name="png"
  local output_root=""
  local -a input_items=()
  local -a pdf_items=()
  local source_pdf=""
  local output_bundle=""
  local base_name=""
  local prefix_name=""
  local total_count="0"
  local success_count="0"
  local command_flag="-png"

  if [[ "$#" -eq 0 ]]; then
    _pdf_show_usage_pdf_aliases "Convert PDF pages to images.\nUsage:\n  pdf-to-images <pdf_or_dir> [more_inputs...] [options]\n\nOptions:\n  -f, --format <png|jpg|jpeg>   Output image format, default: png\n  -d, --density <dpi>           Render density, default: 300\n  -r, --resolution <dpi>        Same as --density\n  -o, --output-dir <dir>        Output root directory\n  -h, --help                    Show this help\n\nExamples:\n  pdf-to-images report.pdf\n  pdf-to-images ./docs --format jpg --density 200\n  pdf-to-images report.pdf ./archive -o ./exports/images"
    return 1
  fi

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -f|--format)
        if [[ -z "${2:-}" ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        format_name="$2"
        shift 2
        ;;
      -d|--density|-r|--resolution)
        if [[ -z "${2:-}" ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        density_value="$2"
        shift 2
        ;;
      -o|--output-dir)
        if [[ -z "${2:-}" ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        output_root="$2"
        shift 2
        ;;
      -h|--help)
        _pdf_show_usage_pdf_aliases "Convert PDF pages to images.\nUsage:\n  pdf-to-images <pdf_or_dir> [more_inputs...] [options]\n\nOptions:\n  -f, --format <png|jpg|jpeg>   Output image format, default: png\n  -d, --density <dpi>           Render density, default: 300\n  -r, --resolution <dpi>        Same as --density\n  -o, --output-dir <dir>        Output root directory\n  -h, --help                    Show this help"
        return 0
        ;;
      -*)
        _pdf_show_error_pdf_aliases "Error: Unknown option \"$1\"."
        return 1
        ;;
      *)
        input_items+=("$1")
        shift
        ;;
    esac
  done

  if [[ "${#input_items[@]}" -eq 0 ]]; then
    _pdf_show_error_pdf_aliases "Error: At least one PDF file or directory is required."
    return 1
  fi

  if ! _pdf_validate_positive_integer_pdf_aliases "$density_value" "Density"; then
    return 1
  fi

  if ! _pdf_validate_image_format_pdf_aliases "$format_name"; then
    return 1
  fi

  if ! _pdf_require_commands_pdf_aliases pdftoppm; then
    return 1
  fi

  if [[ "$format_name" == "jpg" ]] || [[ "$format_name" == "jpeg" ]]; then
    command_flag="-jpeg"
  fi

  if ! _pdf_read_inputs_pdf_aliases "${input_items[@]}"; then
    return 1
  fi
  pdf_items=("${_PDF_COLLECTED_ITEMS_PDF_ALIASES[@]}")

  total_count="${#pdf_items[@]}"
  for source_pdf in "${pdf_items[@]}"; do
    output_bundle="$(_pdf_build_output_bundle_pdf_aliases "$source_pdf" "_images" "$output_root")" || return 1
    if ! _pdf_ensure_directory_pdf_aliases "$output_bundle"; then
      return 1
    fi

    base_name="$(basename "$source_pdf")"
    base_name="${base_name%.*}"
    prefix_name="${output_bundle}/${base_name}"

    printf "%s\n" "Converting \"$source_pdf\" to ${format_name} images..."
    if pdftoppm -r "$density_value" "$command_flag" "$source_pdf" "$prefix_name"; then
      printf "%s\n" "Exported images to \"$output_bundle\"."
      success_count=$((success_count + 1))
    else
      _pdf_show_warning_pdf_aliases "Warning: Failed to convert \"$source_pdf\" to images."
    fi
  done

  _pdf_summary_pdf_aliases "PDF to images" "$total_count" "$success_count"
}

_pdf_to_jpg_pdf_aliases() {
  if [[ "$#" -eq 0 ]]; then
    _pdf_show_usage_pdf_aliases "Convert PDF pages to JPG images.\nUsage:\n  pdf-to-jpg <pdf_or_dir> [more_inputs...] [options]\n\nOptions:\n  -d, --density <dpi>     Render density, default: 300\n  -r, --resolution <dpi>  Same as --density\n  -o, --output-dir <dir>  Output root directory\n  -h, --help              Show this help"
    return 1
  fi

  _pdf_to_images_pdf_aliases --format jpg "$@"
}

_pdf_compress_pdf_aliases() {
  local level_name="screen"
  local output_root=""
  local -a input_items=()
  local -a pdf_items=()
  local source_pdf=""
  local output_pdf=""
  local total_count="0"
  local success_count="0"
  local original_size=""
  local compressed_size=""

  if [[ "$#" -eq 0 ]]; then
    _pdf_show_usage_pdf_aliases "Compress PDF files.\nUsage:\n  pdf-compress <pdf_or_dir> [more_inputs...] [options]\n\nOptions:\n  -l, --level <screen|ebook|printer|prepress>   Compression profile, default: screen\n  -o, --output-dir <dir>                        Output root directory\n  -h, --help                                    Show this help\n\nExamples:\n  pdf-compress report.pdf\n  pdf-compress ./docs --level ebook\n  pdf-compress report.pdf ./archive -o ./compressed"
    return 1
  fi

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -l|--level)
        if [[ -z "${2:-}" ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        level_name="$2"
        shift 2
        ;;
      -o|--output-dir)
        if [[ -z "${2:-}" ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        output_root="$2"
        shift 2
        ;;
      -h|--help)
        _pdf_show_usage_pdf_aliases "Compress PDF files.\nUsage:\n  pdf-compress <pdf_or_dir> [more_inputs...] [options]\n\nOptions:\n  -l, --level <screen|ebook|printer|prepress>   Compression profile, default: screen\n  -o, --output-dir <dir>                        Output root directory\n  -h, --help                                    Show this help"
        return 0
        ;;
      -*)
        _pdf_show_error_pdf_aliases "Error: Unknown option \"$1\"."
        return 1
        ;;
      *)
        input_items+=("$1")
        shift
        ;;
    esac
  done

  if [[ "${#input_items[@]}" -eq 0 ]]; then
    _pdf_show_error_pdf_aliases "Error: At least one PDF file or directory is required."
    return 1
  fi

  if ! _pdf_validate_compression_level_pdf_aliases "$level_name"; then
    return 1
  fi

  if ! _pdf_require_commands_pdf_aliases gs; then
    return 1
  fi

  if ! _pdf_read_inputs_pdf_aliases "${input_items[@]}"; then
    return 1
  fi
  pdf_items=("${_PDF_COLLECTED_ITEMS_PDF_ALIASES[@]}")

  total_count="${#pdf_items[@]}"
  for source_pdf in "${pdf_items[@]}"; do
    output_pdf="$(_pdf_build_output_pdf_aliases "$source_pdf" "_${level_name}" ".pdf" "$output_root")" || return 1

    printf "%s\n" "Compressing \"$source_pdf\" with \"$level_name\" profile..."
    if gs -q -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS="/${level_name}" -dNOPAUSE -dBATCH -sOutputFile="$output_pdf" "$source_pdf"; then
      original_size="$(_pdf_human_size_pdf_aliases "$source_pdf")"
      compressed_size="$(_pdf_human_size_pdf_aliases "$output_pdf")"
      printf "%s\n" "Saved \"$output_pdf\" (${original_size} -> ${compressed_size})."
      success_count=$((success_count + 1))
    else
      _pdf_show_warning_pdf_aliases "Warning: Failed to compress \"$source_pdf\"."
    fi
  done

  _pdf_summary_pdf_aliases "PDF compression" "$total_count" "$success_count"
}

_pdf_encrypt_pdf_aliases() {
  local output_root=""
  local owner_value=""
  local user_value=""
  local -a input_items=()
  local -a pdf_items=()
  local source_pdf=""
  local output_pdf=""
  local owner_secret=""
  local user_secret=""
  local total_count="0"
  local success_count="0"

  if [[ "$#" -eq 0 ]]; then
    _pdf_show_usage_pdf_aliases "Encrypt PDF files.\nUsage:\n  pdf-encrypt <pdf_or_dir> [more_inputs...] [options]\n\nOptions:\n  --owner-password <password>   Owner password, default: random per file\n  --user-password <password>    User password, default: random per file\n  -o, --output-dir <dir>        Output root directory\n  -h, --help                    Show this help\n\nExamples:\n  pdf-encrypt report.pdf\n  pdf-encrypt ./docs --user-password 123456\n  pdf-encrypt report.pdf ./archive -o ./encrypted"
    return 1
  fi

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --owner-password)
        if [[ -z "${2:-}" ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        owner_value="$2"
        shift 2
        ;;
      --user-password)
        if [[ -z "${2:-}" ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        user_value="$2"
        shift 2
        ;;
      -o|--output-dir)
        if [[ -z "${2:-}" ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        output_root="$2"
        shift 2
        ;;
      -h|--help)
        _pdf_show_usage_pdf_aliases "Encrypt PDF files.\nUsage:\n  pdf-encrypt <pdf_or_dir> [more_inputs...] [options]\n\nOptions:\n  --owner-password <password>   Owner password, default: random per file\n  --user-password <password>    User password, default: random per file\n  -o, --output-dir <dir>        Output root directory\n  -h, --help                    Show this help"
        return 0
        ;;
      -*)
        _pdf_show_error_pdf_aliases "Error: Unknown option \"$1\"."
        return 1
        ;;
      *)
        input_items+=("$1")
        shift
        ;;
    esac
  done

  if [[ "${#input_items[@]}" -eq 0 ]]; then
    _pdf_show_error_pdf_aliases "Error: At least one PDF file or directory is required."
    return 1
  fi

  if ! _pdf_require_commands_pdf_aliases gs openssl; then
    return 1
  fi

  if ! _pdf_read_inputs_pdf_aliases "${input_items[@]}"; then
    return 1
  fi
  pdf_items=("${_PDF_COLLECTED_ITEMS_PDF_ALIASES[@]}")

  total_count="${#pdf_items[@]}"
  for source_pdf in "${pdf_items[@]}"; do
    output_pdf="$(_pdf_build_output_pdf_aliases "$source_pdf" "_encrypted" ".pdf" "$output_root")" || return 1
    owner_secret="$owner_value"
    user_secret="$user_value"

    if [[ -z "$owner_secret" ]]; then
      owner_secret="$(openssl rand -base64 12)"
    fi

    if [[ -z "$user_secret" ]]; then
      user_secret="$(openssl rand -base64 12)"
    fi

    printf "%s\n" "Encrypting \"$source_pdf\"..."
    if gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile="$output_pdf" -dPDFSETTINGS=/prepress -dPassThroughJPEGImages=true -sOwnerPassword="$owner_secret" -sUserPassword="$user_secret" -dEncryptionR=3 -dKeyLength=128 -dPermissions=-4 "$source_pdf"; then
      printf "%s\n" "Encrypted: \"$output_pdf\""
      printf "%s\n" "User password: $user_secret"
      printf "%s\n" "Owner password: $owner_secret"
      success_count=$((success_count + 1))
    else
      _pdf_show_warning_pdf_aliases "Warning: Failed to encrypt \"$source_pdf\"."
    fi
  done

  _pdf_summary_pdf_aliases "PDF encryption" "$total_count" "$success_count"
}

_pdf_merge_pdf_aliases() {
  local output_pdf=""
  local -a input_items=()
  local -a pdf_items=()
  local -a sorted_items=()
  local source_pdf=""

  if [[ "$#" -eq 0 ]]; then
    _pdf_show_usage_pdf_aliases "Merge multiple PDFs into one file.\nUsage:\n  pdf-merge <output_pdf> <pdf_or_dir> [more_inputs...]\n\nExamples:\n  pdf-merge merged.pdf a.pdf b.pdf\n  pdf-merge ./exports/all.pdf ./docs ./archive"
    return 1
  fi

  if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    _pdf_show_usage_pdf_aliases "Merge multiple PDFs into one file.\nUsage:\n  pdf-merge <output_pdf> <pdf_or_dir> [more_inputs...]\n\nExamples:\n  pdf-merge merged.pdf a.pdf b.pdf\n  pdf-merge ./exports/all.pdf ./docs ./archive"
    return 0
  fi

  output_pdf="$1"
  shift
  input_items=("$@")

  if [[ "${#input_items[@]}" -eq 0 ]]; then
    _pdf_show_error_pdf_aliases "Error: At least one PDF file or directory is required."
    return 1
  fi

  if [[ "$output_pdf" != *.pdf ]]; then
    output_pdf="${output_pdf}.pdf"
  fi

  if [[ -e "$output_pdf" ]]; then
    _pdf_show_error_pdf_aliases "Error: Output file \"$output_pdf\" already exists."
    return 1
  fi

  if ! _pdf_require_commands_pdf_aliases pdftk; then
    return 1
  fi

  if ! _pdf_read_inputs_pdf_aliases "${input_items[@]}"; then
    return 1
  fi
  pdf_items=("${_PDF_COLLECTED_ITEMS_PDF_ALIASES[@]}")

  if [[ "${#pdf_items[@]}" -lt 2 ]]; then
    _pdf_show_error_pdf_aliases "Error: At least two PDF files are required to merge."
    return 1
  fi

  while IFS= read -r source_pdf; do
    sorted_items+=("$source_pdf")
  done < <(printf "%s\n" "${pdf_items[@]}" | LC_ALL=C sort)
  pdf_items=("${sorted_items[@]}")

  if ! _pdf_ensure_parent_directory_pdf_aliases "$output_pdf"; then
    return 1
  fi

  printf "%s\n" "Merging ${#pdf_items[@]} PDF files into \"$output_pdf\"..."
  if pdftk "${pdf_items[@]}" cat output "$output_pdf"; then
    printf "%s\n" "Merge complete: \"$output_pdf\""
    return 0
  fi

  _pdf_show_error_pdf_aliases "Error: Failed to merge PDF files."
  return 1
}

_pdf_split_pdf_aliases() {
  local output_root=""
  local -a input_items=()
  local -a pdf_items=()
  local source_pdf=""
  local output_bundle=""
  local base_name=""
  local total_count="0"
  local success_count="0"

  if [[ "$#" -eq 0 ]]; then
    _pdf_show_usage_pdf_aliases "Split PDF files into single-page PDFs.\nUsage:\n  pdf-split <pdf_or_dir> [more_inputs...] [options]\n\nOptions:\n  -o, --output-dir <dir>   Output root directory\n  -h, --help               Show this help\n\nExamples:\n  pdf-split report.pdf\n  pdf-split ./docs -o ./exports/pages"
    return 1
  fi

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -o|--output-dir)
        if [[ -z "${2:-}" ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        output_root="$2"
        shift 2
        ;;
      -h|--help)
        _pdf_show_usage_pdf_aliases "Split PDF files into single-page PDFs.\nUsage:\n  pdf-split <pdf_or_dir> [more_inputs...] [options]\n\nOptions:\n  -o, --output-dir <dir>   Output root directory\n  -h, --help               Show this help"
        return 0
        ;;
      -*)
        _pdf_show_error_pdf_aliases "Error: Unknown option \"$1\"."
        return 1
        ;;
      *)
        input_items+=("$1")
        shift
        ;;
    esac
  done

  if [[ "${#input_items[@]}" -eq 0 ]]; then
    _pdf_show_error_pdf_aliases "Error: At least one PDF file or directory is required."
    return 1
  fi

  if ! _pdf_require_commands_pdf_aliases pdftk; then
    return 1
  fi

  if ! _pdf_read_inputs_pdf_aliases "${input_items[@]}"; then
    return 1
  fi
  pdf_items=("${_PDF_COLLECTED_ITEMS_PDF_ALIASES[@]}")

  total_count="${#pdf_items[@]}"
  for source_pdf in "${pdf_items[@]}"; do
    output_bundle="$(_pdf_build_output_bundle_pdf_aliases "$source_pdf" "_pages" "$output_root")" || return 1
    if ! _pdf_ensure_directory_pdf_aliases "$output_bundle"; then
      return 1
    fi

    base_name="$(basename "$source_pdf")"
    base_name="${base_name%.*}"

    printf "%s\n" "Splitting \"$source_pdf\"..."
    if pdftk "$source_pdf" burst output "${output_bundle}/${base_name}_page_%04d.pdf"; then
      rm -f "${output_bundle}/doc_data.txt"
      printf "%s\n" "Pages exported to \"$output_bundle\"."
      success_count=$((success_count + 1))
    else
      _pdf_show_warning_pdf_aliases "Warning: Failed to split \"$source_pdf\"."
    fi
  done

  _pdf_summary_pdf_aliases "PDF split" "$total_count" "$success_count"
}

_pdf_rotate_pdf_aliases() {
  local degree_name=""
  local output_root=""
  local rotation_token=""
  local -a input_items=()
  local -a pdf_items=()
  local source_pdf=""
  local output_pdf=""
  local total_count="0"
  local success_count="0"

  if [[ "$#" -eq 0 ]]; then
    _pdf_show_usage_pdf_aliases "Rotate PDF files.\nUsage:\n  pdf-rotate <pdf_or_dir> [more_inputs...] --degrees <90|180|270> [options]\n\nOptions:\n  -d, --degrees <90|180|270>   Rotation degrees\n  -o, --output-dir <dir>       Output root directory\n  -h, --help                   Show this help\n\nExamples:\n  pdf-rotate report.pdf --degrees 90\n  pdf-rotate ./docs -d 180 -o ./exports/rotated"
    return 1
  fi

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -d|--degrees)
        if [[ -z "${2:-}" ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        degree_name="$2"
        shift 2
        ;;
      -o|--output-dir)
        if [[ -z "${2:-}" ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        output_root="$2"
        shift 2
        ;;
      -h|--help)
        _pdf_show_usage_pdf_aliases "Rotate PDF files.\nUsage:\n  pdf-rotate <pdf_or_dir> [more_inputs...] --degrees <90|180|270> [options]\n\nOptions:\n  -d, --degrees <90|180|270>   Rotation degrees\n  -o, --output-dir <dir>       Output root directory\n  -h, --help                   Show this help"
        return 0
        ;;
      -*)
        _pdf_show_error_pdf_aliases "Error: Unknown option \"$1\"."
        return 1
        ;;
      *)
        input_items+=("$1")
        shift
        ;;
    esac
  done

  if [[ "${#input_items[@]}" -eq 0 ]]; then
    _pdf_show_error_pdf_aliases "Error: At least one PDF file or directory is required."
    return 1
  fi

  if [[ -z "$degree_name" ]]; then
    _pdf_show_error_pdf_aliases "Error: Rotation degrees are required."
    return 1
  fi

  rotation_token="$(_pdf_rotation_token_pdf_aliases "$degree_name")" || return 1

  if ! _pdf_require_commands_pdf_aliases pdftk; then
    return 1
  fi

  if ! _pdf_read_inputs_pdf_aliases "${input_items[@]}"; then
    return 1
  fi
  pdf_items=("${_PDF_COLLECTED_ITEMS_PDF_ALIASES[@]}")

  total_count="${#pdf_items[@]}"
  for source_pdf in "${pdf_items[@]}"; do
    output_pdf="$(_pdf_build_output_pdf_aliases "$source_pdf" "_rotated_${degree_name}" ".pdf" "$output_root")" || return 1

    printf "%s\n" "Rotating \"$source_pdf\" by ${degree_name} degrees..."
    if pdftk "$source_pdf" rotate "$rotation_token" output "$output_pdf"; then
      printf "%s\n" "Saved \"$output_pdf\"."
      success_count=$((success_count + 1))
    else
      _pdf_show_warning_pdf_aliases "Warning: Failed to rotate \"$source_pdf\"."
    fi
  done

  _pdf_summary_pdf_aliases "PDF rotation" "$total_count" "$success_count"
}

_pdf_extract_pdf_aliases() {
  local start_name=""
  local end_name=""
  local output_root=""
  local -a input_items=()
  local -a pdf_items=()
  local source_pdf=""
  local output_pdf=""
  local total_count="0"
  local success_count="0"

  if [[ "$#" -eq 0 ]]; then
    _pdf_show_usage_pdf_aliases "Extract page ranges from PDF files.\nUsage:\n  pdf-extract <pdf_or_dir> [more_inputs...] --start <page> --end <page> [options]\n\nOptions:\n  -s, --start <page>       Start page number\n  -e, --end <page>         End page number\n  -o, --output-dir <dir>   Output root directory\n  -h, --help               Show this help\n\nExamples:\n  pdf-extract report.pdf --start 2 --end 5\n  pdf-extract ./docs -s 1 -e 3 -o ./exports/ranges"
    return 1
  fi

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -s|--start)
        if [[ -z "${2:-}" ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        start_name="$2"
        shift 2
        ;;
      -e|--end)
        if [[ -z "${2:-}" ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        end_name="$2"
        shift 2
        ;;
      -o|--output-dir)
        if [[ -z "${2:-}" ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        output_root="$2"
        shift 2
        ;;
      -h|--help)
        _pdf_show_usage_pdf_aliases "Extract page ranges from PDF files.\nUsage:\n  pdf-extract <pdf_or_dir> [more_inputs...] --start <page> --end <page> [options]\n\nOptions:\n  -s, --start <page>       Start page number\n  -e, --end <page>         End page number\n  -o, --output-dir <dir>   Output root directory\n  -h, --help               Show this help"
        return 0
        ;;
      -*)
        _pdf_show_error_pdf_aliases "Error: Unknown option \"$1\"."
        return 1
        ;;
      *)
        input_items+=("$1")
        shift
        ;;
    esac
  done

  if [[ "${#input_items[@]}" -eq 0 ]]; then
    _pdf_show_error_pdf_aliases "Error: At least one PDF file or directory is required."
    return 1
  fi

  if [[ -z "$start_name" ]] || [[ -z "$end_name" ]]; then
    _pdf_show_error_pdf_aliases "Error: Both start and end page numbers are required."
    return 1
  fi

  if ! _pdf_validate_positive_integer_pdf_aliases "$start_name" "Start page"; then
    return 1
  fi

  if ! _pdf_validate_positive_integer_pdf_aliases "$end_name" "End page"; then
    return 1
  fi

  if [[ "$end_name" -lt "$start_name" ]]; then
    _pdf_show_error_pdf_aliases "Error: End page must be greater than or equal to start page."
    return 1
  fi

  if ! _pdf_require_commands_pdf_aliases pdftk; then
    return 1
  fi

  if ! _pdf_read_inputs_pdf_aliases "${input_items[@]}"; then
    return 1
  fi
  pdf_items=("${_PDF_COLLECTED_ITEMS_PDF_ALIASES[@]}")

  total_count="${#pdf_items[@]}"
  for source_pdf in "${pdf_items[@]}"; do
    output_pdf="$(_pdf_build_output_pdf_aliases "$source_pdf" "_p${start_name}-${end_name}" ".pdf" "$output_root")" || return 1

    printf "%s\n" "Extracting pages ${start_name}-${end_name} from \"$source_pdf\"..."
    if pdftk "$source_pdf" cat "${start_name}-${end_name}" output "$output_pdf"; then
      printf "%s\n" "Saved \"$output_pdf\"."
      success_count=$((success_count + 1))
    else
      _pdf_show_warning_pdf_aliases "Warning: Failed to extract pages from \"$source_pdf\"."
    fi
  done

  _pdf_summary_pdf_aliases "PDF extract" "$total_count" "$success_count"
}

_pdf_to_image_pdf_pdf_aliases() {
  local density_value="300"
  local format_name="png"
  local output_root=""
  local command_flag="-png"
  local image_suffix="png"
  local -a input_items=()
  local -a pdf_items=()
  local source_pdf=""
  local output_pdf=""
  local work_root=""
  local total_count="0"
  local success_count="0"
  local original_size=""
  local rendered_size=""

  if [[ "$#" -eq 0 ]]; then
    _pdf_show_usage_pdf_aliases "Convert PDF files to image-based PDFs.\nUsage:\n  pdf-to-image-pdf <pdf_or_dir> [more_inputs...] [options]\n\nOptions:\n  -d, --density <dpi>      Render density, default: 300\n  -f, --format <png|jpg|jpeg>   Intermediate image format, default: png\n  -o, --output-dir <dir>   Output root directory\n  -h, --help               Show this help\n\nExamples:\n  pdf-to-image-pdf report.pdf\n  pdf-to-image-pdf ./docs --density 200 --format jpg\n  pdf-to-image-pdf report.pdf ./archive -o ./exports/image-pdf"
    return 1
  fi

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -d|--density)
        if [[ -z "${2:-}" ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        density_value="$2"
        shift 2
        ;;
      -f|--format)
        if [[ -z "${2:-}" ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        format_name="$2"
        shift 2
        ;;
      -o|--output-dir)
        if [[ -z "${2:-}" ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        output_root="$2"
        shift 2
        ;;
      -h|--help)
        _pdf_show_usage_pdf_aliases "Convert PDF files to image-based PDFs.\nUsage:\n  pdf-to-image-pdf <pdf_or_dir> [more_inputs...] [options]\n\nOptions:\n  -d, --density <dpi>      Render density, default: 300\n  -f, --format <png|jpg|jpeg>   Intermediate image format, default: png\n  -o, --output-dir <dir>   Output root directory\n  -h, --help               Show this help"
        return 0
        ;;
      -*)
        _pdf_show_error_pdf_aliases "Error: Unknown option \"$1\"."
        return 1
        ;;
      *)
        input_items+=("$1")
        shift
        ;;
    esac
  done

  if [[ "${#input_items[@]}" -eq 0 ]]; then
    _pdf_show_error_pdf_aliases "Error: At least one PDF file or directory is required."
    return 1
  fi

  if ! _pdf_validate_positive_integer_pdf_aliases "$density_value" "Density"; then
    return 1
  fi

  if ! _pdf_validate_image_format_pdf_aliases "$format_name"; then
    return 1
  fi

  if [[ "$format_name" == "jpg" ]] || [[ "$format_name" == "jpeg" ]]; then
    command_flag="-jpeg"
    image_suffix="jpg"
  fi

  if ! _pdf_require_commands_pdf_aliases pdftoppm magick; then
    return 1
  fi

  if ! _pdf_read_inputs_pdf_aliases "${input_items[@]}"; then
    return 1
  fi
  pdf_items=("${_PDF_COLLECTED_ITEMS_PDF_ALIASES[@]}")

  total_count="${#pdf_items[@]}"
  for source_pdf in "${pdf_items[@]}"; do
    output_pdf="$(_pdf_build_output_pdf_aliases "$source_pdf" "_image_${density_value}dpi" ".pdf" "$output_root")" || return 1
    work_root="$(mktemp -d "${TMPDIR:-/tmp}/pdf_aliases_image_XXXXXX")"

    if [[ -z "$work_root" ]] || [[ ! -d "$work_root" ]]; then
      _pdf_show_warning_pdf_aliases "Warning: Failed to create temporary directory for \"$source_pdf\"."
      continue
    fi

    printf "%s\n" "Rendering \"$source_pdf\" as an image-based PDF..."
    if ! pdftoppm -r "$density_value" "$command_flag" "$source_pdf" "${work_root}/page"; then
      _pdf_show_warning_pdf_aliases "Warning: Failed to render \"$source_pdf\" to images."
      rm -rf "$work_root"
      continue
    fi

    if magick "${work_root}"/page-*."${image_suffix}" "$output_pdf"; then
      original_size="$(_pdf_human_size_pdf_aliases "$source_pdf")"
      rendered_size="$(_pdf_human_size_pdf_aliases "$output_pdf")"
      printf "%s\n" "Saved \"$output_pdf\" (${original_size} -> ${rendered_size})."
      success_count=$((success_count + 1))
    else
      _pdf_show_warning_pdf_aliases "Warning: Failed to rebuild \"$source_pdf\" as an image PDF."
    fi

    rm -rf "$work_root"
  done

  _pdf_summary_pdf_aliases "PDF to image PDF" "$total_count" "$success_count"
}

_pdf_to_text_pdf_aliases() {
  local output_root=""
  local -a input_items=()
  local -a pdf_items=()
  local source_pdf=""
  local output_text=""
  local total_count="0"
  local success_count="0"

  if [[ "$#" -eq 0 ]]; then
    _pdf_show_usage_pdf_aliases "Extract text from PDF files.\nUsage:\n  pdf-to-text <pdf_or_dir> [more_inputs...] [options]\n\nOptions:\n  -o, --output-dir <dir>   Output root directory\n  -h, --help               Show this help\n\nExamples:\n  pdf-to-text report.pdf\n  pdf-to-text ./docs -o ./exports/text"
    return 1
  fi

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -o|--output-dir)
        if [[ -z "${2:-}" ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        output_root="$2"
        shift 2
        ;;
      -h|--help)
        _pdf_show_usage_pdf_aliases "Extract text from PDF files.\nUsage:\n  pdf-to-text <pdf_or_dir> [more_inputs...] [options]\n\nOptions:\n  -o, --output-dir <dir>   Output root directory\n  -h, --help               Show this help"
        return 0
        ;;
      -*)
        _pdf_show_error_pdf_aliases "Error: Unknown option \"$1\"."
        return 1
        ;;
      *)
        input_items+=("$1")
        shift
        ;;
    esac
  done

  if [[ "${#input_items[@]}" -eq 0 ]]; then
    _pdf_show_error_pdf_aliases "Error: At least one PDF file or directory is required."
    return 1
  fi

  if ! _pdf_require_commands_pdf_aliases pdftotext; then
    return 1
  fi

  if ! _pdf_read_inputs_pdf_aliases "${input_items[@]}"; then
    return 1
  fi
  pdf_items=("${_PDF_COLLECTED_ITEMS_PDF_ALIASES[@]}")

  total_count="${#pdf_items[@]}"
  for source_pdf in "${pdf_items[@]}"; do
    output_text="$(_pdf_build_output_pdf_aliases "$source_pdf" "" ".txt" "$output_root")" || return 1

    printf "%s\n" "Extracting text from \"$source_pdf\"..."
    if pdftotext "$source_pdf" "$output_text"; then
      printf "%s\n" "Saved \"$output_text\"."
      success_count=$((success_count + 1))
    else
      _pdf_show_warning_pdf_aliases "Warning: Failed to extract text from \"$source_pdf\"."
    fi
  done

  _pdf_summary_pdf_aliases "PDF to text" "$total_count" "$success_count"
}

_pdf_watermark_pdf_aliases() {
  local -a input_items=()
  local -a pdf_items=()
  local source_pdf=""
  local output_pdf=""
  local process_output_pdf=""
  local output_root=""
  local target_root=""
  local existing_output_pdf=""
  local watermark_text=""
  local watermark_image=""
  local watermark_type=""
  local mode_name="repeat"
  local layer_name="over"
  local pages_name="all"
  local position_name="center"
  local opacity_value="0.1"
  local rotate_value="45"
  local scale_value="0.25"
  local width_value=""
  local margin_value="36"
  local font_size_value="48"
  local font_color_value="#888888"
  local font_name="helv"
  local spacing_x_value="240"
  local spacing_y_value="160"
  local x_value=""
  local y_value=""
  local suffix_name="_watermarked"
  local overwrite_flag="0"
  local dry_run_flag="0"
  local total_count="0"
  local success_count="0"
  local -a planned_outputs=()

  if [[ "$#" -eq 0 ]]; then
    _pdf_show_usage_pdf_aliases "Add text or image watermarks to PDF files.\nUsage:\n  pdf-watermark <pdf_or_dir> [more_inputs...] (--text <text> | --image <path>) [options]\n\nDefaults:\n  pages=all, layer=over, opacity=0.1, rotate=45, mode=repeat\n\nOptions:\n  -t, --text <text>              Text watermark content\n  -i, --image <path>             Image watermark path, png/jpg/jpeg\n  --pages <value>                all, odd, even, first, last, or 1,3,5-8; default: all\n  --mode <single|repeat>         Watermark layout mode, default: repeat\n  --layer <over|under>           Draw above or below page content, default: over\n  -p, --position <position>      single mode position, default: center\n  --x <pt>                       Custom x coordinate for single mode\n  --y <pt>                       Custom y coordinate for single mode\n  --margin <pt>                  Position margin, default: 36\n  --opacity <0.0-1.0>            Watermark opacity, default: 0.1\n  --rotate <degrees>             Rotation angle, default: 45\n  --scale <ratio>                Image width ratio against page width, default: 0.25\n  --width <pt>                   Watermark width in points\n  --font-size <pt>               Text font size, default: 48\n  --font-color <color>           Text color, default: #888888\n  --font <name_or_path>          Built-in font name or font file path, default: helv\n  --spacing-x <pt>               Repeat horizontal spacing, default: 240\n  --spacing-y <pt>               Repeat vertical spacing, default: 160\n  --suffix <suffix>              Output suffix, default: _watermarked\n  -o, --output-dir <dir>         Output root directory\n  --overwrite                    Overwrite target files when they already exist\n  --dry-run                      Print planned operations without writing files\n  -h, --help                     Show this help\n\nExamples:\n  pdf-watermark report.pdf --text \"CONFIDENTIAL\"\n  pdf-watermark report.pdf --image logo.png --position bottom-right --mode single\n  pdf-watermark ./docs --text \"Draft\" --pages odd -o ./watermarked\n  pdf-watermark a.pdf b.pdf --text \"Internal\" --pages 1,3,5-8 --layer over\n\nNote:\n  This command requires python3 and PyMuPDF. Install with: python3 -m pip install pymupdf\n  Use straight ASCII quotes in shell commands; mixed smart and ASCII quotes can leave the shell waiting.\n  Under-layer watermarks can be hidden by opaque scanned page images."
    return 0
  fi

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -t|--text)
        if [[ "$#" -lt 2 ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        watermark_text="$2"
        shift 2
        ;;
      -i|--image)
        if [[ "$#" -lt 2 ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        watermark_image="$2"
        shift 2
        ;;
      --pages)
        if [[ "$#" -lt 2 ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        pages_name="$2"
        shift 2
        ;;
      --mode)
        if [[ "$#" -lt 2 ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        mode_name="$2"
        shift 2
        ;;
      --layer)
        if [[ "$#" -lt 2 ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        layer_name="$2"
        shift 2
        ;;
      -p|--position)
        if [[ "$#" -lt 2 ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        position_name="$2"
        shift 2
        ;;
      --x)
        if [[ "$#" -lt 2 ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        x_value="$2"
        shift 2
        ;;
      --y)
        if [[ "$#" -lt 2 ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        y_value="$2"
        shift 2
        ;;
      --margin)
        if [[ "$#" -lt 2 ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        margin_value="$2"
        shift 2
        ;;
      --opacity)
        if [[ "$#" -lt 2 ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        opacity_value="$2"
        shift 2
        ;;
      --rotate)
        if [[ "$#" -lt 2 ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        rotate_value="$2"
        shift 2
        ;;
      --scale)
        if [[ "$#" -lt 2 ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        scale_value="$2"
        shift 2
        ;;
      --width)
        if [[ "$#" -lt 2 ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        width_value="$2"
        shift 2
        ;;
      --font-size)
        if [[ "$#" -lt 2 ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        font_size_value="$2"
        shift 2
        ;;
      --font-color)
        if [[ "$#" -lt 2 ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        font_color_value="$2"
        shift 2
        ;;
      --font)
        if [[ "$#" -lt 2 ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        font_name="$2"
        shift 2
        ;;
      --spacing-x)
        if [[ "$#" -lt 2 ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        spacing_x_value="$2"
        shift 2
        ;;
      --spacing-y)
        if [[ "$#" -lt 2 ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        spacing_y_value="$2"
        shift 2
        ;;
      --suffix)
        if [[ "$#" -lt 2 ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        suffix_name="$2"
        shift 2
        ;;
      -o|--output-dir)
        if [[ "$#" -lt 2 ]]; then
          _pdf_show_error_pdf_aliases "Error: Missing value for $1."
          return 1
        fi
        output_root="$2"
        shift 2
        ;;
      --overwrite)
        overwrite_flag="1"
        shift
        ;;
      --dry-run)
        dry_run_flag="1"
        shift
        ;;
      -h|--help)
        _pdf_watermark_pdf_aliases
        return 0
        ;;
      --)
        shift
        while [[ "$#" -gt 0 ]]; do
          input_items+=("$1")
          shift
        done
        ;;
      -*)
        _pdf_show_error_pdf_aliases "Error: Unknown option \"$1\"."
        return 1
        ;;
      *)
        input_items+=("$1")
        shift
        ;;
    esac
  done

  if [[ "${#input_items[@]}" -eq 0 ]]; then
    _pdf_show_error_pdf_aliases "Error: At least one PDF file or directory is required."
    return 1
  fi

  if [[ -n "$watermark_text" && -n "$watermark_image" ]]; then
    _pdf_show_error_pdf_aliases "Error: Use either --text or --image, not both."
    return 1
  fi

  if [[ -z "$watermark_text" && -z "$watermark_image" ]]; then
    _pdf_show_error_pdf_aliases "Error: Either --text or --image is required."
    return 1
  fi

  if [[ -n "$watermark_text" ]]; then
    watermark_type="text"
  else
    watermark_type="image"
    if ! _pdf_validate_watermark_image_pdf_aliases "$watermark_image"; then
      return 1
    fi
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    _pdf_show_error_pdf_aliases "Error: Required command \"python3\" not found. Please install it first."
    return 1
  fi

  if ! _pdf_validate_watermark_mode_pdf_aliases "$mode_name"; then
    return 1
  fi

  if ! _pdf_validate_watermark_layer_pdf_aliases "$layer_name"; then
    return 1
  fi

  if ! _pdf_validate_watermark_pages_pdf_aliases "$pages_name"; then
    return 1
  fi

  if ! _pdf_validate_watermark_position_pdf_aliases "$position_name"; then
    return 1
  fi

  if ! _pdf_validate_decimal_range_pdf_aliases "$opacity_value" "Opacity" "0" "1"; then
    return 1
  fi

  if ! _pdf_validate_integer_pdf_aliases "$rotate_value" "Rotation angle"; then
    return 1
  fi

  if ! _pdf_validate_decimal_range_pdf_aliases "$scale_value" "Scale" "0.01" "5"; then
    return 1
  fi

  if [[ -n "$width_value" ]] && ! _pdf_validate_decimal_range_pdf_aliases "$width_value" "Width" "1" "10000"; then
    return 1
  fi

  if ! _pdf_validate_decimal_range_pdf_aliases "$margin_value" "Margin" "0" "10000"; then
    return 1
  fi

  if ! _pdf_validate_positive_integer_pdf_aliases "$font_size_value" "Font size"; then
    return 1
  fi

  if ! _pdf_validate_watermark_color_pdf_aliases "$font_color_value"; then
    return 1
  fi

  if ! _pdf_validate_decimal_range_pdf_aliases "$spacing_x_value" "Horizontal spacing" "1" "10000"; then
    return 1
  fi

  if ! _pdf_validate_decimal_range_pdf_aliases "$spacing_y_value" "Vertical spacing" "1" "10000"; then
    return 1
  fi

  if [[ -n "$x_value" ]] && ! _pdf_validate_decimal_range_pdf_aliases "$x_value" "X coordinate" "-100000" "100000"; then
    return 1
  fi

  if [[ -n "$y_value" ]] && ! _pdf_validate_decimal_range_pdf_aliases "$y_value" "Y coordinate" "-100000" "100000"; then
    return 1
  fi

  if [[ ( -n "$x_value" && -z "$y_value" ) || ( -z "$x_value" && -n "$y_value" ) ]]; then
    _pdf_show_error_pdf_aliases "Error: --x and --y must be provided together."
    return 1
  fi

  if [[ -z "$suffix_name" ]]; then
    _pdf_show_error_pdf_aliases "Error: Output suffix cannot be empty."
    return 1
  fi

  if [[ "$dry_run_flag" != "1" ]] && ! python3 - <<PYTHON_CHECK_PYMUPDF
try:
    import fitz
except Exception:
    raise SystemExit(1)
PYTHON_CHECK_PYMUPDF
  then
    _pdf_show_error_pdf_aliases "Error: Python package \"PyMuPDF\" is required. Install it with: python3 -m pip install pymupdf"
    return 1
  fi

  if ! _pdf_read_inputs_pdf_aliases "${input_items[@]}"; then
    return 1
  fi

  pdf_items=("${_PDF_COLLECTED_ITEMS_PDF_ALIASES[@]}")
  total_count="${#pdf_items[@]}"

  if [[ "$overwrite_flag" == "1" ]]; then
    for source_pdf in "${pdf_items[@]}"; do
      output_pdf="$(_pdf_build_output_path_pdf_aliases "$source_pdf" "$suffix_name" ".pdf" "$output_root")" || return 1
      if _pdf_output_target_seen_pdf_aliases "$output_pdf" "${planned_outputs[@]}"; then
        existing_output_pdf="$output_pdf"
        _pdf_show_error_pdf_aliases "Error: Multiple inputs would write to \"$existing_output_pdf\". Use unique filenames or a different output directory."
        return 1
      fi
      planned_outputs+=("$output_pdf")
    done
  fi

  planned_outputs=()
  for source_pdf in "${pdf_items[@]}"; do
    if [[ "$overwrite_flag" == "1" ]]; then
      output_pdf="$(_pdf_build_output_path_pdf_aliases "$source_pdf" "$suffix_name" ".pdf" "$output_root")" || return 1
      if [[ -n "$output_root" ]]; then
        target_root="$output_root"
      else
        target_root="$(dirname "$source_pdf")"
      fi
      if [[ "$output_pdf" == "$source_pdf" ]]; then
        _pdf_show_warning_pdf_aliases "Warning: Skipping \"$source_pdf\" because output would overwrite the source file."
        continue
      fi
    else
      if [[ "$dry_run_flag" == "1" ]]; then
        output_pdf="$(_pdf_build_output_path_pdf_aliases "$source_pdf" "$suffix_name" ".pdf" "$output_root")" || return 1
        output_pdf="$(_pdf_unique_target_with_planned_pdf_aliases "$output_pdf" "${planned_outputs[@]}")" || return 1
      else
        output_pdf="$(_pdf_build_output_pdf_aliases "$source_pdf" "$suffix_name" ".pdf" "$output_root")" || return 1
      fi
    fi

    if [[ "$dry_run_flag" == "1" ]]; then
      planned_outputs+=("$output_pdf")
      printf "%s\n" "Would watermark \"$source_pdf\" -> \"$output_pdf\" (${watermark_type}, mode=${mode_name}, layer=${layer_name}, pages=${pages_name})."
      success_count=$((success_count + 1))
      continue
    fi

    if [[ "$overwrite_flag" == "1" ]]; then
      if [[ -n "$output_root" ]]; then
        if ! _pdf_ensure_directory_pdf_aliases "$target_root"; then
          return 1
        fi
      fi
      process_output_pdf="$(mktemp "${TMPDIR:-/tmp}/pdf_aliases_watermark_XXXXXX")"
      if [[ -z "$process_output_pdf" ]]; then
        _pdf_show_warning_pdf_aliases "Warning: Failed to create temporary output for \"$source_pdf\"."
        continue
      fi
    else
      process_output_pdf="$output_pdf"
    fi

    printf "%s\n" "Watermarking \"$source_pdf\"..."
    if python3 - "$source_pdf" "$process_output_pdf" "$watermark_type" "$watermark_text" "$watermark_image" "$mode_name" "$layer_name" "$pages_name" "$position_name" "$opacity_value" "$rotate_value" "$scale_value" "$width_value" "$margin_value" "$font_size_value" "$font_color_value" "$font_name" "$spacing_x_value" "$spacing_y_value" "$x_value" "$y_value" <<PYTHON_WATERMARK_PDF
import os
import sys

try:
    import fitz
except Exception as exc:
    print(f"Error: Failed to import PyMuPDF: {exc}", file=sys.stderr)
    raise SystemExit(1)

fitz.TOOLS.mupdf_display_errors(False)
fitz.TOOLS.mupdf_display_warnings(False)


source_pdf = sys.argv[1]
output_pdf = sys.argv[2]
watermark_type = sys.argv[3]
watermark_text = sys.argv[4]
watermark_image = sys.argv[5]
mode_name = sys.argv[6]
layer_name = sys.argv[7]
pages_name = sys.argv[8]
position_name = sys.argv[9]
opacity_value = float(sys.argv[10])
rotate_value = int(sys.argv[11])
scale_value = float(sys.argv[12])
width_value = sys.argv[13]
margin_value = float(sys.argv[14])
font_size_value = float(sys.argv[15])
font_color_value = sys.argv[16]
font_name = sys.argv[17]
spacing_x_value = float(sys.argv[18])
spacing_y_value = float(sys.argv[19])
x_value = sys.argv[20]
y_value = sys.argv[21]


def normalize_watermark_text(text):
    quote_pairs = {
        "\u201c": "\u201d",
        "\u2018": "\u2019",
    }
    if len(text) >= 2 and quote_pairs.get(text[0]) == text[-1]:
        return text[1:-1]
    return text


watermark_text = normalize_watermark_text(watermark_text)


def needs_cjk_font(text):
    return any(ord(character) > 127 for character in text)


def resolve_text_font():
    if os.path.isfile(font_name):
        return os.path.splitext(os.path.basename(font_name))[0].replace(" ", ""), font_name
    if font_name == "helv" and needs_cjk_font(watermark_text):
        return "china-s", None
    return font_name, None


def measure_text_width(text, font_alias, font_file):
    if font_file:
        return fitz.Font(fontfile=font_file).text_length(text, fontsize=font_size_value)
    return fitz.get_text_length(text, fontname=font_alias, fontsize=font_size_value)


def parse_color(color_name):
    named_colors = {
        "black": (0, 0, 0),
        "white": (1, 1, 1),
        "gray": (0.5, 0.5, 0.5),
        "grey": (0.5, 0.5, 0.5),
        "red": (1, 0, 0),
        "green": (0, 0.5, 0),
        "blue": (0, 0, 1),
        "yellow": (1, 1, 0),
        "orange": (1, 0.55, 0),
        "purple": (0.5, 0, 0.5),
    }
    if color_name in named_colors:
        return named_colors[color_name]
    if color_name.startswith("#") and len(color_name) == 7:
        red_value = int(color_name[1:3], 16) / 255
        green_value = int(color_name[3:5], 16) / 255
        blue_value = int(color_name[5:7], 16) / 255
        return (red_value, green_value, blue_value)
    raise ValueError(f"Invalid color: {color_name}")


def parse_pages(page_spec, page_count):
    if page_spec == "all":
        return list(range(page_count))
    if page_spec == "odd":
        return [index for index in range(page_count) if index % 2 == 0]
    if page_spec == "even":
        return [index for index in range(page_count) if index % 2 == 1]
    if page_spec == "first":
        return [0] if page_count else []
    if page_spec == "last":
        return [page_count - 1] if page_count else []

    selected_pages = []
    for token in page_spec.split(","):
        if "-" in token:
            start_text, end_text = token.split("-", 1)
            start_page = int(start_text)
            end_page = int(end_text)
        else:
            start_page = int(token)
            end_page = start_page

        if start_page < 1 or end_page < start_page or end_page > page_count:
            raise ValueError(f"Page range out of bounds: {token}")

        selected_pages.extend(range(start_page - 1, end_page))

    return sorted(set(selected_pages))


def make_text_stamp(page_width):
    font_alias, font_file = resolve_text_font()
    if width_value:
        stamp_width = float(width_value)
    else:
        try:
            text_width = measure_text_width(watermark_text, font_alias, font_file)
        except Exception:
            text_width = font_size_value * max(len(watermark_text), 1) * 0.7
        stamp_width = max(text_width + font_size_value, 120, page_width * 0.25)
    stamp_height = max(font_size_value * 2.4, 32)

    for _attempt in range(4):
        stamp_doc = fitz.open()
        stamp_page = stamp_doc.new_page(width=stamp_width, height=stamp_height)
        insert_result = stamp_page.insert_textbox(
            fitz.Rect(0, 0, stamp_width, stamp_height),
            watermark_text,
            fontsize=font_size_value,
            fontname=font_alias,
            fontfile=font_file,
            color=parse_color(font_color_value),
            fill_opacity=opacity_value,
            align=fitz.TEXT_ALIGN_CENTER,
            overlay=True,
        )
        if insert_result >= 0:
            return stamp_doc, stamp_width, stamp_height

        stamp_doc.close()
        stamp_width *= 1.25
        stamp_height *= 1.25

    raise ValueError("Text watermark does not fit the generated stamp area")


def make_image_stamp(page_width):
    source_pixmap = fitz.Pixmap(watermark_image)
    if source_pixmap.n >= 5:
        source_pixmap = fitz.Pixmap(fitz.csRGB, source_pixmap)
    if source_pixmap.alpha:
        alpha_samples = source_pixmap.samples[source_pixmap.n - 1::source_pixmap.n]
        alpha_bytes = bytes(max(0, min(255, int(round(alpha * opacity_value)))) for alpha in alpha_samples)
    else:
        source_pixmap = fitz.Pixmap(source_pixmap, 1)
        alpha_value = max(0, min(255, int(round(opacity_value * 255))))
        alpha_bytes = bytes([alpha_value]) * (source_pixmap.width * source_pixmap.height)
    source_pixmap.set_alpha(alpha_bytes)

    image_width = float(width_value) if width_value else max(page_width * scale_value, 1)
    image_height = image_width * source_pixmap.height / source_pixmap.width
    stamp_doc = fitz.open()
    stamp_page = stamp_doc.new_page(width=image_width, height=image_height)
    stamp_page.insert_image(
        fitz.Rect(0, 0, image_width, image_height),
        pixmap=source_pixmap,
        keep_proportion=True,
        overlay=True,
    )
    return stamp_doc, image_width, image_height


def get_single_rect(page_rect, stamp_width, stamp_height):
    page_width = page_rect.width
    page_height = page_rect.height
    if x_value and y_value:
        left = float(x_value)
        top = float(y_value)
        return fitz.Rect(left, top, left + stamp_width, top + stamp_height)

    horizontal_center = (page_width - stamp_width) / 2
    vertical_center = (page_height - stamp_height) / 2
    positions = {
        "center": (horizontal_center, vertical_center),
        "top-left": (margin_value, margin_value),
        "top": (horizontal_center, margin_value),
        "top-right": (page_width - stamp_width - margin_value, margin_value),
        "left": (margin_value, vertical_center),
        "right": (page_width - stamp_width - margin_value, vertical_center),
        "bottom-left": (margin_value, page_height - stamp_height - margin_value),
        "bottom": (horizontal_center, page_height - stamp_height - margin_value),
        "bottom-right": (page_width - stamp_width - margin_value, page_height - stamp_height - margin_value),
    }
    left, top = positions[position_name]
    return fitz.Rect(left, top, left + stamp_width, top + stamp_height)


def get_repeat_rects(page_rect, stamp_width, stamp_height):
    page_width = page_rect.width
    page_height = page_rect.height
    rects = []
    start_x = -stamp_width
    start_y = -stamp_height
    end_x = page_width + stamp_width
    end_y = page_height + stamp_height
    y_pos = start_y
    while y_pos <= end_y:
        x_pos = start_x
        while x_pos <= end_x:
            rects.append(fitz.Rect(x_pos, y_pos, x_pos + stamp_width, y_pos + stamp_height))
            x_pos += spacing_x_value
        y_pos += spacing_y_value
    return rects


try:
    source_doc = fitz.open(source_pdf)
    selected_pages = parse_pages(pages_name, source_doc.page_count)
    overlay_flag = layer_name == "over"

    if not selected_pages:
        raise ValueError("No pages selected")

    for page_index in selected_pages:
        page = source_doc[page_index]
        page_rect = page.rect
        if watermark_type == "text":
            stamp_doc, stamp_width, stamp_height = make_text_stamp(page_rect.width)
        else:
            stamp_doc, stamp_width, stamp_height = make_image_stamp(page_rect.width)

        if mode_name == "repeat":
            target_rects = get_repeat_rects(page_rect, stamp_width, stamp_height)
        else:
            target_rects = [get_single_rect(page_rect, stamp_width, stamp_height)]

        for target_rect in target_rects:
            page.show_pdf_page(
                target_rect,
                stamp_doc,
                0,
                keep_proportion=True,
                overlay=overlay_flag,
                rotate=rotate_value,
            )
        stamp_doc.close()

    source_doc.save(output_pdf, garbage=4, deflate=True)
    source_doc.close()
except Exception as exc:
    print(f"Error: Failed to watermark PDF: {exc}", file=sys.stderr)
    raise SystemExit(1)
PYTHON_WATERMARK_PDF
    then
      if [[ "$process_output_pdf" != "$output_pdf" ]]; then
        if mv -f "$process_output_pdf" "$output_pdf"; then
          printf "%s\n" "Saved \"$output_pdf\"."
          success_count=$((success_count + 1))
        else
          _pdf_show_warning_pdf_aliases "Warning: Failed to move temporary output to \"$output_pdf\"."
          rm -f "$process_output_pdf"
        fi
      else
        printf "%s\n" "Saved \"$output_pdf\"."
        success_count=$((success_count + 1))
      fi
    else
      _pdf_show_warning_pdf_aliases "Warning: Failed to watermark \"$source_pdf\"."
      rm -f "$process_output_pdf"
    fi
  done

  _pdf_summary_pdf_aliases "PDF watermark" "$total_count" "$success_count"
}

_pdf_help_pdf_aliases() {
  _pdf_show_usage_pdf_aliases "PDF alias overview\n\nAll commands accept one or more PDF files or directories unless noted otherwise.\nDirectory inputs are scanned recursively.\n\nCommands:\n  pdf-info              Show metadata for one or more PDFs\n  pdf-to-images         Export pages to png or jpg images\n  pdf-to-jpg            Shortcut for pdf-to-images --format jpg\n  pdf-compress          Compress one or more PDFs\n  pdf-watermark         Add text or image watermarks to one or more PDFs\n  pdf-encrypt           Encrypt one or more PDFs\n  pdf-merge             Merge many PDFs into one output file\n  pdf-split             Split PDFs into single-page PDFs\n  pdf-rotate            Rotate PDFs by 90, 180, or 270 degrees\n  pdf-extract           Export a page range from one or more PDFs\n  pdf-to-image-pdf      Rebuild PDFs as image-based PDFs\n  pdf-to-text           Export text from one or more PDFs\n\nCompatibility wrappers:\n  pdf-batch-to-images\n  pdf-batch-compress\n  pdf-batch-to-image-pdf\n\nRun any command with --help for detailed usage."
}

_pdf_batch_to_images_pdf_aliases() {
  _pdf_to_images_pdf_aliases "$@"
}

_pdf_batch_compress_pdf_aliases() {
  _pdf_compress_pdf_aliases "$@"
}

_pdf_batch_to_image_pdf_pdf_aliases() {
  _pdf_to_image_pdf_pdf_aliases "$@"
}

# PDF Aliases
# ### --- ###
alias pdf-info='() { _pdf_info_pdf_aliases "$@"; }'
alias pdf-to-images='() { _pdf_to_images_pdf_aliases "$@"; }'
alias pdf-batch-to-images='() { _pdf_batch_to_images_pdf_aliases "$@"; }'
alias pdf-to-jpg='() { _pdf_to_jpg_pdf_aliases "$@"; }'
alias pdf-compress='() { _pdf_compress_pdf_aliases "$@"; }'
alias pdf-batch-compress='() { _pdf_batch_compress_pdf_aliases "$@"; }'
alias pdf-watermark='() { _pdf_watermark_pdf_aliases "$@"; }'
alias pdf-encrypt='() { _pdf_encrypt_pdf_aliases "$@"; }'
alias pdf-merge='() { _pdf_merge_pdf_aliases "$@"; }'
alias pdf-split='() { _pdf_split_pdf_aliases "$@"; }'
alias pdf-rotate='() { _pdf_rotate_pdf_aliases "$@"; }'
alias pdf-extract='() { _pdf_extract_pdf_aliases "$@"; }'
alias pdf-to-image-pdf='() { _pdf_to_image_pdf_pdf_aliases "$@"; }'
alias pdf-batch-to-image-pdf='() { _pdf_batch_to_image_pdf_pdf_aliases "$@"; }'
alias pdf-to-text='() { _pdf_to_text_pdf_aliases "$@"; }'
alias pdf-help='() { _pdf_help_pdf_aliases "$@"; }'
