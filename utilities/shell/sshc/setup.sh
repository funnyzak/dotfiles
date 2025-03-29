#!/usr/bin/expect -f

# SSH Connection Script
# Description: A versatile SSH connection tool supporting multiple servers with key or password authentication.
# Github: funnyzak
# Last Updated: March 29, 2025

# Usage:
#   Interactive mode: ./ssh_connect.exp
#   Non-interactive mode (by ID): ./ssh_connect.exp <server_id>
#   Non-interactive mode (env): TARGET_SERVER_ID=<server_id> ./ssh_connect.exp
#
# Environment Variables:
#   SERVERS_CONFIG: Path to the servers configuration file (default: servers.conf)
#   TARGET_SERVER_ID: Server ID for non-interactive connection
#   SSH_TIMEOUT: Connection timeout in seconds (default: 30)
#   SSH_MAX_ATTEMPTS: Maximum connection attempts (default: 3)
#   SSH_NO_COLOR: Disable colored output if set to any value
#
# Configuration File Format:
#   ID,Name,Host,Port,User,AuthType,AuthValue
#   - ID: Unique identifier for the server
#   - Name: Descriptive name of the server
#   - Host: IP address or hostname
#   - Port: SSH port number
#   - User: SSH username
#   - AuthType: 'key' or 'password'
#   - AuthValue: Path to key file or password
#
# Example Configuration (servers.conf):
#   # ID,Name,Host,Port,User,AuthType,AuthValue
#   web1,Web Server 1,192.168.1.10,22,root,key,/home/user/.ssh/web1.key
#   db1,Database Server 1,192.168.1.20,22,root,password,securepass123
#   app1,App Server 1,192.168.1.30,2222,admin,key,~/app1.key

# Default parameters
set timeout [expr {[info exists ::env(SSH_TIMEOUT)] ? $::env(SSH_TIMEOUT) : 30}]
set max_attempts [expr {[info exists ::env(SSH_MAX_ATTEMPTS)] ? $::env(SSH_MAX_ATTEMPTS) : 3}]
set default_config_path [file join $::env(HOME) ".ssh" "servers.conf"]
set config_file [expr {[info exists ::env(SERVERS_CONFIG)] ? $::env(SERVERS_CONFIG) : $default_config_path}]
set use_colors [expr {![info exists ::env(SSH_NO_COLOR)]}]

# Color codes
if {$use_colors} {
    # ANSI color codes
    set COLOR_RESET "\033\[0m"
    set COLOR_HEADER "\033\[1;36m"
    set COLOR_ID "\033\[1;33m"
    set COLOR_HOST "\033\[1;32m"
    set COLOR_NAME "\033\[1;34m"
    set COLOR_SUCCESS "\033\[1;32m"
    set COLOR_ERROR "\033\[1;31m"
    set COLOR_INFO "\033\[1;35m"
} else {
    # No colors
    set COLOR_RESET ""
    set COLOR_HEADER ""
    set COLOR_ID ""
    set COLOR_HOST ""
    set COLOR_NAME ""
    set COLOR_SUCCESS ""
    set COLOR_ERROR ""
    set COLOR_INFO ""
}

# Expand home directory in path (~)
proc expand_path {path} {
    global ::env

    if {[string match "~/*" $path]} {
        return [file join $::env(HOME) [string range $path 2 end]]
    } elseif {$path eq "~"} {
        return $::env(HOME)
    } elseif {[string match "~*/*" $path]} {
        set username [string range $path 1 [expr {[string first "/" $path] - 1}]]
        set rest [string range $path [expr {[string first "/" $path] + 1}] end]
        # Note: This is a simplified approach. For full implementation,
        # you would need to use platform-specific methods to get user home directories.
        return "/home/$username/$rest"
    }
    return $path
}

# Load server configurations
proc load_servers {filename} {
    global COLOR_ERROR COLOR_RESET

    set servers {}
    if {![file exists $filename]} {
        send_user "${COLOR_ERROR}Error: Configuration file '$filename' does not exist${COLOR_RESET}\n"
        exit 1
    }

    set fp [open $filename r]
    while {[gets $fp line] >= 0} {
        set line [string trim $line]
        if {$line eq "" || [string match "#*" $line]} {
            continue
        }
        set fields [split $line ","]
        if {[llength $fields] < 7} {
            send_user "${COLOR_ERROR}Warning: Invalid config line skipped: $line${COLOR_RESET}\n"
            continue
        }
        lappend servers $fields
    }
    close $fp
    return $servers
}

# Find server by ID
proc find_server_by_id {servers id} {
    foreach server $servers {
        if {[lindex $server 0] eq $id} {
            return $server
        }
    }
    return ""
}

# Display server selection menu
proc select_server {servers} {
    global COLOR_HEADER COLOR_ID COLOR_HOST COLOR_NAME COLOR_RESET COLOR_INFO

    send_user "\n${COLOR_HEADER}Available Servers:${COLOR_RESET}\n"
    send_user "${COLOR_HEADER}#   ID\tName\t\tHost\t\tPort\tUser${COLOR_RESET}\n"
    send_user -- [string repeat "-" 60]
    send_user "\n"

    set idx 1
    foreach server $servers {
        set id [lindex $server 0]
        set name [lindex $server 1]
        set host [lindex $server 2]
        set port [lindex $server 3]
        set user [lindex $server 4]
        send_user "[format "%2d" $idx]  ${COLOR_ID}$id${COLOR_RESET}\t${COLOR_NAME}[string range "$name                " 0 15]${COLOR_RESET}${COLOR_HOST}$host${COLOR_RESET}\t$port\t$user\n"
        incr idx
    }

    send_user "\n${COLOR_INFO}Enter server ID or number (1-[llength $servers]):${COLOR_RESET} "
    expect_user -re "(.*)\n"
    set choice $expect_out(1,string)

    if {[string is integer $choice]} {
        set index [expr {$choice - 1}]
        if {$index >= 0 && $index < [llength $servers]} {
            return [lindex $servers $index]
        }
    } else {
        set server [find_server_by_id $servers $choice]
        if {$server ne ""} {
            return $server
        }
    }
    send_user "${COLOR_ERROR}Invalid selection${COLOR_RESET}\n"
    exit 1
}

# SSH connection function
proc connect_ssh {server_info} {
    global timeout max_attempts COLOR_SUCCESS COLOR_ERROR COLOR_INFO COLOR_RESET

    set id    [lindex $server_info 0]
    set name  [lindex $server_info 1]
    set host  [lindex $server_info 2]
    set port  [lindex $server_info 3]
    set user  [lindex $server_info 4]
    set auth  [lindex $server_info 5]
    set value [lindex $server_info 6]

    # Expand ~ in key path if necessary
    if {$auth eq "key"} {
        set value [expand_path $value]
    }

    set attempt 1
    while {$attempt <= $max_attempts} {
        send_user "${COLOR_INFO}Connecting to $name ($host) - Attempt $attempt/$max_attempts${COLOR_RESET}\n"

        if {$auth eq "key"} {
            spawn ssh -p $port -o StrictHostKeyChecking=no -o PubkeyAuthentication=yes -i $value $user@$host
        } else {
            spawn ssh -p $port -o StrictHostKeyChecking=no $user@$host
        }

        expect {
            "yes/no" {
                send "yes\r"
                exp_continue
            }
            "password:" {
                if {$auth ne "password"} {
                    send_user "${COLOR_ERROR}Server requires password but configured for key auth${COLOR_RESET}\n"
                    return 0
                }
                send "$value\r"
                exp_continue
            }
            "Permission denied" {
                send_user "${COLOR_ERROR}Authentication failed${COLOR_RESET}\n"
                return 0
            }
            -re {(.*[$#%>]|.*[@].+[:])} {
                send_user "${COLOR_SUCCESS}Successfully connected to $name (ID: $id)!${COLOR_RESET}\n"
                interact
                return 1
            }
            "Connection refused" {
                send_user "${COLOR_ERROR}Connection refused${COLOR_RESET}\n"
                sleep 5
                incr attempt
                exp_continue
            }
            timeout {
                send_user "${COLOR_ERROR}Connection timeout${COLOR_RESET}\n"
                sleep 5
                incr attempt
                exp_continue
            }
            eof {
                send_user "${COLOR_ERROR}Connection terminated unexpectedly${COLOR_RESET}\n"
                return 0
            }
        }
    }
    return 0
}


# Main program
send_user "${COLOR_INFO}Loading server configurations...${COLOR_RESET}\n"
set servers [load_servers $config_file]

# Check for command-line argument or environment variable
if {[llength $argv] > 0} {
    set target_id [lindex $argv 0]
} elseif {[info exists ::env(TARGET_SERVER_ID)]} {
    set target_id $::env(TARGET_SERVER_ID)
}

if {[info exists target_id]} {
    set selected_server [find_server_by_id $servers $target_id]
    if {$selected_server eq ""} {
        send_user "${COLOR_ERROR}Error: No server found with ID '$target_id'${COLOR_RESET}\n"
        exit 1
    }
} else {
    set selected_server [select_server $servers]
}

if {![connect_ssh $selected_server]} {
    send_user "${COLOR_ERROR}Failed to connect to the selected server${COLOR_RESET}\n"
    exit 1
}
