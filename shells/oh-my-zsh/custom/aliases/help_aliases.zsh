alias cs='() {
  CHEATSHEET_REMOTE_URL="https://raw.githubusercontent.com/funnyzak/dotfiles/main/utilities/shell/cheatsheet.sh"
  echo "Command cheatsheet tool.\nUsage:\n cheatsheet [command] to view specific command\n cheatsheet -l to list all supported commands"
  curl -sSL "$CHEATSHEET_REMOTE_URL" | bash -s -- "$@"
}'

alias cn_cs='() {
  CHEATSHEET_REMOTE_URL="https://raw.gitcode.com/funnyzak/dotfiles/raw/main/utilities/shell/cheatsheet.sh"
  echo "Command cheatsheet tool.\nUsage:\n cheatsheet [command] to view specific command\n cheatsheet -l to list all supported commands"
  curl -sSL "$CHEATSHEET_REMOTE_URL" | bash -s -- "$@"
}'
