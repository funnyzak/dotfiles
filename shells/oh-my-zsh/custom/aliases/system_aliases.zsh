# Description: System related aliases for monitoring, information, security, and administration tasks.

# Helper function for showing errors
_show_error_system_aliases() {
  echo "$1" >&2
  return 1
}

# Helper function for displaying usage
_show_usage_system_aliases() {
  echo -e "$1"
  return 0
}

# System information
alias df='df -h'  # Display disk usage in human-readable format
alias du='du -ch'  # Display directory size with total in human-readable format
alias free='free -m'  # Display memory usage in MB

# Convert simple aliases to function form for better flexibility
alias htop='() {
  echo "Display processes in htop, filtered by user (default: current user)."
  echo -e "Usage:\n htop [username:$USER]"

  local user="${1:-$USER}"
  htop -u "$user"
}'  # Display processes in htop, filtered by user

alias top='() {
  echo "Display processes in top, filtered by user (default: current user)."
  echo -e "Usage:\n top [username:$USER]"

  local user="${1:-$USER}"
  top -u "$user"
}'  # Display processes in top, filtered by user

# System monitoring
alias watch-mem='() {
  echo "Watch memory usage with regular updates."
  echo -e "Usage:\n watch-mem [interval_seconds:1]"

  local interval="${1:-1}"

  if ! [[ "$interval" =~ ^[0-9]+$ ]]; then
    _show_error_system_aliases "Error: Interval must be a positive integer"
    return 1
  fi

  watch -d -n "$interval" free -m
}'  # Watch memory usage with regular updates

# File hash calculations
alias calc-md5='() {
  echo "Calculate MD5 hash of file(s)."
  echo -e "Usage:\n calc-md5 <file1> [file2] [...]"

  if [ $# -eq 0 ]; then
    _show_error_system_aliases "Error: No files specified"
    return 1
  fi

  md5sum "$@"
}'  # Calculate MD5 hash of files

alias calc-sha1='() {
  echo "Calculate SHA1 hash of file(s)."
  echo -e "Usage:\n calc-sha1 <file1> [file2] [...]"

  if [ $# -eq 0 ]; then
    _show_error_system_aliases "Error: No files specified"
    return 1
  fi

  shasum -a 1 "$@"
}'  # Calculate SHA1 hash of files

alias calc-sha256='() {
  echo "Calculate SHA256 hash of file(s)."
  echo -e "Usage:\n calc-sha256 <file1> [file2] [...]"

  if [ $# -eq 0 ]; then
    _show_error_system_aliases "Error: No files specified"
    return 1
  fi

  shasum -a 256 "$@"
}'  # Calculate SHA256 hash of files

alias calc-sha512='() {
  echo "Calculate SHA512 hash of file(s)."
  echo -e "Usage:\n calc-sha512 <file1> [file2] [...]"

  if [ $# -eq 0 ]; then
    _show_error_system_aliases "Error: No files specified"
    return 1
  fi

  shasum -a 512 "$@"
}'  # Calculate SHA512 hash of files

# Random string generation helper function
_generate_random_string_system_aliases() {
  local charset="$1"
  local length="$2"
  local count="$3"

  # Validate parameters
  if [ -z "$charset" ] || [ -z "$length" ] || [ -z "$count" ]; then
    _show_error_system_aliases "Internal error: Missing parameters for string generation"
    return 1
  fi

  if ! [[ "$length" =~ ^[0-9]+$ ]] || [ "$length" -lt 1 ]; then
    _show_error_system_aliases "Internal error: Length must be a positive integer"
    return 1
  fi

  if ! [[ "$count" =~ ^[0-9]+$ ]] || [ "$count" -lt 1 ]; then
    _show_error_system_aliases "Internal error: Count must be a positive integer"
    return 1
  fi

  if ! command -v openssl &> /dev/null; then
    _show_error_system_aliases "Error: openssl command not found"
    return 1
  fi

  if ! openssl rand -base64 2048 | tr -dc "$charset" | fold -w "$length" | head -n "$count"; then
    _show_error_system_aliases "Error: Failed to generate random string"
    return 1
  fi
}

# Random string generation functions
alias gen-password='() {
  echo "Generate random password(s)."
  echo -e "Usage:\n gen-password [length:16] [count:1]"

  local length="${1:-16}"
  local count="${2:-1}"

  # Validate parameters
  if ! [[ "$length" =~ ^[0-9]+$ ]] || [ "$length" -lt 1 ]; then
    _show_error_system_aliases "Error: Length must be a positive integer"
    return 1
  fi

  if ! [[ "$count" =~ ^[0-9]+$ ]] || [ "$count" -lt 1 ]; then
    _show_error_system_aliases "Error: Count must be a positive integer"
    return 1
  fi

  _generate_random_string_system_aliases "a-zA-Z0-9" "$length" "$count"
}'  # Generate random passwords

alias gen-numbers='() {
  echo "Generate random numeric string(s)."
  echo -e "Usage:\n gen-numbers [length:16] [count:1]"

  local length="${1:-16}"
  local count="${2:-1}"

  # Validate parameters
  if ! [[ "$length" =~ ^[0-9]+$ ]] || [ "$length" -lt 1 ]; then
    _show_error_system_aliases "Error: Length must be a positive integer"
    return 1
  fi

  if ! [[ "$count" =~ ^[0-9]+$ ]] || [ "$count" -lt 1 ]; then
    _show_error_system_aliases "Error: Count must be a positive integer"
    return 1
  fi

  _generate_random_string_system_aliases "0-9" "$length" "$count"
}'  # Generate random numeric strings

alias gen-strings='() {
  echo "Generate random alphabetic string(s)."
  echo -e "Usage:\n gen-strings [length:16] [count:1]"

  local length="${1:-16}"
  local count="${2:-1}"

  # Validate parameters
  if ! [[ "$length" =~ ^[0-9]+$ ]] || [ "$length" -lt 1 ]; then
    _show_error_system_aliases "Error: Length must be a positive integer"
    return 1
  fi

  if ! [[ "$count" =~ ^[0-9]+$ ]] || [ "$count" -lt 1 ]; then
    _show_error_system_aliases "Error: Count must be a positive integer"
    return 1
  fi

  _generate_random_string_system_aliases "a-z" "$length" "$count"
}'  # Generate random alphabetic strings

# General utilities
alias cls='clear'  # Clear screen

alias clear-history='() {
  echo "Clearing command history."
  echo -e "Usage:\n clear-history"

  # Check if shell supports the required history commands
  if ! type history &> /dev/null; then
    _show_error_system_aliases "Error: history command not available in current shell"
    return 1
  fi

  if ! history -c 2>/dev/null; then
    _show_error_system_aliases "Error: Failed to clear history (history -c command failed)"
    return 1
  fi

  if ! history -w 2>/dev/null; then
    _show_error_system_aliases "Error: Failed to write history (history -w command failed)"
    return 1
  fi

  if ! history -r 2>/dev/null; then
    _show_error_system_aliases "Error: Failed to reload history (history -r command failed)"
    return 1
  fi

  echo "Command history cleared successfully"
}'  # Clear command history

# File synchronization
alias rsync-files='() {
  echo "Sync files/directories with rsync (archive, verbose, compress, progress)."
  echo -e "Usage:\n rsync-files <source> <destination> [additional_rsync_options]"

  if [ $# -lt 2 ]; then
    _show_error_system_aliases "Error: Source and destination parameters are required"
    return 1
  fi

  local source="$1"
  local destination="$2"
  shift 2  # Remove the first two parameters

  if ! rsync -avzP "$source" "$destination" "$@"; then
    _show_error_system_aliases "Error: Rsync operation failed"
    return 1
  fi
}'  # Rsync with archive, verbose, compress and progress options

alias rsync-mirror='() {
  echo "Sync files/directories with rsync using delete option for exact mirroring."
  echo -e "Usage:\n rsync-mirror <source> <destination> [additional_rsync_options]"

  if [ $# -lt 2 ]; then
    _show_error_system_aliases "Error: Source and destination parameters are required"
    return 1
  fi

  local source="$1"
  local destination="$2"
  shift 2  # Remove the first two parameters

  if ! rsync -avzP --delete "$source" "$destination" "$@"; then
    _show_error_system_aliases "Error: Rsync mirror operation failed"
    return 1
  fi
}'  # Rsync with delete option for exact mirror

alias rsync-remote='() {
  echo "Rsync from/to remote server using specific SSH port."
  echo -e "Usage:\n rsync-remote <port> <source> <destination> [additional_rsync_options]"
  echo -e "Examples:\n rsync-remote 2001 user@server1:/mnt/ /data"
  echo -e " rsync-remote 2001 /mnt/ user@server1:/data"

  if [ $# -lt 3 ]; then
    _show_error_system_aliases "Error: Port, source, and destination parameters are required"
    return 1
  fi

  local port="$1"
  local source="$2"
  local destination="$3"
  shift 3  # Remove the first three parameters

  # Validate port number
  if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    _show_error_system_aliases "Error: Port must be a number between 1 and 65535"
    return 1
  fi

  echo "Syncing from $source to $destination via port $port"
  if ! rsync -av -e "ssh -p $port" "$source" "$destination" "$@"; then
    _show_error_system_aliases "Error: Remote rsync operation failed"
    return 1
  fi
}'  # Rsync from/to remote server using specific SSH port

# System monitoring functions
alias sys-info='() {
  echo "Display system information summary."
  echo -e "Usage:\n sys-info"

  echo "=== System Information ==="
  echo "Hostname: $(hostname)"
  echo "Kernel: $(uname -r)"
  echo "OS: $(uname -s)"

  # CPU info
  echo -e "\n=== CPU Information ==="
  if command -v lscpu &> /dev/null; then
    lscpu | grep -E "^(Model name|Architecture|CPU\(s\)|CPU MHz)"
  elif [ -f /proc/cpuinfo ]; then
    grep -E "^(model name|cpu MHz|processor)" /proc/cpuinfo | head -n 8
  elif command -v sysctl &> /dev/null; then
    echo "CPU Model: $(sysctl -n machdep.cpu.brand_string 2>/dev/null)"
    echo "CPU Cores: $(sysctl -n hw.ncpu 2>/dev/null)"
  fi

  # Memory info
  echo -e "\n=== Memory Information ==="
  if command -v free &> /dev/null; then
    free -h
  elif command -v vm_stat &> /dev/null; then
    # For macOS
    echo "Memory stats:"
    vm_stat
    echo "Total memory: $(sysctl -n hw.memsize 2>/dev/null | awk '{print $0/1024/1024/1024 " GB"}')"
  fi

  # Disk info
  echo -e "\n=== Disk Usage ==="
  df -h

  # Network info
  echo -e "\n=== Network Interfaces ==="
  if command -v ip &> /dev/null; then
    ip addr | grep -E "^[0-9]+:|inet " | grep -v "inet 127" | grep -v "inet6 ::1"
  elif command -v ifconfig &> /dev/null; then
    ifconfig | grep -E "^[a-zA-Z0-9]+:|inet " | grep -v "inet 127" | grep -v "inet6 ::1"
  fi
}'  # Display system information summary

alias process-mon='() {
  echo "Monitor system processes sorted by resource usage."
  echo -e "Usage:\n process-mon [resource_type:cpu]"
  echo -e "Resource types: cpu, mem, io"

  local resource="${1:-cpu}"

  case "$resource" in
    cpu)
      if command -v htop &> /dev/null; then
        htop --sort-key PERCENT_CPU
      else
        ps aux --sort=-%cpu | head -n 15
      fi
      ;;
    mem)
      if command -v htop &> /dev/null; then
        htop --sort-key PERCENT_MEM
      else
        ps aux --sort=-%mem | head -n 15
      fi
      ;;
    io)
      if command -v iotop &> /dev/null; then
        sudo iotop -o
      elif command -v iostat &> /dev/null; then
        iostat -x 1 5
      else
        _show_error_system_aliases "Error: No IO monitoring tool available (iotop/iostat)"
        return 1
      fi
      ;;
    *)
      _show_error_system_aliases "Error: Invalid resource type. Use 'cpu', 'mem', or 'io'"
      return 1
      ;;
  esac
}'  # Monitor system processes sorted by resource usage

