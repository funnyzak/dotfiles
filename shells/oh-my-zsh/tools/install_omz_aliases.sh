#!/usr/bin/env bash

# Set strict error handling
set -e
set -o pipefail

# Define colors for output
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
RESET="\033[0m"

# Display usage information
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] [ALIAS_FILES...]

Download oh-my-zsh alias files from a remote repository.

Remote execution example:
  curl -fsSL https://cdn.jsdelivr.net/gh/funnyzak/dotfiles@main/shells/oh-my-zsh/tools/install_omz_aliases.sh | bash -s -- --force

Options:
  -h, --help              Show this help message
  -d, --directory DIR     Specify download directory (default: \$ZSH/custom/aliases/)
  -n, --no-overwrite      Don't overwrite existing files
  -l, --list              List available alias files
  -v, --verbose           Enable verbose output
  -f, --force             Force download even if directory doesn't exist

If no alias files are specified, all will be downloaded.
EOF
  exit "${1:-0}"
}

# List available alias files
list_aliases() {
  echo -e "${BLUE}Available alias files:${RESET}"
  for file in "${alias_files[@]}"; do
    echo "  - $file"
  done
  exit 0
}

# Download a single alias file
download_alias() {
  local file="$1"
  local url="${remote_base_url}${file}"
  local dest="${download_dir}/${file}"

  if [[ -f "$dest" && "$overwrite" == "false" ]]; then
    echo -e "${YELLOW}Skipping ${file} (already exists)${RESET}"
    return
  fi

  if [[ "$verbose" == "true" ]]; then
    echo -e "${BLUE}Downloading ${file} from ${url}${RESET}"
  else
    echo -e "${BLUE}Downloading ${file}${RESET}"
  fi

  echo -e "${YELLOW}Downloading ${file} from ${url} to ${dest}${RESET}"
  if curl -sSL "$url" -o "$dest"; then
    echo -e "${GREEN}Successfully downloaded ${file}${RESET}"
  else
    echo -e "${RED}Failed to download ${file}${RESET}" >&2
    return 1
  fi
}

# Default settings
download_dir="${ZSH:-$HOME/.oh-my-zsh}/custom/aliases"
overwrite="true"
verbose="false"
force="false"

# Define the base URL for the remote aliases files
remote_base_url="https://cdn.jsdelivr.net/gh/funnyzak/dotfiles@main/shells/oh-my-zsh/custom/aliases/"

# List of aliases files to download
alias_files=(
  "archive_aliases.zsh"
  "brew_aliases.zsh"
  "bria_aliases.zsh"
  "dependency_aliases.zsh"
  "directory_aliases.zsh"
  "docker_aliases.zsh"
  "filesystem_aliases.zsh"
  "git_aliases.zsh"
  "help_aliases.zsh"
  "image_aliases.zsh"
  "mc_aliases.zsh"
  "network_aliases.zsh"
  "notification_aliases.zsh"
  "pdf_aliases.zsh"
  "system_aliases.zsh"
  "tcpdump_aliases.zsh"
  "video_aliases.zsh"
  "zsh_config_aliases.zsh"
)

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
    -l|--list)
      list_aliases
      ;;
    -v|--verbose)
      verbose="true"
      shift
      ;;
    -f|--force)
      force="true"
      shift
      ;;
    -*)
      echo -e "${RED}Unknown option: $1${RESET}" >&2
      usage 1
      ;;
    *)
      # Collect specified alias files
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

# If no specific files were provided, download all
if [[ ${#files_to_download[@]} -eq 0 ]]; then
  files_to_download=("${alias_files[@]}")
else
  # Validate that specified files exist in the available list
  for file in "${files_to_download[@]}"; do
    if ! printf '%s\n' "${alias_files[@]}" | grep -q "^${file}$"; then
      echo -e "${RED}Error: Unknown alias file: $file${RESET}" >&2
      echo -e "${YELLOW}Use --list to see available files${RESET}" >&2
      exit 1
    fi
  done
fi

# Download the files
echo -e "${BLUE}Downloading aliases to $download_dir${RESET}"
for file in "${files_to_download[@]}"; do
  download_alias "$file"
done

echo -e "${GREEN}All done!${RESET}"
