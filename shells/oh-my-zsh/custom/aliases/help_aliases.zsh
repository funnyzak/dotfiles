# Description: Command cheatsheet aliases for quick reference and usage.

alias cs='() {
  REMOTE_URL_PREFIX="https://raw.githubusercontent.com/funnyzak/dotfiles/refs/heads/${DOTFILES_BRANCH:-main}/"
  REMOTE_URL_PREFIX_CN="https://raw.gitcode.com/funnyzak/dotfiles/raw/${DOTFILES_BRANCH:-main}/"
  if curl -s --connect-timeout 2 "$REMOTE_URL_PREFIX_CN" >/dev/null 2>&1; then
    REMOTE_URL_PREFIX=$REMOTE_URL_PREFIX_CN
  fi
  CHEATSHEET_REMOTE_URL="${REMOTE_URL_PREFIX}utilities/shell/cheatsheet.sh"
  echo "Command cheatsheet tool.\nUsage:\n cs [command] to view specific command\n cs -l to list all supported commands"
  curl -sSL "$CHEATSHEET_REMOTE_URL" | bash -s -- "$@"
}'
