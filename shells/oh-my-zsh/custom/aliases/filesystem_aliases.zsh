# Description: File system related aliases for file operations, searching, manipulation, and management.

# Basic file operations
alias rmi='rm -i'  # Interactive removal - prompts before deleting files
alias rm_dir='() { 
  if [ $# -eq 0 ]; then 
    echo "Remove directory recursively.\nUsage:\n rm_dir <directory_path>"
  else 
    echo "Removing directory $1"
    rm -rfv $1
    echo "Directory $1 has been removed"
  fi 
}'  # Remove directory recursively

# File backup
alias back='() {
  if [ $# -eq 0 ]; then
    echo "Backup file or directory with timestamp.\nUsage:\n back <file_or_directory> [backup_name]"
  else
    timestamp=$(date +%Y%m%d%H%M%S)
    cp -r $1 $1_$timestamp && 
    echo "Backup completed, exported to $1_$timestamp"
  fi
}'  # Create a timestamped backup of file or directory

# File search by size
alias findbigfile='() { 
  if [ $# -eq 0 ]; then 
    echo "Find large files.\nUsage:\n findbigfile <size_in_MB> [directory_path]"
  else 
    size=${1}
    dir_path=${2:-.}
    find $dir_path -type f -size +${size}M -exec ls -lh {} \; | sort -k 5 -h -r
  fi 
}'  # Find files larger than specified size in MB
alias findsmallfile='() { 
  if [ $# -eq 0 ]; then 
    echo "Find small files.\nUsage:\n findsmallfile <size_in_MB> [directory_path]"
  else 
    size=${1}
    dir_path=${2:-.}
    find $dir_path -type f -size -${size}M -exec ls -lh {} \; | sort -k 5 -h
  fi 
}'  # Find files smaller than specified size in MB

# Show file count in a directory
alias fcount='() {
  if [ $# -eq 0 ]; then
    echo "Show file count.\nUsage:\n fcount <directory_path>"
  else
    ls -1p ${1:-./} | grep -v / | wc -l | xargs echo "The number of files in the folder ${1:-./} is => "
  fi
}' # Show file count in a directory

# Show directory count in a directory
alias dcount='() {
  if [ $# -eq 0 ]; then
    echo "Show directory count.\nUsage:\n dcount <directory_path>"
  else
    ls -1p ${1:-./} | grep / | wc -l | xargs echo "The number of folders in the folder ${1:-./} is => "
  fi
}' # Show directory count in a directory

# Show file and directory count in a directory
alias fdcount='() {
  if [ $# -eq 0 ]; then
    echo "Show file and directory count.\nUsage:\n fdcount <directory_path>"
  else
    ls -1p ${1:-./} | wc -l | xargs echo "The number of files and folders in the folder ${1:-./} is => "
  fi
}' # Show file and directory count in a directory

# Show the number of files in the folder and subfolders
alias facount='() {
  if [ $# -eq 0 ]; then
    echo "Show the number of files in the folder and subfolders.\nUsage:\n facount <directory_path> <extension>"
  else
    find ${1:-./} -type f -name "*.${2:-*}" -print | wc -l | xargs echo "folder \"${1:-./}\" and sub folder all file count with extension *.${2:-*} => "
  fi
}' # Show the number of files in the folder and subfolders

# Show the number of directories in the folder and subfolders
alias dacount='() {
  if [ $# -eq 0 ]; then
    echo "Show the number of directories in the folder and subfolders.\nUsage:\n dacount <directory_path>"
  else
    find ${1:-./} -type d -print | wc -l | xargs echo "folder \"${1:-./}\" and sub folder all dir count => "
  fi
}' # Show the number of directories in the folder and subfolders

# Text search
alias search_text='() { 
  if [ $# -eq 0 ]; then 
    echo "Search for text in files with specified extension.\nUsage:\n search_text [path] [keyword] [extension]"
  else 
    search_path="${1:-.}"
    search_keyword="${2}"
    search_suffix="${3:-*}"
    grep -rnw "$search_path" -e "$search_keyword" --include "*.$search_suffix"
    f_count=$(grep -rnw "$search_path" -e "$search_keyword" --include "*.$search_suffix" | wc -l)
    echo -e "\nSearch results: Found $f_count matches"
  fi 
}'  # Search for text in files with specified extension

# Size-based file search
alias search_size='() { 
  if [ $# -eq 0 ]; then 
    echo "Search for files of specified size and extension.\nUsage:\n search_size [path] [size] [extension] [action]\n       search_size /path/to +2MB \"*\" \"echo\""
  else 
    search_path="${1:-.}"
    search_size="${2}"
    search_suffix="${3:-*}"
    action="${4:-echo}"
    find "$search_path" -type f -size $search_size -name "*.$search_suffix" -exec $action {} \;
  fi 
}'  # Search for files of specified size and extension

# Filename search
alias search_fname='() { 
  if [ $# -eq 0 ]; then 
    echo "Search for files containing string in filename.\nUsage:\n search_fname [keyword] [path] [extension] [action]\n       search_fname \"test\" /path/to \"*\" \"echo\""
  else 
    search_path="${2:-.}"
    search_keyowrd="${1}"
    search_suffix="${3:-*}"
    action="${4:-echo}"
    find "$search_path" -type f -name "*$search_keyowrd*.$search_suffix" -exec $action {} \;
  fi 
}'  # Search for files containing string in filename

# Directory name search
alias search_dname='() { 
  if [ $# -eq 0 ]; then 
    echo "Search for directories containing string in name.\nUsage:\n search_dname [keyword] [path] [action]\n       search_dname \"test\" /path/to \"echo\""
  else 
    search_path="${2:-.}"
    search_keyowrd="${1}"
    action="${3:-echo}"
    find "$search_path" -type d -name "*$search_keyowrd*" -exec $action {} \;
  fi 
}'  # Search for directories containing string in name

# Match directory size
alias match_dname_total_size='() { 
  if [ $# -eq 0 ]; then 
    echo "Calculate total size of directories matching name pattern.\nUsage:\n match_dname_total_size [keyword] [path]\n       match_dname_total_size \"test\" /path/to"
  else 
    search_path="${2:-.}"
    search_keyowrd="${1}"
    find "$search_path" -type d -name "*$search_keyowrd*" -exec du -s {} \; | 
    awk "{print \$1}" | awk "{sum+=\$1} END {print sum}" | 
    awk "{print int(\$1 / 1024 / 1024) \"MB\"}" | 
    xargs echo "Total size of directories with name pattern $search_keyowrd: "
  fi 
}'  # Calculate total size of directories matching name pattern

# File deletion
alias del_empty_dir='() {
  if [ $# -eq 0 ]; then
    echo "Delete empty directories.\nUsage:\n del_empty_dir <directory_path>"
  else
    find $1 -type d -empty -delete && echo "Empty directories deleted"
  fi
}'  # Delete empty directories

alias del_files_contain='() {
  if [ $# -eq 0 ]; then 
    echo "Delete files containing specific string in filename.\nUsage: del_files_contain [directory:.] [string]"
    return 1
  fi 
  find $1 -type f -iname "*$2*" -delete
  echo "Deleted all files containing \"$2\" in directory $1"
}'  # Delete files containing specific string in filename

alias del_files_ext='() {
  if [ $# -eq 0 ]; then 
    echo "Delete files with specific extension.\nUsage: del_files_ext [directory:.] [extension]"
    return 1
  fi 
  find $1 -type f -iname "*.$2" -delete
  echo "Deleted all .$2 files in directory $1"
}'  # Delete files with specific extension

# Filename modification
alias del_last_n='() {
  if [ $# -eq 0 ]; then
    echo "Delete last n characters from filenames.\nUsage:\n del_last_n <num_chars> <extension> <directory>"
  else
    n=${1:-1}
    folder_path=${3:-.}
    ext=${2:-*}
    echo "Deleting last $n characters from filenames with extension ${ext} in folder ${folder_path}."
    for file in $(find ${folder_path} -type f -name "*.${ext}"); do
      f_ext="${file##*.}"
      f_ext_len=${#f_ext}
      last_n=$((n + f_ext_len + 1))
      mv $file ${file::-${last_n}}.${f_ext}
      echo "Renamed $file to ${file::-${last_n}}.${f_ext}"
    done
  fi
}'  # Delete last n characters from filenames

alias del_start_n='() {
  if [ $# -eq 0 ]; then
    echo "Delete first n characters from filenames.\nUsage:\n del_start_n <num_chars> <extension> <directory>"
  else
    n=${1:-1}
    folder_path=${3:-.}
    ext=${2:-*}
    echo "Deleting first $n characters from filenames with extension ${ext} in folder ${folder_path}."
    for file in $(find ${folder_path} -type f -name "*.${ext}"); do
      f_path=$(dirname $file)
      f_name=$(basename $file)
      n_name="${f_name:$n}"
      mv "$file" "${f_path}/${n_name}"
      echo "Renamed $file to ${f_path}/${n_name}"
    done
  fi
}'  # Delete first n characters from filenames

alias add_start_str='() {
  if [ $# -eq 0 ]; then
    echo "Add prefix to filenames.\nUsage:\n add_start_str <prefix> <extension> <directory>"
  else
    start_str=${1}
    folder_path=${3:-.}
    ext=${2:-*}
    echo "Adding prefix ${start_str} to filenames with extension ${ext} in folder ${folder_path}."
    for file in $(find ${folder_path} -type f -name "*.${ext}"); do
      f_path=$(dirname $file)
      f_name=$(basename $file)
      n_name="${start_str}${f_name}"
      mv "$file" "${f_path}/${n_name}"
      echo "Renamed $file to ${f_path}/${n_name}"
    done
  fi
}'  # Add prefix to filenames

alias add_last_str='() {
  if [ $# -eq 0 ]; then
    echo "Add suffix to filenames (before extension).\nUsage:\n add_last_str <suffix> <extension> <directory>"
  else
    last_str=${1}
    folder_path=${3:-.}
    ext=${2:-*}
    echo "Adding suffix ${last_str} to filenames with extension ${ext} in folder ${folder_path}."
    for file in $(find ${folder_path} -type f -name "*.${ext}"); do
      f_path=$(dirname $file)
      f_name=$(basename $file)
      f_ext="${f_name##*.}"
      n_name="${f_name%.*}${last_str}.${f_ext}"
      mv "$file" "${f_path}/${n_name}"
      echo "Renamed $file to ${f_path}/${n_name}"
    done
  fi
}'  # Add suffix to filenames (before extension)

alias replace_fname_str='() {
  if [ $# -eq 0 ]; then
    echo "Replace string in filenames.\nUsage:\n replace_fname_str <old_string> <new_string> <extension> <directory>"
  else
    old_str=${1}
    new_str=${2}
    folder_path=${4:-.}
    ext=${3:-*}
    echo "Replacing ${old_str} with ${new_str} in filenames with extension ${ext} in folder ${folder_path}."
    for file in $(find ${folder_path} -type f -name "*.${ext}"); do
      new_file=${file//$old_str/$new_str}
      if [ "$file" != "$new_file" ]; then
        mv "$file" "$new_file"
        echo "Renamed $file to $new_file"
      fi
    done
  fi
}'  # Replace string in filenames

# Content replacement
alias replace_fcontent_str='() {
  if [ $# -eq 0 ]; then
    echo "Replace string in file contents.\nUsage:\n replace_fcontent_str <old_string> <new_string> <extension> <directory>"
  else
    old_str=${1}
    new_str=${2}
    folder_path=${4:-.}
    ext=${3:-*}
    echo "Replacing ${old_str} with ${new_str} in content of files with extension ${ext} in folder ${folder_path}."
    for file in $(find ${folder_path} -type f -name "*.${ext}"); do
      if [ "$(uname)" = "Darwin" ]; then
        sed -i "" "s/${old_str}/${new_str}/g" "$file"
      else
        sed -i "s/${old_str}/${new_str}/g" "$file"
      fi
      echo "Replaced content in $file"
    done
  fi
}'  # Replace string in file contents

# File creation
alias ddfile='() {
  size=${1:-7}
  output=${2:-$(pwd)/file_$(date +%Y%m%d%H%M%S)}
  echo "Creating a ${size}MB file..."
  dd if=/dev/zero of=$output bs=1M count=$size
  echo "File creation completed, exported to $output"
}'  # Create a file of specified size using dd

# File copying
alias cp_fs='() {
  if [ $# -eq 0 ]; then
    echo "Copy files with specific extension to target directory.\nUsage:\n cp_fs <extension> <target_directory>"
  else
    mkdir -p $2
    count=0
    for file in *.$1; do
      if [ -f "$file" ]; then
        cp "$file" "$2/"
        ((count++))
      fi
    done
    echo "Copy completed, copied $count .$1 files to directory $2"
  fi
}'  # Copy all files with specific extension to target directory

# Code line counting
alias countlines='() { 
  path=${1:-$(pwd)}
  ext=${2:-*}
  lines=$(find $path -name "*$ext" -type f -exec wc -l {} + | awk "{s+=\$1} END {print s}")
  echo "Total lines of code in files with extension *$ext in $path: $lines"
}'  # Count total lines of code in files with specified extension

# Quick file creation
alias t_md='() { 
  echo "Create README markdown file.\nUsage: t_md <directory>"
  file_path="${1:-.}/README.md"
  touch $file_path
  echo "Created file $file_path"
}'  # Create README.md file

alias t_txt='() { 
  echo "Create text file.\nUsage: t_txt <directory>"
  file_path="${1:-.}/README.txt"
  touch $file_path
  echo "Created file $file_path"
}'  # Create README.txt file

alias t_py='() { 
  echo "Create Python file.\nUsage: t_py <directory>"
  file_path="${1:-.}/main.py"
  touch $file_path
  echo "Created file $file_path"
}'  # Create Python file

alias t_sh='() { 
  echo "Create Shell script file.\nUsage: t_sh <directory>"
  file_path="${1:-.}/main.sh"
  touch $file_path
  chmod +x $file_path
  echo "Created executable Shell file $file_path"
}'  # Create Shell file with execute permission

alias t_js='() { 
  echo "Create JavaScript file.\nUsage: t_js <directory>"
  file_path="${1:-.}/main.js"
  touch $file_path
  echo "Created file $file_path"
}'  # Create JavaScript file

alias t_json='() { 
  echo "Create JSON file.\nUsage: t_json <directory>"
  file_path="${1:-.}/main.json"
  touch $file_path
  echo "Created file $file_path"
}'  # Create JSON file

alias t_html='() { 
  echo "Create HTML file.\nUsage: t_html <directory>"
  file_path="${1:-.}/index.html"
  touch $file_path
  echo "Created file $file_path"
}'  # Create HTML file

# Batch file creation
alias cf_files='() { 
  if [ $# -eq 0 ]; then 
    echo "Create files with prefix and suffix.\nUsage: cf_files <prefix> <suffix> [count:1] [target_dir:.] [zero_padding:1]"
  else 
    file_prefix="${1}"
    file_suffix="${2}"
    file_count="${3:-1}"
    target_path="${4:-.}"
    zero_fill=${5:-1}
    
    mkdir -p $target_path
    
    for ((i=1;i<=$file_count;i++)); do
      filename="${file_prefix}$(printf "%0${zero_fill}d" $i).${file_suffix}"
      touch "${target_path}/${filename}"
      echo "Created: ${target_path}/${filename}"
    done
  fi
}'  # Create batch files with numbered sequence

# Create files based on existing files
alias tf_dir_ext_file='() { 
  if [ $# -eq 0 ]; then 
    echo "Create files with new extension based on existing files.\nUsage: tf_dir_ext_file <new_extension> [search_extension:*] [source_dir:.] [target_dir:source_dir]"
  else 
    new_suffix="${1}"
    search_suffix="${2:-*}"
    source_path="${3:-.}"
    target_path="${4:-${source_path}}"
    
    mkdir -p $target_path
    
    for source_file in "$source_path"/*.${search_suffix}; do
      if [ -e "$source_file" ]; then
        file_name_no_ext=$(basename "$source_file" .$search_suffix)
        new_file="${target_path}/${file_name_no_ext}.${new_suffix}"
        touch "$new_file"
        echo "Created: $new_file"
      fi
    done
  fi
}'  # Create files with new extension based on existing files

# Clean node_modules
alias del_nms='() {
  search_path=${1:-.}
  echo "Deleting all node_modules directories in $search_path"
  
  count=$(find $search_path -type d -name "node_modules" | wc -l)
  find $search_path -type d -name "node_modules" -exec rm -rf "{}" +
  
  echo "Deleted $count node_modules directories"
}'  # Clean up node_modules directories recursively
