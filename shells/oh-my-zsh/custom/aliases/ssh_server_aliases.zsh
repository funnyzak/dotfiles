# Description: SSH server management aliases and functions

# Helper function to check if sshd is installed
_check_sshd_ssh_server_aliases() {
  if ! command -v sshd &> /dev/null; then
    echo "Error: SSH server (sshd) is not installed on this system." >&2
    return 1
  fi
  return 0
}

# View SSH server configuration
alias ssh-srv-config='() {
  echo -e "View SSH server configuration file."

  if ! _check_sshd_ssh_server_aliases; then return 1; fi

  echo "Viewing SSH server configuration..."

  local config_file=""

  # Check for common SSH config locations
  if [[ -f /etc/ssh/sshd_config ]]; then
    config_file="/etc/ssh/sshd_config"
  elif [[ -f /etc/sshd_config ]]; then
    config_file="/etc/sshd_config"
  elif [[ $(uname) == "Darwin" && -f /private/etc/ssh/sshd_config ]]; then
    config_file="/private/etc/ssh/sshd_config"
  else
    echo "Error: SSH configuration file not found in standard locations" >&2
    return 1
  fi

  less "${config_file}"
}' # View SSH server configuration file

# Edit SSH server configuration
alias ssh-srv-edit='() {
  echo -e "Edit SSH server configuration file with default or specified editor.\nUsage:\n ssh-srv-edit [editor_name:${EDITOR:-nano}]"

  if ! _check_sshd_ssh_server_aliases; then return 1; fi

  local editor="${1:-${EDITOR:-nano}}"

  # Check if editor exists
  if ! command -v "${editor}" &> /dev/null; then
    echo "Error: Specified editor \"${editor}\" not found. Please install it or use another editor." >&2
    return 1
  fi

  local config_file=""

  # Check for common SSH config locations
  if [[ -f /etc/ssh/sshd_config ]]; then
    config_file="/etc/ssh/sshd_config"
  elif [[ -f /etc/sshd_config ]]; then
    config_file="/etc/sshd_config"
  elif [[ $(uname) == "Darwin" && -f /private/etc/ssh/sshd_config ]]; then
    config_file="/private/etc/ssh/sshd_config"
  else
    echo "Error: SSH configuration file not found in standard locations" >&2
    return 1
  fi

  echo "Editing SSH server configuration with ${editor}..."
  sudo "${editor}" "${config_file}"
}' # Edit SSH server configuration file

# Restart SSH server
alias ssh-srv-restart='() {
  echo -e "Restart SSH server using available service manager."

  if ! _check_sshd_ssh_server_aliases; then return 1; fi

  echo "Restarting SSH server..."

  local os_type=$(uname)
  local restart_status=1

  if [[ "${os_type}" == "Darwin" ]]; then
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
    echo "Error: Could not restart SSH server. No known service manager found." >&2
    return 1
  fi

  if [ ${restart_status} -eq 0 ]; then
    echo "SSH server restarted successfully."
  else
    echo "Error: Failed to restart SSH server (exit code: ${restart_status})." >&2
    return 1
  fi
}' # Restart SSH server

# Check SSH server status
alias ssh-srv-status='() {
  echo "Check SSH server status using available service manager."

  if ! _check_sshd_ssh_server_aliases; then return 1; fi

  echo "Checking SSH server status..."

  local os_type=$(uname)

  if [[ "${os_type}" == "Darwin" ]]; then
    # macOS specific status check
    echo "Detected macOS system, checking SSH server status..."
    if sudo launchctl list | grep -q com.openssh.sshd; then
      echo "SSH server is loaded in launchd"
      if netstat -an | grep -q "\.22 "; then
        echo "SSH server is active and listening on port 22"
      else
        echo "SSH server is loaded but not listening on port 22"
      fi
    else
      echo "SSH server is not loaded in launchd"
    fi
  elif command -v systemctl &> /dev/null; then
    # systemd based systems
    sudo systemctl status sshd
  elif command -v service &> /dev/null; then
    # init.d based systems
    sudo service sshd status
  else
    # Fallback method
    echo "Checking SSH process..."
    if ps aux | grep -E "[s]shd"; then
      echo "SSH server process is running"
    else
      echo "No SSH server process found"
    fi

    echo -e "\nChecking SSH port (22)..."
    if command -v netstat &> /dev/null; then
      netstat -tuln | grep ":22"
    elif command -v ss &> /dev/null; then
      ss -tuln | grep ":22"
    elif command -v lsof &> /dev/null; then
      sudo lsof -i :22
    else
      echo "Error: Could not check port status. No suitable command found." >&2
    fi
  fi
}' # Check SSH server status

# View SSH server logs
alias ssh-srv-logs='() {
  echo -e "View SSH server logs from system log files.\nUsage:\n ssh-srv-logs [num_lines:50]"

  if ! _check_sshd_ssh_server_aliases; then return 1; fi

  local num_lines="${1:-50}"

  # Validate that num_lines is a positive integer
  if ! [[ "${num_lines}" =~ ^[0-9]+$ ]]; then
    echo "Error: Number of lines must be a positive integer, got: ${num_lines}" >&2
    return 1
  fi

  echo "Viewing last ${num_lines} lines of SSH server logs..."

  local os_type=$(uname)
  local log_found=false

  if [[ "${os_type}" == "Darwin" ]]; then
    # macOS specific logs
    echo "Detected macOS system, using system.log for SSH logs..."
    if sudo grep -i ssh /var/log/system.log | tail -n "${num_lines}"; then
      log_found=true
    else
      echo "No SSH related entries found in system.log" >&2
    fi
  elif command -v journalctl &> /dev/null; then
    # systemd journal
    echo "Using journalctl to access SSH logs..."
    sudo journalctl -u sshd -n "${num_lines}"
    log_found=true
  elif [[ -f /var/log/auth.log ]]; then
    # Debian/Ubuntu style logs
    sudo less +G /var/log/auth.log
    log_found=true
  elif [[ -f /var/log/secure ]]; then
    # RHEL/CentOS style logs
    sudo less +G /var/log/secure
    log_found=true
  else
    echo "Error: Could not locate SSH logs in standard locations." >&2
    echo "Searching for possible SSH log files..." >&2

    local possible_logs=$(sudo find /var/log -type f -name "*ssh*" -o -name "*auth*" -o -name "*secure*" 2>/dev/null)
    if [[ -n "${possible_logs}" ]]; then
      echo "Possible SSH log files found:" >&2
      echo "${possible_logs}" >&2
      log_found=true
    fi
  fi

  if [[ "${log_found}" == "false" ]]; then
    echo "Error: No SSH log files found." >&2
    return 1
  fi
}' # View SSH server logs

# Test SSH server configuration
alias ssh-srv-test='() {
  echo "Test SSH server configuration syntax."

  if ! _check_sshd_ssh_server_aliases; then return 1; fi

  echo "Testing SSH server configuration..."

  # Store exit code to prevent it from being overwritten
  sudo sshd -t
  local test_status=$?

  if [[ ${test_status} -eq 0 ]]; then
    echo "SSH configuration test passed successfully."
  else
    echo "Error: SSH configuration test failed with exit code ${test_status}." >&2
    return 1
  fi
}' # Test SSH server configuration syntax

