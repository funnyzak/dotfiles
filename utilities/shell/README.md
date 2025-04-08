# Shell Utilities

This directory contains shell-related utility scripts to enhance your workflow.

## Contents
- [ssh_connect.exp](#ssh_connectexp)

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
Connect directly to a server by specifying its ID or number:
```bash
./ssh_connect.exp web1     # Connect using server ID
./ssh_connect.exp 2        # Connect using server number (2nd server in list)
```
Or use environment variables:
```bash
TARGET_SERVER_ID=web1 ./ssh_connect.exp    # Connect using server ID
TARGET_SERVER_NUM=3 ./ssh_connect.exp      # Connect using server number (3rd server in list)
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
- **`TARGET_SERVER_NUM`**: Server number (index) for non-interactive connection. No default.
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

