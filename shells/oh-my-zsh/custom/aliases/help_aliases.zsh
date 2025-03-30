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
}'

# Function to display all available aliases with descriptions
alias aliases-help='() {
  local aliases_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/aliases"
  local categories=()
  local files=()
  local descriptions=()

  echo "\n\033[1;36m===== Available Aliases Index =====\033[0m\n"

  # Check if aliases directory exists
  if [[ ! -d "$aliases_dir" ]]; then
    echo "\033[1;31mError: Aliases directory \"$aliases_dir\" does not exist\033[0m"
    return 1
  fi

  # Collect information from all alias files
  while IFS= read -r file; do
    # Skip non-zsh files
    [[ "$file" != *.zsh ]] && continue

    # Get filename without path and extension
    local name=$(basename "$file" .zsh | sed "s/_aliases//")

    # Read description
    local desc=$(grep -m 1 "^# Description:" "$file" | sed "s/^# Description: *//")

    # Use default description if none exists
    [[ -z "$desc" ]] && desc="No description available"

    # Determine category
    local category="Other"
    if [[ "$name" == *"system"* || "$name" == *"srv"* || "$name" == *"vps"* ]]; then
      category="System Management"
    elif [[ "$name" == *"docker"* || "$name" == *"environment"* ]]; then
      category="Containers & Environment"
    elif [[ "$name" == *"network"* || "$name" == *"ssh"* || "$name" == *"scp"* || "$name" == *"request"* ]]; then
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

    # Save information
    categories+=("$category")
    files+=("$name")
    descriptions+=("$desc")
  done < <(find "$aliases_dir" -type f -name "*_aliases.zsh" | sort)

  # Display by category
  # Create array of unique categories
  local unique_categories=()
  for category in "${categories[@]}"; do
    # Check if category is already in unique_categories
    local found=0
    for unique in "${unique_categories[@]}"; do
      if [[ "$category" == "$unique" ]]; then
        found=1
        break
      fi
    done
    # If not found, add to unique_categories
    if [[ $found -eq 0 ]]; then
      unique_categories+=("$category")
    fi
  done
  # Sort the unique_categories array
  IFS=$"\n" unique_categories=($(sort <<<"${unique_categories[*]}"))
  unset IFS

  for category in "${unique_categories[@]}"; do
    echo "\033[1;33m$category:\033[0m"

    for i in "${!categories[@]}"; do
      if [[ "${categories[$i]}" == "$category" ]]; then
        printf "  \033[1;32m%-20s\033[0m %s\n" "${files[$i]}" "${descriptions[$i]}"
      fi
    done
    echo ""
  done

  echo "\033[1;36mTip: Use \"alias | grep <alias-prefix>\" to view detailed commands for specific aliases\033[0m"
}'
