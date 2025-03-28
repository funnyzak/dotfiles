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
alias htop='htop -u $USER'  # Display current user's processes in htop
alias top='top -u $USER'    # Display current user's processes in top

# System monitoring
alias watchmem='watch -d -n 1 free -m'  # Watch memory usage with updates every second

# File hash calculations
alias md5='md5sum'  # Calculate MD5 hash of a file
alias sha1='shasum -a 1'  # Calculate SHA1 hash of a file
alias sha256='shasum -a 256'  # Calculate SHA256 hash of a file
alias sha512='shasum -a 512'  # Calculate SHA512 hash of a file

# Random string generation helper function
_generate_random_string_system_aliases() {
  local charset="$1"
  local length="$2"
  local count="$3"

  if ! openssl rand -base64 2048 | tr -dc "$charset" | fold -w "$length" | head -n "$count"; then
    _show_error_system_aliases "Failed to generate random string"
    return 1
  fi
}

# Random password generation
alias generate_password='() {
  local length="${1:-16}"
  local count="${2:-1}"

  if [ $# -eq 0 ]; then
    _show_usage_system_aliases "Generate random password.\nUsage:\n generate_password <length:16> <count:1>"
    return 0
  fi

  _generate_random_string_system_aliases "a-zA-Z0-9" "$length" "$count"
}'

alias generate_numbers='() {
  local length="${1:-16}"
  local count="${2:-1}"

  if [ $# -eq 0 ]; then
    _show_usage_system_aliases "Generate random numeric string.\nUsage:\n generate_numbers <length:16> <count:1>"
    return 0
  fi

  _generate_random_string_system_aliases "0-9" "$length" "$count"
}'

alias generate_strings='() {
  local length="${1:-16}"
  local count="${2:-1}"

  if [ $# -eq 0 ]; then
    _show_usage_system_aliases "Generate random alphabetic string.\nUsage:\n generate_strings <length:16> <count:1>"
    return 0
  }

  _generate_random_string_system_aliases "a-z" "$length" "$count"
}'

# General utilities
alias cls='clear'  # Clear screen

alias clear_history='() {
  echo "Clearing command history"
  if history -c && history -w && history -r; then
    echo "Command history cleared"
  else
    _show_error_system_aliases "Failed to clear command history"
  fi
}'

# File synchronization
alias rsync="rsync -avzP"  # Use rsync with archive, verbose, compress and progress options
alias rsync_delete="rsync -avzP --delete"  # rsync with delete option for exact mirror

alias rsync_remote='() {
  if [ $# -lt 3 ]; then
    _show_usage_system_aliases "Rsync from remote server to local or vice versa.\nUsage:\n rsync_remote <port> <source> <destination>\nExample: rsync_remote 2001 user@server1:/mnt/ /data\nExample: rsync_remote 2001 /mnt/ user@server1:/data"
    return 1
  fi
  echo "Syncing from $2 to $3 via port $1"
  if ! rsync -av -e "ssh -p $1" "$2" "$3"; then
    _show_error_system_aliases "Rsync operation failed"
  fi
}'

# Virtual environment utilities
alias venv_create='() {
  local env_dir="${1:-venv}"
  if [ -d "$env_dir" ]; then
    echo "Activating virtual environment: $env_dir"
    if ! source "$env_dir/bin/activate"; then
      _show_error_system_aliases "Failed to activate virtual environment: $env_dir"
      return 1
    fi
  else
    echo "Creating virtual environment: $env_dir"
    if ! python3 -m venv "$env_dir"; then
      _show_error_system_aliases "Failed to create virtual environment: $env_dir"
      return 1
    fi
    source "$env_dir/bin/activate" || _show_error_system_aliases "Failed to activate new virtual environment"
  fi
}'

alias venv_exit='() {
  if [ -z "$VIRTUAL_ENV" ]; then
    echo "No virtual environment is currently activated."
  else
    echo "Deactivating virtual environment: $VIRTUAL_ENV"
    deactivate
  fi
}'

alias venv_delete='() {
  local env_dir="${1:-venv}"
  if [ -d "$env_dir" ]; then
    echo "Removing virtual environment: $env_dir"
    if ! rm -rf "$env_dir"; then
      _show_error_system_aliases "Failed to remove virtual environment: $env_dir"
      return 1
    fi
  else
    echo "Virtual environment not found: $env_dir"
  fi
}'

alias venv_info='() {
  if [ -z "$VIRTUAL_ENV" ]; then
    echo "No virtual environment is currently activated."
  else
    echo "Virtual environment: $VIRTUAL_ENV"
  fi
}'
