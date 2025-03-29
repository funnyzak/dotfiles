# Description: SSH server management aliases and functions

_show_error_ssh_server() {
  echo "Error: $1" >&2
}

# Helper function to check if sshd is installed
_check_sshd_ssh_server_aliases() {
  if ! command -v sshd &>/dev/null; then
    echo "Error: SSH server (sshd) is not installed on this system." >&2
    echo "Please install OpenSSH server package for your system." >&2
    return 1
  fi
  return 0
}

# Helper function to find SSH server config file
_find_sshd_config_ssh_server_aliases() {
  local config_file=""

  # Check for common SSH config locations
  if [[ -f /etc/ssh/sshd_config ]]; then
    config_file="/etc/ssh/sshd_config"
  elif [[ -f /etc/sshd_config ]]; then
    config_file="/etc/sshd_config"
  elif [[ $(uname) == "Darwin" && -f /private/etc/ssh/sshd_config ]]; then
    config_file="/private/etc/ssh/sshd_config"
  fi

  echo "$config_file"
  return 0
}

# View SSH server configuration
alias ssh-srv-config='() {
  echo -e "View SSH server configuration file.\nUsage:\n  ssh-srv-config [--search <pattern>]\nOptions:\n  --search <pattern>: Search for specific configuration pattern"

  local search_pattern=""

  # Parse arguments
  if [[ "$1" == "--search" && -n "$2" ]]; then
    search_pattern="$2"
  fi

  if ! _check_sshd_ssh_server_aliases; then return 1; fi

  echo "Viewing SSH server configuration..."

  local config_file=$(_find_sshd_config_ssh_server_aliases)

  if [[ -z "$config_file" ]]; then
    _show_error_ssh_server "SSH configuration file not found in standard locations."
    return 1
  fi

  if [[ ! -r "$config_file" ]]; then
    _show_error_ssh_server "Cannot read SSH configuration file (permission denied)."
    echo "Try running with sudo: sudo cat $config_file" >&2
    return 1
  fi

  if [[ -n "$search_pattern" ]]; then
    echo "Searching for pattern: $search_pattern"
    grep -i "$search_pattern" "$config_file" || echo "Pattern not found in configuration."
  else
    less "$config_file" || cat "$config_file"
  fi
}' # View SSH server configuration file with search option

# Edit SSH server configuration
alias ssh-srv-edit='() {
  echo -e "Edit SSH server configuration file with default or specified editor.\nUsage:\n  ssh-srv-edit [editor_name:${EDITOR:-nano}]\nParameters:\n  editor_name: Editor to use (default: $EDITOR or nano if not set)"

  if ! _check_sshd_ssh_server_aliases; then return 1; fi

  local editor="${1:-${EDITOR:-nano}}"

  # Check if editor exists
  if ! command -v "$editor" &> /dev/null; then
    _show_error_ssh_server "Specified editor \"$editor\" not found. Please install it or use another editor."
    return 1
  fi

  local config_file=$(_find_sshd_config_ssh_server_aliases)

  if [[ -z "$config_file" ]]; then
    _show_error_ssh_server "SSH configuration file not found in standard locations."
    return 1
  fi

  # Check if we can write to the file (need sudo)
  if [[ ! -w "$config_file" ]]; then
    echo "Note: SSH server configuration requires elevated privileges to edit." >&2
    echo "Using sudo to edit $config_file" >&2
  fi

  echo "Editing SSH server configuration with $editor..."
  sudo "$editor" "$config_file"

  local edit_status=$?
  if [[ $edit_status -ne 0 ]]; then
    _show_error_ssh_server "Failed to edit SSH configuration file."
    return 1
  fi

  echo "Configuration edited. Remember to test it with ssh-srv-test before restarting the server."
}' # Edit SSH server configuration file

# Restart SSH server
alias ssh-srv-restart='() {
  echo -e "Restart SSH server using available service manager.\nUsage:\n  ssh-srv-restart [--test]\nOptions:\n  --test: Test configuration before restarting"

  local test_first=false

  # Parse arguments
  if [[ "$1" == "--test" ]]; then
    test_first=true
  fi

  if ! _check_sshd_ssh_server_aliases; then return 1; fi

  # Test configuration if requested
  if [[ "$test_first" == "true" ]]; then
    echo "Testing SSH server configuration before restart..."
    sudo sshd -t
    local test_status=$?

    if [[ $test_status -ne 0 ]]; then
      _show_error_ssh_server "SSH configuration test failed. Aborting restart to prevent service disruption."
      return 1
    fi
    echo "Configuration test passed. Proceeding with restart."
  fi

  echo "Restarting SSH server..."

  local os_type=$(uname)
  local restart_status=1

  if [[ "$os_type" == "Darwin" ]]; then
    # macOS specific restart
    echo "Detected macOS system, using launchctl to restart SSH server..."
    sudo launchctl unload /System/Library/LaunchDaemons/ssh.plist 2>/dev/null
    sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist 2>/dev/null
    restart_status=$?
  elif command -v systemctl &> /dev/null; then
    # systemd based systems
    sudo systemctl restart sshd
    restart_status=$?
  elif command -v service &> /dev/null; then
    # init.d based systems
    sudo service sshd restart
    restart_status=$?
  elif [[ -f /etc/init.d/sshd ]]; then
    # Direct init script
    sudo /etc/init.d/sshd restart
    restart_status=$?
  else
    _show_error_ssh_server "Could not restart SSH server. No known service manager found."
    return 1
  fi

  if [[ $restart_status -eq 0 ]]; then
    echo "SSH server restarted successfully."
    echo "Verifying SSH server is running"
    ssh-srv-status
    if [[ $? -eq 0 ]]; then
      echo "SSH server is running and listening on the configured port."
    else
      _show_error_ssh_server "SSH server is not running after restart. Please check logs for details."
      return 1
    fi
  else
    _show_error_ssh_server "Failed to restart SSH server. Please check logs for details."
    return 1
  fi
}' # Restart SSH server with optional test

# Check SSH server status
alias ssh-srv-status='() {
  echo -e "Check SSH server status using available service manager.\nUsage:\n  ssh-srv-status [--port <port_number:22>]\nOptions:\n  --port: Check specific port instead of default port 22"

  local port="22"

  # Parse arguments
  if [[ "$1" == "--port" && -n "$2" ]]; then
    port="$2"
    # Validate port number
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [[ "$port" -lt 1 ]] || [[ "$port" -gt 65535 ]]; then
      _show_error_ssh_server "Invalid port number: $port. Must be between 1 and 65535."
      return 1
    fi
  fi

  if ! _check_sshd_ssh_server_aliases; then return 1; fi

  echo "Checking SSH server status..."
  local status_ok=false
  local os_type=$(uname)

  if [[ "$os_type" == "Darwin" ]]; then
    # macOS specific status check
    echo "Detected macOS system, checking SSH server status..."
    if sudo launchctl list | grep -q com.openssh.sshd; then
      echo "✓ SSH server is loaded in launchd"
      status_ok=true

      if netstat -an | grep -q "\.$port "; then
        echo "✓ SSH server is active and listening on port $port"
      else
        echo "✗ SSH server is loaded but not listening on port $port"
        status_ok=false
      fi
    else
      echo "✗ SSH server is not loaded in launchd"
      status_ok=false
    fi
  elif command -v systemctl &> /dev/null; then
    # systemd based systems
    echo "Checking systemd service status:"
    sudo systemctl status sshd
    if sudo systemctl is-active --quiet sshd; then
      echo "✓ SSH server is active (systemd)"
      status_ok=true
    else
      echo "✗ SSH server is not active (systemd)"
      status_ok=false
    fi
  elif command -v service &> /dev/null; then
    # init.d based systems
    echo "Checking service status:"
    sudo service sshd status
    # Since service command output varies, we"ll also check process and port
    status_ok=true
  else
    # Fallback method
    echo "Checking SSH process..."
    if ps aux | grep -E "[s]shd"; then
      echo "✓ SSH server process is running"
      status_ok=true
    else
      echo "✗ No SSH server process found"
      status_ok=false
    fi
  fi

  # Always check port status as additional verification
  echo -e "\nChecking SSH port ($port)..."
  local port_status=false

  if command -v netstat &> /dev/null; then
    if netstat -tuln | grep -q ":$port "; then
      echo "✓ Port $port is open and listening"
      port_status=true
    else
      echo "✗ Port $port is not listening"
    fi
  elif command -v ss &> /dev/null; then
    if ss -tuln | grep -q ":$port "; then
      echo "✓ Port $port is open and listening"
      port_status=true
    else
      echo "✗ Port $port is not listening"
    fi
  elif command -v lsof &> /dev/null; then
    if sudo lsof -i :"$port" | grep -q LISTEN; then
      echo "✓ Port $port is open and listening"
      port_status=true
    else
      echo "✗ Port $port is not listening"
    fi
  else
    echo "Warning: Could not check port status. No suitable command found." >&2
  fi

  # Return appropriate exit code
  if [[ "$status_ok" == "true" && "$port_status" == "true" ]]; then
    return 0
  else
    return 1
  fi
}' # Check SSH server status with port option

# View SSH server logs
alias ssh-srv-logs='() {
  echo -e "View SSH server logs from system log files.\nUsage:\n  ssh-srv-logs [options]\nOptions:\n  --lines <num_lines:50>: Number of lines to display\n  --follow: Follow log output in real-time\n  --search <pattern>: Search for specific pattern in logs"

  if ! _check_sshd_ssh_server_aliases; then return 1; fi

  local num_lines="50"
  local follow_mode=false
  local search_pattern=""

  # Parse arguments
  local i=1
  while [[ $i -le $# ]]; do
    local arg="${!i}"
    case "$arg" in
      --lines)
        i=$((i+1))
        if [[ $i -le $# ]]; then
          num_lines="${!i}"
        else
          _show_error_ssh_server "Missing value for --lines option."
          return 1
        fi
        ;;
      --follow)
        follow_mode=true
        ;;
      --search)
        i=$((i+1))
        if [[ $i -le $# ]]; then
          search_pattern="${!i}"
        else
          _show_error_ssh_server "Missing value for --search option."
          return 1
        fi
        ;;
      [0-9]*)
        # For backward compatibility, accept a number as first argument
        if [[ $i -eq 1 ]]; then
          num_lines="$arg"
        fi
        ;;
      *)
        _show_error_ssh_server "Unknown option: $arg"
        return 1
        ;;
    esac
    i=$((i+1))
  done

  # Validate that num_lines is a positive integer
  if ! [[ "$num_lines" =~ ^[0-9]+$ ]]; then
    _show_error_ssh_server "Number of lines must be a positive integer, got: $num_lines"
    return 1
  fi

  echo "Viewing SSH server logs..."
  local follow_opt=""
  if [[ "$follow_mode" == "true" ]]; then
    echo "(Follow mode enabled - press Ctrl+C to exit)"
    follow_opt="-f"
  fi

  local search_cmd=""
  if [[ -n "$search_pattern" ]]; then
    echo "Searching for pattern: $search_pattern"
    search_cmd="| grep -i \"$search_pattern\""
  fi

  local os_type=$(uname)
  local log_found=false
  local log_cmd=""

  if [[ "$os_type" == "Darwin" ]]; then
    # macOS specific logs
    echo "Detected macOS system, using system.log for SSH logs..."
    if [[ -n "$search_pattern" ]]; then
      sudo grep -i ssh /var/log/system.log | grep -i "$search_pattern" | tail -n "$num_lines"
    elif [[ "$follow_mode" == "true" ]]; then
      sudo log stream --predicate \"process == \"sshd\"\" --info
    else
      sudo grep -i ssh /var/log/system.log | tail -n "$num_lines"
    fi
    log_found=$?
  elif command -v journalctl &> /dev/null; then
    # systemd journal
    echo "Using journalctl to access SSH logs..."
    local journal_cmd="sudo journalctl -u sshd"

    if [[ "$follow_mode" == "true" ]]; then
      journal_cmd="$journal_cmd -f"
    else
      journal_cmd="$journal_cmd -n $num_lines"
    fi

    if [[ -n "$search_pattern" ]]; then
      journal_cmd="$journal_cmd | grep -i \"$search_pattern\""
    fi

    eval "$journal_cmd"
    log_found=true
  elif [[ -f /var/log/auth.log ]]; then
    # Debian/Ubuntu style logs
    if [[ "$follow_mode" == "true" ]]; then
      if [[ -n "$search_pattern" ]]; then
        sudo tail -f /var/log/auth.log | grep -i "$search_pattern"
      else
        sudo tail -f /var/log/auth.log
      fi
    else
      if [[ -n "$search_pattern" ]]; then
        sudo grep -i "$search_pattern" /var/log/auth.log | tail -n "$num_lines"
      else
        sudo tail -n "$num_lines" /var/log/auth.log
      fi
    fi
    log_found=true
  elif [[ -f /var/log/secure ]]; then
    # RHEL/CentOS style logs
    if [[ "$follow_mode" == "true" ]]; then
      if [[ -n "$search_pattern" ]]; then
        sudo tail -f /var/log/secure | grep -i "$search_pattern"
      else
        sudo tail -f /var/log/secure
      fi
    else
      if [[ -n "$search_pattern" ]]; then
        sudo grep -i "$search_pattern" /var/log/secure | tail -n "$num_lines"
      else
        sudo tail -n "$num_lines" /var/log/secure
      fi
    fi
    log_found=true
  else
    echo "Could not locate SSH logs in standard locations." >&2
    echo "Searching for possible SSH log files..." >&2

    local possible_logs=$(sudo find /var/log -type f -name "*ssh*" -o -name "*auth*" -o -name "*secure*" 2>/dev/null)
    if [[ -n "$possible_logs" ]]; then
      echo "Possible SSH log files found:" >&2
      echo "$possible_logs" >&2
      log_found=true
    fi
  fi

  if [[ "$log_found" == "false" ]]; then
    _show_error_ssh_server "No SSH log files found."
    return 1
  fi
}' # View SSH server logs with follow and search options

# Test SSH server configuration
alias ssh-srv-test='() {
  echo -e "Test SSH server configuration syntax.\nUsage:\n  ssh-srv-test [--verbose]\nOptions:\n  --verbose: Show detailed output of the test"

  local verbose=false

  # Parse arguments
  if [[ "$1" == "--verbose" ]]; then
    verbose=true
  fi

  if ! _check_sshd_ssh_server_aliases; then return 1; fi

  local config_file=$(_find_sshd_config_ssh_server_aliases)
  if [[ -z "$config_file" ]]; then
    _show_error_ssh_server "SSH configuration file not found in standard locations."
    return 1
  fi

  echo "Testing SSH server configuration at $config_file..."

  if [[ "$verbose" == "true" ]]; then
    # Verbose mode shows the output of the test
    sudo sshd -t -d
    local test_status=$?
  else
    # Normal mode just shows success/failure
    sudo sshd -t
    local test_status=$?
  fi

  if [[ $test_status -eq 0 ]]; then
    echo "✓ SSH configuration test passed successfully."

    # Show key configuration settings
    echo -e "\nKey configuration settings:"
    echo "-------------------------"
    for setting in "PermitRootLogin" "PasswordAuthentication" "PubkeyAuthentication" "Port" "ListenAddress" "AllowUsers" "AllowGroups"; do
      local value=$(sudo grep -i "^\s*$setting" "$config_file" | head -n 1)
      if [[ -n "$value" ]]; then
        echo "$value"
      fi
    done
  else
    _show_error_ssh_server "SSH configuration test failed with exit code $test_status."
    echo "Use --verbose option to see detailed error information." >&2
    return 1
  fi
}' # Test SSH server configuration syntax with verbose option

alias ssh-srv-help='() {
  echo -e "SSH server management aliases and functions.\nUsage:\n  ssh-srv-help\n\nAvailable commands:"
  echo "  ssh-srv-config   - View SSH server configuration file"
  echo "  ssh-srv-edit     - Edit SSH server configuration file"
  echo "  ssh-srv-restart  - Restart SSH server"
  echo "  ssh-srv-status   - Check SSH server status"
  echo "  ssh-srv-logs     - View SSH server logs"
  echo "  ssh-srv-test     - Test SSH server configuration syntax"
}' # Show help for SSH server management aliases
