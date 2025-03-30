# Description: Command cheatsheet aliases for quick reference and usage.

alias cs='() {
  REMOTE_URL_PREFIX="https://raw.githubusercontent.com/funnyzak/dotfiles/refs/heads/${REPO_BRANCH:-main}/"
  REMOTE_URL_PREFIX_CN="https://raw.gitcode.com/funnyzak/dotfiles/raw/${REPO_BRANCH:-main}/"
  if curl -s --connect-timeout 2 "$REMOTE_URL_PREFIX_CN" >/dev/null 2>&1; then
    REMOTE_URL_PREFIX=$REMOTE_URL_PREFIX_CN
  fi
  CHEATSHEET_REMOTE_URL="${REMOTE_URL_PREFIX}utilities/shell/cheatsheet.sh"
  echo "Command cheatsheet tool.\nUsage:\n cs [command] to view specific command\n cs -l to list all supported commands"
  if [ $# -eq 0 ]; then
    tmpfile=$(mktemp)
    curl -sSL "$CHEATSHEET_REMOTE_URL" -o "$tmpfile" && chmod +x "$tmpfile" && "$tmpfile"
  else
    curl -sSL "$CHEATSHEET_REMOTE_URL" | bash -s -- "$@" || echo "Error executing command."
  fi
}' # Shell command cheatsheet tool


# Extract aliases with grep - simpler approach
# Extract and print aliases from a file with descriptions
extract_aliases() {
  # Get filename without path and extension
  local basename=$(basename "$1")
  local name=${basename%_aliases.zsh}

  # Read file description
  local desc=""
  desc=$(grep "^# Description:" "$1" | head -1)
  desc=${desc#\# Description: }
  [ -z "$desc" ] && desc="No description available"

  # Extract all alias definitions from the file
  grep "^alias " "$1" | while read -r line; do
    # Extract alias name and command
    local alias_name=$(echo "$line" | sed -e "s/^alias \([a-zA-Z0-9_-]*\)=.*/\1/")

    # Skip if alias name is empty
    [ -z "$alias_name" ] && continue

    # Find description for this alias
    local alias_desc="No description"

    # Look for comment at end of line or multi-line function
    if echo "$line" | grep -q "#"; then
      # Extract comment at end of line
      alias_desc=$(echo "$line" | sed -e 's/^[^#]*#[ ]*//' -e 's/[ ]*$//')
    elif echo "$line" | grep -q "()"; then
      # For function aliases, find closing comment if any
      local start_line=$(grep -n "^alias $alias_name=" "$1" | cut -d: -f1)
      local line_count=$(wc -l < "$1")
      local current=$start_line

      # Find closing bracket with comment
      while [ $current -le $line_count ]; do
        local content=$(sed -n "${current}p" "$1")
        if echo "$content" | grep -q "^}'"; then
          if echo "$content" | grep -q "#"; then
            alias_desc=$(echo "$content" | sed -e 's/^[^#]*#[ ]*//' -e 's/[ ]*$//')
            break
          fi
        fi
        current=$((current + 1))
      done
    fi

    # Determine category
    local target_file="$other"
    if echo "$name" | grep -q "system\|srv\|vps"; then
      target_file="$sys_mgmt"
    elif echo "$name" | grep -q "docker\|environment"; then
      target_file="$containers"
    elif echo "$name" | grep -q "network\|ssh\|scp\|request\|tcpdump"; then
      target_file="$network"
    elif echo "$name" | grep -q "git"; then
      target_file="$version"
    elif echo "$name" | grep -q "file\|directory\|archive"; then
      target_file="$file_ops"
    elif echo "$name" | grep -q "image\|video\|audio\|pdf"; then
      target_file="$media"
    elif echo "$name" | grep -q "help\|zsh"; then
      target_file="$help"
    fi

    # Add to category file
    echo "$alias_name|$alias_desc" >> "$target_file"
  done
}

# Function to display all available aliases with descriptions
alias aliases-help='() {
  echo "List available aliases and their descriptions."
  echo "Usage:"
  echo "  aliases-help     - List all aliases"
  echo "  aliases-help -v  - Show verbose output"

  local aliases_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/aliases"
  local verbose=false

  # Parse arguments
  local OPTIND=1
  while getopts ":v" opt; do
    case "$opt" in
      v) verbose=true ;;
      \?) echo "Invalid option: -$OPTARG"; return 1 ;;
    esac
  done
  shift $((OPTIND-1))

  # Print verbose information if requested
  if $verbose; then
    echo "[DEBUG] Starting aliases-help with verbose output"
    echo "[DEBUG] Aliases directory: $aliases_dir"
  fi

  # Check if aliases directory exists
  if [ ! -d "$aliases_dir" ]; then
    echo "Error: Aliases directory \"$aliases_dir\" does not exist"
    return 1
  fi

  echo ""
  echo "===== Available Aliases ====="
  echo ""

  # Find all alias files and process them
  find "$aliases_dir" -type f -name "*_aliases.zsh" | sort | while read -r alias_file; do
    if $verbose; then
      echo "[DEBUG] Processing file: $alias_file"
    fi

    # Get filename without path and extension
    local basename=$(basename "$alias_file")
    local name=${basename%_aliases.zsh}

    # Read file description
    local desc=""
    desc=$(grep "^# Description:" "$alias_file" | head -1)
    desc=${desc#\# Description: }
    [ -z "$desc" ] && desc="No description available"

    # Display the alias name and description
    printf "  %-20s %s\n" "$name" "$desc"
  done

  echo ""
}' # Display all available aliases with descriptions
