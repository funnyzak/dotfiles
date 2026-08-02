# Zsh Configuration

This directory contains basic configuration files for the Zsh shell without Oh My Zsh, suitable for minimal environments or users who prefer a lighter configuration.

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](../../LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/funnyzak/dotfiles)](https://github.com/funnyzak/dotfiles/commits/main)

## Overview

The Zsh configuration is organized into the following categories:

- [Zsh Configuration](#zsh-configuration)
  - [Overview](#overview)
  - [Template Files](#template-files)
    - [Features](#features)
  - [Usage](#usage)

## Template Files

- **Zshrc Template** (`.zshrc-template`): A basic template for the `.zshrc` configuration file.
  - Includes essential settings for history management, completions, and aliases
  - Designed to be modular and easily customizable
  - Supports loading of environment variables, aliases, and functions from separate files

### Features

The Zsh template includes the following features:

- **History Management**:
  - Ignores duplicated entries in the history list
  - Appends new history entries to the history file
  - Shares history between all instances of Zsh

- **Modular Configuration**:
  - Loads environment variables from `~/.zshenv`
  - Loads aliases from `~/.aliases`
  - Loads functions from `~/.functions`
  - Loads custom configurations from `~/.zshrc.local`

- **Completion System**:
  - Configures the Zsh completion system
  - Adds system completion directories to the function path

## Usage

To use the Zsh configuration:

1. Copy the `.zshrc-template` file to your home directory as `.zshrc`:
   ```bash
   cp .zshrc-template ~/.zshrc
   ```

2. Create the following optional files as needed:
   - `~/.zshenv`: Environment variables
   - `~/.aliases`: Shell aliases
   - `~/.functions`: Shell functions
   - `~/.zshrc.local`: Local customizations

3. Customize the `.zshrc` file according to your needs.

4. Restart your shell or run `source ~/.zshrc` to apply the changes.

This configuration provides a lightweight alternative to Oh My Zsh while still offering essential Zsh features and customization options.