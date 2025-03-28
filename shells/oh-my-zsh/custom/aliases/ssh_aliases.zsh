# Description: SSH-related aliases for easier management and usage.

# Helper functions
_show_error_ssh_aliases() {
  echo "Error: $1" >&2
}

_show_usage_ssh_aliases() {
  echo "$1" >&2
}

# SSH key generation helper function with enhanced security
_generate_ssh_key_ssh_aliases() {
  local key_type="$1"
  local key_path="$2"
  local email="$3"
  local bits="$4"
  local description="$5"

  if [[ -z "$key_path" || -z "$email" ]]; then
    return 1
  fi

  echo "Generating $description SSH key: $(basename "$key_path")..."

  local cmd="ssh-keygen -t $key_type"
  if [[ -n "$bits" ]]; then
    cmd="$cmd -b $bits"
  fi
  eval "$cmd -f $key_path -C \"$email\" -N \"\""

  if [[ $? -ne 0 ]]; then
    _show_error_ssh_aliases "Failed to generate SSH key."
    return 1
  fi

  echo "SSH key generated successfully at $key_path"
  echo "Public key:"
  cat "$key_path.pub"
  return 0
}

# SSH Key Management

# Generate a new SSH key with enhanced security
alias ssh-key-generate='() {
  echo "Generate a new SSH key with enhanced security.
Usage:
  ssh-key-generate <key_name> <email> [key_type:ed25519] [bits]
Example:
  ssh-key-generate github \"user@example.com\"
  ssh-key-generate gitlab \"user@example.com\" rsa 4096
Key types: ed25519 (default), rsa, ecdsa, dsa
Default bits: ed25519 (none), rsa (4096), ecdsa (521), dsa (none)"

  local key_name="$1"
  local email="$2"
  local key_type="$3"
  local bits="$4"

  if [[ -z "$key_name" || -z "$email" ]]; then
    _show_error_ssh_aliases "Missing required parameters: key_name and email."
    return 1
  fi

  # Set defaults
  key_type="${key_type:-ed25519}"
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
      ;;
    ed25519|*)
      key_type="ed25519"
      description="Ed25519"
      ;;
  esac

  _generate_ssh_key_ssh_aliases "$key_type" "$HOME/.ssh/$key_name" "$email" "$bits" "$description"
}' # Generate secure SSH key

# Start the SSH agent and load keys
alias ssh-agent-start='() {
  echo "Start SSH agent and load default keys.
Usage:
  ssh-agent-start"

  echo "Starting SSH agent..."
  eval "$(ssh-agent -s)"

  if [[ $? -ne 0 ]]; then
    _show_error_ssh_aliases "Failed to start SSH agent."
    return 1
  fi

  echo "SSH agent started successfully."

  # Load default key if it exists
  if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
    ssh-add "$HOME/.ssh/id_ed25519"
  elif [[ -f "$HOME/.ssh/id_rsa" ]]; then
    ssh-add "$HOME/.ssh/id_rsa"
  fi
}' # Start SSH agent and load default keys

# List all SSH keys in the ~/.ssh directory
alias ssh-key-list='() {
  echo "List all SSH keys in the ~/.ssh directory.
Usage:
  ssh-key-list"

  echo "Listing SSH keys in $HOME/.ssh/:"
  for key in "$HOME/.ssh/"*.pub; do
    if [[ -f "$key" ]]; then
      echo "$(basename "${key%.pub}") ($(head -n 1 "$key" | cut -d " " -f 1-2))"
    fi
  done
}' # List all SSH keys

# SSH Config Management

# Edit SSH config file with default editor
alias ssh-config-edit='() {
  echo "Edit SSH config file with default editor.
Usage:
  ssh-config-edit"

  if [[ -z "$EDITOR" ]]; then
    EDITOR="nano"
  fi

  if [[ ! -f "$HOME/.ssh/config" ]]; then
    echo "SSH config file does not exist. Creating it..." >&2
    mkdir -p "$HOME/.ssh"
    touch "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config"
  fi

  echo "Opening SSH config with $EDITOR..."
  $EDITOR "$HOME/.ssh/config"
}' # Edit SSH config file

# List all SSH hosts from config
alias ssh-hosts-list='() {
  echo "List all SSH hosts from config.
Usage:
  ssh-hosts-list"

  if [[ ! -f "$HOME/.ssh/config" ]]; then
    _show_error_ssh_aliases "SSH config file does not exist."
    return 1
  fi

  echo "SSH hosts defined in your config:"
  grep "^Host " "$HOME/.ssh/config" | sed "s/Host //" | grep -v "\*"
}' # List SSH hosts from config

# SSH Connection Testing and Maintenance

# Test SSH connection to a host
alias ssh-connection-test='() {
  echo "Test SSH connection to a host.
Usage:
  ssh-connection-test <hostname>"

  local host="$1"

  if [[ -z "$host" ]]; then
    _show_error_ssh_aliases "Missing required parameter: hostname."
    return 1
  fi

  echo "Testing SSH connection to $host..."
  ssh -T -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no "$host" exit

  if [[ $? -eq 0 ]]; then
    echo "Success: Connection to $host works."
  else
    _show_error_ssh_aliases "Could not connect to $host."
    return 1
  fi
}' # Test SSH connection

# Copy SSH public key to remote host
alias ssh-key-copy='() {
  echo "Copy SSH public key to remote host.
Usage:
  ssh-key-copy <hostname> [key_file]
Default key_file is ~/.ssh/id_ed25519.pub or ~/.ssh/id_rsa.pub"

  local host="$1"
  local key_file="$2"

  if [[ -z "$host" ]]; then
    _show_error_ssh_aliases "Missing required parameter: hostname."
    return 1
  fi

  if [[ -z "$key_file" ]]; then
    if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
      key_file="$HOME/.ssh/id_ed25519.pub"
    elif [[ -f "$HOME/.ssh/id_rsa.pub" ]]; then
      key_file="$HOME/.ssh/id_rsa.pub"
    else
      _show_error_ssh_aliases "No default SSH key found. Please specify a key file."
      return 1
    fi
  fi

  if [[ ! -f "$key_file" ]]; then
    _show_error_ssh_aliases "Key file $key_file does not exist."
    return 1
  fi

  echo "Copying SSH key $key_file to $host..."
  ssh-copy-id -i "$key_file" "$host"
}' # Copy SSH key to remote host

# SSH key generation convenience aliases

# Generate Ed25519 key (convenience alias)
alias ssh-key-ed25519='() {
  echo "Generate Ed25519 SSH key.
Usage:
  ssh-key-ed25519 <key_path> <email>"

  local key_path="$1"
  local email="$2"

  if [[ -z "$key_path" || -z "$email" ]]; then
    _show_error_ssh_aliases "Missing required parameters: key_path and email."
    return 1
  fi

  _generate_ssh_key_ssh_aliases "ed25519" "$key_path" "$email" "" "Ed25519"
}' # Generate Ed25519 key

# Generate RSA key (convenience alias)
alias ssh-key-rsa='() {
  echo "Generate RSA SSH key.
Usage:
  ssh-key-rsa <key_path> <email>"

  local key_path="$1"
  local email="$2"

  if [[ -z "$key_path" || -z "$email" ]]; then
    _show_error_ssh_aliases "Missing required parameters: key_path and email."
    return 1
  fi

  _generate_ssh_key_ssh_aliases "rsa" "$key_path" "$email" "4096" "RSA"
}' # Generate RSA key

# Generate ECDSA key (convenience alias)
alias ssh-key-ecdsa='() {
  echo "Generate ECDSA SSH key.
Usage:
  ssh-key-ecdsa <key_path> <email>"

  local key_path="$1"
  local email="$2"

  if [[ -z "$key_path" || -z "$email" ]]; then
    _show_error_ssh_aliases "Missing required parameters: key_path and email."
    return 1
  fi

  _generate_ssh_key_ssh_aliases "ecdsa" "$key_path" "$email" "521" "ECDSA"
}' # Generate ECDSA key

# Generate DSA key (convenience alias)
alias ssh-key-dsa='() {
  echo "Generate DSA SSH key.
Usage:
  ssh-key-dsa <key_path> <email>"

  local key_path="$1"
  local email="$2"

  if [[ -z "$key_path" || -z "$email" ]]; then
    _show_error_ssh_aliases "Missing required parameters: key_path and email."
    return 1
  fi

  _generate_ssh_key_ssh_aliases "dsa" "$key_path" "$email" "" "DSA"
}' # Generate DSA key
