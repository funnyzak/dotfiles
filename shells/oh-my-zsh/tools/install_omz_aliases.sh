#!/usr/bin/env bash

# Set strict error handling
set -e
set -o pipefail

# Define colors for output
# Check if terminal supports colors
if [ -t 1 ]; then
  RED="\033[0;31m"
  GREEN="\033[0;32m"
  YELLOW="\033[0;33m"
  BLUE="\033[0;34m"
  RESET="\033[0m"
else
  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  RESET=""
fi

# Check for required commands
check_command() {
  command -v "$1" >/dev/null 2>&1
}

# Check for curl or wget
if check_command curl; then
  DOWNLOAD_CMD="curl -sSL"
  DOWNLOAD_OUT="-o"
elif check_command wget; then
  DOWNLOAD_CMD="wget -q"
  DOWNLOAD_OUT="-O"
else
  echo "Error: Neither curl nor wget found. Please install one of them and try again." >&2
  exit 1
fi

# Display usage information
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] [ALIAS_FILES...]

Install oh-my-zsh alias files from a remote repository (Linux/macOS).
This script downloads specified alias files or a default list of alias files
from a remote repository to the specified directory.

Examples:
  # Local execution examples:
  $(basename "$0") git_aliases.zsh help_aliases.zsh         # Download specific alias files
  $(basename "$0") --url https://example.com/aliases/       # Use custom repository URL
  $(basename "$0") --default-list "git_aliases.zsh,help_aliases.zsh"  # Set custom default list

  # Remote execution examples:
  curl -fsSL https://raw.githubusercontent.com/funnyzak/dotfiles/refs/heads/main/shells/oh-my-zsh/tools/install_omz_aliases.sh | bash -s -- --force
  curl -fsSL https://raw.githubusercontent.com/funnyzak/dotfiles/refs/heads/main/shells/oh-my-zsh/tools/install_omz_aliases.sh | bash -s -- --url https://example.com/aliases/ git_aliases.zsh

Options:
  -h, --help                   Show this help message
  -d, --directory DIR          Specify download directory (default: \$ZSH/custom/aliases/)
  -n, --no-overwrite           Don't overwrite existing files
  -v, --verbose                Enable verbose output
  -f, --force                  Force download even if directory doesn't exist
  -u, --url URL                Custom repository base URL (default: https://raw.githubusercontent.com/funnyzak/dotfiles/refs/heads/main/shells/oh-my-zsh/custom/aliases/)
  -s, --default-list LIST      Custom default alias list (comma-separated, default: all available files)
                               Example: "git_aliases.zsh,help_aliases.zsh"

If no alias files are specified, default list will be downloaded.
EOF
  exit "${1:-0}"
}

# Detect the operating system type
detect_os() {
  local os_name
  if [ "$(uname)" = "Darwin" ]; then
    os_name="macOS"
  elif [ "$(uname)" = "Linux" ]; then
    os_name="Linux"
  else
    os_name="Unknown"
  fi
  echo "$os_name"
}

# Initialize system-related variables
OS_TYPE=$(detect_os)
if [[ "$verbose" == "true" ]]; then
  echo -e "${BLUE}Detected operating system: ${OS_TYPE}${RESET}"
fi

# Download a single alias file
download_alias() {
  local file="$1"
  local url="${remote_base_url}${file}"
  local dest="${download_dir}/${file}"

  if [[ -f "$dest" && "$overwrite" == "false" ]]; then
    echo -e "${YELLOW}Skipping ${file} (already exists)${RESET}"
    return 0
  fi

  # Simplify log output to avoid duplicate information
  if [[ "$verbose" == "true" ]]; then
    echo -e "${BLUE}Downloading ${file} from ${url} to ${dest}${RESET}"
  else
    echo -e "${BLUE}Downloading ${file}${RESET}"
  fi

  if $DOWNLOAD_CMD "$url" $DOWNLOAD_OUT "$dest"; then
    echo -e "${GREEN}Successfully downloaded ${file}${RESET}"
    return 0
  else
    echo -e "${RED}Failed to download ${file}${RESET}" >&2
    ((download_errors++))
    return 1
  fi
}

# Parse comma-separated list into array - POSIX compatible version
parse_comma_list() {
  local list="$1"
  local IFS=','
  local item
  local result=()

  # More compatible method, suitable for different shell versions on macOS and Linux
  for item in $list; do
    # Remove any spaces that may exist
    item="${item## }"
    item="${item%% }"
    [ -n "$item" ] && result+=("$item")
  done

  # Return array elements
  printf "%s\n" "${result[@]}"
}

detect_best_url() {
  local timeout=3
  local urls=("$@")

  for url in "${urls[@]}"; do
    if curl -s --connect-timeout "$timeout" "$url" >/dev/null 2>&1; then
      echo "$url"
      return
    fi
  done
}

# Default settings
download_dir="${ZSH:-$HOME/.oh-my-zsh}/custom/aliases"
overwrite="true"
verbose="false"
force="false"
download_errors=0  # Initialize download error counter

# Define the base URL for the remote aliases files
remote_base_url="https://raw.githubusercontent.com/funnyzak/dotfiles/refs/heads/${REPO_BRANCH:-main}/shells/oh-my-zsh/custom/aliases/"
remote_base_url_cn="https://gitee.com/funnyzak/dotfiles/raw/${REPO_BRANCH:-main}/shells/oh-my-zsh/custom/aliases/"

remote_base_url=$(detect_best_url "$remote_base_url_cn" "$remote_base_url")
# Use China-specific URL if CN=true
if [ "$CN" = "true" ]; then
  remote_base_url="$remote_base_url_cn"
fi

default_alias_files="archive_aliases.zsh,audio_aliases.zsh,base_aliases.zsh,bria_aliases.zsh,directory_aliases.zsh,docker_aliases.zsh,docker_app_aliases.zsh,filesystem_aliases.zsh,git_aliases.zsh,help_aliases.zsh,image_aliases.zsh,ip_aliases.zsh,minio_aliases.zsh,network_aliases.zsh,notification_aliases.zsh,other_aliases.zsh,srv_aliases.zsh,ssh_aliases.zsh,ssh_server_aliases.zsh,ssl_aliases.zsh,system_aliases.zsh,tcpdump_aliases.zsh,url_aliases.zsh,video_aliases.zsh,vps_aliases.zsh,web_aliases.zsh,zsh_config_aliases.zsh,environment_aliases.zsh,calc_aliases.zsh,log_aliases.zsh,mysql_aliases.zsh,group_aliases.zsh,download_aliases.zsh,upload_aliases.zsh,domain_aliases.zsh,claudecode_aliases.zsh"

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      ;;
    -d|--directory)
      download_dir="$2"
      shift 2
      ;;
    -n|--no-overwrite)
      overwrite="false"
      shift
      ;;
    -v|--verbose)
      verbose="true"
      shift
      ;;
    -f|--force)
      force="true"
      shift
      ;;
    -u|--url)
      remote_base_url="$2"
      shift 2
      ;;
    -s|--default-list)
      default_alias_files="$2"
      shift 2
      ;;
    -*)
      echo -e "${RED}Unknown option: $1${RESET}" >&2
      usage 1
      ;;
    *)
      files_to_download=("$@")
      break
      ;;
  esac
done

# Check if download directory exists
if [[ ! -d "$download_dir" ]]; then
  if [[ "$force" == "true" ]]; then
    echo -e "${YELLOW}Creating directory: $download_dir${RESET}"
    mkdir -p "$download_dir"
  else
    echo -e "${RED}Error: Download directory does not exist: $download_dir${RESET}" >&2
    echo -e "${YELLOW}Use -f/--force to create it automatically${RESET}" >&2
    exit 1
  fi
fi

# Make sure the remote_base_url ends with a slash
if ! echo "$remote_base_url" | grep -q '/$'; then
  remote_base_url="${remote_base_url}/"
fi

if [[ ${#files_to_download[@]} -eq 0 ]]; then
  # Parse the default alias list - use a macOS compatible method
  files_to_download=()
  while IFS= read -r line; do
    files_to_download+=("$line")
  done < <(parse_comma_list "$default_alias_files")
fi

# Ensure the array is not empty
if [[ ${#files_to_download[@]} -eq 0 ]]; then
  echo -e "${RED}No files specified for download and default list is empty${RESET}" >&2
  exit 1
fi

# Download the files
echo -e "${BLUE}Downloading aliases to $download_dir${RESET}"
echo -e "${BLUE}Using remote URL: $remote_base_url${RESET}"
# List Alias files to be downloaded
echo -e "${BLUE}Files to download:${RESET}"
for file in "${files_to_download[@]}"; do
  echo -e "  ${YELLOW}${file}${RESET}"
done
echo -e "${BLUE}----------------------------------------${RESET}"
echo -e "${BLUE}Starting download...${RESET}"
# Loop through the files and download each one

successful_downloads=0
# Temporarily disable exit on error
set +e
for file in "${files_to_download[@]}"; do
  if download_alias "$file"; then
    ((successful_downloads++))
  fi
done
# Re-enable exit on error
set -e

# Display download summary
total_files=${#files_to_download[@]}
echo -e "\n${BLUE}Download Summary:${RESET}"
echo -e "  ${GREEN}Successful: $successful_downloads${RESET}"

if [[ $download_errors -gt 0 ]]; then
  echo -e "  ${RED}Failed: $download_errors${RESET}"
  echo -e "${YELLOW}Some files failed to download. Check your network connection or the URL is correct.${RESET}"
  exit_code=1
else
  echo -e "${GREEN}All files downloaded successfully!${RESET}"
  exit_code=0
fi

if [[ successful_downloads -eq 0 ]]; then
  echo -e "${RED}No files were downloaded successfully.${RESET}"
  exit_code=1
else
  echo -e "${GREEN}Successfully downloaded $successful_downloads out of $total_files files.${RESET}"
  echo -e "${GREEN}You can find them in: $download_dir${RESET}"
  echo -e "${GREEN}You can apply them by running: source ~/.zshrc${RESET}"
  exit_code=0
fi

exit $exit_code
