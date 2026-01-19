# Description: SCP related aliases for secure file transfer operations in daily usage and system administration.

# Helper functions
# ---------------

# Helper function to check if scp is installed
_scp_check_installed() {
  if ! command -v scp >/dev/null 2>&1; then
    echo >&2 "Error: scp is not installed. Please install OpenSSH client first."
    return 1
  fi
  return 0
}

# Helper function to display error message
_scp_error() {
  echo >&2 "Error: $1"
  return 1
}

# Helper function to validate host format
_scp_validate_host() {
  local host_str="$1"

  # Check if host string is empty
  if [ -z "$host_str" ]; then
    return 1
  fi

  # Basic validation for host format (user@host or host)
  if ! echo "$host_str" | grep -q -E '^([a-zA-Z0-9_.-]+@)?[a-zA-Z0-9_.-]+$'; then
    return 1
  fi

  return 0
}

# Helper function to find the best available SSH key for a host
_scp_find_best_key() {
  local remote_host="$1"
  local username=""
  local hostname=""

  # Extract username and hostname
  if echo "$remote_host" | grep -q '@'; then
    username=$(echo "$remote_host" | cut -d '@' -f 1)
    hostname=$(echo "$remote_host" | cut -d '@' -f 2)
  else
    hostname="$remote_host"
  fi

  # Check if we have a key specifically for this host in SSH config
  if [ -f "$HOME/.ssh/config" ] && grep -q "Host $hostname" "$HOME/.ssh/config"; then
    local identity_file=$(grep -A 10 "Host $hostname" "$HOME/.ssh/config" | grep "IdentityFile" | head -n 1 | awk '{print $2}')
    if [ -n "$identity_file" ] && [ -f "$identity_file" ]; then
      echo "$identity_file"
      return 0
    fi
  fi

  # Check for common key files
  local key_files=("$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_rsa" "$HOME/.ssh/id_ecdsa" "$HOME/.ssh/id_dsa")

  for key_file in "${key_files[@]}"; do
    if [ -f "$key_file" ]; then
      echo "$key_file"
      return 0
    fi
  done

  # No suitable key found
  return 1
}

# Basic File Transfer Commands
# --------------------------

alias scp-to='() {
  echo "Copy local file to remote host."
  echo "Usage: scp-to <local_file_path> <remote_host> [remote_directory:~] [port:22]"
  echo "Example: scp-to ~/document.txt user@server.com /home/user/docs 2222"

  # Check if scp is installed
  _scp_check_installed || return 1

  # Verify parameters
  if [ $# -lt 2 ]; then
    _scp_error "Insufficient parameters. Please provide local file path and remote host."
    return 1
  fi

  local local_file="$1"
  local remote_host="$2"
  local remote_dir="${3:-~}"
  local port="${4:-22}"

  # Check if local file exists
  if [ ! -f "$local_file" ]; then
    _scp_error "Local file does not exist: $local_file"
    return 1
  fi

  # Validate remote host format
  if ! _scp_validate_host "$remote_host"; then
    _scp_error "Invalid remote host format: $remote_host"
    return 1
  fi

  # Validate port number
  if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    _scp_error "Invalid port number: $port"
    return 1
  fi

  echo "Copying $local_file to $remote_host:$remote_dir (Port: $port)..."
  scp -P "$port" "$local_file" "$remote_host:$remote_dir"

  if [ $? -eq 0 ]; then
    echo "File transferred successfully."
  else
    _scp_error "Failed to transfer file."
    return 1
  fi
}' # Copy local file to remote host

alias scp-from='() {
  echo "Copy remote file to local directory."
  echo "Usage: scp-from <remote_host> <remote_file_path> [local_directory:.] [port:22]"
  echo "Example: scp-from user@server.com /home/user/document.txt ~/downloads 2222"

  # Check if scp is installed
  _scp_check_installed || return 1

  # Verify parameters
  if [ $# -lt 2 ]; then
    _scp_error "Insufficient parameters. Please provide remote host and remote file path."
    return 1
  fi

  local remote_host="$1"
  local remote_file="$2"
  local local_dir="${3:-.}"
  local port="${4:-22}"

  # Check if local directory exists
  if [ ! -d "$local_dir" ]; then
    _scp_error "Local directory does not exist: $local_dir"
    return 1
  fi

  # Validate remote host format
  if ! _scp_validate_host "$remote_host"; then
    _scp_error "Invalid remote host format: $remote_host"
    return 1
  fi

  # Validate port number
  if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    _scp_error "Invalid port number: $port"
    return 1
  fi

  echo "Copying $remote_host:$remote_file to $local_dir (Port: $port)..."
  scp -P "$port" "$remote_host:$remote_file" "$local_dir"

  if [ $? -eq 0 ]; then
    echo "File transferred successfully."
  else
    _scp_error "Failed to transfer file."
    return 1
  fi
}' # Copy remote file to local directory

# Directory Transfer Commands
# -------------------------

alias scp-dir-to='() {
  echo "Copy local directory to remote host recursively."
  echo "Usage: scp-dir-to <local_directory> <remote_host> [remote_directory:~] [port:22]"
  echo "Example: scp-dir-to ~/documents user@server.com /home/user/backup 2222"

  # Check if scp is installed
  _scp_check_installed || return 1

  # Verify parameters
  if [ $# -lt 2 ]; then
    _scp_error "Insufficient parameters. Please provide local directory and remote host."
    return 1
  fi

  local local_dir="$1"
  local remote_host="$2"
  local remote_dir="${3:-~}"
  local port="${4:-22}"

  # Check if local directory exists
  if [ ! -d "$local_dir" ]; then
    _scp_error "Local directory does not exist: $local_dir"
    return 1
  fi

  # Validate remote host format
  if ! _scp_validate_host "$remote_host"; then
    _scp_error "Invalid remote host format: $remote_host"
    return 1
  fi

  # Validate port number
  if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    _scp_error "Invalid port number: $port"
    return 1
  fi

  echo "Copying directory $local_dir to $remote_host:$remote_dir (Port: $port)..."
  scp -P "$port" -r "$local_dir" "$remote_host:$remote_dir"

  if [ $? -eq 0 ]; then
    echo "Directory transferred successfully."
  else
    _scp_error "Failed to transfer directory."
    return 1
  fi
}' # Copy local directory to remote host recursively

alias scp-dir-from='() {
  echo "Copy remote directory to local directory recursively."
  echo "Usage: scp-dir-from <remote_host> <remote_directory> [local_directory:.] [port:22]"
  echo "Example: scp-dir-from user@server.com /home/user/documents ~/downloads 2222"

  # Check if scp is installed
  _scp_check_installed || return 1

  # Verify parameters
  if [ $# -lt 2 ]; then
    _scp_error "Insufficient parameters. Please provide remote host and remote directory."
    return 1
  fi

  local remote_host="$1"
  local remote_dir="$2"
  local local_dir="${3:-.}"
  local port="${4:-22}"

  # Check if local directory exists
  if [ ! -d "$local_dir" ]; then
    _scp_error "Local directory does not exist: $local_dir"
    return 1
  fi

  # Validate remote host format
  if ! _scp_validate_host "$remote_host"; then
    _scp_error "Invalid remote host format: $remote_host"
    return 1
  fi

  # Validate port number
  if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    _scp_error "Invalid port number: $port"
    return 1
  fi

  echo "Copying directory $remote_host:$remote_dir to $local_dir (Port: $port)..."
  scp -P "$port" -r "$remote_host:$remote_dir" "$local_dir"

  if [ $? -eq 0 ]; then
    echo "Directory transferred successfully."
  else
    _scp_error "Failed to transfer directory."
    return 1
  fi
}' # Copy remote directory to local directory recursively

# Advanced Transfer Commands
# ------------------------

alias scp-compress-to='() {
  echo "Copy local file to remote host with compression."
  echo "Usage: scp-compress-to <local_file_path> <remote_host> [remote_directory:~] [port:22]"
  echo "Example: scp-compress-to ~/large_file.txt user@server.com /home/user/docs 2222"

  # Check if scp is installed
  _scp_check_installed || return 1

  # Verify parameters
  if [ $# -lt 2 ]; then
    _scp_error "Insufficient parameters. Please provide local file path and remote host."
    return 1
  fi

  local local_file="$1"
  local remote_host="$2"
  local remote_dir="${3:-~}"
  local port="${4:-22}"

  # Check if local file exists
  if [ ! -f "$local_file" ]; then
    _scp_error "Local file does not exist: $local_file"
    return 1
  fi

  # Validate remote host format
  if ! _scp_validate_host "$remote_host"; then
    _scp_error "Invalid remote host format: $remote_host"
    return 1
  fi

  # Validate port number
  if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    _scp_error "Invalid port number: $port"
    return 1
  fi

  echo "Copying $local_file to $remote_host:$remote_dir with compression (Port: $port)..."
  scp -P "$port" -C "$local_file" "$remote_host:$remote_dir"

  if [ $? -eq 0 ]; then
    echo "File transferred successfully with compression."
  else
    _scp_error "Failed to transfer file."
    return 1
  fi
}' # Copy local file to remote host with compression

alias scp-compress-dir-to='() {
  echo "Copy local directory to remote host recursively with compression."
  echo "Usage: scp-compress-dir-to <local_directory> <remote_host> [remote_directory:~] [port:22]"
  echo "Example: scp-compress-dir-to ~/documents user@server.com /home/user/backup 2222"

  # Check if scp is installed
  _scp_check_installed || return 1

  # Verify parameters
  if [ $# -lt 2 ]; then
    _scp_error "Insufficient parameters. Please provide local directory and remote host."
    return 1
  fi

  local local_dir="$1"
  local remote_host="$2"
  local remote_dir="${3:-~}"
  local port="${4:-22}"

  # Check if local directory exists
  if [ ! -d "$local_dir" ]; then
    _scp_error "Local directory does not exist: $local_dir"
    return 1
  fi

  # Validate remote host format
  if ! _scp_validate_host "$remote_host"; then
    _scp_error "Invalid remote host format: $remote_host"
    return 1
  fi

  # Validate port number
  if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    _scp_error "Invalid port number: $port"
    return 1
  fi

  echo "Copying directory $local_dir to $remote_host:$remote_dir with compression (Port: $port)..."
  scp -P "$port" -C -r "$local_dir" "$remote_host:$remote_dir"

  if [ $? -eq 0 ]; then
    echo "Directory transferred successfully with compression."
  else
    _scp_error "Failed to transfer directory."
    return 1
  fi
}' # Copy local directory to remote host recursively with compression

alias scp-limit-speed-to='() {
  echo "Copy local file to remote host with bandwidth limit."
  echo "Usage: scp-limit-speed-to <local_file_path> <remote_host> <limit_kbps> [remote_directory:~] [port:22]"
  echo "Example: scp-limit-speed-to ~/large_file.txt user@server.com 1000 /home/user/docs 2222"

  # Check if scp is installed
  _scp_check_installed || return 1

  # Verify parameters
  if [ $# -lt 3 ]; then
    _scp_error "Insufficient parameters. Please provide local file path, remote host, and bandwidth limit."
    return 1
  fi

  local local_file="$1"
  local remote_host="$2"
  local limit_kbps="$3"
  local remote_dir="${4:-~}"
  local port="${5:-22}"

  # Check if local file exists
  if [ ! -f "$local_file" ]; then
    _scp_error "Local file does not exist: $local_file"
    return 1
  fi

  # Validate remote host format
  if ! _scp_validate_host "$remote_host"; then
    _scp_error "Invalid remote host format: $remote_host"
    return 1
  fi

  # Validate bandwidth limit
  if ! [[ "$limit_kbps" =~ ^[0-9]+$ ]] || [ "$limit_kbps" -lt 1 ]; then
    _scp_error "Invalid bandwidth limit: $limit_kbps"
    return 1
  fi

  # Validate port number
  if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    _scp_error "Invalid port number: $port"
    return 1
  fi

  echo "Copying $local_file to $remote_host:$remote_dir with bandwidth limit ${limit_kbps}KB/s (Port: $port)..."
  scp -P "$port" -l "$limit_kbps" "$local_file" "$remote_host:$remote_dir"

  if [ $? -eq 0 ]; then
    echo "File transferred successfully with bandwidth limit."
  else
    _scp_error "Failed to transfer file."
    return 1
  fi
}' # Copy local file to remote host with bandwidth limit

# Batch Transfer Commands
# ---------------------

alias scp-batch-to='() {
  echo "Copy multiple local files to remote host."
  echo "Usage: scp-batch-to <remote_host> <remote_directory> <file_pattern> [port:22]"
  echo "Example: scp-batch-to user@server.com /home/user/docs \"*.txt\" 2222"

  # Check if scp is installed
  _scp_check_installed || return 1

  # Verify parameters
  if [ $# -lt 3 ]; then
    _scp_error "Insufficient parameters. Please provide remote host, remote directory, and file pattern."
    return 1
  fi

  local remote_host="$1"
  local remote_dir="$2"
  local file_pattern="$3"
  local port="${4:-22}"

  # Validate remote host format
  if ! _scp_validate_host "$remote_host"; then
    _scp_error "Invalid remote host format: $remote_host"
    return 1
  fi

  # Validate port number
  if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    _scp_error "Invalid port number: $port"
    return 1
  fi

  # Check if any files match the pattern
  local files=($(ls $file_pattern 2>/dev/null))
  if [ ${#files[@]} -eq 0 ]; then
    _scp_error "No files match the pattern: $file_pattern"
    return 1
  fi

  echo "Copying ${#files[@]} files matching '$file_pattern' to $remote_host:$remote_dir (Port: $port)..."
  scp -P "$port" $file_pattern "$remote_host:$remote_dir"

  if [ $? -eq 0 ]; then
    echo "Files transferred successfully."
  else
    _scp_error "Failed to transfer files."
    return 1
  fi
}' # Copy multiple local files to remote host

alias scp-multi-host-to='() {
  echo "Copy local file to multiple remote hosts."
  echo "Usage: scp-multi-host-to <local_file_path> <hosts_file> [remote_directory:~] [port:22]"
  echo "Example: scp-multi-host-to ~/config.txt ~/hosts.txt /etc/app 2222"
  echo "Note: hosts.txt should contain one host per line in format [user@]host"

  # Check if scp is installed
  _scp_check_installed || return 1

  # Verify parameters
  if [ $# -lt 2 ]; then
    _scp_error "Insufficient parameters. Please provide local file path and hosts file."
    return 1
  fi

  local local_file="$1"
  local hosts_file="$2"
  local remote_dir="${3:-~}"
  local port="${4:-22}"

  # Check if local file exists
  if [ ! -f "$local_file" ]; then
    _scp_error "Local file does not exist: $local_file"
    return 1
  fi

  # Check if hosts file exists
  if [ ! -f "$hosts_file" ]; then
    _scp_error "Hosts file does not exist: $hosts_file"
    return 1
  fi

  # Validate port number
  if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    _scp_error "Invalid port number: $port"
    return 1
  fi

  # Read hosts from file
  local hosts=($(cat "$hosts_file"))
  if [ ${#hosts[@]} -eq 0 ]; then
    _scp_error "No hosts found in hosts file: $hosts_file"
    return 1
  fi

  local success_count=0
  local failed_hosts=()

  echo "Copying $local_file to ${#hosts[@]} hosts (Port: $port)..."
  for host in "${hosts[@]}"; do
    # Validate host format
    if ! _scp_validate_host "$host"; then
      echo "Skipping invalid host format: $host"
      failed_hosts+=("$host")
      continue
    fi

    echo "Copying to $host:$remote_dir..."
    scp -P "$port" "$local_file" "$host:$remote_dir"

    if [ $? -eq 0 ]; then
      ((success_count++))
    else
      failed_hosts+=("$host")
    fi
  done

  echo "Transfer completed: $success_count successful, ${#failed_hosts[@]} failed."
  if [ ${#failed_hosts[@]} -gt 0 ]; then
    echo "Failed hosts:"
    printf "  %s\n" "${failed_hosts[@]}"
    return 1
  fi
  return 0
}' # Copy local file to multiple remote hosts

# Secure Transfer Commands
# ----------------------

alias scp-identity='() {
  echo "Copy file using identity file (private key)."
  echo "Usage: scp-identity [identity_file:~/.ssh/id_rsa] <local_file_path> <remote_host> [remote_directory:~] [port:22]"
  echo "Example: scp-identity ~/.ssh/id_rsa ~/document.txt user@server.com /home/user/docs 2222"
  echo "Example: scp-identity ~/document.txt user@server.com  # Uses default identity file"

  # Check if scp is installed
  _scp_check_installed || return 1

  # Parse parameters based on count
  local identity_file=""
  local local_file=""
  local remote_host=""
  local remote_dir=""
  local port="22"

  if [ $# -eq 2 ]; then
    # Use default identity file
    identity_file="$HOME/.ssh/id_rsa"
    local_file="$1"
    remote_host="$2"
    remote_dir="~"
  elif [ $# -ge 3 ]; then
    # Check if first parameter is an identity file or local file
    if [[ "$1" == *".pub" || "$1" == *"id_"* || "$1" == *".pem" || "$1" == *".key" ]]; then
      # First parameter is likely an identity file
      identity_file="$1"
      local_file="$2"
      remote_host="$3"
      remote_dir="${4:-~}"
      port="${5:-22}"
    else
      # First parameter is likely a local file, use default identity
      identity_file="$HOME/.ssh/id_rsa"
      local_file="$1"
      remote_host="$2"
      remote_dir="${3:-~}"
      port="${4:-22}"
    fi
  else
    _scp_error "Insufficient parameters. Please provide at least local file path and remote host."
    return 1
  fi

  # Check if identity file exists
  if [ ! -f "$identity_file" ]; then
    _scp_error "Identity file does not exist: $identity_file"
    return 1
  fi

  # Check if local file exists
  if [ ! -f "$local_file" ]; then
    _scp_error "Local file does not exist: $local_file"
    return 1
  fi

  # Validate remote host format
  if ! _scp_validate_host "$remote_host"; then
    _scp_error "Invalid remote host format: $remote_host"
    return 1
  fi

  # Validate port number
  if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    _scp_error "Invalid port number: $port"
    return 1
  fi

  echo "Copying $local_file to $remote_host:$remote_dir using identity file $identity_file (Port: $port)..."
  scp -P "$port" -i "$identity_file" "$local_file" "$remote_host:$remote_dir"

  if [ $? -eq 0 ]; then
    echo "File transferred successfully using identity file."
  else
    _scp_error "Failed to transfer file."
    return 1
  fi
}' # Copy file using identity file (private key)

alias scp-quiet='() {
  echo "Copy file in quiet mode (no progress display)."
  echo "Usage: scp-quiet <local_file_path> <remote_host> [remote_directory:~] [port:22]"
  echo "Example: scp-quiet ~/document.txt user@server.com /home/user/docs 2222"

  # Check if scp is installed
  _scp_check_installed || return 1

  # Verify parameters
  if [ $# -lt 2 ]; then
    _scp_error "Insufficient parameters. Please provide local file path and remote host."
    return 1
  fi

  local local_file="$1"
  local remote_host="$2"
  local remote_dir="${3:-~}"
  local port="${4:-22}"

  # Check if local file exists
  if [ ! -f "$local_file" ]; then
    _scp_error "Local file does not exist: $local_file"
    return 1
  fi

  # Validate remote host format
  if ! _scp_validate_host "$remote_host"; then
    _scp_error "Invalid remote host format: $remote_host"
    return 1
  fi

  # Validate port number
  if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    _scp_error "Invalid port number: $port"
    return 1
  fi

  echo "Copying $local_file to $remote_host:$remote_dir in quiet mode (Port: $port)..."
  scp -P "$port" -q "$local_file" "$remote_host:$remote_dir"

  if [ $? -eq 0 ]; then
    echo "File transferred successfully."
  else
    _scp_error "Failed to transfer file."
    return 1
  fi
}' # Copy file in quiet mode (no progress display)

alias scp-password='() {
  echo "Copy file using password authentication (will prompt for password)."
  echo "Usage: scp-password <local_file_path> <remote_host> [remote_directory:~] [port:22]"
  echo "Example: scp-password ~/document.txt user@server.com /home/user/docs 2222"

  # Check if scp is installed
  _scp_check_installed || return 1

  # Verify parameters
  if [ $# -lt 2 ]; then
    _scp_error "Insufficient parameters. Please provide local file path and remote host."
    return 1
  fi

  local local_file="$1"
  local remote_host="$2"
  local remote_dir="${3:-~}"
  local port="${4:-22}"

  # Check if local file exists
  if [ ! -f "$local_file" ]; then
    _scp_error "Local file does not exist: $local_file"
    return 1
  fi

  # Validate remote host format
  if ! _scp_validate_host "$remote_host"; then
    _scp_error "Invalid remote host format: $remote_host"
    return 1
  fi

  # Validate port number
  if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    _scp_error "Invalid port number: $port"
    return 1
  fi

  echo "Copying $local_file to $remote_host:$remote_dir using password authentication (Port: $port)..."
  # Force password authentication by disabling public key authentication
  scp -P "$port" -o "PubkeyAuthentication=no" "$local_file" "$remote_host:$remote_dir"

  if [ $? -eq 0 ]; then
    echo "File transferred successfully using password authentication."
  else
    _scp_error "Failed to transfer file."
    return 1
  fi
}' # Copy file using password authentication

alias scp-key='() {
  echo "Copy file or directory using automatic SSH key detection."
  echo "Usage: scp-key <source_path> <destination> [port:22]"
  echo "Examples:"
  echo "  scp-key ~/document.txt user@server.com:/home/user/docs  # Local to remote"
  echo "  scp-key user@server.com:/home/user/document.txt ~/downloads  # Remote to local"
  echo "  scp-key -r ~/documents user@server.com:~/backup  # Directory with recursive flag"

  # Check if scp is installed
  _scp_check_installed || return 1

  # Verify parameters
  if [ $# -lt 2 ]; then
    _scp_error "Insufficient parameters. Please provide source path and destination."
    return 1
  fi

  local recursive_flag=""
  local source_path=""
  local destination=""
  local port="22"

  # Parse parameters
  if [ "$1" = "-r" ]; then
    recursive_flag="-r"
    source_path="$2"
    destination="$3"
    port="${4:-22}"

    if [ $# -lt 3 ]; then
      _scp_error "Insufficient parameters for recursive transfer. Please provide source directory and destination."
      return 1
    fi
  else
    source_path="$1"
    destination="$2"
    port="${3:-22}"
  fi

  # Validate port number
  if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    _scp_error "Invalid port number: $port"
    return 1
  fi

  # Determine if this is a local-to-remote or remote-to-local transfer
  local is_upload=false
  local remote_host=""
  local remote_path=""
  local local_path=""

  if echo "$destination" | grep -q ':'; then
    # Local to remote transfer
    is_upload=true
    remote_host=$(echo "$destination" | cut -d ':' -f 1)
    remote_path=$(echo "$destination" | cut -d ':' -f 2)
    local_path="$source_path"

    # Check if local path exists
    if [ -z "$recursive_flag" ] && [ ! -f "$local_path" ]; then
      _scp_error "Local file does not exist: $local_path"
      return 1
    elif [ -n "$recursive_flag" ] && [ ! -d "$local_path" ]; then
      _scp_error "Local directory does not exist: $local_path"
      return 1
    fi
  elif echo "$source_path" | grep -q ':'; then
    # Remote to local transfer
    is_upload=false
    remote_host=$(echo "$source_path" | cut -d ':' -f 1)
    remote_path=$(echo "$source_path" | cut -d ':' -f 2)
    local_path="$destination"

    # Check if local directory exists for download
    if [ -n "$recursive_flag" ]; then
      if [ ! -d "$local_path" ]; then
        _scp_error "Local directory does not exist: $local_path"
        return 1
      fi
    elif [ -d "$local_path" ]; then
      # It's fine if it's a directory
      :  # No-op
    elif [ -e "$local_path" ] && [ ! -d "$local_path" ]; then
      _scp_error "Local path exists but is not a directory: $local_path"
      return 1
    fi
  else
    _scp_error "Invalid source or destination format. One must be a remote path (user@host:path)."
    return 1
  fi

  # Validate remote host format
  if ! _scp_validate_host "$remote_host"; then
    _scp_error "Invalid remote host format: $remote_host"
    return 1
  fi

  # Find the best SSH key for this host
  local identity_file=$(_scp_find_best_key "$remote_host")
  local identity_option=""

  if [ $? -eq 0 ] && [ -n "$identity_file" ]; then
    identity_option="-i \"$identity_file\""
    echo "Using SSH key: $identity_file"
  else
    echo "No suitable SSH key found. Will use default authentication method."
  fi

  # Prepare the SCP command
  local scp_cmd=""
  if [ "$is_upload" = true ]; then
    echo "Copying $source_path to $remote_host:$remote_path (Port: $port)..."
    if [ -n "$identity_file" ]; then
      scp -P "$port" -i "$identity_file" $recursive_flag "$source_path" "$remote_host:$remote_path"
    else
      scp -P "$port" $recursive_flag "$source_path" "$remote_host:$remote_path"
    fi
  else
    echo "Copying $remote_host:$remote_path to $local_path (Port: $port)..."
    if [ -n "$identity_file" ]; then
      scp -P "$port" -i "$identity_file" $recursive_flag "$remote_host:$remote_path" "$local_path"
    else
      scp -P "$port" $recursive_flag "$remote_host:$remote_path" "$local_path"
    fi
  fi

  if [ $? -eq 0 ]; then
    echo "Transfer completed successfully."
  else
    _scp_error "Failed to transfer. Please check your SSH keys and connection details."
    return 1
  fi
}' # Copy file or directory using automatic SSH key detection

# Utility Commands
# --------------

alias scp-help='() {
  echo "SCP aliases help guide"
  echo "--------------------"
  echo ""
  echo "Basic File Transfer Commands:"
  echo "  scp-to              - Copy local file to remote host"
  echo "  scp-from            - Copy remote file to local directory"
  echo ""
  echo "Directory Transfer Commands:"
  echo "  scp-dir-to          - Copy local directory to remote host recursively"
  echo "  scp-dir-from        - Copy remote directory to local directory recursively"
  echo ""
  echo "Advanced Transfer Commands:"
  echo "  scp-compress-to     - Copy local file to remote host with compression"
  echo "  scp-compress-dir-to - Copy local directory to remote host with compression"
  echo "  scp-limit-speed-to  - Copy local file to remote host with bandwidth limit"
  echo ""
  echo "Batch Transfer Commands:"
  echo "  scp-batch-to        - Copy multiple local files to remote host"
  echo "  scp-multi-host-to   - Copy local file to multiple remote hosts"
  echo ""
  echo "Secure Transfer Commands:"
  echo "  scp-key             - Copy file or directory with automatic SSH key detection"
  echo "  scp-identity        - Copy file using identity file (private key)"
  echo "  scp-quiet           - Copy file in quiet mode (no progress display)"
  echo "  scp-password        - Copy file using password authentication"
  echo ""
  echo "For more detailed help on each command, run the command without parameters."
}' # Display help information for all SCP aliases