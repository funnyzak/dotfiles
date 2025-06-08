# Utilities

This directory contains various utility tools to enhance your workflow, organized by programming language or technology.

## Overview

The utilities are organized into the following categories:

- [Utilities](#utilities)
  - [Overview](#overview)
  - [Python Utilities](#python-utilities)
    - [Available Tools](#available-tools)
  - [Node.js Utilities](#nodejs-utilities)
    - [Available Tools](#available-tools-1)
  - [Shell Utilities](#shell-utilities)
    - [Available Tools](#available-tools-2)
  - [Usage](#usage)

Each section provides a brief overview of the available tools. For detailed documentation, please refer to the README files in the respective subdirectories.

## Python Utilities

Python utilities provide automation scripts for various tasks. For detailed documentation, see [Python Utilities Documentation](./python/README.md).

### Available Tools

- **Background Remover** (`python/bria/background_remover.py`): A versatile script for automated background removal from images using the Bria API.
  - Supports multiple processing modes (URL images, local files, batch processing)
  - Features concurrent processing with configurable multi-threading
  - Provides both interactive and non-interactive operation modes

- **Image Background Overlay Processor** (`python/image-background-overlay-processor.py`): A versatile utility for overlaying foreground images onto background images.
  - Supports intelligent scaling, centering, and margin adjustments
  - Features batch processing and remote URL image fetching
  - Provides customizable output formats

## Node.js Utilities

Node.js utilities provide automation scripts for web development and data processing. For detailed documentation, see [Node.js Utilities Documentation](./nodejs/README.md).

### Available Tools

- **JSON to Files Generator** (`nodejs/json-to-files.js`): A versatile script for extracting data from JSON files and generating corresponding files.
  - Supports flexible JSON extraction with customizable properties
  - Features media resource downloading from HTML content
  - Provides post-processing with custom command execution
  - Includes both batch processing and parallel execution options

## Shell Utilities

Shell utilities provide command-line tools and scripts for system operations. For detailed documentation, see [Shell Utilities Documentation](./shell/README.md).

### Available Tools

- **SSH Connect** (`shell/sshc/ssh_connect.exp`): An Expect script for automating SSH connections to multiple servers.
  - Supports both interactive and non-interactive modes
  - Handles key-based and password-based authentication
  - Includes retry mechanisms and customizable configuration

- **AList Upload** (`shell/alist/alist_upload.sh`): A comprehensive script for uploading files to AList storage via API.
  - Features multiple file upload support with batch processing
  - Automatic authentication with token caching (24h validity) and optional cache disabling
  - Supports command line parameters and environment variable configuration
  - Includes automatic token refresh on 401 errors and comprehensive error handling
  - Provides remote execution capabilities, custom upload paths, and progress tracking

## Usage

Each utility has its own usage instructions and requirements. Please refer to the individual documentation in the respective subdirectories for detailed information on installation, configuration, and usage examples.
