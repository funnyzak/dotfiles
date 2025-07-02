#!/bin/bash
# Setup script for SSH Port Forward Tool

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}SUCCESS: $1${NC}"
}

print_info() {
    echo -e "${BLUE}INFO: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

# Check if expect is installed
check_expect() {
    if ! command -v expect &> /dev/null; then
        print_error "expect is not installed. Please install it first."
        echo "On macOS: brew install expect"
        echo "On Ubuntu/Debian: sudo apt-get install expect"
        echo "On CentOS/RHEL: sudo yum install expect"
        return 1
    fi
    return 0
}

# Create SSH directory if it doesn't exist
create_ssh_directory() {
    if [[ ! -d "$HOME/.ssh" ]]; then
        print_info "Creating SSH directory..."
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"

        if [[ $? -ne 0 ]]; then
            print_error "Failed to create SSH directory"
            return 1
        fi
    fi
    return 0
}

# Copy expect script to SSH directory
copy_expect_script() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local expect_script="$script_dir/ssh_port_forward.exp"
    local target_script="$HOME/.ssh/ssh_port_forward.exp"

    if [[ ! -f "$expect_script" ]]; then
        print_error "Expect script not found: $expect_script"
        return 1
    fi

    print_info "Copying expect script..."
    cp "$expect_script" "$target_script"

    if [[ $? -ne 0 ]]; then
        print_error "Failed to copy expect script"
        return 1
    fi

    chmod +x "$target_script"

    if [[ $? -ne 0 ]]; then
        print_error "Failed to make expect script executable"
        return 1
    fi

    print_success "Expect script installed: $target_script"
    return 0
}

# Create configuration file if it doesn't exist
create_config_file() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local config_example="$script_dir/port_forward.conf.example"
    local config_file="$HOME/.ssh/port_forward.conf"

    if [[ -f "$config_file" ]]; then
        print_warning "Configuration file already exists: $config_file"
        echo -n "Do you want to overwrite it? [y/N]: "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            print_info "Keeping existing configuration file"
            return 0
        fi
    fi

    if [[ -f "$config_example" ]]; then
        print_info "Creating configuration file from example..."
        cp "$config_example" "$config_file"

        if [[ $? -ne 0 ]]; then
            print_error "Failed to create configuration file"
            return 1
        fi

        chmod 600 "$config_file"
        print_success "Configuration file created: $config_file"
        print_info "Please edit the configuration file to add your servers"
    else
        print_warning "Example configuration file not found, creating basic template..."
        cat > "$config_file" << 'EOF'
# Port Forward Configuration File
# Format: ID,Name,Host,Port,User,AuthType,AuthValue,PortMappings
# - ID: Unique identifier for the server
# - Name: Descriptive name of the server
# - Host: IP address or hostname
# - Port: SSH port number
# - User: SSH username
# - AuthType: 'key' or 'password'
# - AuthValue: Path to key file or password
# - PortMappings: Comma-separated list of local:remote port mappings

# Example entries:
# web1,Web Server 1,192.168.1.10,22,root,key,~/.ssh/web1.key,8080:80,3306:3306
# db1,Database Server 1,192.168.1.20,22,root,password,securepass123,3307:3306,6379:6379
# app1,App Server 1,192.168.1.30,2222,admin,key,~/.ssh/app1.key,8081:80,8082:443,3308:3306

EOF
        chmod 600 "$config_file"
        print_success "Basic configuration template created: $config_file"
    fi

    return 0
}

# Create shell alias
create_shell_alias() {
    local shell_rc=""
    local alias_line='alias ssh-port-forward="$HOME/.ssh/ssh_port_forward.exp"'
    local alias_comment='# SSH Port Forward Tool alias'

    # Determine which shell RC file to use
    if [[ "$SHELL" == *"zsh"* ]]; then
        shell_rc="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        shell_rc="$HOME/.bashrc"
    else
        print_warning "Unknown shell: $SHELL. Please manually add the alias to your shell configuration."
        return 0
    fi

    if [[ ! -f "$shell_rc" ]]; then
        print_warning "Shell configuration file not found: $shell_rc"
        return 0
    fi

    # Check if alias already exists
    if grep -q "ssh-port-forward" "$shell_rc"; then
        print_info "Alias already exists in $shell_rc"
        return 0
    fi

    print_info "Adding alias to $shell_rc..."
    echo "" >> "$shell_rc"
    echo "$alias_comment" >> "$shell_rc"
    echo "$alias_line" >> "$shell_rc"

    if [[ $? -eq 0 ]]; then
        print_success "Alias added to $shell_rc"
        print_info "Please run 'source $shell_rc' or restart your shell to use the alias"
    else
        print_error "Failed to add alias to $shell_rc"
        return 1
    fi

    return 0
}

# Main installation function
main() {
    echo "SSH Port Forward Tool Setup"
    echo "=========================="

    # Check prerequisites
    if ! check_expect; then
        exit 1
    fi

    # Create SSH directory
    if ! create_ssh_directory; then
        exit 1
    fi

    # Copy expect script
    if ! copy_expect_script; then
        exit 1
    fi

    # Create configuration file
    if ! create_config_file; then
        exit 1
    fi

    # Create shell alias
    create_shell_alias

    echo ""
    print_success "SSH Port Forward Tool setup completed!"
    echo ""
    print_info "Usage:"
    echo "  ssh-port-forward [server_id]"
    echo ""
    print_info "Configuration:"
    echo "  Edit $HOME/.ssh/port_forward.conf to add your servers"
    echo ""
    print_info "Environment variables:"
    echo "  PORT_FORWARD_CONFIG: Custom config file path"
    echo "  SSH_TIMEOUT: Connection timeout (default: 30)"
    echo "  SSH_MAX_ATTEMPTS: Max connection attempts (default: 3)"
    echo "  SSH_NO_COLOR: Disable colored output"
    echo "  SSH_KEEP_ALIVE: Enable keep-alive (default: 1)"
    echo "  SSH_ALIVE_INTERVAL: Keep-alive interval (default: 60)"
    echo "  SSH_ALIVE_COUNT: Keep-alive count (default: 3)"
    echo "  SSH_DEFAULT_SHELL: Default shell after login"
    echo ""
    print_info "Example configuration:"
    echo "  web1,Web Server,192.168.1.10,22,root,key,~/.ssh/web1.key,8080:80,3306:3306"
    echo ""
}

# Run main function
main "$@"
