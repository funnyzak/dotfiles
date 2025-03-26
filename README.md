# dotfiles

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/funnyzak/dotfiles)](https://github.com/funnyzak/dotfiles/commits/main)

Used to centrally manage personal configuration scripts, system settings, utility scripts, and related documentation, facilitating the backup, synchronization, and reuse of development environments and configurations for commonly used tools.

> **Note:** This project is primarily designed for personal use and may not be suitable for all users. Please modify and adjust according to your own needs.

**CDN Addresses:**

* GitHub raw: [`https://raw.githubusercontent.com/funnyzak/dotfiles/refs/heads/main/`](https://raw.githubusercontent.com/funnyzak/dotfiles/refs/heads/main/)
* Vercel: [`https://idotfiles.vercel.app`](https://idotfiles.vercel.app)
* GitCode: [`https://raw.gitcode.com/funnyzak/dotfiles/raw/main/`](https://raw.gitcode.com/funnyzak/dotfiles/raw/main/)
* jsdelivr: [`https://cdn.jsdelivr.net/gh/funnyzak/dotfiles@main/`](https://cdn.jsdelivr.net/gh/funnyzak/dotfiles@main/)

## Directory Structure

The following directory structure is used to organize different types of scripts and documents for clear management and quick lookup:

```
dotfiles/
├── shells/              # Shell configuration collection
│   ├── zshrc.zsh-template # Zsh configuration template
│   ├── oh-my-zsh/       # Oh My Zsh related configurations
│   │   └── custom/      # Oh My Zsh custom content
│   ├── zsh/             # Zsh configuration
├── system/              # Linux system setup scripts
│   ├── config/          # Scripts related to system configuration files (e.g., sysctl, bashrc)
│   ├── automation/      # System automation scripts (e.g., scheduled tasks, monitoring scripts)
│   └── setup/         # System initialization or installation scripts
├── utilities/
├── python/                    # Python scripts collection
└── shell/                     # Shell scripts collection
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
