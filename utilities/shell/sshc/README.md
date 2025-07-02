# SSH Port Forward Tool

A powerful SSH port forwarding tool that supports multiple port mappings with server configuration management.

## Features

- **Multiple Port Forwarding**: Support for multiple local-to-remote port mappings
- **Server Configuration**: CSV-based configuration file for easy server management
- **Authentication Support**: Both SSH key and password authentication
- **Interactive Mode**: User-friendly interactive server selection
- **Environment Variables**: Configurable behavior through environment variables
- **Cross-platform**: Works on Linux and macOS
- **Colored Output**: Beautiful colored terminal output (can be disabled)

## Installation

### Prerequisites

- `expect` (required for automation)
- `bash` or `zsh` shell

### Install expect

**macOS:**
```bash
brew install expect
```

**Ubuntu/Debian:**
```bash
sudo apt-get install expect
```

**CentOS/RHEL:**
```bash
sudo yum install expect
```

### Setup the Tool

1. **Automatic Setup (Recommended):**
   ```bash
   ssh-port-forward-setup
   ```

2. **Manual Setup:**
   ```bash
   # Copy the expect script
   cp ssh_port_forward.exp ~/.ssh/
   chmod +x ~/.ssh/ssh_port_forward.exp

   # Copy the configuration example
   cp port_forward.conf.example ~/.ssh/port_forward.conf
   chmod 600 ~/.ssh/port_forward.conf

   # Add alias to your shell configuration
   echo 'alias ssh-port-forward="~/.ssh/ssh_port_forward.exp"' >> ~/.zshrc
   source ~/.zshrc
   ```

## Configuration

### Configuration File Format

The configuration file (`~/.ssh/port_forward.conf`) uses CSV format:

```csv
ID,Name,Host,Port,User,AuthType,AuthValue,PortMappings
```

**Fields:**
- `ID`: Unique identifier for the server
- `Name`: Descriptive name of the server
- `Host`: IP address or hostname
- `Port`: SSH port number
- `User`: SSH username
- `AuthType`: `key` or `password`
- `AuthValue`: Path to key file or password
- `PortMappings`: Comma-separated list of `local:remote` port mappings

### Example Configuration

```csv
# Web server with HTTP and MySQL forwarding
web1,Web Server 1,192.168.1.10,22,root,key,~/.ssh/web1.key,8080:80,3306:3306

# Database server with MySQL and Redis forwarding
db1,Database Server 1,192.168.1.20,22,root,password,securepass123,3307:3306,6379:6379

# App server with multiple services
app1,App Server 1,192.168.1.30,2222,admin,key,~/.ssh/app1.key,8081:80,8082:443,3308:3306
```

### Port Mapping Format

Port mappings use the format `local_port:remote_port`:

- `8080:80` - Forward local port 8080 to remote port 80
- `3306:3306` - Forward local port 3306 to remote port 3306
- `8081:80,8082:443` - Multiple mappings separated by commas

## Usage

### Basic Usage

1. **Interactive Mode:**
   ```bash
   ssh-port-forward
   ```
   This will show a list of available servers and prompt for selection.

2. **Direct Connection:**
   ```bash
   ssh-port-forward web1
   ```
   Connect directly to server with ID `web1`.

### Available Commands

- `ssh-port-forward [server_id]` - Connect with port forwarding
- `ssh-port-forward-setup` - Setup the tool
- `ssh-port-forward-config [editor]` - Edit configuration file
- `sshpf [server_id]` - Short alias for ssh-port-forward
- `sshpfc [editor]` - Short alias for ssh-port-forward-config

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT_FORWARD_CONFIG` | Custom config file path | `~/.ssh/port_forward.conf` |
| `SSH_TIMEOUT` | Connection timeout in seconds | `30` |
| `SSH_MAX_ATTEMPTS` | Max connection attempts | `3` |
| `SSH_NO_COLOR` | Disable colored output | `disabled` |
| `SSH_KEEP_ALIVE` | Enable keep-alive packets | `1` |
| `SSH_ALIVE_INTERVAL` | Keep-alive interval in seconds | `60` |
| `SSH_ALIVE_COUNT` | Keep-alive count | `3` |
| `SSH_DEFAULT_SHELL` | Default shell after login | `none` |

## Examples

### Example 1: Web Development

Configure a web server with port forwarding:

```csv
dev-server,Development Server,192.168.1.100,22,developer,key,~/.ssh/dev.key,3000:3000,8080:80,3306:3306
```

Connect and access:
- Local development server: `http://localhost:3000`
- Web server: `http://localhost:8080`
- Database: `localhost:3306`

### Example 2: Database Access

Configure a database server:

```csv
db-server,Database Server,10.0.0.50,22,dbuser,password,mypassword,3307:3306,6379:6379,5432:5432
```

Connect and access:
- MySQL: `localhost:3307`
- Redis: `localhost:6379`
- PostgreSQL: `localhost:5432`

### Example 3: Multiple Services

Configure a server with multiple services:

```csv
app-server,Application Server,app.example.com,2222,admin,key,~/.ssh/app.key,8081:80,8082:443,3308:3306,9000:9000
```

## Troubleshooting

### Common Issues

1. **Permission denied:**
   - Check SSH key permissions (should be 600)
   - Verify username and authentication method
   - Ensure SSH key is added to SSH agent

2. **Connection timeout:**
   - Check network connectivity
   - Verify host and port
   - Increase `SSH_TIMEOUT` environment variable

3. **Port already in use:**
   - Check if local ports are already bound
   - Use different local ports in configuration

4. **Configuration file not found:**
   - Run `ssh-port-forward-setup` to create configuration
   - Check `PORT_FORWARD_CONFIG` environment variable

### Debug Mode

Enable debug output by setting environment variables:

```bash
export SSH_NO_COLOR=1
export SSH_TIMEOUT=60
ssh-port-forward
```

## Security Considerations

1. **File Permissions:**
   - Configuration file should have 600 permissions
   - SSH keys should have 600 permissions
   - SSH directory should have 700 permissions

2. **Password Storage:**
   - Avoid storing passwords in configuration files
   - Use SSH keys for authentication when possible
   - Consider using SSH agent for key management

3. **Network Security:**
   - Use SSH tunnels over untrusted networks
   - Consider using VPN for additional security
   - Regularly update SSH keys and passwords

## Integration with Existing SSH Aliases

This tool integrates with the existing SSH aliases in the dotfiles:

- `ssh-help` - Shows help for all SSH functions including port forwarding
- `ssh-key-generate` - Generate SSH keys for authentication
- `ssh-key-copy` - Copy SSH keys to remote servers
- `ssh-agent-start` - Start SSH agent and load keys

## Contributing

To contribute to this tool:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This tool is part of the dotfiles project and follows the same license terms.
