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
  local remote_url="https://raw.githubusercontent.com/funnyzak/dotfiles/refs/heads/main/"
  curl -fsSL "${remote_url}shells/oh-my-zsh/tools/install_omz_aliases.sh" | bash -s -- "$@"
}' # Install oh-my-zsh alias files from a remote repository (Linux/macOS)

alias install_omz_aliases_cn='() {
  echo "Installing oh-my-zsh alias files from China mirror."
  echo "You can speed up the download using China mirrors."
  echo "Usage: export CN=true; install_omz_aliases_cn"
  local remote_url="https://raw.gitcode.com/funnyzak/dotfiles/raw/main/"
  curl -fsSL "${remote_url}shells/oh-my-zsh/tools/install_omz_aliases.sh" | bash -s -- "$@"
}' # Install oh-my-zsh alias files from a remote repository (China)
