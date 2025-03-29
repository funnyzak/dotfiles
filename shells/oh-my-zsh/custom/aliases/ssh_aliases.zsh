# Description: SSH-related aliases for easier management and usage.

# Helper functions
_show_error_ssh_aliases() {
  echo "Error: $1" >&2
}

_show_usage_ssh_aliases() {
  echo "$1" >&2
}

# Helper function to check SSH key permissions
_check_key_permissions_ssh_aliases() {
  local key_file="$1"

  if [[ ! -f "$key_file" ]]; then
    return 0
  fi

  local current_perms=$(stat -f "%Lp" "$key_file" 2>/dev/null || stat -c "%a" "$key_file" 2>/dev/null)

  if [[ -z "$current_perms" ]]; then
    _show_error_ssh_aliases "Could not determine file permissions for $key_file."
    return 1
  fi

  # Check if permissions are too open (should be 600 or more restrictive)
  if [[ "$current_perms" != "600" && "$current_perms" -gt "600" ]]; then
    return 1
  fi

  return 0
}

# SSH key generation helper function with enhanced security
_generate_ssh_key_ssh_aliases() {
  local key_type="$1"
  local key_path="$2"
  local email="$3"
  local bits="$4"
  local description="$5"

  if [[ -z "$key_path" || -z "$email" ]]; then
    _show_error_ssh_aliases "Missing required parameters for key generation."
    return 1
  fi

  # Check if key already exists and confirm overwrite
  if [[ -f "$key_path" ]]; then
    echo "Warning: SSH key already exists at $key_path"
    echo -n "Do you want to overwrite it? [y/N]: "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
      echo "Key generation cancelled."
      return 0
    fi
  fi

  echo "Generating $description SSH key: $(basename "$key_path")..."

  # Create command with proper parameters
  local cmd="ssh-keygen -t $key_type"
  if [[ -n "$bits" ]]; then
    cmd="$cmd -b $bits"
  fi
  eval "$cmd -f $key_path -C \"$email\" -N \"\""
  local gen_status=$?

  if [[ $gen_status -ne 0 ]]; then
    _show_error_ssh_aliases "Failed to generate SSH key. Please check your parameters and try again."
    return 1
  fi

  # Set proper permissions
  chmod 600 "$key_path"
  chmod 644 "$key_path.pub"

  echo "SSH key generated successfully at $key_path"
  echo "Public key:"
  cat "$key_path.pub"

  # Provide helpful next steps
  echo "\nNext steps:"
  echo "1. Add this key to your SSH agent: ssh-add $key_path"
  echo "2. Copy the public key to remote servers: ssh-key-copy <hostname> $key_path.pub"

  return 0
}

# SSH Key Management

# Generate a new SSH key with enhanced security
alias ssh-key-generate='() {
  echo -e "Generate a new SSH key with enhanced security.\nUsage:\n  ssh-key-generate <key_name> <email> [key_type:ed25519] [bits]\nExample:\n  ssh-key-generate github \"user@example.com\"\n  ssh-key-generate gitlab \"user@example.com\" rsa 4096\nKey types: ed25519 (default), rsa, ecdsa, dsa\nDefault bits: ed25519 (none), rsa (4096), ecdsa (521), dsa (none)"

  local key_name="$1"
  local email="$2"
  local key_type="$3"
  local bits="$4"

  if [[ -z "$key_name" ]]; then
    _show_error_ssh_aliases "Missing required parameter: key_name."
    return 1
  fi

  if [[ -z "$email" ]]; then
    _show_error_ssh_aliases "Missing required parameter: email."
    return 1
  fi

  # Validate email format (basic check)
  if ! echo "$email" | grep -q -E "^[^@]+@[^@]+\.[^@]+$"; then
    _show_error_ssh_aliases "Invalid email format: $email"
    return 1
  fi

  # Set defaults
  key_type="${key_type:-ed25519}"
  local description=""

  case "$key_type" in
    rsa)
      bits="${bits:-4096}"
      description="RSA"
      ;;
    ecdsa)
      bits="${bits:-521}"
      description="ECDSA"
      ;;
    dsa)
      description="DSA"
      echo "Warning: DSA keys are considered less secure and may not be supported by all servers." >&2
      ;;
    ed25519)
      description="Ed25519"
      ;;
    *)
      _show_error_ssh_aliases "Invalid key type: $key_type. Valid types are: ed25519, rsa, ecdsa, dsa."
      return 1
      ;;
  esac

  # Validate bits if provided
  if [[ -n "$bits" ]]; then
    if ! [[ "$bits" =~ ^[0-9]+$ ]]; then
      _show_error_ssh_aliases "Bits must be a positive integer, got: $bits"
      return 1
    fi
  fi

  _generate_ssh_key_ssh_aliases "$key_type" "$HOME/.ssh/$key_name" "$email" "$bits" "$description"
  return $?
}' # Generate secure SSH key

# Start the SSH agent and load keys
alias ssh-agent-start='() {
  echo -e "Start SSH agent and load default or specified keys.\nUsage:\n  ssh-agent-start [key_path]\nIf no key_path is provided, will try to load id_ed25519 or id_rsa by default."

  local key_path="$1"
  local agent_started=false

  # Check if agent is already running
  if [[ -n "$SSH_AGENT_PID" ]]; then
    if ps -p "$SSH_AGENT_PID" > /dev/null; then
      echo "SSH agent is already running with PID $SSH_AGENT_PID"
      agent_started=true
    fi
  fi

  # Start agent if not running
  if [[ "$agent_started" == "false" ]]; then
    echo "Starting SSH agent..."
    eval "$(ssh-agent -s)"

    if [[ $? -ne 0 ]]; then
      _show_error_ssh_aliases "Failed to start SSH agent."
      return 1
    fi

    echo "SSH agent started successfully with PID $SSH_AGENT_PID"
  fi

  # Load specified key or default keys
  if [[ -n "$key_path" ]]; then
    if [[ ! -f "$key_path" ]]; then
      _show_error_ssh_aliases "Specified key file does not exist: $key_path"
      return 1
    fi

    # Check key permissions
    if ! _check_key_permissions_ssh_aliases "$key_path"; then
      echo "Warning: Key file $key_path has incorrect permissions." >&2
      echo "Fixing permissions to 600..." >&2
      chmod 600 "$key_path"
    fi

    echo "Adding key: $key_path"
    ssh-add "$key_path"
    if [[ $? -ne 0 ]]; then
      _show_error_ssh_aliases "Failed to add key: $key_path"
      return 1
    fi
  else
    # Try to load default keys
    local key_added=false
    local default_keys=("$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_rsa" "$HOME/.ssh/id_ecdsa")

    for key in "${default_keys[@]}"; do
      if [[ -f "$key" ]]; then
        # Check key permissions
        if ! _check_key_permissions_ssh_aliases "$key"; then
          echo "Warning: Key file $key has incorrect permissions." >&2
          echo "Fixing permissions to 600..." >&2
          chmod 600 "$key"
        fi

        echo "Adding key: $key"
        ssh-add "$key"
        if [[ $? -eq 0 ]]; then
          key_added=true
        else
          echo "Warning: Failed to add key: $key" >&2
        fi
      fi
    done

    if [[ "$key_added" == "false" ]]; then
      echo "No default keys found or added. You may need to generate a key first."
      echo "Use ssh-key-generate to create a new SSH key."
    fi
  fi

  # Show loaded keys
  echo "\nCurrently loaded keys:"
  ssh-add -l
}' # Start SSH agent and load default or specified keys

# List all SSH keys in the ~/.ssh directory
alias ssh-key-list='() {
  echo -e "List all SSH keys in the ~/.ssh directory with details.\nUsage:\n  ssh-key-list [--check-permissions]\nOptions:\n  --check-permissions: Check and report SSH key file permissions"

  local check_permissions=false

  # Parse arguments
  if [[ "$1" == "--check-permissions" ]]; then
    check_permissions=true
  fi

  if [[ ! -d "$HOME/.ssh" ]]; then
    _show_error_ssh_aliases "SSH directory not found: $HOME/.ssh"
    return 1
  fi

  echo "Listing SSH keys in $HOME/.ssh/:"
  echo "------------------------------"

  local found_keys=false

  for key in "$HOME/.ssh/"*.pub; do
    if [[ -f "$key" ]]; then
      found_keys=true
      local private_key="${key%.pub}"
      local key_name=$(basename "$private_key")
      local key_type=$(head -n 1 "$key" | cut -d " " -f 1)
      local key_comment=$(head -n 1 "$key" | cut -d " " -f 3-)

      echo "Key: $key_name"
      echo "Type: $key_type"
      echo "Comment: $key_comment"

      if [[ "$check_permissions" == "true" ]]; then
        if [[ -f "$private_key" ]]; then
          local private_perms=$(stat -f "%Lp" "$private_key" 2>/dev/null || stat -c "%a" "$private_key" 2>/dev/null)
          echo -n "Private key permissions: $private_perms "

          if [[ "$private_perms" == "600" ]]; then
            echo "(✓ secure)"
          else
            echo "(✗ insecure - should be 600)"
          fi
        else
          echo "Private key not found"
        fi

        local public_perms=$(stat -f "%Lp" "$key" 2>/dev/null || stat -c "%a" "$key" 2>/dev/null)
        echo -n "Public key permissions: $public_perms "

        if [[ "$public_perms" == "644" ]]; then
          echo "(✓ recommended)"
        else
          echo "(should be 644)"
        fi
      fi

      echo "------------------------------"
    fi
  done

  if [[ "$found_keys" == "false" ]]; then
    echo "No SSH keys found. Use ssh-key-generate to create a new key."
  fi
}' # List all SSH keys with details

# SSH Config Management

# Edit SSH config file with default editor
alias ssh-config-edit='() {
  echo -e "Edit SSH config file with default or specified editor.\nUsage:\n  ssh-config-edit [editor_name:${EDITOR:-nano}]\nIf no editor is specified, uses the EDITOR environment variable or defaults to nano."

  local editor="${1:-${EDITOR:-nano}}"

  # Check if editor exists
  if ! command -v "$editor" &> /dev/null; then
    _show_error_ssh_aliases "Specified editor not found: $editor. Please install it or use another editor."
    return 1
  fi

  # Ensure SSH directory exists
  if [[ ! -d "$HOME/.ssh" ]]; then
    echo "Creating SSH directory..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    if [[ $? -ne 0 ]]; then
      _show_error_ssh_aliases "Failed to create SSH directory."
      return 1
    fi
  fi

  # Create config file if it doesn"t exist
  if [[ ! -f "$HOME/.ssh/config" ]]; then
    echo "SSH config file does not exist. Creating it..." >&2
    touch "$HOME/.ssh/config"

    if [[ $? -ne 0 ]]; then
      _show_error_ssh_aliases "Failed to create SSH config file."
      return 1
    fi

    # Add some helpful comments to the new config file
    cat > "$HOME/.ssh/config" << EOF
# SSH Config File
# See man ssh_config for more information

# Example host configuration:
# Host example-nickname
#   HostName example.com
#   User username
#   Port 22
#   IdentityFile ~/.ssh/id_ed25519

# Global options
Host *
  ServerAliveInterval 60
  ServerAliveCountMax 30
  AddKeysToAgent yes
  IdentitiesOnly yes

EOF

    chmod 600 "$HOME/.ssh/config"
  fi

  # Check config file permissions
  local config_perms=$(stat -f "%Lp" "$HOME/.ssh/config" 2>/dev/null || stat -c "%a" "$HOME/.ssh/config" 2>/dev/null)
  if [[ "$config_perms" != "600" ]]; then
    echo "Warning: SSH config file has incorrect permissions: $config_perms" >&2
    echo "Setting permissions to 600..." >&2
    chmod 600 "$HOME/.ssh/config"
  fi

  echo "Opening SSH config with $editor..."
  "$editor" "$HOME/.ssh/config"
}' # Edit SSH config file

# List all SSH hosts from config
alias ssh-hosts-list='() {
  echo -e "List all SSH hosts from config with optional details.\nUsage:\n  ssh-hosts-list [--details]\nOptions:\n  --details: Show additional details for each host"

  local show_details=false

  # Parse arguments
  if [[ "$1" == "--details" ]]; then
    show_details=true
  fi

  if [[ ! -f "$HOME/.ssh/config" ]]; then
    _show_error_ssh_aliases "SSH config file does not exist. Use ssh-config-edit to create one."
    return 1
  fi

  echo "SSH hosts defined in your config:"
  echo "------------------------------"

  if [[ "$show_details" == "true" ]]; then
    # More detailed output with host properties
    local current_host=""
    local in_host_block=false
    local host_details=""

    while IFS= read -r line; do
      # Trim leading/trailing whitespace
      line=$(echo "$line" | sed -e "s/^[[:space:]]*//" -e "s/[[:space:]]*$//")

      # Skip empty lines and comments
      if [[ -z "$line" || "$line" == \#* ]]; then
        continue
      fi

      if [[ "$line" == Host* ]]; then
        # Output previous host details if we were in a host block
        if [[ "$in_host_block" == "true" && "$current_host" != "*" ]]; then
          echo "$host_details"
          echo "------------------------------"
        fi

        # Start new host block
        current_host=$(echo "$line" | sed "s/Host //")

        # Skip wildcard hosts
        if [[ "$current_host" == "*" ]]; then
          in_host_block=false
          continue
        fi

        in_host_block=true
        host_details="Host: $current_host\n"
      elif [[ "$in_host_block" == "true" && "$current_host" != "*" ]]; then
        # Add property to current host details
        local property=$(echo "$line" | cut -d " " -f 1)
        local value=$(echo "$line" | cut -d " " -f 2-)
        host_details+="$property: $value\n"
      fi
    done < "$HOME/.ssh/config"

    # Output the last host block if there was one
    if [[ "$in_host_block" == "true" && "$current_host" != "*" ]]; then
      echo -e "$host_details"
      echo "------------------------------"
    fi
  else
    # Simple output, just host names
    grep "^Host " "$HOME/.ssh/config" | sed "s/Host //" | grep -v "\*" | while read -r host; do
      echo "$host"
    done
  fi
}' # List SSH hosts from config with details

# SSH Connection Testing and Maintenance

# Test SSH connection to a host
alias ssh-connection-test='() {
  echo -e "Test SSH connection to a host with detailed diagnostics.\nUsage:\n  ssh-connection-test <hostname> [port:22] [timeout:5]\nOptions:\n  hostname: The hostname or IP address to connect to\n  port: The SSH port number (default: 22)\n  timeout: Connection timeout in seconds (default: 5)"

  local host="$1"
  local port="${2:-22}"
  local timeout="${3:-5}"

  if [[ -z "$host" ]]; then
    _show_error_ssh_aliases "Missing required parameter: hostname."
    return 1
  fi

  # Validate port number
  if ! [[ "$port" =~ ^[0-9]+$ ]] || [[ "$port" -lt 1 ]] || [[ "$port" -gt 65535 ]]; then
    _show_error_ssh_aliases "Invalid port number: $port. Must be between 1 and 65535."
    return 1
  fi

  # Validate timeout
  if ! [[ "$timeout" =~ ^[0-9]+$ ]] || [[ "$timeout" -lt 1 ]]; then
    _show_error_ssh_aliases "Invalid timeout: $timeout. Must be a positive integer."
    return 1
  fi
  echo "Testing SSH connection to $host on port $port with timeout $timeout seconds..."
  ssh -o ConnectTimeout="$timeout" -p "$port" "$host" exit
  local connection_status=$?
  if [[ $connection_status -eq 0 ]]; then
    echo "Connection successful!"
  else
    _show_error_ssh_aliases "Connection failed (exit code: $connection_status)."
    return 1
  fi
}' # Test SSH connection to a host with diagnostics

# Copy SSH public key to remote host
alias ssh-key-copy='() {
  echo -e "Copy SSH public key to remote host.\nUsage:\n  ssh-key-copy <hostname> [key_file] [port:22] [user]\nParameters:\n  hostname: The hostname or IP address of the remote server\n  key_file: Path to the public key file (default: ~/.ssh/id_ed25519.pub or ~/.ssh/id_rsa.pub)\n  port: SSH port number (default: 22)\n  user: Remote username (default: current user)\nExample:\n  ssh-key-copy example.com\n  ssh-key-copy example.com ~/.ssh/custom_key.pub 2222 admin"

  local host="$1"
  local key_file="$2"
  local port="${3:-22}"
  local user="$4"
  local ssh_copy_id_opts=""

  if [[ -z "$host" ]]; then
    _show_error_ssh_aliases "Missing required parameter: hostname."
    return 1
  fi

  # Validate port number
  if ! [[ "$port" =~ ^[0-9]+$ ]] || [[ "$port" -lt 1 ]] || [[ "$port" -gt 65535 ]]; then
    _show_error_ssh_aliases "Invalid port number: $port. Must be between 1 and 65535."
    return 1
  fi

  # Set port option if not default
  if [[ "$port" != "22" ]]; then
    ssh_copy_id_opts="-p $port"
  fi

  # Set user@host if user is provided
  if [[ -n "$user" ]]; then
    host="$user@$host"
  fi

  # Find default key if none specified
  if [[ -z "$key_file" ]]; then
    if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
      key_file="$HOME/.ssh/id_ed25519.pub"
    elif [[ -f "$HOME/.ssh/id_rsa.pub" ]]; then
      key_file="$HOME/.ssh/id_rsa.pub"
    else
      _show_error_ssh_aliases "No default SSH key found. Please specify a key file or generate a key first."
      return 1
    fi
  fi

  # Validate key file
  if [[ ! -f "$key_file" ]]; then
    _show_error_ssh_aliases "Key file $key_file does not exist."
    return 1
  fi

  # Check if key file is a public key
  if [[ "$key_file" != *.pub ]]; then
    _show_error_ssh_aliases "The specified file does not appear to be a public key (should end with .pub)."
    return 1
  fi

  echo "Copying SSH key $key_file to $host..."
  ssh-copy-id $ssh_copy_id_opts -i "$key_file" "$host"
  local copy_status=$?

  if [[ $copy_status -eq 0 ]]; then
    echo "SSH key successfully copied to $host."
    echo "You can now connect using: ssh $ssh_copy_id_opts $host"
  else
    _show_error_ssh_aliases "Failed to copy SSH key to $host (exit code: $copy_status)."
    return 1
  fi
}' # Copy SSH key to remote host with port and user options

# SSH key generation convenience aliases

# Generate Ed25519 key (convenience alias)
alias ssh-key-ed25519='() {
  echo -e "Generate Ed25519 SSH key (recommended for most users).\nUsage:\n  ssh-key-ed25519 <key_path> <email>\nParameters:\n  key_path: Path to save the key (without .pub extension)\n  email: Email address for key comment"

  local key_path="$1"
  local email="$2"

  if [[ -z "$key_path" ]]; then
    _show_error_ssh_aliases "Missing required parameter: key_path."
    return 1
  fi

  if [[ -z "$email" ]]; then
    _show_error_ssh_aliases "Missing required parameter: email."
    return 1
  fi

  # Validate email format (basic check)
  if ! echo "$email" | grep -q -E "^[^@]+@[^@]+\.[^@]+$"; then
    _show_error_ssh_aliases "Invalid email format: $email"
    return 1
  fi

  _generate_ssh_key_ssh_aliases "ed25519" "$key_path" "$email" "" "Ed25519"
  return $?
}' # Generate Ed25519 key (most secure)

# Generate RSA key (convenience alias)
alias ssh-key-rsa='() {
  echo -e "Generate RSA SSH key with 4096 bits.\nUsage:\n  ssh-key-rsa <key_path> <email> [bits:4096]\nParameters:\n  key_path: Path to save the key (without .pub extension)\n  email: Email address for key comment\n  bits: Key size in bits (default: 4096)"

  local key_path="$1"
  local email="$2"
  local bits="${3:-4096}"

  if [[ -z "$key_path" ]]; then
    _show_error_ssh_aliases "Missing required parameter: key_path."
    return 1
  fi

  if [[ -z "$email" ]]; then
    _show_error_ssh_aliases "Missing required parameter: email."
    return 1
  fi

  # Validate email format (basic check)
  if ! echo "$email" | grep -q -E "^[^@]+@[^@]+\.[^@]+$"; then
    _show_error_ssh_aliases "Invalid email format: $email"
    return 1
  fi

  # Validate bits
  if ! [[ "$bits" =~ ^[0-9]+$ ]]; then
    _show_error_ssh_aliases "Bits must be a positive integer, got: $bits"
    return 1
  fi

  if [[ "$bits" -lt 2048 ]]; then
    echo "Warning: RSA keys less than 2048 bits are considered insecure." >&2
  fi

  _generate_ssh_key_ssh_aliases "rsa" "$key_path" "$email" "$bits" "RSA"
  return $?
}' # Generate RSA key with configurable bits

# Generate ECDSA key (convenience alias)
alias ssh-key-ecdsa='() {
  echo -e "Generate ECDSA SSH key.\nUsage:\n  ssh-key-ecdsa <key_path> <email> [bits:521]\nParameters:\n  key_path: Path to save the key (without .pub extension)\n  email: Email address for key comment\n  bits: Key size in bits (default: 521, options: 256, 384, 521)"

  local key_path="$1"
  local email="$2"
  local bits="${3:-521}"

  if [[ -z "$key_path" ]]; then
    _show_error_ssh_aliases "Missing required parameter: key_path."
    return 1
  fi

  if [[ -z "$email" ]]; then
    _show_error_ssh_aliases "Missing required parameter: email."
    return 1
  fi

  # Validate email format (basic check)
  if ! echo "$email" | grep -q -E "^[^@]+@[^@]+\.[^@]+$"; then
    _show_error_ssh_aliases "Invalid email format: $email"
    return 1
  fi

  # Validate bits
  if [[ "$bits" != "256" && "$bits" != "384" && "$bits" != "521" ]]; then
    _show_error_ssh_aliases "Invalid ECDSA key size: $bits. Valid options are: 256, 384, 521."
    return 1
  fi

  _generate_ssh_key_ssh_aliases "ecdsa" "$key_path" "$email" "$bits" "ECDSA"
  return $?
}' # Generate ECDSA key with configurable bits

# Generate DSA key (convenience alias)
alias ssh-key-dsa='() {
  echo -e "Generate DSA SSH key (NOT RECOMMENDED - legacy support only).\nUsage:\n  ssh-key-dsa <key_path> <email>\nParameters:\n  key_path: Path to save the key (without .pub extension)\n  email: Email address for key comment\nWarning: DSA keys are considered insecure and are deprecated."

  local key_path="$1"
  local email="$2"

  if [[ -z "$key_path" ]]; then
    _show_error_ssh_aliases "Missing required parameter: key_path."
    return 1
  fi

  if [[ -z "$email" ]]; then
    _show_error_ssh_aliases "Missing required parameter: email."
    return 1
  fi

  # Validate email format (basic check)
  if ! echo "$email" | grep -q -E "^[^@]+@[^@]+\.[^@]+$"; then
    _show_error_ssh_aliases "Invalid email format: $email"
    return 1
  fi

  echo "WARNING: DSA keys are considered insecure and are not supported by newer SSH implementations." >&2
  echo "Consider using Ed25519 (ssh-key-ed25519) or RSA (ssh-key-rsa) instead." >&2
  echo -n "Do you want to continue anyway? [y/N]: " >&2
  read -r response
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Key generation cancelled." >&2
    return 0
  fi

  _generate_ssh_key_ssh_aliases "dsa" "$key_path" "$email" "" "DSA"
  return $?
}' # Generate DSA key (legacy support only)

# SSH key permissions fix alias
alias ssh-key-fix-permissions='() {
  echo -e "Fix permissions for SSH keys in ~/.ssh directory.\nUsage:\n  ssh-key-fix-permissions [directory:~/.ssh]\nParameters:\n  directory: SSH directory to fix permissions for (default: ~/.ssh)"

  local ssh_dir="${1:-$HOME/.ssh}"

  if [[ ! -d "$ssh_dir" ]]; then
    _show_error_ssh_aliases "SSH directory not found: $ssh_dir"
    return 1
  fi

  echo "Fixing permissions for SSH directory and keys in $ssh_dir..."

  # Fix directory permissions
  chmod 700 "$ssh_dir"
  if [[ $? -ne 0 ]]; then
    _show_error_ssh_aliases "Failed to set permissions on $ssh_dir"
    return 1
  fi

  # Fix private key permissions
  find "$ssh_dir" -type f -not -name "*.pub" -not -name "known_hosts" -not -name "config" -not -name "authorized_keys" | while read -r key_file; do
    echo "Setting permissions for private key: $key_file"
    chmod 600 "$key_file"
  done

  # Fix public key permissions
  find "$ssh_dir" -type f -name "*.pub" | while read -r pub_file; do
    echo "Setting permissions for public key: $pub_file"
    chmod 644 "$pub_file"
  done

  # Fix config and known_hosts permissions
  for file in "$ssh_dir/config" "$ssh_dir/known_hosts" "$ssh_dir/authorized_keys"; do
    if [[ -f "$file" ]]; then
      echo "Setting permissions for $file"
      chmod 600 "$file"
    fi
  done
  # If there is an *.exp file that gives execute permission
  find "$ssh_dir" -type f -name "*.exp" -exec chmod +x {} \;
  echo "Setting permissions for $ssh_dir/*.exp files"

  echo "SSH permissions fixed successfully."
}' # Fix SSH key permissions

alias ssh-connect()='() {


  local connection_exp_path=${CONNECTION_EXP_PATH:-$HOME/.ssh/ssh_connect.exp}
  if [ ! -f "$connection_exp_path" ]; then
    echo "ssh_connect.exp not found. Downloading..."

    REMOTE_URL_PREFIX="https://raw.githubusercontent.com/funnyzak/dotfiles/refs/heads/${REPO_BRANCH:-main}/"
    REMOTE_URL_PREFIX_CN="https://raw.gitcode.com/funnyzak/dotfiles/raw/${REPO_BRANCH:-main}/"
    if curl -s --connect-timeout 2 "$REMOTE_URL_PREFIX_CN" >/dev/null 2>&1; then
      REMOTE_URL_PREFIX=$REMOTE_URL_PREFIX_CN
    fi`
    CHEATSHEET_REMOTE_URL="${REMOTE_URL_PREFIX}/utilities/shell/sshc/setup.sh"
    curl -sSL "$CHEATSHEET_REMOTE_URL" | bash -s
    chmod +x ~/.ssh/ssh_connect.exp
  fi
  if [ $# -eq 0 ]; then
    tmpfile=$(mktemp)
    curl -sSL "$CHEATSHEET_REMOTE_URL" -o "$tmpfile" && chmod +x "$tmpfile" && "$tmpfile"
  else
    curl -sSL "$CHEATSHEET_REMOTE_URL" | bash -s -- "$@" || echo "Error executing command."
  fi
}'


# SSH help function
alias ssh-help='() {
  echo -e "SSH aliases and functions help\n"
  echo "SSH Key Management:"
  echo "  ssh-key-generate      - Generate a new SSH key with enhanced security"
  echo "  ssh-key-ed25519       - Generate Ed25519 SSH key (recommended)"
  echo "  ssh-key-rsa           - Generate RSA SSH key"
  echo "  ssh-key-ecdsa         - Generate ECDSA SSH key"
  echo "  ssh-key-dsa           - Generate DSA SSH key (not recommended)"
  echo "  ssh-key-list          - List all SSH keys in ~/.ssh directory"
  echo "  ssh-key-copy          - Copy SSH public key to remote host"
  echo "  ssh-key-fix-permissions - Fix permissions for SSH keys"
  echo ""
  echo "SSH Agent Management:"
  echo "  ssh-agent-start       - Start SSH agent and load default keys"
  echo ""
  echo "SSH Config Management:"
  echo "  ssh-config-edit       - Edit SSH config file with default editor"
  echo "  ssh-hosts-list        - List all SSH hosts from config"
  echo ""
  echo "SSH Connection Testing:"
  echo "  ssh-connection-test   - Test SSH connection to a host"
  echo ""
  echo "For server management functions, use: ssh-srv-help"
}' # Show help for SSH aliases and functions

