# Description: Text processing aliases for cleanup, normalization, and quick inspection with a unified txt- prefix.

# Helper Functions
### --- ###

_text_error_text_aliases() {
  local message="$1"

  echo "Error: $message" >&2
  return 1
}

_text_require_command_text_aliases() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    _text_error_text_aliases "Required command is not available: $command_name"
    return 1
  fi

  return 0
}

_text_find_targets_text_aliases() {
  local search_root="$1"
  local search_pattern="$2"
  local recursive="$3"

  if [ "$recursive" = "true" ]; then
    find "$search_root" -type f -name "$search_pattern" -print0
  else
    find "$search_root" -maxdepth 1 -type f -name "$search_pattern" -print0
  fi
}

_text_collect_targets_text_aliases() {
  emulate -L zsh
  setopt local_options pipefail

  local pattern="$1"
  local recursive="$2"
  shift 2

  local input_path=""
  local matched_path=""
  local search_root=""
  local search_pattern=""
  local matched_count=0

  for input_path in "$@"; do
    if [ -f "$input_path" ]; then
      printf "%s\0" "$input_path"
      continue
    fi

    if [ -d "$input_path" ]; then
      _text_find_targets_text_aliases "$input_path" "$pattern" "$recursive"
      continue
    fi

    case "$input_path" in
      *"*"*|*"?"*|*"["*)
        search_root=$(dirname "$input_path") || {
          _text_error_text_aliases "Failed to parse glob input: $input_path"
          return 1
        }
        search_pattern=$(basename "$input_path") || {
          _text_error_text_aliases "Failed to parse glob input: $input_path"
          return 1
        }

        if [ ! -d "$search_root" ]; then
          _text_error_text_aliases "Glob directory does not exist: $search_root"
          return 1
        fi

        matched_count=0
        while IFS= read -r -d "" matched_path; do
          printf "%s\0" "$matched_path"
          matched_count=$((matched_count + 1))
        done < <(_text_find_targets_text_aliases "$search_root" "$search_pattern" "$recursive")

        if [ "$matched_count" -eq 0 ]; then
          _text_error_text_aliases "No files matched glob: $input_path"
          return 1
        fi

        continue
        ;;
    esac

    _text_error_text_aliases "Input path does not exist: $input_path"
    return 1
  done

  return 0
}

_text_make_target_list_text_aliases() {
  local pattern="$1"
  local recursive="$2"
  local target_list_path=""
  shift 2

  target_list_path=$(mktemp) || {
    _text_error_text_aliases "Failed to create temporary target list"
    return 1
  }

  if ! _text_collect_targets_text_aliases "$pattern" "$recursive" "$@" > "$target_list_path"; then
    rm -f "$target_list_path"
    return 1
  fi

  echo "$target_list_path"
}

_text_count_stream_chars_text_aliases() {
  wc -m | tr -d " "
}

_text_count_stream_bytes_text_aliases() {
  wc -c | tr -d " "
}

_text_same_path_text_aliases() {
  local left_path="$1"
  local right_path="$2"

  if [ -z "$left_path" ] || [ -z "$right_path" ]; then
    return 1
  fi

  [ "${left_path:A}" = "${right_path:A}" ]
}

_text_apply_transform_text_aliases() {
  emulate -L zsh
  setopt local_options pipefail

  local source_path="$1"
  local target_path="$2"
  local transform_name="$3"
  shift 3

  local temp_path=""

  temp_path=$(mktemp) || {
    _text_error_text_aliases "Failed to create temporary file for $source_path"
    return 1
  }

  if ! "$transform_name" "$@" < "$source_path" > "$temp_path"; then
    rm -f "$temp_path"
    _text_error_text_aliases "Failed to transform file: $source_path"
    return 1
  fi

  if [ -n "$target_path" ] && ! _text_same_path_text_aliases "$source_path" "$target_path"; then
    if ! cat "$temp_path" > "$target_path"; then
      rm -f "$temp_path"
      _text_error_text_aliases "Failed to write output file: $target_path"
      return 1
    fi
  else
    if ! cat "$temp_path" > "$source_path"; then
      rm -f "$temp_path"
      _text_error_text_aliases "Failed to update file in place: $source_path"
      return 1
    fi
  fi

  rm -f "$temp_path"
  return 0
}

_text_run_transform_text_aliases() {
  emulate -L zsh
  setopt local_options pipefail

  local transform_name="$1"
  local action_label="$2"
  local output_path="$3"
  local stdout_mode="$4"
  local pattern="$5"
  local recursive="$6"
  local verbose="$7"
  shift 7

  local parse_inputs="false"
  local current_arg=""
  local target_path=""
  local target_list_path=""
  local processed_count=0
  local -a transform_args=()
  local -a inputs=()
  local -a targets=()

  while [ $# -gt 0 ]; do
    current_arg="$1"
    if [ "$parse_inputs" = "false" ] && [ "$current_arg" = "--" ]; then
      parse_inputs="true"
      shift
      continue
    fi

    if [ "$parse_inputs" = "false" ]; then
      transform_args+=("$current_arg")
    else
      inputs+=("$current_arg")
    fi

    shift
  done

  if [ "$stdout_mode" = "true" ] && [ -n "$output_path" ]; then
    _text_error_text_aliases "Use either --stdout or --output, not both"
    return 1
  fi

  if [ ${#inputs[@]} -eq 0 ]; then
    if [ -t 0 ]; then
      _text_error_text_aliases "Provide at least one file or directory, or pipe content through standard input"
      return 1
    fi

    if [ -n "$output_path" ]; then
      if ! "$transform_name" "${transform_args[@]}" > "$output_path"; then
        _text_error_text_aliases "Failed to write transformed output to: $output_path"
        return 1
      fi
      echo "Processed standard input."
      return 0
    fi

    "$transform_name" "${transform_args[@]}"
    return $?
  fi

  target_list_path=$(_text_make_target_list_text_aliases "$pattern" "$recursive" "${inputs[@]}") || return 1

  while IFS= read -r -d "" target_path; do
    targets+=("$target_path")
  done < "$target_list_path"

  rm -f "$target_list_path"

  if [ ${#targets[@]} -eq 0 ]; then
    _text_error_text_aliases "No files matched pattern \"$pattern\""
    return 1
  fi

  if [ "$stdout_mode" = "true" ] && [ ${#targets[@]} -ne 1 ]; then
    _text_error_text_aliases "--stdout supports exactly one resolved file"
    return 1
  fi

  if [ -n "$output_path" ] && [ ${#targets[@]} -ne 1 ]; then
    _text_error_text_aliases "--output supports exactly one resolved file"
    return 1
  fi

  for target_path in "${targets[@]}"; do
    if [ "$verbose" = "true" ]; then
      echo "Running $action_label on: $target_path" >&2
    fi

    if [ "$stdout_mode" = "true" ]; then
      if ! "$transform_name" "${transform_args[@]}" < "$target_path"; then
        _text_error_text_aliases "Failed to transform file: $target_path"
        return 1
      fi
    else
      _text_apply_transform_text_aliases "$target_path" "$output_path" "$transform_name" "${transform_args[@]}" || return 1
    fi

    processed_count=$((processed_count + 1))
  done

  if [ "$stdout_mode" != "true" ]; then
    echo "Processed $processed_count file(s)."
  fi

  return 0
}

_text_transform_dedup_text_aliases() {
  local dedup_mode="$1"

  case "$dedup_mode" in
    preserve)
      awk "!seen[\$0]++"
      ;;
    sorted)
      LC_ALL=C sort -u
      ;;
    *)
      _text_error_text_aliases "Unsupported dedup mode: $dedup_mode"
      return 1
      ;;
  esac

  return 0
}

_text_transform_case_text_aliases() {
  local case_mode="$1"

  case "$case_mode" in
    upper)
      tr "[:lower:]" "[:upper:]"
      ;;
    lower)
      tr "[:upper:]" "[:lower:]"
      ;;
    title)
      perl -pe "\$_ = lc(\$_); s/(^|[^[:alnum:]])([[:alpha:]])/\$1 . uc(\$2)/ge"
      ;;
    *)
      _text_error_text_aliases "Unsupported case mode: $case_mode"
      return 1
      ;;
  esac

  return 0
}

_text_transform_line_numbers_text_aliases() {
  local action_name="$1"
  local number_format="$2"

  case "$action_name" in
    add)
      awk -v fmt="$number_format" "{printf fmt, NR; print}"
      ;;
    remove)
      perl -pe "s/^[[:space:]]*[0-9]+(?:[[:space:]]*[|:.)-][[:space:]]*|[[:space:]]+)//"
      ;;
    *)
      _text_error_text_aliases "Unsupported line number action: $action_name"
      return 1
      ;;
  esac

  return 0
}

_text_transform_trim_text_aliases() {
  local trim_mode="$1"

  case "$trim_mode" in
    right)
      perl -pe "s/[ \t]+(\r?\n)$/\$1/; s/[ \t]+$//"
      ;;
    left)
      perl -pe "s/^[ \t]+//"
      ;;
    both)
      perl -pe "s/^[ \t]+//; s/[ \t]+(\r?\n)$/\$1/; s/[ \t]+$//"
      ;;
    blank)
      perl -0pe "s/\A(?:[ \t]*\n)+//; s/(?:\n[ \t]*)+\z/\n/"
      ;;
    *)
      _text_error_text_aliases "Unsupported trim mode: $trim_mode"
      return 1
      ;;
  esac

  return 0
}

_text_transform_eol_text_aliases() {
  local eol_mode="$1"

  case "$eol_mode" in
    lf)
      perl -0pe "s/\r\n/\n/g; s/\r/\n/g"
      ;;
    crlf)
      perl -0pe "s/\r\n/\n/g; s/\r/\n/g; s/\n/\r\n/g"
      ;;
    *)
      _text_error_text_aliases "Unsupported EOL mode: $eol_mode"
      return 1
      ;;
  esac

  return 0
}

_text_dedup_help_text_aliases() {
  echo "Remove duplicate lines from text files."
  echo "Usage: txt-dd [options] <file_or_dir> [more_files_or_dirs...]"
  echo "Options:"
  echo " -o, --output <file>  Write output to file when exactly one target is resolved"
  echo " -p, --pattern <glob> Match pattern for directory inputs (default: *.txt)"
  echo " -r, --recursive      Process directories recursively"
  echo " -s, --stdout         Print transformed content to standard output"
  echo " -v, --verbose        Show progress messages"
  echo "     --sort           Sort unique lines instead of preserving first occurrence"
  echo " -h, --help           Show help"
  echo "Examples:"
  echo " txt-dd notes.txt"
  echo " txt-dd --sort ./docs"
  echo " cat notes.txt | txt-dd"
}

_text_case_help_text_aliases() {
  echo "Convert text case for files or standard input."
  echo "Usage: txt-case [options] <file_or_dir> [more_files_or_dirs...]"
  echo "Options:"
  echo " -m, --mode <mode>    lower | upper | title (default: lower)"
  echo " -o, --output <file>  Write output to file when exactly one target is resolved"
  echo " -p, --pattern <glob> Match pattern for directory inputs (default: *.txt)"
  echo " -r, --recursive      Process directories recursively"
  echo " -s, --stdout         Print transformed content to standard output"
  echo " -v, --verbose        Show progress messages"
  echo " -h, --help           Show help"
  echo "Examples:"
  echo " txt-case --mode upper memo.txt"
  echo " txt-title docs/article.txt"
}

_text_line_numbers_help_text_aliases() {
  echo "Add or remove line numbers for text files."
  echo "Usage: txt-nl [options] <file_or_dir> [more_files_or_dirs...]"
  echo "Options:"
  echo " -a, --action <mode>  add | remove (default: add)"
  echo " -f, --format <fmt>   printf-style format for added numbers (default: %6d | )"
  echo " -o, --output <file>  Write output to file when exactly one target is resolved"
  echo " -p, --pattern <glob> Match pattern for directory inputs (default: *.txt)"
  echo " -r, --recursive      Process directories recursively"
  echo " -s, --stdout         Print transformed content to standard output"
  echo " -v, --verbose        Show progress messages"
  echo " -h, --help           Show help"
  echo "Examples:"
  echo " txt-nl script.txt"
  echo " txt-nl --action remove numbered.txt"
}

_text_trim_help_text_aliases() {
  echo "Trim whitespace from text files."
  echo "Usage: txt-trim [options] <file_or_dir> [more_files_or_dirs...]"
  echo "Options:"
  echo " -m, --mode <mode>    right | left | both | blank (default: right)"
  echo " -o, --output <file>  Write output to file when exactly one target is resolved"
  echo " -p, --pattern <glob> Match pattern for directory inputs (default: *.txt)"
  echo " -r, --recursive      Process directories recursively"
  echo " -s, --stdout         Print transformed content to standard output"
  echo " -v, --verbose        Show progress messages"
  echo " -h, --help           Show help"
  echo "Examples:"
  echo " txt-trim README.txt"
  echo " txt-trim --mode both drafts/"
}

_text_eol_help_text_aliases() {
  echo "Normalize line endings without external dos2unix dependencies."
  echo "Usage: txt-eol [options] <file_or_dir> [more_files_or_dirs...]"
  echo "Options:"
  echo " -m, --mode <mode>    lf | crlf (default: lf)"
  echo " -o, --output <file>  Write output to file when exactly one target is resolved"
  echo " -p, --pattern <glob> Match pattern for directory inputs (default: *.txt)"
  echo " -r, --recursive      Process directories recursively"
  echo " -s, --stdout         Print transformed content to standard output"
  echo " -v, --verbose        Show progress messages"
  echo " -h, --help           Show help"
  echo "Examples:"
  echo " txt-eol notes.txt"
  echo " txt-eol --mode crlf export.txt"
}

_text_wc_help_text_aliases() {
  echo "Show line, word, and byte counts for text files."
  echo "Usage: txt-wc [options] <file_or_dir> [more_files_or_dirs...]"
  echo "Note: word means wc -w word count, not total characters. Use txt-chars for character counts."
  echo "Options:"
  echo " -p, --pattern <glob> Match pattern for directory inputs (default: *.txt)"
  echo " -r, --recursive      Process directories recursively"
  echo " -v, --verbose        Show progress messages"
  echo " -h, --help           Show help"
  echo "Examples:"
  echo " txt-wc notes.txt"
  echo " txt-wc -r docs/"
  echo " cat notes.txt | txt-wc"
}

_text_chars_help_text_aliases() {
  echo "Show character counts for text files."
  echo "Usage: txt-chars [options] <file_or_dir_or_glob> [more_targets...]"
  echo "Options:"
  echo " -p, --pattern <glob> Match pattern for directory inputs (default: *.txt)"
  echo " -r, --recursive      Process directories and quoted globs recursively"
  echo "     --bytes          Count bytes instead of characters"
  echo "     --total-only     Print only the total count"
  echo " -v, --verbose        Show progress messages"
  echo " -h, --help           Show help"
  echo "Examples:"
  echo " txt-chars README.md"
  echo " txt-chars *.md"
  echo " txt-chars \"*.md\""
  echo " txt-chars docs/ -p \"*.md\" -r"
  echo " cat notes.txt | txt-chars"
}

_text_stats_help_text_aliases() {
  echo "Show line, word, character, and byte counts for text files."
  echo "Usage: txt-stats [options] <file_or_dir_or_glob> [more_targets...]"
  echo "Options:"
  echo " -p, --pattern <glob> Match pattern for directory inputs (default: *.txt)"
  echo " -r, --recursive      Process directories and quoted globs recursively"
  echo "     --total-only     Print only the total counts"
  echo " -v, --verbose        Show progress messages"
  echo " -h, --help           Show help"
  echo "Examples:"
  echo " txt-stats README.md"
  echo " txt-stats \"*.md\""
  echo " txt-stats docs/ -p \"*.md\" -r"
  echo " cat notes.txt | txt-stats"
}

# Main Functions
### --- ###

_text_dedup_text_aliases() {
  local output_path=""
  local pattern="*.txt"
  local recursive="false"
  local stdout_mode="false"
  local verbose="false"
  local dedup_mode="preserve"
  local current_arg=""
  local -a inputs=()

  if [ $# -eq 0 ] && [ -t 0 ]; then
    _text_dedup_help_text_aliases
    return 0
  fi

  while [ $# -gt 0 ]; do
    current_arg="$1"
    case "$current_arg" in
      -h|--help)
        _text_dedup_help_text_aliases
        return 0
        ;;
      -o|--output)
        [ -n "$2" ] || { _text_error_text_aliases "Missing output file after $current_arg"; return 1; }
        output_path="$2"
        shift 2
        ;;
      -p|--pattern)
        [ -n "$2" ] || { _text_error_text_aliases "Missing glob pattern after $current_arg"; return 1; }
        pattern="$2"
        shift 2
        ;;
      -r|--recursive)
        recursive="true"
        shift
        ;;
      -s|--stdout)
        stdout_mode="true"
        shift
        ;;
      -v|--verbose)
        verbose="true"
        shift
        ;;
      --sort)
        dedup_mode="sorted"
        shift
        ;;
      -*)
        _text_error_text_aliases "Unknown option: $current_arg"
        return 1
        ;;
      *)
        inputs+=("$current_arg")
        shift
        ;;
    esac
  done

  _text_run_transform_text_aliases "_text_transform_dedup_text_aliases" "dedup" "$output_path" "$stdout_mode" "$pattern" "$recursive" "$verbose" "$dedup_mode" -- "${inputs[@]}"
}

_text_case_text_aliases() {
  local output_path=""
  local pattern="*.txt"
  local recursive="false"
  local stdout_mode="false"
  local verbose="false"
  local case_mode="lower"
  local current_arg=""
  local -a inputs=()

  if [ $# -eq 0 ] && [ -t 0 ]; then
    _text_case_help_text_aliases
    return 0
  fi

  while [ $# -gt 0 ]; do
    current_arg="$1"
    case "$current_arg" in
      -h|--help)
        _text_case_help_text_aliases
        return 0
        ;;
      -m|--mode)
        [ -n "$2" ] || { _text_error_text_aliases "Missing case mode after $current_arg"; return 1; }
        case_mode="$2"
        shift 2
        ;;
      -o|--output)
        [ -n "$2" ] || { _text_error_text_aliases "Missing output file after $current_arg"; return 1; }
        output_path="$2"
        shift 2
        ;;
      -p|--pattern)
        [ -n "$2" ] || { _text_error_text_aliases "Missing glob pattern after $current_arg"; return 1; }
        pattern="$2"
        shift 2
        ;;
      -r|--recursive)
        recursive="true"
        shift
        ;;
      -s|--stdout)
        stdout_mode="true"
        shift
        ;;
      -v|--verbose)
        verbose="true"
        shift
        ;;
      -*)
        _text_error_text_aliases "Unknown option: $current_arg"
        return 1
        ;;
      *)
        inputs+=("$current_arg")
        shift
        ;;
    esac
  done

  case "$case_mode" in
    upper|lower|title)
      ;;
    *)
      _text_error_text_aliases "Case mode must be one of: upper, lower, title"
      return 1
      ;;
  esac

  if [ "$case_mode" = "title" ]; then
    _text_require_command_text_aliases "perl" || return 1
  fi

  _text_run_transform_text_aliases "_text_transform_case_text_aliases" "case conversion" "$output_path" "$stdout_mode" "$pattern" "$recursive" "$verbose" "$case_mode" -- "${inputs[@]}"
}

_text_line_numbers_text_aliases() {
  local output_path=""
  local pattern="*.txt"
  local recursive="false"
  local stdout_mode="false"
  local verbose="false"
  local action_name="add"
  local number_format="%6d | "
  local current_arg=""
  local -a inputs=()

  if [ $# -eq 0 ] && [ -t 0 ]; then
    _text_line_numbers_help_text_aliases
    return 0
  fi

  while [ $# -gt 0 ]; do
    current_arg="$1"
    case "$current_arg" in
      -h|--help)
        _text_line_numbers_help_text_aliases
        return 0
        ;;
      -a|--action)
        [ -n "$2" ] || { _text_error_text_aliases "Missing action after $current_arg"; return 1; }
        action_name="$2"
        shift 2
        ;;
      -f|--format)
        [ -n "$2" ] || { _text_error_text_aliases "Missing line number format after $current_arg"; return 1; }
        number_format="$2"
        shift 2
        ;;
      -o|--output)
        [ -n "$2" ] || { _text_error_text_aliases "Missing output file after $current_arg"; return 1; }
        output_path="$2"
        shift 2
        ;;
      -p|--pattern)
        [ -n "$2" ] || { _text_error_text_aliases "Missing glob pattern after $current_arg"; return 1; }
        pattern="$2"
        shift 2
        ;;
      -r|--recursive)
        recursive="true"
        shift
        ;;
      -s|--stdout)
        stdout_mode="true"
        shift
        ;;
      -v|--verbose)
        verbose="true"
        shift
        ;;
      -*)
        _text_error_text_aliases "Unknown option: $current_arg"
        return 1
        ;;
      *)
        inputs+=("$current_arg")
        shift
        ;;
    esac
  done

  case "$action_name" in
    add|remove)
      ;;
    *)
      _text_error_text_aliases "Line number action must be add or remove"
      return 1
      ;;
  esac

  if [ "$action_name" = "remove" ]; then
    _text_require_command_text_aliases "perl" || return 1
  fi

  _text_run_transform_text_aliases "_text_transform_line_numbers_text_aliases" "line numbering" "$output_path" "$stdout_mode" "$pattern" "$recursive" "$verbose" "$action_name" "$number_format" -- "${inputs[@]}"
}

_text_trim_text_aliases() {
  local output_path=""
  local pattern="*.txt"
  local recursive="false"
  local stdout_mode="false"
  local verbose="false"
  local trim_mode="right"
  local current_arg=""
  local -a inputs=()

  if [ $# -eq 0 ] && [ -t 0 ]; then
    _text_trim_help_text_aliases
    return 0
  fi

  while [ $# -gt 0 ]; do
    current_arg="$1"
    case "$current_arg" in
      -h|--help)
        _text_trim_help_text_aliases
        return 0
        ;;
      -m|--mode)
        [ -n "$2" ] || { _text_error_text_aliases "Missing trim mode after $current_arg"; return 1; }
        trim_mode="$2"
        shift 2
        ;;
      -o|--output)
        [ -n "$2" ] || { _text_error_text_aliases "Missing output file after $current_arg"; return 1; }
        output_path="$2"
        shift 2
        ;;
      -p|--pattern)
        [ -n "$2" ] || { _text_error_text_aliases "Missing glob pattern after $current_arg"; return 1; }
        pattern="$2"
        shift 2
        ;;
      -r|--recursive)
        recursive="true"
        shift
        ;;
      -s|--stdout)
        stdout_mode="true"
        shift
        ;;
      -v|--verbose)
        verbose="true"
        shift
        ;;
      -*)
        _text_error_text_aliases "Unknown option: $current_arg"
        return 1
        ;;
      *)
        inputs+=("$current_arg")
        shift
        ;;
    esac
  done

  case "$trim_mode" in
    right|left|both|blank)
      ;;
    *)
      _text_error_text_aliases "Trim mode must be one of: right, left, both, blank"
      return 1
      ;;
  esac

  _text_require_command_text_aliases "perl" || return 1

  _text_run_transform_text_aliases "_text_transform_trim_text_aliases" "whitespace trim" "$output_path" "$stdout_mode" "$pattern" "$recursive" "$verbose" "$trim_mode" -- "${inputs[@]}"
}

_text_eol_text_aliases() {
  local output_path=""
  local pattern="*.txt"
  local recursive="false"
  local stdout_mode="false"
  local verbose="false"
  local eol_mode="lf"
  local current_arg=""
  local -a inputs=()

  if [ $# -eq 0 ] && [ -t 0 ]; then
    _text_eol_help_text_aliases
    return 0
  fi

  while [ $# -gt 0 ]; do
    current_arg="$1"
    case "$current_arg" in
      -h|--help)
        _text_eol_help_text_aliases
        return 0
        ;;
      -m|--mode)
        [ -n "$2" ] || { _text_error_text_aliases "Missing EOL mode after $current_arg"; return 1; }
        eol_mode="$2"
        shift 2
        ;;
      -o|--output)
        [ -n "$2" ] || { _text_error_text_aliases "Missing output file after $current_arg"; return 1; }
        output_path="$2"
        shift 2
        ;;
      -p|--pattern)
        [ -n "$2" ] || { _text_error_text_aliases "Missing glob pattern after $current_arg"; return 1; }
        pattern="$2"
        shift 2
        ;;
      -r|--recursive)
        recursive="true"
        shift
        ;;
      -s|--stdout)
        stdout_mode="true"
        shift
        ;;
      -v|--verbose)
        verbose="true"
        shift
        ;;
      -*)
        _text_error_text_aliases "Unknown option: $current_arg"
        return 1
        ;;
      *)
        inputs+=("$current_arg")
        shift
        ;;
    esac
  done

  case "$eol_mode" in
    lf|crlf)
      ;;
    *)
      _text_error_text_aliases "EOL mode must be lf or crlf"
      return 1
      ;;
  esac

  _text_require_command_text_aliases "perl" || return 1

  _text_run_transform_text_aliases "_text_transform_eol_text_aliases" "line ending normalization" "$output_path" "$stdout_mode" "$pattern" "$recursive" "$verbose" "$eol_mode" -- "${inputs[@]}"
}

_text_wc_text_aliases() {
  emulate -L zsh
  setopt local_options pipefail

  local pattern="*.txt"
  local recursive="false"
  local verbose="false"
  local current_arg=""
  local target_path=""
  local target_list_path=""
  local -a inputs=()
  local -a targets=()

  if [ $# -eq 0 ] && [ -t 0 ]; then
    _text_wc_help_text_aliases
    return 0
  fi

  while [ $# -gt 0 ]; do
    current_arg="$1"
    case "$current_arg" in
      -h|--help)
        _text_wc_help_text_aliases
        return 0
        ;;
      -p|--pattern)
        [ -n "$2" ] || { _text_error_text_aliases "Missing glob pattern after $current_arg"; return 1; }
        pattern="$2"
        shift 2
        ;;
      -r|--recursive)
        recursive="true"
        shift
        ;;
      -v|--verbose)
        verbose="true"
        shift
        ;;
      -*)
        _text_error_text_aliases "Unknown option: $current_arg"
        return 1
        ;;
      *)
        inputs+=("$current_arg")
        shift
        ;;
    esac
  done

  if [ ${#inputs[@]} -eq 0 ]; then
    if [ -t 0 ]; then
      _text_error_text_aliases "Provide at least one file or directory, or pipe content through standard input"
      return 1
    fi

    wc -l -w -c
    return $?
  fi

  target_list_path=$(_text_make_target_list_text_aliases "$pattern" "$recursive" "${inputs[@]}") || return 1

  while IFS= read -r -d "" target_path; do
    targets+=("$target_path")
  done < "$target_list_path"

  rm -f "$target_list_path"

  if [ ${#targets[@]} -eq 0 ]; then
    _text_error_text_aliases "No files matched pattern \"$pattern\""
    return 1
  fi

  if [ "$verbose" = "true" ]; then
    for target_path in "${targets[@]}"; do
      echo "Collecting counts for: $target_path" >&2
    done
  fi

  wc -l -w -c "${targets[@]}"
}

_text_chars_text_aliases() {
  emulate -L zsh
  setopt local_options pipefail

  local pattern="*.txt"
  local recursive="false"
  local verbose="false"
  local total_only="false"
  local count_mode="characters"
  local current_arg=""
  local target_path=""
  local target_list_path=""
  local current_count=0
  local total_count=0
  local -a inputs=()
  local -a targets=()

  if [ $# -eq 0 ] && [ -t 0 ]; then
    _text_chars_help_text_aliases
    return 0
  fi

  while [ $# -gt 0 ]; do
    current_arg="$1"
    case "$current_arg" in
      -h|--help)
        _text_chars_help_text_aliases
        return 0
        ;;
      -p|--pattern)
        [ -n "$2" ] || { _text_error_text_aliases "Missing glob pattern after $current_arg"; return 1; }
        pattern="$2"
        shift 2
        ;;
      -r|--recursive)
        recursive="true"
        shift
        ;;
      --bytes)
        count_mode="bytes"
        shift
        ;;
      --total-only)
        total_only="true"
        shift
        ;;
      -v|--verbose)
        verbose="true"
        shift
        ;;
      -*)
        _text_error_text_aliases "Unknown option: $current_arg"
        return 1
        ;;
      *)
        inputs+=("$current_arg")
        shift
        ;;
    esac
  done

  if [ ${#inputs[@]} -eq 0 ]; then
    if [ -t 0 ]; then
      _text_error_text_aliases "Provide at least one file, directory, glob, or pipe content through standard input"
      return 1
    fi

    if [ "$count_mode" = "bytes" ]; then
      _text_count_stream_bytes_text_aliases
    else
      _text_count_stream_chars_text_aliases
    fi
    return $?
  fi

  target_list_path=$(_text_make_target_list_text_aliases "$pattern" "$recursive" "${inputs[@]}") || return 1

  while IFS= read -r -d "" target_path; do
    targets+=("$target_path")
  done < "$target_list_path"

  rm -f "$target_list_path"

  if [ ${#targets[@]} -eq 0 ]; then
    _text_error_text_aliases "No files matched pattern \"$pattern\""
    return 1
  fi

  if [ "$total_only" != "true" ]; then
    printf "%-12s %s\n" "$count_mode" "file"
  fi

  for target_path in "${targets[@]}"; do
    if [ "$verbose" = "true" ]; then
      echo "Counting $count_mode for: $target_path" >&2
    fi

    if [ "$count_mode" = "bytes" ]; then
      current_count=$(_text_count_stream_bytes_text_aliases < "$target_path") || {
        _text_error_text_aliases "Failed to count bytes for: $target_path"
        return 1
      }
    else
      current_count=$(_text_count_stream_chars_text_aliases < "$target_path") || {
        _text_error_text_aliases "Failed to count characters for: $target_path"
        return 1
      }
    fi

    total_count=$((total_count + current_count))

    if [ "$total_only" != "true" ]; then
      printf "%-12s %s\n" "$current_count" "$target_path"
    fi
  done

  if [ "$total_only" = "true" ]; then
    echo "$total_count"
  else
    echo ""
    echo "Total files: ${#targets[@]}"
    echo "Total $count_mode: $total_count"
  fi
}

_text_count_file_stats_text_aliases() {
  local target_path="$1"
  local line_count=0
  local word_count=0
  local char_count=0
  local byte_count=0

  line_count=$(wc -l < "$target_path" | tr -d " ") || return 1
  word_count=$(wc -w < "$target_path" | tr -d " ") || return 1
  char_count=$(_text_count_stream_chars_text_aliases < "$target_path") || return 1
  byte_count=$(_text_count_stream_bytes_text_aliases < "$target_path") || return 1

  echo "$line_count $word_count $char_count $byte_count"
}

_text_count_stdin_stats_text_aliases() {
  local temp_path=""

  temp_path=$(mktemp) || {
    _text_error_text_aliases "Failed to create temporary file for standard input"
    return 1
  }

  if ! cat > "$temp_path"; then
    rm -f "$temp_path"
    _text_error_text_aliases "Failed to read standard input"
    return 1
  fi

  _text_count_file_stats_text_aliases "$temp_path"
  local count_status=$?
  rm -f "$temp_path"
  return "$count_status"
}

_text_stats_text_aliases() {
  emulate -L zsh
  setopt local_options pipefail

  local pattern="*.txt"
  local recursive="false"
  local verbose="false"
  local total_only="false"
  local current_arg=""
  local target_path=""
  local target_list_path=""
  local line_count=0
  local word_count=0
  local char_count=0
  local byte_count=0
  local total_lines=0
  local total_words=0
  local total_chars=0
  local total_bytes=0
  local -a inputs=()
  local -a targets=()

  while [ $# -gt 0 ]; do
    current_arg="$1"
    case "$current_arg" in
      -h|--help)
        _text_stats_help_text_aliases
        return 0
        ;;
      -p|--pattern)
        [ -n "$2" ] || { _text_error_text_aliases "Missing glob pattern after $current_arg"; return 1; }
        pattern="$2"
        shift 2
        ;;
      -r|--recursive)
        recursive="true"
        shift
        ;;
      --total-only)
        total_only="true"
        shift
        ;;
      -v|--verbose)
        verbose="true"
        shift
        ;;
      -*)
        _text_error_text_aliases "Unknown option: $current_arg"
        return 1
        ;;
      *)
        inputs+=("$current_arg")
        shift
        ;;
    esac
  done

  if [ ${#inputs[@]} -eq 0 ]; then
    if [ -t 0 ]; then
      _text_error_text_aliases "Provide at least one file, directory, glob, or pipe content through standard input"
      return 1
    fi

    read line_count word_count char_count byte_count <<< "$(_text_count_stdin_stats_text_aliases)" || {
      _text_error_text_aliases "Failed to count standard input"
      return 1
    }

    if [ "$total_only" = "true" ]; then
      echo "$line_count $word_count $char_count $byte_count"
    else
      printf "%-8s %-8s %-12s %-8s %s\n" "lines" "words" "characters" "bytes" "source"
      printf "%-8s %-8s %-12s %-8s %s\n" "$line_count" "$word_count" "$char_count" "$byte_count" "stdin"
    fi
    return 0
  fi

  target_list_path=$(_text_make_target_list_text_aliases "$pattern" "$recursive" "${inputs[@]}") || return 1

  while IFS= read -r -d "" target_path; do
    targets+=("$target_path")
  done < "$target_list_path"

  rm -f "$target_list_path"

  if [ ${#targets[@]} -eq 0 ]; then
    _text_error_text_aliases "No files matched pattern \"$pattern\""
    return 1
  fi

  if [ "$total_only" != "true" ]; then
    printf "%-8s %-8s %-12s %-8s %s\n" "lines" "words" "characters" "bytes" "file"
  fi

  for target_path in "${targets[@]}"; do
    if [ "$verbose" = "true" ]; then
      echo "Collecting text stats for: $target_path" >&2
    fi

    read line_count word_count char_count byte_count <<< "$(_text_count_file_stats_text_aliases "$target_path")" || {
      _text_error_text_aliases "Failed to count file: $target_path"
      return 1
    }

    total_lines=$((total_lines + line_count))
    total_words=$((total_words + word_count))
    total_chars=$((total_chars + char_count))
    total_bytes=$((total_bytes + byte_count))

    if [ "$total_only" != "true" ]; then
      printf "%-8s %-8s %-12s %-8s %s\n" "$line_count" "$word_count" "$char_count" "$byte_count" "$target_path"
    fi
  done

  if [ "$total_only" = "true" ]; then
    echo "$total_lines $total_words $total_chars $total_bytes"
  else
    echo ""
    echo "Total files: ${#targets[@]}"
    printf "Total: lines=%s words=%s characters=%s bytes=%s\n" "$total_lines" "$total_words" "$total_chars" "$total_bytes"
  fi
}

_text_help_text_aliases() {
  echo "Text processing aliases with unified txt- prefixes."
  echo ""
  echo "Primary commands:"
  echo " txt-dd      Remove duplicate lines while preserving order by default"
  echo " txt-case    Convert text to lower, upper, or title case"
  echo " txt-nl      Add or remove line numbers"
  echo " txt-trim    Trim whitespace safely, defaulting to trailing spaces only"
  echo " txt-eol     Normalize line endings to LF or CRLF"
  echo " txt-wc      Show line, word, and byte counts, not character counts"
  echo " txt-chars   Show character counts"
  echo " txt-stats   Show line, word, character, and byte counts"
  echo ""
  echo "Convenience wrappers:"
  echo " txt-up      Shortcut for txt-case --mode upper"
  echo " txt-low     Shortcut for txt-case --mode lower"
  echo " txt-title   Shortcut for txt-case --mode title"
  echo ""
  echo "Compatibility wrappers:"
  echo " text-dedup, text-case, text-linenum, text-help"
  echo ""
  echo "Examples:"
  echo " txt-dd notes.txt"
  echo " txt-trim --mode both docs/"
  echo " txt-eol --mode lf -r ."
  echo " txt-wc README.md"
  echo " txt-chars \"*.md\""
  echo " txt-stats docs/ -p \"*.md\" -r"
}

# Alias Exports
### --- ###

alias txt-dd='() { _text_dedup_text_aliases "$@"; }' # Remove duplicate lines while preserving order by default
alias txt-dedup='() { _text_dedup_text_aliases "$@"; }' # Readable alias for duplicate line removal
alias txt-case='() { _text_case_text_aliases "$@"; }' # Convert file content to lower, upper, or title case
alias txt-up='() { _text_case_text_aliases --mode upper "$@"; }' # Shortcut for uppercase conversion
alias txt-low='() { _text_case_text_aliases --mode lower "$@"; }' # Shortcut for lowercase conversion
alias txt-title='() { _text_case_text_aliases --mode title "$@"; }' # Shortcut for title case conversion
alias txt-nl='() { _text_line_numbers_text_aliases "$@"; }' # Add or remove line numbers
alias txt-trim='() { _text_trim_text_aliases "$@"; }' # Trim whitespace with safe defaults
alias txt-eol='() { _text_eol_text_aliases "$@"; }' # Normalize line endings without dos2unix dependency
alias txt-wc='() { _text_wc_text_aliases "$@"; }' # Show line, word, and byte counts
alias txt-chars='() { _text_chars_text_aliases "$@"; }' # Show character counts for text files
alias txt-stats='() { _text_stats_text_aliases "$@"; }' # Show line, word, character, and byte counts
alias txt-help='() { _text_help_text_aliases "$@"; }' # Display help for text aliases

# Legacy Compatibility
### --- ###

alias text-dedup='() { _text_dedup_text_aliases "$@"; }' # Legacy wrapper for txt-dd
alias text-case='() { _text_case_text_aliases "$@"; }' # Legacy wrapper for txt-case
alias text-linenum='() { _text_line_numbers_text_aliases "$@"; }' # Legacy wrapper for txt-nl
alias text-help='() { _text_help_text_aliases "$@"; }' # Legacy wrapper for txt-help
