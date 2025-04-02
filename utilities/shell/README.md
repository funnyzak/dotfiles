# Shell Utilities

This directory contains shell-related utility scripts to enhance your workflow.

## Contents
- [ssh_connect.exp](#ssh_connectexp)
- [frp (Fast Reverse Proxy)](#frp-fast-reverse-proxy)

## ssh_connect.exp

`ssh_connect.exp` is a versatile Expect script designed to automate SSH connections to multiple servers. It supports both key-based and password-based authentication, with configurable retry logic and server selection.

**Tips:** You can quickly set up ssh_connect.exp with the following script:

```bash
curl -s https://raw.githubusercontent.com/funnyzak/dotfiles/refs/heads/main/utilities/shell/sshc/setup.sh | bash
```

### Features
- **Interactive Mode**: Displays a list of servers for user selection.
- **Non-Interactive Mode**: Connect directly to a server using its ID via command-line arguments or environment variables.
- **Flexible Authentication**: Supports SSH key files or passwords.
- **Retry Mechanism**: Automatically retries failed connections with configurable attempts and timeouts.
- **Environment Variable Support**: Customize behavior without modifying the script.
- **Extensible Configuration**: Manage server details in an external configuration file.

### Requirements
- `expect` installed on your system (`sudo apt install expect` on Debian/Ubuntu, `brew install expect` on macOS, etc.).
- SSH client installed (`openssh-client`).

### Usage

#### Interactive Mode
Run the script without arguments to see a list of servers and select one:
```bash
./ssh_connect.exp
```

#### Non-Interactive Mode
Connect directly to a server by specifying its ID:
```bash
./ssh_connect.exp web1
```
Or use an environment variable:
```bash
TARGET_SERVER_ID=web1 ./ssh_connect.exp
```

#### Custom Configuration
Specify a custom configuration file:
```bash
SERVERS_CONFIG=/path/to/custom.conf ./ssh_connect.exp
```

#### Advanced Options
Override default timeout and retry attempts:
```bash
SSH_TIMEOUT=60 SSH_MAX_ATTEMPTS=5 ./ssh_connect.exp
```

### Environment Variables
- **`SERVERS_CONFIG`**: Path to the server configuration file. Default: `servers.conf`.
- **`TARGET_SERVER_ID`**: Server ID for non-interactive connection. No default.
- **`SSH_TIMEOUT`**: Connection timeout in seconds. Default: `30`.
- **`SSH_MAX_ATTEMPTS`**: Maximum number of connection attempts. Default: `3`.
- **`SSH_DEFAULT_SHELL`**: Shell to switch to after login (e.g., zsh, bash, fish).

### Configuration File
The script reads server details from a configuration file. See `servers.conf.example` for the format:
```
# Format: ID,Name,Host,Port,User,AuthType,AuthValue
web1,Web Server 1,192.168.1.10,22,root,key,/home/user/.ssh/web1.key
db1,Database Server 1,192.168.1.20,22,root,password,securepass123
app1,App Server 1,192.168.1.30,2222,admin,key,/home/user/.ssh/app1.key
```
- **ID**: Unique identifier for the server.
- **Name**: Human-readable server name.
- **Host**: IP address or hostname.
- **Port**: SSH port number.
- **User**: SSH username.
- **AuthType**: `key` or `password`.
- **AuthValue**: Path to key file or plaintext password.

### Installation
1. **Copy the Script**:
   Place `ssh_connect.exp` in a directory in your PATH (e.g., `~/bin`):
   ```bash
   mkdir -p ~/bin
   cp ssh_connect.exp ~/bin/ssh_connect
   chmod +x ~/bin/ssh_connect
   ```

2. **Set Up Configuration**:
   Copy the example config to your home directory and edit it:
   ```bash
   cp servers.conf.example ~/.servers.conf
   # Edit ~/.servers.conf with your server details
   ```

3. **Configure Shell**:
   Add these lines to your shell configuration (e.g., `~/.zshrc` or `~/.bashrc`):
   ```bash
   export SERVERS_CONFIG=~/.servers.conf
   alias sshc='~/bin/ssh_connect'
   ```
   Reload your shell:
   ```bash
   source ~/.zshrc  # or ~/.bashrc
   ```

4. **Verify**:
   Test the script:
   ```bash
   sshc  # Interactive mode
   sshc web1  # Direct connection
   ```

### Example Workflow
1. Configure `~/.servers.conf` with your servers.
2. Use the alias:
   ```bash
   sshc  # Choose a server from the list
   sshc db1  # Connect to Database Server 1
   ```

### Notes
- **Security**: Avoid storing sensitive passwords in plain text. Consider using SSH keys or a password manager.
- **Permissions**: Ensure `ssh_connect.exp` is executable (`chmod +x`) and the configuration file is readable only by you (`chmod 600 ~/.servers.conf`).
- **Troubleshooting**: If connections fail, check your SSH keys, network, and server availability.

## frp (Fast Reverse Proxy)

`install_frpc.sh` is a comprehensive installation and management script for FRP Client (frpc), which helps establish secure connections between local and remote networks through NAT or firewalls.

### Features
- **Complete Installation**: Automated installation and configuration of frpc.
- **Multiple Configuration Methods**: Support for URL-based, local file, or interactive configuration.
- **Customizable Paths**: Flexible installation and configuration paths.
- **Service Management**: Automatic systemd service setup and management.
- **Uninstallation Support**: Clean removal of frpc installation when needed.

### Requirements
- Linux-based operating system with systemd
- Root or sudo privileges
- curl or wget for downloading packages

### Usage

#### Installation
```bash
# Basic installation with token
./install_frpc.sh install --token my-token-value

# Installation with URL configuration
./install_frpc.sh install --token my-token-value --config-url http://example.com/frpc.toml

# Installation with local configuration file
./install_frpc.sh install --token my-token-value --config-file ./my-frpc.toml

# Interactive configuration
./install_frpc.sh install --token my-token-value --interactive

# Installation with custom paths
./install_frpc.sh install --token my-token-value --install-path /usr/local/frpc --config-path /etc/frpc.toml
```

#### Management
```bash
# Show current configuration
./install_frpc.sh config

# Show usage tips
./install_frpc.sh tips

# Uninstall frpc
./install_frpc.sh uninstall
```

#### Remote Execution
```bash
# Remote installation example
curl -sSL https://gitee.com/funnyzak/dotfiless/raw/main/utilities/shell/frp/install_frpc.sh | bash -s install --token your_token --config-url http://example.com/frpc.toml
```

### Options for Install Command
- `--token <value>`: Set the FRP server token (required)
- `--config-url <url>`: Download configuration from URL
- `--config-file <path>`: Use local configuration file
- `--interactive`: Enter interactive configuration mode
- `--frp-download-url <url>`: Custom download URL for frpc package
- `--install-path <path>`: Custom installation path
- `--config-path <path>`: Custom config file path
- `--version <version>`: Specific version to install

### Environment Variables
- `FRPC_INSTALL_PATH`: Custom installation path (default: /opt/frpc)
- `FRPC_CONFIG_PATH`: Custom config path (default: /etc/frp/frpc.toml)
- `FRPC_DOWNLOAD_URL`: Custom download URL for frpc package
- `FRPC_VERSION`: Specific version to install (default: 0.61.2)
- `FRPC_TOKEN`: FRP server token

### Notes
- For security, the script validates all inputs and configurations.
- The script creates a systemd service for automatic startup and management.
- Configuration files are backed up before any changes.
- Logs are available in the system journal (`journalctl -u frpc`).
