# Description: Docker application container management aliases for quick container deployment.

# Docker Application Containers
# ============================

# Start TinyFileManager container
alias dapp-filemanager='() {
  echo "Create TinyFileManager container"
  echo "Usage:"
  echo "  dapp-filemanager <path> <port:80> [container_name:tinyfilemanager] [image:tinyfilemanager/tinyfilemanager:master]"
  echo "Example: dapp-filemanager /absolute/path 80 tinyfilemanager"

  local mount_path="${1}"
  local port="${2:-80}"
  local container_name="${3:-tinyfilemanager}"
  local image="${4:-tinyfilemanager/tinyfilemanager:master}"

  if [ -z "$mount_path" ]; then
    echo "Error: Mount path is required" >&2
    return 1
  fi

  echo "Creating TinyFileManager container..."
  if ! docker run -d -v "$mount_path":/var/www/html/data -p "$port":80 --restart=always --name "$container_name" "$image"; then
    echo "Failed to create TinyFileManager container" >&2
    return 1
  fi

  echo "TinyFileManager container created successfully"
}' # Deploy TinyFileManager container

# Start Hello World container
alias dapp-hello='() {
  echo "Create Hello World container"
  echo "Usage:"
  echo "  dapp-hello [container_name:hello] [image:hello-world:latest]"

  local container_name="${1:-hello}"
  local image="${2:-hello-world:latest}"

  echo "Creating Hello World container..."
  if ! docker run -d --name "$container_name" --restart=on-failure "$image"; then
    echo "Failed to create Hello World container" >&2
    return 1
  fi

  echo "Hello World container created successfully"
}' # Deploy Hello World container

# Start FileBrowser container
alias dapp-filebrowser='() {
  echo "Create FileBrowser container"
  echo "Usage:"
  echo "  dapp-filebrowser <path> <port:80> [container_name:filebrowser] [image:filebrowser/filebrowser:latest]"
  echo "Example: dapp-filebrowser /mnt/tmp 1211 filebrowser"

  local mount_path="${1}"
  local port="${2:-80}"
  local container_name="${3:-filebrowser}"
  local image="${4:-filebrowser/filebrowser:latest}"

  if [ -z "$mount_path" ]; then
    echo "Error: Mount path is required" >&2
    return 1
  fi

  echo "Creating FileBrowser container..."
  if ! docker run -d -v "$mount_path":/srv -e PUID=$(id -u) -e PGID=$(id -g) -p "$port":80 --restart=always --name "$container_name" "$image"; then
    echo "Failed to create FileBrowser container" >&2
    return 1
  fi

  echo "FileBrowser container created successfully"
}' # Deploy FileBrowser container

# Start PHPMyAdmin container
alias dapp-phpmyadmin='() {
  echo "Create PHPMyAdmin container"
  echo "Usage:"
  echo "  dapp-phpmyadmin <db_host> <db_port> <container_port> [container_name:phpmyadmin] [image:phpmyadmin:latest]"
  echo "Example: dapp-phpmyadmin 0.0.0.0 3306 8080 phpmyadmin"

  local db_host="${1}"
  local db_port="${2}"
  local container_port="${3}"
  local container_name="${4:-phpmyadmin}"
  local image="${5:-phpmyadmin:latest}"

  if [ -z "$db_host" ] || [ -z "$db_port" ] || [ -z "$container_port" ]; then
    echo "Error: Database host, port and container port are required" >&2
    return 1
  fi

  echo "Creating PHPMyAdmin container..."
  if ! docker run -d -e PMA_ARBITRARY=1 -e PMA_HOST="$db_host" -e PMA_PORT="$db_port" -p "$container_port":80 --restart=always --name "$container_name" "$image"; then
    echo "Failed to create PHPMyAdmin container" >&2
    return 1
  fi

  echo "PHPMyAdmin container created successfully"
}' # Deploy PHPMyAdmin container

# Start MySQL container
alias dapp-mysql='() {
  echo "Create MySQL container"
  echo "Usage:"
  echo "  dapp-mysql <port:3306> <root_password> <data_dir> [container_name:mysql] [image:mysql:8.0]"
  echo "Example: dapp-mysql 3306 my-secret-pw /path/to/mysql/data mysql"

  local port="${1:-3306}"
  local root_password="${2}"
  local data_dir="${3}"
  local container_name="${4:-mysql}"
  local image="${5:-mysql:8.0}"

  if [ -z "$root_password" ] || [ -z "$data_dir" ]; then
    echo "Error: Root password and data directory are required" >&2
    return 1
  fi

  echo "Creating MySQL container..."
  if ! docker run -d -p "$port":3306 -e MYSQL_ROOT_PASSWORD="$root_password" -v "$data_dir":/var/lib/mysql --restart=always --name "$container_name" "$image"; then
    echo "Failed to create MySQL container" >&2
    return 1
  fi

  echo "MySQL container created successfully"
}' # Deploy MySQL container

# Start PostgreSQL container
alias dapp-postgres='() {
  echo "Create PostgreSQL container"
  echo "Usage:"
  echo "  dapp-postgres <port:5432> <password> <data_dir> [container_name:postgres] [image:postgres:15]"
  echo "Example: dapp-postgres 5432 my-secret-pw /path/to/postgres/data postgres"

  local port="${1:-5432}"
  local password="${2}"
  local data_dir="${3}"
  local container_name="${4:-postgres}"
  local image="${5:-postgres:15}"

  if [ -z "$password" ] || [ -z "$data_dir" ]; then
    echo "Error: Password and data directory are required" >&2
    return 1
  fi

  echo "Creating PostgreSQL container..."
  if ! docker run -d -p "$port":5432 -e POSTGRES_PASSWORD="$password" -v "$data_dir":/var/lib/postgresql/data \
    --restart=always --name "$container_name" "$image"; then
    echo "Failed to create PostgreSQL container" >&2
    return 1
  fi

  echo "PostgreSQL container created successfully"
}' # Deploy PostgreSQL container

# Start Redis container
alias dapp-redis='() {
  echo "Create Redis container"
  echo "Usage:"
  echo "  dapp-redis <port:6379> [data_dir] [container_name:redis] [image:redis:7.0]"
  echo "Example: dapp-redis 6379 /path/to/redis/data redis"

  local port="${1:-6379}"
  local data_dir="${2}"
  local container_name="${3:-redis}"
  local image="${4:-redis:7.0}"
  local data_mount=""

  if [ -n "$data_dir" ]; then
    data_mount="-v $data_dir:/data"
  fi

  echo "Creating Redis container..."
  if ! docker run -d -p "$port":6379 $data_mount --restart=always --name "$container_name" "$image"; then
    echo "Failed to create Redis container" >&2
    return 1
  fi

  echo "Redis container created successfully"
}' # Deploy Redis container

# Start MongoDB container
alias dapp-mongodb='() {
  echo "Create MongoDB container"
  echo "Usage:"
  echo "  dapp-mongodb <port:27017> <data_dir> [container_name:mongodb] [image:mongo:6.0]"
  echo "Example: dapp-mongodb 27017 /path/to/mongo/data mongodb"

  local port="${1:-27017}"
  local data_dir="${2}"
  local container_name="${3:-mongodb}"
  local image="${4:-mongo:6.0}"

  if [ -z "$data_dir" ]; then
    echo "Error: Data directory is required" >&2
    return 1
  fi

  echo "Creating MongoDB container..."
  if ! docker run -d -p "$port":27017 -v "$data_dir":/data/db --restart=always --name "$container_name" "$image"; then
    echo "Failed to create MongoDB container" >&2
    return 1
  fi

  echo "MongoDB container created successfully"
}' # Deploy MongoDB container

# Start Metabase container
alias dapp-metabase='() {
  echo "Create Metabase container"
  echo "Usage:"
  echo "  dapp-metabase <port:3000> [container_name:metabase] [image:metabase/metabase:latest]"
  echo "Example: dapp-metabase 3000 metabase"

  local port="${1:-3000}"
  local container_name="${2:-metabase}"
  local image="${3:-metabase/metabase:latest}"

  echo "Creating Metabase container..."
  if ! docker run -d -p "$port":3000 --restart=always --name "$container_name" "$image"; then
    echo "Failed to create Metabase container" >&2
    return 1
  fi

  echo "Metabase container created successfully"
}' # Deploy Metabase container

# Start AList container
alias dapp-alist='() {
  echo "Create AList container"
  echo "Usage:"
  echo "  dapp-alist <port:5244> <data_dir> [container_name:alist] [image:xhofe/alist:latest]"
  echo "Example: dapp-alist 5244 /path/to/alist/data alist"

  local port="${1:-5244}"
  local data_dir="${2}"
  local container_name="${3:-alist}"
  local image="${4:-xhofe/alist:latest}"

  if [ -z "$data_dir" ]; then
    echo "Error: Data directory is required" >&2
    return 1
  fi

  echo "Creating AList container..."
  if ! docker run -d -p "$port":5244 -v "$data_dir":/opt/alist/data --restart=always --name "$container_name" "$image"; then
    echo "Failed to create AList container" >&2
    return 1
  fi

  echo "AList container created successfully"
}' # Deploy AList container

# Help function for Docker application aliases
alias dapp-help='() {
  echo "Docker Application Aliases Help"
  echo "=============================="
  echo "Available commands:"
  echo "  dapp-filemanager  - Deploy TinyFileManager container"
  echo "  dapp-filebrowser  - Deploy FileBrowser container"
  echo "  dapp-hello        - Deploy Hello World container"
  echo "  dapp-phpmyadmin   - Deploy PHPMyAdmin container"
  echo "  dapp-mysql        - Deploy MySQL database container"
  echo "  dapp-postgres     - Deploy PostgreSQL database container"
  echo "  dapp-redis        - Deploy Redis database container"
  echo "  dapp-mongodb      - Deploy MongoDB database container"
  echo "  dapp-metabase     - Deploy Metabase analytics platform"
  echo "  dapp-alist        - Deploy AList file list program"
  echo "  dapp-help         - Display this help message"
  echo
  echo "For detailed usage information, run any command without arguments"
  echo "All commands support optional image parameter to specify custom image source and version"
}' # Display help for Docker application aliases
