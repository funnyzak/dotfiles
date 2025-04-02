# Description: Command cheatsheet aliases for quick reference and usage.

alias cs2='() {
  local tmpfile=$(mktemp)
  curl -sSL "Https://raw.githubusercontent.com/funnyzak/cli-cheatsheets/refs/heads/${REPO_BRANCH:-main}/cheatsheet.sh" -o "$tmpfile" && chmod +x "$tmpfile" && "$tmpfile" "$@" && rm -f "$tmpfile"
}'

alias cs='() {
  echo -e "Command cheatsheet tool.\nUsage:\n cs [command] - View specific command usage\n cs -l - List all supported commands"

  # Initialize variables with local
  local remote_url_prefix="https://raw.githubusercontent.com/funnyzak/cli-cheatsheets/refs/heads/${REPO_BRANCH:-main}/"
  local remote_url_prefix_cn="https://gitee.com/funnyzak/cli-cheatsheets/raw/${REPO_BRANCH:-main}/"
  local cheatsheet_remote_url=""
  local tmpfile=""

  # Test connection to CN server with timeout to determine best URL
  if curl -s --connect-timeout 2 "$remote_url_prefix_cn" >/dev/null 2>&1; then
    cheatsheet_remote_url="${remote_url_prefix_cn}cheatsheet.sh"
  else
    cheatsheet_remote_url="${remote_url_prefix}cheatsheet.sh"
  fi

  # Handle different execution modes based on arguments
  if [ $# -eq 0 ]; then
    tmpfile=$(mktemp)
    if ! curl -sSL "$cheatsheet_remote_url" -o "$tmpfile"; then
      echo >&2 "Error: Failed to download cheatsheet script from $cheatsheet_remote_url"
      return 1
    fi

    chmod +x "$tmpfile"
    if ! "$tmpfile"; then
      echo >&2 "Error: Failed to execute cheatsheet script"
      rm -f "$tmpfile"
      return 1
    fi

    # Clean up temporary file
    rm -f "$tmpfile"
  else
    if ! curl -sSL "$cheatsheet_remote_url" | bash -s -- "$@"; then
      echo >&2 "Error: Failed to execute command \"$*\" with cheatsheet script"
      return 1
    fi
  fi
}' # Shell command cheatsheet tool

alias aliases-help='() {
  # Define colors
  local reset="\033[0m"
  local bold="\033[1m"
  local cyan="\033[36m"
  local green="\033[32m"
  local yellow="\033[33m"
  local blue="\033[34m"
  local magenta="\033[35m"
  local red="\033[31m"

  echo "${bold}List available aliases and their descriptions.${reset}"
  echo "${yellow}Usage:${reset}"
  echo "  ${green}aliases-help${reset}     - List all aliases"
  echo "  ${green}aliases-help -v${reset}  - Show verbose output"

  local aliases_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/aliases"
  local verbose=false

  # Parse arguments
  local OPTIND=1
  while getopts ":v" opt; do
    case "$opt" in
      v) verbose=true ;;
      \?) echo "${red}Invalid option: -$OPTARG${reset}"; return 1 ;;
    esac
  done
  shift $((OPTIND-1))

  # Print verbose information if requested
  if $verbose; then
    echo "${blue}[DEBUG] Starting aliases-help with verbose output${reset}"
    echo "${blue}[DEBUG] Aliases directory: $aliases_dir${reset}"
  fi

  # Check if aliases directory exists
  if [ ! -d "$aliases_dir" ]; then
    echo "${red}Error: Aliases directory \"$aliases_dir\" does not exist${reset}"
    return 1
  fi

  echo ""
  echo "${bold}${cyan}===== Available Aliases =====${reset}"
  echo ""

  # Find all alias files and process them
  find "$aliases_dir" -type f -name "*_aliases.zsh" | sort | while read -r alias_file; do
    if $verbose; then
      echo "${blue}[DEBUG] Processing file: $alias_file${reset}"
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
    printf "  ${magenta}%-20s${reset} %s\n" "$name" "$desc"
  done

  echo ""
  echo "${yellow}\nNotes:${reset}"
  echo "  • View specific alias definitions: ${bold}less $ZSH_CUSTOM/aliases/ALIAS_NAME_aliases.zsh${reset}"
  echo "    For example: ${bold}less $ZSH_CUSTOM/aliases/git_aliases.zsh${reset}"
  echo "  • ${green}Download more alias files:${reset} "
  echo "    ${bold}curl -fsSL https://gitee.com/funnyzak/dotfiless/raw/main/shells/oh-my-zsh/tools/install_omz_aliases.sh | bash -s -- --force ALIAS_FILENAME${reset}"
  echo "    Example: ${cyan}curl -fsSL https://gitee.com/funnyzak/dotfiless/raw/main/shells/oh-my-zsh/tools/install_omz_aliases.sh | bash -s -- --force git_aliases.zsh${reset}"
  echo "  • Browse available alias files: ${blue}https://github.com/funnyzak/dotfiles/tree/main/shells/oh-my-zsh/custom/aliases${reset}"
}' # Display all available aliases with descriptions
