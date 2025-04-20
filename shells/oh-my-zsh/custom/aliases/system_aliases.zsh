# Description: System related aliases for monitoring, information, security, and administration tasks.

# Helper function for showing errors
_show_error_system_aliases() {
  echo "$1" >&2
  return 1
}

# Helper function for displaying usage
_show_usage_system_aliases() {
  echo -e "$1"
  return 0
}

# System information
alias df='df -h'  # Display disk usage in human-readable format
alias du='du -ch'  # Display directory size with total in human-readable format
alias free='free -m'  # Display memory usage in MB

# Convert simple aliases to function form for better flexibility
alias htop='() {
  echo "Display processes in htop, filtered by user (default: current user)."
  echo -e "Usage:\n htop [username:$USER]"

  local user="${1:-$USER}"
  htop -u "$user"
}'  # Display processes in htop, filtered by user

alias top='() {
  echo "Display processes in top, filtered by user (default: current user)."
  echo -e "Usage:\n top [username:$USER]"

  local user="${1:-$USER}"
  top -u "$user"
}'  # Display processes in top, filtered by user

# System monitoring
alias watch-mem='() {
  echo "Watch memory usage with regular updates."
  echo -e "Usage:\n watch-mem [interval_seconds:1]"

  local interval="${1:-1}"

  if ! [[ "$interval" =~ ^[0-9]+$ ]]; then
    _show_error_system_aliases "Error: Interval must be a positive integer"
    return 1
  fi

  watch -d -n "$interval" free -m
}'  # Watch memory usage with regular updates

# File hash calculations
alias calc-md5='() {
  echo "Calculate MD5 hash of file(s)."
  echo -e "Usage:\n calc-md5 <file1> [file2] [...]"

  if [ $# -eq 0 ]; then
    _show_error_system_aliases "Error: No files specified"
    return 1
  fi

  md5sum "$@"
}'  # Calculate MD5 hash of files

alias calc-sha1='() {
  echo "Calculate SHA1 hash of file(s)."
  echo -e "Usage:\n calc-sha1 <file1> [file2] [...]"

  if [ $# -eq 0 ]; then
    _show_error_system_aliases "Error: No files specified"
    return 1
  fi

  shasum -a 1 "$@"
}'  # Calculate SHA1 hash of files

alias calc-sha256='() {
  echo "Calculate SHA256 hash of file(s)."
  echo -e "Usage:\n calc-sha256 <file1> [file2] [...]"

  if [ $# -eq 0 ]; then
    _show_error_system_aliases "Error: No files specified"
    return 1
  fi

  shasum -a 256 "$@"
}'  # Calculate SHA256 hash of files

alias calc-sha512='() {
  echo "Calculate SHA512 hash of file(s)."
  echo -e "Usage:\n calc-sha512 <file1> [file2] [...]"

  if [ $# -eq 0 ]; then
    _show_error_system_aliases "Error: No files specified"
    return 1
  fi

  shasum -a 512 "$@"
}'  # Calculate SHA512 hash of files

# Random string generation helper function
_generate_random_string_system_aliases() {
  local charset="$1"
  local length="$2"
  local count="$3"

  # Validate parameters
  if [ -z "$charset" ] || [ -z "$length" ] || [ -z "$count" ]; then
    _show_error_system_aliases "Internal error: Missing parameters for string generation"
    return 1
  fi

  if ! [[ "$length" =~ ^[0-9]+$ ]] || [ "$length" -lt 1 ]; then
    _show_error_system_aliases "Internal error: Length must be a positive integer"
    return 1
  fi

  if ! [[ "$count" =~ ^[0-9]+$ ]] || [ "$count" -lt 1 ]; then
    _show_error_system_aliases "Internal error: Count must be a positive integer"
    return 1
  fi

  if ! command -v openssl &> /dev/null; then
    _show_error_system_aliases "Error: openssl command not found"
    return 1
  fi

  if ! openssl rand -base64 2048 | tr -dc "$charset" | fold -w "$length" | head -n "$count"; then
    _show_error_system_aliases "Error: Failed to generate random string"
    return 1
  fi
}

# Random string generation functions
alias gen-password='() {
  echo "Generate random password(s)."
  echo -e "Usage:\n gen-password [length:16] [count:1]"

  local length="${1:-16}"
  local count="${2:-1}"

  # Validate parameters
  if ! [[ "$length" =~ ^[0-9]+$ ]] || [ "$length" -lt 1 ]; then
    _show_error_system_aliases "Error: Length must be a positive integer"
    return 1
  fi

  if ! [[ "$count" =~ ^[0-9]+$ ]] || [ "$count" -lt 1 ]; then
    _show_error_system_aliases "Error: Count must be a positive integer"
    return 1
  fi

  _generate_random_string_system_aliases "a-zA-Z0-9" "$length" "$count"
}'  # Generate random passwords

alias gen-numbers='() {
  echo "Generate random numeric string(s)."
  echo -e "Usage:\n gen-numbers [length:16] [count:1]"

  local length="${1:-16}"
  local count="${2:-1}"

  # Validate parameters
  if ! [[ "$length" =~ ^[0-9]+$ ]] || [ "$length" -lt 1 ]; then
    _show_error_system_aliases "Error: Length must be a positive integer"
    return 1
  fi

  if ! [[ "$count" =~ ^[0-9]+$ ]] || [ "$count" -lt 1 ]; then
    _show_error_system_aliases "Error: Count must be a positive integer"
    return 1
  fi

  _generate_random_string_system_aliases "0-9" "$length" "$count"
}'  # Generate random numeric strings

alias gen-strings='() {
  echo "Generate random alphabetic string(s)."
  echo -e "Usage:\n gen-strings [length:16] [count:1]"

  local length="${1:-16}"
  local count="${2:-1}"

  # Validate parameters
  if ! [[ "$length" =~ ^[0-9]+$ ]] || [ "$length" -lt 1 ]; then
    _show_error_system_aliases "Error: Length must be a positive integer"
    return 1
  fi

  if ! [[ "$count" =~ ^[0-9]+$ ]] || [ "$count" -lt 1 ]; then
    _show_error_system_aliases "Error: Count must be a positive integer"
    return 1
  fi

  _generate_random_string_system_aliases "a-z" "$length" "$count"
}'  # Generate random alphabetic strings

# General utilities
alias cls='clear'  # Clear screen

alias clear-history='() {
  echo "Clearing command history."
  echo -e "Usage:\n clear-history"

  # Check if shell supports the required history commands
  if ! type history &> /dev/null; then
    _show_error_system_aliases "Error: history command not available in current shell"
    return 1
  fi

  if ! history -c 2>/dev/null; then
    _show_error_system_aliases "Error: Failed to clear history (history -c command failed)"
    return 1
  fi

  if ! history -w 2>/dev/null; then
    _show_error_system_aliases "Error: Failed to write history (history -w command failed)"
    return 1
  fi

  if ! history -r 2>/dev/null; then
    _show_error_system_aliases "Error: Failed to reload history (history -r command failed)"
    return 1
  fi

  echo "Command history cleared successfully"
}'  # Clear command history

# File synchronization
alias rsync-files='() {
  echo "Sync files/directories with rsync (archive, verbose, compress, progress)."
  echo -e "Usage:\n rsync-files <source> <destination> [additional_rsync_options]"

  if [ $# -lt 2 ]; then
    _show_error_system_aliases "Error: Source and destination parameters are required"
    return 1
  fi

  local source="$1"
  local destination="$2"
  shift 2  # Remove the first two parameters

  if ! rsync -avzP "$source" "$destination" "$@"; then
    _show_error_system_aliases "Error: Rsync operation failed"
    return 1
  fi
}'  # Rsync with archive, verbose, compress and progress options

alias rsync-mirror='() {
  echo "Sync files/directories with rsync using delete option for exact mirroring."
  echo -e "Usage:\n rsync-mirror <source> <destination> [additional_rsync_options]"

  if [ $# -lt 2 ]; then
    _show_error_system_aliases "Error: Source and destination parameters are required"
    return 1
  fi

  local source="$1"
  local destination="$2"
  shift 2  # Remove the first two parameters

  if ! rsync -avzP --delete "$source" "$destination" "$@"; then
    _show_error_system_aliases "Error: Rsync mirror operation failed"
    return 1
  fi
}'  # Rsync with delete option for exact mirror

alias rsync-remote='() {
  echo "Rsync from/to remote server using specific SSH port."
  echo -e "Usage:\n rsync-remote <port> <source> <destination> [additional_rsync_options]"
  echo -e "Examples:\n rsync-remote 2001 user@server1:/mnt/ /data"
  echo -e " rsync-remote 2001 /mnt/ user@server1:/data"

  if [ $# -lt 3 ]; then
    _show_error_system_aliases "Error: Port, source, and destination parameters are required"
    return 1
  fi

  local port="$1"
  local source="$2"
  local destination="$3"
  shift 3  # Remove the first three parameters

  # Validate port number
  if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    _show_error_system_aliases "Error: Port must be a number between 1 and 65535"
    return 1
  fi

  echo "Syncing from $source to $destination via port $port"
  if ! rsync -av -e "ssh -p $port" "$source" "$destination" "$@"; then
    _show_error_system_aliases "Error: Remote rsync operation failed"
    return 1
  fi
}'  # Rsync from/to remote server using specific SSH port

# System monitoring functions
alias sys-info='() {
  echo "Display system information summary."
  echo -e "Usage:\n sys-info"

  echo "=== System Information ==="
  echo "Hostname: $(hostname)"
  echo "Kernel: $(uname -r)"
  echo "OS: $(uname -s)"

  # CPU info
  echo -e "\n=== CPU Information ==="
  if command -v lscpu &> /dev/null; then
    lscpu | grep -E "^(Model name|Architecture|CPU\(s\)|CPU MHz)"
  elif [ -f /proc/cpuinfo ]; then
    grep -E "^(model name|cpu MHz|processor)" /proc/cpuinfo | head -n 8
  elif command -v sysctl &> /dev/null; then
    echo "CPU Model: $(sysctl -n machdep.cpu.brand_string 2>/dev/null)"
    echo "CPU Cores: $(sysctl -n hw.ncpu 2>/dev/null)"
  fi

  # Memory info
  echo -e "\n=== Memory Information ==="
  if command -v free &> /dev/null; then
    free -h
  elif command -v vm_stat &> /dev/null; then
    # For macOS
    echo "Memory stats:"
    vm_stat
    echo "Total memory: $(sysctl -n hw.memsize 2>/dev/null | awk '{print $0/1024/1024/1024 " GB"}')"
  fi

  # Disk info
  echo -e "\n=== Disk Usage ==="
  df -h

  # Network info
  echo -e "\n=== Network Interfaces ==="
  if command -v ip &> /dev/null; then
    ip addr | grep -E "^[0-9]+:|inet " | grep -v "inet 127" | grep -v "inet6 ::1"
  elif command -v ifconfig &> /dev/null; then
    ifconfig | grep -E "^[a-zA-Z0-9]+:|inet " | grep -v "inet 127" | grep -v "inet6 ::1"
  fi
}'  # Display system information summary

alias process-mon='() {
  echo "Monitor system processes sorted by resource usage."
  echo -e "Usage:\n process-mon [resource_type:cpu]"
  echo -e "Resource types: cpu, mem, io"

  local resource="${1:-cpu}"

  case "$resource" in
    cpu)
      if command -v htop &> /dev/null; then
        htop --sort-key PERCENT_CPU
      else
        ps aux --sort=-%cpu | head -n 15
      fi
      ;;
    mem)
      if command -v htop &> /dev/null; then
        htop --sort-key PERCENT_MEM
      else
        ps aux --sort=-%mem | head -n 15
      fi
      ;;
    io)
      if command -v iotop &> /dev/null; then
        sudo iotop -o
      elif command -v iostat &> /dev/null; then
        iostat -x 1 5
      else
        _show_error_system_aliases "Error: No IO monitoring tool available (iotop/iostat)"
        return 1
      fi
      ;;
    *)
      _show_error_system_aliases "Error: Invalid resource type. Use 'cpu', 'mem', or 'io'"
      return 1
      ;;
  esac
}'  # Monitor system processes sorted by resource usage


# Hostname management
alias change-hostname='() {
  echo "Change system hostname with proper validation."
  echo -e "Usage:\n change-hostname <new_hostname>"

  if [ $# -lt 1 ]; then
    _show_error_system_aliases "Error: New hostname parameter is required"
    return 1
  fi

  local new_hostname="$1"

  # Validate hostname format (RFC 1123 compliant)
  if ! [[ "$new_hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?$ ]]; then
    _show_error_system_aliases "Error: Invalid hostname format. Hostname must:
    - Start and end with alphanumeric characters
    - Contain only alphanumeric characters and hyphens
    - Be between 1 and 63 characters"
    return 1
  fi

  echo "Changing hostname from $(hostname) to $new_hostname"

  # Detect OS and use appropriate commands
  if [[ "$(uname -s)" == "Darwin" ]]; then
    # macOS
    if ! sudo scutil --set HostName "$new_hostname"; then
      _show_error_system_aliases "Error: Failed to set HostName"
      return 1
    fi

    if ! sudo scutil --set LocalHostName "$new_hostname"; then
      _show_error_system_aliases "Error: Failed to set LocalHostName"
      return 1
    fi

    if ! sudo scutil --set ComputerName "$new_hostname"; then
      _show_error_system_aliases "Error: Failed to set ComputerName"
      return 1
    fi

    # Update bonjour name
    if ! sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$new_hostname"; then
      _show_error_system_aliases "Warning: Failed to update NetBIOS name"
    fi

  elif [[ -f /etc/debian_version ]]; then
    # Debian/Ubuntu
    if ! echo "$new_hostname" | sudo tee /etc/hostname > /dev/null; then
      _show_error_system_aliases "Error: Failed to write to /etc/hostname"
      return 1
    fi

    if ! sudo hostname "$new_hostname"; then
      _show_error_system_aliases "Error: Failed to set hostname temporarily"
      return 1
    fi

    # Update /etc/hosts file to include new hostname
    if grep -q "$(hostname)" /etc/hosts; then
      if ! sudo sed -i "s/$(hostname)/$new_hostname/g" /etc/hosts; then
        _show_error_system_aliases "Warning: Failed to update hostname in /etc/hosts"
      fi
    else
      echo "127.0.1.1 $new_hostname" | sudo tee -a /etc/hosts > /dev/null
    fi

  elif [[ -f /etc/redhat-release ]]; then
    # RHEL/CentOS/Fedora
    if command -v hostnamectl &> /dev/null; then
      if ! sudo hostnamectl set-hostname "$new_hostname"; then
        _show_error_system_aliases "Error: Failed to set hostname using hostnamectl"
        return 1
      fi
    else
      if ! sudo hostname "$new_hostname"; then
        _show_error_system_aliases "Error: Failed to set hostname temporarily"
        return 1
      fi

      if ! echo "$new_hostname" | sudo tee /etc/hostname > /dev/null; then
        _show_error_system_aliases "Error: Failed to write to /etc/hostname"
        return 1
      fi
    fi

    # Update /etc/hosts file
    if grep -q "$(hostname)" /etc/hosts; then
      if ! sudo sed -i "s/$(hostname)/$new_hostname/g" /etc/hosts; then
        _show_error_system_aliases "Warning: Failed to update hostname in /etc/hosts"
      fi
    else
      echo "127.0.1.1 $new_hostname" | sudo tee -a /etc/hosts > /dev/null
    fi
  else
    # Generic approach for other Linux systems
    if command -v hostnamectl &> /dev/null; then
      if ! sudo hostnamectl set-hostname "$new_hostname"; then
        _show_error_system_aliases "Error: Failed to set hostname using hostnamectl"
        return 1
      fi
    else
      if ! sudo hostname "$new_hostname"; then
        _show_error_system_aliases "Error: Failed to set hostname temporarily"
        return 1
      fi

      if ! echo "$new_hostname" | sudo tee /etc/hostname > /dev/null; then
        _show_error_system_aliases "Error: Failed to write to /etc/hostname"
        return 1
      fi
    fi
  fi

  echo "Hostname successfully changed to $new_hostname"
  echo "Note: Some services may require restart to recognize the new hostname"
  echo "You may need to log out and log back in for all changes to take effect"
}'  # Change system hostname on Linux or macOS

# User Management
# -----------------

# List all users on the system
alias list-users='() {
  echo "List all users on the system with details."
  echo -e "Usage:\n list-users [filter_pattern]"

  local filter_pattern="$1"
  local user_list_command=""
  local sort_command="sort"

  # Detect OS and use appropriate commands
  if [[ "$(uname -s)" == "Darwin" ]]; then
    # macOS
    if [ -z "$filter_pattern" ]; then
      dscl . list /Users | grep -v "^_" | while read -r username; do
        echo "Username: $username"
        echo "UID: $(dscl . -read /Users/$username UniqueID 2>/dev/null | awk "{print \$2}")"
        echo "Home: $(dscl . -read /Users/$username NFSHomeDirectory 2>/dev/null | awk "{print \$2}")"
        echo "Shell: $(dscl . -read /Users/$username UserShell 2>/dev/null | awk "{print \$2}")"
        echo "-----"
      done
    else
      dscl . list /Users | grep -v "^_" | grep "$filter_pattern" | while read -r username; do
        echo "Username: $username"
        echo "UID: $(dscl . -read /Users/$username UniqueID 2>/dev/null | awk "{print \$2}")"
        echo "Home: $(dscl . -read /Users/$username NFSHomeDirectory 2>/dev/null | awk "{print \$2}")"
        echo "Shell: $(dscl . -read /Users/$username UserShell 2>/dev/null | awk "{print \$2}")"
        echo "-----"
      done
    fi
  else
    # Linux
    if [ -z "$filter_pattern" ]; then
      getent passwd | grep -v "nologin\|false" | sort -t: -k3 -n | while IFS=: read -r user _ uid gid desc home shell; do
        echo "Username: $user"
        echo "UID: $uid"
        echo "GID: $gid"
        echo "Description: $desc"
        echo "Home: $home"
        echo "Shell: $shell"
        echo "-----"
      done
    else
      getent passwd | grep "$filter_pattern" | grep -v "nologin\|false" | sort -t: -k3 -n | while IFS=: read -r user _ uid gid desc home shell; do
        echo "Username: $user"
        echo "UID: $uid"
        echo "GID: $gid"
        echo "Description: $desc"
        echo "Home: $home"
        echo "Shell: $shell"
        echo "-----"
      done
    fi
  fi
}'  # List all users on the system with details

# Add a new user with various options
alias add-user='() {
  echo "Add a new user with optional parameters."
  echo -e "Usage:\n add-user <username> [options]"
  echo -e "Options:"
  echo -e "  -p <password>    : Set user password (random if not specified)"
  echo -e "  -d <home_dir>    : Set home directory path"
  echo -e "  -s <shell>       : Set login shell"
  echo -e "  -g <group>       : Set primary group"
  echo -e "  -G <groups>      : Set additional groups (comma-separated)"
  echo -e "  -m <dir_perms>   : Set home directory permissions (e.g., 755)"
  echo -e "  -c <comment>     : Set comment/description"
  echo -e "Examples:"
  echo -e " add-user john"
  echo -e " add-user jane -p secretpass -m 750 -c \"Jane Doe\""

  if [ $# -lt 1 ]; then
    _show_error_system_aliases "Error: Username parameter is required"
    return 1
  fi

  local username="$1"
  shift

  # Check if username is valid
  if ! [[ "$username" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; then
    _show_error_system_aliases "Error: Invalid username format. Username must:
    - Start with a lowercase letter or underscore
    - Contain only lowercase letters, digits, underscores, or hyphens
    - Be at most 32 characters long"
    return 1
  fi

  # Check if user already exists
  if id "$username" &>/dev/null; then
    _show_error_system_aliases "Error: User '$username' already exists"
    return 1
  fi

  # Default values
  local password=""
  local home_dir=""
  local shell=""
  local group=""
  local groups=""
  local dir_perms="755"
  local comment=""
  local gen_passwd=true
  local password_length=12

  # Parse options
  while [ $# -gt 0 ]; do
    case "$1" in
      -p)
        if [ -z "$2" ]; then
          _show_error_system_aliases "Error: Password value missing after -p option"
          return 1
        fi
        password="$2"
        gen_passwd=false
        shift 2
        ;;
      -d)
        if [ -z "$2" ]; then
          _show_error_system_aliases "Error: Home directory value missing after -d option"
          return 1
        fi
        home_dir="$2"
        shift 2
        ;;
      -s)
        if [ -z "$2" ]; then
          _show_error_system_aliases "Error: Shell value missing after -s option"
          return 1
        fi
        shell="$2"
        shift 2
        ;;
      -g)
        if [ -z "$2" ]; then
          _show_error_system_aliases "Error: Group value missing after -g option"
          return 1
        fi
        group="$2"
        shift 2
        ;;
      -G)
        if [ -z "$2" ]; then
          _show_error_system_aliases "Error: Groups value missing after -G option"
          return 1
        fi
        groups="$2"
        shift 2
        ;;
      -m)
        if [ -z "$2" ]; then
          _show_error_system_aliases "Error: Directory permissions value missing after -m option"
          return 1
        fi
        dir_perms="$2"
        shift 2
        ;;
      -c)
        if [ -z "$2" ]; then
          _show_error_system_aliases "Error: Comment value missing after -c option"
          return 1
        fi
        comment="$2"
        shift 2
        ;;
      *)
        _show_error_system_aliases "Error: Unknown option: $1"
        return 1
        ;;
    esac
  done

  # Generate random password if not specified
  if $gen_passwd; then
    if ! command -v openssl &>/dev/null; then
      _show_error_system_aliases "Error: openssl command not found, cannot generate random password"
      return 1
    fi
    password=$(openssl rand -base64 48 | tr -dc 'a-zA-Z0-9' | fold -w "$password_length" | head -n 1)
    echo "Generated random password for user $username: $password"
  fi

  # Detect OS and add user with appropriate commands
  if [[ "$(uname -s)" == "Darwin" ]]; then
    # macOS
    echo "Creating user on macOS..."

    # Generate next available UID
    local next_uid=$(dscl . -list /Users UniqueID | awk "{print \$2}" | sort -n | tail -1 | awk "{print \$1+1}")

    # Create user
    if ! sudo dscl . -create /Users/"$username"; then
      _show_error_system_aliases "Error: Failed to create user"
      return 1
    fi

    # Set UID
    if ! sudo dscl . -create /Users/"$username" UniqueID "$next_uid"; then
      _show_error_system_aliases "Error: Failed to set UID"
      return 1
    fi

    # Set primary group (staff by default)
    if [ -z "$group" ]; then
      group="staff"
    fi
    local gid=$(dscl . -read /Groups/"$group" PrimaryGroupID 2>/dev/null | awk "{print \$2}")
    if [ -z "$gid" ]; then
      _show_error_system_aliases "Error: Group '$group' does not exist"
      return 1
    fi
    if ! sudo dscl . -create /Users/"$username" PrimaryGroupID "$gid"; then
      _show_error_system_aliases "Error: Failed to set primary group"
      return 1
    fi

    # Set home directory
    if [ -z "$home_dir" ]; then
      home_dir="/Users/$username"
    fi
    if ! sudo dscl . -create /Users/"$username" NFSHomeDirectory "$home_dir"; then
      _show_error_system_aliases "Error: Failed to set home directory"
      return 1
    fi

    # Set shell
    if [ -z "$shell" ]; then
      shell="/bin/zsh"
    fi
    if ! sudo dscl . -create /Users/"$username" UserShell "$shell"; then
      _show_error_system_aliases "Error: Failed to set shell"
      return 1
    fi

    # Set password
    if ! sudo dscl . -passwd /Users/"$username" "$password"; then
      _show_error_system_aliases "Error: Failed to set password"
      return 1
    fi

    # Set real name / comment
    if [ -n "$comment" ]; then
      if ! sudo dscl . -create /Users/"$username" RealName "$comment"; then
        _show_error_system_aliases "Error: Failed to set real name"
        return 1
      fi
    fi

    # Create home directory
    if ! sudo mkdir -p "$home_dir"; then
      _show_error_system_aliases "Error: Failed to create home directory"
      return 1
    fi

    # Set home directory permissions
    if ! sudo chmod "$dir_perms" "$home_dir"; then
      _show_error_system_aliases "Error: Failed to set home directory permissions"
      return 1
    fi

    # Set home directory ownership
    if ! sudo chown -R "$username:$group" "$home_dir"; then
      _show_error_system_aliases "Error: Failed to set home directory ownership"
      return 1
    fi

    # Add to additional groups
    if [ -n "$groups" ]; then
      IFS=',' read -ra ADDR <<< "$groups"
      for i in "${ADDR[@]}"; do
        if ! sudo dseditgroup -o edit -a "$username" -t user "$i"; then
          _show_error_system_aliases "Warning: Failed to add user to group '$i'"
        fi
      done
    fi

  else
    # Linux
    echo "Creating user on Linux..."
    local useradd_cmd="sudo useradd"

    # Set options based on arguments
    if [ -n "$comment" ]; then
      useradd_cmd="$useradd_cmd -c \"$comment\""
    fi

    if [ -n "$home_dir" ]; then
      useradd_cmd="$useradd_cmd -d \"$home_dir\""
    fi

    if [ -n "$shell" ]; then
      useradd_cmd="$useradd_cmd -s \"$shell\""
    fi

    if [ -n "$group" ]; then
      useradd_cmd="$useradd_cmd -g \"$group\""
    fi

    if [ -n "$groups" ]; then
      useradd_cmd="$useradd_cmd -G \"$groups\""
    fi

    # Create home directory
    useradd_cmd="$useradd_cmd -m"

    # Add username
    useradd_cmd="$useradd_cmd \"$username\""

    # Execute useradd command
    if ! eval "$useradd_cmd"; then
      _show_error_system_aliases "Error: Failed to create user"
      return 1
    fi

    # Set home directory permissions if specified
    if [ -n "$dir_perms" ]; then
      local home_path
      if [ -n "$home_dir" ]; then
        home_path="$home_dir"
      else
        home_path="/home/$username"
      fi

      if [ -d "$home_path" ]; then
        if ! sudo chmod "$dir_perms" "$home_path"; then
          _show_error_system_aliases "Warning: Failed to set home directory permissions"
        fi
      fi
    fi

    # Set password
    if ! echo "$username:$password" | sudo chpasswd; then
      _show_error_system_aliases "Error: Failed to set password"
      return 1
    fi
  fi

  echo "User '$username' created successfully!"
  if $gen_passwd; then
    echo "Remember to save the generated password: $password"
  fi
}'  # Add a new user with optional parameters

# Delete a user with options
alias del-user='() {
  echo "Delete a user from the system."
  echo -e "Usage:\n del-user <username> [-f] [-h] [-r]"
  echo -e "Options:"
  echo -e "  -f  : Force removal without confirmation"
  echo -e "  -h  : Keep home directory (default is to remove)"
  echo -e "  -r  : Remove all files owned by user"
  echo -e "Examples:"
  echo -e " del-user john"
  echo -e " del-user jane -f"
  echo -e " del-user john -h"

  if [ $# -lt 1 ]; then
    _show_error_system_aliases "Error: Username parameter is required"
    return 1
  fi

  local username="$1"
  shift

  # Check if user exists
  if ! id "$username" &>/dev/null; then
    _show_error_system_aliases "Error: User '$username' does not exist"
    return 1
  fi

  # Default options
  local force=false
  local keep_home=false
  local remove_all=false

  # Parse options
  while [ $# -gt 0 ]; do
    case "$1" in
      -f)
        force=true
        shift
        ;;
      -h)
        keep_home=true
        shift
        ;;
      -r)
        remove_all=true
        shift
        ;;
      *)
        _show_error_system_aliases "Error: Unknown option: $1"
        return 1
        ;;
    esac
  done

  # Get user home directory
  local home_dir=""
  if [[ "$(uname -s)" == "Darwin" ]]; then
    home_dir=$(dscl . -read /Users/"$username" NFSHomeDirectory 2>/dev/null | awk "{print \$2}")
  else
    home_dir=$(getent passwd "$username" | cut -d: -f6)
  fi

  # Confirm deletion if not forced
  if ! $force; then
    echo "Are you sure you want to delete user '$username'? [y/N]"
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      echo "User deletion canceled"
      return 0
    fi
  fi

  # Detect OS and delete user with appropriate commands
  if [[ "$(uname -s)" == "Darwin" ]]; then
    # macOS
    echo "Deleting user on macOS..."

    # Find processes running by the user and kill them
    if $remove_all; then
      echo "Killing processes owned by user '$username'..."
      pids=$(ps -u "$username" -o pid | grep -v PID)
      if [ -n "$pids" ]; then
        echo "$pids" | xargs sudo kill -9
      fi
    fi

    # Delete user account
    if ! sudo dscl . -delete /Users/"$username"; then
      _show_error_system_aliases "Error: Failed to delete user"
      return 1
    fi

    # Delete home directory if requested
    if [ -n "$home_dir" ] && [ -d "$home_dir" ] && ! $keep_home; then
      echo "Removing home directory: $home_dir"
      if ! sudo rm -rf "$home_dir"; then
        _show_error_system_aliases "Warning: Failed to remove home directory"
      fi
    fi

  else
    # Linux
    echo "Deleting user on Linux..."
    local userdel_cmd="sudo userdel"

    # Set options based on arguments
    if ! $keep_home; then
      userdel_cmd="$userdel_cmd -r"
    fi

    # Remove all files owned by user
    if $remove_all; then
      echo "Finding and removing files owned by user '$username'..."
      sudo find / -user "$username" -delete 2>/dev/null
    fi

    # Add username
    userdel_cmd="$userdel_cmd \"$username\""

    # Execute userdel command
    if ! eval "$userdel_cmd"; then
      _show_error_system_aliases "Error: Failed to delete user"
      return 1
    fi
  fi

  echo "User '$username' deleted successfully!"
}'  # Delete a user with options

# Help function for system aliases
alias sys-help='() {
  echo "System Management Aliases Help"
  echo "==========================="
  echo "Available commands:"
  echo "  System information:"
  echo "  df                - Display disk usage in human-readable format"
  echo "  du                - Display directory size with total in human-readable format"
  echo "  free              - Display memory usage in MB"
  echo "  htop              - Display processes in htop, filtered by user"
  echo "  top               - Display processes in top, filtered by user"
  echo "  watch-mem         - Watch memory usage with regular updates"
  echo "  sys-info          - Display system information summary"
  echo "  process-mon       - Monitor system processes sorted by resource usage"
  echo ""
  echo "  File hash calculations:"
  echo "  calc-md5          - Calculate MD5 hash of file(s)"
  echo "  calc-sha1         - Calculate SHA1 hash of file(s)"
  echo "  calc-sha256       - Calculate SHA256 hash of file(s)"
  echo "  calc-sha512       - Calculate SHA512 hash of file(s)"
  echo ""
  echo "  Random string generation:"
  echo "  gen-password      - Generate random password(s)"
  echo "  gen-numbers       - Generate random numeric string(s)"
  echo "  gen-strings       - Generate random alphabetic string(s)"
  echo ""
  echo "  General utilities:"
  echo "  cls               - Clear screen"
  echo "  clear-history     - Clear command history"
  echo "  change-hostname   - Change system hostname with proper validation"
  echo ""
  echo "  File synchronization:"
  echo "  rsync-files       - Sync files/directories with rsync"
  echo "  rsync-mirror      - Sync files/directories with rsync using delete option"
  echo "  rsync-remote      - Rsync from/to remote server using specific SSH port"
  echo ""
  echo "  User management:"
  echo "  list-users        - List all users on the system with details"
  echo "  add-user          - Add a new user with optional parameters"
  echo "  del-user          - Delete a user with optional force flag"
  echo ""
  echo "  system-help       - Display this help message"
}' # Display help for system management aliases
