# Description: Server maintenance aliases for system services, users, and processes management

# System service management shortcuts
# -----------------------------
alias sc="systemctl" # Control system services
alias scs="systemctl status" # Check system service status
alias scstart="systemctl start" # Start system service
alias scstop="systemctl stop" # Stop system service
alias scr="systemctl restart" # Restart system service
alias sce="systemctl enable" # Enable system service
alias scd="systemctl disable" # Disable system service

# Enhanced systemctl functions
# -----------------------------
alias sc-list='() {
  echo -e "List all running services.\nUsage:\n  sc-list [--all|-a]"

  if [ "$1" = "--all" ] || [ "$1" = "-a" ]; then
    systemctl list-units --type=service --all
  else
    systemctl list-units --type=service --state=running
  fi
}' # List running or all services

alias sc-failed='() {
  echo -e "List all failed services.\nUsage:\n  sc-failed"

  systemctl --failed

  if [ $? -ne 0 ]; then
    echo "Error: Failed to retrieve failed services" >&2
    return 1
  fi
}' # Show failed services

# System log shortcuts
# -----------------------------
alias auditlog="tail -f /var/log/audit/audit.log -n 100" # Monitor audit logs
alias syslog="tail -f /var/log/syslog -n 100" # Monitor system logs
alias kernlog="tail -f /var/log/kern.log -n 100" # Monitor kernel logs
alias authlog="tail -f /var/log/auth.log -n 100" # Monitor authentication logs

# Enhanced log viewing functions
# -----------------------------
alias smartlog='() {
  echo -e "Smartly view system logs.\nUsage:\n  smartlog [log_type:system] [lines:100]"

  # Default values
  local log_type="${1:-system}"
  local lines="${2:-100}"

  # Validate lines is a number
  if ! [[ "$lines" =~ ^[0-9]+$ ]]; then
    echo "Error: lines parameter must be a number" >&2
    return 1
  fi

  case "$log_type" in
    system|sys)
      if [ -f "/var/log/syslog" ]; then
        tail -f "/var/log/syslog" -n "$lines"
      else
        tail -f "/var/log/messages" -n "$lines"
      fi
      ;;
    auth|authentication)
      tail -f "/var/log/auth.log" -n "$lines"
      ;;
    kernel|kern)
      tail -f "/var/log/kern.log" -n "$lines"
      ;;
    audit)
      tail -f "/var/log/audit/audit.log" -n "$lines"
      ;;
    *)
      echo "Error: Unknown log type. Available types: system, auth, kernel, audit" >&2
      return 1
      ;;
  esac
}' # Smart log viewer with multiple log support

# Shell management
# -----------------------------
alias chsh-zsh='() {
  echo -e "Change default shell to ZSH.\nUsage:\n  chsh-zsh [username:$USER]"

  local username="${1:-$USER}"
  local zsh_path=$(which zsh)

  if [ -z "$zsh_path" ]; then
    echo "Error: ZSH not found. Please install ZSH first" >&2
    return 1
  fi

  echo "Changing default shell to ZSH for user $username..."
  sudo chsh -s "$zsh_path" "$username"

  if [ $? -ne 0 ]; then
    echo "Error: Failed to change shell to ZSH" >&2
    return 1
  else
    echo "Shell changed successfully to ZSH for $username"
  fi
}' # Change default shell to ZSH

alias chsh-bash='() {
  echo -e "Change default shell to Bash.\nUsage:\n  chsh-bash [username:$USER]"

  local username="${1:-$USER}"
  local bash_path=$(which bash)

  if [ -z "$bash_path" ]; then
    echo "Error: Bash not found" >&2
    return 1
  fi

  echo "Changing default shell to Bash for user $username..."
  sudo chsh -s "$bash_path" "$username"

  if [ $? -ne 0 ]; then
    echo "Error: Failed to change shell to Bash" >&2
    return 1
  else
    echo "Shell changed successfully to Bash for $username"
  fi
}' # Change default shell to Bash

# Process management
# -----------------------------
# alias kill-port='() {
#   echo -e "Kill process using specific port.\nUsage:\n  kill-port <port_number>"

#   if [ -z "$1" ]; then
#     echo "Error: Port number is required" >&2
#     return 1
#   fi

#   if ! [[ "$1" =~ ^[0-9]+$ ]]; then
#     echo "Error: Port must be a number" >&2
#     return 1
#   fi

#   local port="$1"
#   local pid

#   # Check if we're on Linux or Mac
#   if command -v lsof >/dev/null 2>&1; then
#     pid=$(lsof -i:$port -t)
#   elif command -v netstat >/dev/null 2>&1; then
#     # Fallback to netstat if lsof is not available
#     pid=$(netstat -tuln | grep ":$port " | awk "{print \$7}" | cut -d/ -f1)
#   else
#     echo "Error: Neither lsof nor netstat found" >&2
#     return 1
#   fi

#   if [ -z "$pid" ]; then
#     echo "No process found using port $port"
#     return 0
#   fi

#   echo "Found process(es) using port $port: $pid"
#   echo "Killing process(es)..."

#   for p in $pid; do
#     kill -9 "$p"
#     if [ $? -eq 0 ]; then
#       echo "Process $p killed successfully"
#     else
#       echo "Error: Failed to kill process $p" >&2
#       return 1
#     fi
#   done
# }' # Kill process using specific port
alias kill-pid='() {
  echo -e "Kill process by PID.\nUsage:\n  kill-pid <pid_number>"

  if [ -z "$1" ]; then
    echo "Error: PID is required" >&2
    return 1
  fi

  local pid="$1"

  if ! [[ "$pid" =~ ^[0-9]+$ ]]; then
    echo "Error: PID must be a number" >&2
    return 1
  fi

  echo "Killing process $pid..."
  kill -9 "$pid"

  if [ $? -eq 0 ]; then
    echo "Process $pid killed successfully"
  else
    echo "Error: Failed to kill process $pid" >&2
    return 1
  fi
}' # Kill process by PID

alias sys-overview='() {
  echo -e "Show system overview.\nUsage:\n  sys-overview"

  echo "=== System Info ==="
  uname -a
  echo ""

  echo "=== CPU Info ==="
  if command -v lscpu >/dev/null 2>&1; then
    lscpu | grep -E "^CPU\(s\)|^Model name|^Architecture|^Thread|^Core|^Socket"
  else
    echo "CPU: $(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "CPU info not available")"
    echo "Cores: $(sysctl -n hw.ncpu 2>/dev/null || echo "Core info not available")"
  fi
  echo ""

  echo "=== Memory Usage ==="
  if command -v free >/dev/null 2>&1; then
    free -h
  else
    # macOS alternative
    vm_stat | perl -ne "/page size of (\d+)/ and \$size=\$1; /Pages free: (\d+)/ and printf(\"Free Memory: %.2f GB\n\", \$1 * \$size / 1048576 / 1024); /Pages active: (\d+)/ and printf(\"Active Memory: %.2f GB\n\", \$1 * \$size / 1048576 / 1024); /Pages inactive: (\d+)/ and printf(\"Inactive Memory: %.2f GB\n\", \$1 * \$size / 1048576 / 1024);"
  fi
  echo ""

  echo "=== Disk Usage ==="
  df -h
  echo ""

  echo "=== Load Average ==="
  uptime
}' # Show system overview

alias list-users='() {
  echo -e "List all users on the system.\nUsage:\n  list-users [--active|-a]"

  if [ "$1" = "--active" ] || [ "$1" = "-a" ]; then
    echo "Listing active users:"
    who
  else
    echo "Listing all system users:"

    # Try different methods based on what available
    if [ -f "/etc/passwd" ]; then
      # Using grep and cut instead of awk to avoid zshrc issues
      grep -v "^#" /etc/passwd | while IFS=: read -r username _ uid _; do
        if [ "$uid" -ge 1000 ] && [ "$uid" -ne 65534 ]; then
          echo "$username"
        fi
      done
    elif command -v dscl >/dev/null 2>&1; then
      # macOS specific
      dscl . -list /Users | grep -v "^_"
    else
      echo "Error: Could not determine method to list users" >&2
      return 1
    fi
  fi
}' # List system users


alias clean-system='() {
  echo -e "Clean system caches and temporary files.\nUsage:\n  clean-system [--thorough|-t]"

  local thorough=0
  if [ "$1" = "--thorough" ] || [ "$1" = "-t" ]; then
    thorough=1
  fi

  echo "=== Cleaning system caches ==="

  # OS detection
  if command -v apt-get >/dev/null 2>&1; then
    # Debian/Ubuntu
    echo "Cleaning apt cache..."
    sudo apt-get clean
    sudo apt-get autoclean

    if [ $thorough -eq 1 ]; then
      echo "Running autoremove to clean unused dependencies..."
      sudo apt-get autoremove -y
    fi

  elif command -v brew >/dev/null 2>&1; then
    # macOS with Homebrew
    echo "Cleaning Homebrew cache..."
    brew cleanup

    if [ $thorough -eq 1 ]; then
      echo "Purging Homebrew caches..."
      brew cleanup --prune=all
    fi

    # macOS specific
    echo "Cleaning system log files..."
    sudo rm -rf /private/var/log/asl/*.asl 2>/dev/null

  elif command -v yum >/dev/null 2>&1; then
    # CentOS/RHEL/Fedora
    echo "Cleaning yum cache..."
    sudo yum clean all

    if [ $thorough -eq 1 ]; then
      echo "Running autoremove to clean unused dependencies..."
      sudo yum autoremove -y
    fi
  fi

  # Common for all Unix-like systems
  echo "Cleaning temporary files..."
  sudo find /tmp -type f -mtime +10 -delete 2>/dev/null

  echo "=== System cleaning complete ==="
}' # Clean system caches and temp files

alias backup-config='() {
  echo -e "Backup system configuration files.\nUsage:\n  backup-config [destination:~/backups]"

  local destination="${1:-$HOME/backups}"
  local date_str=$(date +%Y%m%d-%H%M%S)
  local backup_file="$destination/system_config_$date_str.tar.gz"

  # Create destination directory if it doesnt exist
  mkdir -p "$destination"

  echo "Creating backup of system configuration files to $backup_file"

  # Common config locations
  echo "Backing up /etc configuration files..."
  if [ -d "/etc" ]; then
    sudo tar czf "$backup_file" /etc 2>/dev/null

    if [ $? -ne 0 ]; then
      echo "Warning: Some files couldn"t be backed up (permission issues)" >&2
    fi

    # Fix permissions
    sudo chown $(whoami) "$backup_file"

    echo "Permissions fixed for backup file: $backup_file"
  else
    echo "Error: /etc directory not found" >&2
    return 1
  fi

  echo "Backup completed: $backup_file"
}' # Backup system configuration files
