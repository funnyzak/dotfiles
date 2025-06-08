# Shell Utilities

This directory contains shell-related utility scripts to enhance your workflow.

## Contents
- [ssh_connect.exp](#ssh_connectexp)
- [alist_upload.sh](#alist_uploadsh)

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

## alist_upload.sh

`alist_upload.sh` is a comprehensive shell script for uploading files to AList storage via API. It features automatic authentication with token caching, multiple file upload support, and comprehensive error handling.

**Tips:** You can quickly execute the script remotely:

```bash
curl -fsSL https://gitee.com/funnyzak/dotfiles/raw/main/utilities/shell/alist/alist_upload.sh | bash -s -- file1.txt file2.pdf
```

### Features
- **Multiple File Upload**: Upload single or multiple files in one command
- **API Authentication**: Automatic token management with 24-hour validity caching
- **Command Line Support**: Full parameter support for all configuration options
- **Environment Variables**: Configure via environment variables for automation
- **Automatic Token Refresh**: Seamless token renewal when expired on 401 errors
- **Custom Remote Paths**: Upload files to specific directories
- **Token Caching Control**: Option to disable token caching with `--no-cache`
- **Comprehensive Logging**: Detailed error handling and verbose output options
- **Remote Execution**: Support for direct remote execution from repository
- **Batch Processing**: Upload multiple files with progress tracking and summary reporting

### Requirements
- `curl` installed on your system
- `jq` (optional, for better JSON parsing)
- Valid AList server with API access

### Usage

#### Basic Usage
Upload a single file to the root directory:
```bash
./alist_upload.sh file1.txt
```

Upload multiple files to the root directory:
```bash
./alist_upload.sh file1.txt file2.pdf ./path/file3.jpg
```

#### Specify Remote Path
Upload multiple files to a specific remote directory:
```bash
./alist_upload.sh -r /documents file1.txt file2.pdf
```

#### Full Parameter Configuration
Specify all parameters via command line:
```bash
./alist_upload.sh -a https://api.example.com -u username -p password -r /backup file1.txt file2.pdf
```

#### Using Environment Variables
Configure via environment variables:
```bash
export ALIST_API_URL="https://api.example.com"
export ALIST_USERNAME="myuser"
export ALIST_PASSWORD="mypass"
./alist_upload.sh file1.txt file2.pdf
```

#### Disable Token Caching
Upload without using cached tokens:
```bash
./alist_upload.sh --no-cache file1.txt
```

#### Verbose Output
Enable detailed logging:
```bash
./alist_upload.sh -v file1.txt file2.pdf
```

### Environment Variables
- **`ALIST_API_URL`**: API base URL (e.g., http://prod-cn.your-api-server.com)
- **`ALIST_USERNAME`**: Username for authentication
- **`ALIST_PASSWORD`**: Password for authentication
- **`ALIST_TOKEN`**: Pre-existing authentication token (optional)

### Command Line Parameters
- **`-a, --api-url`**: API base URL
- **`-u, --username`**: Username for authentication
- **`-p, --password`**: Password for authentication
- **`-t, --token`**: Pre-existing authentication token
- **`-r, --remote-path`**: Remote upload path (default: /)
- **`--no-cache`**: Disable token caching (login for each upload)
- **`-v, --verbose`**: Enable verbose output
- **`-h, --help`**: Show help message

### Remote Execution
Execute directly from the repository without downloading:
```bash
# Direct remote execution - single file
curl -fsSL https://gitee.com/funnyzak/dotfiles/raw/main/utilities/shell/alist/alist_upload.sh | bash -s -- file1.txt

# Direct remote execution - multiple files
curl -fsSL https://gitee.com/funnyzak/dotfiles/raw/main/utilities/shell/alist/alist_upload.sh | bash -s -- file1.txt file2.pdf

# With parameters
curl -fsSL https://gitee.com/funnyzak/dotfiles/raw/main/utilities/shell/alist/alist_upload.sh | bash -s -- -r /documents file1.txt file2.pdf
```

### Installation
1. **Download the Script**:
   ```bash
   curl -fsSL -o alist_upload.sh https://gitee.com/funnyzak/dotfiles/raw/main/utilities/shell/alist/alist_upload.sh
   chmod +x alist_upload.sh
   ```

2. **Set Up Environment Variables** (Optional):
   Add to your shell configuration (e.g., `~/.zshrc` or `~/.bashrc`):
   ```bash
   export ALIST_API_URL="https://your-alist-server.com"
   export ALIST_USERNAME="your-username"
   export ALIST_PASSWORD="your-password"
   ```

3. **Create Alias** (Optional):
   ```bash
   alias alist-upload='/path/to/alist_upload.sh'
   ```

### Example Workflow
1. Configure environment variables or prepare command line parameters
2. Upload files:
   ```bash
   ./alist_upload.sh document.pdf                                    # Upload single file to root
   ./alist_upload.sh document.pdf image.jpg archive.zip              # Upload multiple files to root
   ./alist_upload.sh -r /backup important.zip data.csv               # Upload multiple files to /backup directory
   ./alist_upload.sh -v -r /documents report.docx presentation.pptx  # Upload with verbose output
   ./alist_upload.sh --no-cache file1.txt file2.pdf                  # Upload without token caching
   ```

### Token Caching
The script automatically caches authentication tokens in `~/.cache/alist/token` with 24-hour validity. This improves performance by avoiding repeated authentication requests. Token caching can be disabled using the `--no-cache` option for scenarios requiring fresh authentication for each upload.

### Notes
- **Security**: Avoid storing passwords in plain text. Consider using environment variables or secure credential management.
- **File Validation**: The script validates file existence and readability before upload.
- **Error Handling**: Comprehensive error handling with automatic token refresh on 401 errors.
- **Path Normalization**: Remote paths are automatically normalized (leading slash added, trailing slash removed).
- **Batch Processing**: Multiple files are uploaded sequentially with progress tracking and final summary reporting.
- **Performance**: Small delay (0.5s) between uploads to avoid overwhelming the server.

