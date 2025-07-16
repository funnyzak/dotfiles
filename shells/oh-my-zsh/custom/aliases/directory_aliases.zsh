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


# Help function for directory aliases
alias dir-help='() {
  echo "Directory Management Aliases Help"
  echo "=============================="
  echo "Available commands:"
  echo "  ..                - Navigate up one directory"
  echo "  ...               - Navigate up two directories"
  echo "  ~                 - Navigate to home directory"
  echo "  mkcd              - Create a directory and navigate into it"
  echo "  ll                - List files in long format with human-readable sizes"
  echo "  la                - List all files including hidden ones"
  echo "  lsa               - List all files including hidden ones in single column"
  echo "  lsdir             - List only directories"
  echo "  lsfile            - List only files in the specified directory"
  echo "  du1               - Show size of first-level subdirectories"
  echo "  du2               - Show size of second-level subdirectories"
  echo "  du3               - Show size of third-level subdirectories"
  echo "  du_sorted         - Sort directories by size"
  echo "  du_sorted2        - Sort second-level directories by size"
  echo "  dutl              - Calculate total size of a directory"
  echo "  tree1             - Display directory tree with depth 1"
  echo "  tree2             - Display directory tree with depth 2"
  echo "  tree3             - Display directory tree with depth 3"
  echo "  tree4             - Display directory tree with depth 4"
  echo "  tree5             - Display directory tree with depth 5"
  echo "  tree6             - Display directory tree with depth 6"
  echo "  watchsize         - Monitor directory size changes"
  echo "  watchdf           - Monitor disk usage"
  echo "  w_fcount          - Monitor file count in target directory"
  echo "  w_fcount_ext      - Monitor count of files with specific extension"
  echo "  directory-help    - Display this help message"
}' # Display help for directory management aliases
