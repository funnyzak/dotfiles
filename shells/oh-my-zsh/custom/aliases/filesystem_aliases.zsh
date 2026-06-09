# Description: File system related aliases for file operations, searching, manipulation, and management.

# Helper functions for common filesystem alias operations
_filesystem_aliases_require_args() {
  local usage_text="$1"
  shift

  if [ $# -eq 0 ]; then
    echo -e "$usage_text" >&2
    return 1
  fi

  return 0
}

_filesystem_aliases_require_directory() {
  local target_directory="$1"

  if [ ! -d "$target_directory" ]; then
    echo "Error: Directory \"$target_directory\" does not exist." >&2
    echo "Check the directory path and try again." >&2
    return 1
  fi

  return 0
}

_filesystem_aliases_require_path() {
  local target_path="$1"

  if [ ! -e "$target_path" ]; then
    echo "Error: Path \"$target_path\" does not exist." >&2
    echo "Check the file or directory path and try again." >&2
    return 1
  fi

  return 0
}

_filesystem_aliases_is_positive_integer() {
  local number_value="$1"

  case "$number_value" in
    ""|*[!0-9]*)
      return 1
      ;;
    *)
      [ "$number_value" -gt 0 ]
      ;;
  esac
}

_filesystem_aliases_normalize_extension() {
  local extension_value="$1"

  extension_value="${extension_value#.}"
  if [ -z "$extension_value" ]; then
    echo "Error: Extension must not be empty." >&2
    return 1
  fi

  echo "$extension_value"
}

_filesystem_aliases_confirm() {
  local prompt_text="$1"
  local confirm_value

  echo "$prompt_text"
  read -r confirm_value

  [ "$confirm_value" = "y" ] || [ "$confirm_value" = "Y" ] || [ "$confirm_value" = "yes" ] || [ "$confirm_value" = "YES" ]
}

_filesystem_aliases_find_files_by_extension() {
  local target_directory="$1"
  local extension_value="$2"

  if [ "$extension_value" = "*" ]; then
    find "$target_directory" -type f
  else
    find "$target_directory" -type f -name "*.$extension_value"
  fi
}

_filesystem_aliases_run_path_action() {
  local action_name="$1"
  local target_path="$2"

  case "$action_name" in
    echo)
      echo "$target_path"
      ;;
    ls)
      ls "$target_path"
      ;;
    ls-lh|"ls -lh")
      ls -lh "$target_path"
      ;;
    rm-i|"rm -i")
      rm -i "$target_path"
      ;;
    *)
      echo "Error: Unsupported action \"$action_name\". Use echo, ls, ls-lh, or rm-i." >&2
      return 1
      ;;
  esac
}

_filesystem_aliases_escape_sed_pattern() {
  printf "%s" "$1" | sed "s/[][\\.^\$*|]/\\\\&/g"
}

_filesystem_aliases_escape_sed_replacement() {
  printf "%s" "$1" | sed "s/[\\&|]/\\\\&/g"
}

_filesystem_aliases_create_parent_directory() {
  local target_path="$1"
  local parent_directory

  parent_directory=$(dirname "$target_path")
  if [ ! -d "$parent_directory" ] && ! mkdir -p "$parent_directory"; then
    echo "Error: Failed to create parent directory \"$parent_directory\"." >&2
    return 1
  fi

  return 0
}

_filesystem_aliases_create_file() {
  local target_directory="$1"
  local file_name="$2"
  local content_text="$3"
  local executable_flag="${4:-false}"
  local target_path="${target_directory}/${file_name}"

  if [ ! -d "$target_directory" ] && ! mkdir -p "$target_directory"; then
    echo "Error: Failed to create directory \"$target_directory\"." >&2
    return 1
  fi

  if [ -n "$content_text" ]; then
    if ! printf "%b" "$content_text" > "$target_path"; then
      echo "Error: Failed to write file \"$target_path\"." >&2
      return 1
    fi
  else
    if ! touch "$target_path"; then
      echo "Error: Failed to create file \"$target_path\"." >&2
      return 1
    fi
  fi

  if [ "$executable_flag" = "true" ] && ! chmod +x "$target_path"; then
    echo "Error: Failed to make file executable \"$target_path\"." >&2
    return 1
  fi

  echo "Created file \"$target_path\""
}

_filesystem_aliases_count_lines_in_files() {
  local target_directory="$1"
  local extension_value="$2"
  local line_count
  local file_count

  if [ "$extension_value" = "*" ]; then
    line_count=$(find "$target_directory" -type f -not -path "*/\.*" -exec wc -l {} + 2>/dev/null | awk "{sum+=\$1} END {print sum+0}")
    file_count=$(find "$target_directory" -type f -not -path "*/\.*" | wc -l | tr -d " ")
  else
    line_count=$(find "$target_directory" -type f -name "*.$extension_value" -not -path "*/\.*" -exec wc -l {} + 2>/dev/null | awk "{sum+=\$1} END {print sum+0}")
    file_count=$(find "$target_directory" -type f -name "*.$extension_value" -not -path "*/\.*" | wc -l | tr -d " ")
  fi

  echo "${line_count:-0} ${file_count:-0}"
}

_filesystem_aliases_extension_matches() {
  local target_path="$1"
  local extensions_value="$2"
  local base_name="${target_path##*/}"
  local file_extension
  local normalized_extensions

  if [ -z "$extensions_value" ] || [ "$extensions_value" = "*" ]; then
    return 0
  fi

  if [ "$base_name" = "${base_name%.*}" ]; then
    return 1
  fi

  file_extension="${base_name##*.}"
  normalized_extensions=$(printf "%s" "$extensions_value" | tr -d " .")

  case ",$normalized_extensions," in
    *",$file_extension,"*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Basic file operations
alias rmi='() {
  if ! _filesystem_aliases_require_args "Remove files interactively.\nUsage:\n rmi <path> [...]" "$@"; then
    return 1
  fi

  rm -i "$@"
}' # Interactive removal - prompts before deleting files

alias rmdir='() {
  local target_directory="$1"

  if [ -z "$target_directory" ]; then
    echo -e "Remove an empty directory.\nUsage:\n rmdir <directory_path>" >&2
    return 1
  fi

  if [ $# -gt 1 ]; then
    echo "Error: rmdir accepts only one directory path." >&2
    return 1
  fi

  if ! _filesystem_aliases_require_directory "$target_directory"; then
    return 1
  fi

  if ! command rmdir "$target_directory"; then
    echo "Error: Failed to remove empty directory \"$target_directory\"." >&2
    echo "Use fs-rd for confirmed recursive removal." >&2
    return 1
  fi

  echo "Directory \"$target_directory\" has been removed successfully."
}' # Remove an empty directory

alias fs-rd='() {
  local target_directory="$1"

  if [ -z "$target_directory" ]; then
    echo -e "Remove a directory recursively after confirmation.\nUsage:\n fs-rd <directory_path>" >&2
    return 1
  fi

  if [ $# -gt 1 ]; then
    echo "Error: fs-rd accepts only one directory path." >&2
    return 1
  fi

  if ! _filesystem_aliases_require_directory "$target_directory"; then
    return 1
  fi

  if ! _filesystem_aliases_confirm "Remove directory \"$target_directory\" recursively? (y/n)"; then
    echo "Operation cancelled."
    return 0
  fi

  if ! rm -rfv "$target_directory"; then
    echo "Error: Failed to remove directory \"$target_directory\"." >&2
    return 1
  fi

  echo "Directory \"$target_directory\" has been removed successfully."
}' # Remove directory recursively after confirmation

alias fs-bak='() {
  local source_path="$1"
  local backup_name="$2"
  local timestamp_value
  local backup_path

  if ! _filesystem_aliases_require_args "Backup file or directory with timestamp.\nUsage:\n fs-bak <file_or_directory> [backup_name]" "$@"; then
    return 1
  fi

  if ! _filesystem_aliases_require_path "$source_path"; then
    return 1
  fi

  timestamp_value=$(date +%Y%m%d%H%M%S)
  backup_path="${backup_name:-${source_path}_${timestamp_value}}"

  if [ -e "$backup_path" ]; then
    echo "Error: Backup target \"$backup_path\" already exists." >&2
    return 1
  fi

  echo "Creating backup of \"$source_path\"..."
  if ! cp -R "$source_path" "$backup_path"; then
    echo "Error: Failed to create backup of \"$source_path\"." >&2
    return 1
  fi

  echo "Backup completed, exported to \"$backup_path\"."
}' # Create a timestamped backup of file or directory

# File search by size
alias fs-big='() {
  local size_value="10"
  local target_directory="."

  while [ $# -gt 0 ]; do
    case "$1" in
      -s|--size)
        if [ -z "$2" ]; then
          echo "Error: Missing value for $1." >&2
          return 1
        fi
        size_value="$2"
        shift 2
        ;;
      -d|--directory)
        if [ -z "$2" ]; then
          echo "Error: Missing value for $1." >&2
          return 1
        fi
        target_directory="$2"
        shift 2
        ;;
      -h|--help)
        echo -e "Find large files.\nUsage:\n fs-big [--size MB:10] [--directory path:.]"
        return 0
        ;;
      *)
        echo "Error: Unknown option \"$1\"." >&2
        return 1
        ;;
    esac
  done

  if ! _filesystem_aliases_is_positive_integer "$size_value"; then
    echo "Error: Size must be a positive integer in MB." >&2
    return 1
  fi

  if ! _filesystem_aliases_require_directory "$target_directory"; then
    return 1
  fi

  echo "Finding files larger than ${size_value}MB in \"$target_directory\"..."
  find "$target_directory" -type f -size +"${size_value}"M -exec ls -lh {} \; | sort -k 5 -h -r
  echo ""
  echo "Found $(find "$target_directory" -type f -size +"${size_value}"M | wc -l | tr -d " ") files larger than ${size_value}MB in \"$target_directory\"."
}' # Find files larger than specified size in MB

alias fs-small='() {
  local size_value="1"
  local target_directory="."

  while [ $# -gt 0 ]; do
    case "$1" in
      -s|--size)
        if [ -z "$2" ]; then
          echo "Error: Missing value for $1." >&2
          return 1
        fi
        size_value="$2"
        shift 2
        ;;
      -d|--directory)
        if [ -z "$2" ]; then
          echo "Error: Missing value for $1." >&2
          return 1
        fi
        target_directory="$2"
        shift 2
        ;;
      -h|--help)
        echo -e "Find small files.\nUsage:\n fs-small [--size MB:1] [--directory path:.]"
        return 0
        ;;
      *)
        echo "Error: Unknown option \"$1\"." >&2
        return 1
        ;;
    esac
  done

  if ! _filesystem_aliases_is_positive_integer "$size_value"; then
    echo "Error: Size must be a positive integer in MB." >&2
    return 1
  fi

  if ! _filesystem_aliases_require_directory "$target_directory"; then
    return 1
  fi

  echo "Finding files smaller than ${size_value}MB in \"$target_directory\"..."
  find "$target_directory" -type f -size -"${size_value}"M -exec ls -lh {} \; | sort -k 5 -h
  echo ""
  echo "Found $(find "$target_directory" -type f -size -"${size_value}"M | wc -l | tr -d " ") files smaller than ${size_value}MB in \"$target_directory\"."
}' # Find files smaller than specified size in MB

# File and directory counting
alias fs-cf='() {
  local target_directory="${1:-.}"

  if ! _filesystem_aliases_require_directory "$target_directory"; then
    return 1
  fi

  echo "Number of files in \"$target_directory\": $(find "$target_directory" -mindepth 1 -maxdepth 1 -type f | wc -l | tr -d " ")"
}' # Count files in directory

alias fs-cd='() {
  local target_directory="${1:-.}"

  if ! _filesystem_aliases_require_directory "$target_directory"; then
    return 1
  fi

  echo "Number of directories in \"$target_directory\": $(find "$target_directory" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d " ")"
}' # Count directories in directory

alias fs-ca='() {
  local target_directory="${1:-.}"

  if ! _filesystem_aliases_require_directory "$target_directory"; then
    return 1
  fi

  echo "Total number of files and directories in \"$target_directory\": $(find "$target_directory" -mindepth 1 -maxdepth 1 | wc -l | tr -d " ")"
}' # Count all files and directories

alias fs-caf='() {
  local target_directory="${1:-.}"
  local extension_value="${2:-*}"

  if [ $# -gt 2 ]; then
    echo -e "Count all files in directory and subdirectories.\nUsage:\n fs-caf [directory_path:.] [extension:*]" >&2
    return 1
  fi

  extension_value=$(_filesystem_aliases_normalize_extension "$extension_value") || return 1

  if ! _filesystem_aliases_require_directory "$target_directory"; then
    return 1
  fi

  echo "Total number of files with extension \"$extension_value\" in \"$target_directory\" and subdirectories: $(_filesystem_aliases_find_files_by_extension "$target_directory" "$extension_value" | wc -l | tr -d " ")"
}' # Count all files including subdirectories

alias fs-cad='() {
  local target_directory="${1:-.}"

  if ! _filesystem_aliases_require_directory "$target_directory"; then
    return 1
  fi

  echo "Total number of directories in \"$target_directory\" and subdirectories: $(find "$target_directory" -type d | wc -l | tr -d " ")"
}' # Count all directories including subdirectories

# Text and file searching
alias fs-t='() {
  local search_keyword="$1"
  local target_directory="${2:-.}"
  local extension_value="${3:-*}"
  local match_count

  if ! _filesystem_aliases_require_args "Search for text in files.\nUsage:\n fs-t <keyword> [path:.] [extension:*]" "$@"; then
    return 1
  fi

  extension_value=$(_filesystem_aliases_normalize_extension "$extension_value") || return 1

  if ! _filesystem_aliases_require_directory "$target_directory"; then
    return 1
  fi

  echo "Searching for \"$search_keyword\" in \"$target_directory\"..."
  if [ "$extension_value" = "*" ]; then
    grep -RIn -- "$search_keyword" "$target_directory" || true
    match_count=$(grep -RIn -- "$search_keyword" "$target_directory" 2>/dev/null | wc -l | tr -d " ")
  else
    grep -RIn --include="*.$extension_value" -- "$search_keyword" "$target_directory" || true
    match_count=$(grep -RIn --include="*.$extension_value" -- "$search_keyword" "$target_directory" 2>/dev/null | wc -l | tr -d " ")
  fi

  echo ""
  echo "Search results: Found ${match_count:-0} matches."
}' # Search for text in files

alias fs-size='() {
  local search_size="$1"
  local target_directory="${2:-.}"
  local extension_value="${3:-*}"
  local action_name="${4:-echo}"
  local match_count
  local current_path

  if ! _filesystem_aliases_require_args "Search for files by size.\nUsage:\n fs-size <size_with_unit> [path:.] [extension:*] [action:echo|ls|ls-lh|rm-i]\nExample:\n fs-size +10M . pdf ls-lh" "$@"; then
    return 1
  fi

  extension_value=$(_filesystem_aliases_normalize_extension "$extension_value") || return 1

  if ! _filesystem_aliases_require_directory "$target_directory"; then
    return 1
  fi

  echo "Finding files with size \"$search_size\" and extension \"$extension_value\" in \"$target_directory\"..."
  match_count=$(_filesystem_aliases_find_files_by_extension "$target_directory" "$extension_value" | while IFS= read -r current_path; do find "$current_path" -prune -type f -size "$search_size" -print; done | wc -l | tr -d " ")

  while IFS= read -r current_path; do
    if [ -n "$current_path" ] && [ -f "$current_path" ]; then
      _filesystem_aliases_run_path_action "$action_name" "$current_path" || return 1
    fi
  done < <(_filesystem_aliases_find_files_by_extension "$target_directory" "$extension_value" | while IFS= read -r current_path; do find "$current_path" -prune -type f -size "$search_size" -print; done)

  echo ""
  echo "Found ${match_count:-0} matching files."
}' # Search for files by size

alias fs-f='() {
  local search_keyword="$1"
  local target_directory="${2:-.}"
  local extension_value="${3:-*}"
  local action_name="${4:-echo}"
  local match_count
  local current_path

  if ! _filesystem_aliases_require_args "Search for files by name pattern.\nUsage:\n fs-f <keyword> [path:.] [extension:*] [action:echo|ls|ls-lh|rm-i]" "$@"; then
    return 1
  fi

  extension_value=$(_filesystem_aliases_normalize_extension "$extension_value") || return 1

  if ! _filesystem_aliases_require_directory "$target_directory"; then
    return 1
  fi

  echo "Finding files containing \"$search_keyword\" with extension \"$extension_value\" in \"$target_directory\"..."
  if [ "$extension_value" = "*" ]; then
    match_count=$(find "$target_directory" -type f -name "*$search_keyword*" | wc -l | tr -d " ")
    while IFS= read -r current_path; do
      _filesystem_aliases_run_path_action "$action_name" "$current_path" || return 1
    done < <(find "$target_directory" -type f -name "*$search_keyword*")
  else
    match_count=$(find "$target_directory" -type f -name "*$search_keyword*.$extension_value" | wc -l | tr -d " ")
    while IFS= read -r current_path; do
      _filesystem_aliases_run_path_action "$action_name" "$current_path" || return 1
    done < <(find "$target_directory" -type f -name "*$search_keyword*.$extension_value")
  fi

  echo ""
  echo "Found ${match_count:-0} matching files."
}' # Search for files by name pattern

alias fs-dir='() {
  local search_keyword="$1"
  local target_directory="${2:-.}"
  local action_name="${3:-echo}"
  local match_count
  local current_path

  if ! _filesystem_aliases_require_args "Search for directories by name pattern.\nUsage:\n fs-dir <keyword> [path:.] [action:echo|ls|ls-lh|rm-i]" "$@"; then
    return 1
  fi

  if ! _filesystem_aliases_require_directory "$target_directory"; then
    return 1
  fi

  echo "Finding directories containing \"$search_keyword\" in \"$target_directory\"..."
  match_count=$(find "$target_directory" -type d -name "*$search_keyword*" | wc -l | tr -d " ")
  while IFS= read -r current_path; do
    _filesystem_aliases_run_path_action "$action_name" "$current_path" || return 1
  done < <(find "$target_directory" -type d -name "*$search_keyword*")

  echo ""
  echo "Found ${match_count:-0} matching directories."
}' # Search for directories by name pattern

alias fs-dsize='() {
  local search_keyword="$1"
  local target_directory="${2:-.}"
  local total_size
  local directory_count

  if ! _filesystem_aliases_require_args "Calculate total size of directories matching name pattern.\nUsage:\n fs-dsize <keyword> [path:.]" "$@"; then
    return 1
  fi

  if ! _filesystem_aliases_require_directory "$target_directory"; then
    return 1
  fi

  directory_count=$(find "$target_directory" -type d -name "*$search_keyword*" | wc -l | tr -d " ")
  total_size=$(find "$target_directory" -type d -name "*$search_keyword*" -exec du -s {} \; 2>/dev/null | awk "{sum+=\$1} END {printf \"%dMB\", (sum+0)/1024}")
  echo "Total size of $directory_count directories with name pattern \"$search_keyword\": $total_size"
}' # Calculate total size of directories matching name pattern

# File deletion and management
alias fs-de='() {
  local target_directory="$1"
  local before_count
  local after_count

  if ! _filesystem_aliases_require_args "Delete empty directories.\nUsage:\n fs-de <directory_path>" "$@"; then
    return 1
  fi

  if ! _filesystem_aliases_require_directory "$target_directory"; then
    return 1
  fi

  before_count=$(find "$target_directory" -mindepth 1 -type d | wc -l | tr -d " ")
  if ! find "$target_directory" -mindepth 1 -type d -empty -delete; then
    echo "Error: Failed to delete empty directories in \"$target_directory\"." >&2
    return 1
  fi
  after_count=$(find "$target_directory" -mindepth 1 -type d | wc -l | tr -d " ")

  echo "Deleted $((before_count - after_count)) empty directories in \"$target_directory\"."
}' # Delete empty directories

alias fs-deln='() {
  local search_text="$1"
  local target_directory="${2:-.}"
  local match_count

  if ! _filesystem_aliases_require_args "Delete files containing specific string in filename.\nUsage:\n fs-deln <string> [directory:.]" "$@"; then
    return 1
  fi

  if [ -z "$search_text" ]; then
    echo "Error: Search string must not be empty." >&2
    return 1
  fi

  if ! _filesystem_aliases_require_directory "$target_directory"; then
    return 1
  fi

  match_count=$(find "$target_directory" -type f -iname "*$search_text*" | wc -l | tr -d " ")
  if [ "$match_count" -eq 0 ]; then
    echo "No files found containing \"$search_text\" in \"$target_directory\"."
    return 0
  fi

  if ! _filesystem_aliases_confirm "Found $match_count files. Proceed with deletion? (y/n)"; then
    echo "Operation cancelled."
    return 0
  fi

  if ! find "$target_directory" -type f -iname "*$search_text*" -delete; then
    echo "Error: Failed to delete matching files in \"$target_directory\"." >&2
    return 1
  fi

  echo "Deleted $match_count files containing \"$search_text\" in \"$target_directory\"."
}' # Delete files containing specific string in filename

alias fs-dele='() {
  local extension_value="$1"
  local target_directory="${2:-.}"
  local match_count

  if ! _filesystem_aliases_require_args "Delete files with specific extension.\nUsage:\n fs-dele <extension> [directory:.]" "$@"; then
    return 1
  fi

  extension_value=$(_filesystem_aliases_normalize_extension "$extension_value") || return 1

  if ! _filesystem_aliases_require_directory "$target_directory"; then
    return 1
  fi

  match_count=$(find "$target_directory" -type f -iname "*.$extension_value" | wc -l | tr -d " ")
  if [ "$match_count" -eq 0 ]; then
    echo "No files found with extension \"$extension_value\" in \"$target_directory\"."
    return 0
  fi

  if ! _filesystem_aliases_confirm "Found $match_count files. Proceed with deletion? (y/n)"; then
    echo "Operation cancelled."
    return 0
  fi

  if ! find "$target_directory" -type f -iname "*.$extension_value" -delete; then
    echo "Error: Failed to delete files with extension \"$extension_value\" in \"$target_directory\"." >&2
    return 1
  fi

  echo "Deleted $match_count files with extension \"$extension_value\" in \"$target_directory\"."
}' # Delete files with specific extension

alias fs-cnm='() {
  local search_directory="${1:-.}"
  local directory_count

  if ! _filesystem_aliases_require_directory "$search_directory"; then
    return 1
  fi

  directory_count=$(find "$search_directory" -type d -name "node_modules" -prune | wc -l | tr -d " ")
  if [ "$directory_count" -eq 0 ]; then
    echo "No node_modules directories found in \"$search_directory\"."
    return 0
  fi

  if ! _filesystem_aliases_confirm "Found $directory_count node_modules directories. Proceed with deletion? (y/n)"; then
    echo "Operation cancelled."
    return 0
  fi

  if ! find "$search_directory" -type d -name "node_modules" -prune -exec rm -rf {} +; then
    echo "Error: Some node_modules directories could not be deleted." >&2
    return 1
  fi

  echo "Successfully deleted $directory_count node_modules directories."
}' # Clean up node_modules directories recursively

alias fs-delage='() {
  local target_directory="$1"
  local minutes_value="$2"
  local extensions_value="$3"
  local candidate_list
  local current_path
  local file_count
  local deleted_count=0

  if [ -z "$target_directory" ] || [ -z "$minutes_value" ]; then
    echo -e "Delete files older than specified minutes in a directory.\nUsage:\n fs-delage <directory_path> <minutes_ago> [file_extensions]\nExamples:\n fs-delage /tmp 60\n fs-delage /logs 1440 \"log,txt,tmp\"" >&2
    return 1
  fi

  if ! _filesystem_aliases_require_directory "$target_directory"; then
    return 1
  fi

  if ! _filesystem_aliases_is_positive_integer "$minutes_value"; then
    echo "Error: minutes_ago must be a positive integer." >&2
    return 1
  fi

  candidate_list=$(mktemp) || {
    echo "Error: Failed to create temporary file." >&2
    return 1
  }

  while IFS= read -r current_path; do
    if _filesystem_aliases_extension_matches "$current_path" "$extensions_value"; then
      echo "$current_path" >> "$candidate_list"
    fi
  done < <(find "$target_directory" -type f -mmin +"$minutes_value" 2>/dev/null)

  file_count=$(wc -l < "$candidate_list" | tr -d " ")
  if [ "$file_count" -eq 0 ]; then
    echo "No files found matching the criteria."
    rm -f "$candidate_list"
    return 0
  fi

  echo "Found $file_count files matching the criteria:"
  head -10 "$candidate_list"
  if [ "$file_count" -gt 10 ]; then
    echo "... and $((file_count - 10)) more files"
  fi

  if ! _filesystem_aliases_confirm "Delete these $file_count files? (y/n)"; then
    echo "Operation cancelled."
    rm -f "$candidate_list"
    return 0
  fi

  while IFS= read -r current_path; do
    if [ -n "$current_path" ] && rm -f "$current_path"; then
      deleted_count=$((deleted_count + 1))
    else
      echo "Error: Failed to delete \"$current_path\"." >&2
    fi
  done < "$candidate_list"

  if [ "$deleted_count" -ne "$file_count" ]; then
    echo "Error: Deleted $deleted_count of $file_count files. Check permissions and try again." >&2
    rm -f "$candidate_list"
    return 1
  fi

  rm -f "$candidate_list"
  echo "Successfully deleted $deleted_count files."
}' # Delete files older than specified minutes with optional file type filtering

# Filename modification
alias fs-trimend='() {
  local trim_count="${1:-1}"
  local extension_value="${2:-*}"
  local target_directory="${3:-.}"
  local current_path
  local parent_directory
  local base_name
  local name_part
  local extension_part
  local new_name
  local new_path
  local renamed_count=0

  if ! _filesystem_aliases_is_positive_integer "$trim_count"; then
    echo "Error: num_chars must be a positive integer." >&2
    return 1
  fi

  extension_value=$(_filesystem_aliases_normalize_extension "$extension_value") || return 1
  if ! _filesystem_aliases_require_directory "$target_directory"; then
    return 1
  fi

  while IFS= read -r current_path; do
    parent_directory=$(dirname "$current_path")
    base_name=$(basename "$current_path")
    name_part="${base_name%.*}"
    extension_part="${base_name##*.}"

    if [ "$name_part" = "$base_name" ]; then
      extension_part=""
    fi

    if [ "${#name_part}" -le "$trim_count" ]; then
      echo "Warning: Skipping \"$current_path\" because filename is too short." >&2
      continue
    fi

    new_name="${name_part:0:${#name_part} - trim_count}"
    if [ -n "$extension_part" ]; then
      new_name="${new_name}.${extension_part}"
    fi
    new_path="${parent_directory}/${new_name}"

    if [ -e "$new_path" ]; then
      echo "Warning: Skipping \"$current_path\" because target \"$new_path\" already exists." >&2
      continue
    fi

    if mv "$current_path" "$new_path"; then
      echo "Renamed \"$current_path\" to \"$new_path\""
      renamed_count=$((renamed_count + 1))
    else
      echo "Error: Failed to rename \"$current_path\"." >&2
    fi
  done < <(_filesystem_aliases_find_files_by_extension "$target_directory" "$extension_value")

  echo "Successfully renamed $renamed_count files."
}' # Delete last n characters from filenames

alias fs-trimstart='() {
  local trim_count="${1:-1}"
  local extension_value="${2:-*}"
  local target_directory="${3:-.}"
  local current_path
  local parent_directory
  local base_name
  local name_part
  local extension_part
  local new_name
  local new_path
  local renamed_count=0

  if ! _filesystem_aliases_is_positive_integer "$trim_count"; then
    echo "Error: num_chars must be a positive integer." >&2
    return 1
  fi

  extension_value=$(_filesystem_aliases_normalize_extension "$extension_value") || return 1
  if ! _filesystem_aliases_require_directory "$target_directory"; then
    return 1
  fi

  while IFS= read -r current_path; do
    parent_directory=$(dirname "$current_path")
    base_name=$(basename "$current_path")
    name_part="${base_name%.*}"
    extension_part="${base_name##*.}"

    if [ "$name_part" = "$base_name" ]; then
      extension_part=""
    fi

    if [ "${#name_part}" -le "$trim_count" ]; then
      echo "Warning: Skipping \"$current_path\" because filename is too short." >&2
      continue
    fi

    new_name="${name_part:$trim_count}"
    if [ -n "$extension_part" ]; then
      new_name="${new_name}.${extension_part}"
    fi
    new_path="${parent_directory}/${new_name}"

    if [ -e "$new_path" ]; then
      echo "Warning: Skipping \"$current_path\" because target \"$new_path\" already exists." >&2
      continue
    fi

    if mv "$current_path" "$new_path"; then
      echo "Renamed \"$current_path\" to \"$new_path\""
      renamed_count=$((renamed_count + 1))
    else
      echo "Error: Failed to rename \"$current_path\"." >&2
    fi
  done < <(_filesystem_aliases_find_files_by_extension "$target_directory" "$extension_value")

  echo "Successfully renamed $renamed_count files."
}' # Delete first n characters from filenames

alias fs-pre='() {
  local prefix_text="$1"
  local extension_value="${2:-*}"
  local target_directory="${3:-.}"
  local current_path
  local new_path
  local renamed_count=0

  if ! _filesystem_aliases_require_args "Add prefix to filenames.\nUsage:\n fs-pre <prefix> [extension:*] [directory:.]" "$@"; then
    return 1
  fi

  extension_value=$(_filesystem_aliases_normalize_extension "$extension_value") || return 1
  if ! _filesystem_aliases_require_directory "$target_directory"; then
    return 1
  fi

  while IFS= read -r current_path; do
    new_path="$(dirname "$current_path")/${prefix_text}$(basename "$current_path")"
    if [ -e "$new_path" ]; then
      echo "Warning: Skipping \"$current_path\" because target \"$new_path\" already exists." >&2
      continue
    fi
    if mv "$current_path" "$new_path"; then
      echo "Renamed \"$current_path\" to \"$new_path\""
      renamed_count=$((renamed_count + 1))
    else
      echo "Error: Failed to rename \"$current_path\"." >&2
    fi
  done < <(_filesystem_aliases_find_files_by_extension "$target_directory" "$extension_value")

  echo "Successfully renamed $renamed_count files."
}' # Add prefix to filenames

alias fs-suf='() {
  local suffix_text="$1"
  local extension_value="${2:-*}"
  local target_directory="${3:-.}"
  local current_path
  local parent_directory
  local base_name
  local name_part
  local extension_part
  local new_path
  local renamed_count=0

  if ! _filesystem_aliases_require_args "Add suffix to filenames before extension.\nUsage:\n fs-suf <suffix> [extension:*] [directory:.]" "$@"; then
    return 1
  fi

  extension_value=$(_filesystem_aliases_normalize_extension "$extension_value") || return 1
  if ! _filesystem_aliases_require_directory "$target_directory"; then
    return 1
  fi

  while IFS= read -r current_path; do
    parent_directory=$(dirname "$current_path")
    base_name=$(basename "$current_path")
    name_part="${base_name%.*}"
    extension_part="${base_name##*.}"
    if [ "$name_part" = "$base_name" ]; then
      new_path="${parent_directory}/${base_name}${suffix_text}"
    else
      new_path="${parent_directory}/${name_part}${suffix_text}.${extension_part}"
    fi

    if [ -e "$new_path" ]; then
      echo "Warning: Skipping \"$current_path\" because target \"$new_path\" already exists." >&2
      continue
    fi
    if mv "$current_path" "$new_path"; then
      echo "Renamed \"$current_path\" to \"$new_path\""
      renamed_count=$((renamed_count + 1))
    else
      echo "Error: Failed to rename \"$current_path\"." >&2
    fi
  done < <(_filesystem_aliases_find_files_by_extension "$target_directory" "$extension_value")

  echo "Successfully renamed $renamed_count files."
}' # Add suffix to filenames before extension

alias fs-rname='() {
  local old_text="$1"
  local new_text="$2"
  local extension_value="${3:-*}"
  local target_directory="${4:-.}"
  local old_pattern
  local new_replacement
  local current_path
  local base_name
  local new_name
  local new_path
  local renamed_count=0

  if [ $# -lt 2 ]; then
    echo -e "Replace string in filenames.\nUsage:\n fs-rname <old_string> <new_string> [extension:*] [directory:.]" >&2
    return 1
  fi

  extension_value=$(_filesystem_aliases_normalize_extension "$extension_value") || return 1
  if ! _filesystem_aliases_require_directory "$target_directory"; then
    return 1
  fi

  old_pattern=$(_filesystem_aliases_escape_sed_pattern "$old_text")
  new_replacement=$(_filesystem_aliases_escape_sed_replacement "$new_text")

  while IFS= read -r current_path; do
    base_name=$(basename "$current_path")
    new_name=$(printf "%s" "$base_name" | sed "s|$old_pattern|$new_replacement|g")
    if [ "$base_name" = "$new_name" ]; then
      continue
    fi
    new_path="$(dirname "$current_path")/${new_name}"
    if [ -e "$new_path" ]; then
      echo "Warning: Skipping \"$current_path\" because target \"$new_path\" already exists." >&2
      continue
    fi
    if mv "$current_path" "$new_path"; then
      echo "Renamed \"$current_path\" to \"$new_path\""
      renamed_count=$((renamed_count + 1))
    else
      echo "Error: Failed to rename \"$current_path\"." >&2
    fi
  done < <(_filesystem_aliases_find_files_by_extension "$target_directory" "$extension_value")

  echo "Successfully renamed $renamed_count files."
}' # Replace string in filenames

# Content replacement
alias fs-rtext='() {
  local old_text="$1"
  local new_text="$2"
  local extension_value="${3:-*}"
  local target_directory="${4:-.}"
  local old_pattern
  local new_replacement
  local current_path
  local updated_count=0

  if [ $# -lt 2 ]; then
    echo -e "Replace string in file contents.\nUsage:\n fs-rtext <old_string> <new_string> [extension:*] [directory:.]" >&2
    return 1
  fi

  extension_value=$(_filesystem_aliases_normalize_extension "$extension_value") || return 1
  if ! _filesystem_aliases_require_directory "$target_directory"; then
    return 1
  fi

  old_pattern=$(_filesystem_aliases_escape_sed_pattern "$old_text")
  new_replacement=$(_filesystem_aliases_escape_sed_replacement "$new_text")

  while IFS= read -r current_path; do
    if grep -Fq -- "$old_text" "$current_path"; then
      if [ "$(uname)" = "Darwin" ]; then
        sed -i "" "s|$old_pattern|$new_replacement|g" "$current_path"
      else
        sed -i "s|$old_pattern|$new_replacement|g" "$current_path"
      fi

      if [ $? -eq 0 ]; then
        echo "Updated content in \"$current_path\""
        updated_count=$((updated_count + 1))
      else
        echo "Error: Failed to update content in \"$current_path\"." >&2
      fi
    fi
  done < <(_filesystem_aliases_find_files_by_extension "$target_directory" "$extension_value")

  echo "Successfully updated $updated_count files."
}' # Replace string in file contents

# File creation
alias fs-mkdummy='() {
  local size_value="${1:-10}"
  local output_path="${2:-$(pwd)/file_$(date +%Y%m%d%H%M%S)}"

  if ! _filesystem_aliases_is_positive_integer "$size_value"; then
    echo "Error: size_in_MB must be a positive integer." >&2
    return 1
  fi

  if ! _filesystem_aliases_create_parent_directory "$output_path"; then
    return 1
  fi

  echo "Creating a ${size_value}MB file at \"$output_path\"..."
  if ! dd if=/dev/zero of="$output_path" bs=1M count="$size_value" 2>/dev/null; then
    echo "Error: Failed to create file at \"$output_path\"." >&2
    return 1
  fi

  echo "File creation completed. Created a ${size_value}MB file at \"$output_path\"."
}' # Create a dummy file of specified size using dd

alias fs-mkmd='() {
  local target_directory="${1:-.}"
  _filesystem_aliases_create_file "$target_directory" "README.md" ""
}' # Create README.md file

alias fs-mktxt='() {
  local target_directory="${1:-.}"
  local file_name="${2:-README.txt}"
  _filesystem_aliases_create_file "$target_directory" "$file_name" ""
}' # Create text file

alias fs-mkpy='() {
  local target_directory="${1:-.}"
  local file_name="${2:-main.py}"
  _filesystem_aliases_create_file "$target_directory" "$file_name" ""
}' # Create Python file

alias fs-mksh='() {
  local target_directory="${1:-.}"
  local file_name="${2:-main.sh}"
  _filesystem_aliases_create_file "$target_directory" "$file_name" "#!/bin/bash\n\n" true
}' # Create Shell file with execute permission

alias fs-mkjs='() {
  local target_directory="${1:-.}"
  local file_name="${2:-main.js}"
  _filesystem_aliases_create_file "$target_directory" "$file_name" ""
}' # Create JavaScript file

alias fs-mkjson='() {
  local target_directory="${1:-.}"
  local file_name="${2:-main.json}"
  _filesystem_aliases_create_file "$target_directory" "$file_name" "{}\n"
}' # Create JSON file

alias fs-mkhtml='() {
  local target_directory="${1:-.}"
  local file_name="${2:-index.html}"
  local html_content="<!DOCTYPE html>\n<html>\n  <head>\n    <meta charset=\"UTF-8\">\n    <title>Document</title>\n  </head>\n  <body>\n  </body>\n</html>\n"

  _filesystem_aliases_create_file "$target_directory" "$file_name" "$html_content"
}' # Create HTML file with basic structure

alias fs-mkbatch='() {
  local file_prefix="$1"
  local file_suffix="$2"
  local file_count="${3:-1}"
  local target_directory="${4:-.}"
  local zero_padding="${5:-1}"
  local index_value
  local file_name
  local target_path
  local created_count=0

  if [ $# -lt 2 ]; then
    echo -e "Create batch files with numbered sequence.\nUsage:\n fs-mkbatch <prefix> <suffix> [count:1] [target_dir:.] [zero_padding:1]" >&2
    return 1
  fi

  if ! _filesystem_aliases_is_positive_integer "$file_count" || ! _filesystem_aliases_is_positive_integer "$zero_padding"; then
    echo "Error: count and zero_padding must be positive integers." >&2
    return 1
  fi

  if [ ! -d "$target_directory" ] && ! mkdir -p "$target_directory"; then
    echo "Error: Failed to create directory \"$target_directory\"." >&2
    return 1
  fi

  index_value=1
  while [ "$index_value" -le "$file_count" ]; do
    file_name="${file_prefix}$(printf "%0${zero_padding}d" "$index_value").${file_suffix#.}"
    target_path="${target_directory}/${file_name}"
    if touch "$target_path"; then
      echo "Created: \"$target_path\""
      created_count=$((created_count + 1))
    else
      echo "Error: Failed to create \"$target_path\"." >&2
    fi
    index_value=$((index_value + 1))
  done

  echo "Batch creation completed. Created $created_count of $file_count files in \"$target_directory\"."
}' # Create batch files with numbered sequence

alias fs-mirror='() {
  local new_extension="$1"
  local search_extension="${2:-*}"
  local source_directory="${3:-.}"
  local target_directory="${4:-$source_directory}"
  local current_path
  local base_name
  local name_part
  local target_path
  local created_count=0

  if ! _filesystem_aliases_require_args "Create files with new extension based on existing files.\nUsage:\n fs-mirror <new_extension> [search_extension:*] [source_dir:.] [target_dir:source_dir]" "$@"; then
    return 1
  fi

  new_extension=$(_filesystem_aliases_normalize_extension "$new_extension") || return 1
  search_extension=$(_filesystem_aliases_normalize_extension "$search_extension") || return 1

  if ! _filesystem_aliases_require_directory "$source_directory"; then
    return 1
  fi

  if [ ! -d "$target_directory" ] && ! mkdir -p "$target_directory"; then
    echo "Error: Failed to create target directory \"$target_directory\"." >&2
    return 1
  fi

  while IFS= read -r current_path; do
    base_name=$(basename "$current_path")
    name_part="${base_name%.*}"
    if [ "$name_part" = "$base_name" ]; then
      name_part="$base_name"
    fi
    target_path="${target_directory}/${name_part}.${new_extension}"
    if [ -e "$target_path" ]; then
      echo "Warning: Skipping \"$target_path\" because it already exists." >&2
      continue
    fi
    if touch "$target_path"; then
      echo "Created: \"$target_path\""
      created_count=$((created_count + 1))
    else
      echo "Error: Failed to create \"$target_path\"." >&2
    fi
  done < <(_filesystem_aliases_find_files_by_extension "$source_directory" "$search_extension")

  echo "Mirror operation completed. Created $created_count files with extension \"$new_extension\"."
}' # Create files with new extension based on existing files

# File copying
alias fs-cpext='() {
  local extension_value="$1"
  local target_directory="$2"
  local current_path
  local copied_count=0

  if [ $# -lt 2 ]; then
    echo -e "Copy files with specific extension from current directory to target directory.\nUsage:\n fs-cpext <extension> <target_directory>" >&2
    return 1
  fi

  extension_value=$(_filesystem_aliases_normalize_extension "$extension_value") || return 1

  if [ ! -d "$target_directory" ] && ! mkdir -p "$target_directory"; then
    echo "Error: Failed to create directory \"$target_directory\"." >&2
    return 1
  fi

  for current_path in ./*."$extension_value"; do
    if [ -f "$current_path" ]; then
      if cp "$current_path" "$target_directory/"; then
        copied_count=$((copied_count + 1))
      else
        echo "Error: Failed to copy \"$current_path\" to \"$target_directory/\"." >&2
      fi
    fi
  done

  echo "Copy completed. Copied $copied_count files with extension \"$extension_value\" to \"$target_directory/\"."
}' # Copy all files with specific extension to target directory

# Code line counting
alias fs-cl='() {
  local target_directory="${1:-$(pwd)}"
  local extension_value="${2:-*}"
  local line_count
  local file_count

  extension_value=$(_filesystem_aliases_normalize_extension "$extension_value") || return 1
  if ! _filesystem_aliases_require_directory "$target_directory"; then
    return 1
  fi

  read -r line_count file_count <<< "$(_filesystem_aliases_count_lines_in_files "$target_directory" "$extension_value")"
  echo "Total lines of code in $file_count files with extension \"$extension_value\" in \"$target_directory\": $line_count"
}' # Count total lines of code in files

# File system help function
alias fs-help='() {
  echo "File System Aliases Help"
  echo "========================"
  echo "Basic File Operations:"
  echo "  rmi                       - Interactive removal"
  echo "  rmdir                     - Remove an empty directory"
  echo "  fs-rd                       - Remove directory recursively with confirmation"
  echo "  fs-bak                      - Create a timestamped backup"
  echo ""
  echo "File Search:"
  echo "  fs-big                      - Find files larger than specified size in MB"
  echo "  fs-small                    - Find files smaller than specified size in MB"
  echo "  fs-t                        - Search for text in files"
  echo "  fs-size                     - Search for files by size"
  echo "  fs-f                        - Search for files by name pattern"
  echo "  fs-dir                      - Search for directories by name pattern"
  echo "  fs-dsize                    - Calculate total size of matching directories"
  echo ""
  echo "Counting:"
  echo "  fs-cf                       - Count files in directory"
  echo "  fs-cd                       - Count directories in directory"
  echo "  fs-ca                       - Count all files and directories"
  echo "  fs-caf                      - Count all files including subdirectories"
  echo "  fs-cad                      - Count all directories including subdirectories"
  echo "  fs-cl                       - Count total lines of code in files"
  echo ""
  echo "Deletion and Cleanup:"
  echo "  fs-de                       - Delete empty directories"
  echo "  fs-deln                     - Delete files containing string in filename"
  echo "  fs-dele                     - Delete files with extension"
  echo "  fs-cnm                      - Delete node_modules directories recursively"
  echo "  fs-delage                   - Delete files older than specified minutes"
  echo ""
  echo "Filename Modification:"
  echo "  fs-trimend                  - Delete last n characters from filenames"
  echo "  fs-trimstart                - Delete first n characters from filenames"
  echo "  fs-pre                      - Add prefix to filenames"
  echo "  fs-suf                      - Add suffix before extension"
  echo "  fs-rname                    - Replace string in filenames"
  echo ""
  echo "Content and Creation:"
  echo "  fs-rtext                    - Replace string in file contents"
  echo "  fs-mkdummy                  - Create a dummy file of specified size"
  echo "  fs-mkmd                     - Create README.md file"
  echo "  fs-mktxt                    - Create text file"
  echo "  fs-mkpy                     - Create Python file"
  echo "  fs-mksh                     - Create executable Shell file"
  echo "  fs-mkjs                     - Create JavaScript file"
  echo "  fs-mkjson                   - Create JSON file"
  echo "  fs-mkhtml                   - Create HTML file"
  echo "  fs-mkbatch                  - Create numbered files"
  echo "  fs-mirror                   - Create files with new extension"
  echo "  fs-cpext                    - Copy files by extension"
}' # Display help for filesystem aliases
