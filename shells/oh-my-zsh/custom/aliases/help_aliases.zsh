# Description: This script defines a set of aliases for quickly accessing various cheat sheets and help documents using curl and less.

alias cheatsheet='() {
  CHEATSHEET_REMOTE_URL="https://raw.githubusercontent.com/funnyzak/dotfiles/main/utilities/shell/cheatsheet.sh"
  CN_CHEATSHEET_REMOTE_URL="https://raw.gitcode.com/funnyzak/dotfiles/raw/main/utilities/shell/cheatsheet.sh"

  if [[ -n "$CN" ]]; then
    CHEATSHEET_REMOTE_URL="$CN_CHEATSHEET_REMOTE_URL"
  fi

  echo "Command cheatsheet tool.\nUsage:\n cheatsheet [command] to view specific command\n cheatsheet -l to list all supported commands"

  if [[ $# -eq 0 ]]; then
    curl -sSL "$CHEATSHEET_REMOTE_URL" | bash
  else
    curl -sSL "$CHEATSHEET_REMOTE_URL" | bash -s -- "$@"
  fi
}' # Command cheatsheet tool
