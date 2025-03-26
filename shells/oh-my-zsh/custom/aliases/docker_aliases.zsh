# Description: Docker related aliases for container, image and compose management with enhanced functionality.

# Container Management
alias dps='() {
  echo "Displays all Docker containers.\nUsage:\n dps [container_name_filter]"
  if [ -n "$1" ]; then
    docker ps -a | grep "$1"
  else
    docker ps -a
  fi
}' # Lists all containers, with optional filter

alias watchdps='() {
  echo "Monitors Docker container status in real-time.\nUsage:\n watchdps [interval_seconds]"
  interval=${1:-1}
  if ! command -v watch &> /dev/null; then
    echo "Error: \"watch\" command not found."
    if [[ "$(uname)" == "Darwin" ]]; then
      echo "Try installing it with: brew install watch"
    else
      echo "Try installing it with your package manager"
    fi
    return 1
  fi
  watch -n $interval "docker ps -a"
}' # Monitors container status in real-time, with adjustable refresh interval

alias dnet='() { 
  echo "Displays Docker networks.\nUsage:\n dnet [network_name_filter]"
  if [ -n "$1" ]; then
    docker network ls | grep "$1"
  else
    docker network ls
  fi
}' # Lists all networks, with optional filter

# Image Management
alias dimages='() {
  echo "Displays all Docker images.\nUsage:\n dimages [image_name_filter]"
  if [ -n "$1" ]; then
    docker images | grep "$1"
  else
    docker images
  fi
}' # Lists all images, with optional filter

# Container Operations
alias dstop='() {
  echo "Stops the specified Docker container(s).\nUsage:\n dstop <container_id or container_name> [container2...]"
  if [ $# -eq 0 ]; then
    echo "Error: Please specify the container ID or name to stop"
    return 1
  fi
  docker stop "$@"
  echo "Attempted to stop container(s): $@"
}' # Stops specified container(s)

alias dstopall='() { 
  echo "Stops all Docker containers.\nUsage:\n dstopall"
  running_containers=$(docker ps -q)
  if [ -z "$running_containers" ]; then
    echo "No containers are running"
  else
    docker stop $(docker ps -q)
    echo "Stopped all containers"
  fi
}' # Stops all containers

alias drm='() { 
  echo "Removes the specified Docker container(s).\nUsage:\n drm <container_id or container_name> [container2...]"
  if [ $# -eq 0 ]; then
    echo "Error: Please specify the container ID or name to remove"
    return 1
  fi
  docker rm "$@"
  echo "Removed container(s): $@"
}' # Removes specified container(s)

alias drst='() { 
  echo "Restarts the specified Docker container(s).\nUsage:\n drst <container_id or container_name> [container2...]"
  if [ $# -eq 0 ]; then
    echo "Error: Please specify the container ID or name to restart"
    return 1
  fi
  docker restart "$@"
  echo "Restarted container(s): $@"
}' # Restarts specified container(s)

alias drmi='() { 
  echo "Removes the specified Docker image(s).\nUsage:\n drmi <image_id or image_name> [image2...]"
  if [ $# -eq 0 ]; then
    echo "Error: Please specify the image ID or name to remove"
    return 1
  fi
  docker rmi "$@"
  echo "Removed image(s): $@"
}' # Removes specified image(s)

alias dren='() { 
  echo "Renames a Docker container.\nUsage:\n dren <old_name> <new_name>"
  if [ $# -ne 2 ]; then
    echo "Error: Please provide the old and new container names"
    echo "Example: dren old_container new_container"
    return 1
  fi
  docker rename "$1" "$2"
  echo "Renamed container $1 to $2"
}' # Renames a container

# Container Logs and Terminal
alias dlogs='() {
  echo "Displays Docker container logs.\nUsage:\n dlogs <container_id or container_name> [number_of_lines=300]"
  if [ $# -eq 0 ]; then
    echo "Error: Please specify the container ID or name"
    return 1
  fi
  docker logs -f -t --tail ${2:-300} "$1"
}' # Shows container logs, defaults to last 300 lines

alias dbash='() { 
  echo "Enters a Docker container terminal.\nUsage:\n dbash <container_id or container_name> [command=bash/sh]"
  if [ $# -eq 0 ]; then
    echo "Error: Please specify the container ID or name"
    return 1
  fi
  
  command=${2:-bash}
  if docker exec -it "$1" $command 2>/dev/null; then
    :
  elif docker exec -it "$1" sh; then
    :
  else
    echo "Error: Unable to enter the terminal of container $1"
    return 1
  fi
}' # Enters container terminal, tries bash, then sh

alias dexec='() { 
  echo "Executes a command in a Docker container.\nUsage:\n dexec <container_id or container_name> <command> [args...]"
  if [ $# -lt 2 ]; then
    echo "Error: Please specify the container ID or name and the command to execute"
    echo "Example: dexec my_container ls -la"
    return 1
  fi
  docker exec -it "$1" "${@:2}"
}' # Executes a command in a container

# File Transfer
alias dcp='() { 
  echo "Copies a file from the local machine to a Docker container.\nUsage:\n dcp <local_path> <container_name>:<container_path>"
  if [ $# -ne 2 ]; then
    echo "Error: Please provide the local path and the container path"
    echo "Example: dcp ./local_file.txt my_container:/app/file.txt"
    return 1
  fi
  docker cp "$1" "$2"
  echo "Copied $1 to container $2"
}' # Copies file to container

alias dcpl='() { 
  echo "Copies a file from a Docker container to the local machine.\nUsage:\n dcpl <container_name>:<container_path> <local_path>"
  if [ $# -ne 2 ]; then
    echo "Error: Please provide the container path and the local path"
    echo "Example: dcpl my_container:/app/file.txt ./local_file.txt"
    return 1
  fi
  docker cp "$1" "$2"
  echo "Copied $1 from container to $2"
}' # Copies file from container

# Forceful Operations
alias drmq='() { 
  echo "Forcefully removes all Docker containers.\nUsage:\n drmq [--force/-f]"
  container_count=$(docker ps -aq | wc -l | tr -d " ")
  
  if [ "$container_count" -eq 0 ]; then
    echo "No containers to remove"
    return 0
  fi
  
  force=0
  if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
    force=1
  elif [ -n "$1" ]; then
    echo "Error: Unknown parameter $1"
    echo "Usage: drmq [--force/-f]"
    return 1
  fi
  
  if [ $force -eq 0 ]; then
    echo "Warning: About to remove $container_count containers"
    echo "Use --force or -f to skip confirmation"
    read -p "Confirm removal? (y/n): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
      echo "Operation cancelled"
      return 0
    fi
  fi
  
  docker rm -f $(docker ps -aq)
  echo "Forcefully removed $container_count containers"
}' # Forcefully removes all containers, with optional confirmation prompt

alias dsrm='() { 
  echo "Stops and removes the specified Docker container(s).\nUsage:\n dsrm <container_id or container_name> [container2...]"
  if [ $# -eq 0 ]; then
    echo "Error: Please specify the container ID or name to stop and remove"
    return 1
  fi
  docker stop "$@" && docker rm "$@"
  echo "Stopped and removed container(s): $@"
}' # Stops and removes specified container(s)

# Image Operations
alias dpl='() { 
  echo "Pulls a Docker image.\nUsage:\n dpl <image_name>[:tag]"
  if [ $# -eq 0 ]; then
    echo "Error: Please specify the image name to pull"
    return 1
  fi
  docker pull "$@"
  echo "Pulled image(s): $@"
}' # Pulls an image

# Docker Compose Detection Function
__docker_compose_cmd() {
  if command -v docker-compose &> /dev/null; then
    echo "docker-compose"
  else
    echo "docker compose"
  fi
}

# Docker Compose Operations
alias dcupd='() { 
  echo "Starts containers using Docker Compose.\nUsage:\n dcupd [service_name] [service2...]"
  compose_cmd=$(__docker_compose_cmd)
  
  if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ] || [ -f "compose.yml" ] || [ -f "compose.yaml" ]; then
    $compose_cmd up -d "$@"
    echo "Started Docker Compose service(s): ${@:-all}"
  else
    echo "Error: Docker Compose configuration file not found in the current directory"
    return 1
  fi
}' # Starts containers using Docker Compose

alias dcdown='() { 
  echo "Stops containers using Docker Compose.\nUsage:\n dcdown [options]"
  compose_cmd=$(__docker_compose_cmd)
  
  if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ] || [ -f "compose.yml" ] || [ -f "compose.yaml" ]; then
    $compose_cmd down "$@"
    echo "Stopped Docker Compose service(s)"
  else
    echo "Error: Docker Compose configuration file not found in the current directory"
    return 1
  fi
}' # Stops containers using Docker Compose

alias dcrestart='() { 
  echo "Restarts containers using Docker Compose.\nUsage:\n dcrestart [service_name] [service2...]"
  compose_cmd=$(__docker_compose_cmd)
  
  if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ] || [ -f "compose.yml" ] || [ -f "compose.yaml" ]; then
    $compose_cmd restart "$@"
    echo "Restarted Docker Compose service(s): ${@:-all}"
  else
    echo "Error: Docker Compose configuration file not found in the current directory"
    return 1
  fi
}' # Restarts containers using Docker Compose

alias dcsrm='() { 
  echo "Stops and removes containers using Docker Compose.\nUsage:\n dcsrm [service_name] [service2...]"
  compose_cmd=$(__docker_compose_cmd)
  
  if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ] || [ -f "compose.yml" ] || [ -f "compose.yaml" ]; then
    $compose_cmd stop "$@" && $compose_cmd rm -f "$@"
    echo "Stopped and removed Docker Compose service(s): ${@:-all}"
  else
    echo "Error: Docker Compose configuration file not found in the current directory"
    return 1
  fi
}' # Stops and removes containers using Docker Compose

alias dcps='() { 
  echo "Displays Docker Compose container status.\nUsage:\n dcps [service_name]"
  compose_cmd=$(__docker_compose_cmd)
  
  if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ] || [ -f "compose.yml" ] || [ -f "compose.yaml" ]; then
    $compose_cmd ps "$@"
  else
    echo "Error: Docker Compose configuration file not found in the current directory"
    return 1
  fi
}' # Displays Docker Compose container status

alias dclogs='() { 
  echo "Displays Docker Compose container logs.\nUsage:\n dclogs <service_name> [number_of_lines=300]"
  if [ $# -eq 0 ]; then
    echo "Error: Please specify the service name"
    return 1
  fi
  
  compose_cmd=$(__docker_compose_cmd)
  
  if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ] || [ -f "compose.yml" ] || [ -f "compose.yaml" ]; then
    $compose_cmd logs -f -t --tail ${2:-300} "$1"
  else
    echo "Error: Docker Compose configuration file not found in the current directory"
    return 1
  fi
}' # Displays Docker Compose container logs

alias dcbash='() { 
  echo "Enters a Docker Compose container terminal.\nUsage:\n dcbash <service_name> [command=bash/sh]"
  if [ $# -eq 0 ]; then
    echo "Error: Please specify the service name"
    return 1
  fi
  
  compose_cmd=$(__docker_compose_cmd)
  
  if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ] || [ -f "compose.yml" ] || [ -f "compose.yaml" ]; then
    if $compose_cmd exec "$1" bash 2>/dev/null; then
      :
    elif $compose_cmd exec "$1" sh; then
      :
    else
      echo "Error: Unable to enter the terminal of service $1"
      return 1
    fi
  else
    echo "Error: Docker Compose configuration file not found in the current directory"
    return 1
  fi
}' # Enters Docker Compose container terminal

alias dce='() { 
  echo "Executes a command in a Docker Compose container.\nUsage:\n dce <service_name> <command> [args...]"
  if [ $# -lt 2 ]; then
    echo "Error: Please specify the service name and the command to execute"
    echo "Example: dce web ls -la"
    return 1
  fi
  
  compose_cmd=$(__docker_compose_cmd)
  
  if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ] || [ -f "compose.yml" ] || [ -f "compose.yaml" ]; then
    $compose_cmd exec "$@"
  else
    echo "Error: Docker Compose configuration file not found in the current directory"
    return 1
  fi
}' # Executes a command in a Docker Compose container

alias dcr='() { 
  echo "Runs a command using Docker Compose.\nUsage:\n dcr <service_name> <command> [args...]"
  if [ $# -lt 1 ]; then
    echo "Error: Please specify the service name"
    return 1
  fi
  
  compose_cmd=$(__docker_compose_cmd)
  
  if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ] || [ -f "compose.yml" ] || [ -f "compose.yaml" ]; then
    $compose_cmd run "$@"
  else
    echo "Error: Docker Compose configuration file not found in the current directory"
    return 1
  fi
}' # Runs a command using Docker Compose

alias dcpse='() { 
  echo "Pauses Docker Compose service(s).\nUsage:\n dcpse [service_name] [service2...]"
  compose_cmd=$(__docker_compose_cmd)
  
  if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ] || [ -f "compose.yml" ] || [ -f "compose.yaml" ]; then
    $compose_cmd pause "$@"
    echo "Paused service(s): ${@:-all}"
  else
    echo "Error: Docker Compose configuration file not found in the current directory"
    return 1
  fi
}' # Pauses Docker Compose service(s)

alias dcupse='() { 
  echo "Unpauses Docker Compose service(s).\nUsage:\n dcupse [service_name] [service2...]"
  compose_cmd=$(__docker_compose_cmd)
  
  if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ] || [ -f "compose.yml" ] || [ -f "compose.yaml" ]; then
    $compose_cmd unpause "$@"
    echo "Unpaused service(s): ${@:-all}"
  else
    echo "Error: Docker Compose configuration file not found in the current directory"
    return 1
  fi
}' # Unpauses Docker Compose service(s)

alias dctop='() { 
  echo "Displays Docker Compose container resource usage.\nUsage:\n dctop [service_name] [service2...]"
  compose_cmd=$(__docker_compose_cmd)
  
  if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ] || [ -f "compose.yml" ] || [ -f "compose.yaml" ]; then
    $compose_cmd top "$@"
  else
    echo "Error: Docker Compose configuration file not found in the current directory"
    return 1
  fi
}' # Displays Docker Compose container resource usage

alias dcstop='() { 
  echo "Stops Docker Compose service(s).\nUsage:\n dcstop [service_name] [service2...]"
  compose_cmd=$(__docker_compose_cmd)
  
  if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ] || [ -f "compose.yml" ] || [ -f "compose.yaml" ]; then
    $compose_cmd stop "$@"
    echo "Stopped service(s): ${@:-all}"
  else
    echo "Error: Docker Compose configuration file not found in the current directory"
    return 1
  fi
}' # Stops Docker Compose service(s)

# Performance Monitoring
alias dstat='() { 
  echo "Displays Docker container resource statistics.\nUsage:\n dstat [container_name_filter]"
  format="table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}\t{{.PIDs}}"
  
  if [ -n "$1" ]; then
    # Filter specified container
    container_ids=$(docker ps -q --filter "name=$1")
    if [ -z "$container_ids" ]; then
      echo "Error: No running containers found with names containing '$1'"
      return 1
    fi
    docker stats --format "$format" $(docker ps -q --filter "name=$1")
  else
    # Show all containers
    docker stats --format "$format"
  fi
}' # Displays container resource usage, with optional container name filter

# Additional Utilities
alias dprune='() {
  echo "Cleans up unused Docker resources.\nUsage:\n dprune [--all/-a] [--volumes/-v]"
  
  all=0
  volumes=0
  
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --all|-a)
        all=1
        shift
        ;;
      --volumes|-v)
        volumes=1
        shift
        ;;
      *)
        echo "Error: Unknown parameter $1"
        echo "Usage: dprune [--all/-a] [--volumes/-v]"
        return 1
        ;;
    esac
  done
  
  if [ $all -eq 1 ]; then
    echo "Cleaning up all unused containers, networks, images, and build cache"
    docker system prune -f
    
    if [ $volumes -eq 1 ]; then
      echo "Also cleaning up unused volumes"
      docker volume prune -f
    fi
  else
    echo "Cleaning up dangling images and stopped containers"
    docker container prune -f
    docker image prune -f
    
    if [ $volumes -eq 1 ]; then
      echo "Also cleaning up unused volumes"
      docker volume prune -f
    fi
  fi
  
  echo "Docker resource cleanup complete"
}' # Cleans up unused Docker resources

alias dinspect='() {
  echo "Inspects Docker container, image, or network details.\nUsage:\n dinspect <container|image|network> <name_or_id>"
  if [ $# -lt 2 ]; then
    echo "Error: Please specify the resource type and name/ID to inspect"
    echo "Example: dinspect container nginx"
    echo "      dinspect image ubuntu:20.04"
    echo "      dinspect network bridge"
    return 1
  fi
  
  resource_type=$1
  resource_name=$2
  
  case "$resource_type" in
    container|containers)
      docker container inspect "$resource_name"
      ;;
    image|images)
      docker image inspect "$resource_name"
      ;;
    network|networks)
      docker network inspect "$resource_name"
      ;;
    volume|volumes)
      docker volume inspect "$resource_name"
      ;;
    *)
      echo "Error: Unknown resource type $resource_type"
      echo "Supported types: container, image, network, volume"
      return 1
      ;;
  esac
}' # Inspects Docker resource details