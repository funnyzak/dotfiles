# Description: Homebrew related aliases for package management on macOS.

# Helper function for Homebrew commands
_brew_command_brew_aliases() {
  local cmd="$1"
  shift

  if ! command -v brew >/dev/null 2>&1; then
    echo "Error: Homebrew is not installed or not in PATH." >&2
    return 1
  fi

  brew "$cmd" "$@"
  local exit_code=$?
  if [ $exit_code -ne 0 ]; then
    echo "Error: Homebrew command 'brew $cmd' failed with exit code $exit_code." >&2
    return $exit_code
  fi
  return 0
}

alias brewup='() {
  echo -e "Cleanup and doctor check for Homebrew.\nUsage:\n brewup"

  echo "Running brew cleanup..."
  if ! _brew_command_brew_aliases cleanup; then
    echo "Error: Homebrew cleanup failed." >&2
    return 1
  fi

  echo "Running brew doctor..."
  if ! _brew_command_brew_aliases doctor; then
    echo "Warning: Homebrew doctor reported issues. Review the output above." >&2
    # Continue execution as doctor warnings are often non-fatal
  fi

  echo "Homebrew cleanup and doctor check completed successfully"
}' # Cleanup and doctor check for Homebrew

alias brewupg='() {
  echo -e "Update and upgrade Homebrew packages.\nUsage:\n brewupg"

  echo "Updating Homebrew..."
  if ! _brew_command_brew_aliases update; then
    echo "Error: Homebrew update failed." >&2
    return 1
  fi

  echo "Upgrading Homebrew packages..."
  if ! _brew_command_brew_aliases upgrade; then
    echo "Error: Homebrew upgrade failed." >&2
    return 1
  fi

  echo "Homebrew update and upgrade completed successfully"
}' # Update and upgrade Homebrew packages

alias brewi='() {
  echo -e "Install Homebrew packages.\nUsage:\n brewi <package1> [package2...]"

  if [ $# -eq 0 ]; then
    echo "Error: No packages specified for installation." >&2
    return 1
  fi

  echo "Installing Homebrew packages: $*"
  if ! _brew_command_brew_aliases install "$@"; then
    echo "Error: Failed to install one or more packages." >&2
    return 1
  fi

  echo "Homebrew packages installed successfully: $*"
}' # Install Homebrew packages

alias brewu='() {
  echo -e "Uninstall Homebrew packages.\nUsage:\n brewu <package1> [package2...]"

  if [ $# -eq 0 ]; then
    echo "Error: No packages specified for uninstallation." >&2
    return 1
  fi

  echo "Uninstalling Homebrew packages: $*"
  if ! _brew_command_brew_aliases uninstall "$@"; then
    echo "Error: Failed to uninstall one or more packages." >&2
    return 1
  fi

  echo "Homebrew packages uninstalled successfully: $*"
}' # Uninstall Homebrew packages

alias brewls='() {
  echo -e "List installed Homebrew packages.\nUsage:\n brewls [pattern]"

  if [ $# -eq 0 ]; then
    if ! _brew_command_brew_aliases list; then
      echo "Error: Failed to list installed packages." >&2
      return 1
    fi
  else
    if ! _brew_command_brew_aliases list "$@"; then
      echo "Error: Failed to list packages matching pattern." >&2
      return 1
    fi
  fi
}' # List installed Homebrew packages

alias brewsrch='() {
  echo -e "Search for Homebrew packages.\nUsage:\n brewsrch <search_term>"

  if [ $# -eq 0 ]; then
    echo "Error: No search term provided." >&2
    return 1
  fi

  echo "Searching for Homebrew packages matching: $1"
  if ! _brew_command_brew_aliases search "$1"; then
    echo "Error: Search operation failed." >&2
    return 1
  fi
}' # Search for Homebrew packages

alias brewinfo='() {
  echo -e "Show information about Homebrew packages.\nUsage:\n brewinfo <package>"

  if [ $# -eq 0 ]; then
    echo "Error: No package specified." >&2
    return 1
  fi

  echo "Showing information for Homebrew package: $1"
  if ! _brew_command_brew_aliases info "$1"; then
    echo "Error: Failed to retrieve package information." >&2
    return 1
  fi
}' # Show information about Homebrew packages
