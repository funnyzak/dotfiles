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

# SSL utilities
alias sslscan='() {
  if [ $# -eq 0 ]; then
    _show_usage_system_aliases "Scan SSL/TLS configuration.\nUsage:\n sslscan <domain> <port:443>"
    return 1
  fi
  nmap --script ssl-enum-ciphers -p "${2:-443}" "$1" || _show_error_system_aliases "Failed to scan SSL configuration for $1"
}'

alias sslscan2='sslscan -tlsall'  # Scan with all TLS protocol versions

# Internet speed testing
alias speedtest='() {
  echo "Running internet speed test..."
  curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python - || _show_error_system_aliases "Failed to run speed test"
}'

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
alias rand_pass='() {
  if [ $# -eq 0 ]; then
    _show_usage_system_aliases "Generate random password.\nUsage:\n rand_pass <length:16> <count:1>"
  fi
  local length="${1:-16}"
  local count="${2:-1}"
  _generate_random_string_system_aliases "a-zA-Z0-9" "$length" "$count"
}'

alias rand_nums='() {
  if [ $# -eq 0 ]; then
    _show_usage_system_aliases "Generate random numeric string.\nUsage:\n rand_nums <length:16> <count:1>"
  fi
  local length="${1:-16}"
  local count="${2:-1}"
  _generate_random_string_system_aliases "0-9" "$length" "$count"
}'

alias rand_strs='() {
  if [ $# -eq 0 ]; then
    _show_usage_system_aliases "Generate random alphabetic string.\nUsage:\n rand_strs <length:16> <count:1>"
  fi
  local length="${1:-16}"
  local count="${2:-1}"
  _generate_random_string_system_aliases "a-z" "$length" "$count"
}'

# Server utilities
alias httpserver='() {
  local port="${1:-3080}"
  echo "Starting HTTP server on port $port"
  if ! python -m http.server "$port"; then
    _show_error_system_aliases "Failed to start HTTP server on port $port"
  fi
}'

alias sserve='() {
  local port="${1:-8080}"
  echo "Starting serve HTTP server on port $port"
  if ! command -v serve &> /dev/null; then
    _show_error_system_aliases "serve command not found. Please install it first."
    return 1
  fi
  if ! serve -port "$port"; then
    _show_error_system_aliases "Failed to start serve on port $port"
  fi
}'

# General utilities
alias cls='clear'  # Clear screen

alias clch='() {
  echo "Clearing command history"
  if history -c && history -w && history -r; then
    echo "Command history cleared"
  else
    _show_error_system_aliases "Failed to clear command history"
  fi
}'

# File synchronization
alias rsync="rsync -avzP"  # Use rsync with archive, verbose, compress and progress options
alias rsync_d="rsync -avzP --delete"  # rsync with delete option for exact mirror

alias rsync_r2l='() {
  if [ $# -lt 3 ]; then
    _show_usage_system_aliases "Rsync from remote server to local or vice versa.\nUsage:\n rsync_r2l <port> <source> <destination>\nExample: rsync_r2l 2001 user@server1:/mnt/ /data\nExample: rsync_r2l 2001 /mnt/ user@server1:/data"
    return 1
  fi
  echo "Syncing from $2 to $3 via port $1"
  if ! rsync -av -e "ssh -p $1" "$2" "$3"; then
    _show_error_system_aliases "Rsync operation failed"
  fi
}'

# Virtual environment utilities
alias venv_start='() {
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

alias venv_deactivate='() {
  if [ -z "$VIRTUAL_ENV" ]; then
    echo "No virtual environment is currently activated."
  else
    echo "Deactivating virtual environment: $VIRTUAL_ENV"
    deactivate
  fi
}'

alias venv_remove='() {
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

alias venv_list='() {
  if [ -z "$VIRTUAL_ENV" ]; then
    echo "No virtual environment is currently activated."
  else
    echo "Virtual environment: $VIRTUAL_ENV"
  fi
}'
