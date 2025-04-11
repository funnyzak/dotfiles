# Description: Advanced log viewing aliases with filtering, highlighting and real-time monitoring capabilities

# Core helper functions
### --- ###

# Helper function for filtering logs by keyword
_loglog_filter() {
  local log_file="$1"
  local keyword="$2"
  local lines="$3"

  # Validate file exists
  if [ ! -f "$log_file" ]; then
    echo "Error: Log file \"$log_file\" not found or not accessible." >&2
    return 1
  fi

  # Validate lines parameter is a number
  if ! [[ "$lines" =~ ^[0-9]+$ ]]; then
    echo "Error: Lines parameter must be a positive number." >&2
    return 1
  fi

  # Execute command with error handling
  tail -n "$lines" "$log_file" | grep --color=auto "$keyword"
  if [ $? -ne 0 ]; then
    echo "Note: No matches found for keyword \"$keyword\" in the last $lines lines." >&2
    return 0
  fi
}

# Helper function for filtering logs by multiple keywords
_loglog_multi_filter() {
  local log_file="$1"
  local lines="$2"
  shift 2
  local grep_args=("$@")

  # Validate file exists
  if [ ! -f "$log_file" ]; then
    echo "Error: Log file \"$log_file\" not found or not accessible." >&2
    return 1
  fi

  # Build the grep command chain
  local cmd="tail -n $lines \"$log_file\""

  for keyword in "${grep_args[@]}"; do
    cmd="$cmd | grep --color=auto \"$keyword\""
  done

  # Execute command with error handling
  eval "$cmd"
  local status=$?

  if [ $status -ne 0 ]; then
    echo "Note: No matches found for the specified keywords in the last $lines lines." >&2
    return 0
  fi
}

# Helper function for highlighting log patterns
_loglog_highlight() {
  local log_file="$1"
  local lines="$2"
  shift 2
  local patterns=("$@")
  local highlight_cmd=""

  # Validate file exists
  if [ ! -f "$log_file" ]; then
    echo "Error: Log file \"$log_file\" not found or not accessible." >&2
    return 1
  fi

  # Process patterns and build highlight command
  for arg in "${patterns[@]}"; do
    if [[ "$arg" == *:* ]]; then
      # Extract pattern and color
      local pattern="${arg%%:*}"
      local color="${arg#*:}"

      # Validate color
      case "$color" in
        red|green|yellow|blue|magenta|cyan)
          # Valid color
          ;;
        *)
          echo "Warning: Unsupported color \"$color\". Using default (red)." >&2
          color="red"
          ;;
      esac

      # Map color names to ANSI color codes
      local color_code
      case "$color" in
        red)      color_code="31" ;;
        green)    color_code="32" ;;
        yellow)   color_code="33" ;;
        blue)     color_code="34" ;;
        magenta)  color_code="35" ;;
        cyan)     color_code="36" ;;
      esac

      # Add to highlight command
      if [ -z "$highlight_cmd" ]; then
        highlight_cmd="GREP_COLOR=\"01;${color_code}\" grep --color=always -E \"$pattern|$\" "
      else
        highlight_cmd="$highlight_cmd | GREP_COLOR=\"01;${color_code}\" grep --color=always -E \"$pattern|$\" "
      fi
    fi
  done

  # If no highlight patterns were provided, use default highlighting
  if [ -z "$highlight_cmd" ]; then
    highlight_cmd="GREP_COLOR=\"01;31\" grep --color=always -E \"error|ERROR|Error|$\" | "
    highlight_cmd="$highlight_cmd GREP_COLOR=\"01;33\" grep --color=always -E \"warning|WARNING|Warning|$\" | "
    highlight_cmd="$highlight_cmd GREP_COLOR=\"01;32\" grep --color=always -E \"info|INFO|Info|$\" "
  fi

  # Execute command with error handling
  eval "tail -n $lines \"$log_file\" | $highlight_cmd"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to process log file." >&2
    return 1
  fi
}

# Log viewing with keyword filtering
### --- ###
alias logf='() {
  echo -e "Filter log file content by keyword(s)\nUsage:\n logf <file_path> <keyword> [lines:100]\nExample:\n logf /var/log/system.log error"

  # Parameter validation
  if [ $# -lt 2 ]; then
    echo "Error: Insufficient parameters. File path and keyword are required." >&2
    return 1
  fi

  local log_file="$1"
  local keyword="$2"
  local lines=${3:-100}

  _loglog_filter "$log_file" "$keyword" "$lines"
}' # Filter log file content by keyword(s)

alias log-filter='() {
  echo -e "Filter log file content by keyword(s)\nUsage:\n log-filter <file_path> <keyword> [lines:100]\nExample:\n log-filter /var/log/system.log error"

  # Parameter validation
  if [ $# -lt 2 ]; then
    echo "Error: Insufficient parameters. File path and keyword are required." >&2
    return 1
  fi

  local log_file="$1"
  local keyword="$2"
  local lines=${3:-100}

  _loglog_filter "$log_file" "$keyword" "$lines"
}' # Filter log file content by keyword(s) (original name)

alias logmf='() {
  echo -e "Filter log file content by multiple keywords (AND logic)\nUsage:\n logmf <file_path> <keyword1> <keyword2> [keyword3...] [--lines=100]\nExample:\n logmf /var/log/system.log error warning --lines=200"

  # Parameter validation
  if [ $# -lt 3 ]; then
    echo "Error: Insufficient parameters. File path and at least two keywords are required." >&2
    return 1
  fi

  local log_file="$1"
  local lines=100
  local grep_args=()
  local i=0

  # Process arguments
  shift # Remove file_path from arguments

  for arg in "$@"; do
    if [[ "$arg" == --lines=* ]]; then
      lines="${arg#--lines=}"
      # Validate lines parameter is a number
      if ! [[ "$lines" =~ ^[0-9]+$ ]]; then
        echo "Error: Lines parameter must be a positive number." >&2
        return 1
      fi
    else
      grep_args[$i]="$arg"
      i=$((i+1))
    fi
  done

  # Check if we have at least two keywords
  if [ ${#grep_args[@]} -lt 2 ]; then
    echo "Error: At least two keywords are required." >&2
    return 1
  fi

  _loglog_multi_filter "$log_file" "$lines" "${grep_args[@]}"
}' # Filter log file content by multiple keywords (AND logic)

alias log-multi-filter='() {
  echo -e "Filter log file content by multiple keywords (AND logic)\nUsage:\n log-multi-filter <file_path> <keyword1> <keyword2> [keyword3...] [--lines=100]\nExample:\n log-multi-filter /var/log/system.log error warning --lines=200"

  # Parameter validation
  if [ $# -lt 3 ]; then
    echo "Error: Insufficient parameters. File path and at least two keywords are required." >&2
    return 1
  fi

  local log_file="$1"
  local lines=100
  local grep_args=()
  local i=0

  # Process arguments
  shift # Remove file_path from arguments

  for arg in "$@"; do
    if [[ "$arg" == --lines=* ]]; then
      lines="${arg#--lines=}"
      # Validate lines parameter is a number
      if ! [[ "$lines" =~ ^[0-9]+$ ]]; then
        echo "Error: Lines parameter must be a positive number." >&2
        return 1
      fi
    else
      grep_args[$i]="$arg"
      i=$((i+1))
    fi
  done

  # Check if we have at least two keywords
  if [ ${#grep_args[@]} -lt 2 ]; then
    echo "Error: At least two keywords are required." >&2
    return 1
  fi

  _loglog_multi_filter "$log_file" "$lines" "${grep_args[@]}"
}' # Filter log file content by multiple keywords (AND logic) (original name)

# Log viewing with highlighting
### --- ###
alias logh='() {
  echo -e "View log file with highlighted patterns\nUsage:\n logh <file_path> [pattern1:red] [pattern2:green] [pattern3:yellow] [lines:100]\nExample:\n logh /var/log/system.log error:red warning:yellow info:green"

  # Parameter validation
  if [ $# -lt 1 ]; then
    echo "Error: Log file path is required." >&2
    return 1
  fi

  local log_file="$1"
  local lines=100
  local patterns=()

  # Process arguments
  shift # Remove file_path from arguments

  for arg in "$@"; do
    if [[ "$arg" =~ ^[0-9]+$ ]]; then
      # If argument is just a number, treat it as lines
      lines="$arg"
    elif [[ "$arg" == lines:* ]]; then
      # Extract lines value
      lines="${arg#lines:}"
      # Validate lines parameter is a number
      if ! [[ "$lines" =~ ^[0-9]+$ ]]; then
        echo "Error: Lines parameter must be a positive number." >&2
        return 1
      fi
    else
      patterns+=("$arg")
    fi
  done

  _loglog_highlight "$log_file" "$lines" "${patterns[@]}"
}' # View log file with highlighted patterns

alias log-highlight='() {
  echo -e "View log file with highlighted patterns\nUsage:\n log-highlight <file_path> [pattern1:red] [pattern2:green] [pattern3:yellow] [lines:100]\nExample:\n log-highlight /var/log/system.log error:red warning:yellow info:green"

  # Parameter validation
  if [ $# -lt 1 ]; then
    echo "Error: Log file path is required." >&2
    return 1
  fi

  local log_file="$1"
  local lines=100
  local patterns=()

  # Process arguments
  shift # Remove file_path from arguments

  for arg in "$@"; do
    if [[ "$arg" =~ ^[0-9]+$ ]]; then
      # If argument is just a number, treat it as lines
      lines="$arg"
    elif [[ "$arg" == lines:* ]]; then
      # Extract lines value
      lines="${arg#lines:}"
      # Validate lines parameter is a number
      if ! [[ "$lines" =~ ^[0-9]+$ ]]; then
        echo "Error: Lines parameter must be a positive number." >&2
        return 1
      fi
    else
      patterns+=("$arg")
    fi
  done

  _loglog_highlight "$log_file" "$lines" "${patterns[@]}"
}' # View log file with highlighted patterns (original name)

# Real-time log monitoring
### --- ###
alias logw='() {
  echo -e "Watch log file in real-time with optional refresh interval\nUsage:\n logw <file_path> [interval:2] [lines:20] [keyword]\nExample:\n logw /var/log/system.log 5 50 error"

  # Parameter validation
  if [ $# -lt 1 ]; then
    echo "Error: Log file path is required." >&2
    return 1
  fi

  local log_file="$1"
  local interval=2
  local lines=20
  local keyword=""

  # Validate file exists
  if [ ! -f "$log_file" ]; then
    echo "Error: Log file \"$log_file\" not found or not accessible." >&2
    return 1
  fi

  # Process optional arguments
  if [ $# -ge 2 ]; then
    # Check if second argument is a number (interval)
    if [[ "$2" =~ ^[0-9]+(.[0-9]+)?$ ]]; then
      interval="$2"
      shift
    fi
  fi

  if [ $# -ge 2 ]; then
    # Check if next argument is a number (lines)
    if [[ "$2" =~ ^[0-9]+$ ]]; then
      lines="$2"
      shift
    fi
  fi

  # If there"s still an argument, it"s the keyword
  if [ $# -ge 2 ]; then
    keyword="$2"
  fi

  # Prepare the watch command
  local cmd
  if [ -z "$keyword" ]; then
    cmd="tail -n $lines \"$log_file\""
  else
    cmd="tail -n $lines \"$log_file\" | grep --color=always \"$keyword\""
  fi

  # Execute the watch command
  echo "Watching \"$log_file\" (refreshing every $interval seconds)..."
  echo "Press Ctrl+C to exit."

  # Use watch command if available, otherwise use a while loop
  if command -v watch >/dev/null 2>&1; then
    watch -n "$interval" -c "$cmd"
    local status=$?
    if [ $status -ne 0 ]; then
      echo "Error: Failed to watch log file." >&2
      return 1
    fi
  else
    # Fallback for systems without watch command
    while true; do
      clear
      echo "Every ${interval}s: $cmd"
      echo ""
      eval "$cmd"
      sleep "$interval"
    done
  fi
}' # Watch log file in real-time with optional refresh interval

alias log-watch='() {
  echo -e "Watch log file in real-time with optional refresh interval\nUsage:\n log-watch <file_path> [interval:2] [lines:20] [keyword]\nExample:\n log-watch /var/log/system.log 5 50 error"

  # Parameter validation
  if [ $# -lt 1 ]; then
    echo "Error: Log file path is required." >&2
    return 1
  fi

  local log_file="$1"
  local interval=2
  local lines=20
  local keyword=""

  # Validate file exists
  if [ ! -f "$log_file" ]; then
    echo "Error: Log file \"$log_file\" not found or not accessible." >&2
    return 1
  fi

  # Process optional arguments
  if [ $# -ge 2 ]; then
    # Check if second argument is a number (interval)
    if [[ "$2" =~ ^[0-9]+(.[0-9]+)?$ ]]; then
      interval="$2"
      shift
    fi
  fi

  if [ $# -ge 2 ]; then
    # Check if next argument is a number (lines)
    if [[ "$2" =~ ^[0-9]+$ ]]; then
      lines="$2"
      shift
    fi
  fi

  # If there"s still an argument, it"s the keyword
  if [ $# -ge 2 ]; then
    keyword="$2"
  fi

  # Prepare the watch command
  local cmd
  if [ -z "$keyword" ]; then
    cmd="tail -n $lines \"$log_file\""
  else
    cmd="tail -n $lines \"$log_file\" | grep --color=always \"$keyword\""
  fi

  # Execute the watch command
  echo "Watching \"$log_file\" (refreshing every $interval seconds)..."
  echo "Press Ctrl+C to exit."

  # Use watch command if available, otherwise use a while loop
  if command -v watch >/dev/null 2>&1; then
    watch -n "$interval" -c "$cmd"
    local status=$?
    if [ $status -ne 0 ]; then
      echo "Error: Failed to watch log file." >&2
      return 1
    fi
  else
    # Fallback for systems without watch command
    while true; do
      clear
      echo "Every ${interval}s: $cmd"
      echo ""
      eval "$cmd"
      sleep "$interval"
    done
  fi
}' # Watch log file in real-time with optional refresh interval (original name)

alias logfh='() {
  echo -e "Follow log file updates with highlighted patterns\nUsage:\n logfh <file_path> [pattern1:red] [pattern2:green] [pattern3:yellow] [lines:50]\nExample:\n logfh /var/log/system.log error:red warning:yellow"

  # Parameter validation
  if [ $# -lt 1 ]; then
    echo "Error: Log file path is required." >&2
    return 1
  fi

  local log_file="$1"
  local lines=50
  local patterns=()

  # Validate file exists
  if [ ! -f "$log_file" ]; then
    echo "Error: Log file \"$log_file\" not found or not accessible." >&2
    return 1
  fi

  # Process arguments
  shift # Remove file_path from arguments

  for arg in "$@"; do
    if [[ "$arg" =~ ^[0-9]+$ ]]; then
      # If argument is just a number, treat it as lines
      lines="$arg"
    elif [[ "$arg" == lines:* ]]; then
      # Extract lines value
      lines="${arg#lines:}"
      # Validate lines parameter is a number
      if ! [[ "$lines" =~ ^[0-9]+$ ]]; then
        echo "Error: Lines parameter must be a positive number." >&2
        return 1
      fi
    else
      patterns+=("$arg")
    fi
  done

  # Build highlight command
  local highlight_cmd=""

  for arg in "${patterns[@]}"; do
    if [[ "$arg" == *:* ]]; then
      # Extract pattern and color
      local pattern="${arg%%:*}"
      local color="${arg#*:}"

      # Validate color
      case "$color" in
        red|green|yellow|blue|magenta|cyan)
          # Valid color
          ;;
        *)
          echo "Warning: Unsupported color \"$color\". Using default (red)." >&2
          color="red"
          ;;
      esac

      # Map color names to ANSI color codes
      local color_code
      case "$color" in
        red)      color_code="31" ;;
        green)    color_code="32" ;;
        yellow)   color_code="33" ;;
        blue)     color_code="34" ;;
        magenta)  color_code="35" ;;
        cyan)     color_code="36" ;;
      esac

      # Add to highlight command
      if [ -z "$highlight_cmd" ]; then
        highlight_cmd="GREP_COLOR=\"01;${color_code}\" grep --color=always -E \"$pattern|$\" "
      else
        highlight_cmd="$highlight_cmd | GREP_COLOR=\"01;${color_code}\" grep --color=always -E \"$pattern|$\" "
      fi
    fi
  done

  # If no highlight patterns were provided, use default highlighting
  if [ -z "$highlight_cmd" ]; then
    highlight_cmd="GREP_COLOR=\"01;31\" grep --color=always -E \"error|ERROR|Error|$\" | "
    highlight_cmd="$highlight_cmd GREP_COLOR=\"01;33\" grep --color=always -E \"warning|WARNING|Warning|$\" | "
    highlight_cmd="$highlight_cmd GREP_COLOR=\"01;32\" grep --color=always -E \"info|INFO|Info|$\" "
  fi

  # Execute command with error handling
  echo "Following \"$log_file\" with highlighting..."
  echo "Press Ctrl+C to exit."

  eval "tail -f -n $lines \"$log_file\" | $highlight_cmd"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to process log file." >&2
    return 1
  fi
}' # Follow log file updates with highlighted patterns

alias log-follow-highlight='() {
  echo -e "Follow log file updates with highlighted patterns\nUsage:\n log-follow-highlight <file_path> [pattern1:red] [pattern2:green] [pattern3:yellow] [lines:50]\nExample:\n log-follow-highlight /var/log/system.log error:red warning:yellow"

  # Parameter validation
  if [ $# -lt 1 ]; then
    echo "Error: Log file path is required." >&2
    return 1
  fi

  local log_file="$1"
  local lines=50
  local patterns=()

  # Validate file exists
  if [ ! -f "$log_file" ]; then
    echo "Error: Log file \"$log_file\" not found or not accessible." >&2
    return 1
  fi

  # Process arguments
  shift # Remove file_path from arguments

  for arg in "$@"; do
    if [[ "$arg" =~ ^[0-9]+$ ]]; then
      # If argument is just a number, treat it as lines
      lines="$arg"
    elif [[ "$arg" == lines:* ]]; then
      # Extract lines value
      lines="${arg#lines:}"
      # Validate lines parameter is a number
      if ! [[ "$lines" =~ ^[0-9]+$ ]]; then
        echo "Error: Lines parameter must be a positive number." >&2
        return 1
      fi
    else
      patterns+=("$arg")
    fi
  done

  # Build highlight command
  local highlight_cmd=""

  for arg in "${patterns[@]}"; do
    if [[ "$arg" == *:* ]]; then
      # Extract pattern and color
      local pattern="${arg%%:*}"
      local color="${arg#*:}"

      # Validate color
      case "$color" in
        red|green|yellow|blue|magenta|cyan)
          # Valid color
          ;;
        *)
          echo "Warning: Unsupported color \"$color\". Using default (red)." >&2
          color="red"
          ;;
      esac

      # Map color names to ANSI color codes
      local color_code
      case "$color" in
        red)      color_code="31" ;;
        green)    color_code="32" ;;
        yellow)   color_code="33" ;;
        blue)     color_code="34" ;;
        magenta)  color_code="35" ;;
        cyan)     color_code="36" ;;
      esac

      # Add to highlight command
      if [ -z "$highlight_cmd" ]; then
        highlight_cmd="GREP_COLOR=\"01;${color_code}\" grep --color=always -E \"$pattern|$\" "
      else
        highlight_cmd="$highlight_cmd | GREP_COLOR=\"01;${color_code}\" grep --color=always -E \"$pattern|$\" "
      fi
    fi
  done

  # If no highlight patterns were provided, use default highlighting
  if [ -z "$highlight_cmd" ]; then
    highlight_cmd="GREP_COLOR=\"01;31\" grep --color=always -E \"error|ERROR|Error|$\" | "
    highlight_cmd="$highlight_cmd GREP_COLOR=\"01;33\" grep --color=always -E \"warning|WARNING|Warning|$\" | "
    highlight_cmd="$highlight_cmd GREP_COLOR=\"01;32\" grep --color=always -E \"info|INFO|Info|$\" "
  fi

  # Execute command with error handling
  echo "Following \"$log_file\" with highlighting..."
  echo "Press Ctrl+C to exit."

  eval "tail -f -n $lines \"$log_file\" | $highlight_cmd"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to process log file." >&2
    return 1
  fi
}' # Follow log file updates with highlighted patterns (original name)

# Quick shortcuts for common log files
### --- ###
alias sysl='() {
  echo -e "View system log with highlighting\nUsage:\n sysl [lines:100] [pattern1:red] [pattern2:green]\nExample:\n sysl 50 error:red"

  local lines=100
  local patterns=()

  for arg in "$@"; do
    if [[ "$arg" =~ ^[0-9]+$ ]]; then
      lines="$arg"
    else
      patterns+=("$arg")
    fi
  done

  if [ -f "/var/log/system.log" ]; then
    _loglog_highlight "/var/log/system.log" "$lines" "${patterns[@]}"
  elif [ -f "/var/log/syslog" ]; then
    _loglog_highlight "/var/log/syslog" "$lines" "${patterns[@]}"
  else
    echo "Error: System log file not found." >&2
    return 1
  fi
}' # View system log with highlighting

# Log file clearing

alias log-clear='() {
  echo -e "Clear log file(s) (truncate to zero length)\nUsage:\n log-clear <file_path1> [file_path2] [file_path3...]\nExample:\n log-clear /var/log/app.log /var/log/error.log"

  # Parameter validation
  if [ $# -lt 1 ]; then
    echo "Error: At least one log file path is required." >&2
    return 1
  fi

  local success_count=0
  local failure_count=0
  local file_path=""
  local current_file=""

  # Process each file
  for file_path in "$@"; do
    current_file="$file_path"

    # Validate file exists
    if [ ! -f "$current_file" ]; then
      echo "Error: Log file \"$current_file\" not found or not accessible." >&2
      failure_count=$((failure_count + 1))
      continue
    fi

    # Validate file is writable
    if [ ! -w "$current_file" ]; then
      echo "Error: No write permission for log file \"$current_file\"." >&2
      failure_count=$((failure_count + 1))
      continue
    fi

    # Clear the log file
    : > "$current_file"
    if [ $? -eq 0 ]; then
      echo "Successfully cleared log file: \"$current_file\""
      success_count=$((success_count + 1))
    else
      echo "Error: Failed to clear log file \"$current_file\"." >&2
      failure_count=$((failure_count + 1))
    fi
  done

  # Summary
  echo ""
  echo "Summary: Cleared $success_count file(s), failed to clear $failure_count file(s)."

  # Return success only if all files were cleared successfully
  if [ $failure_count -gt 0 ]; then
    return 1
  fi
  return 0
}' # Clear log file(s) (truncate to zero length) (original name)

alias logc='log-clear' # Alias for log-clear

alias log100='() {
  echo "Display last 100 lines of file and follow updates.\nUsage:\n log100 <file_path>"
  tail -f -n 100 "$@"
}' # Display last 100 lines of file and follow updates

alias log200='() {
  echo "Display last 200 lines of file and follow updates.\nUsage:\n log200 <file_path>"
  tail -f -n 200 "$@"
}' # Display last 200 lines of file and follow updates

alias log500='() {
  echo "Display last 500 lines of file and follow updates.\nUsage:\n log500 <file_path>"
  tail -f -n 500 "$@"
}' # Display last 500 lines of file and follow updates

alias log1000='() {
  echo "Display last 1000 lines of file and follow updates.\nUsage:\n log1000 <file_path>"
  tail -f -n 1000 "$@"
}' # Display last 1000 lines of file and follow updates

alias log2000='() {
  echo "Display last 2000 lines of file and follow updates.\nUsage:\n log2000 <file_path>"
  tail -f -n 2000 "$@"
}' # Display last 2000 lines of file and follow updates

# Help function
### --- ###
alias log-help='() {
  echo "Advanced log viewing aliases with filtering, highlighting and real-time monitoring"
  echo ""
  echo "Log filtering:"
  echo "  logf              - Filter log file content by keyword (short for log-filter)"
  echo "  log-filter        - Filter log file content by keyword (original name)"
  echo "  logmf             - Filter log by multiple keywords (short for log-multi-filter)"
  echo "  log-multi-filter  - Filter log by multiple keywords (original name)"
  echo ""
  echo "Log highlighting:"
  echo "  logh              - View log with highlighted patterns (short for log-highlight)"
  echo "  log-highlight     - View log with highlighted patterns (original name)"
  echo ""
  echo "Real-time monitoring:"
  echo "  logw              - Watch log in real-time (short for log-watch)"
  echo "  log-watch         - Watch log in real-time (original name)"
  echo "  logfh             - Follow log with highlighting (short for log-follow-highlight)"
  echo "  log-follow-highlight - Follow log with highlighting (original name)"
  echo ""
  echo "Log clearing:"
  echo "  log-clear         - Clear log file(s) (truncate to zero length)"
  echo "  logc              - Alias for log-clear"
  echo ""
  echo "Quick shortcuts:"
  echo "  sysl              - View system log with highlighting"
  echo ""
  echo "Help:"
  echo "  log-help             - Display this help message (short for loglog-help)"
}' # Display help for advanced log viewing aliases
