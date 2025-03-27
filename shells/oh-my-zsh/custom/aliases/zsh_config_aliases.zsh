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
