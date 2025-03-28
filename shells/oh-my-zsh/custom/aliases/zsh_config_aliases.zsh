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
  local alias_dir="${ZSH:-$HOME/.oh-my-zsh}/custom/aliases"
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
}'

alias omz-adel='() {
  echo "Delete custom alias files from Oh-My-Zsh custom aliases directory."
  echo "Usage:"
  echo " omz-adel [-i|--interactive] [-a|--all] [file_name1 file_name2 ...]"
  echo ""
  echo "Options:"
  echo "  -i, --interactive   Interactive mode for selection"
  echo "  -a, --all           Delete all alias files"
  echo "  file_name           File name(s) without _aliases.zsh extension"

  local aliases_dir="${ZSH:-$HOME/.oh-my-zsh}/custom/aliases"
  local interactive=false
  local delete_all=false
  local files_to_delete=()

  # Check if aliases directory exists
  if [ ! -d "$aliases_dir" ]; then
    echo "Error: Custom aliases directory not found: $aliases_dir" >&2
    return 1
  fi

  # No arguments provided
  if [ $# -eq 0 ]; then
    echo "Error: No action specified. Use -i for interactive mode, -a for all files, or provide file names." >&2
    return 1
  fi

  # Process arguments
  while [ $# -gt 0 ]; do
    case "$1" in
      -i|--interactive)
        interactive=true
        shift
        ;;
      -a|--all)
        delete_all=true
        shift
        ;;
      -*)
        echo "Error: Unknown option: $1" >&2
        return 1
        ;;
      *)
        files_to_delete+=("$1")
        shift
        ;;
    esac
  done

  # Interactive mode
  if [ "$interactive" = true ]; then
    echo "Available alias files:"
    local all_files=($(find "$aliases_dir" -name "*_aliases.zsh" -type f -exec basename {} \; | sort))

    if [ ${#all_files[@]} -eq 0 ]; then
      echo "No alias files found in $aliases_dir" >&2
      return 1
    fi

    local i=1
    for file in "${all_files[@]}"; do
      # Strip _aliases.zsh suffix for display
      local display_name="${file%_aliases.zsh}"
      echo "[$i] $display_name"
      ((i++))
    done

    echo ""
    echo "Enter numbers to delete (space-separated), or 'q' to quit:"
    read -r selection

    if [[ "$selection" == "q" ]]; then
      echo "Operation cancelled."
      return 0
    fi

    for num in $selection; do
      if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le ${#all_files[@]} ]; then
        local file_index=$((num - 1))
        local file_path="$aliases_dir/${all_files[$file_index]}"
        local file_name="${all_files[$file_index]%_aliases.zsh}"

        echo "Deleting $file_name..."
        if ! rm "$file_path"; then
          echo "Error: Failed to delete $file_path" >&2
        fi
      else
        echo "Warning: Invalid selection '$num' - skipping" >&2
      fi
    done

  # Delete all files
  elif [ "$delete_all" = true ]; then
    echo "WARNING: This will delete ALL custom alias files!"
    echo "Are you sure? (y/N)"
    read -r confirm

    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
      echo "Deleting all alias files..."
      local count=0
      for file in "$aliases_dir"/*_aliases.zsh; do
        if [ -f "$file" ]; then
          if rm "$file"; then
            ((count++))
          else
            echo "Error: Failed to delete $file" >&2
          fi
        fi
      done

      if [ $count -eq 0 ]; then
        echo "No alias files found to delete."
      else
        echo "$count alias files deleted successfully."
      fi
    else
      echo "Operation cancelled."
      return 0
    fi

  # Delete specific files
  elif [ ${#files_to_delete[@]} -gt 0 ]; then
    local success_count=0
    local error_count=0

    for name in "${files_to_delete[@]}"; do
      local file_path="$aliases_dir/${name}_aliases.zsh"

      if [ -f "$file_path" ]; then
        echo "Deleting $name..."
        if rm "$file_path"; then
          ((success_count++))
        else
          echo "Error: Failed to delete $name" >&2
          ((error_count++))
        fi
      else
        echo "Error: File not found: $file_path" >&2
        ((error_count++))
      fi
    done

    echo "$success_count file(s) deleted successfully, $error_count error(s)."
  fi

  echo "Run 'zreload' to apply changes."
  return 0
}'
