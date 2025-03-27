# Description: Zsh configuration related aliases for managing oh-my-zsh and shell configuration.

# Oh-My-Zsh Management
alias omz='omz' # Oh-My-Zsh command
alias omzupdate='omz update' # Update Oh-My-Zsh

# Zsh Configuration Management
alias zshconfig='mate ~/.zshrc' # Edit ~/.zshrc in Mate text editor
alias zshrc='source ~/.zshrc' # Source ~/.zshrc to reload configuration
alias zshconfigp='less ~/.zshrc' # View ~/.zshrc in less
alias ohmyzsh='mate ~/.oh-my-zsh' # Edit ~/.oh-my-zsh directory in Mate text editor
alias asg='(){ echo "Search alias.\nUsage:\n asg <alias_name>"; alias_name=${@}; alias | grep $alias_name;}' # Search for aliases

alias install_omz_aliases='() {
  REMOTE_URL_PREFIX="https://raw.githubusercontent.com/funnyzak/dotfiles/refs/heads/main/"
  REMOTE_URL_PREFIX_CN="https://raw.gitcode.com/funnyzak/dotfiles/raw/main/"
  if curl -s --connect-timeout 2 "$REMOTE_URL_PREFIX_CN" >/dev/null 2>&1; then
    REMOTE_URL_PREFIX=$REMOTE_URL_PREFIX_CN
  fi
  echo "Installing oh-my-zsh alias files from remote repository."
  echo "Using remote URL: $REMOTE_URL_PREFIX"
  curl -fsSL "${REMOTE_URL_PREFIX}shells/oh-my-zsh/tools/install_omz_aliases.sh" | bash -s -- "$@"
}' # Install oh-my-zsh alias files from a remote repository (Linux/macOS)
