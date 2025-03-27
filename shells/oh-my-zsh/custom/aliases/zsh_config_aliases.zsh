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
  echo "Installing oh-my-zsh alias files from remote repository."
  local remote_prefix="https://raw.githubusercontent.com/funnyzak/dotfiles/refs/heads/main/"
  local remote_prefix_CN="https://raw.gitcode.com/funnyzak/dotfiles/raw/main/"
  if [[ "$1" == *"CN"* || "$1" == *"cn"* ]]; then
    remote_prefix="${remote_prefix_CN}"
    shift
  fi
  echo "Using remote URL: $remote_prefix"
  curl -fsSL "${remote_prefix}shells/oh-my-zsh/tools/install_omz_aliases.sh" | bash -s -- "$@"
}' # Install oh-my-zsh alias files from a remote repository (Linux/macOS)
