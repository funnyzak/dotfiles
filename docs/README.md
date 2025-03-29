# Documentation

This directory contains various documentation resources organized by category, providing quick reference guides, command cheatsheets, and help documentation for different tools and technologies.

## Overview

The documentation is organized into the following categories:

- [Documentation](#documentation)
  - [Overview](#overview)
  - [Command-Line Interface (CLI) Cheatsheets](#command-line-interface-cli-cheatsheets)
    - [Available Categories](#available-categories)
  - [Help Documentation](#help-documentation)
  - [Command Documentation](#command-documentation)
  - [General Documentation](#general-documentation)
  - [Templates](#templates)
  - [Usage](#usage)

Each section provides a brief overview of the available documentation. For detailed information, please refer to the README files in the respective subdirectories.

## Command-Line Interface (CLI) Cheatsheets

The `cli` directory contains comprehensive cheatsheets for various command-line tools, organized by category. These cheatsheets provide quick reference guides for syntax, common commands, and usage examples.

### Available Categories

- **Android** (`cli/android/`): Commands for Android development and device management.
- **Build Tools** (`cli/build/`): Build automation tools like Maven, Gradle, and CMake.
- **Database** (`cli/database/`): Database management tools including MySQL, PostgreSQL, MongoDB, and Redis.
- **Media** (`cli/media/`): Media processing tools like FFmpeg and ImageMagick.
- **Network** (`cli/network/`): Networking utilities such as curl, dig, ssh, and more.
- **Package Managers** (`cli/package/`): Package management tools like npm, pip, brew, and others.
- **Runtime** (`cli/runtime/`): Runtime environments for languages like Python, Node.js, Java, and Go.
- **System** (`cli/system/`): System utilities for file manipulation, process management, and more.
- **Tools** (`cli/tools/`): General development tools like Git, Docker, and jq.
- **Web Servers** (`cli/webserver/`): Web server configuration and management tools.

## Help Documentation

The `help` directory contains detailed help documentation for various applications and tools, providing in-depth explanations, tutorials, and troubleshooting guides.

## Command Documentation

The `command` directory contains documentation specifically focused on command usage, including detailed parameter descriptions, examples, and best practices.

## General Documentation

The `general` directory contains general-purpose documentation that doesn't fit into the other categories, including conceptual guides, architectural overviews, and reference materials.

## Templates

The `templates` directory contains documentation templates that can be used as starting points for creating new documentation.

## Usage

To use these documentation resources:

1. Navigate to the appropriate category directory based on what you're looking for.
2. Open the relevant documentation file in your preferred text editor or viewer.
3. For CLI cheatsheets, you can also use the `cheatsheet.sh` utility in the `utilities/shell/` directory for interactive access.

```bash
# Example: Using the cheatsheet utility to access Git documentation
../utilities/shell/cheatsheet.sh git
```

All documentation is maintained in plain text format for maximum compatibility and ease of use across different environments.