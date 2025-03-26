# Description: Directory navigation and file listing aliases for efficient filesystem operations.

# 目录导航
alias ..='() { 
  echo "Navigate up one directory.\nUsage:\n .."
  cd ..
}'  # Navigate up one directory
alias ...='() { 
  echo "Navigate up two directories.\nUsage:\n ..."
  cd ../..
}'  # Navigate up two directories
alias ~='() { 
  echo "Navigate to home directory.\nUsage:\n ~"
  cd ~
}'  # Navigate to home directory

# 创建并进入文件夹
alias mkcd='() {
  if [ $# -eq 0 ]; then
    echo "Create a directory and navigate into it.\nUsage:\n mkcd <directory_name>"
    return 0
  fi
  mkdir -p "$1" && cd "$1"
}'  # Create a directory and navigate into it

# 列表显示
alias ll='() { 
  echo "List files in long format with human-readable sizes.\nUsage:\n ll [directory_path]"
  ls -lh ${@:-./}
}'  # List files in long format with human-readable sizes
alias la='() { 
  echo "List all files including hidden ones.\nUsage:\n la [directory_path]" 
  ls -lah ${@:-./}
}'  # List all files including hidden ones
alias lsa='() { 
  echo "List all files including hidden ones in single column.\nUsage:\n lsa [directory_path]"
  ls -1lah ${@:-./}
}'  # List all files including hidden ones in single column
alias lsdir='() { 
  echo "List only directories.\nUsage:\n lsdir [directory_path]"
  ls -1d ${1:-./}*/
}'  # List only directories
alias lsfile='() { 
  echo "List only files in the specified directory.\nUsage:\n lsfile [directory_path]"
  ls -1p ${1:-./} | grep -v /
}'  # List only files

# 详细列表显示
alias du1='() {
  echo "Show size of first-level subdirectories.\nUsage:\n du1 [directory_path]"
  du_path=${1:-.}
  if [ "$(uname)" = "Darwin" ]; then
    du -h -d 1 "$du_path"
  else
    du -h --max-depth=1 "$du_path"
  fi
}'  # Show size of first-level subdirectories
alias du2='() {
  echo "Show size of second-level subdirectories.\nUsage:\n du2 [directory_path]"
  du_path=${1:-.}
  if [ "$(uname)" = "Darwin" ]; then
    du -h -d 2 "$du_path"
  else
    du -h --max-depth=2 "$du_path"
  fi
}'  # Show size of second-level subdirectories
alias du3='() {
  echo "Show size of third-level subdirectories.\nUsage:\n du3 [directory_path]"
  du_path=${1:-.}
  if [ "$(uname)" = "Darwin" ]; then
    du -h -d 3 "$du_path"
  else
    du -h --max-depth=3 "$du_path"
  fi
}'  # Show size of third-level subdirectories

# 按大小排序
alias du_sorted='() {
  echo "Sort directories by size.\nUsage:\n du_sorted [directory_path]"
  du_path=${1:-.}
  if [ "$(uname)" = "Darwin" ]; then
    du -h -d 1 "$du_path" | sort -hr
  else
    du -h --max-depth=1 "$du_path" | sort -hr
  fi
}'  # Sort directories by size
alias du_sorted2='() {
  echo "Sort second-level directories by size.\nUsage:\n du_sorted2 [directory_path]"
  du_path=${1:-.}
  if [ "$(uname)" = "Darwin" ]; then
    du -h -d 2 "$du_path" | sort -hr
  else
    du -h --max-depth=2 "$du_path" | sort -hr
  fi
}'  # Sort second-level directories by size

# 目录大小统计
alias dutl='() {
  echo "Calculate total size of a directory.\nUsage:\n dutl [directory_path]"
  du -sh ${@:-./}
}'  # Calculate total size of a directory

# 目录树显示
alias tree1='() {
  echo "Display directory tree with depth 1.\nUsage:\n tree1 [directory_path]"
  tree -L 1 ${@:-./}
}'  # Display directory tree with depth 1
alias tree2='() {
  echo "Display directory tree with depth 2.\nUsage:\n tree2 [directory_path]"
  tree -L 2 ${@:-./}
}'  # Display directory tree with depth 2
alias tree3='() {
  echo "Display directory tree with depth 3.\nUsage:\n tree3 [directory_path]"
  tree -L 3 ${@:-./}
}'  # Display directory tree with depth 3
alias tree4='() {
  echo "Display directory tree with depth 4.\nUsage:\n tree4 [directory_path]"
  tree -L 4 ${@:-./}
}'  # Display directory tree with depth 4
alias tree5='() {
  echo "Display directory tree with depth 5.\nUsage:\n tree5 [directory_path]"
  tree -L 5 ${@:-./}
}'  # Display directory tree with depth 5
alias tree6='() {
  echo "Display directory tree with depth 6.\nUsage:\n tree6 [directory_path]"
  tree -L 6 ${@:-./}
}'  # Display directory tree with depth 6

# 监视目录变化
alias watchsize='() {
  echo "Monitor directory size changes.\nUsage:\n watchsize [directory_path]"
  watch -d -n 1 du -sh ${@:-./}
}'  # Monitor directory size changes
alias watchdf='() {
  echo "Monitor disk usage.\nUsage:\n watchdf"
  watch -d -n 1 df -h
}'  # Monitor disk usage
alias w_fcount='() {
  if [ $# -eq 0 ]; then
    echo "Monitor file count in target directory.\nUsage:\n w_fcount <target_directory> [interval_seconds]"
    return 0
  fi
  target_dir="${1}"
  interval="${2:-1}"
  echo "Monitoring file count in directory: $target_dir (updating every $interval seconds)"
  watch -n "$interval" "find \"$target_dir\" -type f -print | wc -l | xargs echo \"File count => \""
}'  # Monitor file count in target directory
alias w_fcount_ext='() {
  if [ $# -eq 0 ]; then
    echo "Monitor count of files with specific extension.\nUsage:\n w_fcount_ext <file_extension> [target_directory] [interval_seconds]"
    return 0
  fi
  file_ext="${1}"
  target_dir="${2:-./}"
  interval="${3:-1}"
  echo "Monitoring count of files with .$file_ext extension in directory: $target_dir (updating every $interval seconds)"
  watch -n "$interval" "find \"$target_dir\" -type f -name \"*.$file_ext\" -print | wc -l | xargs echo \"File count => \""
}'  # Monitor count of files with specific extension

# 文件查看
alias less='() {
  echo "View file with less pager.\nUsage:\n less <file_path>"
  command less "$@"
}'  # View file with less pager
alias more='() {
  echo "View file with more pager.\nUsage:\n more <file_path>"
  command more "$@"
}'  # View file with more pager
alias cat='() {
  echo "Display file content.\nUsage:\n cat <file_path>"
  command cat "$@"
}'  # Display file content
alias log='() {
  echo "Display last 300 lines of file and follow updates.\nUsage:\n log <file_path>"
  tail -f -n 300 "$@"
}'  # Display last 300 lines of file and follow updates
alias log100='() {
  echo "Display last 100 lines of file and follow updates.\nUsage:\n log100 <file_path>"
  tail -f -n 100 "$@"
}'  # Display last 100 lines of file and follow updates
alias log200='() {
  echo "Display last 200 lines of file and follow updates.\nUsage:\n log200 <file_path>"
  tail -f -n 200 "$@"
}'  # Display last 200 lines of file and follow updates
alias log500='() {
  echo "Display last 500 lines of file and follow updates.\nUsage:\n log500 <file_path>"
  tail -f -n 500 "$@"
}'  # Display last 500 lines of file and follow updates
alias log1000='() {
  echo "Display last 1000 lines of file and follow updates.\nUsage:\n log1000 <file_path>"
  tail -f -n 1000 "$@"
}'  # Display last 1000 lines of file and follow updates

# 文件编辑
alias vim='() {
  echo "Edit file with vim.\nUsage:\n vim <file_path>"
  command vim "$@"
}'  # Edit file with vim
alias vi='() {
  echo "Edit file with vi.\nUsage:\n vi <file_path>"
  command vi "$@"
}'  # Edit file with vi

# 文件模板创建
alias t_md='() { 
  echo "Create README.md file.\nUsage:\n t_md [directory_path]"
  file_path="${1:-.}/README.md"
  touch "$file_path" && echo "Created file: $file_path"
}'  # Create README.md file
alias t_txt='() { 
  echo "Create README.txt file.\nUsage:\n t_txt [directory_path]"
  file_path="${1:-.}/README.txt"
  touch "$file_path" && echo "Created file: $file_path"
}'  # Create README.txt file
alias t_py='() { 
  echo "Create Python file.\nUsage:\n t_py [directory_path]"
  file_path="${1:-.}/main.py"
  touch "$file_path" && echo "Created file: $file_path"
}'  # Create Python file
alias t_sh='() { 
  echo "Create executable Shell script.\nUsage:\n t_sh [directory_path]"
  file_path="${1:-.}/main.sh"
  touch "$file_path" && echo "Created file: $file_path" 
  chmod +x "$file_path"
  echo "Made file executable"
}'  # Create executable Shell script
alias t_js='() { 
  echo "Create JavaScript file.\nUsage:\n t_js [directory_path]"
  file_path="${1:-.}/main.js"
  touch "$file_path" && echo "Created file: $file_path"
}'  # Create JavaScript file
alias t_json='() { 
  echo "Create JSON file.\nUsage:\n t_json [directory_path]"
  file_path="${1:-.}/main.json"
  touch "$file_path" && echo "Created file: $file_path"
}'  # Create JSON file
alias t_html='() { 
  echo "Create HTML file.\nUsage:\n t_html [directory_path]"
  file_path="${1:-.}/index.html"
  touch "$file_path" && echo "Created file: $file_path"
}'  # Create HTML file

# 批量文件创建
alias cf_files='() { 
  if [ $# -eq 0 ]; then 
    echo "Create multiple files with specified prefix and suffix.\nUsage:\n cf_files <file_prefix> <file_suffix> [file_count] [target_path] [zero_padding]"
    return 0
  fi 
  file_prefix="${1}"
  file_suffix="${2}"
  file_count="${3:-1}"
  target_path="${4:-.}"
  zero_fill=${5:-4}
  
  echo "Creating $file_count files with prefix '$file_prefix' and suffix '.$file_suffix' in $target_path"
  mkdir -p "$target_path"
  for ((i=1;i<=$file_count;i++)); do 
    fileName="${target_path}/${file_prefix}$(printf "%0${zero_fill}d" $i).${file_suffix}"
    touch "$fileName"
    echo "Created: $fileName"
  done
}'  # Create multiple files with specified prefix and suffix
alias tf_dir_ext_file='() { 
  if [ $# -eq 0 ]; then 
    echo "Create files with new extension based on existing files.\nUsage:\n tf_dir_ext_file <new_extension> [search_extension] [source_path] [target_path]"
    return 0
  fi 
  new_suffix="${1}"
  search_suffix="${2:-*}"
  source_path="${3:-.}"
  target_path="${4:-${source_path}}"
  
  echo "Creating files with .$new_suffix extension based on .$search_suffix files in $source_path"
  mkdir -p "$target_path"
  for source_file in "$source_path"/*.${search_suffix}; do 
    if [ -e "$source_file" ]; then 
      file_name_no_ext=$(basename "$source_file" .$search_suffix)
      new_file="${target_path}/${file_name_no_ext}.${new_suffix}"
      touch "$new_file"
      echo "Created: $new_file"
    fi
  done
}'  # Create files with new extension based on existing files