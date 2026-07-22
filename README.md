# dotfiles

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/funnyzak/dotfiles)](https://github.com/funnyzak/dotfiles/commits/main)

A comprehensive dotfiles repository designed for centralized management of personal configuration scripts, system settings, utility scripts, and related documentation. This project facilitates the backup, synchronization, and reuse of development environments and configurations for commonly used tools across multiple systems.

> **Note:** This project is primarily designed for personal use and may not be suitable for all users. Please modify and adjust according to your own needs.

**CDN Addresses:**

* GitHub raw: [`https://raw.githubusercontent.com/funnyzak/dotfiles/refs/heads/main/`](https://raw.githubusercontent.com/funnyzak/dotfiles/refs/heads/main/)
* Vercel: [`https://idotfiles.vercel.app`](https://idotfiles.vercel.app)
* Gitee: [`https://gitee.com/funnyzak/dotfiles/raw/main/`](https://gitee.com/funnyzak/dotfiles/raw/main/)
* jsdelivr: [`https://cdn.jsdelivr.net/gh/funnyzak/dotfiles@main/`](https://cdn.jsdelivr.net/gh/funnyzak/dotfiles@main/)

## Directory Structure

The following directory structure is used to organize different types of scripts and documents for clear management and quick lookup:

```
dotfiles/
├── shells/              # Shell configuration collection
│   ├── oh-my-zsh/       # Oh My Zsh related configurations
│   │   ├── custom/     # Custom aliases, functions, plugins, themes
│   │   └── tools/      # Installation and management scripts
│   ├── zsh/             # Zsh configuration (minimal setup)
│   └── README.md
├── system/              # System setup and configuration scripts
│   ├── config/          # System configuration files (bashrc, etc.)
│   ├── automation/      # System automation scripts (backups, monitoring)
│   └── setup/           # System initialization and installation scripts
├── utilities/           # Utility tools organized by language
│   ├── python/          # Python automation scripts
│   ├── nodejs/          # Node.js utilities
│   ├── shell/           # Shell utility scripts
│   └── README.md
├── docs/                # Documentation resources
│   ├── help/            # Tool-specific help documentation
│   ├── command/         # Command reference documentation
│   ├── general/         # General documentation and guides
│   ├── common/          # Common configurations and templates
│   └── templates/       # Documentation templates
├── templates/           # Configuration templates
│   ├── packages/        # Package configuration templates
│   └── system/          # System configuration templates
├── .github/             # GitHub workflows and configuration
├── .cursor/             # Cursor IDE configuration
├── .editorconfig        # Editor configuration
├── .gitignore           # Git ignore rules
├── LICENSE              # MIT License
├── README.md            # This file
└── CLAUDE.md            # Claude Code assistant configuration
```

## Key Features

### Shell Configurations
- **Oh My Zsh**: Comprehensive setup with custom aliases, plugins, and themes
- **Zsh**: Minimal configuration for lightweight environments
- **SSH Configuration Helper**: Multi-server SSH management tool

### System Automation
- **Installation Scripts**: Automated setup of development tools
- **Configuration Management**: System-level configuration scripts
- **Automation Tasks**: Daily backups, monitoring, and scheduled tasks

### Utility Tools
- **Python Scripts**: Background removal, image processing, automation tools
- **Shell Utilities**: AList upload, MySQL backup, SSH connection tools
- **Node.js Tools**: JSON processing, file generation utilities


## License

Under the [MIT License](LICENSE).
