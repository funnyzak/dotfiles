# Description: System related aliases for monitoring, information, security, and administration tasks.

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
    echo "Scan SSL/TLS configuration.\nUsage:\n sslscan <domain> <port:443>"
    return 1
  else
    nmap --script ssl-enum-ciphers -p ${2:-443} $1
  fi
}'  # Scan SSL/TLS configuration of a server

alias sslscan2='sslscan -tlsall'  # Scan with all TLS protocol versions

# Internet speed testing
alias speedtest="curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -"  # Run internet speed test

# Random password generation
alias rand_pass='() {
  if [ $# -eq 0 ]; then
    echo "Generate random password.\nUsage:\n rand_pass <length:16> <count:1>"
    length=16
    count=1
  else
    length=${1:-16}
    count=${2:-1}
  fi
  openssl rand -base64 2048 | tr -dc "a-zA-Z0-9" | fold -w $length | head -n $count
}'  # Generate random alphanumeric password

alias rand_nums='() {
  if [ $# -eq 0 ]; then
    echo "Generate random numeric string.\nUsage:\n rand_nums <length:16> <count:1>"
    length=16
    count=1
  else
    length=${1:-16}
    count=${2:-1}
  fi
  openssl rand -base64 2048 | tr -dc "0-9" | fold -w $length | head -n $count
}'  # Generate random numeric string

alias rand_strs='() {
  if [ $# -eq 0 ]; then
    echo "Generate random alphabetic string.\nUsage:\n rand_strs <length:16> <count:1>"
    length=16
    count=1
  else
    length=${1:-16}
    count=${2:-1}
  fi
  openssl rand -base64 2048 | tr -dc "a-z" | fold -w $length | head -n $count
}'  # Generate random alphabetic string

# SSH key generation
alias nkey_ed29='() {
  if [ $# -lt 2 ]; then
    echo "Generate ed25519 SSH key.\nUsage:\n nkey_ed29 <key_path> <email>"
    return 1
  fi
  fpath=${1:-id_ed25519}
  mail=${2:-user@example.com}
  ssh-keygen -t ed25519 -f $fpath -C $mail &&
  echo "Generated ed25519 SSH key, saved to $fpath"
}'  # Generate ed25519 SSH key

alias nkey_rsa='() {
  if [ $# -lt 2 ]; then
    echo "Generate RSA SSH key.\nUsage:\n nkey_rsa <key_path> <email>"
    return 1
  fi
  fpath=${1:-id_rsa}
  mail=${2:-user@example.com}
  ssh-keygen -t rsa -b 4096 -f $fpath -C $mail &&
  echo "Generated RSA SSH key, saved to $fpath"
}'  # Generate 4096-bit RSA SSH key

alias nkey_ecdsa='() {
  if [ $# -lt 2 ]; then
    echo "Generate ECDSA SSH key.\nUsage:\n nkey_ecdsa <key_path> <email>"
    return 1
  fi
  fpath=${1:-id_ecdsa}
  mail=${2:-user@example.com}
  ssh-keygen -t ecdsa -b 521 -f $fpath -C $mail &&
  echo "Generated ECDSA SSH key, saved to $fpath"
}'  # Generate ECDSA SSH key

alias nkey_dsa='() {
  if [ $# -lt 2 ]; then
    echo "Generate DSA SSH key.\nUsage:\n nkey_dsa <key_path> <email>"
    return 1
  fi
  fpath=${1:-id_dsa}
  mail=${2:-user@example.com}
  ssh-keygen -t dsa -f $fpath -C $mail &&
  echo "Generated DSA SSH key, saved to $fpath"
}'  # Generate DSA SSH key

# Server utilities
alias httpserver='() {
  port=${1:-3080}
  echo "Starting HTTP server on port $port"
  python -m http.server $port
}'  # Start a simple HTTP server on specified port

alias sserve='() {
  port=${1:-8080}
  echo "Starting serve HTTP server on port $port"
  serve -port $port
}'  # Start serve HTTP server on specified port

# General utilities
alias cls='clear'  # Clear screen
alias clch='() {
  echo "Clearing command history"
  history -c
  history -w
  history -r
  echo "Command history cleared"
}'  # Clear command history

# File synchronization
alias rsync="rsync -avzP"  # Use rsync with archive, verbose, compress and progress options
alias rsync_d="rsync -avzP --delete"  # rsync with delete option for exact mirror
# rsync remote server to local
alias rsync_r2l='(){
  if [ $# -lt 3 ]; then
    echo "Rsync from remote server to local or vice versa.\nUsage:\n rsync_r2l <port> <source> <destination>\nExample: rsync_r2l 2001 user@server1:/mnt/ /data\nExample: rsync_r2l 2001 /mnt/ user@server1:/data"
    return 1
  else
    echo "Syncing from $2 to $3 via port $1"
    rsync -av -e "ssh -p $1" $2 $3
  fi
}'  # Rsync with SSH port specification


# Virtual environment utility
alias venv_start='() {
  env_dir="${1:-venv}"
  if [ -d "$env_dir" ]; then
    echo "Activating virtual environment: $env_dir"
    source "$env_dir/bin/activate"
  else
    echo "Creating virtual environment: $env_dir"
    python3 -m venv "$env_dir"
    source "$env_dir/bin/activate"
  fi
}'  # Create and activate a virtual environment

alias venv_deactivate='() {
  if [ -z "$VIRTUAL_ENV" ]; then
    echo "No virtual environment is currently activated."
  else
    echo "Deactivating virtual environment: $VIRTUAL_ENV"
    deactivate
  fi
}'  # Deactivate the current virtual environment

alias venv_remove='() {
  env_dir="${1:-venv}"
  if [ -d "$env_dir" ]; then
    echo "Removing virtual environment: $env_dir"
    rm -rf "$env_dir"
  else
    echo "Virtual environment not found: $env_dir"
  fi
}'  # Remove a virtual environment

alias venv_list='() {
  if [ -z "$VIRTUAL_ENV" ]; then
    echo "No virtual environment is currently activated."
  else
    echo "Virtual environment: $VIRTUAL_ENV"
  fi
}'  # List the current virtual environment
