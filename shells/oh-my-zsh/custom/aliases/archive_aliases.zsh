# Description: Advanced compression and extraction aliases for ZIP, TAR and other archive formats. Provides intuitive shortcuts for common archive operations.

# =========================
# ZIP Compression Aliases
# =========================

alias zip_cur='() { 
  echo "Compressing current directory to a ZIP file.\nUsage:\n zip_cur [output_filename]"
  zip_name=${1:-$(basename $(pwd)).zip}
  echo "Creating archive: $zip_name"
  zip -x "*.DS_Store" -r -q -9 "$zip_name" . && 
  echo "Compression completed, saved to $zip_name" 
}'  # Compress current directory to a ZIP file

alias zip_dir='() {
  if [ $# -eq 0 ]; then
    echo "Compress a directory to a ZIP file.\nUsage:\n zip_dir <directory_path> [output_filename]"
    return 1
  fi
  zip_path=${1}
  if [ ! -d "$zip_path" ]; then
    echo "Error: Directory $zip_path does not exist"
    return 1
  fi
  zip_name=${2:-$(basename ${zip_path}).zip}
  echo "Creating archive: $zip_name from directory: $zip_path"
  zip -x "*.DS_Store" -r -q -9 "$zip_name" "$zip_path" && 
  echo "Compression completed, saved to $zip_name"
}'  # Compress a specific directory to a ZIP file

alias zip_dirp='() { 
  if [ $# -lt 2 ]; then
    echo "Compress a directory with password protection.\nUsage:\n zip_dirp <directory_path> <password> [output_filename]"
    return 1
  fi
  zip_path=${1}
  if [ ! -d "$zip_path" ]; then
    echo "Error: Directory $zip_path does not exist"
    return 1
  fi
  zip_name=${3:-$(basename ${zip_path}).zip}
  echo "Creating password-protected archive: $zip_name from directory: $zip_path"
  zip -x "*.DS_Store" -r -q -9 -P "$2" "$zip_name" "$zip_path" && 
  echo "Compression completed, saved to $zip_name"
}'  # Compress a directory with password protection

alias zip_ext='() {
  if [ $# -eq 0 ]; then
    echo "Compress all files with specific extension.\nUsage:\n zip_ext <file_extension> [target_directory]"
    return 1
  fi
  ext=${1}
  zip_path=${2:-.}
  if [ ! -d "$zip_path" ]; then
    echo "Error: Directory $zip_path does not exist"
    return 1
  fi
  echo "Compressing all .$ext files in $zip_path"
  
  # Save current directory
  current_dir=$(pwd)
  
  # Change to target directory
  cd "$zip_path" || return 1
  
  # Check if any matching files exist
  if [ -z "$(find . -type f -name "*.${ext}" -print -quit)" ]; then
    echo "Warning: No files with extension .$ext found in $zip_path"
    cd "$current_dir"
    return 1
  fi
  
  # Search and compress
  find . -type f -name "*.${ext}" -print | xargs zip -r -q -9 "${ext}.zip" && 
  echo "Compression completed, saved to $zip_path/${ext}.zip"
  
  # Return to original directory
  cd "$current_dir"
}'  # Compress all files with specific extension

alias zip_sub='() { 
  echo "Compress each subdirectory to separate ZIP files.\nUsage:\n zip_sub [parent_directory]"
  target_dir=${1:-.}
  if [ ! -d "$target_dir" ]; then
    echo "Error: Directory $target_dir does not exist"
    return 1
  fi
  echo "Compressing all subdirectories in $target_dir"
  
  # Save current directory
  current_dir=$(pwd)
  
  # Change to target directory
  cd "$target_dir" || return 1
  
  # Check if any subdirectories exist
  if [ -z "$(ls -d ./*/ 2>/dev/null)" ]; then
    echo "Warning: No subdirectories found in $target_dir"
    cd "$current_dir"
    return 1
  fi
  
  # Process each subdirectory
  for dir in $(ls -d ./*/); do 
    timestamp=$(date +%Y%m%d%H%M%S)
    archive_name="./$(basename "$dir")_${timestamp}.zip"
    echo "Compressing directory: $(basename "$dir") to $archive_name"
    (zip -x "*.DS_Store" -r -q "$archive_name" "${dir}"* && 
    echo "Successfully compressed to $archive_name")
  done
  
  # Return to original directory
  cd "$current_dir"
}'  # Compress each subdirectory to separate ZIP files

alias zip_each='() { 
  echo "Compress each file in a directory to separate ZIP files.\nUsage:\n zip_each [directory_path]"
  target_dir=${1:-.}
  if [ ! -d "$target_dir" ]; then
    echo "Error: Directory $target_dir does not exist"
    return 1
  fi
  echo "Compressing each file in $target_dir"
  
  # Save current directory
  current_dir=$(pwd)
  
  # Change to target directory
  cd "$target_dir" || return 1
  
  # Check if any files exist
  if [ -z "$(ls 2>/dev/null)" ]; then
    echo "Warning: No files found in $target_dir"
    cd "$current_dir"
    return 1
  fi
  
  # Compress each file
  compressed_count=0
  for file in $(ls); do 
    # Skip directories and existing zip files
    if [ -f "$file" ] && [[ "$file" != *.zip ]]; then
      archive_name="./$(basename "$file").zip"
      echo "Compressing file: $file to $archive_name"
      (zip -x "*.DS_Store" -r -q "$archive_name" "$file" && 
      echo "Successfully compressed to $archive_name")
      ((compressed_count++))
    fi
  done
  
  if [ $compressed_count -eq 0 ]; then
    echo "No suitable files found for compression"
  else
    echo "Completed compressing $compressed_count files"
  fi
  
  # Return to original directory
  cd "$current_dir"
}'  # Compress each file in a directory to separate ZIP files

alias zip_each_with_date='() { 
  echo "Compress each file with timestamp in filename.\nUsage:\n zip_each_with_date [directory_path]"
  target_dir=${1:-.}
  if [ ! -d "$target_dir" ]; then
    echo "Error: Directory $target_dir does not exist"
    return 1
  fi
  echo "Compressing each file with timestamp in $target_dir"
  
  # Save current directory
  current_dir=$(pwd)
  
  # Change to target directory
  cd "$target_dir" || return 1
  
  # Check if any files exist
  if [ -z "$(ls 2>/dev/null)" ]; then
    echo "Warning: No files found in $target_dir"
    cd "$current_dir"
    return 1
  fi
  
  # Compress each file with timestamp
  compressed_count=0
  for file in $(ls); do 
    # Skip directories and existing zip files
    if [ -f "$file" ] && [[ "$file" != *.zip ]]; then
      timestamp=$(date +%Y%m%d%H%M%S)
      archive_name="./$(basename "$file")_${timestamp}.zip"
      echo "Compressing file: $file to $archive_name"
      (zip -x "*.DS_Store" -r -q "$archive_name" "$file" && 
      echo "Successfully compressed to $archive_name")
      ((compressed_count++))
    fi
  done
  
  if [ $compressed_count -eq 0 ]; then
    echo "No suitable files found for compression"
  else
    echo "Completed compressing $compressed_count files with timestamps"
  fi
  
  # Return to original directory
  cd "$current_dir"
}'  # Compress each file with timestamp in filename

alias zip_each_with_pwd='() { 
  echo "Compress each file with password protection.\nUsage:\n zip_each_with_pwd [directory_path] [password]"
  dir_path=${1:-.}
  if [ ! -d "$dir_path" ]; then
    echo "Error: Directory $dir_path does not exist"
    return 1
  fi
  
  # Save current directory
  current_dir=$(pwd)
  
  # Change to target directory
  cd "$dir_path" || return 1
  
  # Check if any files exist
  if [ -z "$(ls 2>/dev/null)" ]; then
    echo "Warning: No files found in $dir_path"
    cd "$current_dir"
    return 1
  fi
  
  echo "Compressing files with password protection in $dir_path"
  
  # Create or clear password file
  echo "Filename:Password" > password.txt
  
  # Compress each file with password
  compressed_count=0
  for file in $(ls); do
    # Skip password file, directories, and existing zip files
    if [ "$file" = "password.txt" ] || [ ! -f "$file" ] || [[ "$file" == *.zip ]]; then
      continue
    fi
    
    # Generate random password if not provided
    if [ -z "$2" ]; then
      pwd=$(openssl rand -base64 8)
    else
      pwd=$2
    fi
    
    archive_name="./$(basename "$file").zip"
    echo "Compressing file: $file to $archive_name with password"
    
    # Use password to compress file
    zip -x "*.DS_Store" -r -q -P "$pwd" "$archive_name" "$file" && 
    echo "Successfully compressed to $archive_name with password: $pwd"
    
    # Save filename and password to password.txt
    echo "$(basename "$file").zip:$pwd" >> password.txt
    ((compressed_count++))
  done
  
  if [ $compressed_count -eq 0 ]; then
    echo "No suitable files found for compression"
    rm password.txt
  else
    echo "Completed compressing $compressed_count files with password protection"
    echo "Passwords have been saved to $dir_path/password.txt"
  fi
  
  # Return to original directory
  cd "$current_dir"
}'  # Compress each file with password protection

# Single File ZIP Compression
alias zip_single='() { 
  if [ $# -eq 0 ]; then 
    echo "Compress a single file to ZIP format.\nUsage:\n zip_single <file_path> [output_filename]"
    return 1
  fi
  
  zip_path=${1}
  if [ ! -f "$zip_path" ]; then
    echo "Error: File $zip_path does not exist or is not a regular file"
    return 1
  fi
  
  zip_dir=$(dirname "$zip_path")
  file_name=$(basename "$zip_path")
  zip_name=${2:-${file_name}.zip}
  
  echo "Compressing file: $file_name to $zip_name"
  
  # Save current directory
  current_dir=$(pwd)
  
  cd "$zip_dir" || return 1
  
  zip -x "*.DS_Store" -r -q -9 "$zip_name" "$file_name" && 
  echo "Compression completed, saved to $zip_dir/$zip_name"
  
  # Return to original directory
  cd "$current_dir"
}'  # Compress a single file to ZIP format

alias zip_singlep='() { 
  if [ $# -lt 2 ]; then 
    echo "Compress a single file with password protection.\nUsage:\n zip_singlep <file_path> <password> [output_filename]"
    return 1
  fi
  
  zip_path=${1}
  if [ ! -f "$zip_path" ]; then
    echo "Error: File $zip_path does not exist or is not a regular file"
    return 1
  fi
  
  zip_dir=$(dirname "$zip_path")
  file_name=$(basename "$zip_path")
  zip_name=${3:-${file_name}.zip}
  
  echo "Compressing file: $file_name to $zip_name with password protection"
  
  # Save current directory
  current_dir=$(pwd)
  
  cd "$zip_dir" || return 1
  
  zip -x "*.DS_Store" -r -q -9 -P "$2" "$zip_name" "$file_name" && 
  echo "Compression completed, saved to $zip_dir/$zip_name"
  
  # Return to original directory
  cd "$current_dir"
}'  # Compress a single file with password protection

# =========================
# ZIP Extraction Aliases
# =========================

alias unzip_file='() { 
  if [ $# -eq 0 ]; then
    echo "Extract a ZIP file.\nUsage:\n unzip_file <zip_file> [destination_path]"
    return 1
  fi
  
  unzip_name=${1}
  if [ ! -f "$unzip_name" ]; then
    echo "Error: File $unzip_name does not exist or is not a regular file"
    return 1
  fi
  
  unzip_path=${2:-$(dirname "$unzip_name")}
  if [ ! -d "$unzip_path" ]; then
    echo "Creating destination directory: $unzip_path"
    mkdir -p "$unzip_path"
  fi
  
  echo "Extracting: $unzip_name to $unzip_path"
  unzip -q "$unzip_name" -d "$unzip_path" && 
  echo "Extraction completed, files extracted to $unzip_path"
}'  # Extract a ZIP file

alias unzip_each='() { 
  echo "Extract all ZIP files in a directory.\nUsage:\n unzip_each [directory_path]"
  target_dir=${1:-.}
  if [ ! -d "$target_dir" ]; then
    echo "Error: Directory $target_dir does not exist"
    return 1
  fi
  
  # Save current directory
  current_dir=$(pwd)
  
  # Change to target directory
  cd "$target_dir" || return 1
  
  # Check if any zip files exist
  if [ -z "$(ls *.zip 2>/dev/null)" ]; then
    echo "Warning: No ZIP files found in $target_dir"
    cd "$current_dir"
    return 1
  fi
  
  echo "Extracting all ZIP files in $target_dir"
  extracted_count=0
  
  for file in $(ls *.zip 2>/dev/null); do 
    dir_name=$(basename "$file" .zip)
    echo "Extracting: $file to ./$dir_name"
    mkdir -p "./$dir_name"
    unzip -q "$file" -d "./$dir_name" && 
    echo "Successfully extracted to ./$dir_name"
    ((extracted_count++))
  done
  
  echo "Completed extracting $extracted_count ZIP files"
  
  # Return to original directory
  cd "$current_dir"
}'  # Extract all ZIP files in a directory

alias unzip_pwd='() { 
  if [ $# -lt 2 ]; then
    echo "Extract a password-protected ZIP file.\nUsage:\n unzip_pwd <zip_file> <password> [destination_path]"
    return 1
  fi
  
  unzip_name=${1}
  if [ ! -f "$unzip_name" ]; then
    echo "Error: File $unzip_name does not exist or is not a regular file"
    return 1
  fi
  
  unzip_path=${3:-$(dirname "$unzip_name")}
  if [ ! -d "$unzip_path" ]; then
    echo "Creating destination directory: $unzip_path"
    mkdir -p "$unzip_path"
  fi
  
  echo "Extracting password-protected: $unzip_name to $unzip_path"
  unzip -q -P "$2" "$unzip_name" -d "$unzip_path" && 
  echo "Extraction completed, files extracted to $unzip_path"
}'  # Extract a password-protected ZIP file

# =========================
# TAR Compression Aliases
# =========================

alias tar_cur='() { 
  echo "Compress current directory with tar.\nUsage:\n tar_cur [output_filename]"
  tar_name=${1:-$(basename $(pwd)).tar.gz}
  
  echo "Creating tar archive: $tar_name"
  tar -czf "$tar_name" . && 
  echo "Compression completed, saved to $tar_name"
}'  # Compress current directory with tar

alias tar_dir='() { 
  if [ $# -eq 0 ]; then 
    echo "Compress a directory with tar.\nUsage:\n tar_dir <directory_path> [output_filename]"
    return 1
  fi
  
  tar_path=${1}
  if [ ! -d "$tar_path" ]; then
    echo "Error: Directory $tar_path does not exist"
    return 1
  fi
  
  tar_name=${2:-$(basename ${tar_path}).tar.gz}
  
  echo "Creating tar archive: $tar_name from directory: $tar_path"
  tar -czf "$tar_name" "$tar_path" && 
  echo "Compression completed, saved to $tar_name"
}'  # Compress a directory with tar

alias tar_ext='() {
  if [ $# -eq 0 ]; then
    echo "Compress all files with specific extension using tar.\nUsage:\n tar_ext <file_extension> [target_directory]"
    return 1
  fi
  
  ext=${1}
  tar_path=${2:-.}
  if [ ! -d "$tar_path" ]; then
    echo "Error: Directory $tar_path does not exist"
    return 1
  fi
  
  echo "Compressing all .$ext files in $tar_path"
  
  # Save current directory
  current_dir=$(pwd)
  
  # Change to target directory
  cd "$tar_path" || return 1
  
  # Check if any matching files exist
  if [ -z "$(find . -type f -name "*.${ext}" -print -quit)" ]; then
    echo "Warning: No files with extension .$ext found in $tar_path"
    cd "$current_dir"
    return 1
  fi
  
  # Search and compress
  find . -type f -name "*.${ext}" -print | xargs tar -czf "${ext}.tar.gz" && 
  echo "Compression completed, saved to $tar_path/${ext}.tar.gz"
  
  # Return to original directory
  cd "$current_dir"
}'  # Compress all files with specific extension using tar

alias tar_sub='() { 
  echo "Compress each subdirectory to separate tar archives.\nUsage:\n tar_sub [parent_directory]"
  target_dir=${1:-.}
  if [ ! -d "$target_dir" ]; then
    echo "Error: Directory $target_dir does not exist"
    return 1
  fi
  
  echo "Compressing all subdirectories in $target_dir"
  
  # Save current directory
  current_dir=$(pwd)
  
  # Change to target directory
  cd "$target_dir" || return 1
  
  # Check if any subdirectories exist
  if [ -z "$(ls -d ./*/ 2>/dev/null)" ]; then
    echo "Warning: No subdirectories found in $target_dir"
    cd "$current_dir"
    return 1
  fi
  
  # Process each subdirectory
  for dir in $(ls -d ./*/); do 
    timestamp=$(date +%Y%m%d%H%M%S)
    archive_name="./$(basename "$dir")_${timestamp}.tar.gz"
    echo "Compressing directory: $(basename "$dir") to $archive_name"
    (tar -czf "$archive_name" "${dir}"* && 
    echo "Successfully compressed to $archive_name")
  done
  
  # Return to original directory
  cd "$current_dir"
}'  # Compress each subdirectory to separate tar archives

alias tar_each='() { 
  echo "Compress each file in a directory to separate tar archives.\nUsage:\n tar_each [directory_path]"
  target_dir=${1:-.}
  if [ ! -d "$target_dir" ]; then
    echo "Error: Directory $target_dir does not exist"
    return 1
  fi
  
  echo "Compressing each file in $target_dir"
  
  # Save current directory
  current_dir=$(pwd)
  
  # Change to target directory
  cd "$target_dir" || return 1
  
  # Check if any files exist
  if [ -z "$(ls 2>/dev/null)" ]; then
    echo "Warning: No files found in $target_dir"
    cd "$current_dir"
    return 1
  fi
  
  # Compress each file
  compressed_count=0
  for file in $(ls); do 
    # Skip directories and existing tar.gz files
    if [ -f "$file" ] && [[ "$file" != *.tar.gz ]]; then
      timestamp=$(date +%Y%m%d%H%M%S)
      archive_name="./$(basename "$file")_${timestamp}.tar.gz"
      echo "Compressing file: $file to $archive_name"
      (tar -czf "$archive_name" "$file" && 
      echo "Successfully compressed to $archive_name")
      ((compressed_count++))
    fi
  done
  
  if [ $compressed_count -eq 0 ]; then
    echo "No suitable files found for compression"
  else
    echo "Completed compressing $compressed_count files"
  fi
  
  # Return to original directory
  cd "$current_dir"
}'  # Compress each file in a directory to separate tar archives

alias tar_single='() { 
  if [ $# -eq 0 ]; then 
    echo "Compress a single file with tar.\nUsage:\n tar_single <file_path> [output_filename]"
    return 1
  fi
  
  tar_path=${1}
  if [ ! -f "$tar_path" ]; then
    echo "Error: File $tar_path does not exist or is not a regular file"
    return 1
  fi
  
  tar_dir=$(dirname "$tar_path")
  file_name=$(basename "$tar_path")
  tar_name=${2:-${file_name}.tar.gz}
  
  echo "Compressing file: $file_name to $tar_name"
  
  current_dir=$(pwd)
  
  cd "$tar_dir" || return 1
  
  tar -czf "$tar_name" "$file_name" && 
  echo "Compression completed, saved to $tar_dir/$tar_name"
  
  # Return to original directory
  cd "$current_dir"
}'  # Compress a single file with tar

# =========================
# TAR Extraction Aliases
# =========================

alias untar='() { 
  if [ $# -eq 0 ]; then
    echo "Extract a tar archive.\nUsage:\n untar <tar_file> [destination_path]"
    return 1
  fi
  
  untar_name=${1}
  if [ ! -f "$untar_name" ]; then
    echo "Error: File $untar_name does not exist or is not a regular file"
    return 1
  fi
  
  untar_path=${2:-$(dirname "$untar_name")}
  if [ ! -d "$untar_path" ]; then
    echo "Creating destination directory: $untar_path"
    mkdir -p "$untar_path"
  fi
  
  echo "Extracting: $untar_name to $untar_path"
  tar -xzf "$untar_name" -C "$untar_path" && 
  echo "Extraction completed, files extracted to $untar_path"
}'  # Extract a tar archive

alias untar_each='() {
  echo "Extract all tar archives in a directory.\nUsage:\n untar_each [directory_path]"
  target_dir=${1:-.}
  if [ ! -d "$target_dir" ]; then
    echo "Error: Directory $target_dir does not exist"
    return 1
  fi
  
  # Save current directory
  current_dir=$(pwd)
  
  # Change to target directory
  cd "$target_dir" || return 1
  
  # Check if any tar files exist
  if [ -z "$(ls *.tar.gz 2>/dev/null)" ]; then
    if [ -z "$(ls *.tgz 2>/dev/null)" ]; then
      echo "Warning: No tar archives found in $target_dir"
      cd "$current_dir"
      return 1
    fi
  fi
  
  echo "Extracting all tar archives in $target_dir"
  extracted_count=0
  
  # Extract .tar.gz files
  for file in $(ls *.tar.gz 2>/dev/null); do 
    dir_name=$(basename "$file" .tar.gz)
    echo "Extracting: $file to ./$dir_name"
    mkdir -p "./$dir_name"
    tar -xzf "$file" -C "./$dir_name" && 
    echo "Successfully extracted to ./$dir_name"
    ((extracted_count++))
  done
  
  # Extract .tgz files
  for file in $(ls *.tgz 2>/dev/null); do 
    dir_name=$(basename "$file" .tgz)
    echo "Extracting: $file to ./$dir_name"
    mkdir -p "./$dir_name"
    tar -xzf "$file" -C "./$dir_name" && 
    echo "Successfully extracted to ./$dir_name"
    ((extracted_count++))
  done
  
  echo "Completed extracting $extracted_count tar archives"
  
  # Return to original directory
  cd "$current_dir"
}'  # Extract all tar archives in a directory

# =========================
# General Archive Utilities
# =========================

alias extract='() {
  if [ $# -eq 0 ]; then
    echo "Extract any supported archive file.\nUsage:\n extract <archive_file> [destination_path]"
    return 1
  fi
  
  archive_file=${1}
  if [ ! -f "$archive_file" ]; then
    echo "Error: File $archive_file does not exist or is not a regular file"
    return 1
  fi
  
  extract_path=${2:-$(dirname "$archive_file")}
  if [ ! -d "$extract_path" ]; then
    echo "Creating destination directory: $extract_path"
    mkdir -p "$extract_path"
  fi
  
  echo "Extracting: $archive_file to $extract_path"
  
  case $archive_file in
    *.tar.bz2)   tar -xjf "$archive_file" -C "$extract_path" ;;
    *.tar.gz)    tar -xzf "$archive_file" -C "$extract_path" ;;
    *.tar.xz)    tar -xJf "$archive_file" -C "$extract_path" ;;
    *.bz2)       bunzip2 -k "$archive_file" ;;
    *.rar)       unrar x "$archive_file" "$extract_path" ;;
    *.gz)        gunzip -k "$archive_file" ;;
    *.tar)       tar -xf "$archive_file" -C "$extract_path" ;;
    *.tbz2)      tar -xjf "$archive_file" -C "$extract_path" ;;
    *.tgz)       tar -xzf "$archive_file" -C "$extract_path" ;;
    *.zip)       unzip -q "$archive_file" -d "$extract_path" ;;
    *.Z)         uncompress "$archive_file" ;;
    *.7z)        7z x "$archive_file" -o"$extract_path" ;;
    *)           echo "Error: $archive_file cannot be extracted via extract" && return 1 ;;
  esac
  
  echo "Extraction completed, files extracted to $extract_path"
}'  # Extract any supported archive file

alias archive_info='() {
  if [ $# -eq 0 ]; then
    echo "Display information about an archive file.\nUsage:\n archive_info <archive_file>"
    return 1
  fi
  
  archive_file=${1}
  if [ ! -f "$archive_file" ]; then
    echo "Error: File $archive_file does not exist or is not a regular file"
    return 1
  fi
  
  echo "Archive information for: $archive_file"
  echo "----------------------------------------"
  
  case $archive_file in
    *.tar.bz2|*.tbz2)   echo "Type: TAR+BZIP2"; tar -tjf "$archive_file" | sort ;;
    *.tar.gz|*.tgz)     echo "Type: TAR+GZIP"; tar -tzf "$archive_file" | sort ;;
    *.tar.xz)           echo "Type: TAR+XZ"; tar -tJf "$archive_file" | sort ;;
    *.tar)              echo "Type: TAR"; tar -tf "$archive_file" | sort ;;
    *.zip)              echo "Type: ZIP"; unzip -l "$archive_file" ;;
    *.rar)              echo "Type: RAR"; unrar l "$archive_file" ;;
    *.7z)               echo "Type: 7-Zip"; 7z l "$archive_file" ;;
    *)                  echo "Error: Unsupported archive format" && return 1 ;;
  esac
  
  echo "----------------------------------------"
  file_size=$(du -h "$archive_file" | cut -f1)
  echo "Archive size: $file_size"
}'  # Display information about an archive file

# Set aliases compatible with non-macOS systems
if [ "$(uname)" != "Darwin" ]; then
  # Override the unzip function for Linux systems
  alias unzip='unzip_file'
fi
