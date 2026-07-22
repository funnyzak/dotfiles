# Description: macOS specific aliases for system management and software installation

# Mac system tools and software installation
alias mac-install-essential='() {
  echo -e "Install essential macOS software via Homebrew.\nUsage:\n mac-install-essential"

  # Check if Homebrew is installed
  if ! command -v brew &> /dev/null; then
    echo "Homebrew is not installed. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [ $? -ne 0 ]; then
      echo "Failed to install Homebrew. Please check your internet connection and try again." >&2
      return 1
    fi
  else
    echo "Homebrew is already installed."
  fi

  local casks=("hiddenbar" "devtoys" "textmate" "ipatool" "flipper" "libreoffice" "pdfsam-basic" "studio-3t" "imagej" "vlc" "oss-browser" "postman" "raycast" "dotnet-sdk")
  local formulae=("whois" "apprise" "ansible" "pipx" "rclone" "watch" "caddy" "wget" "git" "cocoapods" "pyenv" "ffmpeg" "imagemagick" "tree" "findutils" "minio/stable/mc" "maven" "docker" "lazydocker" "htop" "btop" "yt-dlp" "fd" "ghostscript" "golang" "rust" "goreleaser" "serve" "autojump" "jq" "gh" "frpc" "nvm" "pandoc" "openjdk@11" "openjdk@17")

  # Install Casks
  echo "Installing Casks..."
  for cask in "${casks[@]}"; do
    if ! brew list --cask "$cask" &> /dev/null; then
      echo "Installing $cask..."
      brew install --cask "$cask"
      if [ $? -ne 0 ]; then
        echo "Failed to install $cask. Continuing with next package..." >&2
      fi
    else
      echo "$cask is already installed. Skipping..."
    fi
  done

  # Install Formulae
  echo "Installing Formulae..."
  for formula in "${formulae[@]}"; do
    if ! brew list "$formula" &> /dev/null; then
      echo "Installing $formula..."
      brew install "$formula"
      if [ $? -ne 0 ]; then
        echo "Failed to install $formula. Continuing with next package..." >&2
      fi
    else
      echo "$formula is already installed. Skipping..."
    fi
  done

  echo "Software installation completed."
}' # Install essential macOS software via Homebrew

alias mac-install-node='() {
  echo -e "Install Node.js and npm packages.\nUsage:\n mac-install-node"

  # Check if Node.js/npm is installed
  if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
    echo "Node.js or npm is not installed. Installing Node.js..."
    brew install node
    if [ $? -ne 0 ]; then
      echo "Failed to install Node.js. Please check Homebrew and try again." >&2
      return 1
    fi
  else
    echo "Node.js and npm are already installed."
  fi

  local npm_packages=("pushoo-cli" "pake" "fpdf2pic" "picgo" "prettier" "rimraf" "npm-check-updates" "eslint" "typescript" "@vscode/vsce" "@githubnext/github-copilot-cli")

  # Install npm packages
  echo "Installing npm packages..."
  for package in "${npm_packages[@]}"; do
    if ! npm list -g "$package" &> /dev/null; then
      echo "Installing $package..."
      npm install -g "$package"
      if [ $? -ne 0 ]; then
        echo "Failed to install $package. Continuing with next package..." >&2
      fi
    else
      echo "$package is already installed. Skipping..."
    fi
  done

  echo "Node.js packages installation completed."
}' # Install Node.js and npm packages

alias mac-install-python='() {
  echo -e "Install Python packages.\nUsage:\n mac-install-python"

  # Check if pip3 is installed
  if ! command -v pip3 &> /dev/null; then
    echo "pip3 is not installed. Installing Python3 and pip..."
    brew install python3
    if [ $? -ne 0 ]; then
      echo "Failed to install Python3. Please check Homebrew and try again." >&2
      return 1
    fi
  else
    echo "pip3 is already installed."
  fi

  # Install uv (Python package installer)
  if ! command -v uv &> /dev/null; then
    echo "Installing uv (Python package manager)..."
    brew install uv
    if [ $? -ne 0 ]; then
      echo "Failed to install uv. Please check Homebrew and try again." >&2
    else
      echo "uv successfully installed."
    fi
  else
    echo "uv is already installed."
  fi

  local pip_packages=("ansible")

  # Install pip packages
  echo "Installing pip packages..."
  for package in "${pip_packages[@]}"; do
    if ! pip3 list | grep "$package" &> /dev/null; then
      echo "Installing $package..."
      pip3 install "$package"
      if [ $? -ne 0 ]; then
        echo "Failed to install $package. Continuing with next package..." >&2
      fi
    else
      echo "$package is already installed. Skipping..."
    fi
  done

  echo "Python packages installation completed."
}' # Install Python packages

alias mac-setup-all='() {
  echo -e "Setup all essential macOS software, Node.js and Python packages.\nUsage:\n mac-setup-all"

  mac-install-essential
  local essential_result=$?

  mac-install-node
  local node_result=$?

  mac-install-python
  local python_result=$?

  echo "Setup completed with exit codes: Essential=$essential_result, Node=$node_result, Python=$python_result"

  if [[ $essential_result -ne 0 || $node_result -ne 0 || $python_result -ne 0 ]]; then
    echo "Some installations had errors. Please check the output above." >&2
    return 1
  fi

  echo "All software has been successfully installed."
}' # Setup all essential macOS software and packages

alias mac-brew-update='() {
  echo -e "Update all Homebrew packages, casks, and formulae.\nUsage:\n mac-brew-update"

  if ! command -v brew &> /dev/null; then
    echo "Homebrew is not installed. Please install Homebrew first." >&2
    return 1
  fi

  echo "Updating Homebrew..."
  brew update
  if [ $? -ne 0 ]; then
    echo "Failed to update Homebrew. Please check your internet connection." >&2
    return 1
  fi

  echo "Upgrading all packages..."
  brew upgrade
  if [ $? -ne 0 ]; then
    echo "Some packages failed to upgrade. Check the output for details." >&2
    return 1
  fi

  echo "Cleaning up..."
  brew cleanup

  echo "Homebrew update completed successfully."
}' # Update all Homebrew packages

alias mac-brew-doctor='() {
  echo -e "Run Homebrew diagnostics.\nUsage:\n mac-brew-doctor"

  if ! command -v brew &> /dev/null; then
    echo "Homebrew is not installed. Please install Homebrew first." >&2
    return 1
  fi

  echo "Running Homebrew diagnostics..."
  brew doctor
  local doctor_result=$?

  if [ $doctor_result -eq 0 ]; then
    echo "Homebrew is healthy!"
  else
    echo "Homebrew reported some issues. Please review the output above." >&2
  fi

  return $doctor_result
}' # Run Homebrew diagnostics

alias mac-brew-list='() {
  echo -e "List all installed Homebrew packages.\nUsage:\n mac-brew-list [--casks|--formulae]"

  if ! command -v brew &> /dev/null; then
    echo "Homebrew is not installed. Please install Homebrew first." >&2
    return 1
  fi

  if [[ "$1" == "--casks" ]]; then
    echo "Installed Casks:"
    brew list --cask
  elif [[ "$1" == "--formulae" ]]; then
    echo "Installed Formulae:"
    brew list --formula
  else
    echo "Installed Casks:"
    brew list --cask
    echo -e "\nInstalled Formulae:"
    brew list --formula
  fi
}' # List all installed Homebrew packages

# Mac system utilities
alias mac-flush-dns='() {
  echo -e "Flush DNS cache on macOS.\nUsage:\n mac-flush-dns"

  echo "Flushing DNS cache..."
  sudo dscacheutil -flushcache
  sudo killall -HUP mDNSResponder

  if [ $? -eq 0 ]; then
    echo "DNS cache flushed successfully!"
  else
    echo "Failed to flush DNS cache. Make sure you have sudo privileges." >&2
    return 1
  fi
}' # Flush DNS cache on macOS

alias mac-purge-memory='() {
  echo -e "Purge inactive memory on macOS.\nUsage:\n mac-purge-memory"

  echo "Purging inactive memory..."
  sudo purge

  if [ $? -eq 0 ]; then
    echo "Memory purged successfully!"
  else
    echo "Failed to purge memory. Make sure you have sudo privileges." >&2
    return 1
  fi
}' # Purge inactive memory on macOS

# Mac system info
alias mac-info='() {
  echo -e "Display macOS system information.\nUsage:\n mac-info"

  echo "macOS Version:"
  sw_vers

  echo -e "\nHardware Information:"
  system_profiler SPHardwareDataType | grep -E "Model Name|Processor|Memory|Serial"

  echo -e "\nDisk Usage:"
  df -h | grep -E "Size|disk1|disk2"

  echo -e "\nMemory Usage:"
  vm_stat | perl -ne "/page size of (\d+)/ and \$size=\$1; /Pages free: (\d+)/ and printf(\"Free Memory: %.2f GB\n\", \$1 * \$size / 1048576 / 1024); /Pages active: (\d+)/ and printf(\"Active Memory: %.2f GB\n\", \$1 * \$size / 1048576 / 1024); /Pages inactive: (\d+)/ and printf(\"Inactive Memory: %.2f GB\n\", \$1 * \$size / 1048576 / 1024);"

  echo -e "\nIP Addresses:"
  ifconfig | grep inet | grep -v inet6 | grep -v 127.0.0.1 | awk "{print \$2}"
}' # Display macOS system information

# Mac Help
alias mac-help='() {
  echo -e "macOS Aliases Help\n"
  echo "mac-install-essential   - Install essential macOS software via Homebrew"
  echo "mac-install-node        - Install Node.js and npm packages"
  echo "mac-install-python      - Install Python packages"
  echo "mac-setup-all           - Setup all essential software and packages"
  echo "mac-brew-update         - Update all Homebrew packages"
  echo "mac-brew-doctor         - Run Homebrew diagnostics"
  echo "mac-brew-list           - List all installed Homebrew packages"
  echo "mac-flush-dns           - Flush DNS cache on macOS"
  echo "mac-purge-memory        - Purge inactive memory on macOS"
  echo "mac-info                - Display macOS system information"
  echo "mac-help                - Show this help message"
}' # Show macOS aliases help
