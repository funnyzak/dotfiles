# Description: Docker application container management aliases for quick container deployment.

# Docker Application Containers
# ============================

# Start TinyFileManager container
alias dapp-filemanager='() {
  echo "Create TinyFileManager container"
  echo "Usage:"
  echo "  dapp-filemanager <path> <port:80> <container_name:tinyfilemanager>"
  echo "Example: dapp-filemanager /absolute/path 80 tinyfilemanager"

  local mount_path="${1}"
  local port="${2:-80}"
  local container_name="${3:-tinyfilemanager}"

  if [ -z "$mount_path" ]; then
    echo "Error: Mount path is required" >&2
    return 1
  fi

  echo "Creating TinyFileManager container..."
  if ! docker run -d -v "$mount_path":/var/www/html/data -p "$port":80 --restart=always --name "$container_name" tinyfilemanager/tinyfilemanager:master; then
    echo "Failed to create TinyFileManager container" >&2
    return 1
  fi

  echo "TinyFileManager container created successfully"
}' # Deploy TinyFileManager container

# Start Hello World container
alias dapp-hello='() {
  echo "Create Hello World container"
  echo "Usage:"
  echo "  dapp-hello [container_name:hello]"

  local container_name="${1:-hello}"

  echo "Creating Hello World container..."
  if ! docker run -d --name "$container_name" --restart=on-failure hello-world; then
    echo "Failed to create Hello World container" >&2
    return 1
  fi

  echo "Hello World container created successfully"
}' # Deploy Hello World container

# Start FileBrowser container
alias dapp-filebrowser='() {
  echo "Create FileBrowser container"
  echo "Usage:"
  echo "  dapp-filebrowser <path> <port:80> <container_name:filebrowser>"
  echo "Example: dapp-filebrowser /mnt/tmp 1211 filebrowser"

  local mount_path="${1}"
  local port="${2:-80}"
  local container_name="${3:-filebrowser}"

  if [ -z "$mount_path" ]; then
    echo "Error: Mount path is required" >&2
    return 1
  fi

  echo "Creating FileBrowser container..."
  if ! docker run -d -v "$mount_path":/srv -e PUID=$(id -u) -e PGID=$(id -g) -p "$port":80 --restart=always --name "$container_name" \
    swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/filebrowser/filebrowser:v2.31.1; then
    echo "Failed to create FileBrowser container" >&2
    return 1
  fi

  echo "FileBrowser container created successfully"
}' # Deploy FileBrowser container

# Help function for Docker application aliases
alias dapp-help='() {
  echo "Docker Application Aliases Help"
  echo "=============================="
  echo "Available commands:"
  echo "  dapp-filemanager  - Deploy TinyFileManager container"
  echo "  dapp-filebrowser  - Deploy FileBrowser container"
  echo "  dapp-hello        - Deploy Hello World container"
  echo "  dapp-help         - Display this help message"
  echo
  echo "For detailed usage information, run any command without arguments or with -h/--help flag"
}' # Display help for Docker application aliases
