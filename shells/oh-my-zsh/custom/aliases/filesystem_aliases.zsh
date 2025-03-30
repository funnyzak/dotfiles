# Description: File system related aliases for file operations, searching, manipulation, and management.

# Helper functions for common operations
_validate_params_filesystem_aliases() {
  if [ $# -eq 0 ]; then
    echo "$1" >&2
    return 1
  fi
  return 0
}

_check_command_status_filesystem_aliases() {
  if [ $? -ne 0 ]; then
    echo "Error: $1" >&2
    return 1
  fi
  return 0
}

# Enhanced helper functions for better error handling
_check_directory_exists_filesystem_aliases() {
  if [ ! -d "$1" ]; then
    echo "Error: Directory \"$1\" does not exist." >&2
    return 1
  fi
  return 0
}

_check_file_exists_filesystem_aliases() {
  if [ ! -e "$1" ]; then
    echo "Error: File \"$1\" does not exist." >&2
    return 1
  fi
  return 0
}

# Basic file operations
alias rmi='rm -i' # Interactive removal - prompts before deleting files

alias fs-rm-interactive='rm -i' # Interactive removal - prompts before deleting files

alias log100='() {
  echo "Display last 100 lines of file and follow updates.\nUsage:\n log100 <file_path>"
  tail -f -n 100 "$@"
}' # Display last 100 lines of file and follow updates

alias log200='() {
  echo "Display last 200 lines of file and follow updates.\nUsage:\n log200 <file_path>"
  tail -f -n 200 "$@"
}' # Display last 200 lines of file and follow updates

alias log500='() {
  echo "Display last 500 lines of file and follow updates.\nUsage:\n log500 <file_path>"
  tail -f -n 500 "$@"
}' # Display last 500 lines of file and follow updates

alias log1000='() {
  echo "Display last 1000 lines of file and follow updates.\nUsage:\n log1000 <file_path>"
  tail -f -n 1000 "$@"
}' # Display last 1000 lines of file and follow updates

alias log2000='() {
  echo "Display last 2000 lines of file and follow updates.\nUsage:\n log2000 <file_path>"
  tail -f -n 2000 "$@"
}' # Display last 2000 lines of file and follow updates

alias rmdir='() {
  if ! _validate_params_filesystem_aliases "Remove directory recursively.\nUsage:\n rmdir <directory_path>"; then
    return 1
  fi

  if [ ! -d "$1" ]; then
    echo "Error: Directory \"$1\" does not exist." >&2
    return 1
  fi

  echo "Removing directory \"$1\"..."
  rm -rfv "$1"

  if _check_command_status_filesystem_aliases "Failed to remove directory \"$1\"."; then
    echo "Directory \"$1\" has been removed successfully."
  fi
}' # Remove directory recursively

alias fs-rm-dir='rmdir' # Alias for removing directory recursively

# File backup
alias fs-backup='() {
  if ! _validate_params_filesystem_aliases "Backup file or directory with timestamp.\nUsage:\n fs-backup <file_or_directory> [backup_name]"; then
    return 1
  fi

  if [ ! -e "$1" ]; then
    echo "Error: File or directory \"$1\" does not exist." >&2
    return 1
  fi

  timestamp=$(date +%Y%m%d%H%M%S)
  backup_path="$1_$timestamp"

  echo "Creating backup of \"$1\"..."
  cp -r "$1" "$backup_path"

  if _check_command_status_filesystem_aliases "Failed to create backup of \"$1\"."; then
    echo "Backup completed, exported to \"$backup_path\""
  fi
}' # Create a timestamped backup of file or directory

# File search by size
alias fs-find-big='() {
  if ! _validate_params_filesystem_aliases "Find large files.\nUsage:\n fs-find-big <size_in_MB:10> [directory_path:.]"; then
    return 1
  fi

  size=${1:-10}
  dir_path=${2:-.}

  if [ ! -d "$dir_path" ]; then
    echo "Error: Directory \"$dir_path\" does not exist." >&2
    return 1
  fi

  echo "Finding files larger than ${size}MB in \"$dir_path\"..."
  find "$dir_path" -type f -size +${size}M -exec ls -lh {} \; | sort -k 5 -h -r

  count=$(find "$dir_path" -type f -size +${size}M | wc -l | tr -d " ")
  echo -e "\nFound $count files larger than ${size}MB in \"$dir_path\"."
}' # Find files larger than specified size in MB

alias fs-find-small='() {
  if ! _validate_params_filesystem_aliases "Find small files.\nUsage:\n fs-find-small <size_in_MB:1> [directory_path:.]"; then
    return 1
  fi

  size=${1:-1}
  dir_path=${2:-.}

  if [ ! -d "$dir_path" ]; then
    echo "Error: Directory \"$dir_path\" does not exist." >&2
    return 1
  fi

  echo "Finding files smaller than ${size}MB in \"$dir_path\"..."
  find "$dir_path" -type f -size -${size}M -exec ls -lh {} \; | sort -k 5 -h

  count=$(find "$dir_path" -type f -size -${size}M | wc -l | tr -d " ")
  echo -e "\nFound $count files smaller than ${size}MB in \"$dir_path\"."
}' # Find files smaller than specified size in MB

# File and directory counting
alias fs-count-files='() {
  dir_path="${1:-.}"

  if [ ! -d "$dir_path" ]; then
    echo "Error: Directory \"$dir_path\" does not exist." >&2
    return 1
  fi

  count=$(ls -1p "$dir_path" | grep -v / | wc -l | tr -d " ")
  echo "Number of files in \"$dir_path\": $count"
}' # Count files in directory

alias fs-count-dirs='() {
  dir_path="${1:-.}"

  if [ ! -d "$dir_path" ]; then
    echo "Error: Directory \"$dir_path\" does not exist." >&2
    return 1
  fi

  count=$(ls -1p "$dir_path" | grep / | wc -l | tr -d " ")
  echo "Number of directories in \"$dir_path\": $count"
}' # Count directories in directory

alias fs-count-all='() {
  dir_path="${1:-.}"

  if [ ! -d "$dir_path" ]; then
    echo "Error: Directory \"$dir_path\" does not exist." >&2
    return 1
  fi

  count=$(ls -1p "$dir_path" | wc -l | tr -d " ")
  echo "Total number of files and directories in \"$dir_path\": $count"
}' # Count all files and directories

alias fs-count-all-files='() {
  if [ $# -gt 2 ]; then
    echo "Count all files in directory and subdirectories.\nUsage:\n fs-count-all-files [directory_path:.] [extension:*]" >&2
    return 1
  fi

  dir_path="${1:-.}"
  extension="${2:-*}"

  if [ ! -d "$dir_path" ]; then
    echo "Error: Directory \"$dir_path\" does not exist." >&2
    return 1
  fi

  count=$(find "$dir_path" -type f -name "*.$extension" | wc -l | tr -d " ")
  echo "Total number of files with extension \".$extension\" in \"$dir_path\" and subdirectories: $count"
}' # Count all files including subdirectories

alias fs-count-all-dirs='() {
  dir_path="${1:-.}"

  if [ ! -d "$dir_path" ]; then
    echo "Error: Directory \"$dir_path\" does not exist." >&2
    return 1
  fi

  count=$(find "$dir_path" -type d | wc -l | tr -d " ")
  echo "Total number of directories in \"$dir_path\" and subdirectories: $count"
}' # Count all directories including subdirectories

# Text and file searching
alias fs-find-text='() {
  if [ $# -lt 2 ]; then
    echo "Search for text in files.\nUsage:\n fs-find-text <keyword> [path:.] [extension:*]" >&2
    return 1
  fi

  search_keyword="$1"
  search_path="${2:-.}"
  search_ext="${3:-*}"

  if [ ! -d "$search_path" ]; then
    echo "Error: Directory \"$search_path\" does not exist." >&2
    return 1
  fi

  echo "Searching for \"$search_keyword\" in files with extension \".$search_ext\" in \"$search_path\"..."
  grep -rnw "$search_path" -e "$search_keyword" --include="*.$search_ext"

  result_count=$(grep -rnw "$search_path" -e "$search_keyword" --include="*.$search_ext" | wc -l | tr -d " ")
  echo -e "\nSearch results: Found $result_count matches"
}' # Search for text in files

alias fs-find-by-size='() {
  if [ $# -lt 2 ]; then
    echo "Search for files by size.\nUsage:\n fs-find-by-size <size_with_unit> [path:.] [extension:*] [action:echo]" >&2
    echo "Example: fs-find-by-size +10M /path/to/dir pdf ls -lh" >&2
    return 1
  fi

  search_size="$1"
  search_path="${2:-.}"
  search_ext="${3:-*}"
  action="${4:-echo}"

  if [ ! -d "$search_path" ]; then
    echo "Error: Directory \"$search_path\" does not exist." >&2
    return 1
  fi

  echo "Finding files with size $search_size and extension \".$search_ext\" in \"$search_path\"..."
  find "$search_path" -type f -size "$search_size" -name "*.$search_ext" -exec $action {} \;

  count=$(find "$search_path" -type f -size "$search_size" -name "*.$search_ext" | wc -l | tr -d " ")
  echo -e "\nFound $count matching files."
}' # Search for files by size

alias fs-find-files='() {
  if [ $# -lt 1 ]; then
    echo "Search for files by name pattern.\nUsage:\n fs-find-files <keyword> [path:.] [extension:*] [action:echo]" >&2
    return 1
  fi

  search_keyword="$1"
  search_path="${2:-.}"
  search_ext="${3:-*}"
  action="${4:-echo}"

  if [ ! -d "$search_path" ]; then
    echo "Error: Directory \"$search_path\" does not exist." >&2
    return 1
  fi

  echo "Finding files containing \"$search_keyword\" in filename with extension \".$search_ext\" in \"$search_path\"..."
  find "$search_path" -type f -name "*$search_keyword*.$search_ext" -exec $action {} \;

  count=$(find "$search_path" -type f -name "*$search_keyword*.$search_ext" | wc -l | tr -d " ")
  echo -e "\nFound $count matching files."
}' # Search for files by name pattern

alias fs-find-dirs='() {
  if [ $# -lt 1 ]; then
    echo "Search for directories by name pattern.\nUsage:\n fs-find-dirs <keyword> [path:.] [action:echo]" >&2
    return 1
  fi

  search_keyword="$1"
  search_path="${2:-.}"
  action="${3:-echo}"

  if [ ! -d "$search_path" ]; then
    echo "Error: Directory \"$search_path\" does not exist." >&2
    return 1
  fi

  echo "Finding directories containing \"$search_keyword\" in name in \"$search_path\"..."
  find "$search_path" -type d -name "*$search_keyword*" -exec $action {} \;

  count=$(find "$search_path" -type d -name "*$search_keyword*" | wc -l | tr -d " ")
  echo -e "\nFound $count matching directories."
}' # Search for directories by name pattern

alias fs-dir-size-match='() {
  if [ $# -lt 1 ]; then
    echo "Calculate total size of directories matching name pattern.\nUsage:\n fs-dir-size-match <keyword> [path:.]" >&2
    return 1
  fi

  search_keyword="$1"
  search_path="${2:-.}"

  if [ ! -d "$search_path" ]; then
    echo "Error: Directory \"$search_path\" does not exist." >&2
    return 1
  fi

  echo "Calculating total size of directories matching \"$search_keyword\" in \"$search_path\"..."
  total_size=$(find "$search_path" -type d -name "*$search_keyword*" -exec du -s {} \; |
    awk "{print \$1}" | awk "{sum+=\$1} END {print sum}" |
    awk "{print int(\$1 / 1024 / 1024) \"MB\"}")

  dir_count=$(find "$search_path" -type d -name "*$search_keyword*" | wc -l | tr -d " ")
  echo "Total size of $dir_count directories with name pattern \"$search_keyword\": $total_size"
}' # Calculate total size of directories matching name pattern

# File deletion and management
alias fs-del-empty-dirs='() {
  if [ $# -lt 1 ]; then
    echo "Delete empty directories.\nUsage:\n fs-del-empty-dirs <directory_path>" >&2
    return 1
  fi

  dir_path="$1"

  if [ ! -d "$dir_path" ]; then
    echo "Error: Directory \"$dir_path\" does not exist." >&2
    return 1
  fi

  echo "Finding and deleting empty directories in \"$dir_path\"..."
  count_before=$(find "$dir_path" -type d | wc -l | tr -d " ")
  find "$dir_path" -type d -empty -delete
  count_after=$(find "$dir_path" -type d | wc -l | tr -d " ")
  deleted=$((count_before - count_after))

  echo "Deleted $deleted empty directories in \"$dir_path\""
}' # Delete empty directories

alias fs-del-files-named='() {
  if [ $# -lt 2 ]; then
    echo "Delete files containing specific string in filename.\nUsage: fs-del-files-named <string> [directory:.]" >&2
    return 1
  fi

  search_str="$1"
  dir_path="${2:-.}"

  if [ ! -d "$dir_path" ]; then
    echo "Error: Directory \"$dir_path\" does not exist." >&2
    return 1
  fi

  echo "Finding files containing \"$search_str\" in filename in \"$dir_path\"..."
  count=$(find "$dir_path" -type f -iname "*$search_str*" | wc -l | tr -d " ")

  if [ "$count" -eq 0 ]; then
    echo "No files found containing \"$search_str\" in \"$dir_path\""
    return 0
  fi

  echo "Found $count files. Proceed with deletion? (y/n)"
  read -r confirm
  if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    find "$dir_path" -type f -iname "*$search_str*" -delete
    echo "Deleted $count files containing \"$search_str\" in \"$dir_path\""
  else
    echo "Operation cancelled"
  fi
}' # Delete files containing specific string in filename

alias fs-del-files-with-ext='() {
  if [ $# -lt 2 ]; then
    echo "Delete files with specific extension.\nUsage: fs-del-files-with-ext <extension> [directory:.]" >&2
    return 1
  fi

  extension="$1"
  dir_path="${2:-.}"

  if [ ! -d "$dir_path" ]; then
    echo "Error: Directory \"$dir_path\" does not exist." >&2
    return 1
  fi

  # Remove leading dot if present
  extension="${extension#.}"

  echo "Finding files with extension \".$extension\" in \"$dir_path\"..."
  count=$(find "$dir_path" -type f -iname "*.$extension" | wc -l | tr -d " ")

  if [ "$count" -eq 0 ]; then
    echo "No files found with extension \".$extension\" in \"$dir_path\""
    return 0
  fi

  echo "Found $count files. Proceed with deletion? (y/n)"
  read -r confirm
  if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    find "$dir_path" -type f -iname "*.$extension" -delete
    echo "Deleted $count files with extension \".$extension\" in \"$dir_path\""
  else
    echo "Operation cancelled"
  fi
}' # Delete files with specific extension

# Filename modification
alias fs-trim-filename-end='() {
  if [ $# -lt 1 ]; then
    echo "Delete last n characters from filenames.\nUsage:\n fs-trim-filename-end <num_chars:1> [extension:*] [directory:.]" >&2
    return 1
  fi

  n=${1:-1}
  ext=${2:-*}
  folder_path=${3:-.}

  if [ ! -d "$folder_path" ]; then
    echo "Error: Directory \"$folder_path\" does not exist." >&2
    return 1
  fi

  echo "Deleting last $n characters from filenames with extension \".$ext\" in folder \"$folder_path\"..."
  count=0

  for file in $(find "$folder_path" -type f -name "*.$ext"); do
    f_ext="${file##*.}"
    f_ext_len=${#f_ext}
    last_n=$((n + f_ext_len + 1))

    if [ ${#file} -le $last_n ]; then
      echo "Warning: Skipping \"$file\" - filename too short to trim $n characters" >&2
      continue
    fi

    new_file="${file::-${last_n}}.${f_ext}"
    mv "$file" "$new_file"
    if [ $? -eq 0 ]; then
      echo "Renamed \"$file\" to \"$new_file\""
      ((count++))
    else
      echo "Error: Failed to rename \"$file\"" >&2
    fi
  done

  echo "Successfully renamed $count files"
}' # Delete last n characters from filenames

alias fs-trim-filename-start='() {
  if [ $# -lt 1 ]; then
    echo "Delete first n characters from filenames.\nUsage:\n fs-trim-filename-start <num_chars:1> [extension:*] [directory:.]" >&2
    return 1
  fi

  n=${1:-1}
  ext=${2:-*}
  folder_path=${3:-.}

  if [ ! -d "$folder_path" ]; then
    echo "Error: Directory \"$folder_path\" does not exist." >&2
    return 1
  fi

  echo "Deleting first $n characters from filenames with extension \".$ext\" in folder \"$folder_path\"..."
  count=0

  for file in $(find "$folder_path" -type f -name "*.$ext"); do
    f_path=$(dirname "$file")
    f_name=$(basename "$file")

    if [ ${#f_name} -le $n ]; then
      echo "Warning: Skipping \"$file\" - filename too short to trim $n characters" >&2
      continue
    fi

    n_name="${f_name:$n}"
    new_file="${f_path}/${n_name}"

    mv "$file" "$new_file"
    if [ $? -eq 0 ]; then
      echo "Renamed \"$file\" to \"$new_file\""
      ((count++))
    else
      echo "Error: Failed to rename \"$file\"" >&2
    fi
  done

  echo "Successfully renamed $count files"
}' # Delete first n characters from filenames

alias fs-add-prefix='() {
  if [ $# -lt 1 ]; then
    echo "Add prefix to filenames.\nUsage:\n fs-add-prefix <prefix> [extension:*] [directory:.]" >&2
    return 1
  fi

  prefix="$1"
  ext=${2:-*}
  folder_path=${3:-.}

  if [ ! -d "$folder_path" ]; then
    echo "Error: Directory \"$folder_path\" does not exist." >&2
    return 1
  fi

  echo "Adding prefix \"$prefix\" to filenames with extension \".$ext\" in folder \"$folder_path\"..."
  count=0

  for file in $(find "$folder_path" -type f -name "*.$ext"); do
    f_path=$(dirname "$file")
    f_name=$(basename "$file")
    n_name="${prefix}${f_name}"
    new_file="${f_path}/${n_name}"

    if [ -e "$new_file" ]; then
      echo "Warning: Skipping \"$file\" - target file \"$new_file\" already exists" >&2
      continue
    fi

    mv "$file" "$new_file"
    if [ $? -eq 0 ]; then
      echo "Renamed \"$file\" to \"$new_file\""
      ((count++))
    else
      echo "Error: Failed to rename \"$file\"" >&2
    fi
  done

  echo "Successfully renamed $count files"
}' # Add prefix to filenames

alias fs-add-suffix='() {
  if [ $# -lt 1 ]; then
    echo "Add suffix to filenames (before extension).\nUsage:\n fs-add-suffix <suffix> [extension:*] [directory:.]" >&2
    return 1
  fi

  suffix="$1"
  ext=${2:-*}
  folder_path=${3:-.}

  if [ ! -d "$folder_path" ]; then
    echo "Error: Directory \"$folder_path\" does not exist." >&2
    return 1
  fi

  echo "Adding suffix \"$suffix\" to filenames with extension \".$ext\" in folder \"$folder_path\"..."
  count=0

  for file in $(find "$folder_path" -type f -name "*.$ext"); do
    f_path=$(dirname "$file")
    f_name=$(basename "$file")
    f_ext="${f_name##*.}"
    f_base="${f_name%.*}"
    n_name="${f_base}${suffix}.${f_ext}"
    new_file="${f_path}/${n_name}"

    if [ -e "$new_file" ]; then
      echo "Warning: Skipping \"$file\" - target file \"$new_file\" already exists" >&2
      continue
    fi

    mv "$file" "$new_file"
    if [ $? -eq 0 ]; then
      echo "Renamed \"$file\" to \"$new_file\""
      ((count++))
    else
      echo "Error: Failed to rename \"$file\"" >&2
    fi
  done

  echo "Successfully renamed $count files"
}' # Add suffix to filenames (before extension)

alias fs-replace-in-filename='() {
  if [ $# -lt 2 ]; then
    echo "Replace string in filenames.\nUsage:\n fs-replace-in-filename <old_string> <new_string> [extension:*] [directory:.]" >&2
    return 1
  fi

  old_str="$1"
  new_str="$2"
  ext=${3:-*}
  folder_path=${4:-.}

  if [ ! -d "$folder_path" ]; then
    echo "Error: Directory \"$folder_path\" does not exist." >&2
    return 1
  fi

  echo "Replacing \"$old_str\" with \"$new_str\" in filenames with extension \".$ext\" in folder \"$folder_path\"..."
  count=0

  for file in $(find "$folder_path" -type f -name "*.$ext"); do
    if [[ "$file" != *"$old_str"* ]]; then
      continue
    fi

    new_file="${file//$old_str/$new_str}"

    if [ "$file" = "$new_file" ]; then
      continue
    fi

    if [ -e "$new_file" ]; then
      echo "Warning: Skipping \"$file\" - target file \"$new_file\" already exists" >&2
      continue
    fi

    mv "$file" "$new_file"
    if [ $? -eq 0 ]; then
      echo "Renamed \"$file\" to \"$new_file\""
      ((count++))
    else
      echo "Error: Failed to rename \"$file\"" >&2
    fi
  done

  echo "Successfully renamed $count files"
}' # Replace string in filenames

# Content replacement
alias fs-replace-in-files='() {
  if [ $# -lt 2 ]; then
    echo "Replace string in file contents.\nUsage:\n fs-replace-in-files <old_string> <new_string> [extension:*] [directory:.]" >&2
    return 1
  fi

  old_str="$1"
  new_str="$2"
  ext=${3:-*}
  folder_path=${4:-.}

  if [ ! -d "$folder_path" ]; then
    echo "Error: Directory \"$folder_path\" does not exist." >&2
    return 1
  fi

  echo "Replacing \"$old_str\" with \"$new_str\" in content of files with extension \".$ext\" in folder \"$folder_path\"..."
  count=0

  for file in $(find "$folder_path" -type f -name "*.$ext"); do
    if grep -q "$old_str" "$file"; then
      if [ "$(uname)" = "Darwin" ]; then
        sed -i "" "s/${old_str}/${new_str}/g" "$file"
      else
        sed -i "s/${old_str}/${new_str}/g" "$file"
      fi

      if [ $? -eq 0 ]; then
        echo "Updated content in \"$file\""
        ((count++))
      else
        echo "Error: Failed to update content in \"$file\"" >&2
      fi
    fi
  done

  echo "Successfully updated $count files"
}' # Replace string in file contents

# File creation
alias fs-create-dummy-file='() {
  echo "Create a file of specified size using dd.\nUsage:\n fs-create-dummy-file [size_in_MB:10] [output_path:./file_timestamp]"

  size=${1:-10}
  output=${2:-$(pwd)/file_$(date +%Y%m%d%H%M%S)}

  echo "Creating a ${size}MB file at \"$output\"..."
  dd if=/dev/zero of="$output" bs=1M count=$size 2>/dev/null

  if [ $? -eq 0 ]; then
    echo "File creation completed. Created a ${size}MB file at \"$output\""
  else
    echo "Error: Failed to create file at \"$output\"" >&2
    return 1
  fi
}' # Create a dummy file of specified size using dd

# File copying
alias fs-copy-by-ext='() {
  if [ $# -lt 2 ]; then
    echo "Copy files with specific extension to target directory.\nUsage:\n fs-copy-by-ext <extension> <target_directory>" >&2
    return 1
  fi

  ext="$1"
  # Remove leading dot if present
  ext="${ext#.}"
  target_dir="$2"

  if [ ! -d "$target_dir" ] && ! mkdir -p "$target_dir"; then
    echo "Error: Failed to create directory \"$target_dir\"" >&2
    return 1
  fi

  count=0
  for file in *."$ext"; do
    if [ -f "$file" ]; then
      cp "$file" "$target_dir/"
      if [ $? -eq 0 ]; then
        ((count++))
      else
        echo "Error: Failed to copy \"$file\" to \"$target_dir/\"" >&2
      fi
    fi
  done

  echo "Copy completed. Copied $count files with extension \".$ext\" to \"$target_dir/\""
}' # Copy all files with specific extension to target directory

# Extract line counting into a separate helper function for better reusability
_count_lines_in_files_filesystem_aliases() {
  local search_path="$1"
  local file_ext="$2"
  local lines=0
  local count=0

  if [ "$file_ext" = "*" ]; then
    lines=$(find "$search_path" -type f -not -path "*/\.*" -exec wc -l {} + 2>/dev/null | awk '{s+=$1} END {print s+0}')
    count=$(find "$search_path" -type f -not -path "*/\.*" | wc -l | tr -d " ")
  else
    lines=$(find "$search_path" -name "*.$file_ext" -type f -not -path "*/\.*" -exec wc -l {} + 2>/dev/null | awk '{s+=$1} END {print s+0}')
    count=$(find "$search_path" -name "*.$file_ext" -type f -not -path "*/\.*" | wc -l | tr -d " ")
  fi

  # Handle the case where no files are found
  lines=${lines:-0}
  count=${count:-0}

  # Return the results as output
  echo "$lines $count"
}

# Code line counting
alias fs-count-lines='() {
  echo "Count total lines of code in files.\nUsage:\n fs-count-lines [dir:.] [extension:*]"

  dir=${1:-$(pwd)}
  ext=${2:-*}

  if [ ! -d "$dir" ]; then
    echo "Error: Directory \"$dir\" does not exist." >&2
    return 1
  fi

  # Call the helper function and parse the results
  read lines file_count <<< "$(_count_lines_in_files_filesystem_aliases "$dir" "$ext")"

  echo "Total lines of code in $file_count files with extension \"*$ext\" in \"$dir\": $lines"
}' # Count total lines of code in files

# Quick file creation
alias fs-create-md='() {
  echo "Create README markdown file.\nUsage: fs-create-md [directory:.]"

  dir_path="${1:-.}"
  file_path="${dir_path}/README.md"

  if [ ! -d "$dir_path" ] && ! mkdir -p "$dir_path"; then
    echo "Error: Failed to create directory \"$dir_path\"" >&2
    return 1
  fi

  touch "$file_path"

  if [ $? -eq 0 ]; then
    echo "Created file \"$file_path\""
  else
    echo "Error: Failed to create file \"$file_path\"" >&2
    return 1
  fi
}' # Create README.md file

alias fs-create-txt='() {
  echo "Create text file.\nUsage: fs-create-txt [directory:.] [filename:README.txt]"

  dir_path="${1:-.}"
  filename="${2:-README.txt}"
  file_path="${dir_path}/${filename}"

  if [ ! -d "$dir_path" ] && ! mkdir -p "$dir_path"; then
    echo "Error: Failed to create directory \"$dir_path\"" >&2
    return 1
  fi

  touch "$file_path"

  if [ $? -eq 0 ]; then
    echo "Created file \"$file_path\""
  else
    echo "Error: Failed to create file \"$file_path\"" >&2
    return 1
  fi
}' # Create text file

alias fs-create-py='() {
  echo "Create Python file.\nUsage: fs-create-py [directory:.] [filename:main.py]"

  dir_path="${1:-.}"
  filename="${2:-main.py}"
  file_path="${dir_path}/${filename}"

  if [ ! -d "$dir_path" ] && ! mkdir -p "$dir_path"; then
    echo "Error: Failed to create directory \"$dir_path\"" >&2
    return 1
  fi

  touch "$file_path"

  if [ $? -eq 0]; then
    echo "Created file \"$file_path\""
  else
    echo "Error: Failed to create file \"$file_path\"" >&2
    return 1
  fi
}' # Create Python file

alias fs-create-sh='() {
  echo "Create Shell script file.\nUsage: fs-create-sh [directory:.] [filename:main.sh]"

  dir_path="${1:-.}"
  filename="${2:-main.sh}"
  file_path="${dir_path}/${filename}"

  if [ ! -d "$dir_path" ] && ! mkdir -p "$dir_path"; then
    echo "Error: Failed to create directory \"$dir_path\"" >&2
    return 1
  fi

  touch "$file_path"
  chmod +x "$file_path"

  if [ $? -eq 0 ]; then
    echo "#!/bin/bash" > "$file_path"
    echo "" >> "$file_path"
    echo "Created executable Shell file \"$file_path\""
  else
    echo "Error: Failed to create file \"$file_path\"" >&2
    return 1
  fi
}' # Create Shell file with execute permission

alias fs-create-js='() {
  echo "Create JavaScript file.\nUsage: fs-create-js [directory:.] [filename:main.js]"

  dir_path="${1:-.}"
  filename="${2:-main.js}"
  file_path="${dir_path}/${filename}"

  if [ ! -d "$dir_path" ] && ! mkdir -p "$dir_path"; then
    echo "Error: Failed to create directory \"$dir_path\"" >&2
    return 1
  fi

  touch "$file_path"

  if [ $? -eq 0 ]; then
    echo "Created file \"$file_path\""
  else
    echo "Error: Failed to create file \"$file_path\"" >&2
    return 1
  fi
}' # Create JavaScript file

alias fs-create-json='() {
  echo "Create JSON file.\nUsage: fs-create-json [directory:.] [filename:main.json]"

  dir_path="${1:-.}"
  filename="${2:-main.json}"
  file_path="${dir_path}/${filename}"

  if [ ! -d "$dir_path" ] && ! mkdir -p "$dir_path"; then
    echo "Error: Failed to create directory \"$dir_path\"" >&2
    return 1
  fi

  touch "$file_path"
  echo "{}" > "$file_path"

  if [ $? -eq 0 ]; then
    echo "Created file \"$file_path\" with empty JSON object"
  else
    echo "Error: Failed to create file \"$file_path\"" >&2
    return 1
  fi
}' # Create JSON file

alias fs-create-html='() {
  echo "Create HTML file.\nUsage: fs-create-html [directory:.] [filename:index.html]"

  dir_path="${1:-.}"
  filename="${2:-index.html}"
  file_path="${dir_path}/${filename}"

  if [ ! -d "$dir_path" ] && ! mkdir -p "$dir_path"; then
    echo "Error: Failed to create directory \"$dir_path\"" >&2
    return 1
  fi

  touch "$file_path"

  if [ $? -eq 0 ]; then
    echo "<!DOCTYPE html>" > "$file_path"
    echo "<html>" >> "$file_path"
    echo "  <head>" >> "$file_path"
    echo "    <meta charset=\"UTF-8\">" >> "$file_path"
    echo "    <title>Document</title>" >> "$file_path"
    echo "  </head>" >> "$file_path"
    echo "  <body>" >> "$file_path"
    echo "    " >> "$file_path"
    echo "  </body>" >> "$file_path"
    echo "</html>" >> "$file_path"
    echo "Created file \"$file_path\" with basic HTML structure"
  else
    echo "Error: Failed to create file \"$file_path\"" >&2
    return 1
  fi
}' # Create HTML file with basic structure

# Batch file creation
alias fs-create-batch='() {
  if [ $# -lt 2 ]; then
    echo "Create batch files with numbered sequence.\nUsage: fs-create-batch <prefix> <suffix> [count:1] [target_dir:.] [zero_padding:1]" >&2
    return 1
  fi

  file_prefix="$1"
  file_suffix="$2"
  file_count="${3:-1}"
  target_path="${4:-.}"
  zero_fill=${5:-1}

  if ! mkdir -p "$target_path"; then
    echo "Error: Failed to create directory \"$target_path\"" >&2
    return 1
  fi

  created=0
  for ((i=1;i<=$file_count;i++)); do
    filename="${file_prefix}$(printf "%0${zero_fill}d" $i).${file_suffix}"
    file_path="${target_path}/${filename}"

    touch "$file_path"
    if [ $? -eq 0 ]; then
      echo "Created: \"$file_path\""
      ((created++))
    else
      echo "Error: Failed to create \"$file_path\"" >&2
    fi
  done

  echo "Batch creation completed. Created $created of $file_count files in \"$target_path\""
}' # Create batch files with numbered sequence

# Create files based on existing files
alias fs-mirror-files='() {
  if [ $# -lt 1]; then
    echo "Create files with new extension based on existing files.\nUsage: fs-mirror-files <new_extension> [search_extension:*] [source_dir:.] [target_dir:source_dir]" >&2
    return 1
  fi

  new_suffix="${1#.}"  # Remove leading dot if present
  search_suffix="${2:-*}"
  source_path="${3:-.}"
  target_path="${4:-$source_path}"

  if [ ! -d "$source_path" ]; then
    echo "Error: Source directory \"$source_path\" does not exist." >&2
    return 1
  fi

  if ! mkdir -p "$target_path"; then
    echo "Error: Failed to create target directory \"$target_path\"" >&2
    return 1
  fi

  count=0
  for source_file in "$source_path"/*.$search_suffix; do
    if [ -f "$source_file" ]; then
      file_name_no_ext=$(basename "$source_file" .$search_suffix)
      new_file="${target_path}/${file_name_no_ext}.${new_suffix}"

      touch "$new_file"
      if [ $? -eq 0 ]; then
        echo "Created: \"$new_file\""
        ((count++))
      else
        echo "Error: Failed to create \"$new_file\"" >&2
      fi
    fi
  done

  echo "Mirror operation completed. Created $count files with extension \".$new_suffix\" based on \".$search_suffix\" files."
}' # Create files with new extension based on existing files

# Clean node_modules
alias fs-clean-node-modules='() {
  echo "Delete all node_modules directories recursively.\nUsage: fs-clean-node-modules [search_path:.]"

  search_path="${1:-.}"

  if [ ! -d "$search_path" ]; then
    echo "Error: Directory \"$search_path\" does not exist." >&2
    return 1
  fi

  echo "Searching for node_modules directories in \"$search_path\"..."
  dirs=$(find "$search_path" -type d -name "node_modules" | wc -l | tr -d " ")

  if [ "$dirs" -eq 0 ]; then
    echo "No node_modules directories found in \"$search_path\""
    return 0
  fi

  echo "Found $dirs node_modules directories. Proceed with deletion? (y/n)"
  read -r confirm

  if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    echo "Deleting all node_modules directories in \"$search_path\"..."
    find "$search_path" -type d -name "node_modules" -exec rm -rf "{}" \;

    if [ $? -eq 0 ]; then
      echo "Successfully deleted $dirs node_modules directories"
    else
      echo "Error: Some directories could not be deleted" >&2
      return 1
    fi
  else
    echo "Operation cancelled"
  fi
}' # Clean up node_modules directories recursively

# File system help function
alias fs-help='() {
  echo "File System Aliases Help"
  echo "========================"
  echo "This module provides various file system related aliases for file operations, searching, manipulation, and management."
  echo ""
  echo "Basic File Operations:"
  echo "  fs-rm-interactive         - Interactive removal - prompts before deleting files"
  echo "  fs-rm-dir                 - Remove directory recursively"
  echo "  fs-backup                 - Create a timestamped backup of file or directory"
  echo ""
  echo "File Search:"
  echo "  fs-find-big               - Find files larger than specified size in MB"
  echo "  fs-find-small             - Find files smaller than specified size in MB"
  echo "  fs-find-text              - Search for text in files"
  echo "  fs-find-by-size           - Search for files by size"
  echo "  fs-find-files             - Search for files by name pattern"
  echo "  fs-find-dirs              - Search for directories by name pattern"
  echo ""
  echo "File and Directory Counting:"
  echo "  fs-count-files            - Count files in directory"
  echo "  fs-count-dirs             - Count directories in directory"
  echo "  fs-count-all              - Count all files and directories"
  echo "  fs-count-all-files        - Count all files including subdirectories"
  echo "  fs-count-all-dirs         - Count all directories including subdirectories"
  echo "  fs-count-lines            - Count total lines of code in files"
  echo ""
  echo "File Deletion and Management:"
  echo "  fs-del-empty-dirs         - Delete empty directories"
  echo "  fs-del-files-named        - Delete files containing specific string in filename"
  echo "  fs-del-files-with-ext     - Delete files with specific extension"
  echo "  fs-clean-node-modules     - Delete all node_modules directories recursively"
  echo ""
  echo "Filename Modification:"
  echo "  fs-trim-filename-end      - Delete last n characters from filenames"
  echo "  fs-trim-filename-start    - Delete first n characters from filenames"
  echo "  fs-add-prefix             - Add prefix to filenames"
  echo "  fs-add-suffix             - Add suffix to filenames (before extension)"
  echo "  fs-replace-in-filename    - Replace string in filenames"
  echo ""
  echo "Content Replacement:"
  echo "  fs-replace-in-files       - Replace string in file contents"
  echo "  fs-dir-size-match         - Calculate total size of directories matching name pattern"
  echo ""
  echo "File Creation:"
  echo "  fs-create-dummy-file      - Create a dummy file of specified size using dd"
  echo "  fs-create-md              - Create README.md file"
  echo "  fs-create-txt             - Create text file"
  echo "  fs-create-py              - Create Python file"
  echo "  fs-create-sh              - Create Shell file with execute permission"
  echo "  fs-create-js              - Create JavaScript file"
  echo "  fs-create-json            - Create JSON file with empty object"
  echo "  fs-create-html            - Create HTML file with basic structure"
  echo "  fs-create-batch           - Create batch files with numbered sequence"
  echo "  fs-mirror-files           - Create files with new extension based on existing files"
  echo ""
  echo "Display File Content:"
  echo "  log100            - Display last 100 lines of file and follow updates"
  echo "  log200            - Display last 200 lines of file and follow updates"
  echo "  log500            - Display last 500 lines of file and follow updates"
  echo "  log1000           - Display last 1000 lines of file and follow updates"
  echo "  log2000           - Display last 2000 lines of file and follow updates"
  echo ""
  echo "File Copying:"
  echo "  fs-copy-by-ext            - Copy all files with specific extension to target directory"
  echo ""
  echo "For detailed usage of each command, run the command without parameters."
}' # Display help for filesystem aliases
