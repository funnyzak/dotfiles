# Description: Other useful aliases for various tasks.

alias install_omz_aliases='() {
  local remote_url="https://raw.githubusercontent.com/funnyzak/dotfiles/refs/heads/main/"
  if [[ "$CN" == "true" ]]; then
    remote_url = "https://raw.gitcode.com/funnyzak/dotfiles/raw/main/"
  fi
  curl -fsSL "${remote_url}shells/oh-my-zsh/tools/install_omz_aliases.sh" | bash -s -- "$@"
}' # Install oh-my-zsh alias files from a remote repository (Linux/macOS)
