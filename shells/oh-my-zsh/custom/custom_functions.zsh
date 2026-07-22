command_exists() {
  command -v "$1" >/dev/null 2>&1
}

detect_best_url() {
  local timeout=3
  local urls=("${@}")

  for url in "${urls[@]}"; do
    if curl -s --connect-timeout "$timeout" "$url" >/dev/null 2>&1; then
      echo "$url"
      return
    fi
  done
  echo "No working URL found"
}

current_datetime() {
  date "+%Y-%m-%d %H:%M:%S"
}

rmdir_if_empty() {
  if [[ -z "$(ls -A "$1")" ]]; then # Check if the directory is empty (excluding . and ..)
    rmdir "$1"
    color_echo green "Directory '$1' removed (empty)."
  else
    color_echo yellow "Directory '$1' is not empty, not removed."
  fi
}

git_current_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null
}

is_wsl() {
  if [[ "$(uname -r)" == *Microsoft* ]]; then # Or check the contents of /proc/sys/kernel/osrelease
    return 0 # Is WSL, return success
  else
    return 1 # Is not WSL, return failure
  fi
}

is_mac() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    return 0 # Is macOS, return success
  else
    return 1 # Is not macOS, return failure
  fi
}

pretty_json() {
  if ! command_exists jq; then
    color_echo yellow "Warning: 'jq' command not found. Please install jq for pretty JSON output."
    echo "$1" # If jq doesn't exist, just output the raw JSON
    return
  fi

  if [ -f "$1" ]; then # If the argument is a file path
    jq '.' "$1"
  else # Assume the argument is a JSON string
    echo "$1" | jq '.'
  fi
}

get_ip_address() {
  # Try using the ip command (more modern)
  if command -v ip >/dev/null 2>&1; then
    ip addr show | grep "inet " | awk '{print $2}' | head -n 1 | cut -d'/' -f1
  # If the ip command doesn't exist, try using ifconfig (older, may not be universal)
  elif command -v ifconfig >/dev/null 2>&1; then
    ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -n 1
  else
    color_echo red "Error: Neither 'ip' nor 'ifconfig' command found. Cannot get IP address."
    return 1
  fi
}

string_contains() {
  if [[ "$1" == *"$2"* ]]; then
    return 0 # Contains, return success (true)
  else
    return 1 # Does not contain, return failure (false)
  fi
}

extract_filename() {
  local filepath="$1"
  local filename=$(basename "$filepath")
  echo "${filename%.*}" # Use parameter expansion to remove the extension
}
