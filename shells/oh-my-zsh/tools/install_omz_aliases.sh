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

Download oh-my-zsh alias files from a remote repository.

Examples:
  # Local execution examples:
  $(basename "$0") --list                                   # List available alias files
  $(basename "$0") git_aliases.zsh help_aliases.zsh         # Download specific alias files
  $(basename "$0") --url https://example.com/aliases/       # Use custom repository URL
  $(basename "$0") --default-list "git_aliases.zsh,help_aliases.zsh"  # Set custom default list

  # Remote execution examples:
  curl -fsSL https://cdn.jsdelivr.net/gh/funnyzak/dotfiles@main/shells/oh-my-zsh/tools/install_omz_aliases.sh | bash -s -- --force
  curl -fsSL https://cdn.jsdelivr.net/gh/funnyzak/dotfiles@main/shells/oh-my-zsh/tools/install_omz_aliases.sh | bash -s -- --url https://example.com/aliases/ git_aliases.zsh

Options:
  -h, --help                   Show this help message
  -d, --directory DIR          Specify download directory (default: \$ZSH/custom/aliases/)
  -n, --no-overwrite           Don't overwrite existing files
  -l, --list                   List available alias files
  -v, --verbose                Enable verbose output
  -f, --force                  Force download even if directory doesn't exist
  -u, --url URL                Custom repository base URL (default: https://cdn.jsdelivr.net/gh/funnyzak/dotfiles@main/shells/oh-my-zsh/custom/aliases/)
  -s, --default-list LIST      Custom default alias list (comma-separated, default: all available files)
                               Example: "git_aliases.zsh,help_aliases.zsh"

If no alias files are specified, default list will be downloaded.
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
  if $DOWNLOAD_CMD "$url" $DOWNLOAD_OUT "$dest"; then
    echo -e "${GREEN}Successfully downloaded ${file}${RESET}"
  else
    echo -e "${RED}Failed to download ${file}${RESET}" >&2
    return 1
  fi
}

# Parse comma-separated list into array - POSIX compatible version
parse_comma_list() {
  local list="$1"
  local IFS=','
  local item
  local result=()

  # Read comma-separated list into array - POSIX compatible
  for item in $list; do
    result+=("$item")
  done

  # Print the array elements
  for item in "${result[@]}"; do
    echo "$item"
  done
}

# Default settings
download_dir="${ZSH:-$HOME/.oh-my-zsh}/custom/aliases"
overwrite="true"
verbose="false"
force="false"

# Define the base URL for the remote aliases files
remote_base_url="https://cdn.jsdelivr.net/gh/funnyzak/dotfiles@main/shells/oh-my-zsh/custom/aliases/"

# Define default alias files
default_alias_files="git_aliases.zsh,help_aliases.zsh"

# Full list of aliases files available
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

# Make sure the remote_base_url ends with a slash
if ! echo "$remote_base_url" | grep -q '/$'; then
  remote_base_url="${remote_base_url}/"
fi

# If no specific files were provided, use default list
if [[ ${#files_to_download[@]} -eq 0 ]]; then
  # Parse the default list - POSIX compatible approach
  default_files=()
  while read -r line; do
    default_files+=("$line")
  done < <(parse_comma_list "$default_alias_files")

  # Validate default files
  valid_defaults=()
  for file in "${default_files[@]}"; do
    is_valid=0
    for valid_file in "${alias_files[@]}"; do
      if [[ "$file" == "$valid_file" ]]; then
        is_valid=1
        break
      fi
    done

    if [[ $is_valid -eq 1 ]]; then
      valid_defaults+=("$file")
    else
      echo -e "${YELLOW}Warning: Skipping unknown default alias file: $file${RESET}" >&2
    fi
  done

  if [[ ${#valid_defaults[@]} -eq 0 ]]; then
    echo -e "${YELLOW}No valid default files found, using all available files${RESET}"
    files_to_download=("${alias_files[@]}")
  else
    files_to_download=("${valid_defaults[@]}")
  fi
else
  # Validate that specified files exist in the available list
  valid_files=()
  for file in "${files_to_download[@]}"; do
    is_valid=0
    for valid_file in "${alias_files[@]}"; do
      if [[ "$file" == "$valid_file" ]]; then
        is_valid=1
        break
      fi
    done

    if [[ $is_valid -eq 1 ]]; then
      valid_files+=("$file")
    else
      echo -e "${RED}Error: Unknown alias file: $file${RESET}" >&2
      echo -e "${YELLOW}Use --list to see available files${RESET}" >&2
    fi
  done

  if [[ ${#valid_files[@]} -eq 0 ]]; then
    echo -e "${RED}No valid files to download${RESET}" >&2
    exit 1
  fi

  files_to_download=("${valid_files[@]}")
fi

# Download the files
echo -e "${BLUE}Downloading aliases to $download_dir${RESET}"
echo -e "${BLUE}Using remote URL: $remote_base_url${RESET}"
for file in "${files_to_download[@]}"; do
  download_alias "$file"
done

echo -e "${GREEN}All done!${RESET}"
