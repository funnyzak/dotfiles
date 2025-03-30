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
  local alias_file=$1
  local prefix=$2

  grep "^alias " "$alias_file" | while read -r line; do
    # Extract alias name
    local alias_name=""
    alias_name=$(echo "$line" | sed -e "s/^alias \([a-zA-Z0-9_-]*\)=.*/\1/")
    # Skip if not matching prefix filter
    if [ -n "$prefix" ] && ! echo "$alias_name" | grep -q "^$prefix"; then
      continue
    fi

    # Try to find the comment at end of alias function
    local comment="No description available"
    local alias_end_line=$(grep -n "^}'" "$alias_file" | grep -A 1 -B 20 "$alias_name" | head -1)

    if [ -n "$alias_end_line" ]; then
      local line_num=${alias_end_line%%:*}
      local comment_line=$(sed -n "${line_num}p" "$alias_file")

      if echo "$comment_line" | grep -q "#"; then
        comment=$(echo "$comment_line" | sed -e "s/^.*#[ ]*//" -e "s/[ ]*$//")
      fi
    fi
    # Print alias with description
    printf "  %-20s %s\n" "$alias_name" "$comment"
  done
}

# Function to display all available aliases with descriptions
alias aliases-help='() {
  echo "List available aliases and their descriptions."
  echo "Usage:"
  echo "  aliases-help                   - List all aliases by category"
  echo "  aliases-help -p <prefix>       - List aliases starting with prefix"
  echo "  aliases-help -f <file_prefix>  - List aliases from files with prefix (e.g., srv)"
  echo "  aliases-help -d                - Show detailed alias descriptions"
  echo "  aliases-help -v                - Show verbose output"

  local aliases_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/aliases"
  local verbose=false
  local detailed=false
  local prefix=""
  local file_prefix=""

  # Parse arguments
  local OPTIND=1
  while getopts ":vdp:f:" opt; do
    case "$opt" in
      v) verbose=true ;;
      d) detailed=true ;;
      p) prefix="$OPTARG" ;;
      f) file_prefix="$OPTARG" ;;
      \?) echo "Invalid option: -$OPTARG"; return 1 ;;
    esac
  done
  shift $((OPTIND-1))

  # Print verbose information if requested
  if $verbose; then
    echo "[DEBUG] Starting aliases-help with verbose output"
    echo "[DEBUG] Aliases directory: $aliases_dir"
    [ -n "$prefix" ] && echo "[DEBUG] Filtering by prefix: $prefix"
    [ -n "$file_prefix" ] && echo "[DEBUG] Filtering by file prefix: $file_prefix"
  fi

  # Check if aliases directory exists
  if [ ! -d "$aliases_dir" ]; then
    echo "Error: Aliases directory \"$aliases_dir\" does not exist"
    return 1
  fi

  # Create temporary directory for category files
  local tmp_dir=""
  if command -v mktemp >/dev/null 2>&1; then
    tmp_dir=$(mktemp -d)
  else
    # Fallback if mktemp not available
    tmp_dir="/tmp/aliases_help_$$"
    mkdir -p "$tmp_dir"
  fi

  # Create category files
  local sys_mgmt="$tmp_dir/system_management"
  local containers="$tmp_dir/containers"
  local network="$tmp_dir/network"
  local version="$tmp_dir/version"
  local file_ops="$tmp_dir/file_ops"
  local media="$tmp_dir/media"
  local help="$tmp_dir/help"
  local other="$tmp_dir/other"

  # Create empty files
  touch "$sys_mgmt" "$containers" "$network" "$version" "$file_ops" "$media" "$help" "$other"

  # Build file list based on prefix
  local file_list="$tmp_dir/file_list"
  if [ -n "$file_prefix" ]; then
    find "$aliases_dir" -type f -name "${file_prefix}*_aliases.zsh" | sort > "$file_list"
  else
    find "$aliases_dir" -type f -name "*_aliases.zsh" | sort > "$file_list"
  fi

  if $verbose; then
    echo "[DEBUG] Found $(wc -l < "$file_list") alias files"
  fi

  # Process each alias file
  if $detailed; then
    echo ""
    echo "===== Detailed Aliases List ====="
    echo ""

    while read -r alias_file; do
      [ ! -f "$alias_file" ] && continue

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

      echo "${name} aliases: ($desc)"

      # Call the helper function with current file and prefix
      extract_aliases "$alias_file" "$prefix"

      echo ""
    done < "$file_list"
  else
    echo ""
    echo "===== Available Aliases Index ====="
    echo ""

    # Process all files for category view
    while read -r alias_file; do
      [ ! -f "$alias_file" ] && continue

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

      # Count aliases in file if prefix filter is applied
      if [ -n "$prefix" ]; then
        local count=$(grep -c "^alias $prefix" "$alias_file" || echo "0")
        if [ "$count" -eq 0 ]; then
          continue
        fi
        name="$name ($count aliases)"
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
      echo "$name|$desc" >> "$target_file"
    done < "$file_list"

    # Display categories
    for category in "System Management:$sys_mgmt" "Containers & Environment:$containers" "Network Tools:$network" "Version Control:$version" "File Operations:$file_ops" "Media Processing:$media" "Help & Configuration:$help" "Other:$other"; do
      local title=${category%%:*}
      local file=${category#*:}

      # Skip empty categories
      if [ ! -s "$file" ]; then
        continue
      fi

      echo "$title:"

      # Display each entry
      while read -r line; do
        local name=${line%%|*}
        local desc=${line#*|}
        printf "  %-20s %s\n" "$name" "$desc"
      done < "$file"

      echo ""
    done
  fi

  # Cleanup
  rm -rf "$tmp_dir"

  # Show helpful tips
  if [ -n "$prefix" ]; then
    echo "To see detailed descriptions: aliases-help -d -p $prefix"
  elif [ -n "$file_prefix" ]; then
    echo "To see detailed descriptions: aliases-help -d -f $file_prefix"
  else
    echo "Tips:"
    echo "  - Use \"aliases-help -d\" to see detailed descriptions of all aliases"
    echo "  - Use \"aliases-help -p prefix\" to filter aliases by prefix"
    echo "  - Use \"aliases-help -f file_prefix\" to show aliases from specific files"
  fi
}' # Display all available aliases with descriptions
