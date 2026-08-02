# Description: Gemini Watermark Tool aliases for safe single-file, multi-file, and directory watermark removal workflows.

#------------------------------------------------------------------------------
# Helper Functions
#------------------------------------------------------------------------------

_gniwt_show_error_gniwt_aliases() {
  echo "Error: $1" >&2
  return 1
}

_gniwt_print_info_gniwt_aliases() {
  echo "$1"
}

_gniwt_show_usage_gniwt_aliases() {
  echo -e "Remove Gemini visible watermarks with safe wrapper defaults.\nUsage:\n  gniwt-rm [wrapper-options] <input_path ...> [-- upstream_args]\n\nWrapper options:\n  -o, --output PATH           Output file path for single file input\n  --output-dir DIR            Output directory for multiple files or directory input\n  --suffix TEXT               Output suffix for generated files or directories (default: _clean)\n  --in-place                  Process file inputs in place using the upstream simple mode\n  -h, --help                  Show this help message\n\nCommon upstream options:\n  -f, --force                 Skip watermark detection\n  -t, --threshold VALUE       Detection threshold, 0.0-1.0\n  --force-small               Force 48x48 watermark size\n  --force-large               Force 96x96 watermark size\n  --region SPEC               Explicit watermark region\n  --fallback-region SPEC      Fallback search region\n  --snap                      Enable snap search\n  --snap-min-size N           Snap min size\n  --snap-max-size N           Snap max size\n  --snap-threshold VALUE      Snap acceptance threshold\n  --denoise METHOD            Cleanup method: ai, ns, telea, soft, off\n  --sigma N                   AI denoise sigma\n  --strength N                Denoise strength percent\n  --radius N                  Inpaint radius\n  -v, --verbose               Verbose output\n  -q, --quiet                 Quiet output\n  -b, --banner                Show banner\n  --no-banner                 Hide banner\n\nEnvironment variables:\n  GNIWT_BIN                   Fallback binary path if PATH lookup fails\n  GWT_BIN                     Secondary fallback binary path\n  GEMINI_WATERMARK_TOOL_BIN   Tertiary fallback binary path\n\nExamples:\n  gniwt-rm image.png\n  gniwt-rm image1.png image2.png --output-dir ./cleaned --threshold 0.40\n  gniwt-rm ./input_dir --output-dir ./clean_dir --denoise ai\n  gniwt-rm --in-place image1.png image2.png -- --version"
}

_gniwt_help_gniwt_aliases() {
  echo "Gemini Watermark Tool alias commands"
  echo "  gniwt-rm    Safe wrapper around GeminiWatermarkTool or gwt-mini"
  echo "  gniwt-bin   Show the resolved Gemini Watermark Tool binary"
  echo "  gniwt-help  Show this help message"
}

_gniwt_require_value_gniwt_aliases() {
  local option_name="$1"
  local option_value="${2:-}"

  if [ -z "$option_value" ] || [[ "$option_value" == -* ]]; then
    _gniwt_show_error_gniwt_aliases "Option \"$option_name\" requires a value."
    return 1
  fi

  return 0
}

_gniwt_validate_path_exists_gniwt_aliases() {
  local target_path="$1"

  if [ ! -e "$target_path" ]; then
    _gniwt_show_error_gniwt_aliases "Path not found: $target_path"
    return 1
  fi

  return 0
}

_gniwt_validate_file_gniwt_aliases() {
  local target_path="$1"

  if [ ! -f "$target_path" ]; then
    _gniwt_show_error_gniwt_aliases "File not found: $target_path"
    return 1
  fi

  return 0
}

_gniwt_validate_dir_gniwt_aliases() {
  local target_path="$1"

  if [ ! -d "$target_path" ]; then
    _gniwt_show_error_gniwt_aliases "Directory not found: $target_path"
    return 1
  fi

  return 0
}

_gniwt_resolve_binary_gniwt_aliases() {
  local resolved_path=""
  local resolved_source=""

  if command -v GeminiWatermarkTool > /dev/null 2>&1; then
    resolved_path="$(command -v GeminiWatermarkTool)"
    resolved_source="PATH:GeminiWatermarkTool"
  elif command -v gwt-mini > /dev/null 2>&1; then
    resolved_path="$(command -v gwt-mini)"
    resolved_source="PATH:gwt-mini"
  elif [ -n "${GNIWT_BIN:-}" ]; then
    resolved_path="$GNIWT_BIN"
    resolved_source="ENV:GNIWT_BIN"
  elif [ -n "${GWT_BIN:-}" ]; then
    resolved_path="$GWT_BIN"
    resolved_source="ENV:GWT_BIN"
  elif [ -n "${GEMINI_WATERMARK_TOOL_BIN:-}" ]; then
    resolved_path="$GEMINI_WATERMARK_TOOL_BIN"
    resolved_source="ENV:GEMINI_WATERMARK_TOOL_BIN"
  else
    _gniwt_show_error_gniwt_aliases "GeminiWatermarkTool not found in PATH and no fallback environment variable is set."
    return 1
  fi

  if [ ! -x "$resolved_path" ]; then
    _gniwt_show_error_gniwt_aliases "Resolved binary is not executable: $resolved_path"
    return 1
  fi

  printf "%s|%s\n" "$resolved_source" "$resolved_path"
}

_gniwt_output_file_gniwt_aliases() {
  local input_file="$1"
  local suffix_text="$2"
  local output_root="${3:-}"
  local parent_dir=""
  local base_name=""
  local stem_name=""
  local extension_name=""
  local target_dir=""

  parent_dir="$(dirname "$input_file")"
  base_name="$(basename "$input_file")"
  stem_name="${base_name%.*}"
  extension_name="${base_name##*.}"
  target_dir="$parent_dir"

  if [ -n "$output_root" ]; then
    target_dir="$output_root"
  fi

  if ! mkdir -p "$target_dir"; then
    _gniwt_show_error_gniwt_aliases "Failed to create output directory: $target_dir"
    return 1
  fi

  if [ "$stem_name" = "$base_name" ]; then
    printf "%s/%s%s\n" "$target_dir" "$base_name" "$suffix_text"
  else
    printf "%s/%s%s.%s\n" "$target_dir" "$stem_name" "$suffix_text" "$extension_name"
  fi
}

_gniwt_output_dir_gniwt_aliases() {
  local input_dir="$1"
  local suffix_text="$2"
  local explicit_output_dir="${3:-}"
  local normalized_input_dir="${input_dir%/}"

  if [ -n "$explicit_output_dir" ]; then
    printf "%s\n" "$explicit_output_dir"
  else
    printf "%s%s\n" "$normalized_input_dir" "$suffix_text"
  fi
}

_gniwt_prepare_output_parent_gniwt_aliases() {
  local target_path="$1"
  local parent_dir=""

  parent_dir="$(dirname "$target_path")"

  if [ -n "$parent_dir" ] && [ "$parent_dir" != "." ] && [ ! -d "$parent_dir" ]; then
    if ! mkdir -p "$parent_dir"; then
      _gniwt_show_error_gniwt_aliases "Failed to create parent directory: $parent_dir"
      return 1
    fi
  fi

  return 0
}

_gniwt_run_command_gniwt_aliases() {
  local tool_path="$1"
  shift

  "$tool_path" "$@"
}

#------------------------------------------------------------------------------
# Main Commands
#------------------------------------------------------------------------------

_gniwt_remove_gniwt_aliases() {
  if [ $# -eq 0 ]; then
    _gniwt_show_usage_gniwt_aliases
    return 1
  fi

  local explicit_output=""
  local explicit_output_dir=""
  local suffix_text="_clean"
  local in_place=false
  local resolved_line=""
  local resolved_source=""
  local tool_path=""
  local input_path=""
  local output_path=""
  local output_dir=""
  local planned_output=""
  local dir_count=0
  local file_count=0
  local process_status=0
  local -a upstream_args
  local -a input_paths
  local -a planned_outputs

  while [ $# -gt 0 ]; do
    case "$1" in
      -o|--output)
        _gniwt_require_value_gniwt_aliases "$1" "${2:-}" || return 1
        explicit_output="$2"
        shift 2
        ;;
      --output-dir)
        _gniwt_require_value_gniwt_aliases "$1" "${2:-}" || return 1
        explicit_output_dir="$2"
        shift 2
        ;;
      --suffix)
        _gniwt_require_value_gniwt_aliases "$1" "${2:-}" || return 1
        suffix_text="$2"
        shift 2
        ;;
      --in-place)
        in_place=true
        shift
        ;;
      -f|--force|--force-small|--force-large|--snap|--verbose|-v|--quiet|-q|--banner|-b|--no-banner)
        upstream_args+=("$1")
        shift
        ;;
      -t|--threshold|--region|--fallback-region|--snap-min-size|--snap-max-size|--snap-threshold|--denoise|--sigma|--strength|--radius|--backend)
        _gniwt_require_value_gniwt_aliases "$1" "${2:-}" || return 1
        upstream_args+=("$1" "$2")
        shift 2
        ;;
      -h|--help)
        _gniwt_show_usage_gniwt_aliases
        return 0
        ;;
      --)
        shift
        while [ $# -gt 0 ]; do
          upstream_args+=("$1")
          shift
        done
        ;;
      -*)
        _gniwt_show_error_gniwt_aliases "Unknown wrapper option: $1. Use -- to pass raw upstream options."
        return 1
        ;;
      *)
        input_paths+=("$1")
        shift
        ;;
    esac
  done

  if [ ${#input_paths[@]} -eq 0 ]; then
    _gniwt_show_error_gniwt_aliases "At least one input path is required."
    return 1
  fi

  resolved_line="$(_gniwt_resolve_binary_gniwt_aliases)" || return 1
  resolved_source="${resolved_line%%|*}"
  tool_path="${resolved_line#*|}"

  for input_path in "${input_paths[@]}"; do
    _gniwt_validate_path_exists_gniwt_aliases "$input_path" || return 1
    if [ -d "$input_path" ]; then
      dir_count=$((dir_count + 1))
    else
      file_count=$((file_count + 1))
    fi
  done

  if [ "$dir_count" -gt 1 ]; then
    _gniwt_show_error_gniwt_aliases "Only one directory input is supported at a time."
    return 1
  fi

  if [ "$dir_count" -gt 0 ] && [ "$file_count" -gt 0 ]; then
    _gniwt_show_error_gniwt_aliases "Do not mix directory inputs with file inputs."
    return 1
  fi

  if [ -n "$explicit_output" ] && [ ${#input_paths[@]} -ne 1 ]; then
    _gniwt_show_error_gniwt_aliases "--output is only valid for a single file input."
    return 1
  fi

  if $in_place && { [ -n "$explicit_output" ] || [ -n "$explicit_output_dir" ]; }; then
    _gniwt_show_error_gniwt_aliases "--in-place cannot be combined with --output or --output-dir."
    return 1
  fi

  if [ "$dir_count" -eq 1 ] && $in_place; then
    _gniwt_show_error_gniwt_aliases "--in-place is only supported for file inputs."
    return 1
  fi

  if [ "$dir_count" -eq 1 ]; then
    input_path="${input_paths[1]}"
    _gniwt_validate_dir_gniwt_aliases "$input_path" || return 1
    output_dir="$(_gniwt_output_dir_gniwt_aliases "$input_path" "$suffix_text" "${explicit_output_dir:-$explicit_output}")" || return 1

    if [ "$output_dir" = "${input_path%/}" ]; then
      _gniwt_show_error_gniwt_aliases "Output directory must differ from input directory."
      return 1
    fi

    _gniwt_prepare_output_parent_gniwt_aliases "$output_dir" || return 1
    _gniwt_print_info_gniwt_aliases "Using $tool_path ($resolved_source)"
    _gniwt_run_command_gniwt_aliases "$tool_path" "${upstream_args[@]}" -i "$input_path" -o "$output_dir"
    return $?
  fi

  if $in_place; then
    for input_path in "${input_paths[@]}"; do
      _gniwt_validate_file_gniwt_aliases "$input_path" || return 1
    done

    _gniwt_print_info_gniwt_aliases "Using $tool_path ($resolved_source)"
    _gniwt_run_command_gniwt_aliases "$tool_path" "${upstream_args[@]}" "${input_paths[@]}"
    return $?
  fi

  for input_path in "${input_paths[@]}"; do
    _gniwt_validate_file_gniwt_aliases "$input_path" || return 1
  done

  if [ ${#input_paths[@]} -eq 1 ] && [ -n "$explicit_output" ]; then
    output_path="$explicit_output"
  else
    for input_path in "${input_paths[@]}"; do
      planned_output="$(_gniwt_output_file_gniwt_aliases "$input_path" "$suffix_text" "$explicit_output_dir")" || return 1
      if [ "$planned_output" = "$input_path" ]; then
        _gniwt_show_error_gniwt_aliases "Output path must differ from input path: $input_path"
        return 1
      fi
      if printf "%s\n" "${planned_outputs[@]}" | grep -F -x -- "$planned_output" > /dev/null 2>&1; then
        _gniwt_show_error_gniwt_aliases "Conflicting output path detected: $planned_output"
        return 1
      fi
      planned_outputs+=("$planned_output")
    done
  fi

  _gniwt_print_info_gniwt_aliases "Using $tool_path ($resolved_source)"

  if [ ${#input_paths[@]} -eq 1 ]; then
    input_path="${input_paths[1]}"
    if [ -z "$output_path" ]; then
      output_path="$(_gniwt_output_file_gniwt_aliases "$input_path" "$suffix_text" "$explicit_output_dir")" || return 1
    fi

    if [ "$output_path" = "$input_path" ]; then
      _gniwt_show_error_gniwt_aliases "Output path must differ from input path: $input_path"
      return 1
    fi

    _gniwt_prepare_output_parent_gniwt_aliases "$output_path" || return 1
    _gniwt_run_command_gniwt_aliases "$tool_path" "${upstream_args[@]}" -i "$input_path" -o "$output_path"
    return $?
  fi

  for input_path in "${input_paths[@]}"; do
    output_path="$(_gniwt_output_file_gniwt_aliases "$input_path" "$suffix_text" "$explicit_output_dir")" || return 1
    _gniwt_prepare_output_parent_gniwt_aliases "$output_path" || return 1
    if ! _gniwt_run_command_gniwt_aliases "$tool_path" "${upstream_args[@]}" -i "$input_path" -o "$output_path"; then
      process_status=1
    fi
  done

  return "$process_status"
}

_gniwt_show_binary_gniwt_aliases() {
  local resolved_line=""
  local resolved_source=""
  local tool_path=""

  resolved_line="$(_gniwt_resolve_binary_gniwt_aliases)" || return 1
  resolved_source="${resolved_line%%|*}"
  tool_path="${resolved_line#*|}"

  echo "source: $resolved_source"
  echo "binary: $tool_path"
}

alias gniwt-rm="_gniwt_remove_gniwt_aliases"
alias gniwt-bin="_gniwt_show_binary_gniwt_aliases"
alias gniwt-help="_gniwt_help_gniwt_aliases"
