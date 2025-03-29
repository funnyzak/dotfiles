# Description: Advanced compression and extraction aliases for ZIP, TAR and other archive formats. Provides intuitive shortcuts for common archive operations.

# ==========================
# Common Utility Functions
# ==========================

# Utility function to validate directory
_archive_validate_dir() {
  local dir="$1"
  local error_msg="${2:-Directory}"
  if [ ! -d "$dir" ]; then
    echo "Error: $error_msg $dir does not exist" >&2
    return 1
  fi
  return 0
}

# Utility function to validate file
_archive_validate_file() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "Error: File $file does not exist or is not a regular file" >&2
    return 1
  fi
  return 0
}

# Utility function to change directory and remember original
_archive_pushd() {
  local target_dir="$1"
  export _ARCHIVE_PREV_DIR=$(pwd)
  cd "$target_dir" || { echo "Error: Cannot change directory to $target_dir" >&2; return 1; }
  return 0
}

# Utility function to return to original directory
_archive_popd() {
  if [ -n "$_ARCHIVE_PREV_DIR" ]; then
    cd "$_ARCHIVE_PREV_DIR" || { echo "Error: Cannot return to previous directory $_ARCHIVE_PREV_DIR" >&2; return 1; }
    unset _ARCHIVE_PREV_DIR
  fi
  return 0
}

# Utility function for common zip options
_archive_zip_opts() {
  echo "-x \"*.DS_Store\" -r -q -9"
}

# Utility function for common tar options
_archive_tar_opts() {
  echo "--exclude=\"*.DS_Store\""
}

# Utility function to select compression option
_archive_tar_compress_opt() {
  local format="${1:-gz}"
  case "$format" in
    gz|gzip)  echo "-z" ;;
    bz2|bzip) echo "-j" ;;
    xz)       echo "-J" ;;
    *)        echo "-z" ;; # Default to gzip
  esac
}

# Utility function to get file extension for tar format
_archive_tar_extension() {
  local format="${1:-gz}"
  case "$format" in
    gz|gzip)  echo "tar.gz" ;;
    bz2|bzip) echo "tar.bz2" ;;
    xz)       echo "tar.xz" ;;
    *)        echo "tar.gz" ;; # Default to .tar.gz
  esac
}

# ==========================
# Core ZIP Functions
# ==========================

# Unified ZIP compression function
alias zip-utils='() {
  local usage="ZIP utilities for compressing files and directories.
Available commands:
  zip-utils dir <directory> [output_name] [-p password] [-t]     - Compress directory
  zip-utils file <file> [output_name] [-p password] [-t]         - Compress single file
  zip-utils cur [output_name] [-p password] [-t]                 - Compress current directory
  zip-utils ext <extension> [target_dir] [-p password] [-t]      - Compress files with extension
  zip-utils sub [parent_dir] [-p password] [-t]                  - Compress subdirectories
  zip-utils each [target_dir] [-p password] [-t]                 - Compress each item separately"

  # Parse command
  if [ $# -eq 0 ]; then
    echo "$usage"
    return 1
  fi

  local command="$1"
  shift

  # Parse options
  local OPTIND opt password timestamp_flag
  local use_pwd=0 use_date=0

  while getopts "p:t" opt; do
    case $opt in
      p) use_pwd=1; password="$OPTARG" ;;
      t) use_date=1 ;;
      *) echo "Error: Invalid option" >&2; return 1 ;;
    esac
  done
  OPTIND=1

  # Generate timestamp if needed
  local timestamp=""
  if [ $use_date -eq 1 ]; then
    timestamp="_$(date +%Y%m%d%H%M%S)"
  fi

  # Password option string
  local pwd_opt=""
  if [ $use_pwd -eq 1 ]; then
    pwd_opt="-P \"$password\""
  fi

  # Process commands
  case "$command" in
    dir)
      # Check parameters
      if [ $# -eq 0 ]; then
        echo "Compress a directory to a ZIP file.
Usage:
 zip-utils dir <directory_path> [output_filename] [-p password] [-t]"
        return 1
      fi

      local zip_path="$1"
      _archive_validate_dir "$zip_path" || return 1

      local zip_name="${2:-$(basename ${zip_path})$timestamp.zip}"
      local pwd_note=""
      [ $use_pwd -eq 1 ] && pwd_note=" with password protection"

      echo "Creating archive$pwd_note: $zip_name from directory: $zip_path"
      eval "zip $(_archive_zip_opts) $pwd_opt \"$zip_name\" \"$zip_path\"" || {
        echo "Error: Failed to create ZIP archive" >&2
        return 1
      }
      echo "Compression completed, saved to $zip_name"
    ;;

    file)
      # Check parameters
      if [ $# -eq 0 ]; then
        echo "Compress a single file to ZIP format.
Usage:
 zip-utils file <file_path> [output_filename] [-p password] [-t]"
        return 1
      fi

      local zip_path="$1"
      _archive_validate_file "$zip_path" || return 1

      local zip_dir=$(dirname "$zip_path")
      local file_name=$(basename "$zip_path")
      local zip_name="${2:-${file_name}$timestamp.zip}"
      local pwd_note=""
      [ $use_pwd -eq 1 ] && pwd_note=" with password protection"

      echo "Compressing file$pwd_note: $file_name to $zip_name"
      _archive_pushd "$zip_dir" || return 1

      eval "zip $(_archive_zip_opts) $pwd_opt \"$zip_name\" \"$file_name\"" || {
        echo "Error: Failed to create ZIP archive" >&2
        _archive_popd
        return 1
      }
      echo "Compression completed, saved to $zip_dir/$zip_name"

      _archive_popd
    ;;

    cur)
      local zip_name="${1:-$(basename $(pwd))$timestamp.zip}"
      local pwd_note=""
      [ $use_pwd -eq 1 ] && pwd_note=" with password protection"

      echo "Compressing current directory$pwd_note to a ZIP file: $zip_name"
      eval "zip $(_archive_zip_opts) $pwd_opt \"$zip_name\" ." || {
        echo "Error: Failed to create ZIP archive" >&2
        return 1
      }
      echo "Compression completed, saved to $zip_name"
    ;;

    ext)
      # Check parameters
      if [ $# -eq 0 ]; then
        echo "Compress all files with specific extension.
Usage:
 zip-utils ext <file_extension> [target_directory] [-p password] [-t]"
        return 1
      fi

      local ext="$1"
      local zip_path="${2:-.}"
      _archive_validate_dir "$zip_path" || return 1

      echo "Compressing all .$ext files in $zip_path"
      _archive_pushd "$zip_path" || return 1

      # Check if any matching files exist
      if [ -z "$(find . -type f -name "*.${ext}" -print -quit 2>/dev/null)" ]; then
        echo "Warning: No files with extension .$ext found in $zip_path" >&2
        _archive_popd
        return 1
      fi

      local output_name="${ext}$timestamp.zip"

      # Search and compress
      eval "find . -type f -name \"*.${ext}\" -print | xargs zip $(_archive_zip_opts) $pwd_opt \"$output_name\"" || {
        echo "Error: Failed to create ZIP archive" >&2
        _archive_popd
        return 1
      }
      echo "Compression completed, saved to $zip_path/$output_name"

      _archive_popd
    ;;

    sub)
      local target_dir="${1:-.}"
      _archive_validate_dir "$target_dir" || return 1

      echo "Compressing all subdirectories in $target_dir"
      _archive_pushd "$target_dir" || return 1

      # Check if any subdirectories exist
      if [ -z "$(ls -d ./*/ 2>/dev/null)" ]; then
        echo "Warning: No subdirectories found in $target_dir" >&2
        _archive_popd
        return 1
      fi

      # Process each subdirectory
      local success=true
      for dir in $(ls -d ./*/ 2>/dev/null); do
        local dir_basename=$(basename "$dir")
        local archive_name="./${dir_basename}$timestamp.zip"
        echo "Compressing directory: $dir_basename to $archive_name"
        eval "(zip $(_archive_zip_opts) $pwd_opt \"$archive_name\" \"${dir}\"* &&
        echo \"Successfully compressed to $archive_name\")" || {
          echo "Error: Failed to compress $dir_basename" >&2
          success=false
        }
      done

      $success || echo "Warning: Some directories may not have been compressed successfully" >&2
      _archive_popd
    ;;

    each)
      local target_dir="${1:-.}"
      _archive_validate_dir "$target_dir" || return 1

      echo "Compressing each file or subdirectory to separate ZIP files"
      _archive_pushd "$target_dir" || return 1

      # Check if any files exist
      if [ -z "$(ls 2>/dev/null)" ]; then
        echo "Warning: No files found in $target_dir" >&2
        _archive_popd
        return 1
      fi

      # Create password file if using passwords
      if [ $use_pwd -eq 1 ]; then
        echo "Filename:Password" > password.txt
        echo "Using password protection. Passwords will be saved to $target_dir/password.txt"
      fi

      # Compress each file or subdirectory
      local compressed_count=0
      local success=true
      for item in $(ls); do
        # Skip existing zip files and password file
        if [[ "$item" != *.zip ]] && [ "$item" != "password.txt" ]; then
          local archive_name="./$(basename \"$item\")$timestamp.zip"
          echo "Compressing: $item to $archive_name"

          # Use password if specified
          if [ $use_pwd -eq 1 ]; then
            eval "zip $(_archive_zip_opts) $pwd_opt \"$archive_name\" \"$item\"" && {
              echo "Successfully compressed to $archive_name with password protection"
              echo "$(basename "$archive_name"):$password" >> password.txt
              ((compressed_count++))
            } || {
              echo "Error: Failed to compress $item" >&2
              success=false
            }
          else
            eval "zip $(_archive_zip_opts) \"$archive_name\" \"$item\"" && {
              echo "Successfully compressed to $archive_name"
              ((compressed_count++))
            } || {
              echo "Error: Failed to compress $item" >&2
              success=false
            }
          fi
        fi
      done

      if [ $compressed_count -eq 0 ]; then
        echo "No suitable items found for compression" >&2
        [ $use_pwd -eq 1 ] && rm password.txt
        _archive_popd
        return 1
      else
        echo "Completed compressing $compressed_count items"
        $success || echo "Warning: Some items may not have been compressed successfully" >&2
      fi

      _archive_popd
    ;;

    *)
      echo "Error: Unknown command: $command" >&2
      echo "$usage"
      return 1
    ;;
  esac
}'

# ==========================
# Legacy Compatibility Aliases
# ==========================
alias zip-cur='() { zip-utils cur "$@"; }'  # Compress current directory to ZIP
alias zip-dir='() { zip-utils dir "$@"; }'  # Compress a directory to ZIP
alias zip-dirp='() { local dir="$1"; local pwd="$2"; local name="$3"; zip-utils dir "$dir" "$name" -p "$pwd"; }' # Compress directory with password
alias zip-ext='() { zip-utils ext "$@"; }'  # Compress files with specific extension
alias zip-sub='() { zip-utils sub "$@"; }'  # Compress subdirectories
alias zip-each='() {
  local OPTIND opt d p password
  local use_date=0 use_pwd=0

  # Parse legacy options
  while getopts "dp:" opt; do
    case $opt in
      d) use_date=1 ;;
      p) use_pwd=1; password=$OPTARG ;;
      *) echo "Error: Invalid option" >&2; return 1 ;;
    esac
  done
  shift $((OPTIND - 1))

  # Build new option string
  local opts=""
  [ $use_date -eq 1 ] && opts="$opts -t"
  [ $use_pwd -eq 1 ] && opts="$opts -p \"$password\""

  eval "zip-utils each $1 $opts"
}'  # Compress each item in directory separately

alias zip-single='() { zip-utils file "$@"; }'  # Compress a single file
alias zip-singlep='() { local file="$1"; local pwd="$2"; local name="$3"; zip-utils file "$file" "$name" -p "$pwd"; }'  # Compress a single file with password

# ==========================
# Extraction Functions
# ==========================

# Unified ZIP extraction function
alias unzip-utils='() {
  local usage="ZIP extraction utilities for extracting ZIP archives.
Available commands:
  unzip-utils file <zip_file> [destination_path] [-p password]    - Extract a ZIP file
  unzip-utils each [directory_path] [-p password]                - Extract all ZIP files in a directory"

  # Parse command
  if [ $# -eq 0 ]; then
    echo "$usage"
    return 1
  fi

  local command="$1"
  shift

  # Parse options
  local OPTIND opt password
  local use_pwd=0

  while getopts "p:" opt; do
    case $opt in
      p) use_pwd=1; password="$OPTARG" ;;
      *) echo "Error: Invalid option" >&2; return 1 ;;
    esac
  done
  OPTIND=1

  # Password option string
  local pwd_opt=""
  if [ $use_pwd -eq 1 ]; then
    pwd_opt="-P \"$password\""
  fi

  # Process commands
  case "$command" in
    file)
      # Check parameters
      if [ $# -eq 0 ]; then
        echo "Extract a ZIP file.
Usage:
 unzip-utils file <zip_file> [destination_path] [-p password]"
        return 1
      fi

      local unzip_name="$1"
      _archive_validate_file "$unzip_name" || return 1

      local unzip_path="${2:-$(dirname "$unzip_name")}"
      if [ ! -d "$unzip_path" ]; then
        echo "Creating destination directory: $unzip_path"
        mkdir -p "$unzip_path" || {
          echo "Error: Failed to create destination directory" >&2
          return 1
        }
      fi

      local pwd_note=""
      [ $use_pwd -eq 1 ] && pwd_note=" (password-protected)"

      echo "Extracting$pwd_note: $unzip_name to $unzip_path"
      eval "unzip -q $pwd_opt \"$unzip_name\" -d \"$unzip_path\"" || {
        echo "Error: Failed to extract ZIP file. Check if the password is correct (if applicable)." >&2
        return 1
      }
      echo "Extraction completed, files extracted to $unzip_path"
    ;;

    each)
      local target_dir="${1:-.}"
      _archive_validate_dir "$target_dir" || return 1

      echo "Extracting all ZIP files in $target_dir"
      _archive_pushd "$target_dir" || return 1

      # Check if any zip files exist
      if [ -z "$(ls *.zip 2>/dev/null)" ]; then
        echo "Warning: No ZIP files found in $target_dir" >&2
        _archive_popd
        return 1
      fi

      local extracted_count=0
      local success=true

      for file in $(ls *.zip 2>/dev/null); do
        local dir_name=$(basename "$file" .zip)
        echo "Extracting: $file to ./$dir_name"
        mkdir -p "./$dir_name" || {
          echo "Error: Failed to create directory ./$dir_name" >&2
          success=false
          continue
        }

        if [ $use_pwd -eq 1 ]; then
          eval "unzip -q $pwd_opt \"$file\" -d \"./$dir_name\"" && {
            echo "Successfully extracted to ./$dir_name"
            ((extracted_count++))
          } || {
            echo "Error: Failed to extract $file. Check if the password is correct." >&2
            success=false
          }
        else
          unzip -q "$file" -d "./$dir_name" && {
            echo "Successfully extracted to ./$dir_name"
            ((extracted_count++))
          } || {
            echo "Error: Failed to extract $file" >&2
            success=false
          }
        fi
      done

      if [ $extracted_count -eq 0 ]; then
        echo "Failed to extract any ZIP files" >&2
        _archive_popd
        return 1
      else
        echo "Completed extracting $extracted_count ZIP files"
        $success || echo "Warning: Some files may not have been extracted successfully" >&2
      fi

      _archive_popd
    ;;

    *)
      echo "Error: Unknown command: $command" >&2
      echo "$usage"
      return 1
    ;;
  esac
}'

# Legacy compatibility aliases
alias unzip-file='() { unzip-utils file "$@"; }'  # Extract a ZIP file
alias unzip-each='() { unzip-utils each "$@"; }'  # Extract all ZIP files in a directory
alias unzip-pwd='() { local file="$1"; local pwd="$2"; local dest="$3"; unzip-utils file "$file" "$dest" -p "$pwd"; }'  # Extract password-protected ZIP file

# ==========================
# Core TAR Functions
# ==========================

# Unified TAR compression function
alias tar-utils='() {
  local usage="TAR utilities for creating and managing TAR archives.
Available commands:
  tar-utils dir <directory> [output_name] [-f format] [-t]     - Compress directory
  tar-utils file <file> [output_name] [-f format] [-t]         - Compress single file
  tar-utils cur [output_name] [-f format] [-t]                 - Compress current directory
  tar-utils ext <extension> [target_dir] [-f format] [-t]      - Compress files with extension
  tar-utils sub [parent_dir] [-f format] [-t]                  - Compress subdirectories
  tar-utils each [target_dir] [-f format] [-t]                 - Compress each item separately

Available formats:
  gz/gzip (default) - gzip compression (.tar.gz)
  bz2/bzip         - bzip2 compression (.tar.bz2)
  xz               - xz compression (.tar.xz)"

  # Parse command
  if [ $# -eq 0 ]; then
    echo "$usage"
    return 1
  fi

  local command="$1"
  shift

  # Parse options
  local OPTIND opt format timestamp_flag
  local use_date=0
  local compress_format="gz"

  while getopts "f:t" opt; do
    case $opt in
      f) compress_format="$OPTARG" ;;
      t) use_date=1 ;;
      *) echo "Error: Invalid option" >&2; return 1 ;;
    esac
  done
  OPTIND=1

  # Generate timestamp if needed
  local timestamp=""
  if [ $use_date -eq 1 ]; then
    timestamp="_$(date +%Y%m%d%H%M%S)"
  fi

  # Get file extension based on format
  local file_ext=$(_archive_tar_extension "$compress_format")
  local compress_opt=$(_archive_tar_compress_opt "$compress_format")

  # Process commands
  case "$command" in
    dir)
      # Check parameters
      if [ $# -eq 0 ]; then
        echo "Compress a directory to a TAR file.
Usage:
 tar-utils dir <directory_path> [output_filename] [-f format] [-t]"
        return 1
      fi

      local tar_path="$1"
      _archive_validate_dir "$tar_path" || return 1

      local tar_name="${2:-$(basename ${tar_path})$timestamp.$file_ext}"

      echo "Creating archive ($compress_format): $tar_name from directory: $tar_path"
      eval "tar $compress_opt -cf \"$tar_name\" $(_archive_tar_opts) -C \"$(dirname \"$tar_path\")\" \"$(basename \"$tar_path\")\"" || {
        echo "Error: Failed to create TAR archive" >&2
        return 1
      }
      echo "Compression completed, saved to $tar_name"
    ;;

    file)
      # Check parameters
      if [ $# -eq 0 ]; then
        echo "Compress a single file to TAR format.
Usage:
 tar-utils file <file_path> [output_filename] [-f format] [-t]"
        return 1
      fi

      local tar_path="$1"
      _archive_validate_file "$tar_path" || return 1

      local tar_dir=$(dirname "$tar_path")
      local file_name=$(basename "$tar_path")
      local tar_name="${2:-${file_name}$timestamp.$file_ext}"

      echo "Compressing file: $file_name to $tar_name"
      _archive_pushd "$tar_dir" || return 1

      eval "tar $compress_opt -cf \"$tar_name\" $(_archive_tar_opts) \"$file_name\"" || {
        echo "Error: Failed to create TAR archive" >&2
        _archive_popd
        return 1
      }
      echo "Compression completed, saved to $tar_dir/$tar_name"

      _archive_popd
    ;;

    cur)
      local tar_name="${1:-$(basename $(pwd))$timestamp.$file_ext}"

      echo "Compressing current directory to a TAR file: $tar_name"
      eval "tar $compress_opt -cf \"$tar_name\" $(_archive_tar_opts) ." || {
        echo "Error: Failed to create TAR archive" >&2
        return 1
      }
      echo "Compression completed, saved to $tar_name"
    ;;

    ext)
      # Check parameters
      if [ $# -eq 0 ]; then
        echo "Compress all files with specific extension.
Usage:
 tar-utils ext <file_extension> [target_directory] [-f format] [-t]"
        return 1
      fi

      local ext="$1"
      local tar_path="${2:-.}"
      _archive_validate_dir "$tar_path" || return 1

      echo "Compressing all .$ext files in $tar_path"
      _archive_pushd "$tar_path" || return 1

      # Check if any matching files exist
      if [ -z "$(find . -type f -name "*.${ext}" -print -quit 2>/dev/null)" ]; then
        echo "Warning: No files with extension .$ext found in $tar_path" >&2
        _archive_popd
        return 1
      fi

      local output_name="${ext}$timestamp.$file_ext"

      # Create file list
      find . -type f -name "*.${ext}" > .tmpfilelist || {
        echo "Error: Failed to create file list" >&2
        _archive_popd
        return 1
      }

      # Compress files
      eval "tar $compress_opt -cf \"$output_name\" $(_archive_tar_opts) -T .tmpfilelist" || {
        echo "Error: Failed to create TAR archive" >&2
        rm -f .tmpfilelist
        _archive_popd
        return 1
      }
      echo "Compression completed, saved to $tar_path/$output_name"

      # Clean up
      rm -f .tmpfilelist
      _archive_popd
    ;;

    sub)
      local target_dir="${1:-.}"
      _archive_validate_dir "$target_dir" || return 1

      echo "Compressing all subdirectories in $target_dir"
      _archive_pushd "$target_dir" || return 1

      # Check if any subdirectories exist
      if [ -z "$(ls -d ./*/ 2>/dev/null)" ]; then
        echo "Warning: No subdirectories found in $target_dir" >&2
        _archive_popd
        return 1
      fi

      # Process each subdirectory
      local success=true
      for dir in $(ls -d ./*/ 2>/dev/null); do
        local dir_basename=$(basename "$dir")
        local archive_name="./${dir_basename}$timestamp.$file_ext"
        echo "Compressing directory: $dir_basename to $archive_name"
        eval "(tar $compress_opt -cf \"$archive_name\" $(_archive_tar_opts) \"${dir%/}\" &&
        echo \"Successfully compressed to $archive_name\")" || {
          echo "Error: Failed to compress $dir_basename" >&2
          success=false
        }
      done

      $success || echo "Warning: Some directories may not have been compressed successfully" >&2
      _archive_popd
    ;;

    each)
      local target_dir="${1:-.}"
      _archive_validate_dir "$target_dir" || return 1

      echo "Compressing each file or subdirectory to separate TAR files"
      _archive_pushd "$target_dir" || return 1

      # Check if any files exist
      if [ -z "$(ls 2>/dev/null)" ]; then
        echo "Warning: No files found in $target_dir" >&2
        _archive_popd
        return 1
      fi

      # Compress each file or subdirectory
      local compressed_count=0
      local success=true
      for item in $(ls); do
        # Skip existing archive files
        if [[ "$item" != *.tar.* ]]; then
          local archive_name="./$(basename "$item")$timestamp.$file_ext"
          echo "Compressing: $item to $archive_name"

          eval "tar $compress_opt -cf \"$archive_name\" $(_archive_tar_opts) \"$item\"" && {
            echo "Successfully compressed to $archive_name"
            ((compressed_count++))
          } || {
            echo "Error: Failed to compress $item" >&2
            success=false
          }
        fi
      done

      if [ $compressed_count -eq 0 ]; then
        echo "No suitable items found for compression" >&2
        _archive_popd
        return 1
      else
        echo "Completed compressing $compressed_count items"
        $success || echo "Warning: Some items may not have been compressed successfully" >&2
      fi

      _archive_popd
    ;;

    *)
      echo "Error: Unknown command: $command" >&2
      echo "$usage"
      return 1
    ;;
  esac
}'

# Legacy compatibility aliases for TAR
alias tar-dir='() { tar-utils dir "$@"; }'  # Compress directory to TAR archive
alias tar-file='() { tar-utils file "$@"; }'  # Compress file to TAR archive
alias tar-cur='() { tar-utils cur "$@"; }'  # Compress current directory to TAR archive
alias tar-ext='() { tar-utils ext "$@"; }'  # Compress files with extension to TAR archive
alias tar-sub='() { tar-utils sub "$@"; }'  # Compress subdirectories to TAR archives
alias tar-each='() { tar-utils each "$@"; }'  # Compress each item to separate TAR archive

# Format-specific aliases
alias tgz-dir='() { tar-utils dir "$@" -f gz; }'  # Create .tar.gz archive from directory
alias tbz2-dir='() { tar-utils dir "$@" -f bz2; }'  # Create .tar.bz2 archive from directory
alias txz-dir='() { tar-utils dir "$@" -f xz; }'  # Create .tar.xz archive from directory

# TAR extraction function
alias untar-utils='() {
  local usage="TAR extraction utilities for extracting TAR archives.
Available commands:
  untar-utils file <tar_file> [destination_path]     - Extract a TAR file
  untar-utils each [directory_path]                 - Extract all TAR files in a directory"

  # Parse command
  if [ $# -eq 0 ]; then
    echo "$usage"
    return 1
  fi

  local command="$1"
  shift

  # Process commands
  case "$command" in
    file)
      # Check parameters
      if [ $# -eq 0 ]; then
        echo "Extract a TAR file.
Usage:
 untar-utils file <tar_file> [destination_path]"
        return 1
      fi

      local untar_name="$1"
      _archive_validate_file "$untar_name" || return 1

      local untar_path="${2:-$(dirname "$untar_name")}"
      if [ ! -d "$untar_path" ]; then
        echo "Creating destination directory: $untar_path"
        mkdir -p "$untar_path" || {
          echo "Error: Failed to create destination directory" >&2
          return 1
        }
      fi

      # Auto-detect compression format based on extension
      local compress_opt=""
      if [[ "$untar_name" == *.tar.gz ]] || [[ "$untar_name" == *.tgz ]]; then
        compress_opt="-z"
      elif [[ "$untar_name" == *.tar.bz2 ]] || [[ "$untar_name" == *.tbz2 ]]; then
        compress_opt="-j"
      elif [[ "$untar_name" == *.tar.xz ]]; then
        compress_opt="-J"
      fi

      echo "Extracting: $untar_name to $untar_path"
      eval "tar $compress_opt -xf \"$untar_name\" -C \"$untar_path\"" || {
        echo "Error: Failed to extract TAR archive" >&2
        return 1
      }
      echo "Extraction completed, files extracted to $untar_path"
    ;;

    each)
      local target_dir="${1:-.}"
      _archive_validate_dir "$target_dir" || return 1

      echo "Extracting all TAR files in $target_dir"
      _archive_pushd "$target_dir" || return 1

      # Check if any tar files exist
      if [ -z "$(ls *.tar* 2>/dev/null)" ]; then
        echo "Warning: No TAR files found in $target_dir" >&2
        _archive_popd
        return 1
      fi

      local extracted_count=0
      local success=true

      # Extract .tar files
      for file in $(ls *.tar 2>/dev/null); do
        [ -f "$file" ] || continue
        local dir_name=$(basename "$file" .tar)
        echo "Extracting: $file to ./$dir_name"
        mkdir -p "./$dir_name" || {
          echo "Error: Failed to create directory ./$dir_name" >&2
          success=false
          continue
        }
        tar -xf "$file" -C "./$dir_name" && {
          echo "Successfully extracted to ./$dir_name"
          ((extracted_count++))
        } || {
          echo "Error: Failed to extract $file" >&2
          success=false
        }
      done

      # Extract .tar.gz and .tgz files
      for file in $(ls *.tar.gz *.tgz 2>/dev/null | sort -u); do
        [ -f "$file" ] || continue
        local dir_name=$(basename "$file" | sed "s/\.tar\.gz$//;s/\.tgz$//")
        echo "Extracting: $file to ./$dir_name"
        mkdir -p "./$dir_name" || {
          echo "Error: Failed to create directory ./$dir_name" >&2
          success=false
          continue
        }
        tar -zxf "$file" -C "./$dir_name" && {
          echo "Successfully extracted to ./$dir_name"
          ((extracted_count++))
        } || {
          echo "Error: Failed to extract $file" >&2
          success=false
        }
      done

      # Extract .tar.bz2 and .tbz2 files
      for file in $(ls *.tar.bz2 *.tbz2 2>/dev/null | sort -u); do
        [ -f "$file" ] || continue
        local dir_name=$(basename "$file" | sed "s/\.tar\.bz2$//;s/\.tbz2$//")
        echo "Extracting: $file to ./$dir_name"
        mkdir -p "./$dir_name" || {
          echo "Error: Failed to create directory ./$dir_name" >&2
          success=false
          continue
        }
        tar -jxf "$file" -C "./$dir_name" && {
          echo "Successfully extracted to ./$dir_name"
          ((extracted_count++))
        } || {
          echo "Error: Failed to extract $file" >&2
          success=false
        }
      done

      # Extract .tar.xz files
      for file in $(ls *.tar.xz 2>/dev/null); do
        [ -f "$file" ] || continue
        local dir_name=$(basename "$file" .tar.xz)
        echo "Extracting: $file to ./$dir_name"
        mkdir -p "./$dir_name" || {
          echo "Error: Failed to create directory ./$dir_name" >&2
          success=false
          continue
        }
        tar -Jxf "$file" -C "./$dir_name" && {
          echo "Successfully extracted to ./$dir_name"
          ((extracted_count++))
        } || {
          echo "Error: Failed to extract $file" >&2
          success=false
        }
      done

      if [ $extracted_count -eq 0 ]; then
        echo "Failed to extract any TAR files" >&2
        _archive_popd
        return 1
      } else {
        echo "Completed extracting $extracted_count TAR files"
        $success || echo "Warning: Some files may not have been extracted successfully" >&2
      }

      _archive_popd
    ;;

    *)
      echo "Error: Unknown command: $command" >&2
      echo "$usage"
      return 1
    ;;
  esac
}'

# Legacy compatibility aliases for TAR
alias tar-dir='() { tar-utils dir "$@"; }'  # Compress directory to TAR archive
alias tar-file='() { tar-utils file "$@"; }'  # Compress file to TAR archive
alias tar-cur='() { tar-utils cur "$@"; }'  # Compress current directory to TAR archive
alias tar-ext='() { tar-utils ext "$@"; }'  # Compress files with extension to TAR archive
alias tar-sub='() { tar-utils sub "$@"; }'  # Compress subdirectories to TAR archives
alias tar-each='() { tar-utils each "$@"; }'  # Compress each item to separate TAR archive

# Format-specific aliases
alias tgz-dir='() { tar-utils dir "$@" -f gz; }'  # Create .tar.gz archive from directory
alias tbz2-dir='() { tar-utils dir "$@" -f bz2; }'  # Create .tar.bz2 archive from directory
alias txz-dir='() { tar-utils dir "$@" -f xz; }'  # Create .tar.xz archive from directory

# TAR extraction function
alias untar-utils='() {
  local usage="TAR extraction utilities for extracting TAR archives.
Available commands:
  untar-utils file <tar_file> [destination_path]     - Extract a TAR file
  untar-utils each [directory_path]                 - Extract all TAR files in a directory"

  # Parse command
  if [ $# -eq 0 ]; then
    echo "$usage"
    return 1
  fi

  local command="$1"
  shift

  # Process commands
  case "$command" in
    file)
      # Check parameters
      if [ $# -eq 0 ]; then
        echo "Extract a TAR file.
Usage:
 untar-utils file <tar_file> [destination_path]"
        return 1
      fi

      local untar_name="$1"
      _archive_validate_file "$untar_name" || return 1

      local untar_path="${2:-$(dirname "$untar_name")}"
      if [ ! -d "$untar_path" ]; then
        echo "Creating destination directory: $untar_path"
        mkdir -p "$untar_path" || {
          echo "Error: Failed to create destination directory" >&2
          return 1
        }
      fi

      # Auto-detect compression format based on extension
      local compress_opt=""
      if [[ "$untar_name" == *.tar.gz ]] || [[ "$untar_name" == *.tgz ]]; then
        compress_opt="-z"
      elif [[ "$untar_name" == *.tar.bz2 ]] || [[ "$untar_name" == *.tbz2 ]]; then
        compress_opt="-j"
      elif [[ "$untar_name" == *.tar.xz ]]; then
        compress_opt="-J"
      fi

      echo "Extracting: $untar_name to $untar_path"
      eval "tar $compress_opt -xf \"$untar_name\" -C \"$untar_path\"" || {
        echo "Error: Failed to extract TAR archive" >&2
        return 1
      }
      echo "Extraction completed, files extracted to $untar_path"
    ;;

    each)
      local target_dir="${1:-.}"
      _archive_validate_dir "$target_dir" || return 1

      echo "Extracting all TAR files in $target_dir"
      _archive_pushd "$target_dir" || return 1

      # Check if any tar files exist
      if [ -z "$(ls *.tar* 2>/dev/null)" ]; then
        echo "Warning: No TAR files found in $target_dir" >&2
        _archive_popd
        return 1
      fi

      local extracted_count=0
      local success=true

      # Extract .tar files
      for file in $(ls *.tar 2>/dev/null); do
        [ -f "$file" ] || continue
        local dir_name=$(basename "$file" .tar)
        echo "Extracting: $file to ./$dir_name"
        mkdir -p "./$dir_name" || {
          echo "Error: Failed to create directory ./$dir_name" >&2
          success=false
          continue
        }
        tar -xf "$file" -C "./$dir_name" && {
          echo "Successfully extracted to ./$dir_name"
          ((extracted_count++))
        } || {
          echo "Error: Failed to extract $file" >&2
          success=false
        }
      done

      # Extract .tar.gz and .tgz files
      for file in $(ls *.tar.gz *.tgz 2>/dev/null | sort -u); do
        [ -f "$file" ] || continue
        local dir_name=$(basename "$file" | sed "s/\.tar\.gz$//;s/\.tgz$//")
        echo "Extracting: $file to ./$dir_name"
        mkdir -p "./$dir_name" || {
          echo "Error: Failed to create directory ./$dir_name" >&2
          success=false
          continue
        }
        tar -zxf "$file" -C "./$dir_name" && {
          echo "Successfully extracted to ./$dir_name"
          ((extracted_count++))
        } || {
          echo "Error: Failed to extract $file" >&2
          success=false
        }
      done

      # Extract .tar.bz2 and .tbz2 files
      for file in $(ls *.tar.bz2 *.tbz2 2>/dev/null | sort -u); do
        [ -f "$file" ] || continue
        local dir_name=$(basename "$file" | sed "s/\.tar\.bz2$//;s/\.tbz2$//")
        echo "Extracting: $file to ./$dir_name"
        mkdir -p "./$dir_name" || {
          echo "Error: Failed to create directory ./$dir_name" >&2
          success=false
          continue
        }
        tar -jxf "$file" -C "./$dir_name" && {
          echo "Successfully extracted to ./$dir_name"
          ((extracted_count++))
        } || {
          echo "Error: Failed to extract $file" >&2
          success=false
        }
      done

      # Extract .tar.xz files
      for file in $(ls *.tar.xz 2>/dev/null); do
        [ -f "$file" ] || continue
        local dir_name=$(basename "$file" .tar.xz)
        echo "Extracting: $file to ./$dir_name"
        mkdir -p "./$dir_name" || {
          echo "Error: Failed to create directory ./$dir_name" >&2
          success=false
          continue
        }
        tar -Jxf "$file" -C "./$dir_name" && {
          echo "Successfully extracted to ./$dir_name"
          ((extracted_count++))
        } || {
          echo "Error: Failed to extract $file" >&2
          success=false
        }
      done

      if [ $extracted_count -eq 0 ]; then
        echo "Failed to extract any TAR files" >&2
        _archive_popd
        return 1
      } else {
        echo "Completed extracting $extracted_count TAR files"
        $success || echo "Warning: Some files may not have been extracted successfully" >&2
      }

      _archive_popd
    ;;

    *)
      echo "Error: Unknown command: $command" >&2
      echo "$usage"
      return 1
    ;;
  esac
}'

# Legacy compatibility aliases for TAR extraction
alias untar-file='() { untar-utils file "$@"; }'  # Extract a TAR archive
alias untar-each='() { untar-utils each "$@"; }'  # Extract all TAR archives in directory

# ==========================
# Combined Utilities
# ==========================

# Combined archive utilities (handles both ZIP and TAR)
alias archive-utils='() {
  local usage="Archive utilities for compressing and extracting files.
Available commands:
  archive-utils compress <type> <command> [options]   - Compress files using specified archive type
  archive-utils extract <type> <command> [options]    - Extract files from specified archive type

Available types:
  zip - ZIP archives (.zip)
  tar - TAR archives (.tar, .tar.gz, .tar.bz2, .tar.xz)

Run with just the type to see available commands:
  archive-utils compress zip
  archive-utils extract tar"

  # Parse command
  if [ $# -lt 2 ]; then
    echo "$usage"
    return 1
  fi

  local operation="$1"
  local type="$2"
  shift 2

  case "$operation" in
    compress)
      case "$type" in
        zip) zip-utils "$@" ;;
        tar) tar-utils "$@" ;;
        *) echo "Error: Unknown archive type: $type" >&2; return 1 ;;
      esac
    ;;

    extract)
      case "$type" in
        zip) unzip-utils "$@" ;;
        tar) untar-utils "$@" ;;
        *) echo "Error: Unknown archive type: $type" >&2; return 1 ;;
      esac
    ;;

    *)
      echo "Error: Unknown operation: $operation" >&2
      echo "$usage"
      return 1
    ;;
  esac
}'

# Auto-detect and extract any archive type
alias extract='() {
  if [ $# -eq 0 ]; then
    echo "Extract any supported archive file.
Usage:
 extract <archive_file> [destination_path]"
    return 1
  fi

  local file="$1"
  local destination="${2:-$(dirname "$file")}"

  if [ ! -f "$file" ]; then
    echo "Error: File $file does not exist" >&2
    return 1
  fi

  if [ ! -d "$destination" ]; then
    echo "Creating destination directory: $destination"
    mkdir -p "$destination" || {
      echo "Error: Failed to create destination directory" >&2
      return 1
    }
  fi

  echo "Extracting $file to $destination"

  case "$file" in
    *.zip)
      unzip-utils file "$file" "$destination"
      ;;
    *.tar)
      untar-utils file "$file" "$destination"
      ;;
    *.tar.gz|*.tgz)
      untar-utils file "$file" "$destination"
      ;;
    *.tar.bz2|*.tbz2)
      untar-utils file "$file" "$destination"
      ;;
    *.tar.xz)
      untar-utils file "$file" "$destination"
      ;;
    *.rar)
      if command -v unrar &> /dev/null; then
        unrar x "$file" "$destination" || {
          echo "Error: Failed to extract RAR archive" >&2
          return 1
        }
      else
        echo "Error: unrar is not installed" >&2
        return 1
      fi
      ;;
    *.7z)
      if command -v 7z &> /dev/null; then
        7z x "$file" -o"$destination" || {
          echo "Error: Failed to extract 7z archive" >&2
          return 1
        }
      else
        echo "Error: 7z is not installed" >&2
        return 1
      fi
      ;;
    *)
      echo "Error: Unsupported archive format" >&2
      return 1
      ;;
  esac

  echo "Extraction completed: $file -> $destination"
}'
