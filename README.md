# dotfiles

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/funnyzak/dotfiles)](https://github.com/funnyzak/dotfiles/commits/main)

Used to centrally manage personal configuration scripts, system settings, utility scripts, and related documentation, facilitating the backup, synchronization, and reuse of development environments and configurations for commonly used tools.

> **Note:** This project is primarily designed for personal use and may not be suitable for all users. Please modify and adjust according to your own needs.

**CDN Addresses:**

*   jsdelivr: [`https://cdn.jsdelivr.net/gh/funnyzak/dotfiles@main/`](https://cdn.jsdelivr.net/gh/funnyzak/dotfiles@main/)
*   GitHub raw: [`https://raw.githubusercontent.com/funnyzak/dotfiles/main/`](https://raw.githubusercontent.com/funnyzak/dotfiles/main/)
* Vercel: [`https://idotfiles.vercel.app`](https://idotfiles.vercel.app)   

## Directory Structure

The following directory structure is used to organize different types of scripts and documents for clear management and quick lookup:

```
dotfiles/
├── shells/              # Shell configuration collection
│   ├── oh-my-zsh/       # Oh My Zsh related configurations
│   │   └── custom/      # Oh My Zsh custom content
│   │       ├── aliases/
│   │       ├── plugins/
│   │       └── themes/
│   ├── zsh/       # Zsh configuration
├── system/              # Linux system setup scripts
│   ├── config/          # Scripts related to system configuration files (e.g., sysctl, bashrc)
│   │   ├── bashrc.sh
│   │   └── sysctl.conf
│   ├── automation/      # System automation scripts (e.g., scheduled tasks, monitoring scripts)
│   │   └── daily_backup.sh
│   └── setup/         # System initialization or installation scripts
│       └── install_tools.sh
├── utilities/           # General scripts (cross-platform or not specific to applications)
│   ├── shell/           # Shell scripts
│   │   └── batch_rename.sh
│   ├── python/          # Python scripts
│   │   └── process_data.py
│   ├── ...              # Directories for other languages or types of general scripts
├── docs/                # Documentation
│   ├── help/            # Help documentation for applications or tools
│   │   ├── app-x-usage.md
│   │   └── cli-tool-tips.md
│   ├── general/         # General documentation
│   │   ├── linux-command-tips.md
│   │   └── git-workflow.md
│   ├── templates/       # Documentation templates
│   │   └── report-template.md
```

## License

Under the [MIT License](LICENSE).