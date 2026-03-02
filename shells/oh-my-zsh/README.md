# Oh My Zsh Configuration

This directory contains configuration files, custom components, and utility scripts for Oh My Zsh, a framework for managing Zsh configuration.

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](../../LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/funnyzak/dotfiles)](https://github.com/funnyzak/dotfiles/commits/main)

## Overview

The Oh My Zsh configuration is organized into the following categories:

- [Oh My Zsh Configuration](#oh-my-zsh-configuration)
  - [Overview](#overview)
  - [Custom Components](#custom-components)
    - [Aliases](#aliases)
    - [Functions](#functions)
    - [Plugins](#plugins)
    - [Themes](#themes)
  - [Template Files](#template-files)
  - [Utility Scripts](#utility-scripts)
    - [Oh My Zsh Installer](#oh-my-zsh-installer)
    - [Aliases Installer](#aliases-installer)
  - [Usage](#usage)

## Custom Components

### Aliases

The `custom/aliases/` directory contains a collection of alias files for various tasks and tools:

- `archive_aliases.zsh`: Shortcuts for compression and extraction operations
- `brew_aliases.zsh`: Homebrew-related command aliases

To add new aliases, create a `.zsh` file in the `~/.oh-my-zsh/custom/aliases/` directory and add it to the `install_omz_aliases.sh` script for management.

### Functions

The `custom/custom_functions.zsh` file contains utility functions for common tasks:

- Command existence checking: `command_exists()`
- URL detection: `detect_best_url()`
- Date and time formatting: `current_datetime()`
- Directory operations: `rmdir_if_empty()`
- Git operations: `git_current_branch()`
- Platform detection: `is_wsl()`, `is_mac()`
- JSON formatting: `pretty_json()`
- Network utilities: `get_ip_address()`
- String manipulation: `string_contains()`, `extract_filename()`

### Plugins

The `custom/plugins/` directory contains additional plugins beyond the standard Oh My Zsh collection. Add your custom plugins here to extend Oh My Zsh functionality.

### Themes

The `custom/themes/` directory contains personalized themes for Oh My Zsh. Add your custom themes here to customize the appearance of your shell.

## Template Files

The `zshrc.zsh-template` file is a comprehensive template for the `.zshrc` configuration file. It includes pre-configured plugins, themes, and settings.

To install the template remotely:

```bash
curl -fsSL https://gitee.com/funnyzak/dotfiles/raw/main/shells/oh-my-zsh/zshrc.zsh-template -o ~/.zshrc
```

## Utility Scripts

### Oh My Zsh Installer

The `tools/install_omz.sh` script is a versatile tool for installing, updating, or uninstalling Oh My Zsh.

**Features**:
- Multiple installation modes and configuration options
- Automatic backup of existing configurations
- Options for forced reinstallation and shell switching
- Support for custom repository URLs and configuration files

**Usage Examples**:
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

**Remote Execution**:
```bash
# Basic remote installation
curl -fsSL https://gitee.com/funnyzak/dotfiles/raw/main/shells/oh-my-zsh/tools/install_omz.sh -o _install_omz.sh && chmod +x _install_omz.sh && ./_install_omz.sh --force

```

**Environment Variables**:
```bash
# Use custom repository URL
OMZ_REPO_URL=https://github.com/ohmyzsh/ohmyzsh.git ./install_omz.sh

# Specify zshrc template branch
OMZ_ZSHRC_BRANCH=develop ./install_omz.sh

# Specify custom zshrc template URL
OMZ_ZSHRC_URL=https://example.com/my-zshrc.template ./install_omz.sh

# Custom installation directory
OMZ_INSTALL_DIR=~/custom-omz ./install_omz.sh
```

**Options**:
- `-y, --yes`: Skip all confirmation prompts
- `-s, --switch`: Automatically switch default shell to zsh
- `-f, --force`: Force reinstallation
- `-u, --update`: Update Oh My Zsh only
- `-r, --uninstall`: Uninstall Oh My Zsh
- `-h, --help`: Display help information

### Aliases Installer

The `tools/install_omz_aliases.sh` script is a tool for downloading Oh My Zsh alias files from remote repositories.

**Features**:
- Download specific alias files or default collections
- Support for custom download directories and repository URLs
- Options for overwriting existing files
- Automatic detection of the best URL source (with China acceleration support)

**Usage Examples**:
```bash
# Install all default alias files
./install_omz_aliases.sh

# Install specific alias files
./install_omz_aliases.sh git_aliases.zsh help_aliases.zsh

# Use custom URL
./install_omz_aliases.sh --url https://example.com/aliases/

# Set custom default list
./install_omz_aliases.sh --default-list "git_aliases.zsh,help_aliases.zsh"

# Force install to specific directory
./install_omz_aliases.sh --directory ~/custom_aliases --force
```

**Remote Execution**:
```bash
# Download all alias files
curl -fsSL https://gitee.com/funnyzak/dotfiles/raw/main/shells/oh-my-zsh/tools/install_omz_aliases.sh | bash -s -- --force

# Download specific alias files
curl -fsSL https://gitee.com/funnyzak/dotfiles/raw/main/shells/oh-my-zsh/tools/install_omz_aliases.sh | bash -s -- git_aliases.zsh system_aliases.zsh
```

**Options**:
- `-h, --help`: Display help information
- `-d, --directory DIR`: Specify download directory (default: $ZSH/custom/aliases/)
- `-n, --no-overwrite`: Do not overwrite existing files
- `-v, --verbose`: Enable verbose output
- `-f, --force`: Force download even if directory doesn't exist
- `-u, --url URL`: Specify custom repository URL
- `-s, --default-list LIST`: Custom default alias list (comma-separated)

## Usage

To use the Oh My Zsh configuration:

1. Install Oh My Zsh using the provided installer script:
   ```bash
   ./tools/install_omz.sh
   ```

2. Copy or download the zshrc template to your home directory:
   ```bash
   curl -fsSL https://gitee.com/funnyzak/dotfiles/raw/main/shells/oh-my-zsh/zshrc.zsh-template -o ~/.zshrc
   ```

3. Install desired aliases using the aliases installer script:
   ```bash
   ./tools/install_omz_aliases.sh
   ```

4. Customize your configuration by adding or modifying files in the `custom/` directory.
