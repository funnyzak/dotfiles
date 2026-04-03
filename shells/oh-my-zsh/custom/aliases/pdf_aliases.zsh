# Description: PDF related aliases for inspection, export, compression, encryption, merge, split, and batch manipulation.

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

_pdf_help_pdf_aliases() {
  _pdf_show_usage_pdf_aliases "PDF alias overview\n\nAll commands accept one or more PDF files or directories unless noted otherwise.\nDirectory inputs are scanned recursively.\n\nCommands:\n  pdf-info              Show metadata for one or more PDFs\n  pdf-to-images         Export pages to png or jpg images\n  pdf-to-jpg            Shortcut for pdf-to-images --format jpg\n  pdf-compress          Compress one or more PDFs\n  pdf-encrypt           Encrypt one or more PDFs\n  pdf-merge             Merge many PDFs into one output file\n  pdf-split             Split PDFs into single-page PDFs\n  pdf-rotate            Rotate PDFs by 90, 180, or 270 degrees\n  pdf-extract           Export a page range from one or more PDFs\n  pdf-to-image-pdf      Rebuild PDFs as image-based PDFs\n  pdf-to-text           Export text from one or more PDFs\n\nCompatibility wrappers:\n  pdf-batch-to-images\n  pdf-batch-compress\n  pdf-batch-to-image-pdf\n\nRun any command with --help for detailed usage."
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
alias pdf-encrypt='() { _pdf_encrypt_pdf_aliases "$@"; }'
alias pdf-merge='() { _pdf_merge_pdf_aliases "$@"; }'
alias pdf-split='() { _pdf_split_pdf_aliases "$@"; }'
alias pdf-rotate='() { _pdf_rotate_pdf_aliases "$@"; }'
alias pdf-extract='() { _pdf_extract_pdf_aliases "$@"; }'
alias pdf-to-image-pdf='() { _pdf_to_image_pdf_pdf_aliases "$@"; }'
alias pdf-batch-to-image-pdf='() { _pdf_batch_to_image_pdf_pdf_aliases "$@"; }'
alias pdf-to-text='() { _pdf_to_text_pdf_aliases "$@"; }'
alias pdf-help='() { _pdf_help_pdf_aliases "$@"; }'
