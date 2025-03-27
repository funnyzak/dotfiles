# Description: SSH server management aliases and functions

# Helper function to check if sshd is installed
_check_sshd_installed() {
  if ! command -v sshd &> /dev/null; then
    echo "Error: SSH server (sshd) is not installed on this system." >&2
    return 1
  fi
  return 0
}

# View SSH server configuration
alias ssh-srv-config='() {
  if ! _check_sshd_installed; then return 1; fi

  echo "Viewing SSH server configuration..."

  if [[ -f /etc/ssh/sshd_config ]]; then
    less /etc/ssh/sshd_config
  else
    echo "Error: SSH configuration file not found at /etc/ssh/sshd_config" >&2
    return 1
  fi
}' # View SSH server configuration file

# Edit SSH server configuration
alias ssh-srv-edit='() {
  if ! _check_sshd_installed; then return 1; fi

  local editor="${EDITOR:-nano}"
  echo "Editing SSH server configuration with ${editor}..."

  if [[ -f /etc/ssh/sshd_config ]]; then
    sudo "${editor}" /etc/ssh/sshd_config
  else
    echo "Error: SSH configuration file not found at /etc/ssh/sshd_config" >&2
    return 1
  fi
}' # Edit SSH server configuration file

# Restart SSH server
alias ssh-srv-restart='() {
  if ! _check_sshd_installed; then return 1; fi

  echo "Restarting SSH server..."

  if command -v systemctl &> /dev/null; then
    sudo systemctl restart sshd
  elif command -v service &> /dev/null; then
    sudo service sshd restart
  else
    echo "Error: Could not restart SSH server. No known service manager found." >&2
    return 1
  fi

  if [ $? -eq 0 ]; then
    echo "SSH server restarted successfully."
  else
    echo "Error: Failed to restart SSH server." >&2
    return 1
  fi
}' # Restart SSH server

# Check SSH server status
alias ssh-srv-status='() {
  if ! _check_sshd_installed; then return 1; fi

  echo "Checking SSH server status..."

  if command -v systemctl &> /dev/null; then
    sudo systemctl status sshd
  elif command -v service &> /dev/null; then
    sudo service sshd status
  else
    echo "Checking SSH process..."
    ps aux | grep -E "[s]shd"

    echo -e "\nChecking SSH port (22)..."
    netstat -tuln | grep ":22"
  fi
}' # Check SSH server status

# View SSH server logs
alias ssh-srv-logs='() {
  if ! _check_sshd_installed; then return 1; fi

  echo "Viewing SSH server logs..."

  if [[ -f /var/log/auth.log ]]; then
    sudo less /var/log/auth.log
  elif [[ -f /var/log/secure ]]; then
    sudo less /var/log/secure
  else
    echo "Looking for SSH logs in journald..."
    sudo journalctl -u sshd
  fi
}' # View SSH server logs

# Test SSH server configuration
alias ssh-srv-test='() {
  if ! _check_sshd_installed; then return 1; fi

  echo "Testing SSH server configuration..."
  sudo sshd -t

  if [ $? -eq 0 ]; then
    echo "SSH configuration test passed successfully."
  else
    echo "Error: SSH configuration test failed." >&2
    return 1
  fi
}' # Test SSH server configuration syntax
