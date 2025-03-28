# Description: Zsh configuration related aliases for managing oh-my-zsh and shell configuration.

# Oh-My-Zsh Management
alias omz-update='() {
  echo "Updating Oh-My-Zsh..."
  if ! omz update; then
    echo "Error: Failed to update Oh-My-Zsh" >&2
    return 1
  fi
  echo "Oh-My-Zsh updated successfully"
}'

alias omz-deps='() {
  echo "Install dependencies required by shell aliases."
  echo "Usage:"
  echo " omz-deps [--force]"

  local force=false

  # Process arguments
  for arg in "$@"; do
    case "$arg" in
      --force)
        force=true
        ;;
      *)
        echo "Error: Unknown option: $arg" >&2
        echo "Usage: omz-deps [--force]" >&2
        return 1
        ;;
    esac
  done

  # Define dependencies
  local common_deps="wget nmap openssl imagemagick youtube-dl jq"
  local macos_deps="$common_deps gh coreutils apprise"
  local linux_deps="$common_deps github-cli coreutils apprise"

  # Install based on OS
  if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "Using Homebrew to install dependencies"
    if ! command -v brew >/dev/null 2>&1; then
      echo "Error: Homebrew not found. Please install Homebrew first: https://brew.sh" >&2
      return 1
    fi
    
    echo "Installing: $macos_deps"
    if ! brew install $macos_deps; then
      echo "Error: Failed to install dependencies via Homebrew" >&2
      return 1
    fi
    echo "Dependencies successfully installed via Homebrew"
  elif [[ "$(uname -s)" == "Linux" ]]; then
    # Check for common package managers
    if command -v apt-get >/dev/null 2>&1; then
      local pkg_manager="apt-get"
      local install_cmd="sudo apt-get install -y"
    elif command -v yum >/dev/null 2>&1; then
      local pkg_manager="yum"
      local install_cmd="sudo yum install -y"
    elif command -v dnf >/dev/null 2>&1; then
      local pkg_manager="dnf"
      local install_cmd="sudo dnf install -y"
    elif command -v pacman >/dev/null 2>&1; then
      local pkg_manager="pacman"
      local install_cmd="sudo pacman -S --noconfirm"
    else
      echo "Error: No supported package manager found" >&2
      echo "Please install these dependencies manually: $linux_deps" >&2
      return 1
    fi
    
    # Confirm installation or use force flag
    if [ "$force" = false ]; then
      echo "This will install the following packages using $pkg_manager:"
      echo "$linux_deps"
      read -r -p "Continue? [y/N] " response
      if [[ ! "$response" =~ ^[yY]$ ]]; then
        echo "Installation cancelled"
        return 0
      fi
    fi
    
    echo "Installing dependencies using $pkg_manager..."
    if ! $install_cmd $linux_deps; then
      echo "Error: Failed to install some dependencies" >&2
      echo "You may need to install missing packages manually" >&2
      return 1
    fi
    echo "Dependencies successfully installed"
  else
    echo "Error: Unsupported operating system: $(uname -s)" >&2
    echo "Please install these dependencies manually: $common_deps" >&2
    return 1
  fi
  
  # Verify installations
  echo "Verifying installations..."
  local missing_deps=""
  for dep in $common_deps; do
    if ! command -v $dep >/dev/null 2>&1; then
      missing_deps="$missing_deps $dep"
    fi
  done
  
  if [ -n "$missing_deps" ]; then
    echo "Warning: Some dependencies could not be verified: $missing_deps" >&2
    echo "You may need to install them manually or check your PATH" >&2
  else
    echo "All dependencies successfully installed and verified"
  fi
}' # Install dependencies required by shell aliases

# Zsh Configuration Management
alias omz-reload='() {
  echo "Reloading Zsh configuration..."
  if ! source ~/.zshrc; then
    echo "Error: Failed to reload Zsh configuration" >&2
    return 1
  fi
  echo "Zsh configuration reloaded successfully"
}'

alias omz-view='() {
  echo "Viewing ~/.zshrc..."
  if ! less ~/.zshrc; then
    echo "Error: Failed to view ~/.zshrc" >&2
    return 1
  fi
}'

alias omz-edit='() {
  echo "Editing ~/.oh-my-zsh..."
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

alias omz-uninstall='() {
  echo "Uninstall Oh-My-Zsh from your system."
  echo "Usage:"
  echo " omz-uninstall [-f|--force]"

  local force=false

  # Process arguments
  for arg in "$@"; do
    case "$arg" in
      -f|--force)
        force=true
        ;;
      *)
        echo "Error: Unknown option: $arg" >&2
        echo "Usage: omz-uninstall [-f|--force]" >&2
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

alias omz-aedit='() {
  echo "Edit or create an alias script file in Oh-My-Zsh custom aliases directory."
  echo "Usage:"
  echo " omz-aedit <alias_file_name>"

  if [ -z "$1" ]; then
    echo "Error: Missing alias file name parameter" >&2
    return 1
  fi

  local alias_name="$1"
  local alias_dir="$HOME/.oh-my-zsh/custom/aliases"
  local alias_file="${alias_dir}/${alias_name}_aliases.zsh"

  if [ ! -d "$alias_dir" ]; then
    echo "Error: Custom aliases directory not found: $alias_dir" >&2
  fi

  # Determine editor to use
  local editor="${EDITOR:-nano}"

  # Check if file exists
  if [ -f "$alias_file" ]; then
    echo "Opening existing alias file: $alias_file"
  else
    echo "Creating new alias file: $alias_file"
    # Create default template for new file
    echo "# Description: ${alias_name^} related aliases." > "$alias_file"
    echo "" >> "$alias_file"
    echo "# Add your ${alias_name} aliases below" >> "$alias_file"
    echo "" >> "$alias_file"
  fi

  # Open the file in editor
  if ! "$editor" "$alias_file"; then
    echo "Error: Failed to open $alias_file with $editor" >&2
    return 1
  fi

  echo "Alias file edited successfully. Run 'zreload' to apply changes."
}' # Edit or create an alias script file in Oh-My-Zsh custom aliases directory

alias omz-remove-custom-aliases='() {
  local aliases_dir="$HOME/.oh-my-zsh/custom/aliases"

  echo "Remove custom aliases from Oh-My-Zsh"

  # Check if aliases directory exists
  if [ ! -d "$aliases_dir" ]; then
    echo "Error: Custom aliases directory does not exist: $aliases_dir" >&2
    return 1
  fi

  # Count number of alias files
  local file_count=$(find "$aliases_dir" -type f -name "*_aliases.zsh" | wc -l | tr -d " ")
  echo "Found $file_count alias file(s) in $aliases_dir"

  # Ask for confirmation
  echo -n "Are you sure you want to remove all custom aliases? [y/N] "
  read -r confirmation
  if [[ ! "$confirmation" =~ ^[yY]$ ]]; then
    echo "Operation cancelled"
    return 0
  fi

  # # Create backup before removal
  # local backup_dir="$HOME/.oh-my-zsh-aliases-backup-$(date +%Y%m%d%H%M%S)"
  # echo "Creating backup in $backup_dir"
  # if ! cp -r "$aliases_dir" "$backup_dir"; then
  #   echo "Warning: Failed to create backup, proceeding anyway" >&2
  # fi

  # Remove directory
  echo "Removing custom aliases directory: $aliases_dir"
  if rm -rf "$aliases_dir"; then
    echo "Custom aliases removed successfully"
    # echo "Backup saved to $backup_dir"
    echo "Run 'omz-reload' to apply changes"
  else
    echo "Error: Failed to remove $aliases_dir" >&2
    return 1
  fi
}' # Remove custom aliases from Oh-My-Zsh

alias omz-clear-empty-aliases='() {
  local aliases_dir="$HOME/.oh-my-zsh/custom/aliases"

  echo "Clear empty alias files from Oh-My-Zsh"

  # Check if aliases directory exists
  if [ ! -d "$aliases_dir" ]; then
    echo "Error: Custom aliases directory does not exist: $aliases_dir" >&2
    return 1
  fi

  # Find and remove empty files
  local empty_files=$(find "$aliases_dir" -type f -size 0)
  if [ -z "$empty_files" ]; then
    echo "No empty alias files found in $aliases_dir"
    return 0
  fi

  # Ask for confirmation
  echo "Found empty alias files:"
  echo "$empty_files"
  echo -n "Are you sure you want to remove all empty alias files? [y/N] "
  read -r confirmation
  if [[ ! "$confirmation" =~ ^[yY]$ ]]; then
    echo "Operation cancelled"
    return 0
  fi
  # Remove empty files
  echo "Removing empty alias files..."
  if rm -f $empty_files; then
    echo "Empty alias files removed successfully"
    echo "Run 'omz-reload' to apply changes"
  else
    echo "Error: Failed to remove empty alias files" >&2
    return 1
  fi
}' # Clear empty alias files from Oh-My-Zsh
