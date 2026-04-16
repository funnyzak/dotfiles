#!/bin/bash

# Function to check if a command exists
command_exists() {
  command -v "$1" &> /dev/null
}

# Install Homebrew if it's not already installed
if ! command_exists brew; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "Homebrew is already installed."
fi

# Update Homebrew
echo "Updating Homebrew..."
brew update

# Upgrade Homebrew packages
echo "Upgrading Homebrew packages..."
brew upgrade

# Install essential tools
echo "Installing essential tools..."
brew install git wget curl vim tmux zsh

# Install zsh plugins (example)
if ! [ -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "Oh My Zsh is already installed."
fi

# Change default shell to zsh
if ! grep -q "$(which zsh)" /etc/shells; then
  echo "Adding zsh to /etc/shells..."
  sudo sh -c "echo $(which zsh) >> /etc/shells"
fi

if [ "$SHELL" != "$(which zsh)" ]; then
  echo "Changing default shell to zsh..."
  chsh -s $(which zsh)
  echo "Please open a new terminal or run 'exec zsh' for the changes to take effect."
else
  echo "Zsh is already the default shell."
fi

echo "Installation complete!"