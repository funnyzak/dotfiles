# Zshrc Aliases Development Guide

This document provides comprehensive guidelines for creating and maintaining high-quality shell alias functions in this dotfiles repository.

## Overview

This guide is specifically designed for developers working with zshrc alias files in the `shells/oh-my-zsh/custom/aliases/` directory. It ensures consistency, quality, and best practices across all alias functions.

## Core Requirements

### Function Format
All aliases must be defined as functions using the standard format:
```bash
alias function_name='() { ... }'
```

### String Handling
- **No single quotes** in function body code
- Use double quotes `"` for all strings
- Escape double quotes with backslash: `\"`
- Escape single quotes in words: `couldn"t` instead of `couldn't`
- Example: `echo \"Hello, World!\"` instead of `echo 'Hello, World!'`

### Variable Usage
- **Local variables only** - no global variables
- Use `local` keyword for all variables
- Naming convention: `lowercase_with_underscores`
- Avoid reserved words: `path`, `file`, `dir`, `temp`, `status`, `result`
- Example: `local config_file="/path/to/config"`

### Error Handling
- Check command exit status (`$?`) immediately after execution
- Provide clear, informative error messages
- Output errors to stderr (`>&2`)
- Include error type, location, and troubleshooting suggestions
- Validate all input parameters

### Parameter Design
- Use positional parameters (`$1`, `$2`, ...) as primary input
- Support optional flags when necessary (`-f`, `--verbose`)
- Validate all parameters for type, format, and range
- Provide sensible defaults for optional parameters

## Code Structure

### Function Template
```bash
alias function_name='() {
    # Usage information
    echo -e "Function description.\nUsage:\n function_name <required_param> [optional_param:default]"

    # Parameter validation
    if [ $# -eq 0 ]; then
        echo "Error: Missing required parameter" >&2
        return 1
    fi

    local param1="$1"
    local param2="${2:-default_value}"

    # Main logic
    if ! some_command "$param1"; then
        echo "Error: Command failed for parameter: $param1" >&2
        return 1
    fi
}'
```

### Usage Information Format
- Use `echo -e` for functions with parameters
- Use simple `echo` for basic functions
- Format: `<parameter_name:default_value>` for optional parameters
- Include examples for complex functions

**Examples:**
```bash
# Simple function
echo "Show system information."

# Function with parameters
echo -e "Create a file with specified size.\nUsage:\n function_name <size_in_MB:100> [directory_path:~]"

# Complex function with examples
echo -e "Remove background from an image.\nUsage:\nbria-bg-remove <image_path_or_url> [output_path]"
echo -e "Examples:\n bria-bg-remove photo.jpg\n -> Creates photo_background_remove.jpg"
```

### Naming Conventions

#### Alias Names
- Use lowercase letters only
- Use hyphens to separate words: `get-user-info`, `process-data`
- No numbers unless meaningful: `get-1st-user`
- Avoid conflicts with system commands
- Use descriptive names: `mkd` instead of `md`
- Check for conflicts with `type alias_name` or `command -v alias_name`

#### Function Parameters
- Use lowercase letters only
- Avoid special characters
- Keep names concise but descriptive

#### Helper Functions
- Prefix with underscore: `_helper_function`
- Include filename suffix: `_filesystem_helper` for filesystem_aliases.zsh
- Extract common logic to improve maintainability

## Cross-Platform Compatibility

### Shell Compatibility
- Prioritize Bash compatibility
- Avoid Bashisms unless explicitly required
- Test on both Linux and macOS (Darwin)
- Use portable shell constructs

### Platform-Specific Considerations
- macOS uses BSD commands (different from GNU)
- Handle path differences appropriately
- Consider package manager differences (Homebrew vs apt)

## File Organization

### File Structure
```bash
# Description: Brief description of file purpose
# File: category_aliases.zsh

# Section 1: Basic Functions
# -------------------------

alias basic-function='() { ... }' # Description

# Section 2: Advanced Functions
# -----------------------------

alias advanced-function='() { ... }' # Description

# Helper Functions
# ----------------

_helper_function() {
    # Helper logic
}
```

### Grouping Guidelines
- Group related functions together
- Use section headers with `#` symbols
- Add separators between sections
- Include comments explaining complex logic
- Add help functions for complex files

### Documentation Comments
- File description at top: `# Description: ...`
- Function descriptions on same line or next line
- Use English for all comments and documentation
- Include examples for complex functions

## Environment Variables and Configuration

### Environment Variables
- Use descriptive names: `BRIA_API_KEY`, `CONFIG_PATH`
- Provide default values when possible
- Document required variables in usage information
- Avoid conflicting with system variables

### Configuration Files
- Use standard paths: `~/.config/tool_name/config`
- Document configuration file format
- Provide fallback values for missing configurations
- Handle configuration file creation if needed

## Code Quality

### Error Handling Examples
```bash
# Good error handling
if [ ! -f "$file_path" ]; then
    echo "Error: File not found: $file_path" >&2
    echo "Please check the file path and try again." >&2
    return 1
fi

# Command execution with error checking
if ! some_command "$param"; then
    echo "Error: Failed to process $param" >&2
    echo "Check input and try again." >&2
    return 1
fi
```

### Code Style
- Use consistent indentation (2 spaces)
- Add comments for complex logic
- Keep functions focused on single responsibility
- Avoid deeply nested conditional logic
- Use early returns for error conditions

## Current Alias Files

The project contains the following alias files:

```
shells/oh-my-zsh/custom/aliases/
├── adb_aliases.zsh              # Android Debug Bridge aliases
├── archive_aliases.zsh          # File compression and extraction
├── audio_aliases.zsh            # Audio processing tools
├── base_aliases.zsh             # Basic shell aliases
├── brew_aliases.zsh             # Homebrew package manager
├── bria_aliases.zsh             # Bria API image processing
├── directory_aliases.zsh        # Directory navigation and management
├── docker_aliases.zsh           # Docker container management
├── docker_app_aliases.zsh       # Docker application aliases
├── filesystem_aliases.zsh       # File system operations
├── git_aliases.zsh              # Git version control
├── help_aliases.zsh             # Help and documentation
├── image_aliases.zsh            # Image processing tools
├── minio_aliases.zsh             # Minio object storage
├── network_aliases.zsh          # Network tools and utilities
├── notification_aliases.zsh     # System notifications
├── other_aliases.zsh            # Miscellaneous aliases
├── pdf_aliases.zsh              # PDF processing tools
├── srv_aliases.zsh              # Server management
├── ssh_aliases.zsh               # SSH connection management
├── ssh_server_aliases.zsh       # SSH server configuration
├── system_aliases.zsh           # System administration
├── tcpdump_aliases.zsh          # Network packet analysis
├── url_aliases.zsh              # URL handling and processing
├── video_aliases.zsh            # Video processing tools
├── vps_aliases.zsh              # Virtual Private Server management
├── web_aliases.zsh              # Web development tools
├── environment_aliases.zsh     # Environment variable management
└── zsh_config_aliases.zsh      # Zsh configuration management
```

## Testing and Validation

### Syntax Testing
```bash
# Test syntax
bash -n alias_file.zsh
zsh -n alias_file.zsh

# Test individual functions
source alias_file.zsh
function_name --help  # Should show usage
```

### Functionality Testing
- Test on both Linux and macOS
- Verify error handling works correctly
- Check parameter validation
- Test edge cases and boundary conditions
- Ensure no conflicts with existing commands

## Best Practices Summary

1. **Always use function format**: `alias name='() { ... }'`
2. **No single quotes in function body**
3. **Use local variables exclusively**
4. **Include comprehensive error handling**
5. **Provide clear usage information**
6. **Follow naming conventions consistently**
7. **Test cross-platform compatibility**
8. **Document thoroughly**
9. **Extract common logic to helper functions**
10. **Avoid conflicts with system commands**

## Integration with Development Workflow

This guide is automatically applied when working with files matching the pattern `shells/oh-my-zsh/custom/aliases/*.zsh`. The Cursor IDE integration ensures these standards are followed during development.

For additional information about the project structure and development workflow, refer to the main [CLAUDE.md](../CLAUDE.md) file.