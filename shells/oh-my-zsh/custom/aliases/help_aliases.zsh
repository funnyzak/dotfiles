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
  echo "    ${bold}curl -fsSL https://raw.gitcode.com/funnyzak/dotfiles/raw/main/shells/oh-my-zsh/tools/install_omz_aliases.sh | bash -s -- --force ALIAS_FILENAME${reset}"
  echo "    Example: ${cyan}curl -fsSL https://raw.gitcode.com/funnyzak/dotfiles/raw/main/shells/oh-my-zsh/tools/install_omz_aliases.sh | bash -s -- --force git_aliases.zsh${reset}"
  echo "  • Browse available alias files: ${blue}https://github.com/funnyzak/dotfiles/tree/main/shells/oh-my-zsh/custom/aliases${reset}"
}' # Display all available aliases with descriptions
