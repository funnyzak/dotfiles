# Claude Code Assistant Configuration

This document provides essential information for Claude Code assistants working with this dotfiles repository.

## Project Overview

This is a comprehensive dotfiles repository designed for centralized management of personal configuration scripts, system settings, utility scripts, and related documentation. The project facilitates backup, synchronization, and reuse of development environments and configurations for commonly used tools.

**Key Characteristics:**
- Personal use focused (may not be suitable for all users)
- Multi-platform support with macOS/Linux emphasis
- Shell-centric configuration management
- Utility scripts for automation and productivity
- Well-organized modular structure

## Directory Structure

```
dotfiles/
├── shells/              # Shell configuration collection
│   ├── oh-my-zsh/       # Oh My Zsh related configurations
│   ├── zsh/             # Zsh configuration
│   └── README.md
├── system/              # Linux system setup scripts
│   ├── config/          # System configuration files
│   ├── automation/      # System automation scripts
│   └── setup/           # System initialization scripts
├── utilities/           # Utility tools organized by language
│   ├── python/          # Python automation scripts
│   ├── nodejs/          # Node.js utilities
│   └── shell/           # Shell utility scripts
├── docs/                # Documentation resources
│   ├── help/            # Tool-specific help docs
│   ├── command/         # Command documentation
│   ├── general/         # General documentation
│   ├── templates/       # Documentation templates
│   └── ZSHRC_ALIASES_GUIDE.md  # Zsh aliases development guide
├── templates/           # Configuration templates
├── .github/             # GitHub workflows and configs
├── .cursor/             # Cursor IDE configuration
├── .editorconfig        # Editor configuration
├── .gitignore           # Git ignore rules
├── LICENSE              # MIT License
└── README.md            # Main project documentation
```

## Code Style and Conventions

### File Formatting
- **Indentation**: 2 spaces for most files (per .editorconfig)
- **Line Endings**: LF (Unix-style)
- **Character Encoding**: UTF-8
- **Final Newline**: Required for all files
- **Trailing Whitespace**: Trimmed

### Shell Scripts (.sh)
- Use shebang `#!/bin/bash` for bash scripts
- Follow existing naming conventions: `snake_case` for functions, `UPPER_CASE` for environment variables
- Include comments for complex logic
- Error handling with `set -e` for critical scripts

### Zsh Configuration (.zsh)
- Modular organization with separate files for aliases, functions, plugins
- Follow Oh My Zsh conventions when applicable
- Use descriptive names for aliases and functions
- **For alias development**: See [ZSHRC_ALIASES_GUIDE.md](docs/ZSHRC_ALIASES_GUIDE.md) for comprehensive guidelines

### Python Scripts (.py)
- Follow PEP 8 style guidelines
- Include docstrings for functions and classes
- Use virtual environments (`.venv/` directory)

### Documentation (.md)
- Use GitHub Flavored Markdown
- Include clear headings and structure
- Provide usage examples where applicable

## Development Workflow

### Common Commands
```bash
# Test shell scripts
bash system/setup/install_tools.sh

# Install Oh My Zsh configurations
bash shells/oh-my-zsh/tools/install_omz.sh

# Install aliases
bash shells/oh-my-zsh/tools/install_omz_aliases.sh

# Run Python utilities
cd utilities/python && python script_name.py
```

### Git Workflow
- **Main Branch**: `main`
- **Commit Style**: Conventional commits with prefix `chore:`, `feat:`, `fix:`, etc.
- **Pull Requests**: Required for all changes
- **Branch Protection**: Main branch protected

### Testing
- Shell scripts: Test with `bash -n script.sh` for syntax
- Python scripts: Use `python -m py_compile script.py` for syntax check
- No automated test suite currently (manual testing only)

## Key Components

### Shell Configurations
- **Oh My Zsh**: Comprehensive setup with custom aliases, plugins, themes
- **Zsh**: Minimal configuration for lightweight setups
- **SSH Configuration Helper (SSHC)**: Multi-server SSH management

### System Scripts
- **Installation Tools**: Automated setup of common development tools
- **Configuration Management**: System-level configuration scripts
- **Automation**: Daily backups, monitoring, scheduled tasks

### Utilities
- **Python**: Background removal, image processing, automation scripts
- **Node.js**: JSON processing, file generation utilities
- **Shell**: AList upload, MySQL backup, SSH tools

## CDN Sources

The project provides multiple CDN sources for remote script execution:
- GitHub raw: `https://raw.githubusercontent.com/funnyzak/dotfiles/refs/heads/main/`
- Vercel: `https://idotfiles.vercel.app`
- Gitee: `https://gitee.com/funnyzak/dotfiles/raw/main/`
- jsdelivr: `https://cdn.jsdelivr.net/gh/funnyzak/dotfiles@main/`

## Security Considerations

- Never commit private keys, passwords, or sensitive configuration
- Use environment variables for sensitive data
- SSH keys should be managed separately (excluded via .gitignore)
- Database credentials should be externalized

## External Dependencies

### Shell Dependencies
- `bash` (required for most scripts)
- `zsh` (for Zsh configurations)
- `curl` or `wget` (for remote installations)
- `git` (for version control operations)

### Python Dependencies
- Managed via `requirements.txt` or `Pipfile`
- Use virtual environments
- Key packages: `requests`, `Pillow`, `opencv-python`

### Node.js Dependencies
- Managed via `package.json`
- Use `npm` or `yarn` for package management

## Common Tasks

### Adding New Aliases
1. **Read the guidelines**: Review [ZSHRC_ALIASES_GUIDE.md](docs/ZSHRC_ALIASES_GUIDE.md) for comprehensive development standards
2. Create new file in `shells/oh-my-zsh/custom/aliases/` following naming pattern: `category_aliases.zsh`
3. **Follow strict conventions**:
   - Use function format: `alias name='() { ... }'`
   - No single quotes in function body (use double quotes with escaping)
   - Include comprehensive error handling and usage information
   - Use local variables only
   - Test cross-platform compatibility (macOS/Linux)
4. Test with `bash -n file.zsh` and `source ~/.zshrc`
5. **Cursor IDE integration**: The `.cursor/rules/zshrc.aliases.mdc` file automatically applies these standards when editing alias files

### Creating New Utilities
1. Choose appropriate language directory (`utilities/python/`, `utilities/shell/`, etc.)
2. Include README.md with usage instructions
3. Add to main utilities documentation

### Updating Documentation
1. Update relevant README.md files
2. Follow existing documentation structure
3. Include examples and usage instructions

## Related Projects

- [cli-cheatsheets](https://github.com/funnyzak/cli-cheatsheets)
- [frpc](https://github.com/funnyzak/frpc)

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Development Tools and Integration

### Cursor IDE Integration
- **Alias Development**: The `.cursor/rules/zshrc.aliases.mdc` file automatically applies zshrc alias development standards when editing files matching `shells/oh-my-zsh/custom/aliases/*.zsh`
- **Automatic Quality Control**: Ensures all aliases follow the comprehensive guidelines documented in [ZSHRC_ALIASES_GUIDE.md](docs/ZSHRC_ALIASES_GUIDE.md)

### Specialized Documentation
- **Zsh Aliases Guide**: Comprehensive guidelines for creating high-quality shell alias functions
- **Code Standards**: Enforced conventions for error handling, parameter validation, and cross-platform compatibility

## Notes for Claude Code

- This is a personal dotfiles repository - modifications should respect the personal use case
- Shell scripts should be defensive and handle errors appropriately
- Remote installation scripts should include multiple CDN options
- Documentation should be comprehensive and include practical examples
- Modular organization is preferred over monolithic configurations
- Cross-platform compatibility (macOS/Linux) is important where applicable
- **For alias development**: Always consult [ZSHRC_ALIASES_GUIDE.md](docs/ZSHRC_ALIASES_GUIDE.md) for detailed standards and best practices