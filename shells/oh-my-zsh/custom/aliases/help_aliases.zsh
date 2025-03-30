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

# Helper function to extract alias descriptions from trailing comments
_extract_alias_comments() {
  local aliases_file="$1"
  local file_content

  # Read the file content into a variable
  file_content=$(cat "$aliases_file")

  # Process the file
  echo "$file_content" | awk '
    /^alias [a-zA-Z0-9_-]+=/,/^}'\''/ {
      # Accumulate the alias definition
      gathered = gathered $0 "\n"

      # If this is the last line of the alias definition with a comment
      if ($0 ~ /^}'\''.*#/) {
        # Extract the alias name
        match(gathered, /^alias ([a-zA-Z0-9_-]+)=/, arr)
        if (arr[1] != "") {
          name = arr[1]

          # Extract the comment
          match($0, /#[[:space:]]*(.*)[[:space:]]*$/, comment_arr)
          if (comment_arr[1] != "") {
            print name "|" comment_arr[1]
          } else {
            print name "|No description available"
          }
        }
        # Reset for next alias
        gathered = ""
      }
    }
  '
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
    echo "\033[1;34m[DEBUG] Starting aliases-help with verbose output\033[0m"
    echo "\033[1;34m[DEBUG] Aliases directory: $aliases_dir\033[0m"
    [ -n "$prefix" ] && echo "\033[1;34m[DEBUG] Filtering by prefix: $prefix\033[0m"
    [ -n "$file_prefix" ] && echo "\033[1;34m[DEBUG] Filtering by file prefix: $file_prefix\033[0m"
  fi

  # Check if aliases directory exists
  if [[ ! -d "$aliases_dir" ]]; then
    echo "\033[1;31mError: Aliases directory \"$aliases_dir\" does not exist\033[0m"
    return 1
  fi

  # Use simple file structure for better compatibility
  local file_pattern="*_aliases.zsh"
  if [ -n "$file_prefix" ]; then
    file_pattern="${file_prefix}*_aliases.zsh"
  fi

  # If detailed view is requested, show each alias with its description
  if $detailed; then
    echo "\n\033[1;36m===== Detailed Aliases List =====\033[0m\n"

    for alias_file in "$aliases_dir"/$file_pattern; do
      # Skip if file doesn"t exist
      [ ! -f "$alias_file" ] && continue

      local file_basename=$(basename "$alias_file" .zsh)
      local name=${file_basename%_aliases}

      # Read file description
      local file_desc=$(grep -m 1 "^# Description:" "$alias_file" | sed "s/^# Description: *//")
      [ -z "$file_desc" ] && file_desc="No description available"

      echo "\033[1;33m${name} aliases:\033[0m (${file_desc})"

      # Extract aliases and their descriptions
      local alias_data=$(_extract_alias_comments "$alias_file")

      # Show all aliases or filter by prefix
      echo "$alias_data" | while IFS="|" read -r alias_name alias_desc; do
        if [ -z "$prefix" ] || [[ "$alias_name" == "$prefix"* ]]; then
          printf "  \033[1;32m%-20s\033[0m %s\n" "$alias_name" "$alias_desc"
        fi
      done

      echo ""
    done

    return 0
  fi

  echo "\n\033[1;36m===== Available Aliases Index =====\033[0m\n"

  # Category-based display
  local output=""
  declare -A categories

  # Initialize categories with empty arrays
  categories["System Management"]=""
  categories["Containers & Environment"]=""
  categories["Network Tools"]=""
  categories["Version Control"]=""
  categories["File Operations"]=""
  categories["Media Processing"]=""
  categories["Help & Configuration"]=""
  categories["Other"]=""

  for alias_file in "$aliases_dir"/$file_pattern; do
    # Skip if file doesn"t exist
    [ ! -f "$alias_file" ] && continue

    if $verbose; then
      echo "\033[1;34m[DEBUG] Processing file: $alias_file\033[0m"
    fi

    # Get filename without path and extension
    local file_basename=$(basename "$alias_file" .zsh)
    local name=${file_basename%_aliases}

    # Read description
    local desc=$(grep -m 1 "^# Description:" "$alias_file" | sed "s/^# Description: *//")
    [ -z "$desc" ] && desc="No description available"

    # Determine category
    local category="Other"
    if [[ "$name" == *"system"* || "$name" == *"srv"* || "$name" == *"vps"* ]]; then
      category="System Management"
    elif [[ "$name" == *"docker"* || "$name" == *"environment"* ]]; then
      category="Containers & Environment"
    elif [[ "$name" == *"network"* || "$name" == *"ssh"* || "$name" == *"scp"* || "$name" == *"request"* || "$name" == *"tcpdump"* ]]; then
      category="Network Tools"
    elif [[ "$name" == *"git"* ]]; then
      category="Version Control"
    elif [[ "$name" == *"file"* || "$name" == *"directory"* || "$name" == *"archive"* ]]; then
      category="File Operations"
    elif [[ "$name" == *"image"* || "$name" == *"video"* || "$name" == *"audio"* || "$name" == *"pdf"* ]]; then
      category="Media Processing"
    elif [[ "$name" == *"help"* || "$name" == *"zsh"* ]]; then
      category="Help & Configuration"
    fi

    if $verbose; then
      echo "\033[1;34m[DEBUG] File: $name, Category: $category, Desc: $desc\033[0m"
    fi

    # Count aliases in file if prefix filter is applied
    local alias_count=0
    if [ -n "$prefix" ]; then
      alias_count=$(grep -c "^alias ${prefix}" "$alias_file" || echo "0")

      if [ "$alias_count" -eq 0 ]; then
        # Skip files with no matching aliases
        continue
      fi
    fi

    # Add to appropriate category
    local display_name="$name"
    [ -n "$prefix" ] && display_name="${name} ($alias_count aliases)"

    # Append to the category
    categories["$category"]="${categories[$category]}${display_name}|${desc}\n"
  done

  # Display categorized output
  for category in "System Management" "Containers & Environment" "Network Tools" "Version Control" "File Operations" "Media Processing" "Help & Configuration" "Other"; do
    local category_content="${categories[$category]}"

    # Skip empty categories
    [ -z "$category_content" ] && continue

    echo "\033[1;33m$category:\033[0m"

    # Display each file in the category
    echo -e "$category_content" | while IFS="|" read -r name desc; do
      printf "  \033[1;32m%-20s\033[0m %s\n" "$name" "$desc"
    done

    echo ""
  done

  # Show helpful tips
  if [ -n "$prefix" ]; then
    echo "\033[1;36mTo see detailed descriptions: aliases-help -d -p $prefix\033[0m"
  elif [ -n "$file_prefix" ]; then
    echo "\033[1;36mTo see detailed descriptions: aliases-help -d -f $file_prefix\033[0m"
  else
    echo "\033[1;36mTips:\033[0m"
    echo "  - Use \"aliases-help -d\" to see detailed descriptions of all aliases"
    echo "  - Use \"aliases-help -p prefix\" to filter aliases by prefix"
    echo "  - Use \"aliases-help -f file_prefix\" to show aliases from specific files"
  fi
}' # Display all available aliases with descriptions
