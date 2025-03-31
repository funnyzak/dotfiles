# Shells

This directory contains shell configuration files, aliases, plugins, and themes for centralized management of shell environments across different systems.

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](../LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/funnyzak/dotfiles)](https://github.com/funnyzak/dotfiles/commits/main)

## Overview

The shell configurations are organized into the following categories:

- [Shells](#shells)
  - [Overview](#overview)
  - [Oh My Zsh Configuration](#oh-my-zsh-configuration)
    - [Available Components](#available-components)
    - [Template Files](#template-files)
    - [Utility Scripts](#utility-scripts)
  - [Zsh Configuration](#zsh-configuration)
    - [Available Components](#available-components-1)
  - [SSH Configuration Helper (SSHC)](#ssh-configuration-helper-sshc)
    - [Remote Execution Examples](#remote-execution-examples)
  - [Usage](#usage)

Each section provides a brief overview of the available configurations. For detailed documentation, please refer to the specific subdirectories.

## Oh My Zsh Configuration

The Oh My Zsh configuration provides a comprehensive setup for the Zsh shell with custom aliases, plugins, and themes. The configuration is designed to enhance productivity and provide a more user-friendly shell experience.  For detailed documentation, see [Oh My Zsh Configuration Documentation](./oh-my-zsh/README.md).

### Available Components

- **Custom Aliases** (`oh-my-zsh/custom/aliases/`): A collection of aliases for various tasks and tools.
  - `archive_aliases.zsh`: Shortcuts for compression and extraction operations
  - `brew_aliases.zsh`: Homebrew-related command aliases
  - Add new aliases by creating `.zsh` files in the `~/.oh-my-zsh/custom/aliases/` directory

- **Custom Functions** (`oh-my-zsh/custom/custom_functions.zsh`): Utility functions for common tasks.
  - Includes functions for command existence checking, URL detection, file operations, and more
  - Provides cross-platform compatibility functions (WSL, macOS detection)

- **Custom Plugins** (`oh-my-zsh/custom/plugins/`): Additional plugins beyond the standard Oh My Zsh collection.

- **Custom Themes** (`oh-my-zsh/custom/themes/`): Personalized themes for Oh My Zsh.

### Template Files

- **Zshrc Template** (`oh-my-zsh/zshrc.zsh-template`): A comprehensive template for the `.zshrc` configuration file.
  - Includes pre-configured plugins, themes, and settings
  - Can be installed remotely:
    ```bash
    curl -fsSL https://raw.gitcode.com/funnyzak/dotfiles/raw/main/shells/oh-my-zsh/zshrc.zsh-template -o ~/.zshrc
    ```

### Utility Scripts

- **Oh My Zsh Installer** (`oh-my-zsh/tools/install_omz.sh`): A versatile script for installing, updating, or uninstalling Oh My Zsh.
  - Supports multiple installation modes and configuration options
  - Features automatic backup of existing configurations
  - Provides options for forced reinstallation and shell switching
  - Supports custom repository URLs and configuration files
  - **Usage Examples**:
    ```bash
    # Basic installation
    ./install_omz.sh

    # Non-interactive installation
    ./install_omz.sh --yes

    # Force reinstallation
    ./install_omz.sh --force

    # Update Oh My Zsh only
    ./install_omz.sh --update

    # Uninstall Oh My Zsh
    ./install_omz.sh --uninstall
    ```
  - **Remote Execution**:
    ```bash
    # Basic remote installation
    curl -fsSL https://raw.gitcode.com/funnyzak/dotfiles/raw/main/shells/oh-my-zsh/tools/install_omz.sh | bash -- --force
    ```
  - **Environment Variables**:
    ```bash
    # Use custom repository URL
    OMZ_REPO_URL=https://github.com/ohmyzsh/ohmyzsh.git ./install_omz.sh

    # Specify zshrc template branch
    OMZ_ZSHRC_BRANCH=develop ./install_omz.sh
    ```

- **Aliases Installer** (`oh-my-zsh/tools/install_omz_aliases.sh`): A tool for downloading Oh My Zsh alias files from remote repositories.
  - Supports downloading specific alias files or default collections
  - Features custom download directories and repository URLs
  - Provides options for overwriting existing files
  - Automatically detects and uses the best URL source (with China acceleration support)
  - **Usage Examples**:
    ```bash
    # Install all default alias files
    ./install_omz_aliases.sh

    # Install specific alias files
    ./install_omz_aliases.sh git_aliases.zsh help_aliases.zsh
    ```
  - **Remote Execution**:
    ```bash
    # Download all alias files
    curl -fsSL https://raw.gitcode.com/funnyzak/dotfiles/raw/main/shells/oh-my-zsh/tools/install_omz_aliases.sh | bash -s -- --force
    ```

## Zsh Configuration

The Zsh configuration provides a basic setup for the Zsh shell without Oh My Zsh, suitable for minimal environments or users who prefer a lighter configuration. For detailed documentation, see [Zsh Configuration Documentation](./zsh/README.md).

### Available Components

- **Zshrc Template** (`zsh/.zshrc-template`): A basic template for the `.zshrc` configuration file.
  - Includes essential settings for history management, completions, and aliases
  - Designed to be modular and easily customizable
  - Supports loading of environment variables, aliases, and functions from separate files

## SSH Configuration Helper (SSHC)

The SSH Configuration Helper (SSHC) provides a convenient way to manage and connect to multiple SSH servers. It includes a setup script and an interactive connection tool supporting both key-based and password authentication.

### Remote Execution Examples

- **Standard Installation**:
  ```bash
  curl -s https://raw.githubusercontent.com/funnyzak/dotfiles/refs/heads/main/utilities/shell/sshc/setup.sh | bash
  # or
  wget -qO- https://raw.githubusercontent.com/funnyzak/dotfiles/refs/heads/main/utilities/shell/sshc/setup.sh | bash
  ```

- **Installation with Specific Branch**:
  ```bash
  curl -s https://raw.githubusercontent.com/funnyzak/dotfiles/refs/heads/main/utilities/shell/sshc/setup.sh | REPO_BRANCH=sshc bash
  # or
  wget -qO- https://raw.githubusercontent.com/funnyzak/dotfiles/refs/heads/main/utilities/shell/sshc/setup.sh | REPO_BRANCH=sshc bash
  ```

The installation script will:
1. Create or verify the `~/.ssh` directory with secure permissions
2. Download the SSH connection script and server configuration template
3. Set appropriate permissions for security
4. Provide usage instructions

## Usage

Each configuration has its own usage instructions and requirements. To use these configurations:

1. **For Oh My Zsh users**:
   - Install Oh My Zsh using the provided installer script
   - Copy or download the zshrc template to your home directory
   - Install desired aliases using the aliases installer script

2. **For basic Zsh users**:
   - Copy the `.zshrc-template` file to your home directory as `.zshrc`
   - Customize the file according to your needs

For detailed information on installation, configuration, and usage examples, please refer to the specific documentation in each subdirectory.
