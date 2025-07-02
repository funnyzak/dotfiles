#!/bin/bash
# Test script for SSH Port Forward configuration file

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

# Function to validate port number
validate_port() {
    local port="$1"
    if [[ ! "$port" =~ ^[0-9]+$ ]] || [[ "$port" -lt 1 ]] || [[ "$port" -gt 65535 ]]; then
        return 1
    fi
    return 0
}

# Function to validate port mapping format
validate_port_mapping() {
    local mapping="$1"
    local parts=(${mapping//:/ })

    if [[ ${#parts[@]} -ne 2 ]]; then
        return 1
    fi

    local local_port="${parts[0]}"
    local remote_port="${parts[1]}"

    if ! validate_port "$local_port" || ! validate_port "$remote_port"; then
        return 1
    fi

    return 0
}

# Function to parse and validate port mappings
parse_port_mappings() {
    local mappings="$1"
    local valid_mappings=()
    local invalid_mappings=()

    if [[ -z "$mappings" ]]; then
        return 0
    fi

    IFS=',' read -ra mapping_array <<< "$mappings"

    for mapping in "${mapping_array[@]}"; do
        mapping=$(echo "$mapping" | xargs) # trim whitespace
        if [[ -n "$mapping" ]]; then
            if validate_port_mapping "$mapping"; then
                valid_mappings+=("$mapping")
            else
                invalid_mappings+=("$mapping")
            fi
        fi
    done

    echo "VALID:${valid_mappings[*]}"
    echo "INVALID:${invalid_mappings[*]}"
}

# Function to validate configuration file
validate_config_file() {
    local config_file="$1"
    local line_number=0
    local valid_entries=0
    local invalid_entries=0
    local errors=()

    if [[ ! -f "$config_file" ]]; then
        print_error "Configuration file not found: $config_file"
        return 1
    fi

    print_info "Validating configuration file: $config_file"
    echo "=========================================="

    while IFS= read -r line; do
        ((line_number++))

        # Skip empty lines and comments
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi

        # Parse CSV format
        IFS=',' read -ra fields <<< "$line"

        if [[ ${#fields[@]} -lt 8 ]]; then
            errors+=("Line $line_number: Insufficient fields (${#fields[@]}/8)")
            ((invalid_entries++))
            continue
        fi

        # Extract fields
        local id="${fields[0]}"
        local name="${fields[1]}"
        local host="${fields[2]}"
        local port="${fields[3]}"
        local user="${fields[4]}"
        local auth_type="${fields[5]}"
        local auth_value="${fields[6]}"
        local port_mappings="${fields[7]}"

        # Trim whitespace
        id=$(echo "$id" | xargs)
        name=$(echo "$name" | xargs)
        host=$(echo "$host" | xargs)
        port=$(echo "$port" | xargs)
        user=$(echo "$user" | xargs)
        auth_type=$(echo "$auth_type" | xargs)
        auth_value=$(echo "$auth_value" | xargs)
        port_mappings=$(echo "$port_mappings" | xargs)

        # Validate required fields
        local has_errors=false

        if [[ -z "$id" ]]; then
            errors+=("Line $line_number: Empty server ID")
            has_errors=true
        fi

        if [[ -z "$name" ]]; then
            errors+=("Line $line_number: Empty server name")
            has_errors=true
        fi

        if [[ -z "$host" ]]; then
            errors+=("Line $line_number: Empty host")
            has_errors=true
        fi

        if ! validate_port "$port"; then
            errors+=("Line $line_number: Invalid port: $port")
            has_errors=true
        fi

        if [[ -z "$user" ]]; then
            errors+=("Line $line_number: Empty user")
            has_errors=true
        fi

        if [[ "$auth_type" != "key" && "$auth_type" != "password" ]]; then
            errors+=("Line $line_number: Invalid auth type: $auth_type (must be 'key' or 'password')")
            has_errors=true
        fi

        if [[ -z "$auth_value" ]]; then
            errors+=("Line $line_number: Empty auth value")
            has_errors=true
        fi

        # Validate port mappings
        if [[ -n "$port_mappings" ]]; then
            local mapping_result=$(parse_port_mappings "$port_mappings")
            local valid_part=$(echo "$mapping_result" | grep "^VALID:" | cut -d: -f2)
            local invalid_part=$(echo "$mapping_result" | grep "^INVALID:" | cut -d: -f2)

            if [[ -n "$invalid_part" ]]; then
                errors+=("Line $line_number: Invalid port mappings: $invalid_part")
                has_errors=true
            fi
        fi

        if [[ "$has_errors" == "true" ]]; then
            ((invalid_entries++))
        else
            ((valid_entries++))
            print_success "Line $line_number: Valid entry - $id ($name)"
        fi
    done < "$config_file"

    echo ""
    echo "Validation Summary:"
    echo "=================="
    print_success "Valid entries: $valid_entries"

    if [[ $invalid_entries -gt 0 ]]; then
        print_error "Invalid entries: $invalid_entries"
        echo ""
        echo "Errors:"
        for error in "${errors[@]}"; do
            print_error "  $error"
        done
        return 1
    else
        print_success "All entries are valid!"
        return 0
    fi
}

# Function to show configuration summary
show_config_summary() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        print_error "Configuration file not found: $config_file"
        return 1
    fi

    print_info "Configuration Summary:"
    echo "========================"

    local total_servers=0
    local total_mappings=0

    while IFS= read -r line; do
        # Skip empty lines and comments
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi

        # Parse CSV format
        IFS=',' read -ra fields <<< "$line"

        if [[ ${#fields[@]} -ge 8 ]]; then
            local id="${fields[0]}"
            local name="${fields[1]}"
            local host="${fields[2]}"
            local port="${fields[3]}"
            local user="${fields[4]}"
            local auth_type="${fields[5]}"
            local port_mappings="${fields[7]}"

            # Trim whitespace
            id=$(echo "$id" | xargs)
            name=$(echo "$name" | xargs)
            host=$(echo "$host" | xargs)
            port=$(echo "$port" | xargs)
            user=$(echo "$user" | xargs)
            auth_type=$(echo "$auth_type" | xargs)
            port_mappings=$(echo "$port_mappings" | xargs)

            ((total_servers++))

            echo ""
            echo "Server $total_servers:"
            echo "  ID: $id"
            echo "  Name: $name"
            echo "  Host: $host:$port"
            echo "  User: $user"
            echo "  Auth: $auth_type"

            if [[ -n "$port_mappings" ]]; then
                echo "  Port Mappings:"
                IFS=',' read -ra mapping_array <<< "$port_mappings"
                for mapping in "${mapping_array[@]}"; do
                    mapping=$(echo "$mapping" | xargs)
                    if [[ -n "$mapping" ]]; then
                        echo "    $mapping"
                        ((total_mappings++))
                    fi
                done
            else
                echo "  Port Mappings: None"
            fi
        fi
    done < "$config_file"

    echo ""
    echo "Summary:"
    echo "  Total servers: $total_servers"
    echo "  Total port mappings: $total_mappings"
}

# Main function
main() {
    local config_file="${1:-$HOME/.ssh/port_forward.conf}"
    local action="${2:-validate}"

    case "$action" in
        "validate")
            validate_config_file "$config_file"
            ;;
        "summary")
            show_config_summary "$config_file"
            ;;
        "both")
            validate_config_file "$config_file"
            echo ""
            show_config_summary "$config_file"
            ;;
        *)
            echo "Usage: $0 [config_file] [action]"
            echo "Actions: validate, summary, both"
            echo "Default config file: $HOME/.ssh/port_forward.conf"
            echo "Default action: validate"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
