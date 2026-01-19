# Shell Utilities

This directory contains shell-related utility scripts to enhance your workflow.

## Contents
- [ssh_connect.exp](#ssh_connectexp)
- [ssh_port_forward.exp](#ssh_port_forwardexp)
- [alist_upload.sh](#alist_uploadsh)
- [mysql_backup.sh](#mysql_backupsh)

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

## ssh_port_forward.exp

`ssh_port_forward.exp` is an advanced Expect script designed to automate SSH connections with port forwarding capabilities. It extends the functionality of `ssh_connect.exp` by adding support for multiple local-to-remote port mappings, making it ideal for accessing remote services through SSH tunnels.

**Tips:** You can quickly set up ssh_port_forward.exp with the following script:

```bash
curl -s https://raw.githubusercontent.com/funnyzak/dotfiles/refs/heads/main/utilities/shell/sshc/setup.sh | bash
```

### Features
- **Multiple Port Forwarding**: Configure multiple local-to-remote port mappings per server with flexible format support
- **Port Conflict Detection**: Automatically detects and warns about port conflicts before attempting connection
- **Interactive Mode**: Displays a list of servers with their port mappings for user selection
- **Non-Interactive Mode**: Connect directly to a server using its ID via command-line arguments
- **Flexible Authentication**: Supports SSH key files or passwords
- **Retry Mechanism**: Automatically retries failed connections with configurable attempts and timeouts
- **Keep-Alive Support**: Configurable SSH keep-alive settings for stable connections
- **Environment Variable Support**: Customize behavior without modifying the script
- **Extensible Configuration**: Manage server details and port mappings in an external configuration file
- **Color-Coded Output**: Enhanced user experience with colored terminal output
- **Enhanced Error Handling**: Comprehensive error handling with detailed troubleshooting information

### Requirements
- `expect` installed on your system (`sudo apt install expect` on Debian/Ubuntu, `brew install expect` on macOS, etc.)
- SSH client installed (`openssh-client`)

### Usage

#### Interactive Mode
Run the script without arguments to see a list of servers and select one:
```bash
./ssh_port_forward.exp
```

#### Non-Interactive Mode
Connect directly to a server by specifying its ID or number:
```bash
./ssh_port_forward.exp web1     # Connect using server ID
./ssh_port_forward.exp 2        # Connect using server number (2nd server in list)
```
Or use environment variables:
```bash
TARGET_SERVER_ID=web1 ./ssh_port_forward.exp    # Connect using server ID
TARGET_SERVER_NUM=3 ./ssh_port_forward.exp      # Connect using server number (3rd server in list)
```

#### Custom Configuration
Specify a custom configuration file:
```bash
PORT_FORWARD_CONFIG=/path/to/custom.conf ./ssh_port_forward.exp
```

#### Advanced Options
Override default timeout and retry attempts:
```bash
SSH_TIMEOUT=60 SSH_MAX_ATTEMPTS=5 ./ssh_port_forward.exp
```

### Environment Variables
- **`PORT_FORWARD_CONFIG`**: Path to the port forward configuration file. Default: `~/.ssh/port_forward.conf`
- **`TARGET_SERVER_ID`**: Server ID for non-interactive connection. No default.
- **`TARGET_SERVER_NUM`**: Server number (index) for non-interactive connection. No default.
- **`SSH_TIMEOUT`**: Connection timeout in seconds. Default: `300`
- **`SSH_CONNECTION_TIMEOUT`**: SSH connection timeout in seconds. Default: `60`
- **`SSH_MAX_ATTEMPTS`**: Maximum number of connection attempts. Default: `5`
- **`SSH_NO_COLOR`**: Disable colored output. Default: `0` (enabled)
- **`SSH_KEEP_ALIVE`**: Enable SSH keep-alive. Default: `1` (enabled)
- **`SSH_ALIVE_INTERVAL`**: Keep-alive interval in seconds. Default: `15`
- **`SSH_ALIVE_COUNT`**: Maximum keep-alive count. Default: `10`
- **`SSH_TCP_KEEP_ALIVE`**: Enable TCP keep-alive. Default: `1` (enabled)
- **`SSH_DEFAULT_SHELL`**: Shell to switch to after login (e.g., zsh, bash, fish)

### Configuration File
The script reads server details and port mappings from a configuration file. See `port_forward.conf.example` for the format:
```
# Format: ID,Name,Host,Port,User,AuthType,AuthValue,PortMapping1,PortMapping2,...
web1,Web Server 1,192.168.1.10,22,root,key,~/.ssh/web1.key,8080:80,3306:3306,6379:6379
db1,Database Server 1,192.168.1.20,22,root,password,securepass123,3307:3306,6379:6379
app1,App Server 1,192.168.1.30,2222,admin,key,~/.ssh/app1.key,8081:80,8082:443,3308:3306
```

- **ID**: Unique identifier for the server
- **Name**: Human-readable server name
- **Host**: IP address or hostname
- **Port**: SSH port number
- **User**: SSH username
- **AuthType**: `key` or `password`
- **AuthValue**: Path to key file or plaintext password
- **PortMappings**: Multiple port mapping fields in format "local_port:remote_port"

### Port Mapping Format
Port mappings follow the format `local_port:remote_port` and support multiple configuration methods:
- **local_port**: Port on your local machine that will forward to the remote server
- **remote_port**: Port on the remote server that you want to access
- **Method 1 - Separate fields**: `...,8080:80,3306:3306,6379:6379`
- **Method 2 - Comma-separated in one field**: `...,8080:80,3306:3306,6379:6379`
- **Method 3 - Mixed approach**: Both methods can be used together

### Installation
1. **Copy the Script**:
   Place `ssh_port_forward.exp` in a directory in your PATH (e.g., `~/bin`):
   ```bash
   mkdir -p ~/bin
   cp ssh_port_forward.exp ~/bin/ssh_port_forward
   chmod +x ~/bin/ssh_port_forward
   ```

2. **Set Up Configuration**:
   Copy the example config to your SSH directory and edit it:
   ```bash
   cp port_forward.conf.example ~/.ssh/port_forward.conf
   # Edit ~/.ssh/port_forward.conf with your server details and port mappings
   ```

3. **Configure Shell**:
   Add these lines to your shell configuration (e.g., `~/.zshrc` or `~/.bashrc`):
   ```bash
   export PORT_FORWARD_CONFIG=~/.ssh/port_forward.conf
   alias sshpf='~/bin/ssh_port_forward'
   ```
   Reload your shell:
   ```bash
   source ~/.zshrc  # or ~/.bashrc
   ```

4. **Verify**:
   Test the script:
   ```bash
   sshpf  # Interactive mode
   sshpf web1  # Direct connection with port forwarding
   ```

### Example Workflow
1. Configure `~/.ssh/port_forward.conf` with your servers and port mappings
2. Use the alias:
   ```bash
   sshpf                    # Choose a server from the list
   sshpf db1                # Connect to Database Server 1 with port forwarding
   sshpf 2                  # Connect to the second server in the list
   sshpf ali-bj-main        # Connect to server with ID 'ali-bj-main'
   ```

### Common Use Cases
- **Web Development**: Forward local port 8080 to remote port 80 for web server access
- **Database Access**: Forward local port 3307 to remote MySQL port 3306
- **Redis Access**: Forward local port 6379 to remote Redis port 6379
- **Multiple Services**: Forward multiple ports simultaneously for complex applications

### Port Conflict Detection
The script automatically detects port conflicts before attempting connections and provides helpful suggestions:
- **Conflict Detection**: Checks if local ports are already in use before connecting
- **Alternative Ports**: Suggests available alternative ports when conflicts are detected
- **Error Prevention**: Prevents connection attempts when port conflicts exist
- **Troubleshooting**: Provides commands to identify and resolve port conflicts

### Troubleshooting
If you encounter issues:
1. **Port Conflicts**: The script will detect and warn about port conflicts
   - Use `lsof -i :PORT_NUMBER` to see what's using a port
   - Kill processes with `kill -9 PID` if needed
   - Choose alternative ports as suggested by the script

2. **Connection Issues**: Check SSH connectivity and authentication
   - Verify SSH keys exist and have correct permissions
   - Test basic SSH connection without port forwarding
   - Check network connectivity and firewall settings

3. **Configuration Issues**: Validate your configuration file
   - Ensure port mappings use valid integer port numbers
   - Check that SSH key files exist and are readable
   - Verify server details are correct

### Notes
- **Security**: Avoid storing sensitive passwords in plain text. Consider using SSH keys or a password manager
- **Permissions**: Ensure `ssh_port_forward.exp` is executable (`chmod +x`) and the configuration file is readable only by you (`chmod 600 ~/.ssh/port_forward.conf`)
- **Port Management**: The script helps manage port conflicts but you should still plan your port usage carefully
- **Firewall**: Make sure your local firewall allows connections to the forwarded ports
- **Connection Stability**: Enhanced keep-alive settings provide better connection stability for long-running sessions

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

## mysql_backup.sh

`mysql_backup.sh` is a professional MySQL database backup script with comprehensive features for enterprise-grade database backup operations. It supports multi-database backup, configuration files, notification systems, logging, automatic cleanup, and more advanced features.

**Tips:** You can quickly execute the script remotely:

```bash
bash <(curl -fsSL https://gitee.com/funnyzak/dotfiles/raw/main/utilities/shell/mysql/mysql_backup.sh)
```

### Features
- **Multi-Database Support**: Backup all databases or specific databases with comma-separated list
- **Sequential Processing**: Reliable sequential backup operations for data integrity
- **Configuration Files**: YAML configuration file support for complex setups
- **Notification System**: Integrated Apprise and Bark notification support for backup status
- **Comprehensive Logging**: Detailed logging with multiple log levels and optional file output
- **Automatic Cleanup**: Configurable retention policy for old backup files
- **Compression Support**: Optional tar.gz compression for backup files
- **Pre/Post Commands**: Execute custom commands before and after backup operations
- **Environment Variables**: Full environment variable support for automation
- **Cross-Platform**: Support for Ubuntu, Debian, CentOS, RHEL, and macOS
- **Auto-Installation**: Automatic MySQL client installation if not present
- **Error Handling**: Comprehensive error handling with detailed statistics reporting
- **Remote Execution**: Support for direct remote execution from repository

### Requirements
- `mysqldump` (auto-installed if missing)
- `tar`, `gzip` (system built-in)
- `curl` (for notifications)
- `yq` (YAML parsing, optional)

### Usage

#### Basic Usage
Backup all databases with default settings:
```bash
./mysql_backup.sh
```

#### Backup Specific Databases
Backup specific databases to a custom directory:
```bash
./mysql_backup.sh -h 192.168.1.100 -u root -p mypass -d "wordpress,nextcloud" -o /backup/mysql
```

#### Enable Compression and Retention
Use compression and retention cleanup:
```bash
./mysql_backup.sh -c -r 30 -v
```

#### Using Configuration File
Use a YAML configuration file:
```bash
./mysql_backup.sh -f ./mysql_backup.yaml
```

#### Enable Notifications
Configure notification services:
```bash
./mysql_backup.sh --apprise-url "http://localhost:8000/notify" --bark-url "https://api.day.app" --bark-key "your_key"
```

#### Remote Execution
Execute directly from the repository:
```bash
# Basic remote execution
bash <(curl -fsSL https://gitee.com/funnyzak/dotfiles/raw/main/utilities/shell/mysql/mysql_backup.sh)

# With parameters
bash <(curl -fsSL https://gitee.com/funnyzak/dotfiles/raw/main/utilities/shell/mysql/mysql_backup.sh) \
  -h localhost -u backup_user -p backup_pass -d "db1,db2" -o /backup -c

# Using remote configuration file
curl -fsSL https://gitee.com/funnyzak/dotfiles/raw/main/utilities/shell/mysql/mysql_backup.yaml > /tmp/backup.yaml
bash <(curl -fsSL https://gitee.com/funnyzak/dotfiles/raw/main/utilities/shell/mysql/mysql_backup.sh) \
  -f /tmp/backup.yaml
```

### Environment Variables
- **`MYSQL_HOST`**: MySQL server address (default: 127.0.0.1)
- **`MYSQL_PORT`**: MySQL port (default: 3306)
- **`MYSQL_USER`**: MySQL username (default: root)
- **`MYSQL_PASSWORD`**: MySQL password (default: root)
- **`BACKUP_OUTPUT_DIR`**: Backup output directory (default: ./)
- **`BACKUP_RETENTION_DAYS`**: Backup retention days (default: 0)
- **`APPRISE_URL`**: Apprise notification URL
- **`APPRISE_TAGS`**: Apprise notification tags (default: all)
- **`BARK_URL`**: Bark server URL
- **`BARK_KEY`**: Bark device key

### Command Line Parameters
- **`-n, --name`**: Instance name for notifications (default: hostname)
- **`-h, --host`**: MySQL server address
- **`-P, --port`**: MySQL port
- **`-u, --user`**: MySQL username
- **`-p, --password`**: MySQL password
- **`-d, --databases`**: Database names to backup (comma-separated)
- **`-o, --output`**: Backup file output directory
- **`-s, --suffix`**: Backup file suffix (default: sql)
- **`-e, --extra-opts`**: Additional mysqldump parameters
- **`--pre-cmd`**: Command to execute before backup
- **`--post-cmd`**: Command to execute after backup
- **`-c, --compress`**: Use tar compression for backup files

- **`-r, --retention`**: Backup retention days (0 means no cleanup)
- **`-l, --log-dir`**: Log file directory
- **`-v, --verbose`**: Enable verbose debug output
- **`-f, --config`**: Configuration file path
- **`--apprise-url`**: Apprise notification URL
- **`--apprise-tags`**: Apprise notification tags
- **`--bark-url`**: Bark server URL
- **`--bark-key`**: Bark device key
- **`--help`**: Show help information

### Configuration File
The script supports YAML configuration files for complex setups:
```yaml
# MySQL connection settings
general:
  # Instance name for notifications (default: hostname)
  name: ""

# MySQL connection configuration
mysql:
  host: "127.0.0.1"
  port: 3306
  user: "root"
  password: "root"
  # Database list for backup, empty string means backup all databases, or specify database names: "db1,db2,db3"
  databases: ""

# Backup configuration
backup:
  output_dir: "./"
  file_suffix: "sql"
  extra_options: "--ssl-mode=DISABLED --single-transaction --routines --triggers --events --hex-blob --complete-insert"
  compress: true
  # Backup retention days, 0 means skip backup file cleanup
  retention_days: 180

# Command execution configuration
commands:
  # Command to execute before backup, e.g.: "echo 'Starting backup...'"
  pre_backup: ""
  # Command to execute after backup, e.g.: "echo 'Backup completed'"
  post_backup: ""

# Logging configuration
logging:
  # Log directory, empty means no log file recording
  log_dir: ""
  # Enable verbose output
  verbose: false

# Notification configuration
notifications:
  apprise:
    # Apprise server URL, e.g.: "http://localhost:8000/notify/wgzryvfbmwoybymj"
    # Leave empty to disable Apprise notifications
    url: ""
    # Notification tags (default: "all")
    tags: "all"
  bark:
    # Bark server URL, e.g.: "https://api.day.app"
    # Leave empty to disable Bark notifications
    url: ""
    # Bark device key (required if bark url is set)
    # Get this from your Bark app
    device_key: ""
```

### Installation
1. **Download the Script**:
   ```bash
   curl -fsSL -o mysql_backup.sh https://gitee.com/funnyzak/dotfiles/raw/main/utilities/shell/mysql/mysql_backup.sh
   chmod +x mysql_backup.sh
   ```

2. **Set Up Environment Variables** (Optional):
   Add to your shell configuration (e.g., `~/.zshrc` or `~/.bashrc`):
   ```bash
   export MYSQL_HOST="your-mysql-server.com"
   export MYSQL_USER="backup_user"
   export MYSQL_PASSWORD="secure_password"
   export BACKUP_OUTPUT_DIR="/backup/mysql"
   export BACKUP_RETENTION_DAYS="30"
   ```

3. **Create Configuration File** (Optional):
   ```bash
   cp mysql_backup.yaml.example mysql_backup.yaml
   # Edit mysql_backup.yaml with your settings
   ```

4. **Set Up Cron Job** (Optional):
   ```bash
   # Daily backup at 2 AM
   0 2 * * * /path/to/mysql_backup.sh -f /path/to/mysql_backup.yaml
   ```

### Example Workflow
1. Configure environment variables or create a YAML configuration file
2. Run backup operations:
   ```bash
   ./mysql_backup.sh                                    # Basic backup with defaults
   ./mysql_backup.sh -d "app_db,user_db" -c            # Backup specific databases with compression
   ./mysql_backup.sh -f production.yaml                # Use configuration file
   ./mysql_backup.sh -v -r 7 --apprise-url "http://localhost:8000/notify"  # Verbose with cleanup and notifications
   ```

### Backup Statistics
The script provides comprehensive backup statistics including:
- Total databases processed
- Successful and failed backup counts
- Total backup file size
- Backup duration
- Individual file sizes and names

### Notes
- **Security**: Avoid storing passwords in plain text. Use environment variables or secure credential management.
- **Permissions**: Ensure the script has appropriate permissions and the backup directory is writable.
- **MySQL Client**: The script automatically installs MySQL client if not present on supported systems.
- **Sequential Processing**: Uses sequential processing to ensure data integrity and avoid system overload.
- **File Naming**: Backup files are named with database name and timestamp for easy identification.
- **Compression**: When enabled, creates tar.gz files and removes original SQL files.
- **Notifications**: Supports both Apprise (universal notification) and Bark (iOS) notification services.
- **Error Recovery**: Comprehensive error handling with automatic cleanup of failed backup files.

