#!/usr/bin/env bash

# SSH Configuration Helper Script
# Author: GitHub: funnyzak
# Version: 1.1.0
# Last Updated: 2025-03-29
# Usage:
# 1. Local installation:
#    chmod +x /path/to/setup.sh
#    /path/to/setup.sh
#
# 2. Remote installation:
#    curl -s https://raw.githubusercontent.com/funnyzak/dotfiles/refs/heads/sshc/utilities/shell/sshc/setup.sh | bash
#    # or
#    wget -qO- https://raw.githubusercontent.com/funnyzak/dotfiles/refs/heads/sshc/utilities/shell/sshc/setup.sh | bash
#
# 3. Remote installation with specific branch:
#    curl -s https://raw.githubusercontent.com/funnyzak/dotfiles/refs/heads/sshc/utilities/shell/sshc/setup.sh | REPO_BRANCH=sshc bash
#    # or
#    wget -qO- https://raw.githubusercontent.com/funnyzak/dotfiles/refs/heads/sshc/utilities/shell/sshc/setup.sh | REPO_BRANCH=sshc bash
#
# Security Note:
# - Always use key-based authentication when possible
# - Never store passwords in plain text
# - Regularly rotate your SSH keys
# - Limit access to your SSH configuration files
#
# This script helps users quickly configure SSH connections
# It downloads necessary template files and saves them to the ~/.ssh directory

# Set error handling
set -e

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly PLAIN='\033[0m'

# Maximum download retry attempts
readonly MAX_RETRIES=3

# Print colored messages
print_message() {
  local color="$1"
  local message="$2"
  echo -e "${color}${message}${PLAIN}"
}

# Print info message
info() {
  print_message "${BLUE}" "Info: $1"
}

# Print success message
success() {
  print_message "${GREEN}" "Success: $1"
}

# Print warning message
warning() {
  print_message "${YELLOW}" "Warning: $1"
}

# Print error message
error() {
  print_message "${RED}" "Error: $1" >&2
}

# Function to check and set file permissions
set_secure_permissions() {
  local file_path="$1"
  local permissions="$2"

  if ! chmod "$permissions" "$file_path"; then
    error "Failed to set permissions on $file_path"
    return 1
  fi

  success "Set secure permissions ($permissions) on $file_path"
  return 0
}

# Function to download files with retry
download_file() {
  local url="$1"
  local output_file="$2"
  local retry_count=0

  info "Downloading: $url"

  while [ $retry_count -lt $MAX_RETRIES ]; do
    if curl -s -f -o "$output_file" "$url"; then
      success "File downloaded successfully: $output_file"
      return 0
    else
      retry_count=$((retry_count + 1))
      warning "Download attempt $retry_count failed. Retrying in 2 seconds..."
      sleep 2
    fi
  done

  warning "File download failed after $MAX_RETRIES attempts: $url"
  return 1
}

# Ensure ~/.ssh directory exists with proper permissions
setup_ssh_dir() {
  info "Checking ~/.ssh directory..."

  if [ ! -d "$HOME/.ssh" ]; then
    info "~/.ssh directory does not exist, creating..."

    if ! mkdir -p "$HOME/.ssh"; then
      error "Failed to create ~/.ssh directory. Please check permissions."
      exit 1
    fi

    if ! set_secure_permissions "$HOME/.ssh" "700"; then
      error "Failed to set secure permissions on ~/.ssh directory."
      exit 1
    fi

    success "Created ~/.ssh directory with secure permissions"
  else
    info "~/.ssh directory already exists"

    # Check if permissions are secure
    local current_perm
    current_perm=$(stat -c "%a" "$HOME/.ssh" 2>/dev/null || stat -f "%Lp" "$HOME/.ssh" 2>/dev/null)

    if [ "$current_perm" != "700" ]; then
      warning "Current ~/.ssh directory permissions ($current_perm) are not secure"
      if ! set_secure_permissions "$HOME/.ssh" "700"; then
        error "Failed to set secure permissions on ~/.ssh directory."
        exit 1
      fi
    else
      info "~/.ssh directory has correct permissions"
    fi
  fi
}

# Check if file exists and prompt before overwriting
check_file_exists() {
  local file_path="$1"
  local file_desc="$2"

  if [ -f "$file_path" ]; then
    warning "$file_desc already exists at $file_path"

    read -rp "Do you want to overwrite it? (y/N): " response
    case "$response" in
      [yY][eE][sS]|[yY])
        info "Will overwrite existing file"
        return 0
        ;;
      *)
        info "Skipping download for $file_desc"
        return 1
        ;;
    esac
  fi

  return 0
}

# Download configuration files
download_templates() {
  local github_base_url="https://raw.githubusercontent.com/funnyzak/dotfiles/refs/heads/${REPO_BRANCH:-main}/utilities/shell/sshc"
  local gitcode_base_url="https://raw.gitcode.com/funnyzak/dotfiles/raw/${REPO_BRANCH:-main}/utilities/shell/sshc"
  local ssh_connect_file="$HOME/.ssh/ssh_connect.exp"
  local servers_conf_file="$HOME/.ssh/servers.conf"
  local download_source="GitHub"
  local download_success=true

  # Check if files already exist and prompt before overwriting
  check_file_exists "$ssh_connect_file" "SSH connect script" || return 0
  check_file_exists "$servers_conf_file" "Servers configuration file" || return 0

  info "First trying to download template files from GitHub..."

  # Try downloading ssh_connect.exp from GitHub
  if ! download_file "$github_base_url/ssh_connect.exp" "$ssh_connect_file"; then
    download_success=false
  fi

  # Try downloading servers.conf.example from GitHub
  if ! download_file "$github_base_url/servers.conf.example" "$servers_conf_file"; then
    download_success=false
  fi

  # If downloads from GitHub fail, try GitCode
  if [ "$download_success" = false ]; then
    warning "Failed to download files from GitHub, trying GitCode..."
    download_source="GitCode"

    # Try downloading ssh_connect.exp from GitCode
    if ! download_file "$gitcode_base_url/ssh_connect.exp" "$ssh_connect_file"; then
      error "Failed to download ssh_connect.exp from GitCode. Please check your network connection or try again later."
      exit 1
    fi

    # Try downloading servers.conf.example from GitCode
    if ! download_file "$gitcode_base_url/servers.conf.example" "$servers_conf_file"; then
      error "Failed to download servers.conf.example from GitCode. Please check your network connection or try again later."
      exit 1
    fi
  fi

  # Set file permissions
  if ! set_secure_permissions "$ssh_connect_file" "755"; then
    error "Failed to set executable permissions on ssh_connect.exp"
    exit 1
  fi

  if ! set_secure_permissions "$servers_conf_file" "600"; then
    error "Failed to set secure permissions on servers.conf"
    exit 1
  fi

  success "Downloaded files from $download_source with secure permissions"
  return 0
}

# Display usage instructions
show_instructions() {
  echo ""
  success "SSH connection configuration setup complete!"
  echo ""
  info "Created/configured the following files:"
  echo "  - ~/.ssh/ssh_connect.exp (SSH connection script)"
  echo "  - ~/.ssh/servers.conf (Server configuration file)"
  echo ""
  info "⚠️  SECURITY RECOMMENDATIONS:"
  echo "  1. Always use key-based authentication when possible"
  echo "  2. Never store passwords in plain text in configuration files"
  echo "  3. Ensure your SSH keys are protected with strong passphrases"
  echo "  4. Keep your private keys secure - don't share or expose them"
  echo ""
  info "Instructions:"
  echo "  1. Edit the ~/.ssh/servers.conf file to add your SSH server configurations"
  echo "     Format: ID,Name,Host,Port,Username,AuthType,AuthValue"
  echo ""
  echo "     Examples:"
  echo "     web1,Web Server 1,192.168.1.10,22,root,key,~/.ssh/id_rsa"
  echo "     db1,Database Server,192.168.1.20,22,admin,key,~/.ssh/db_key"
  echo ""
  info "Usage:"
  echo "  - Interactive selection: ~/.ssh/ssh_connect.exp"
  echo "  - Direct connection to specific server: ~/.ssh/ssh_connect.exp <server_id>"
  echo "  - Using environment variable: TARGET_SERVER_ID=web1 ~/.ssh/ssh_connect.exp"
  echo ""
  info "You may need to install the expect package to run the ssh_connect.exp script:"
  echo "  - Debian/Ubuntu: sudo apt-get install expect"
  echo "  - CentOS/RHEL: sudo yum install expect"
  echo "  - macOS (using Homebrew): brew install expect"
  echo ""
}

# Check for dependencies
check_dependencies() {
  info "Checking for required dependencies..."

  # Check for curl
  if ! command -v curl &> /dev/null; then
    error "curl is required but not installed. Please install curl and try again."
    exit 1
  fi

  # Check for expect (optional, just a warning)
  if ! command -v expect &> /dev/null; then
    warning "expect is not installed. You will need to install it to use the ssh_connect.exp script."
  else
    info "expect is installed."
  fi

  success "Required dependencies check passed"
}

# Main function
main() {
  info "Starting SSH connection configuration setup..."

  # Check dependencies
  check_dependencies

  # Ensure ~/.ssh directory exists with proper permissions
  setup_ssh_dir

  # Download template files
  download_templates

  # Show usage instructions
  show_instructions
}

# Run main function
main
