# Description: Homebrew related aliases for package management on macOS.

alias brewup='() { 
  echo "Cleanup and doctor check for Homebrew.\nUsage:\n brewup"
  echo "Running brew cleanup and doctor..."
  brew cleanup && brew doctor && 
  echo "Homebrew cleanup and doctor check completed"
}' # Cleanup and doctor check for Homebrew

alias brewupg='() { 
  echo "Update and upgrade Homebrew packages.\nUsage:\n brewupg"
  echo "Updating Homebrew and upgrading packages..."
  brew update && brew upgrade && 
  echo "Homebrew update and upgrade completed"
}' # Update and upgrade Homebrew packages

alias brewi='() { 
  if [ $# -eq 0 ]; then
    echo "Install Homebrew packages.\nUsage:\n brewi <package1> [package2...]"
    return 1
  fi
  echo "Installing Homebrew packages: $@"
  brew install $@ && 
  echo "Homebrew packages installed: $@"
}' # Install Homebrew packages

alias brewu='() { 
  if [ $# -eq 0 ]; then
    echo "Uninstall Homebrew packages.\nUsage:\n brewu <package1> [package2...]"
    return 1
  fi
  echo "Uninstalling Homebrew packages: $@"
  brew uninstall $@ && 
  echo "Homebrew packages uninstalled: $@"
}' # Uninstall Homebrew packages

alias brewls='() { 
  echo "List installed Homebrew packages.\nUsage:\n brewls"
  brew list
}' # List installed Homebrew packages

alias brewsrch='() { 
  if [ $# -eq 0 ]; then
    echo "Search for Homebrew packages.\nUsage:\n brewsrch <search_term>"
    return 1
  fi
  echo "Searching for Homebrew packages matching: $1"
  brew search $1
}' # Search for Homebrew packages

alias brewinfo='() { 
  if [ $# -eq 0 ]; then
    echo "Show information about Homebrew packages.\nUsage:\n brewinfo <package>"
    return 1
  fi
  echo "Showing information for Homebrew package: $1"
  brew info $1
}' # Show information about Homebrew packages