# Description: Advanced log viewing aliases with filtering, highlighting, real-time monitoring, and maintenance helpers

# Core helper functions
### --- ###

_log_error_log_aliases() {
  echo "Error: $1" >&2
}

_log_note_log_aliases() {
  echo "Note: $1" >&2
}

_log_output_color_mode_log_aliases() {
  if [ -t 1 ]; then
    echo "always"
  else
    echo "never"
  fi
}

_log_require_log_target_log_aliases() {
  local log_target="$1"

  if [ ! -f "$log_target" ]; then
    _log_error_log_aliases "Log file \"$log_target\" not found or not accessible."
    return 1
  fi

  return 0
}

_log_require_positive_integer_log_aliases() {
  local raw_value="$1"
  local value_label="$2"

  if ! [[ "$raw_value" =~ ^[0-9]+$ ]] || [ "$raw_value" -le 0 ]; then
    _log_error_log_aliases "${value_label} parameter must be a positive integer."
    return 1
  fi

  return 0
}

_log_require_positive_number_log_aliases() {
  local raw_value="$1"
  local value_label="$2"

  if ! [[ "$raw_value" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    _log_error_log_aliases "${value_label} parameter must be a positive number."
    return 1
  fi

  if ! awk -v numeric_value="$raw_value" "BEGIN { exit !(numeric_value > 0) }"; then
    _log_error_log_aliases "${value_label} parameter must be greater than zero."
    return 1
  fi

  return 0
}

_log_color_code_log_aliases() {
  local color_name="$1"

  case "$color_name" in
    red)
      echo "31"
      ;;
    green)
      echo "32"
      ;;
    yellow)
      echo "33"
      ;;
    blue)
      echo "34"
      ;;
    magenta)
      echo "35"
      ;;
    cyan)
      echo "36"
      ;;
    *)
      return 1
      ;;
  esac

  return 0
}

_log_stream_highlight_log_aliases() {
  local color_enabled="0"
  local item_separator=""
  local awk_specs=()
  local raw_spec=""
  local pattern_text=""
  local color_name=""
  local color_code=""

  if [ $# -eq 0 ]; then
    set -- "error:red" "ERROR:red" "Error:red" "warning:yellow" "WARNING:yellow" "Warning:yellow" "info:green" "INFO:green" "Info:green"
  fi

  if [ -t 1 ]; then
    color_enabled="1"
  fi

  item_separator=$(printf "\034")

  for raw_spec in "$@"; do
    if [[ "$raw_spec" == *:* ]]; then
      pattern_text="${raw_spec%%:*}"
      color_name="${raw_spec#*:}"
    else
      continue
    fi

    color_code=$(_log_color_code_log_aliases "$color_name")
    if [ $? -ne 0 ]; then
      _log_note_log_aliases "Unsupported color \"$color_name\". Using default color \"red\"."
      color_code="31"
    fi

    awk_specs+=("${pattern_text}${item_separator}${color_code}")
  done

  if [ ${#awk_specs[@]} -eq 0 ]; then
    awk_specs=(
      "error${item_separator}31"
      "ERROR${item_separator}31"
      "Error${item_separator}31"
      "warning${item_separator}33"
      "WARNING${item_separator}33"
      "Warning${item_separator}33"
      "info${item_separator}32"
      "INFO${item_separator}32"
      "Info${item_separator}32"
    )
  fi

  if ! awk -v color_enabled="$color_enabled" -v item_separator="$item_separator" "
    BEGIN {
      esc = sprintf(\"%c\", 27)
      spec_count = ARGC - 1
      for (i = 1; i < ARGC; i++) {
        split(ARGV[i], pair, item_separator)
        patterns[i] = pair[1]
        colors[i] = pair[2]
        delete ARGV[i]
      }
    }
    {
      line = \$0
      if (color_enabled == 1) {
        for (i = 1; i <= spec_count; i++) {
          gsub(patterns[i], esc \"[01;\" colors[i] \"m&\" esc \"[0m\", line)
        }
      }
      print line
    }
  " "${awk_specs[@]}"; then
    _log_error_log_aliases "Failed to highlight log content."
    return 1
  fi

  return 0
}

_log_filter_log_aliases() {
  local log_target="$1"
  local keyword_text="$2"
  local line_limit="$3"
  local scratch_input=""
  local color_mode=""
  local command_exit_code=0

  if ! _log_require_log_target_log_aliases "$log_target"; then
    return 1
  fi

  if ! _log_require_positive_integer_log_aliases "$line_limit" "Lines"; then
    return 1
  fi

  scratch_input=$(mktemp)
  if [ -z "$scratch_input" ] || [ ! -f "$scratch_input" ]; then
    _log_error_log_aliases "Failed to allocate scratch storage for log filtering."
    return 1
  fi

  if ! tail -n "$line_limit" "$log_target" > "$scratch_input"; then
    rm -f "$scratch_input"
    _log_error_log_aliases "Failed to read the last $line_limit lines from \"$log_target\"."
    return 1
  fi

  color_mode=$(_log_output_color_mode_log_aliases)
  grep --color="$color_mode" -- "$keyword_text" "$scratch_input"
  command_exit_code=$?
  rm -f "$scratch_input"

  if [ $command_exit_code -eq 0 ]; then
    return 0
  fi

  if [ $command_exit_code -eq 1 ]; then
    _log_note_log_aliases "No matches found for keyword \"$keyword_text\" in the last $line_limit lines."
    return 0
  fi

  _log_error_log_aliases "Failed to filter log content for keyword \"$keyword_text\"."
  return 1
}

_log_multi_filter_log_aliases() {
  local log_target="$1"
  local line_limit="$2"
  shift 2
  local grep_terms=("$@")
  local scratch_input=""
  local scratch_matches=""
  local command_exit_code=0

  if ! _log_require_log_target_log_aliases "$log_target"; then
    return 1
  fi

  if ! _log_require_positive_integer_log_aliases "$line_limit" "Lines"; then
    return 1
  fi

  scratch_input=$(mktemp)
  scratch_matches=$(mktemp)
  if [ -z "$scratch_input" ] || [ -z "$scratch_matches" ] || [ ! -f "$scratch_input" ] || [ ! -f "$scratch_matches" ]; then
    rm -f "$scratch_input" "$scratch_matches"
    _log_error_log_aliases "Failed to allocate scratch storage for multi-keyword filtering."
    return 1
  fi

  if ! tail -n "$line_limit" "$log_target" > "$scratch_input"; then
    rm -f "$scratch_input" "$scratch_matches"
    _log_error_log_aliases "Failed to read the last $line_limit lines from \"$log_target\"."
    return 1
  fi

  if ! awk "
    BEGIN {
      term_count = ARGC - 2
      for (i = 1; i <= term_count; i++) {
        terms[i] = ARGV[i]
        delete ARGV[i]
      }
    }
    {
      for (i = 1; i <= term_count; i++) {
        if (\$0 !~ terms[i]) {
          next
        }
      }
      print
    }
  " "${grep_terms[@]}" "$scratch_input" > "$scratch_matches"; then
    rm -f "$scratch_input" "$scratch_matches"
    _log_error_log_aliases "Failed to filter log content with multiple keywords."
    return 1
  fi

  if [ ! -s "$scratch_matches" ]; then
    rm -f "$scratch_input" "$scratch_matches"
    _log_note_log_aliases "No matches found for the specified keywords in the last $line_limit lines."
    return 0
  fi

  if [ -t 1 ]; then
    _log_stream_highlight_log_aliases "${grep_terms[@]/%/:cyan}" < "$scratch_matches"
    command_exit_code=$?
  else
    cat "$scratch_matches"
    command_exit_code=$?
  fi

  rm -f "$scratch_input" "$scratch_matches"

  if [ $command_exit_code -ne 0 ]; then
    _log_error_log_aliases "Failed to print multi-keyword filter output."
    return 1
  fi

  return 0
}

_log_highlight_log_aliases() {
  local log_target="$1"
  local line_limit="$2"
  shift 2
  local pattern_specs=("$@")
  local scratch_input=""
  local command_exit_code=0

  if ! _log_require_log_target_log_aliases "$log_target"; then
    return 1
  fi

  if ! _log_require_positive_integer_log_aliases "$line_limit" "Lines"; then
    return 1
  fi

  scratch_input=$(mktemp)
  if [ -z "$scratch_input" ] || [ ! -f "$scratch_input" ]; then
    _log_error_log_aliases "Failed to allocate scratch storage for log highlighting."
    return 1
  fi

  if ! tail -n "$line_limit" "$log_target" > "$scratch_input"; then
    rm -f "$scratch_input"
    _log_error_log_aliases "Failed to read the last $line_limit lines from \"$log_target\"."
    return 1
  fi

  _log_stream_highlight_log_aliases "${pattern_specs[@]}" < "$scratch_input"
  command_exit_code=$?
  rm -f "$scratch_input"

  if [ $command_exit_code -ne 0 ]; then
    _log_error_log_aliases "Failed to highlight log content."
    return 1
  fi

  return 0
}

_log_render_watch_snapshot_log_aliases() {
  local log_target="$1"
  local line_limit="$2"
  local keyword_text="$3"

  if [ -z "$keyword_text" ]; then
    if ! tail -n "$line_limit" "$log_target"; then
      _log_error_log_aliases "Failed to read the last $line_limit lines from \"$log_target\"."
      return 1
    fi

    return 0
  fi

  _log_filter_log_aliases "$log_target" "$keyword_text" "$line_limit"
}

_log_follow_highlight_log_aliases() {
  local log_target="$1"
  local line_limit="$2"
  shift 2
  local pattern_specs=("$@")

  if ! _log_require_log_target_log_aliases "$log_target"; then
    return 1
  fi

  if ! _log_require_positive_integer_log_aliases "$line_limit" "Lines"; then
    return 1
  fi

  if [ -n "${ZSH_VERSION:-}" ]; then
    setopt localoptions pipefail
  fi

  echo "Following \"$log_target\" with highlighting..."
  echo "Press Ctrl+C to exit."

  if ! tail -f -n "$line_limit" "$log_target" | _log_stream_highlight_log_aliases "${pattern_specs[@]}"; then
    _log_error_log_aliases "Failed to follow log content with highlighting."
    return 1
  fi

  return 0
}

_log_system_log_target_log_aliases() {
  if [ -f "/var/log/system.log" ]; then
    echo "/var/log/system.log"
    return 0
  fi

  if [ -f "/var/log/syslog" ]; then
    echo "/var/log/syslog"
    return 0
  fi

  return 1
}

# Backward-compatible helper wrappers
_loglog_filter() {
  _log_filter_log_aliases "$@"
}

_loglog_multi_filter() {
  _log_multi_filter_log_aliases "$@"
}

_loglog_highlight() {
  _log_highlight_log_aliases "$@"
}

# Public alias entry helpers
### --- ###

_log_filter_entry_log_aliases() {
  local alias_name="$1"
  shift

  echo -e "Filter log file content by keyword(s)\nUsage:\n ${alias_name} <log_target> <keyword> [lines:100]\nExample:\n ${alias_name} /var/log/system.log error"

  if [ $# -lt 2 ]; then
    _log_error_log_aliases "Insufficient parameters. Log file and keyword are required."
    return 1
  fi

  local log_target="$1"
  local keyword_text="$2"
  local line_limit="${3:-100}"

  _log_filter_log_aliases "$log_target" "$keyword_text" "$line_limit"
}

_log_multi_filter_entry_log_aliases() {
  local alias_name="$1"
  shift

  echo -e "Filter log file content by multiple keywords (AND logic)\nUsage:\n ${alias_name} <log_target> <keyword1> <keyword2> [keyword3...] [--lines 100]\nExample:\n ${alias_name} /var/log/system.log error warning --lines 200"

  if [ $# -lt 3 ]; then
    _log_error_log_aliases "Insufficient parameters. Log file and at least two keywords are required."
    return 1
  fi

  local log_target="$1"
  local line_limit="100"
  local grep_terms=()
  local raw_arg=""
  shift

  while [ $# -gt 0 ]; do
    raw_arg="$1"

    case "$raw_arg" in
      --lines=*)
        line_limit="${raw_arg#--lines=}"
        ;;
      --lines)
        if [ $# -lt 2 ]; then
          _log_error_log_aliases "Missing value for --lines."
          return 1
        fi
        line_limit="$2"
        shift
        ;;
      *)
        grep_terms+=("$raw_arg")
        ;;
    esac

    shift
  done

  if [ ${#grep_terms[@]} -lt 2 ]; then
    _log_error_log_aliases "At least two keywords are required."
    return 1
  fi

  _log_multi_filter_log_aliases "$log_target" "$line_limit" "${grep_terms[@]}"
}

_log_highlight_entry_log_aliases() {
  local alias_name="$1"
  shift

  echo -e "View log file with highlighted patterns\nUsage:\n ${alias_name} <log_target> [pattern1:red] [pattern2:green] [pattern3:yellow] [lines:100]\nExample:\n ${alias_name} /var/log/system.log error:red warning:yellow info:green"

  if [ $# -lt 1 ]; then
    _log_error_log_aliases "Log file path is required."
    return 1
  fi

  local log_target="$1"
  local line_limit="100"
  local pattern_specs=()
  local raw_arg=""
  shift

  while [ $# -gt 0 ]; do
    raw_arg="$1"

    case "$raw_arg" in
      --lines=*)
        line_limit="${raw_arg#--lines=}"
        ;;
      --lines)
        if [ $# -lt 2 ]; then
          _log_error_log_aliases "Missing value for --lines."
          return 1
        fi
        line_limit="$2"
        shift
        ;;
      lines:*)
        line_limit="${raw_arg#lines:}"
        ;;
      *)
        if [[ "$raw_arg" =~ ^[0-9]+$ ]]; then
          line_limit="$raw_arg"
        else
          pattern_specs+=("$raw_arg")
        fi
        ;;
    esac

    shift
  done

  _log_highlight_log_aliases "$log_target" "$line_limit" "${pattern_specs[@]}"
}

_log_watch_entry_log_aliases() {
  local alias_name="$1"
  shift

  echo -e "Watch log file in real-time with optional refresh interval\nUsage:\n ${alias_name} <log_target> [interval:2] [lines:20] [keyword]\nExample:\n ${alias_name} /var/log/system.log 5 50 error"

  if [ $# -lt 1 ]; then
    _log_error_log_aliases "Log file path is required."
    return 1
  fi

  local log_target="$1"
  local interval_value="2"
  local line_limit="20"
  local keyword_text=""
  local extra_count=0
  shift

  extra_count=$#

  if [ $# -gt 0 ]; then
    case "$1" in
      interval:*)
        interval_value="${1#interval:}"
        shift
        ;;
      lines:*)
        line_limit="${1#lines:}"
        shift
        ;;
      *)
        if [[ "$1" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
          interval_value="$1"
          shift
        elif [ $extra_count -eq 1 ]; then
          keyword_text="$1"
          shift
        else
          _log_error_log_aliases "Interval parameter must be a positive number."
          return 1
        fi
        ;;
    esac
  fi

  if [ $# -gt 0 ]; then
    case "$1" in
      lines:*)
        line_limit="${1#lines:}"
        shift
        ;;
      *)
        if [[ "$1" =~ ^[0-9]+$ ]]; then
          line_limit="$1"
          shift
        fi
        ;;
    esac
  fi

  if [ $# -gt 0 ]; then
    keyword_text="$*"
  fi

  if ! _log_require_log_target_log_aliases "$log_target"; then
    return 1
  fi

  if ! _log_require_positive_number_log_aliases "$interval_value" "Interval"; then
    return 1
  fi

  if ! _log_require_positive_integer_log_aliases "$line_limit" "Lines"; then
    return 1
  fi

  echo "Watching \"$log_target\" (refreshing every $interval_value seconds)..."
  echo "Press Ctrl+C to exit."

  while true; do
    if command -v clear >/dev/null 2>&1; then
      clear
    else
      printf "\033c"
    fi

    echo "Watching \"$log_target\" (refreshing every $interval_value seconds)..."
    echo "Press Ctrl+C to exit."
    echo ""

    if ! _log_render_watch_snapshot_log_aliases "$log_target" "$line_limit" "$keyword_text"; then
      return 1
    fi

    sleep "$interval_value"
  done
}

_log_follow_highlight_entry_log_aliases() {
  local alias_name="$1"
  shift

  echo -e "Follow log file updates with highlighted patterns\nUsage:\n ${alias_name} <log_target> [pattern1:red] [pattern2:green] [pattern3:yellow] [lines:50]\nExample:\n ${alias_name} /var/log/system.log error:red warning:yellow"

  if [ $# -lt 1 ]; then
    _log_error_log_aliases "Log file path is required."
    return 1
  fi

  local log_target="$1"
  local line_limit="50"
  local pattern_specs=()
  local raw_arg=""
  shift

  while [ $# -gt 0 ]; do
    raw_arg="$1"

    case "$raw_arg" in
      --lines=*)
        line_limit="${raw_arg#--lines=}"
        ;;
      --lines)
        if [ $# -lt 2 ]; then
          _log_error_log_aliases "Missing value for --lines."
          return 1
        fi
        line_limit="$2"
        shift
        ;;
      lines:*)
        line_limit="${raw_arg#lines:}"
        ;;
      *)
        if [[ "$raw_arg" =~ ^[0-9]+$ ]]; then
          line_limit="$raw_arg"
        else
          pattern_specs+=("$raw_arg")
        fi
        ;;
    esac

    shift
  done

  _log_follow_highlight_log_aliases "$log_target" "$line_limit" "${pattern_specs[@]}"
}

_log_system_entry_log_aliases() {
  echo -e "View system log with highlighting\nUsage:\n sysl [lines:100] [pattern1:red] [pattern2:green]\nExample:\n sysl 50 error:red"

  local line_limit="100"
  local pattern_specs=()
  local system_log_target=""
  local raw_arg=""

  while [ $# -gt 0 ]; do
    raw_arg="$1"

    case "$raw_arg" in
      --lines=*)
        line_limit="${raw_arg#--lines=}"
        ;;
      --lines)
        if [ $# -lt 2 ]; then
          _log_error_log_aliases "Missing value for --lines."
          return 1
        fi
        line_limit="$2"
        shift
        ;;
      lines:*)
        line_limit="${raw_arg#lines:}"
        ;;
      *)
        if [[ "$raw_arg" =~ ^[0-9]+$ ]]; then
          line_limit="$raw_arg"
        else
          pattern_specs+=("$raw_arg")
        fi
        ;;
    esac

    shift
  done

  system_log_target=$(_log_system_log_target_log_aliases)
  if [ $? -ne 0 ] || [ -z "$system_log_target" ]; then
    _log_error_log_aliases "System log file not found."
    return 1
  fi

  _log_highlight_log_aliases "$system_log_target" "$line_limit" "${pattern_specs[@]}"
}

_log_clear_entry_log_aliases() {
  local alias_name="$1"
  shift

  echo -e "Clear log file(s) (truncate to zero length)\nUsage:\n ${alias_name} <log_target1> [log_target2] [log_target3...]\nExample:\n ${alias_name} /var/log/app.log /var/log/error.log"

  if [ $# -lt 1 ]; then
    _log_error_log_aliases "At least one log file path is required."
    return 1
  fi

  local cleared_count=0
  local failed_count=0
  local log_target=""

  for log_target in "$@"; do
    if [ ! -f "$log_target" ]; then
      _log_error_log_aliases "Log file \"$log_target\" not found or not accessible."
      failed_count=$((failed_count + 1))
      continue
    fi

    if [ ! -w "$log_target" ]; then
      _log_error_log_aliases "No write permission for log file \"$log_target\"."
      failed_count=$((failed_count + 1))
      continue
    fi

    if : > "$log_target"; then
      echo "Successfully cleared log file: \"$log_target\""
      cleared_count=$((cleared_count + 1))
    else
      _log_error_log_aliases "Failed to clear log file \"$log_target\"."
      failed_count=$((failed_count + 1))
    fi
  done

  echo ""
  echo "Summary: Cleared $cleared_count file(s), failed to clear $failed_count file(s)."

  if [ $failed_count -gt 0 ]; then
    return 1
  fi

  return 0
}

_log_tail_follow_entry_log_aliases() {
  local alias_name="$1"
  local line_limit="$2"
  shift 2

  echo -e "Display last ${line_limit} lines of file and follow updates.\nUsage:\n ${alias_name} <log_target1> [log_target2] [log_target3...]\nExample:\n ${alias_name} /var/log/system.log"

  if [ $# -lt 1 ]; then
    _log_error_log_aliases "At least one log file path is required."
    return 1
  fi

  local log_target=""

  for log_target in "$@"; do
    if ! _log_require_log_target_log_aliases "$log_target"; then
      return 1
    fi
  done

  if ! tail -f -n "$line_limit" "$@"; then
    _log_error_log_aliases "Failed to follow log content."
    return 1
  fi

  return 0
}

_log_help_entry_log_aliases() {
  echo "Advanced log viewing aliases with filtering, highlighting and real-time monitoring"
  echo ""
  echo "Log filtering:"
  echo "  logf                 - Filter log file content by keyword (short for log-filter)"
  echo "  log-filter           - Filter log file content by keyword"
  echo "  logmf                - Filter log by multiple keywords (short for log-multi-filter)"
  echo "  log-multi-filter     - Filter log by multiple keywords"
  echo ""
  echo "Log highlighting:"
  echo "  logh                 - View log with highlighted patterns (short for log-highlight)"
  echo "  log-highlight        - View log with highlighted patterns"
  echo ""
  echo "Real-time monitoring:"
  echo "  logw                 - Watch log in real-time (short for log-watch)"
  echo "  log-watch            - Watch log in real-time"
  echo "  logfh                - Follow log with highlighting (short for log-follow-highlight)"
  echo "  log-follow-highlight - Follow log with highlighting"
  echo ""
  echo "Log clearing:"
  echo "  log-clear            - Clear log file(s) (truncate to zero length)"
  echo "  logc                 - Clear log file(s) using the short alias"
  echo ""
  echo "Quick shortcuts:"
  echo "  sysl                 - View system log with highlighting"
  echo "  log100               - Follow the last 100 log lines"
  echo "  log200               - Follow the last 200 log lines"
  echo "  log500               - Follow the last 500 log lines"
  echo "  log1000              - Follow the last 1000 log lines"
  echo "  log2000              - Follow the last 2000 log lines"
  echo ""
  echo "Help:"
  echo "  log-help             - Display this help message"
}

# Log viewing with keyword filtering
### --- ###
alias logf='() { _log_filter_entry_log_aliases "logf" "$@"; }' # Filter log file content by keyword(s)
alias log-filter='() { _log_filter_entry_log_aliases "log-filter" "$@"; }' # Filter log file content by keyword(s) (original name)
alias logmf='() { _log_multi_filter_entry_log_aliases "logmf" "$@"; }' # Filter log file content by multiple keywords (AND logic)
alias log-multi-filter='() { _log_multi_filter_entry_log_aliases "log-multi-filter" "$@"; }' # Filter log file content by multiple keywords (AND logic) (original name)

# Log viewing with highlighting
### --- ###
alias logh='() { _log_highlight_entry_log_aliases "logh" "$@"; }' # View log file with highlighted patterns
alias log-highlight='() { _log_highlight_entry_log_aliases "log-highlight" "$@"; }' # View log file with highlighted patterns (original name)

# Real-time log monitoring
### --- ###
alias logw='() { _log_watch_entry_log_aliases "logw" "$@"; }' # Watch log file in real-time with optional refresh interval
alias log-watch='() { _log_watch_entry_log_aliases "log-watch" "$@"; }' # Watch log file in real-time with optional refresh interval (original name)
alias logfh='() { _log_follow_highlight_entry_log_aliases "logfh" "$@"; }' # Follow log file updates with highlighted patterns
alias log-follow-highlight='() { _log_follow_highlight_entry_log_aliases "log-follow-highlight" "$@"; }' # Follow log file updates with highlighted patterns (original name)

# Quick shortcuts for common log files
### --- ###
alias sysl='() { _log_system_entry_log_aliases "$@"; }' # View system log with highlighting

# Log file clearing
### --- ###
alias log-clear='() { _log_clear_entry_log_aliases "log-clear" "$@"; }' # Clear log file(s) (truncate to zero length)
alias logc='() { _log_clear_entry_log_aliases "logc" "$@"; }' # Clear log file(s) using the short alias

# Fixed line follow shortcuts
### --- ###
alias log100='() { _log_tail_follow_entry_log_aliases "log100" "100" "$@"; }' # Display last 100 lines of file and follow updates
alias log200='() { _log_tail_follow_entry_log_aliases "log200" "200" "$@"; }' # Display last 200 lines of file and follow updates
alias log500='() { _log_tail_follow_entry_log_aliases "log500" "500" "$@"; }' # Display last 500 lines of file and follow updates
alias log1000='() { _log_tail_follow_entry_log_aliases "log1000" "1000" "$@"; }' # Display last 1000 lines of file and follow updates
alias log2000='() { _log_tail_follow_entry_log_aliases "log2000" "2000" "$@"; }' # Display last 2000 lines of file and follow updates

# Help function
### --- ###
alias log-help='() { _log_help_entry_log_aliases "$@"; }' # Display help for advanced log viewing aliases
