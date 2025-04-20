# Description: Server maintenance aliases for system services, users, and processes management

# System service management shortcuts
# -----------------------------
alias sc="systemctl"            # Control system services
alias scs="systemctl status"    # Check system service status
alias scstart="systemctl start" # Start system service
alias scstop="systemctl stop"   # Stop system service
alias scr="systemctl restart"   # Restart system service
alias sce="systemctl enable"    # Enable system service
alias scd="systemctl disable"   # Disable system service

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
alias syslog="tail -f /var/log/syslog -n 100"            # Monitor system logs
alias kernlog="tail -f /var/log/kern.log -n 100"         # Monitor kernel logs
alias authlog="tail -f /var/log/auth.log -n 100"         # Monitor authentication logs

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

alias srv-overview='() {
  echo -e "Show system overview.\nUsage:\n  srv-overview"

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

alias srv-clean-system='() {
  echo -e "Clean system caches and temporary files.\nUsage:\n  srv-clean-system [--thorough|-t]"

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

alias srv-backup-config='() {
  echo -e "Backup system configuration files.\nUsage:\n  srv-backup-config [destination:~/backups]"

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

# Time synchronization
# -----------------------------
alias srv-sync-time='() {
  echo -e "Synchronize system time with NTP servers.\nUsage:\n  srv-sync-time [ntp_server:pool.ntp.org]"

  local ntp_server="${1:-pool.ntp.org}"

  echo "Attempting to synchronize time with NTP server: $ntp_server"

  # Check if running as root (required for time changes)
  if [ "$(id -u)" -ne 0 ]; then
    echo "Note: Time synchronization typically requires root privileges"
    echo "Attempting with sudo..."
  fi

  # Try different time sync commands based on what is available
  if command -v ntpdate >/dev/null 2>&1; then
    echo "Using ntpdate for time synchronization..."
    sudo ntpdate "$ntp_server"

    if [ $? -ne 0 ]; then
      echo "Error: Failed to synchronize time using ntpdate" >&2
      return 1
    fi

  elif command -v chronyd >/dev/null 2>&1; then
    echo "Using chronyd for time synchronization..."
    sudo chronyd -q "server $ntp_server iburst"

    if [ $? -ne 0 ]; then
      echo "Error: Failed to synchronize time using chronyd" >&2
      return 1
    fi

  elif command -v timedatectl >/dev/null 2>&1; then
    echo "Using timedatectl for time synchronization..."
    sudo timedatectl set-ntp true

    if [ $? -ne 0 ]; then
      echo "Error: Failed to enable NTP using timedatectl" >&2
      return 1
    fi

    # Manually sync with specified server on systems with systemd-timesyncd
    if [ -f "/etc/systemd/timesyncd.conf" ]; then
      sudo sed -i.bak "s/^#*NTP=.*/NTP=$ntp_server/" /etc/systemd/timesyncd.conf
      sudo systemctl restart systemd-timesyncd
    fi

  elif command -v sntp >/dev/null 2>&1; then
    echo "Using sntp for time synchronization..."
    sudo sntp -s "$ntp_server"

    if [ $? -ne 0 ]; then
      echo "Error: Failed to synchronize time using sntp" >&2
      return 1
    fi

  # macOS specific
  elif command -v systemsetup >/dev/null 2>&1; then
    echo "Using macOS systemsetup for time synchronization..."
    sudo systemsetup -setnetworktimeserver "$ntp_server"
    sudo systemsetup -setusingnetworktime on

    if [ $? -ne 0 ]; then
      echo "Error: Failed to configure time server on macOS" >&2
      return 1
    fi

  else
    echo "Error: No supported time synchronization tools found (ntpdate, chronyd, timedatectl, sntp, or systemsetup)" >&2
    return 1
  fi

  echo "System time synchronized successfully with $ntp_server"
  echo "Current system time: $(date)"
}' # Synchronize system time with NTP servers

alias srv-fix-locale='() {
  echo -e "Check and fix system locale settings.\nUsage:\n  srv-fix-locale [options] [target_locale:en_US.UTF-8]\nOptions:\n  --auto|-a       Auto-fix without prompting\n  --list|-l       List available locales\n  --test|-t       Test mode (no changes)\n  --verbose|-v    Verbose output"

  # Parse arguments
  local auto_fix=0
  local test_mode=0
  local verbose=0
  local list_mode=0
  local target_locale=""

  # Process all arguments
  while [ $# -gt 0 ]; do
    case "$1" in
      --auto|-a)
        auto_fix=1
        shift
        ;;
      --test|-t)
        test_mode=1
        shift
        ;;
      --verbose|-v)
        verbose=1
        shift
        ;;
      --list|-l)
        list_mode=1
        shift
        ;;
      *)
        # If not an option, treat as target locale
        if [[ ! "$1" =~ ^- ]]; then
          target_locale="$1"
          shift
        else
          echo "Error: Unknown option $1" >&2
          return 1
        fi
        ;;
    esac
  done

  # List available locales and exit if requested
  if [ "$list_mode" -eq 1 ]; then
    echo "Available locales on this system:"
    locale -a
    return 0
  fi

  # Detect system type
  local system_type=""
  if [ -f "/etc/os-release" ]; then
    system_type=$(grep -oP "^ID=\K.*" /etc/os-release | tr -d \")
  elif [ "$(uname)" = "Darwin" ]; then
    system_type="macos"
  else
    system_type="unknown"
  fi

  if [ "$verbose" -eq 1 ]; then
    echo "Detected system: $system_type"
  fi

  # Determine target locale if not specified
  if [ -z "$target_locale" ]; then
    # Try to detect current system locale or fallback to en_US.UTF-8
    if [ -n "$LANG" ]; then
      target_locale="$LANG"
    elif [ -f "/etc/default/locale" ]; then
      target_locale=$(grep -oP "^LANG=\K.*" /etc/default/locale)
    else
      target_locale="en_US.UTF-8"
    fi
  fi

  echo "Checking system locale settings (target: $target_locale)..."

  # Check if locale command exists
  if ! command -v locale >/dev/null 2>&1; then
    echo "Error: locale command not found" >&2
    return 1
  fi

  # Check current locale status
  local locale_output
  local has_error=0
  locale_output=$(locale 2>&1)

  if echo "$locale_output" | grep -q "Cannot set LC_"; then
    has_error=1
    echo "Issues found:"
    echo "$locale_output" | grep "Cannot set LC_"
    echo ""
  fi

  # On macOS, different validation approach
  if [ "$system_type" = "macos" ]; then
    if ! locale -a | grep -q "$target_locale"; then
      has_error=1
      echo "Warning: Target locale $target_locale not found on macOS" >&2
    elif [ "$has_error" -eq 0 ]; then
      echo "Locale settings appear correct on macOS"

      if [ "$verbose" -eq 1 ]; then
        echo "Current locale settings:"
        locale
      fi
      return 0
    fi
  # Linux systems
  else
    # Check if target locale is available
    if ! locale -a 2>/dev/null | grep -q "$target_locale"; then
      echo "Warning: Target locale $target_locale not generated on this system"
      has_error=1
    elif [ "$has_error" -eq 0 ]; then
      echo "Locale settings appear correct"

      if [ "$verbose" -eq 1 ]; then
        echo "Current locale settings:"
        locale
      fi
      return 0
    fi
  fi

  # Exit early in test mode
  if [ "$test_mode" -eq 1 ]; then
    if [ "$has_error" -eq 1 ]; then
      echo "Test mode: Locale issues found, would fix by setting to $target_locale"
    else
      echo "Test mode: Locale settings appear correct"
    fi
    return 0
  fi

  # Prompt user for fix if not in auto mode
  if [ "$has_error" -eq 1 ] && [ "$auto_fix" -eq 0 ]; then
    echo "Would you like to fix locale settings to $target_locale? (y/n)"
    read -r response
    if ! [[ "$response" =~ ^[Yy]$ ]]; then
      echo "User canceled. Keeping current settings."
      return 0
    fi
  fi

  # If we get here, either has_error=1 and (auto_fix=1 or user said yes)
  if [ "$has_error" -eq 1 ]; then
    echo "Starting locale fix process for $target_locale..."

    # macOS specific fix
    if [ "$system_type" = "macos" ]; then
      echo "Setting macOS locale..."
      if [ -f "$HOME/.zshrc" ]; then
        # Check if LANG is already set in .zshrc
        if grep -q "^export LANG=" "$HOME/.zshrc"; then
          sed -i.bak "s|^export LANG=.*|export LANG=\"$target_locale\"|" "$HOME/.zshrc"
        else
          echo "export LANG=\"$target_locale\"" >> "$HOME/.zshrc"
        fi

        if grep -q "^export LC_ALL=" "$HOME/.zshrc"; then
          sed -i.bak "s|^export LC_ALL=.*|export LC_ALL=\"$target_locale\"|" "$HOME/.zshrc"
        else
          echo "export LC_ALL=\"$target_locale\"" >> "$HOME/.zshrc"
        fi
      fi

      # Apply to current session
      export LANG="$target_locale"
      export LC_ALL="$target_locale"

    # Linux systems
    else
      # Debian/Ubuntu/etc.
      if [ -f "/etc/locale.gen" ]; then
        echo "Checking if locale needs to be generated..."

        # Uncomment or add the target locale in locale.gen
        local locale_pattern=$(echo "$target_locale" | sed "s/\./\\\./g")
        if grep -q "^#\s*$locale_pattern" "/etc/locale.gen"; then
          echo "Uncommenting $target_locale in /etc/locale.gen"
          if [ "$verbose" -eq 1 ]; then
            echo "Running: sudo sed -i \"s/^#\s*$locale_pattern/$locale_pattern/\" /etc/locale.gen"
          fi
          sudo sed -i "s/^#\s*$locale_pattern/$locale_pattern/" /etc/locale.gen
        elif ! grep -q "$locale_pattern" "/etc/locale.gen"; then
          echo "Adding $target_locale to /etc/locale.gen"
          if [ "$verbose" -eq 1 ]; then
            echo "Running: sudo bash -c \"echo \"$target_locale UTF-8\" >> /etc/locale.gen\""
          fi
          sudo bash -c "echo \"$target_locale UTF-8\" >> /etc/locale.gen"
        else
          echo "$target_locale already enabled in locale.gen"
        fi

        # Generate locales
        echo "Generating locales..."
        if [ "$verbose" -eq 1 ]; then
          sudo locale-gen
        else
          sudo locale-gen > /dev/null
        fi
      fi

      # Set default locale in appropriate config files
      echo "Setting system-wide locale defaults..."

      if [ -d "/etc/default" ]; then
        if [ "$verbose" -eq 1 ]; then
          echo "Updating /etc/default/locale with LANG=$target_locale and LC_ALL=$target_locale"
        fi
        sudo bash -c "echo \"LANG=$target_locale\" > /etc/default/locale"
        sudo bash -c "echo \"LC_ALL=$target_locale\" >> /etc/default/locale"
      fi

      # Update user configs
      if [ -f "$HOME/.profile" ]; then
        echo "Updating user profile..."
        if grep -q "export LANG=" "$HOME/.profile"; then
          sed -i.bak "s|export LANG=.*|export LANG=\"$target_locale\"|" "$HOME/.profile"
        else
          echo "export LANG=\"$target_locale\"" >> "$HOME/.profile"
        fi

        if grep -q "export LC_ALL=" "$HOME/.profile"; then
          sed -i.bak "s|export LC_ALL=.*|export LC_ALL=\"$target_locale\"|" "$HOME/.profile"
        else
          echo "export LC_ALL=\"$target_locale\"" >> "$HOME/.profile"
        fi
      fi
    fi

    # Apply to current session for both platforms
    export LANG="$target_locale"
    export LC_ALL="$target_locale"

    echo "Locale fix applied. Verifying new settings..."
    locale_output=$(locale 2>&1)

    if echo "$locale_output" | grep -q "Cannot set LC_"; then
      echo "Warning: Some locale issues still remain:" >&2
      echo "$locale_output" | grep "Cannot set LC_" >&2
      echo "A system restart may be required for all changes to take effect." >&2
      return 1
    else
      echo "Locale successfully configured to $target_locale"
      if [ "$verbose" -eq 1 ]; then
        echo "Current locale settings:"
        locale
      fi
      echo "Note: Some applications may require restart to recognize the new locale settings."
    fi
  fi
}' # Check and fix system locale settings

# Process management with enhanced killing options
# -----------------------------
alias kill-ports='() {
  echo -e "Kill processes using specific ports.\nUsage:\n  kill-ports <port1> [port2] [port3] ..."
  echo "Example:"
  echo "  kill-ports 8080 3000 5000"
  echo ""
  echo "Note: Use with caution. This will kill all processes using the specified ports."
  echo "      Ensure you have the correct ports to avoid killing unintended processes."

  if [ $# -eq 0 ]; then
    echo "Error: At least one port number is required" >&2
    return 1
  fi

  local success=0
  local error=0

  for port in "$@"; do
    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
      echo "Error: \"$port\" is not a valid port number" >&2
      error=1
      continue
    fi

    local pid=""
    local cmd=""

    # Check if we"re on Linux or Mac
    if command -v lsof >/dev/null 2>&1; then
      pid=$(lsof -ti:$port)

      # If pid is found, get process name
      if [ -n "$pid" ]; then
        cmd=$(ps -p "$pid" -o comm= 2>/dev/null)
      fi
    elif command -v netstat >/dev/null 2>&1; then
      # Fallback to netstat if lsof is not available
      pid=$(netstat -tuln 2>/dev/null | grep ":$port " | awk "{print \$7}" | cut -d/ -f1)

      # If pid is found, get process name
      if [ -n "$pid" ]; then
        cmd=$(ps -p "$pid" -o comm= 2>/dev/null)
      fi
    else
      echo "Error: Neither lsof nor netstat found" >&2
      return 1
    fi

    if [ -z "$pid" ]; then
      echo "No process found using port $port"
      continue
    fi

    echo "Found process \"$cmd\" (PID: $pid) using port $port"
    echo "Killing process..."

    kill -15 $pid 2>/dev/null
    sleep 0.1

    # Check if process still exists, if yes try SIGKILL
    if kill -0 $pid 2>/dev/null; then
      echo "Process did not exit with SIGTERM, trying SIGKILL..."
      kill -9 $pid
    fi

    # Verify process was killed
    if ! kill -0 $pid 2>/dev/null; then
      echo "Process using port $port killed successfully"
      success=1
    else
      echo "Error: Failed to kill process using port $port" >&2
      error=1
    fi
  done

  if [ $error -eq 1 ] && [ $success -eq 0 ]; then
    return 1
  fi
}' # Kill processes using specific ports

alias kill-keyword='() {
  echo -e "Kill processes matching a keyword.\nUsage:\n  kill-keyword <search_keyword> [--force|-f] [--interactive|-i]"
  echo "Options:"
  echo "  --force, -f       Force kill (SIGKILL)"
  echo "  --interactive, -i  Ask for confirmation before killing each process"
  echo ""
  echo "Example:"
  echo "  kill-keyword httpd --force"
  echo "  kill-keyword sshd --interactive"
  echo ""
  echo "Note: Use with caution. This will kill all processes matching the keyword."
  echo "      Ensure you have the correct keyword to avoid killing unintended processes."
  echo ""

  if [ $# -eq 0 ]; then
    echo "Error: Search keyword required" >&2
    return 1
  fi

  local keyword="$1"
  shift

  local force=0
  local interactive=0

  # Process options
  while [ $# -gt 0 ]; do
    case "$1" in
      --force|-f)
        force=1
        shift
        ;;
      --interactive|-i)
        interactive=1
        shift
        ;;
      *)
        echo "Error: Unknown option $1" >&2
        return 1
        ;;
    esac
  done

  # Find processes matching the keyword
  local pids
  local ps_cmd

  if [ "$(uname)" = "Darwin" ]; then
    # macOS ps format
    ps_cmd="ps -ax -o pid,ppid,user,command"
  else
    # Linux ps format
    ps_cmd="ps -eo pid,ppid,user,command"
  fi

  pids=$(eval "$ps_cmd" | grep -v "grep" | grep -i "$keyword" | awk "{print \$1}")

  if [ -z "$pids" ]; then
    echo "No processes found matching \"$keyword\""
    return 0
  fi

  # Count matching processes
  local count=$(echo "$pids" | wc -l)
  count=$(echo "$count" | tr -d " \t")

  echo "Found $count process(es) matching \"$keyword\":"

  # Show process details
  local pid_list=""
  for pid in $pids; do
    local cmd=$(ps -p "$pid" -o command= 2>/dev/null)
    local user=$(ps -p "$pid" -o user= 2>/dev/null)
    echo "PID: $pid | User: $user | Command: $cmd"
    pid_list="$pid_list $pid"
  done

  # In interactive mode, ask for confirmation for each process
  if [ "$interactive" -eq 1 ]; then
    for pid in $pids; do
      local cmd=$(ps -p "$pid" -o command= 2>/dev/null)
      echo -n "Kill process $pid ($cmd)? (y/n): "
      read -r response

      if [[ "$response" =~ ^[Yy]$ ]]; then
        if [ "$force" -eq 1 ]; then
          kill -9 "$pid"
        else
          kill -15 "$pid"
          sleep 0.1
          # Check if process still exists, if yes try SIGKILL
          if kill -0 "$pid" 2>/dev/null; then
            echo "Process did not exit with SIGTERM, trying SIGKILL..."
            kill -9 "$pid"
          fi
        fi

        if ! kill -0 "$pid" 2>/dev/null; then
          echo "Process $pid killed successfully"
        else
          echo "Error: Failed to kill process $pid" >&2
        fi
      else
        echo "Skipped process $pid"
      fi
    done
  else
    # Kill all processes at once
    echo "Killing all matching processes..."

    local signal="-15"
    if [ "$force" -eq 1 ]; then
      signal="-9"
    fi

    for pid in $pids; do
      kill $signal "$pid" 2>/dev/null

      if [ "$force" -ne 1 ]; then
        sleep 0.1
        # Check if process still exists, if yes try SIGKILL
        if kill -0 "$pid" 2>/dev/null; then
          echo "Process $pid did not exit with SIGTERM, trying SIGKILL..."
          kill -9 "$pid"
        fi
      fi

      if ! kill -0 "$pid" 2>/dev/null; then
        echo "Process $pid killed successfully"
      else
        echo "Error: Failed to kill process $pid" >&2
      fi
    done
  fi
}' # Kill processes matching a keyword

alias srv-frpc='() {
  curl -sSL https://gitee.com/funnyzak/frpc/raw/main/frpc.sh | bash -s "$@"
}'


# Other useful aliases
alias disable-welcome="sudo chmod -x /etc/update-motd.d/*" # Disable welcome message

# User management for deployment
# -----------------------------
alias srv-create-deploy='() {
  echo -e "Create a deployment user with proper permissions.\nUsage:\n  srv-create-deploy <username> [group_name:username] [deploy_dir:/var/www/username] [--shell|-s] [--no-password|-n]"
  echo -e "Options:"
  echo -e "  --shell, -s         Allow shell access (default: no shell access)"
  echo -e "  --no-password, -n   Don\"t set password (use key-based auth only)"
  echo -e "Examples:"
  echo -e "  srv-create-deploy deployuser"
  echo -e "  srv-create-deploy myapp myappgroup /var/www/myapplication --shell"

  # Check if username is provided
  if [ -z "$1" ]; then
    echo "Error: Username is required" >&2
    return 1
  fi

  local username="$1"
  shift

  # Default values
  local group_name="$username"
  local deploy_dir="/var/www/$username"
  local allow_shell=0
  local set_password=1

  # Process all arguments
  while [ $# -gt 0 ]; do
    case "$1" in
      --shell|-s)
        allow_shell=1
        shift
        ;;
      --no-password|-n)
        set_password=0
        shift
        ;;
      *)
        # If first positional parameter after username and not an option, treat as group name
        if [[ ! "$1" =~ ^- ]] && [ -z "$2" ]; then
          group_name="$1"
          shift
        # If second positional parameter and not an option, treat as deploy directory
        elif [[ ! "$1" =~ ^- ]]; then
          group_name="$1"
          deploy_dir="$2"
          shift 2
        else
          echo "Error: Unknown option $1" >&2
          return 1
        fi
        ;;
    esac
  done

  # Create group if it doesn"t exist
  echo "Creating group $group_name if it doesn\"t exist..."
  if ! getent group "$group_name" > /dev/null 2>&1; then
    sudo groupadd "$group_name"
    if [ $? -ne 0 ]; then
      echo "Error: Failed to create group $group_name" >&2
      return 1
    fi
    echo "Group $group_name created successfully"
  else
    echo "Group $group_name already exists"
  fi

  # Check if user already exists
  if id "$username" > /dev/null 2>&1; then
    echo "Error: User $username already exists" >&2
    return 1
  fi

  # Create user with default home directory
  echo "Creating user $username..."
  sudo useradd -m -g "$group_name" "$username"

  if [ $? -ne 0 ]; then
    echo "Error: Failed to create user $username" >&2
    return 1
  fi

  # Set password if required
  if [ "$set_password" -eq 1 ]; then
    echo "Setting password for $username..."
    sudo passwd "$username"

    if [ $? -ne 0 ]; then
      echo "Error: Failed to set password for $username" >&2
      return 1
    fi
  else
    echo "Skipping password setup (key-based authentication recommended)"
  fi

  # Disable shell access if requested
  if [ "$allow_shell" -eq 0 ]; then
    echo "Disabling shell access for $username..."
    sudo usermod -s /usr/sbin/nologin "$username"

    if [ $? -ne 0 ]; then
      echo "Warning: Failed to disable shell access for $username" >&2
    fi
  fi

  # Make sure deployment directory exists and has correct permissions
  echo "Setting up deployment directory $deploy_dir with correct permissions..."
  if [ ! -d "$deploy_dir" ]; then
    sudo mkdir -p "$deploy_dir"
  fi

  sudo chown "$username:$group_name" "$deploy_dir"
  sudo chmod 755 "$deploy_dir"

  # Get the actual home directory
  local home_dir=$(eval echo ~${username})

  echo "Created deployment user $username successfully:"
  echo "  - Username: $username"
  echo "  - Group: $group_name"
  echo "  - Home directory: $home_dir"
  echo "  - Deployment directory: $deploy_dir"
  echo "  - Shell access: $([ "$allow_shell" -eq 1 ] && echo "Enabled" || echo "Disabled")"

  # Create ssh directory for key-based auth if password is skipped
  if [ "$set_password" -eq 0 ]; then
    echo ""
    echo "Next steps for setting up SSH key authentication:"
    echo "1. Create .ssh directory:"
    echo "   sudo mkdir -p ${home_dir}/.ssh"
    echo ""
    echo "2. Add your public key to authorized_keys:"
    echo "   sudo nano ${home_dir}/.ssh/authorized_keys"
    echo ""
    echo "3. Set correct permissions:"
    echo "   sudo chown -R ${username}:${group_name} ${home_dir}/.ssh"
    echo "   sudo chmod 700 ${home_dir}/.ssh"
    echo "   sudo chmod 600 ${home_dir}/.ssh/authorized_keys"
  fi
}' # Create a deployment user with proper permissions

# Help function for server aliases
alias srv-help='() {
  echo "Server Management Aliases Help"
  echo "=========================="
  echo "Available commands:"
  echo "  System service management:"
  echo "  sc                - Control system services"
  echo "  scs               - Check system service status"
  echo "  scstart           - Start system service"
  echo "  scstop            - Stop system service"
  echo "  scr               - Restart system service"
  echo "  sce               - Enable system service"
  echo "  scd               - Disable system service"
  echo "  sc-list           - List running or all services"
  echo "  sc-failed         - Show failed services"
  echo ""
  echo "  System log shortcuts:"
  echo "  auditlog          - Monitor audit logs"
  echo "  syslog            - Monitor system logs"
  echo "  kernlog           - Monitor kernel logs"
  echo "  authlog           - Monitor authentication logs"
  echo "  smartlog          - Smart log viewer with multiple log support"
  echo ""
  echo "  Shell management:"
  echo "  chsh-zsh          - Change default shell to ZSH"
  echo "  chsh-bash         - Change default shell to Bash"
  echo ""
  echo "  Process management:"
  echo "  kill-pid          - Kill process by PID"
  echo "  kill-ports        - Kill processes using specific ports"
  echo "  kill-keyword      - Kill processes matching a keyword"
  echo ""
  echo "  System information and monitoring:"
  echo "  srv-overview      - Show system overview"
  echo "  srv-create-deploy - Create a deployment user with proper permissions"
  echo ""
  echo "  System tool management:"
  echo "  srv-frpc          - Install and configure frp client"
  echo ""
  echo "  System maintenance:"
  echo "  srv-clean-system      - Clean system caches and temporary files"
  echo "  srv-backup-config     - Backup system configuration files"
  echo "  srv-sync-time         - Synchronize system time with NTP servers"
  echo "  srv-fix-locale        - Check and fix system locale settings"
  echo "  srv-help              - Display this help message"
}' # Display help for server management aliases
