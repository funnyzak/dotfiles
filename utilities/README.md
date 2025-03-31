# Utilities

This directory contains various utility tools to enhance your workflow, organized by programming language or technology.

## Overview

The utilities are organized into the following categories:

- [Utilities](#utilities)
  - [Overview](#overview)
  - [Python Utilities](#python-utilities)
    - [Available Tools](#available-tools)
  - [Shell Utilities](#shell-utilities)
    - [Available Tools](#available-tools-1)
  - [Usage](#usage)

Each section provides a brief overview of the available tools. For detailed documentation, please refer to the README files in the respective subdirectories.

## Python Utilities

Python utilities provide automation scripts for various tasks. For detailed documentation, see [Python Utilities Documentation](./python/README.md).

### Available Tools

- **Background Remover** (`python/bria/background_remover.py`): A versatile script for automated background removal from images using the Bria API.
  - Supports multiple processing modes (URL images, local files, batch processing)
  - Features concurrent processing with configurable multi-threading
  - Provides both interactive and non-interactive operation modes

## Shell Utilities

Shell utilities provide command-line tools and scripts for system operations. For detailed documentation, see [Shell Utilities Documentation](./shell/README.md).

### Available Tools

- **SSH Connect** (`shell/sshc/ssh_connect.exp`): An Expect script for automating SSH connections to multiple servers.
  - Supports both interactive and non-interactive modes
  - Handles key-based and password-based authentication
  - Includes retry mechanisms and customizable configuration

- **FRP Client Installer** (`shell/frp/install_frpc.sh`): Installation and management script for Fast Reverse Proxy Client.
  - Automates installation and configuration
  - Supports multiple configuration methods
  - Provides customizable installation paths

## Usage

Each utility has its own usage instructions and requirements. Please refer to the individual documentation in the respective subdirectories for detailed information on installation, configuration, and usage examples.
