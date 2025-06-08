#!/bin/bash

# =============================================================================
# MySQL Database Backup Script
# =============================================================================
#
# Description: Professional MySQL database backup script with support for
#              multi-database backup, configuration files, notification
#              system, logging, automatic cleanup and more features
#
# Author: funnyzak
# Version: 1.0.0
# Created: 2025-06-08
# Repository: https://gitee.com/funnyzak/dotfiles
#
# System Compatibility:
#   - Ubuntu 18.04+
#   - Debian 9+
#   - CentOS 7+
#   - RHEL 7+
#   - macOS 10.14+
#
# Dependencies:
#   mysqldump (auto-install)
#   tar, gzip (system built-in)
#   curl (for notifications)
#   yq (YAML parsing, optional)
#
# Remote execution examples:
#   # Direct execution (using default configuration)
#   bash <(curl -fsSL https://gitee.com/funnyzak/dotfiles/raw/main/utilities/shell/mysql/mysql_backup.sh)
#
#   # Execution with parameters
#   bash <(curl -fsSL https://gitee.com/funnyzak/dotfiles/raw/main/utilities/shell/mysql/mysql_backup.sh) \
#     -h localhost -u backup_user -p backup_pass -d "db1,db2" -o /backup -c
#
#   # Using remote configuration file
#   curl -fsSL https://gitee.com/funnyzak/dotfiles/raw/main/utilities/shell/mysql/mysql_backup.yaml > /tmp/backup.yaml
#   bash <(curl -fsSL https://gitee.com/funnyzak/dotfiles/raw/main/utilities/shell/mysql/mysql_backup.sh) \
#     -f /tmp/backup.yaml
#
# Local usage examples:
#   # Basic backup
#   ./mysql_backup.sh
#
#   # Backup specific databases to specific directory
#   ./mysql_backup.sh -h 192.168.1.100 -u root -p mypass -d "wordpress,nextcloud" -o /backup/mysql
#
#   # Enable compression and retention
#   ./mysql_backup.sh -c -r 30 -v
#
#   # Using configuration file
#   ./mysql_backup.sh -f ./mysql_backup.yaml
#
#   # Enable notifications
#   ./mysql_backup.sh --apprise-url "http://localhost:8000/notify" --bark-url "https://api.day.app" --bark-key "your_key"
#
# Environment variable support:
#   MYSQL_HOST, MYSQL_PORT, MYSQL_USER, MYSQL_PASSWORD
#   BACKUP_OUTPUT_DIR, BACKUP_RETENTION_DAYS
#   APPRISE_URL, APPRISE_TAGS, BARK_URL, BARK_KEY
#
# =============================================================================

set -euo pipefail

# =============================================================================
# Global constants definition
# =============================================================================
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_AUTHOR="funnyzak"
readonly SCRIPT_URL="https://gitee.com/funnyzak/dotfiles/raw/main/utilities/shell/mysql/mysql_backup.sh"

# Default configuration
readonly DEFAULT_HOST="127.0.0.1"
readonly DEFAULT_PORT="3306"
readonly DEFAULT_USER="root"
readonly DEFAULT_PASSWORD="root"
readonly DEFAULT_OUTPUT_DIR="./"
readonly DEFAULT_SUFFIX="sql"
readonly DEFAULT_EXTRA_OPTS="--ssl-mode=DISABLED --single-transaction --routines --triggers --events --flush-logs --hex-blob --complete-insert"
readonly DEFAULT_RETENTION="0"
readonly DEFAULT_CONFIG_FILE="./mysql_backup.yaml"
readonly DEFAULT_APPRISE_TAGS="all"
readonly DEFAULT_NAME="$(hostname)"

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# =============================================================================
# Global variables
# =============================================================================
MYSQL_HOST="${MYSQL_HOST:-$DEFAULT_HOST}"
MYSQL_PORT="${MYSQL_PORT:-$DEFAULT_PORT}"
MYSQL_USER="${MYSQL_USER:-$DEFAULT_USER}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-$DEFAULT_PASSWORD}"
DATABASES=""
OUTPUT_DIR="${BACKUP_OUTPUT_DIR:-$DEFAULT_OUTPUT_DIR}"
FILE_SUFFIX="$DEFAULT_SUFFIX"
EXTRA_OPTS="$DEFAULT_EXTRA_OPTS"
PRE_CMD=""
POST_CMD=""
COMPRESS=false
RETENTION="${BACKUP_RETENTION_DAYS:-$DEFAULT_RETENTION}"
LOG_DIR=""
VERBOSE=false
CONFIG_FILE="$DEFAULT_CONFIG_FILE"
APPRISE_URL="${APPRISE_URL:-}"
APPRISE_TAGS="${APPRISE_TAGS:-$DEFAULT_APPRISE_TAGS}"
BARK_URL="${BARK_URL:-}"
BARK_KEY="${BARK_KEY:-}"
INSTANCE_NAME="$DEFAULT_NAME"

# Runtime variables
LOG_FILE=""
BACKUP_START_TIME=""
BACKUP_END_TIME=""
TOTAL_DATABASES=0
SUCCESSFUL_BACKUPS=0
FAILED_BACKUPS=0
BACKUP_FILES=()
TOTAL_SIZE=0

# =============================================================================
# Utility functions
# =============================================================================

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    local log_entry="[$timestamp] [$level] $message"

    # Console output
    case "$level" in
        "ERROR")
            echo -e "${RED}$log_entry${NC}" >&2
            ;;
        "WARN")
            echo -e "${YELLOW}$log_entry${NC}" >&2
            ;;
        "INFO")
            echo -e "${GREEN}$log_entry${NC}"
            ;;
        "DEBUG")
            if [[ "$VERBOSE" == "true" ]]; then
                echo -e "${CYAN}$log_entry${NC}"
            fi
            ;;
        *)
            echo "$log_entry"
            ;;
    esac

    # File output
    if [[ -n "$LOG_FILE" && -w "$(dirname "$LOG_FILE")" ]]; then
        echo "$log_entry" >> "$LOG_FILE"
    fi
}

# Error handling function
error_exit() {
    log "ERROR" "$1"
    local error_body="Instance: $INSTANCE_NAME\\nError: $1\\nTime: $(date '+%Y-%m-%d %H:%M:%S')"
    send_notification "❌ MySQL Backup Failed" "$error_body"
    exit "${2:-1}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get operating system information
get_os_info() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    elif [[ -f /etc/redhat-release ]]; then
        echo "rhel"
    else
        echo "unknown"
    fi
}

# Install MySQL client
install_mysql_client() {
    local os_type
    os_type="$(get_os_info)"

    log "INFO" "Detected operating system: $os_type"
    log "INFO" "Installing MySQL client..."

    case "$os_type" in
        "ubuntu"|"debian")
            if command_exists apt-get; then
                sudo apt-get update -qq
                sudo apt-get install -y mysql-client
            else
                error_exit "Cannot find apt-get package manager"
            fi
            ;;
        "centos"|"rhel"|"fedora")
            if command_exists dnf; then
                sudo dnf install -y mysql
            elif command_exists yum; then
                sudo yum install -y mysql
            else
                error_exit "Cannot find yum/dnf package manager"
            fi
            ;;
        "macos")
            if command_exists brew; then
                brew install mysql-client
            else
                error_exit "Please install Homebrew first or manually install MySQL client"
            fi
            ;;
        *)
            error_exit "Unsupported operating system, please manually install mysqldump"
            ;;
    esac

    log "INFO" "MySQL client installation completed"
}

# Check system environment
check_environment() {
    log "INFO" "Checking system environment..."
    log "DEBUG" "Starting environment check for required tools"

    # Check mysqldump
    if ! command_exists mysqldump; then
        log "WARN" "mysqldump not found, attempting to install..."
        install_mysql_client

        if ! command_exists mysqldump; then
            error_exit "mysqldump installation failed, please manually install MySQL client"
        fi
    fi
    log "DEBUG" "mysqldump found: $(which mysqldump)"

    # Check required tools
    local required_tools=("tar" "gzip" "curl")
    for tool in "${required_tools[@]}"; do
        if ! command_exists "$tool"; then
            error_exit "Missing required tool: $tool"
        fi
        log "DEBUG" "$tool found: $(which $tool)"
    done

    log "INFO" "System environment check completed"
}

# Note: MySQL connection test removed as client may only have mysqldump installed
# The connection will be tested during the actual backup process

# Get database list
get_database_list() {
    if [[ -n "$DATABASES" ]]; then
        # Use specified database list
        echo "$DATABASES" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$'
    else
        # Get all databases (excluding system databases)
        local mysql_cmd="mysql -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USER"
        if [[ -n "$MYSQL_PASSWORD" ]]; then
            mysql_cmd="$mysql_cmd -p$MYSQL_PASSWORD"
        fi

        if command_exists mysql; then
            $mysql_cmd -e "SHOW DATABASES;" 2>/dev/null | grep -v -E '^(Database|information_schema|performance_schema|mysql|sys)$' || {
                error_exit "Unable to retrieve database list and no databases specified"
            }
        else
            error_exit "MySQL client not found and no databases specified"
        fi
    fi
}

# Create backup directory
create_backup_directory() {
    if [[ ! -d "$OUTPUT_DIR" ]]; then
        log "INFO" "Creating backup directory: $OUTPUT_DIR"
        log "DEBUG" "Backup directory path: $(realpath "$OUTPUT_DIR" 2>/dev/null || echo "$OUTPUT_DIR")"
        mkdir -p "$OUTPUT_DIR" || error_exit "Cannot create backup directory: $OUTPUT_DIR"
    fi

    # Set directory permissions
    chmod 750 "$OUTPUT_DIR" || log "WARN" "Cannot set backup directory permissions"
    log "DEBUG" "Backup directory permissions: $(ls -ld "$OUTPUT_DIR")"
}

# Create log directory and file
setup_logging() {
    if [[ -n "$LOG_DIR" ]]; then
        if [[ ! -d "$LOG_DIR" ]]; then
            mkdir -p "$LOG_DIR" || error_exit "Cannot create log directory: $LOG_DIR"
        fi

        LOG_FILE="$LOG_DIR/mysql_backup_$(date '+%Y%m%d_%H%M%S').log"
        touch "$LOG_FILE" || error_exit "Cannot create log file: $LOG_FILE"
        chmod 640 "$LOG_FILE"

        log "INFO" "Log file: $LOG_FILE"
        log "DEBUG" "Log directory: $LOG_DIR"
        log "DEBUG" "Log file permissions: $(ls -l "$LOG_FILE")"
    fi
}

# Parse YAML configuration file (simple implementation)
parse_yaml_config() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        log "WARN" "Configuration file does not exist: $config_file"
        return 0
    fi

    log "INFO" "Parsing configuration file: $config_file"
    log "DEBUG" "Configuration file size: $(wc -c < "$config_file") bytes"

    # Track current section context for nested YAML parsing
    local current_section=""
    local current_subsection=""

    # Simple YAML parsing (supports basic format only)
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue

        # Detect section headers (no indentation)
        if [[ "$line" =~ ^([^[:space:]]+):[[:space:]]*$ ]]; then
            current_section="${BASH_REMATCH[1]}"
            current_subsection=""
            log "DEBUG" "Entering section: $current_section"
            continue
        fi

        # Detect subsection headers (2 spaces indentation)
        if [[ "$line" =~ ^[[:space:]]{2}([^[:space:]]+):[[:space:]]*$ ]]; then
            current_subsection="${BASH_REMATCH[1]}"
            log "DEBUG" "Entering subsection: $current_section.$current_subsection"
            continue
        fi

        # Parse key-value pairs
        if [[ "$line" =~ ^[[:space:]]*([^:]+):[[:space:]]*(.*)$ ]]; then
            local key="${BASH_REMATCH[1]// /}"
            local value="${BASH_REMATCH[2]}"

            # Remove quotes
            value="${value#\"}"
            value="${value%\"}"
            value="${value#\'}"
            value="${value%\'}"

            log "DEBUG" "Parsing config: $current_section.$current_subsection.$key = $value"

            # Handle nested configuration based on section context
            if [[ "$current_section" == "notifications" ]]; then
                case "$current_subsection.$key" in
                    "apprise.url") APPRISE_URL="$value" ;;
                    "apprise.tags") APPRISE_TAGS="$value" ;;
                    "bark.url") BARK_URL="$value" ;;
                    "bark.device_key") BARK_KEY="$value" ;;
                esac
            else
                # Handle top-level and other nested configurations
                case "$key" in
                    "name") INSTANCE_NAME="$value" ;;
                    "host") MYSQL_HOST="$value" ;;
                    "port") MYSQL_PORT="$value" ;;
                    "user") MYSQL_USER="$value" ;;
                    "password") MYSQL_PASSWORD="$value" ;;
                    "databases") DATABASES="$value" ;;
                    "output_dir") OUTPUT_DIR="$value" ;;
                    "file_suffix") FILE_SUFFIX="$value" ;;
                    "extra_options") EXTRA_OPTS="$value" ;;
                    "compress") [[ "$value" == "true" ]] && COMPRESS=true ;;
                    "retention_days") RETENTION="$value" ;;
                    "pre_backup") PRE_CMD="$value" ;;
                    "post_backup") POST_CMD="$value" ;;
                    "log_dir") LOG_DIR="$value" ;;
                    "verbose") [[ "$value" == "true" ]] && VERBOSE=true ;;
                esac
            fi
        fi
    done < "$config_file"

    log "INFO" "Configuration file parsing completed"
    log "DEBUG" "Final instance name: $INSTANCE_NAME"
    log "DEBUG" "Final Apprise URL: $APPRISE_URL"
    log "DEBUG" "Final Bark URL: $BARK_URL"
}

# Send notification
send_notification() {
    local title="$1"
    local body="$2"
    local notification_sent=false

    log "DEBUG" "Attempting to send notification: $title"
    log "DEBUG" "Notification body: $body"

    # Apprise notification
    if [[ -n "$APPRISE_URL" ]]; then
        log "DEBUG" "Sending Apprise notification..."
        log "DEBUG" "Apprise URL: $APPRISE_URL, Tags: $APPRISE_TAGS"
        # Convert \n to actual newlines for Apprise form data
        local apprise_body
        apprise_body="$(echo -e "$body")"
        if curl -X POST \
            -F "body=$apprise_body" \
            -F "tags=$APPRISE_TAGS" \
            "$APPRISE_URL" \
            >/dev/null 2>&1; then
            log "INFO" "Apprise notification sent successfully"
            notification_sent=true
        else
            log "WARN" "Apprise notification failed"
        fi
    fi

    # Bark notification
    if [[ -n "$BARK_URL" && -n "$BARK_KEY" ]]; then
        log "DEBUG" "Sending Bark notification..."
        log "DEBUG" "Bark URL: $BARK_URL, Device Key: ${BARK_KEY:0:8}..."
        # Escape special characters for JSON and convert \n to \\n for proper JSON
        local bark_body bark_title
        bark_body="$(echo "$body")"
        bark_title="$(echo "$title")"
        if curl -X POST "$BARK_URL/push" \
            -H 'Content-Type: application/json; charset=utf-8' \
            -d "{
                \"body\": \"$bark_body\",
                \"device_key\": \"$BARK_KEY\",
                \"title\": \"$bark_title\"
            }" \
            >/dev/null 2>&1; then
            log "INFO" "Bark notification sent successfully"
            notification_sent=true
        else
            log "WARN" "Bark notification failed"
        fi
    fi

    # Log if no notification services are configured
    if [[ -z "$APPRISE_URL" && ( -z "$BARK_URL" || -z "$BARK_KEY" ) ]]; then
        log "DEBUG" "No notification services configured (APPRISE_URL or BARK_URL+BARK_KEY required)"
    fi

    if [[ "$notification_sent" == "false" ]]; then
        log "DEBUG" "No notifications were sent"
    fi
}

# Format file size
format_size() {
    local size="$1"
    if [[ "$size" -gt 1073741824 ]]; then
        echo "$(( size / 1073741824 ))GB"
    elif [[ "$size" -gt 1048576 ]]; then
        echo "$(( size / 1048576 ))MB"
    elif [[ "$size" -gt 1024 ]]; then
        echo "$(( size / 1024 ))KB"
    else
        echo "${size}B"
    fi
}

# Serial database backup
backup_databases_serial() {
    local databases=("$@")

    log "DEBUG" "Starting serial backup"

    for database in "${databases[@]}"; do
        local timestamp
        timestamp="$(date '+%Y-%m-%d_%H-%M-%S')"
        local backup_file="$OUTPUT_DIR/${database}_${timestamp}.$FILE_SUFFIX"

        log "INFO" "Starting backup for database: $database"
        log "DEBUG" "Backup file path: $backup_file"

        # Build mysqldump command
        local dump_cmd="mysqldump -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USER"
        if [[ -n "$MYSQL_PASSWORD" ]]; then
            dump_cmd="$dump_cmd -p$MYSQL_PASSWORD"
        fi
        dump_cmd="$dump_cmd $EXTRA_OPTS $database"

        # Create safe debug output (mask password)
        local debug_cmd="$dump_cmd"
        if [[ -n "$MYSQL_PASSWORD" ]]; then
            debug_cmd="${dump_cmd//-p$MYSQL_PASSWORD/-p***}"
        fi
        log "DEBUG" "Mysqldump command: $debug_cmd"

        eval "$dump_cmd" > "$backup_file" 2>/dev/null

        # check backup file exists
        if [[ -f "$backup_file" ]]; then
            # Set file permissions
            chmod 640 "$backup_file"
            log "DEBUG" "Backup file permissions set to 640"

            # Compress file
            if [[ "$COMPRESS" == "true" ]]; then
                log "DEBUG" "Compressing backup file: $backup_file"
                tar -czf "${backup_file}.tar.gz" -C "$(dirname "$backup_file")" "$(basename "$backup_file")" && rm "$backup_file"
                backup_file="${backup_file}.tar.gz"
                log "DEBUG" "Compression completed: $backup_file"
            fi

            local file_size
            file_size="$(stat -c%s "$backup_file" 2>/dev/null || stat -f%z "$backup_file" 2>/dev/null || echo 0)"
            TOTAL_SIZE=$((TOTAL_SIZE + file_size))

            BACKUP_FILES+=("$backup_file")
            SUCCESSFUL_BACKUPS=$((SUCCESSFUL_BACKUPS + 1))

            log "INFO" "Database $database backup successful: $backup_file ($(format_size "$file_size"))"
            log "DEBUG" "Total backups completed: $SUCCESSFUL_BACKUPS"
        else
            FAILED_BACKUPS=$((FAILED_BACKUPS + 1))
            log "ERROR" "Database $database backup failed"
            log "DEBUG" "Failed backups count: $FAILED_BACKUPS"
            [[ -f "$backup_file" ]] && rm -f "$backup_file"
        fi
    done
}

# Clean up old backups
cleanup_old_backups() {
    if [[ "$RETENTION" -eq 0 ]]; then
        log "INFO" "Skipping backup cleanup (retention days is 0)"
        return 0
    fi

    log "INFO" "Cleaning up backup files older than $RETENTION days..."
    log "DEBUG" "Cleanup directory: $OUTPUT_DIR"

    local deleted_count=0
    while IFS= read -r -d '' file; do
        log "DEBUG" "Deleting old backup file: $file"
        rm -f "$file"
        deleted_count=$((deleted_count + 1))
    done < <(find "$OUTPUT_DIR" -name "*.sql" -o -name "*.sql.tar.gz" -type f -mtime +"$RETENTION" -print0 2>/dev/null)

    if [[ "$deleted_count" -gt 0 ]]; then
        log "INFO" "Cleanup completed, deleted $deleted_count old backup files"
    else
        log "INFO" "No old backup files to clean up"
    fi
    log "DEBUG" "Cleanup process finished"
}

# Show backup statistics
show_backup_statistics() {
    local duration=$((BACKUP_END_TIME - BACKUP_START_TIME))
    local duration_formatted

    if [[ "$duration" -ge 3600 ]]; then
        duration_formatted="$((duration / 3600))h $((duration % 3600 / 60))m $((duration % 60))s"
    elif [[ "$duration" -ge 60 ]]; then
        duration_formatted="$((duration / 60))m $((duration % 60))s"
    else
        duration_formatted="${duration}s"
    fi

    log "INFO" "Backup Statistics:"
    log "INFO" "  Total databases: $TOTAL_DATABASES"
    log "INFO" "  Successful backups: $SUCCESSFUL_BACKUPS"
    log "INFO" "  Failed backups: $FAILED_BACKUPS"
    log "INFO" "  Total file size: $(format_size "$TOTAL_SIZE")"
    log "INFO" "  Backup duration: $duration_formatted"
    log "INFO" "  Backup files:"

    for file in "${BACKUP_FILES[@]}"; do
        local file_size
        file_size="$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo 0)"
        log "INFO" "    $(basename "$file") ($(format_size "$file_size"))"
    done

    log "DEBUG" "Statistics calculation completed"
}

# Show help information
show_help() {
    echo -e "
${WHITE}MySQL Database Backup Script v$SCRIPT_VERSION${NC}
${CYAN}Author: $SCRIPT_AUTHOR${NC}

${YELLOW}Description:${NC}
  Professional MySQL database backup script with support for multi-database
  backup, configuration files, notification system, logging,
  automatic cleanup and more features.

${YELLOW}Usage:${NC}
  $SCRIPT_NAME [options]

${YELLOW}Options:${NC}
  ${GREEN}-n, --name${NC}          Instance name for notifications (default: hostname)
  ${GREEN}-h, --host${NC}          MySQL server address (default: $DEFAULT_HOST)
  ${GREEN}-P, --port${NC}          MySQL port (default: $DEFAULT_PORT)
  ${GREEN}-u, --user${NC}          MySQL username (default: $DEFAULT_USER)
  ${GREEN}-p, --password${NC}      MySQL password (default: $DEFAULT_PASSWORD)
  ${GREEN}-d, --databases${NC}     Database names to backup, comma-separated (default: backup all databases)
  ${GREEN}-o, --output${NC}        Backup file output directory (default: $DEFAULT_OUTPUT_DIR)
  ${GREEN}-s, --suffix${NC}        Backup file suffix (default: $DEFAULT_SUFFIX)
  ${GREEN}-e, --extra-opts${NC}    Additional mysqldump parameters
  ${GREEN}    --pre-cmd${NC}       Command to execute before backup
  ${GREEN}    --post-cmd${NC}      Command to execute after backup
  ${GREEN}-c, --compress${NC}      Use tar compression for backup files (default: false)
  ${GREEN}-r, --retention${NC}     Backup retention days (default: $DEFAULT_RETENTION, 0 means no cleanup)
  ${GREEN}-l, --log-dir${NC}       Log file directory (if not specified, no log file)
  ${GREEN}-v, --verbose${NC}       Enable verbose debug output (default: false)
  ${GREEN}-f, --config${NC}        Configuration file path (default: $DEFAULT_CONFIG_FILE)
  ${GREEN}    --apprise-url${NC}   Apprise notification URL
  ${GREEN}    --apprise-tags${NC}  Apprise notification tags (default: $DEFAULT_APPRISE_TAGS)
  ${GREEN}    --bark-url${NC}      Bark server URL
  ${GREEN}    --bark-key${NC}      Bark device key
  ${GREEN}    --help${NC}          Show help information

${YELLOW}Examples:${NC}
  # Basic backup
  $SCRIPT_NAME

  # Backup specific databases
  $SCRIPT_NAME -h localhost -u root -p mypass -d "db1,db2" -o /backup

  # Enable compression and retention
  $SCRIPT_NAME -c -r 30 -v

  # Use configuration file
  $SCRIPT_NAME -f ./mysql_backup.yaml

  # Remote execution
  bash <(curl -fsSL $SCRIPT_URL) -h localhost -u root -p mypass

${YELLOW}Environment Variables:${NC}
  MYSQL_HOST, MYSQL_PORT, MYSQL_USER, MYSQL_PASSWORD
  BACKUP_OUTPUT_DIR, BACKUP_RETENTION_DAYS
  APPRISE_URL, APPRISE_TAGS, BARK_URL, BARK_KEY

${YELLOW}More Information:${NC}
  Project: https://gitee.com/funnyzak/dotfiles
  Script: $SCRIPT_URL
"
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--name)
                INSTANCE_NAME="$2"
                shift 2
                ;;
            -h|--host)
                MYSQL_HOST="$2"
                shift 2
                ;;
            -P|--port)
                MYSQL_PORT="$2"
                shift 2
                ;;
            -u|--user)
                MYSQL_USER="$2"
                shift 2
                ;;
            -p|--password)
                MYSQL_PASSWORD="$2"
                shift 2
                ;;
            -d|--databases)
                DATABASES="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            -s|--suffix)
                FILE_SUFFIX="$2"
                shift 2
                ;;
            -e|--extra-opts)
                EXTRA_OPTS="$2"
                shift 2
                ;;
            --pre-cmd)
                PRE_CMD="$2"
                shift 2
                ;;
            --post-cmd)
                POST_CMD="$2"
                shift 2
                ;;
            -c|--compress)
                COMPRESS=true
                shift
                ;;
            -r|--retention)
                RETENTION="$2"
                shift 2
                ;;
            -l|--log-dir)
                LOG_DIR="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -f|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            --apprise-url)
                APPRISE_URL="$2"
                shift 2
                ;;
            --apprise-tags)
                APPRISE_TAGS="$2"
                shift 2
                ;;
            --bark-url)
                BARK_URL="$2"
                shift 2
                ;;
            --bark-key)
                BARK_KEY="$2"
                shift 2
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                error_exit "Unknown parameter: $1"
                ;;
        esac
    done
}

# Main function
main() {
    # Parse command line arguments
    parse_arguments "$@"

    # Parse configuration file
    if [[ -f "$CONFIG_FILE" ]]; then
        parse_yaml_config "$CONFIG_FILE"
    fi

    # Set default instance name if empty
    if [[ -z "$INSTANCE_NAME" ]]; then
        INSTANCE_NAME="$DEFAULT_NAME"
    fi

    # Setup logging
    setup_logging

    log "INFO" "MySQL backup script started (version: $SCRIPT_VERSION)"
    log "INFO" "Script author: $SCRIPT_AUTHOR"
    log "INFO" "Instance name: $INSTANCE_NAME"
    log "DEBUG" "Configuration: Host=$MYSQL_HOST, Port=$MYSQL_PORT, User=$MYSQL_USER"
    log "DEBUG" "Output directory: $OUTPUT_DIR"
    log "DEBUG" "Notification config: Apprise URL=${APPRISE_URL:+configured}, Bark URL=${BARK_URL:+configured}, Bark Key=${BARK_KEY:+configured}"

    # Record start time
    BACKUP_START_TIME="$(date +%s)"

    # Check system environment
    check_environment

    # Create backup directory
    create_backup_directory

    # Execute pre-backup command
    if [[ -n "$PRE_CMD" ]]; then
        log "INFO" "Executing pre-backup command: $PRE_CMD"
        eval "$PRE_CMD" || log "WARN" "Pre-backup command execution failed"
    fi

    # Get database list
    log "INFO" "Getting database list..."
    local databases_array=()
    while IFS= read -r database; do
        [[ -n "$database" ]] && databases_array+=("$database")
    done < <(get_database_list)

    TOTAL_DATABASES="${#databases_array[@]}"

    if [[ "$TOTAL_DATABASES" -eq 0 ]]; then
        error_exit "No databases found for backup"
    fi

    log "INFO" "Found $TOTAL_DATABASES databases for backup"
    log "DEBUG" "Database list: ${databases_array[*]}"

    # Start backup
    log "INFO" "Starting database backup..."
    backup_databases_serial "${databases_array[@]}"

    # Record end time
    BACKUP_END_TIME="$(date +%s)"

    # Clean up old backups
    cleanup_old_backups

    # Execute post-backup command
    if [[ -n "$POST_CMD" ]]; then
        log "INFO" "Executing post-backup command: $POST_CMD"
        eval "$POST_CMD" || log "WARN" "Post-backup command execution failed"
    fi

    # Show statistics
    show_backup_statistics

    # Send notifications
    if [[ "$FAILED_BACKUPS" -eq 0 ]]; then
        local notification_body="✅ MySQL backup completed successfully\\nInstance: $INSTANCE_NAME\\nDatabases: ${databases_array[*]}($SUCCESSFUL_BACKUPS)\nTotal size: $(format_size "$TOTAL_SIZE")\\nTime: $(date '+%Y-%m-%d %H:%M:%S')"
        send_notification "MySQL Backup Success" "$notification_body"
        log "INFO" "All database backups completed successfully"
    else
        local notification_body="⚠️ MySQL backup partially failed\\nInstance: $INSTANCE_NAME\\nDatabases: ${databases_array[*]}($SUCCESSFUL_BACKUPS)\nFailed: $FAILED_BACKUPS\\nTime: $(date '+%Y-%m-%d %H:%M:%S')"
        send_notification "MySQL Backup Warning" "$notification_body"
        log "WARN" "Some database backups failed"
        exit 1
    fi
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
