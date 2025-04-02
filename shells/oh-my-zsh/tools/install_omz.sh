#!/bin/bash

# install_omz.sh - Oh My Zsh Installation and Uninstallation Script
# Author: GitHub: funnyzak
# Version: 1.1.0
# Last Updated: March 27, 2025

# Exit on any error, undefined variable, or pipe failure
set -euo pipefail

# ==================================
# DOCUMENTATION AND USAGE EXAMPLES
# ==================================

# Usage Examples:
#
# 1. Local Execution Examples:
#    - Basic installation:                 ./install_omz.sh
#    - Non-interactive installation:       ./install_omz.sh --yes
#    - Force reinstall:                    ./install_omz.sh --force
#    - Update only:                        ./install_omz.sh --update
#    - Uninstall Oh My Zsh:                ./install_omz.sh --uninstall
#
# 2. Remote Execution Examples:
#    - Basic remote installation:
#      curl -fsSL https://gitee.com/funnyzak/dotfiles/raw/main/shells/oh-my-zsh/tools/install_omz.sh | bash
#
#    - Non-interactive remote installation:
#      curl -fsSL https://gitee.com/funnyzak/dotfiles/raw/main/shells/oh-my-zsh/tools/install_omz.sh | bash -s -- --yes
#
#    - Force reinstall remotely:
#      curl -fsSL https://raw.githubusercontent.com/funnyzak/dotfiles/refs/heads/main/shells/oh-my-zsh/tools/install_omz.sh | bash -s -- --force
#
#    - Uninstall remotely:
#      curl -fsSL https://gitee.com/funnyzak/dotfiles/raw/main/shells/oh-my-zsh/tools/install_omz.sh | bash -s -- --uninstall
#
# 3. Environment Variables:
#    - OMZ_REPO_URL:        Custom Oh My Zsh repository URL
#                           Example: OMZ_REPO_URL=https://github.com/ohmyzsh/ohmyzsh.git ./install_omz.sh
#
#    - OMZ_ZSHRC_BRANCH:   Specify branch for zshrc template
#                           Example: OMZ_ZSHRC_BRANCH=develop ./install_omz.sh
#
#    - OMZ_ZSHRC_URL:           Custom zshrc template URL
#                           Example: OMZ_ZSHRC_URL=https://example.com/my-zshrc.template ./install_omz.sh
#
#    - OMZ_INSTALL_DIR:     Custom Oh My Zsh installation directory (default: ~/.oh-my-zsh)
#                           Example: OMZ_INSTALL_DIR=~/custom-omz ./install_omz.sh

# ==================================
# HELPER FUNCTIONS
# ==================================

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PLAIN='\033[0m'

# Print a message with color
print_message() {
  local color="$1"
  local message="$2"
  echo -e "${color}${message}${PLAIN}"
}

# Print info message
info() {
  print_message "${BLUE}" "INFO: $1"
}

# Print success message
success() {
  print_message "${GREEN}" "SUCCESS: $1"
}

# Print warning message
warning() {
  print_message "${YELLOW}" "WARNING: $1"
}

# Print error message
error() {
  print_message "${RED}" "ERROR: $1" >&2
}

# Confirm action from user
confirm() {
  if [ "$SKIP_CONFIRM" = true ]; then
    return 0
  fi

  read -e -p "$1 [y/n]: " confirm
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    return 0
  else
    return 1
  fi
}

# Show help information
show_help() {
    echo "Oh My Zsh Installation and Uninstallation Script"
    echo "Usage: $0 [OPTION]..."
    echo ""
    echo "Options:"
    echo "  -y, --yes        Skip all confirmation prompts"
    echo "  -s, --switch     Automatically switch default shell to zsh"
    echo "  -f, --force      Force reinstallation"
    echo "  -u, --update     Only update installed Oh My Zsh"
    echo "  -r, --uninstall  Uninstall Oh My Zsh"
    echo "  -h, --help       Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0               Interactive installation"
    echo "  $0 -y -s         Non-interactive installation with shell switching"
    echo "  $0 -u            Update existing Oh My Zsh installation"
    echo "  $0 -r            Uninstall Oh My Zsh"
    echo ""
    echo "Environment Variables:"
    echo "  OMZ_REPO_URL     Custom Oh My Zsh repository URL"
    echo "  OMZ_ZSHRC_BRANCH Branch for zshrc template"
    echo "  OMZ_ZSHRC_URL        Custom zshrc template URL"
    echo "  OMZ_INSTALL_DIR  Custom Oh My Zsh installation directory (default: ~/.oh-my-zsh)"
}

# ==================================
# CONFIGURATION AND FLAGS
# ==================================

# Temporary directory for installation files
TMP_PATH="$(mktemp -d /tmp/ohmyzsh.XXXXXX)"

# Installation directory (default: ~/.oh-my-zsh)
OMZ_INSTALL_DIR="${OMZ_INSTALL_DIR:-$HOME/.oh-my-zsh}"

# zshrc configuration URL
OMZ_ZSHRC_BRANCH=${OMZ_ZSHRC_BRANCH:-main}
OMZ_ZSHRC_URL=${OMZ_ZSHRC_URL:-https://gitee.com/funnyzak/dotfiles/raw/${OMZ_ZSHRC_BRANCH}/shells/oh-my-zsh/zshrc.zsh-template}
OMZ_REPO_URL=${OMZ_REPO_URL:-https://gitcode.com/gh_mirrors/oh/ohmyzsh.git}

# Command line flags
SKIP_CONFIRM=false      # Skip confirmation prompts
AUTO_SWITCH_SHELL=false # Automatically switch default shell
FORCE_REINSTALL=false   # Force reinstallation
UPDATE_ONLY=false       # Only update
UNINSTALL_MODE=false    # Uninstall mode


# ==================================
# ARGUMENT PARSING
# ==================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -y|--yes)
                SKIP_CONFIRM=true
                shift
                ;;
            -s|--switch)
                AUTO_SWITCH_SHELL=true
                shift
                ;;
            -f|--force)
                FORCE_REINSTALL=true
                shift
                ;;
            -u|--update)
                UPDATE_ONLY=true
                shift
                ;;
            -r|--uninstall)
                UNINSTALL_MODE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# ==================================
# UTILITY FUNCTIONS
# ==================================

# Clean up temporary files
cleanup() {
    info "Cleaning up temporary files..."
    rm -rf "${TMP_PATH}"
}

# Set up exit trap
setup_trap() {
    trap 'cleanup' EXIT
}

# Check if Oh My Zsh is installed
check_if_installed() {
    if [ -d "${OMZ_INSTALL_DIR}" ]; then
        return 0
    else
        return 1
    fi
}

# Validate system requirements
validate_system() {
    # Make sure we have a home directory
    if [ -z "$HOME" ]; then
        error "HOME directory not set or doesn't exist"
        exit 1
    fi
}

# ==================================
# INSTALLATION FUNCTIONS
# ==================================

# Check and install dependencies
check_dependencies() {
    info "Checking required dependencies..."

    # Check package manager
    PKG_MANAGER=""
    if command -v yum > /dev/null 2>&1; then
        PKG_MANAGER="yum"
    elif command -v apt-get > /dev/null 2>&1; then
        PKG_MANAGER="apt-get"
    elif command -v brew > /dev/null 2>&1; then
        PKG_MANAGER="brew"
    fi

    # List of dependencies to check
    local dependencies=("git" "curl" "zsh")
    local missing_deps=()

    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" > /dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done

    # Install missing dependencies if package manager is available
    if [ ${#missing_deps[@]} -gt 0 ]; then
        warning "Missing dependencies: ${missing_deps[*]}"

        if [ -n "$PKG_MANAGER" ]; then
            info "Installing missing dependencies using $PKG_MANAGER..."

            case "$PKG_MANAGER" in
                yum)
                    sudo yum install -y "${missing_deps[@]}"
                    ;;
                apt-get)
                    sudo apt-get update
                    sudo apt-get install -y "${missing_deps[@]}"
                    ;;
                brew)
                    brew install "${missing_deps[@]}"
                    ;;
            esac

            # Verify installation
            for dep in "${missing_deps[@]}"; do
                if ! command -v "$dep" > /dev/null 2>&1; then
                    error "Failed to install $dep. Please install it manually and try again."
                    exit 1
                fi
            done
        else
            error "No package manager found to install missing dependencies."
            error "Please install the following dependencies manually: ${missing_deps[*]}"
            exit 1
        fi
    fi

    success "All required dependencies are available"
}

# Create temporary directory
create_tmp_dir() {
    info "Creating temporary directory..."
    if [ ! -d "${TMP_PATH}" ]; then
        mkdir -p "${TMP_PATH}"
    fi

    if [ $? -ne 0 ]; then
        error "Failed to create temporary directory"
        exit 1
    fi
}

# Backup existing Oh My Zsh configuration
backup_existing_omz() {
    if check_if_installed; then
        info "Backing up existing Oh My Zsh configuration..."
        BACKUP_DIR="$HOME/.oh-my-zsh.backup.$(date +%Y%m%d%H%M%S)"
        cp -r "${OMZ_INSTALL_DIR}" "${BACKUP_DIR}"

        if [ -f "$HOME/.zshrc" ]; then
            cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
        fi

        success "Configuration backed up to ${BACKUP_DIR}"
    fi
}

# Uninstall existing Oh My Zsh
uninstall_oh_my_zsh() {
    if ! check_if_installed; then
        warning "Oh My Zsh is not installed. Nothing to uninstall."
        return 0
    fi

    if [ "$UNINSTALL_MODE" = true ] && [ "$SKIP_CONFIRM" != true ]; then
        confirm "Are you sure you want to remove Oh My Zsh?" || exit 0
    fi

    info "Removing Oh My Zsh installation directory..."
    rm -rf "${OMZ_INSTALL_DIR}"

    if [ -e "$HOME/.zshrc" ]; then
        ZSHRC_SAVE="$HOME/.zshrc.omz-uninstalled-$(date +%Y-%m-%d_%H-%M-%S)"
        info "Found ~/.zshrc -- Renaming to ${ZSHRC_SAVE}"
        mv "$HOME/.zshrc" "${ZSHRC_SAVE}"
    fi

    info "Looking for original zsh config..."
    ZSHRC_ORIG="$HOME/.zshrc.pre-oh-my-zsh"
    if [ -e "$ZSHRC_ORIG" ]; then
        info "Found $ZSHRC_ORIG -- Restoring to ~/.zshrc"
        mv "$ZSHRC_ORIG" "$HOME/.zshrc"
        success "Your original zsh config was restored."
    else
        info "No original zsh config found"
    fi

    success "Oh My Zsh has been uninstalled!"
    info "Don't forget to restart your terminal!"

    return 0
}

# Clone Oh My Zsh repository
clone_omz() {
    info "Cloning Oh My Zsh repository..."
    mkdir -p "${TMP_PATH}/ohmyzsh"

    git clone --depth=1 "${OMZ_REPO_URL}" "${TMP_PATH}/ohmyzsh" 2>/dev/null

    if [ $? -ne 0 ]; then
        error "Failed to clone Oh My Zsh repository"
        exit 1
    fi
}

# Install Oh My Zsh
install_omz() {
    info "Installing Oh My Zsh..."

    # Use Oh My Zsh's installer with our settings
    export REPO="ohmyzsh"
    export REMOTE="${OMZ_REPO_URL}"

    # Skip interactive prompts and shell change
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh "${TMP_PATH}/ohmyzsh/tools/install.sh" --skip-chsh --unattended

    if [ $? -ne 0 ]; then
        error "Oh My Zsh installation failed"
        exit 1
    fi

    success "Oh My Zsh installed successfully"
}

# Setup Git remote repository
setup_git_remote() {
    info "Setting Oh My Zsh repository source..."

    cd "${OMZ_INSTALL_DIR}"
    git remote set-url origin "${OMZ_REPO_URL}"
    git pull

    if [ $? -ne 0 ]; then
        warning "Failed to set repository source. This is not critical."
    fi
}

# Update Oh My Zsh
update_omz() {
    info "Updating Oh My Zsh..."

    if [ -f "${OMZ_INSTALL_DIR}/tools/upgrade.sh" ]; then
        sh "${OMZ_INSTALL_DIR}/tools/upgrade.sh"
    else
        (cd "${OMZ_INSTALL_DIR}" && git pull)
    fi

    if [ $? -ne 0 ]; then
        error "Failed to update Oh My Zsh"
        return 1
    fi

    success "Oh My Zsh updated successfully"
    return 0
}

# Download zshrc configuration file
download_zshrc() {
    info "Downloading zshrc configuration file..."

    # Backup existing configuration if present
    if [ -f "$HOME/.zshrc" ]; then
        cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
    fi

    # Download new configuration
    echo "Downloading zshrc configuration file from ${OMZ_ZSHRC_URL}..."
    curl -s -o "$HOME/.zshrc" "${OMZ_ZSHRC_URL}"

    if [ $? -ne 0 ]; then
        error "Failed to download zshrc configuration file"
        exit 1
    fi

    success "Configuration file downloaded successfully"
}

# Switch default shell to Zsh
switch_shell() {
    # Skip if shell is already Zsh
    if [ "$(basename "$SHELL")" = "zsh" ]; then
        success "Current shell is already Zsh"
        return 0
    fi

    # Check for shell switching flag or ask user
    if [ "$AUTO_SWITCH_SHELL" = true ] || confirm "Switch default shell to Zsh?"; then
        info "Switching default shell to Zsh..."

        # Get path to Zsh
        ZSH_PATH=$(which zsh)

        # Make sure Zsh is in /etc/shells
        if ! grep -q "$ZSH_PATH" /etc/shells; then
            warning "Adding $ZSH_PATH to /etc/shells"
            echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
        fi

        # Change shell
        chsh -s "$ZSH_PATH"

        if [ $? -ne 0 ]; then
            warning "Failed to switch default shell. Please run: chsh -s $ZSH_PATH"
        else
            success "Default shell switched to Zsh"
        fi
    else
        info "Shell unchanged. You can manually switch later with: chsh -s $(which zsh)"
    fi
}

# Handle existing Oh My Zsh installation
handle_existing_installation() {
    # If not installed, return 1 (need to perform fresh install)
    if ! check_if_installed; then
        return 0
    fi

    # If force reinstallation is requested
    if [ "$FORCE_REINSTALL" = true ]; then
        info "Existing Oh My Zsh installation detected. Performing forced reinstallation..."
        backup_existing_omz
        uninstall_oh_my_zsh
        return 0  # Need fresh installation
    fi

    # If update only is requested
    if [ "$UPDATE_ONLY" = true ]; then
        info "Update mode: Only updating existing Oh My Zsh installation..."
        update_omz
        download_zshrc
        cleanup

        success "Oh My Zsh update completed!"
        info "You can apply the new configuration with: source ~/.zshrc"
        success "Enjoy using Oh My Zsh!"

        exit 0  # Exit after updating
    fi

    # Interactive mode - ask user what to do
    info "Existing Oh My Zsh installation detected"

    echo "Please select an action:"
    echo "1) Update existing installation"
    echo "2) Reinstall"
    echo "3) Skip installation"

    local choice
    if [ "$SKIP_CONFIRM" = true ]; then
        choice=1
    else
        read -p "Enter option [1-3]: " choice
    fi

    case $choice in
        1)
            update_omz
            download_zshrc
            cleanup

            success "Oh My Zsh update completed!"
            info "You can apply the new configuration with: source ~/.zshrc"
            success "Enjoy using Oh My Zsh!"

            exit 0
            ;;
        2)
            backup_existing_omz
            uninstall_oh_my_zsh
            return 1  # Need fresh installation
            ;;
        3|*)
            success "Installation skipped. Keeping existing configuration."
            exit 0
            ;;
    esac
}

# ==================================
# MAIN FUNCTION
# ==================================

main() {
    # Parse command line arguments
    parse_args "$@"

    # Set up cleanup trap
    setup_trap

    # Validate system
    validate_system

    # Banner
    print_message "${GREEN}" "=== Oh My Zsh Installation and Uninstallation Script ==="

    # Uninstall mode
    if [ "$UNINSTALL_MODE" = true ]; then
        uninstall_oh_my_zsh
        exit 0
    fi
    # Check if already installed
    handle_existing_installation

    # From here, we're doing a fresh installation
    # Ask for confirmation if not in auto mode
    if [ "$SKIP_CONFIRM" != true ]; then
        confirm "Ready to install Oh My Zsh. Continue?" || exit 0
    fi

    # Installation process
    check_dependencies
    create_tmp_dir

    # Execute installation steps
    clone_omz
    install_omz
    setup_git_remote
    download_zshrc
    switch_shell

    # Final success message
    success "Oh My Zsh installation completed!"
    info "You can now:"
    info "1. Run 'zsh' to enter Zsh environment"
    info "2. Run 'source ~/.zshrc' to apply the new configuration"
    info "3. If needed, run 'chsh -s $(which zsh)' to switch your default shell"
    success "Enjoy using Oh My Zsh!"
}

# Run main function with all arguments
main "$@"
