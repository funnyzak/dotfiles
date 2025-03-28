# Description: Docker related aliases for container, image and compose management with enhanced functionality. These aliases provide shortcuts for common Docker operations, monitoring, and administration tasks with improved error handling and cross-platform compatibility.

# Docker Command Availability Check
__docker_cmd_exists() {
  command -v docker &> /dev/null
  return $?
}

# Docker Compose Detection Function
__docker_compose_cmd() {
  if command -v docker-compose &> /dev/null; then
    echo "docker-compose"
  else
    echo "docker compose"
  fi
}

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
  echo "Inspects Docker container, image, or network details.\nUsage:\n dinspect <container|image|network|volume> <name_or_id>"
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

alias dvol='() {
  echo "Lists Docker volumes.\nUsage:\n dvol [volume_name_filter]"
  if [ -n "$1" ]; then
    docker volume ls | grep "$1"
  else
    docker volume ls
  fi
}' # Lists Docker volumes with optional filter

alias dstart='() {
  echo "Starts stopped Docker container(s).\nUsage:\n dstart <container_id or container_name> [container2...]"
  if [ $# -eq 0 ]; then
    echo "Error: Please specify the container ID or name to start"
    return 1
  fi
  docker start "$@"
  echo "Started container(s): $@"
}' # Starts stopped container(s)

alias dsystem='() {
  echo "Displays Docker system information.\nUsage:\n dsystem [info|df|events]"
  if [ $# -eq 0 ]; then
    docker system info
    return 0
  fi

  case "$1" in
    info)
      docker system info
      ;;
    df)
      docker system df -v
      ;;
    events)
      docker events
      ;;
    *)
      echo "Error: Unknown parameter $1"
      echo "Usage: dsystem [info|df|events]"
      return 1
      ;;
  esac
}' # Displays Docker system information

alias dbuildx='() {
  echo "Build with Docker BuildX.\nUsage:\n dbuildx <build|ls|use|inspect> [options]"
  if [ $# -eq 0 ]; then
    echo "Error: Please specify a BuildX command"
    echo "Available commands: build, ls, use, inspect"
    return 1
  fi

  case "$1" in
    build)
      docker buildx build "${@:2}"
      ;;
    ls)
      docker buildx ls
      ;;
    use)
      if [ $# -lt 2 ]; then
        echo "Error: Please specify the builder instance to use"
        return 1
      fi
      docker buildx use "$2"
      ;;
    inspect)
      if [ $# -lt 2 ]; then
        echo "Error: Please specify the builder instance to inspect"
        return 1
      fi
      docker buildx inspect "$2"
      ;;
    *)
      echo "Error: Unknown BuildX command $1"
      echo "Available commands: build, ls, use, inspect"
      return 1
      ;;
  esac
}' # Docker BuildX helper

alias dhealth='() {
  echo "Checks Docker container health status.\nUsage:\n dhealth [container_name_filter]"

  format="table {{.Names}}\t{{.Status}}\t{{.Health.Status}}"
  if [ -n "$1" ]; then
    docker ps --format "$format" | grep "$1"
  else
    docker ps --format "$format"
  fi
}' # Shows health status of running containers

alias dlint='() {
  echo "Lints Dockerfile.\nUsage:\n dlint <dockerfile_path>"
  if [ $# -eq 0 ]; then
    echo "Error: Please specify the path to the Dockerfile"
    return 1
  fi

  if ! command -v hadolint &> /dev/null; then
    echo "Error: hadolint is not installed"
    if [[ "$(uname)" == "Darwin" ]]; then
      echo "Try installing it with: brew install hadolint"
    else
      echo "Try installing it with: sudo wget -O /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64 && sudo chmod +x /usr/local/bin/hadolint"
    fi
    return 1
  fi

  hadolint "$1"
}' # Lints Dockerfile using hadolint

alias dclean-img='() {
  echo "Removes unused Docker images.\nUsage:\n dclean-img [--all/-a]"

  if [ "$1" = "--all" ] || [ "$1" = "-a" ]; then
    echo "Removing all unused images..."
    docker image prune -a -f
  else
    echo "Removing dangling images..."
    docker image prune -f
  fi
}' # Removes unused Docker images

alias dclean-vol='() {
  echo "Removes unused Docker volumes.\nUsage:\n dclean-vol"

  if [ "$(docker volume ls -qf dangling=true | wc -l | tr -d " ")" -eq 0 ]; then
    echo "No unused volumes to remove"
    return 0
  fi

  echo "Removing unused volumes..."
  docker volume prune -f
}' # Removes unused Docker volumes

alias dip='() {
  echo "Shows IP address of a Docker container.\nUsage:\n dip <container_id or container_name>"
  if [ $# -eq 0 ]; then
    echo "Error: Please specify the container ID or name"
    return 1
  fi

  network_settings=$(docker inspect --format="{{json .NetworkSettings.Networks}}" "$1")
  if [ -z "$network_settings" ]; then
    echo "Error: Could not retrieve network information for container $1"
    return 1
  fi

  echo "IP addresses for container $1:"
  docker inspect --format="{{range \$key, \$value := .NetworkSettings.Networks}}{{printf \"\$key: %s\\n\" \$value.IPAddress}}{{end}}" "$1"
}' # Shows container IP address(es)

alias dbuild='() {
  echo "Builds a Docker image.\nUsage:\n dbuild <path_to_dockerfile> <image_name>:<tag> [--no-cache]"
  if [ $# -lt 2 ]; then
    echo "Error: Please specify the Dockerfile path and image name"
    echo "Example: dbuild ./Dockerfile myapp:latest"
    return 1
  fi

  dockerfile_path="$1"
  image_name="$2"
  no_cache=""

  if [ "$3" = "--no-cache" ]; then
    no_cache="--no-cache"
  fi

  if [ ! -f "$dockerfile_path" ]; then
    echo "Error: Dockerfile not found at $dockerfile_path"
    return 1
  fi

  echo "Building Docker image $image_name from $dockerfile_path..."
  docker build $no_cache -t "$image_name" -f "$dockerfile_path" "$(dirname "$dockerfile_path")"
}' # Builds a Docker image

alias dtag='() {
  echo "Tags a Docker image.\nUsage:\n dtag <source_image>:<source_tag> <target_image>:<target_tag>"
  if [ $# -ne 2 ]; then
    echo "Error: Please provide the source and target image names with tags"
    echo "Example: dtag myapp:latest docker.io/username/myapp:1.0"
    return 1
  fi

  docker tag "$1" "$2"
  echo "Tagged $1 as $2"
}' # Tags a Docker image

alias dpush='() {
  echo "Pushes a Docker image to a registry.\nUsage:\n dpush <image_name>:<tag>"
  if [ $# -eq 0 ]; then
    echo "Error: Please specify the image name to push"
    return 1
  fi

  echo "Pushing image $1 to registry..."
  docker push "$1"
}' # Pushes a Docker image to registry

alias dtail='() {
  echo "Shows live logs from multiple containers.\nUsage:\n dtail <container1> [container2...]"
  if [ $# -eq 0 ]; then
    echo "Error: Please specify at least one container"
    return 1
  fi

  containers=()
  for container in "$@"; do
    containers+=("--name=$container")
  done

  if ! command -v docker-tail &> /dev/null; then
    if ! command -v multitail &> /dev/null; then
      echo "Error: This function requires either docker-tail or multitail"
      if [[ "$(uname)" == "Darwin" ]]; then
        echo "Try installing multitail with: brew install multitail"
      else
        echo "Try installing multitail with your package manager"
      fi
      return 1
    fi

    cmd_args=""
    for container in "$@"; do
      cmd_args="$cmd_args -l \"docker logs -f --tail=10 $container\" "
    done

    eval "multitail $cmd_args"
  else
    docker-tail "${containers[@]}"
  fi
}' # Shows live logs from multiple containers

alias dnetconnect='() {
  echo "Connects a container to a network.\nUsage:\n dnetconnect <container_id or container_name> <network_name>"
  if [ $# -ne 2 ]; then
    echo "Error: Please provide the container ID/name and network name"
    echo "Example: dnetconnect my_container my_network"
    return 1
  fi

  docker network connect "$2" "$1"
  echo "Connected container $1 to network $2"
}' # Connects a container to a network

alias dnetdisconnect='() {
  echo "Disconnects a container from a network.\nUsage:\n dnetdisconnect <container_id or container_name> <network_name>"
  if [ $# -ne 2 ]; then
    echo "Error: Please provide the container ID/name and network name"
    echo "Example: dnetdisconnect my_container my_network"
    return 1
  fi

  docker network disconnect "$2" "$1"
  echo "Disconnected container $1 from network $2"
}' # Disconnects a container from a network

alias dnetcreate='() {
  echo "Creates a Docker network.\nUsage:\n dnetcreate <network_name> [--driver=bridge]"
  if [ $# -eq 0 ]; then
    echo "Error: Please specify the network name to create"
    return 1
  fi

  network_name="$1"
  driver="bridge"

  if [[ "$2" == --driver=* ]]; then
    driver="${2#--driver=}"
  fi

  docker network create --driver "$driver" "$network_name"
  echo "Created network $network_name with driver $driver"
}' # Creates a Docker network

alias dcval='() {
  echo "Validates Docker Compose file.\nUsage:\n dcval [file_path=docker-compose.yml]"
  compose_cmd=$(__docker_compose_cmd)
  file_path="${1:-docker-compose.yml}"

  if [ ! -f "$file_path" ]; then
    echo "Error: Docker Compose file not found at $file_path"
    return 1
  fi

  $compose_cmd -f "$file_path" config
  if [ $? -eq 0 ]; then
    echo "Docker Compose file $file_path is valid"
  else
    echo "Docker Compose file $file_path contains errors"
    return 1
  fi
}' # Validates Docker Compose file

# Docker Help Function
alias dkr-help='() {
  echo "Docker Aliases Help"
  echo "=================="
  echo "Shows list of all available Docker aliases with descriptions.\nUsage:\n dkr-help [category]"

  # Define categories
  local categories=(
    "Container Management"
    "Image Management"
    "Container Operations"
    "Container Logs and Terminal"
    "File Transfer"
    "Forceful Operations"
    "Docker Compose Operations"
    "Performance Monitoring"
    "Network Management"
    "System Management"
    "Build Operations"
    "Cleanup Operations"
  )

  # Check if category was specified
  if [ $# -gt 0 ]; then
    case "$1" in
      "container")
        categories=("Container Management" "Container Operations" "Container Logs and Terminal")
        ;;
      "image")
        categories=("Image Management" "Build Operations")
        ;;
      "compose")
        categories=("Docker Compose Operations")
        ;;
      "network")
        categories=("Network Management")
        ;;
      "system")
        categories=("System Management" "Performance Monitoring" "Cleanup Operations")
        ;;
      "all")
        # Keep all categories
        ;;
      *)
        echo "Error: Unknown category: $1"
        echo "Available categories: container, image, compose, network, system, all"
        return 1
        ;;
    esac
  fi

  # Container Management aliases
  if [[ " ${categories[@]} " =~ " Container Management " ]]; then
    echo "\nContainer Management:"
    echo "  dps              - Lists all containers, with optional filter"
    echo "  watchdps         - Monitors container status in real-time, with adjustable refresh interval"
    echo "  dstart           - Starts stopped container(s)"
    echo "  dstop            - Stops specified container(s)"
    echo "  dstopall         - Stops all containers"
    echo "  drst             - Restarts specified container(s)"
    echo "  dren             - Renames a container"
    echo "  dhealth          - Shows health status of running containers"
  fi

  # Image Management aliases
  if [[ " ${categories[@]} " =~ " Image Management " ]]; then
    echo "\nImage Management:"
    echo "  dimages          - Lists all images, with optional filter"
    echo "  drmi             - Removes specified image(s)"
    echo "  dpl              - Pulls an image"
    echo "  dtag             - Tags a Docker image"
    echo "  dpush            - Pushes a Docker image to registry"
  fi

  # Container Operations aliases
  if [[ " ${categories[@]} " =~ " Container Operations " ]]; then
    echo "\nContainer Operations:"
    echo "  drm              - Removes specified container(s)"
    echo "  dsrm             - Stops and removes specified container(s)"
    echo "  drmq             - Forcefully removes all containers, with optional confirmation prompt"
  fi

  # Container Logs and Terminal aliases
  if [[ " ${categories[@]} " =~ " Container Logs and Terminal " ]]; then
    echo "\nContainer Logs and Terminal:"
    echo "  dlogs            - Shows container logs, defaults to last 300 lines"
    echo "  dtail            - Shows live logs from multiple containers"
    echo "  dbash            - Enters container terminal, tries bash, then sh"
    echo "  dexec            - Executes a command in a container"
  fi

  # File Transfer aliases
  if [[ " ${categories[@]} " =~ " File Transfer " ]]; then
    echo "\nFile Transfer:"
    echo "  dcp              - Copies file to container"
    echo "  dcpl             - Copies file from container"
  fi

  # Network Management aliases
  if [[ " ${categories[@]} " =~ " Network Management " ]]; then
    echo "\nNetwork Management:"
    echo "  dnet             - Lists all networks, with optional filter"
    echo "  dnetconnect      - Connects a container to a network"
    echo "  dnetdisconnect   - Disconnects a container from a network"
    echo "  dnetcreate       - Creates a Docker network"
    echo "  dip              - Shows container IP address(es)"
  fi

  # Docker Compose Operations aliases
  if [[ " ${categories[@]} " =~ " Docker Compose Operations " ]]; then
    echo "\nDocker Compose Operations:"
    echo "  dcupd            - Starts containers using Docker Compose"
    echo "  dcdown           - Stops containers using Docker Compose"
    echo "  dcrestart        - Restarts containers using Docker Compose"
    echo "  dcsrm            - Stops and removes containers using Docker Compose"
    echo "  dcps             - Displays Docker Compose container status"
    echo "  dclogs           - Displays Docker Compose container logs"
    echo "  dcbash           - Enters Docker Compose container terminal"
    echo "  dce              - Executes a command in a Docker Compose container"
    echo "  dcr              - Runs a command using Docker Compose"
    echo "  dcpse            - Pauses Docker Compose service(s)"
    echo "  dcupse           - Unpauses Docker Compose service(s)"
    echo "  dcstop           - Stops Docker Compose service(s)"
    echo "  dctop            - Displays Docker Compose container resource usage"
    echo "  dcval            - Validates Docker Compose file"
  fi

  # Performance Monitoring aliases
  if [[ " ${categories[@]} " =~ " Performance Monitoring " ]]; then
    echo "\nPerformance Monitoring:"
    echo "  dstat            - Displays container resource usage, with optional container name filter"
  fi

  # System Management aliases
  if [[ " ${categories[@]} " =~ " System Management " ]]; then
    echo "\nSystem Management:"
    echo "  dsystem          - Displays Docker system information"
    echo "  dinspect         - Inspects Docker resource details"
    echo "  dvol             - Lists Docker volumes with optional filter"
  fi

  # Build Operations aliases
  if [[ " ${categories[@]} " =~ " Build Operations " ]]; then
    echo "\nBuild Operations:"
    echo "  dbuild           - Builds a Docker image"
    echo "  dbuildx          - Docker BuildX helper"
    echo "  dlint            - Lints Dockerfile using hadolint"
  fi

  # Cleanup Operations aliases
  if [[ " ${categories[@]} " =~ " Cleanup Operations " ]]; then
    echo "\nCleanup Operations:"
    echo "  dprune           - Cleans up unused Docker resources"
    echo "  dclean-img       - Removes unused Docker images"
    echo "  dclean-vol       - Removes unused Docker volumes"
  fi
}' # Shows all available Docker aliases with their descriptions
