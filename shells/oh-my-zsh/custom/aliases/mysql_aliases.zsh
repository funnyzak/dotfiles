# Description: MySQL related aliases for database management and administration. These aliases provide shortcuts for common MySQL operations including database backup, restore, querying, user management, and performance monitoring with enhanced error handling and cross-platform compatibility.

# MySQL Command Availability Check
__mysql_cmd_exists() {
  command -v mysql &> /dev/null
  return $?
}

# MySQL Client Connection Helper
__mysql_connect() {
  local host="${1:-localhost}"
  local user="${2:-root}"
  local password="$3"
  local port="${4:-3306}"
  local database="$5"
  local options="$6"

  local connect_cmd="mysql"

  # Add connection parameters
  connect_cmd+="  -h \"$host\" -u \"$user\" -P $port"

  # Add password if provided
  if [ -n "$password" ]; then
    connect_cmd+="  -p\"$password\""
  fi

  # Add database if provided
  if [ -n "$database" ]; then
    connect_cmd+="  \"$database\""
  fi

  # Add additional options if provided
  if [ -n "$options" ]; then
    connect_cmd+="  $options"
  fi

  eval "$connect_cmd"
}

# MySQL Dump Helper
__mysql_dump() {
  local host="${1:-localhost}"
  local user="${2:-root}"
  local password="$3"
  local port="${4:-3306}"
  local database="$5"
  local tables="$6"
  local options="${7:---single-transaction --quick --lock-tables=false}"
  local output_file="$8"

  local dump_cmd="mysqldump"

  # Add connection parameters
  dump_cmd+="  -h \"$host\" -u \"$user\" -P $port"

  # Add password if provided
  if [ -n "$password" ]; then
    dump_cmd+="  -p\"$password\""
  fi

  # Add options
  dump_cmd+="  $options"

  # Add database
  if [ -n "$database" ]; then
    dump_cmd+="  \"$database\""

    # Add tables if provided
    if [ -n "$tables" ]; then
      dump_cmd+="  $tables"
    fi
  fi

  # Add output redirection if provided
  if [ -n "$output_file" ]; then
    dump_cmd+="  > \"$output_file\""
  fi

  eval "$dump_cmd"
}

_mysql_install_check() {
  if ! command -v mysql &> /dev/null; then
    echo "Error: MySQL client not found. Please install MySQL client."
    _mysql_install_tips
    return 1
  fi
  return 0
}

_mysql_install_tips() {
    echo "Installation instructions:"
    echo "  - Debian/Ubuntu:  sudo apt-get install mysql-client"
    echo "  - RHEL/CentOS:    sudo yum install mysql"
    echo "  - Fedora:         sudo dnf install mysql"
    echo "  - macOS:          brew install mysql-client"
    echo "  - Windows:        Download the installer from https://dev.mysql.com/downloads/mysql/"
    echo "  - Arch Linux:     sudo pacman -S mysql-clients"
    echo "  - Alpine:         apk add mysql-client"
    echo "  - OpenSUSE:      sudo zypper install mysql-client"
}

_mysql_dump_install_check() {
  if ! command -v mysqldump &> /dev/null; then
    echo "Error: mysqldump not found. Please install MySQL client."
    _mysql_install_tips
    return 1
  fi
  return 0
}

# Basic MySQL Operations
alias myl='() {
  echo "Lists all MySQL databases.\nUsage:\n myl [host:localhost] [user:root] [password] [port:3306]"

  if ! _mysql_install_check; then
    _mysql_install_tips
    return 1
  fi

  local host="${1:-localhost}"
  local user="${2:-root}"
  local password="$3"
  local port="${4:-3306}"

  __mysql_connect "$host" "$user" "$password" "$port" "" "-e \"SHOW DATABASES;\""
}' # Lists all MySQL databases

alias mydb='() {
  echo "Connects to a MySQL database.\nUsage:\n mydb <database> [host:localhost] [user:root] [password] [port:3306]"

  if ! _mysql_install_check; then
    _mysql_install_tips
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Error: Please specify the database name"
    return 1
  fi

  local database="$1"
  local host="${2:-localhost}"
  local user="${3:-root}"
  local password="$4"
  local port="${5:-3306}"

  __mysql_connect "$host" "$user" "$password" "$port" "$database"
}' # Connects to a MySQL database

alias myq='() {
  echo "Executes a SQL query on a MySQL database.\nUsage:\n myq <database> <query> [host:localhost] [user:root] [password] [port:3306]"

  if ! _mysql_install_check; then
    _mysql_install_tips
    return 1
  fi

  if [ $# -lt 2 ]; then
    echo "Error: Please specify the database name and SQL query"
    echo "Example: myq mydatabase \"SELECT * FROM users LIMIT 10;\""
    return 1
  fi

  local database="$1"
  local query="$2"
  local host="${3:-localhost}"
  local user="${4:-root}"
  local password="$5"
  local port="${6:-3306}"

  __mysql_connect "$host" "$user" "$password" "$port" "$database" "-e \"$query\""
}' # Executes a SQL query on a MySQL database

alias myt='() {
  echo "Lists all tables in a MySQL database.\nUsage:\n myt <database> [host:localhost] [user:root] [password] [port:3306]"

  if ! _mysql_install_check; then
    _mysql_install_tips
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Error: Please specify the database name"
    return 1
  fi

  local database="$1"
  local host="${2:-localhost}"
  local user="${3:-root}"
  local password="$4"
  local port="${5:-3306}"

  __mysql_connect "$host" "$user" "$password" "$port" "$database" "-e \"SHOW TABLES;\""
}' # Lists all tables in a MySQL database

alias mytd='() {
  echo "Shows the structure of a MySQL table.\nUsage:\n mytd <database> <table> [host:localhost] [user:root] [password] [port:3306]"

  if ! _mysql_install_check; then
    _mysql_install_tips
    return 1
  fi

  if [ $# -lt 2 ]; then
    echo "Error: Please specify the database name and table name"
    echo "Example: mytd mydatabase users"
    return 1
  fi

  local database="$1"
  local table="$2"
  local host="${3:-localhost}"
  local user="${4:-root}"
  local password="$5"
  local port="${6:-3306}"

  __mysql_connect "$host" "$user" "$password" "$port" "$database" "-e \"DESCRIBE \\\"$table\\\";\""
}' # Shows the structure of a MySQL table

# Database Backup and Restore
alias mybackup='() {
  echo "Backs up a MySQL database.\nUsage:\n mybackup <database> [output_file:database_name-YYYY-MM-DD.sql] [host:localhost] [user:root] [password] [port:3306] [options:--single-transaction --quick --lock-tables=false]"

  if ! _mysql_dump_install_check; then
    _mysql_install_tips
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Error: Please specify the database name"
    return 1
  fi

  local database="$1"
  local date_suffix=$(date +"%Y-%m-%d")
  local output_file="${2:-${database}-${date_suffix}.sql}"
  local host="${3:-localhost}"
  local user="${4:-root}"
  local password="$5"
  local port="${6:-3306}"
  local options="${7:---single-transaction --quick --lock-tables=false}"

  echo "Backing up database \"$database\" to \"$output_file\"..."
  __mysql_dump "$host" "$user" "$password" "$port" "$database" "" "$options" "$output_file"

  if [ $? -eq 0 ]; then
    echo "Backup completed successfully: $output_file"
    echo "File size: $(du -h "$output_file" | cut -f1)"
  else
    echo "Error: Backup failed"
    return 1
  fi
}' # Backs up a MySQL database

alias mybackup-gz='() {
  echo "Backs up a MySQL database with gzip compression.\nUsage:\n mybackup-gz <database> [output_file:database_name-YYYY-MM-DD.sql.gz] [host:localhost] [user:root] [password] [port:3306] [options:--single-transaction --quick --lock-tables=false]"

  if ! _mysql_dump_install_check; then
    _mysql_install_tips
    return 1
  fi

  if ! command -v gzip &> /dev/null; then
    echo "Error: gzip not found. Please install gzip."
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Error: Please specify the database name"
    return 1
  fi

  local database="$1"
  local date_suffix=$(date +"%Y-%m-%d")
  local output_file="${2:-${database}-${date_suffix}.sql.gz}"
  local host="${3:-localhost}"
  local user="${4:-root}"
  local password="$5"
  local port="${6:-3306}"
  local options="${7:---single-transaction --quick --lock-tables=false}"

  echo "Backing up database \"$database\" to \"$output_file\" with compression..."

  # Create dump command without output redirection
  local dump_cmd="mysqldump -h \"$host\" -u \"$user\" "

  # Add password if provided
  if [ -n "$password" ]; then
    dump_cmd+="-p\"$password\" "
  fi

  # Add port, options and database
  dump_cmd+="-P $port $options \"$database\" | gzip > \"$output_file\""

  eval "$dump_cmd"

  if [ $? -eq 0 ]; then
    echo "Compressed backup completed successfully: $output_file"
    echo "File size: $(du -h "$output_file" | cut -f1)"
  else
    echo "Error: Compressed backup failed"
    return 1
  fi
}' # Backs up a MySQL database with gzip compression

alias mytbackup='() {
  echo "Backs up specific tables from a MySQL database.\nUsage:\n mytbackup <database> <table1 table2...> [output_file:database_name-tables-YYYY-MM-DD.sql] [host:localhost] [user:root] [password] [port:3306] [options:--single-transaction --quick --lock-tables=false]"

  if ! _mysql_dump_install_check; then
    _mysql_install_tips
    return 1
  fi

  if [ $# -lt 2 ]; then
    echo "Error: Please specify the database name and at least one table name"
    echo "Example: mytbackup mydatabase users products"
    return 1
  fi

  local database="$1"
  shift
  local tables="$@"
  local table_count=$(echo "$tables" | wc -w | tr -d " ")
  local date_suffix=$(date +"%Y-%m-%d")

  # Extract tables for the output filename
  local first_table=$(echo "$tables" | cut -d" " -f1)
  local output_file="${database}-${first_table}-and-$((table_count-1))-tables-${date_suffix}.sql"

  # Check if there are more arguments after tables
  local remaining_args=()
  for arg in "$@"; do
    if [[ "$arg" == -* || "$arg" == *:* ]]; then
      # This is likely an option or host:port format
      remaining_args+=("$arg")
      # Remove from tables
      tables=${tables//$arg/}
    fi
  done

  # If we have remaining args, the first one is the output file
  if [ ${#remaining_args[@]} -gt 0 ]; then
    output_file="${remaining_args[0]}"
    remaining_args=("${remaining_args[@]:1}")
  fi

  local host="${remaining_args[0]:-localhost}"
  local user="${remaining_args[1]:-root}"
  local password="${remaining_args[2]}"
  local port="${remaining_args[3]:-3306}"
  local options="${remaining_args[4]:---single-transaction --quick --lock-tables=false}"

  echo "Backing up tables \"$tables\" from database \"$database\" to \"$output_file\"..."
  __mysql_dump "$host" "$user" "$password" "$port" "$database" "$tables" "$options" "$output_file"

  if [ $? -eq 0 ]; then
    echo "Table backup completed successfully: $output_file"
    echo "File size: $(du -h "$output_file" | cut -f1)"
  else
    echo "Error: Table backup failed"
    return 1
  fi
}' # Backs up specific tables from a MySQL database

alias myrestore='() {
  echo "Restores a MySQL database from a SQL dump file.\nUsage:\n myrestore <database> <dump_file> [host:localhost] [user:root] [password] [port:3306]"

  if ! _mysql_install_check; then
    _mysql_install_tips
    return 1
  fi

  if [ $# -lt 2 ]; then
    echo "Error: Please specify the database name and dump file"
    echo "Example: myrestore mydatabase backup.sql"
    return 1
  fi

  local database="$1"
  local dump_file="$2"
  local host="${3:-localhost}"
  local user="${4:-root}"
  local password="$5"
  local port="${6:-3306}"

  if [ ! -f "$dump_file" ]; then
    echo "Error: Dump file \"$dump_file\" not found"
    return 1
  fi

  # Check if the file is gzipped
  if [[ "$dump_file" == *.gz ]]; then
    echo "Restoring compressed database \"$database\" from \"$dump_file\"..."

    # Create restore command
    local restore_cmd="gunzip -c \"$dump_file\" | mysql -h \"$host\" -u \"$user\" "

    # Add password if provided
    if [ -n "$password" ]; then
      restore_cmd+="-p\"$password\" "
    fi

    # Add port and database
    restore_cmd+="-P $port \"$database\""

    eval "$restore_cmd"
  else
    echo "Restoring database \"$database\" from \"$dump_file\"..."

    # Create restore command
    local restore_cmd="mysql -h \"$host\" -u \"$user\" "

    # Add password if provided
    if [ -n "$password" ]; then
      restore_cmd+="-p\"$password\" "
    fi

    # Add port and database
    restore_cmd+="-P $port \"$database\" < \"$dump_file\""

    eval "$restore_cmd"
  fi

  if [ $? -eq 0 ]; then
    echo "Database restore completed successfully"
  else
    echo "Error: Database restore failed"
    return 1
  fi
}' # Restores a MySQL database from a SQL dump file

# Database Creation and Management
alias mycreate='() {
  echo "Creates a new MySQL database.\nUsage:\n mycreate <database> [host:localhost] [user:root] [password] [port:3306] [charset:utf8mb4] [collation:utf8mb4_unicode_ci]"

  if ! _mysql_install_check; then
    _mysql_install_tips
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Error: Please specify the database name"
    return 1
  fi

  local database="$1"
  local host="${2:-localhost}"
  local user="${3:-root}"
  local password="$4"
  local port="${5:-3306}"
  local charset="${6:-utf8mb4}"
  local collation="${7:-utf8mb4_unicode_ci}"

  echo "Creating database \"$database\" with charset \"$charset\" and collation \"$collation\"..."
  __mysql_connect "$host" "$user" "$password" "$port" "" "-e \"CREATE DATABASE IF NOT EXISTS \\\"$database\\\" CHARACTER SET $charset COLLATE $collation;\""

  if [ $? -eq 0 ]; then
    echo "Database \"$database\" created successfully"
  else
    echo "Error: Failed to create database \"$database\""
    return 1
  fi
}' # Creates a new MySQL database

alias mydrop='() {
  echo "Drops a MySQL database.\nUsage:\n mydrop <database> [host:localhost] [user:root] [password] [port:3306]"

  if ! _mysql_install_check; then
    _mysql_install_tips
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Error: Please specify the database name"
    return 1
  fi

  local database="$1"
  local host="${2:-localhost}"
  local user="${3:-root}"
  local password="$4"
  local port="${5:-3306}"

  # Confirm database drop
  read -p "Are you sure you want to drop database \"$database\"? This action cannot be undone. (y/n): " confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Database drop cancelled"
    return 0
  fi

  echo "Dropping database \"$database\"..."
  __mysql_connect "$host" "$user" "$password" "$port" "" "-e \"DROP DATABASE IF EXISTS \\\"$database\\\";\""

  if [ $? -eq 0 ]; then
    echo "Database \"$database\" dropped successfully"
  else
    echo "Error: Failed to drop database \"$database\""
    return 1
  fi
}' # Drops a MySQL database

# User Management
alias myusers='() {
  echo "Lists MySQL users.\nUsage:\n myusers [host:localhost] [user:root] [password] [port:3306]"

  if ! _mysql_install_check; then
    _mysql_install_tips
    return 1
  fi

  local host="${1:-localhost}"
  local user="${2:-root}"
  local password="$3"
  local port="${4:-3306}"

  __mysql_connect "$host" "$user" "$password" "$port" "mysql" "-e \"SELECT User, Host, plugin FROM user ORDER BY User, Host;\""
}' # Lists MySQL users

alias mycreate-user='() {
  echo "Creates a new MySQL user.\nUsage:\n mycreate-user <username> <password> [host:%] [privileges:ALL] [database:*] [grant_option:false] [admin_host:localhost] [admin_user:root] [admin_password] [admin_port:3306]"

  if ! _mysql_install_check; then
    _mysql_install_tips
    return 1
  fi

  if [ $# -lt 2 ]; then
    echo "Error: Please specify the username and password"
    echo "Example: mycreate-user newuser password123"
    return 1
  fi

  local username="$1"
  local user_password="$2"
  local user_host="${3:-%}"
  local privileges="${4:-ALL}"
  local database="${5:-*}"
  local grant_option="${6:-false}"
  local admin_host="${7:-localhost}"
  local admin_user="${8:-root}"
  local admin_password="$9"
  local admin_port="${10:-3306}"

  # Create user SQL
  local create_user_sql="CREATE USER \\\"$username\\\"@\\\"$user_host\\\" IDENTIFIED BY \\\"$user_password\\\";"

  # Grant privileges SQL
  local grant_sql="GRANT $privileges ON "

  # Handle database specification
  if [ "$database" = "*" ]; then
    grant_sql+="*.*"
  else
    grant_sql+="\\\"$database\\\".* "
  fi

  grant_sql+=" TO \\\"$username\\\"@\\\"$user_host\\\""

  # Add WITH GRANT OPTION if requested
  if [ "$grant_option" = "true" ]; then
    grant_sql+=" WITH GRANT OPTION"
  fi

  grant_sql+=";"

  # Flush privileges SQL
  local flush_sql="FLUSH PRIVILEGES;"

  # Execute SQL commands
  echo "Creating user \"$username\"@\"$user_host\" with privileges \"$privileges\" on \"$database\"..."
  __mysql_connect "$admin_host" "$admin_user" "$admin_password" "$admin_port" "" "-e \"$create_user_sql $grant_sql $flush_sql\""

  if [ $? -eq 0 ]; then
    echo "User \"$username\"@\"$user_host\" created successfully"
  else
    echo "Error: Failed to create user \"$username\"@\"$user_host\""
    return 1
  fi
}' # Creates a new MySQL user

alias mydrop-user='() {
  echo "Drops a MySQL user.\nUsage:\n mydrop-user <username> [host:%] [admin_host:localhost] [admin_user:root] [admin_password] [admin_port:3306]"

  if ! _mysql_install_check; then
    _mysql_install_tips
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Error: Please specify the username"
    return 1
  fi

  local username="$1"
  local user_host="${2:-%}"
  local admin_host="${3:-localhost}"
  local admin_user="${4:-root}"
  local admin_password="$5"
  local admin_port="${6:-3306}"

  # Confirm user drop
  read -p "Are you sure you want to drop user \"$username\"@\"$user_host\"? This action cannot be undone. (y/n): " confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "User drop cancelled"
    return 0
  fi

  # Drop user SQL
  local drop_user_sql="DROP USER IF EXISTS \\\"$username\\\"@\\\"$user_host\\\";"

  # Flush privileges SQL
  local flush_sql="FLUSH PRIVILEGES;"

  # Execute SQL commands
  echo "Dropping user \"$username\"@\"$user_host\"..."
  __mysql_connect "$admin_host" "$admin_user" "$admin_password" "$admin_port" "" "-e \"$drop_user_sql $flush_sql\""

  if [ $? -eq 0 ]; then
    echo "User \"$username\"@\"$user_host\" dropped successfully"
  else
    echo "Error: Failed to drop user \"$username\"@\"$user_host\""
    return 1
  fi
}' # Drops a MySQL user

# Performance Monitoring
alias myps='() {
  echo "Shows MySQL process list.\nUsage:\n myps [host:localhost] [user:root] [password] [port:3306]"

  if ! _mysql_install_check; then
    _mysql_install_tips
    return 1
  fi

  local host="${1:-localhost}"
  local user="${2:-root}"
  local password="$3"
  local port="${4:-3306}"

  __mysql_connect "$host" "$user" "$password" "$port" "" "-e \"SHOW PROCESSLIST;\""
}' # Shows MySQL process list

alias mystatus='() {
  echo "Shows MySQL server status.\nUsage:\n mystatus [host:localhost] [user:root] [password] [port:3306]"

  if ! _mysql_install_check; then
    _mysql_install_tips
    return 1
  fi

  local host="${1:-localhost}"
  local user="${2:-root}"
  local password="$3"
  local port="${4:-3306}"

  __mysql_connect "$host" "$user" "$password" "$port" "" "-e \"SHOW STATUS;\""
}' # Shows MySQL server status

alias myvars='() {
  echo "Shows MySQL server variables.\nUsage:\n myvars [pattern] [host:localhost] [user:root] [password] [port:3306]"

  if ! _mysql_install_check; then
    _mysql_install_tips
    return 1
  fi

  local pattern="$1"
  local host="${2:-localhost}"
  local user="${3:-root}"
  local password="$4"
  local port="${5:-3306}"

  if [ -n "$pattern" ]; then
    __mysql_connect "$host" "$user" "$password" "$port" "" "-e \"SHOW VARIABLES LIKE '%$pattern%';\""
  else
    __mysql_connect "$host" "$user" "$password" "$port" "" "-e \"SHOW VARIABLES;\""
  fi
}' # Shows MySQL server variables

alias myengines='() {
  echo "Shows MySQL storage engines.\nUsage:\n myengines [host:localhost] [user:root] [password] [port:3306]"

  if ! _mysql_install_check; then
    _mysql_install_tips
    return 1
  fi

  local host="${1:-localhost}"
  local user="${2:-root}"
  local password="$3"
  local port="${4:-3306}"

  __mysql_connect "$host" "$user" "$password" "$port" "" "-e \"SHOW ENGINES;\""
}' # Shows MySQL storage engines

alias myversion='() {
  echo "Shows MySQL server version.\nUsage:\n myversion [host:localhost] [user:root] [password] [port:3306]"

  if ! _mysql_install_check; then
    _mysql_install_tips
    return 1
  fi

  local host="${1:-localhost}"
  local user="${2:-root}"
  local password="$3"
  local port="${4:-3306}"

  __mysql_connect "$host" "$user" "$password" "$port" "" "-e \"SELECT VERSION();\""
}' # Shows MySQL server version

alias myslow='() {
  echo "Shows MySQL slow query log.\nUsage:\n myslow [limit:10] [host:localhost] [user:root] [password] [port:3306]"

  if ! _mysql_install_check; then
    _mysql_install_tips
    return 1
  fi

  local limit="${1:-10}"
  local host="${2:-localhost}"
  local user="${3:-root}"
  local password="$4"
  local port="${5:-3306}"

  __mysql_connect "$host" "$user" "$password" "$port" "" "-e \"SHOW VARIABLES LIKE '%slow_query%'; SELECT * FROM mysql.slow_log ORDER BY start_time DESC LIMIT $limit;\""
}' # Shows MySQL slow query log

alias mycheck='() {
  echo "Checks MySQL table status.\nUsage:\n mycheck <database> [table] [host:localhost] [user:root] [password] [port:3306]"

  if ! _mysql_install_check; then
    _mysql_install_tips
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Error: Please specify the database name"
    return 1
  fi

  local database="$1"
  local table="$2"
  local host="${3:-localhost}"
  local user="${4:-root}"
  local password="$5"
  local port="${6:-3306}"

  if [ -n "$table" ]; then
    echo "Checking table \"$table\" in database \"$database\"..."
    __mysql_connect "$host" "$user" "$password" "$port" "$database" "-e \"CHECK TABLE \\\"$table\\\";\""
  else
    echo "Checking all tables in database \"$database\"..."
    __mysql_connect "$host" "$user" "$password" "$port" "$database" "-e \"SHOW TABLE STATUS;\""
  fi
}' # Checks MySQL table status

alias myrepair='() {
  echo "Repairs MySQL table.\nUsage:\n myrepair <database> <table> [host:localhost] [user:root] [password] [port:3306]"

  if ! _mysql_install_check; then
    _mysql_install_tips
    return 1
  fi

  if [ $# -lt 2 ]; then
    echo "Error: Please specify the database name and table name"
    echo "Example: myrepair mydatabase users"
    return 1
  fi

  local database="$1"
  local table="$2"
  local host="${3:-localhost}"
  local user="${4:-root}"
  local password="$5"
  local port="${6:-3306}"

  echo "Repairing table \"$table\" in database \"$database\"..."
  __mysql_connect "$host" "$user" "$password" "$port" "$database" "-e \"REPAIR TABLE \\\"$table\\\";\""
}' # Repairs MySQL table

alias myoptimize='() {
  echo "Optimizes MySQL table.\nUsage:\n myoptimize <database> <table> [host:localhost] [user:root] [password] [port:3306]"

  if ! _mysql_install_check; then
    _mysql_install_tips
    return 1
  fi

  if [ $# -lt 2 ]; then
    echo "Error: Please specify the database name and table name"
    echo "Example: myoptimize mydatabase users"
    return 1
  fi

  local database="$1"
  local table="$2"
  local host="${3:-localhost}"
  local user="${4:-root}"
  local password="$5"
  local port="${6:-3306}"

  echo "Optimizing table \"$table\" in database \"$database\"..."
  __mysql_connect "$host" "$user" "$password" "$port" "$database" "-e \"OPTIMIZE TABLE \\\"$table\\\";\""
}' # Optimizes MySQL table

alias mysize='() {
  echo "Shows MySQL database size.\nUsage:\n mysize [database] [host:localhost] [user:root] [password] [port:3306]"

  if ! _mysql_install_check; then
    _mysql_install_tips
    return 1
  fi

  local database="$1"
  local host="${2:-localhost}"
  local user="${3:-root}"
  local password="$4"
  local port="${5:-3306}"

  if [ -n "$database" ]; then
    echo "Calculating size of database \"$database\"..."
    __mysql_connect "$host" "$user" "$password" "$port" "information_schema" "-e \"SELECT table_schema AS 'Database', ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' FROM information_schema.tables WHERE table_schema = '$database' GROUP BY table_schema;\""
  else
    echo "Calculating size of all databases..."
    __mysql_connect "$host" "$user" "$password" "$port" "information_schema" "-e \"SELECT table_schema AS 'Database', ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' FROM information_schema.tables GROUP BY table_schema;\""
  fi
}' # Shows MySQL database size

alias mytsize='() {
  echo "Shows MySQL table sizes.\nUsage:\n mytsize <database> [host:localhost] [user:root] [password] [port:3306]"

  if ! _mysql_install_check; then
    _mysql_install_tips
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Error: Please specify the database name"
    return 1
  fi

  local database="$1"
  local host="${2:-localhost}"
  local user="${3:-root}"
  local password="$4"
  local port="${5:-3306}"

  echo "Calculating table sizes in database \"$database\"..."
  __mysql_connect "$host" "$user" "$password" "$port" "information_schema" "-e \"SELECT table_name AS 'Table', ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)' FROM information_schema.tables WHERE table_schema = '$database' ORDER BY (data_length + index_length) DESC;\""
}' # Shows MySQL table sizes

# MySQL Help Function
alias mysql-help='() {
  # Define colors
  local reset="\033[0m"
  local bold="\033[1m"
  local cyan="\033[36m"
  local green="\033[32m"
  local yellow="\033[33m"
  local blue="\033[34m"
  local magenta="\033[35m"
  local red="\033[31m"

  echo "${bold}MySQL Aliases Help${reset}"
  echo "${yellow}====================${reset}"
  echo ""
  echo "${bold}Basic Operations:${reset}"
  echo "  ${green}myl${reset}              - List all MySQL databases"
  echo "  ${green}mydb${reset}             - Connect to a MySQL database"
  echo "  ${green}myq${reset}              - Execute a SQL query on a MySQL database"
  echo "  ${green}myt${reset}              - List all tables in a MySQL database"
  echo "  ${green}mytd${reset}             - Show the structure of a MySQL table"
  echo ""
  echo "${bold}Backup and Restore:${reset}"
  echo "  ${green}mybackup${reset}         - Back up a MySQL database"
  echo "  ${green}mybackup-gz${reset}      - Back up a MySQL database with gzip compression"
  echo "  ${green}mytbackup${reset}        - Back up specific tables from a MySQL database"
  echo "  ${green}myrestore${reset}        - Restore a MySQL database from a SQL dump file"
  echo ""
  echo "${bold}Database Management:${reset}"
  echo "  ${green}mycreate${reset}         - Create a new MySQL database"
  echo "  ${green}mydrop${reset}           - Drop a MySQL database"
  echo ""
  echo "${bold}User Management:${reset}"
  echo "  ${green}myusers${reset}          - List MySQL users"
  echo "  ${green}mycreate-user${reset}    - Create a new MySQL user"
  echo "  ${green}mydrop-user${reset}      - Drop a MySQL user"
  echo ""
  echo "${bold}Performance Monitoring:${reset}"
  echo "  ${green}myps${reset}             - Show MySQL process list"
  echo "  ${green}mystatus${reset}         - Show MySQL server status"
  echo "  ${green}myvars${reset}           - Show MySQL server variables"
  echo "  ${green}myengines${reset}        - Show MySQL storage engines"
  echo "  ${green}myversion${reset}        - Show MySQL server version"
  echo "  ${green}myslow${reset}           - Show MySQL slow query log"
  echo ""
  echo "${bold}Maintenance:${reset}"
  echo "  ${green}mycheck${reset}          - Check MySQL table status"
  echo "  ${green}myrepair${reset}         - Repair MySQL table"
  echo "  ${green}myoptimize${reset}       - Optimize MySQL table"
  echo "  ${green}mysize${reset}           - Show MySQL database size"
  echo "  ${green}mytsize${reset}          - Show MySQL table sizes"
  echo ""
  echo "${yellow}For detailed usage of each command, run the command without arguments.${reset}"
}' # MySQL aliases help function
