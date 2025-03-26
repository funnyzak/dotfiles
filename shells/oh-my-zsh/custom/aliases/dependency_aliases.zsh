# Description: install dependencies for aliases

# Dependency install hint
depend_libs_install() {
  echo "Installing dependencies for aliases..."
  if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "Using Homebrew to install dependencies (brew install wget nmap openssl imagemagick youtube-dl gh jq coreutils)."
    brew install wget nmap openssl imagemagick youtube-dl gh jq coreutils apprise
    echo "Dependencies installed via Homebrew."
  elif [[ "$(uname -s)" == "Linux" ]]; then
    echo "Please install dependencies manually (e.g., sudo apt-get install wget nmap openssl imagemagick youtube-dl github-cli jq coreutils apprise)."
    echo "Dependencies: wget nmap openssl imagemagick youtube-dl github-cli jq coreutils apprise"
  else
    echo "Unsupported operating system. Please install dependencies manually."
    echo "Dependencies: wget nmap openssl imagemagick youtube-dl github-cli jq coreutils apprise"
  fi
}

# Dependency install hint alias
alias depend_install="depend_libs_install" # Install dependencies for aliases.
