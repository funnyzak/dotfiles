# Description: Zsh configuration related aliases for managing oh-my-zsh and shell configuration.

# Oh-My-Zsh Management
alias omz='omz' # Oh-My-Zsh command
alias omzupdate='() {
  echo "Updating Oh-My-Zsh..."
  if ! omz update; then
    echo "Error: Failed to update Oh-My-Zsh" >&2
    return 1
  fi
  echo "Oh-My-Zsh updated successfully"
}'

# Zsh Configuration Management
alias zedit='() {
  if [ -z "$EDITOR" ]; then
    EDITOR="nano"
  fi
  echo "Opening ~/.zshrc in $EDITOR"
  $EDITOR ~/.zshrc
}'

alias zreload='() {
  echo "Reloading Zsh configuration..."
  if ! source ~/.zshrc; then
    echo "Error: Failed to reload Zsh configuration" >&2
    return 1
  fi
  echo "Zsh configuration reloaded successfully"
}'

alias zview='() {
  echo "Viewing ~/.zshrc..."
  if ! less ~/.zshrc; then
    echo "Error: Failed to view ~/.zshrc" >&2
    return 1
  fi
}'

alias ohmyedit='() {
  if [ -z "$EDITOR" ]; then
    EDITOR="nano"
  fi
  echo "Opening ~/.oh-my-zsh in $EDITOR"
  $EDITOR ~/.oh-my-zsh
}'

alias asearch='() {
  if [ -z "$1" ]; then
    echo "Search for aliases by pattern" >&2
    echo "Usage: asearch <pattern>" >&2
    return 1
  fi

  local pattern="$1"
  echo "Searching for aliases matching \"$pattern\"..."
  local results=$(alias | grep -i "$pattern")

  if [ -z "$results" ]; then
    echo "No aliases found matching \"$pattern\"" >&2
    return 1
  fi

  echo "$results"
}'

alias zuninstall='() {
  echo "Uninstall Oh-My-Zsh from your system."
  echo "Usage:"
  echo " zuninstall [-f|--force]"

  local force=false

  # Process arguments
  for arg in "$@"; do
    case "$arg" in
      -f|--force)
        force=true
        ;;
      *)
        echo "Error: Unknown option: $arg" >&2
        echo "Usage: zuninstall [-f|--force]" >&2
        return 1
        ;;
    esac
  done

  # Check if Oh-My-Zsh is installed
  if [ ! -d "$ZSH" ] || [ ! -f "$ZSH/oh-my-zsh.sh" ]; then
    echo "Error: Oh-My-Zsh does not appear to be installed" >&2
    return 1
  fi

  # Handle shell restoration
  if hash chsh >/dev/null 2>&1 && [ -f ~/.shell.pre-oh-my-zsh ]; then
    old_shell=$(cat ~/.shell.pre-oh-my-zsh)
    echo "Switching your shell back to '$old_shell':"
    if chsh -s "$old_shell"; then
      rm -f ~/.shell.pre-oh-my-zsh
    else
      echo "Could not change default shell. Change it manually by running chsh"
      echo "or editing the /etc/passwd file."
      return 1
    fi
  fi

  # Confirmation unless force flag is present
  if [ "$force" = false ]; then
    read -r -p "Are you sure you want to remove Oh My Zsh? [y/N] " confirmation
    if [ "$confirmation" != y ] && [ "$confirmation" != Y ]; then
      echo "Uninstall cancelled"
      return 0
    fi
  fi

  echo "Removing ~/.oh-my-zsh"
  if [ -d ~/.oh-my-zsh ]; then
    rm -rf ~/.oh-my-zsh
  fi

  # Backup current .zshrc
  if [ -e ~/.zshrc ]; then
    ZSHRC_SAVE=~/.zshrc.omz-uninstalled-$(date +%Y-%m-%d_%H-%M-%S)
    echo "Found ~/.zshrc -- Renaming to ${ZSHRC_SAVE}"
    mv ~/.zshrc "${ZSHRC_SAVE}"
  fi

  # Restore original zshrc if exists
  echo "Looking for original zsh config..."
  ZSHRC_ORIG=~/.zshrc.pre-oh-my-zsh
  if [ -e "$ZSHRC_ORIG" ]; then
    echo "Found $ZSHRC_ORIG -- Restoring to ~/.zshrc"
    mv "$ZSHRC_ORIG" ~/.zshrc
    echo "Your original zsh config was restored."
  else
    echo "No original zsh config found"
  fi

  echo "Thanks for trying out Oh My Zsh. It's been uninstalled."
  echo "Don't forget to restart your terminal!"
  return 0
}'
