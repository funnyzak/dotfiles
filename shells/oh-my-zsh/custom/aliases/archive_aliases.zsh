# Description: Compression and extraction aliases for ZIP, TAR, 7z and RAR workflows.

# ==========================
# Shared Helper Functions
# ==========================

_archive_error_archive_aliases() {
  local message="$1"
  echo "Error: $message" >&2
  return 1
}

_archive_warn_archive_aliases() {
  local message="$1"
  echo "Warning: $message" >&2
}

_archive_validate_dir_archive_aliases() {
  local target_dir="$1"
  local label="${2:-Directory}"

  if [ ! -d "$target_dir" ]; then
    _archive_error_archive_aliases "$label \"$target_dir\" does not exist."
    return 1
  fi

  return 0
}

_archive_validate_file_archive_aliases() {
  local target_file="$1"
  local label="${2:-File}"

  if [ ! -f "$target_file" ]; then
    _archive_error_archive_aliases "$label \"$target_file\" does not exist."
    return 1
  fi

  return 0
}

_archive_ensure_dir_archive_aliases() {
  local target_dir="$1"

  if [ -d "$target_dir" ]; then
    return 0
  fi

  if ! mkdir -p "$target_dir"; then
    _archive_error_archive_aliases "Failed to create directory \"$target_dir\"."
    return 1
  fi

  return 0
}

_archive_require_command_archive_aliases() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    _archive_error_archive_aliases "Required command \"$command_name\" is not installed."
    return 1
  fi

  return 0
}

_archive_timestamp_suffix_archive_aliases() {
  local use_timestamp="$1"

  if [ "$use_timestamp" = "1" ]; then
    echo "_$(date +%Y%m%d%H%M%S)"
  else
    echo ""
  fi
}

_archive_output_in_cwd_archive_aliases() {
  local output_name="$1"

  case "$output_name" in
    /*)
      echo "$output_name"
      ;;
    *)
      echo "$(pwd)/$output_name"
      ;;
  esac
}

_archive_output_in_base_dir_archive_aliases() {
  local base_dir="$1"
  local output_name="$2"

  case "$output_name" in
    /*)
      echo "$output_name"
      ;;
    *)
      echo "$base_dir/$output_name"
      ;;
  esac
}

_archive_tar_flag_archive_aliases() {
  local format_name="${1:-gz}"

  case "$format_name" in
    gz|gzip)
      echo "-z"
      ;;
    bz2|bzip|bzip2)
      echo "-j"
      ;;
    xz)
      echo "-J"
      ;;
    *)
      echo ""
      return 1
      ;;
  esac
}

_archive_tar_extension_archive_aliases() {
  local format_name="${1:-gz}"

  case "$format_name" in
    gz|gzip)
      echo "tar.gz"
      ;;
    bz2|bzip|bzip2)
      echo "tar.bz2"
      ;;
    xz)
      echo "tar.xz"
      ;;
    *)
      echo ""
      return 1
      ;;
  esac
}

_archive_tar_detect_flag_archive_aliases() {
  local archive_name="$1"

  case "$archive_name" in
    *.tar.gz|*.tgz)
      echo "-z"
      ;;
    *.tar.bz2|*.tbz2)
      echo "-j"
      ;;
    *.tar.xz|*.txz)
      echo "-J"
      ;;
    *.tar)
      echo ""
      ;;
    *)
      echo ""
      return 1
      ;;
  esac
}

_archive_is_tar_archive_archive_aliases() {
  local archive_name="$1"

  case "$archive_name" in
    *.tar|*.tar.gz|*.tgz|*.tar.bz2|*.tbz2|*.tar.xz|*.txz)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

_archive_strip_archive_suffix_archive_aliases() {
  local archive_name
  archive_name="$(basename "$1")"

  case "$archive_name" in
    *.tar.gz)
      echo "${archive_name%.tar.gz}"
      ;;
    *.tgz)
      echo "${archive_name%.tgz}"
      ;;
    *.tar.bz2)
      echo "${archive_name%.tar.bz2}"
      ;;
    *.tbz2)
      echo "${archive_name%.tbz2}"
      ;;
    *.tar.xz)
      echo "${archive_name%.tar.xz}"
      ;;
    *.txz)
      echo "${archive_name%.txz}"
      ;;
    *.tar)
      echo "${archive_name%.tar}"
      ;;
    *.zip)
      echo "${archive_name%.zip}"
      ;;
    *)
      echo "$archive_name"
      ;;
  esac
}

_archive_zip_usage_archive_aliases() {
  echo -e "ZIP utilities for compressing files and directories.\nUsage:\n zip-utils <dir|file|cur|ext|sub|each> [arguments] [options]\n\nCommands:\n dir  <directory_path> [output_name]          Compress one directory\n file <file_path> [output_name]               Compress one file\n cur  [output_name]                           Compress the current directory\n ext  <extension> [target_directory:.]        Compress matching files recursively\n sub  [target_directory:.]                    Compress each immediate subdirectory\n each [target_directory:.]                    Compress each immediate item\n\nOptions:\n -p, --password <password>                    Enable ZIP password protection\n -t, --timestamp                              Append a timestamp to generated names\n -h, --help                                   Show this help message"
}

_archive_unzip_usage_archive_aliases() {
  echo -e "ZIP extraction utilities.\nUsage:\n unzip-utils <file|each> [arguments] [options]\n\nCommands:\n file <zip_file> [destination_path]           Extract one ZIP archive\n each [directory_path:.]                      Extract all ZIP archives in a directory\n\nOptions:\n -p, --password <password>                    Use a password for extraction\n -h, --help                                   Show this help message"
}

_archive_tar_usage_archive_aliases() {
  echo -e "TAR utilities for creating compressed TAR archives.\nUsage:\n tar-utils <dir|file|cur|ext|sub|each> [arguments] [options]\n\nCommands:\n dir  <directory_path> [output_name]          Compress one directory\n file <file_path> [output_name]               Compress one file\n cur  [output_name]                           Compress the current directory\n ext  <extension> [target_directory:.]        Compress matching files recursively\n sub  [target_directory:.]                    Compress each immediate subdirectory\n each [target_directory:.]                    Compress each immediate item\n\nOptions:\n -f, --format <gz|bz2|xz>                     Compression format, default is gz\n -t, --timestamp                              Append a timestamp to generated names\n -h, --help                                   Show this help message"
}

_archive_untar_usage_archive_aliases() {
  echo -e "TAR extraction utilities.\nUsage:\n untar-utils <file|each> [arguments] [options]\n\nCommands:\n file <tar_file> [destination_path]           Extract one TAR archive\n each [directory_path:.]                      Extract all TAR archives in a directory\n\nOptions:\n -h, --help                                   Show this help message"
}

_archive_combined_usage_archive_aliases() {
  echo -e "Archive utilities for ZIP and TAR workflows.\nUsage:\n archive-utils <compress|extract> <zip|tar> [subcommand] [arguments] [options]\n\nExamples:\n archive-utils compress zip dir ./logs -t\n archive-utils extract tar file backup.tar.gz ./restore"
}

_archive_extract_usage_archive_aliases() {
  echo -e "Extract any supported archive file.\nUsage:\n extract <archive_file> [destination_path]\n\nSupported formats:\n zip, tar, tar.gz, tgz, tar.bz2, tbz2, tar.xz, txz, rar, 7z"
}

_archive_help_archive_aliases() {
  echo "Archive Management Aliases Help"
  echo "=============================="
  echo "zip-utils      Unified ZIP compression entry point"
  echo "zip-cur        Compress current directory to ZIP"
  echo "zip-dir        Compress a directory to ZIP"
  echo "zip-dirp       Compress a directory to ZIP with password"
  echo "zip-ext        Compress files by extension to ZIP"
  echo "zip-sub        Compress each subdirectory to ZIP"
  echo "zip-each       Compress each item in a directory to ZIP"
  echo "zip-single     Compress one file to ZIP"
  echo "zip-singlep    Compress one file to ZIP with password"
  echo "unzip-utils    Unified ZIP extraction entry point"
  echo "unzip-file     Extract one ZIP archive"
  echo "unzip-each     Extract all ZIP archives in a directory"
  echo "unzip-pwd      Extract one ZIP archive with password"
  echo "tar-utils      Unified TAR compression entry point"
  echo "tar-dir        Compress a directory to TAR"
  echo "tar-file       Compress a file to TAR"
  echo "tar-cur        Compress current directory to TAR"
  echo "tar-ext        Compress files by extension to TAR"
  echo "tar-sub        Compress each subdirectory to TAR"
  echo "tar-each       Compress each item in a directory to TAR"
  echo "tgz-dir        Compress a directory to tar.gz"
  echo "tbz2-dir       Compress a directory to tar.bz2"
  echo "txz-dir        Compress a directory to tar.xz"
  echo "untar-utils    Unified TAR extraction entry point"
  echo "untar-file     Extract one TAR archive"
  echo "untar-each     Extract all TAR archives in a directory"
  echo "archive-utils  Combined ZIP and TAR dispatcher"
  echo "extract        Auto-detect archive type and extract it"
  echo "archive-help   Display this help message"
}

_archive_run_zip_archive_aliases() {
  local archive_output="$1"
  local password="$2"
  shift 2

  local -a zip_args
  zip_args=(-r -q -9)

  if [ -n "$password" ]; then
    zip_args+=(-P "$password")
  fi

  zip "${zip_args[@]}" "$archive_output" "$@" -x "*.DS_Store"
}

_archive_run_tar_archive_aliases() {
  local tar_flag="$1"
  local archive_output="$2"
  shift 2

  tar "$tar_flag" -cf "$archive_output" --exclude=".DS_Store" --exclude="*/.DS_Store" "$@"
}

_archive_extract_tar_archive_aliases() {
  local archive_file="$1"
  local destination_path="$2"

  local tar_flag=""
  if ! tar_flag="$(_archive_tar_detect_flag_archive_aliases "$archive_file")"; then
    _archive_error_archive_aliases "Unsupported TAR archive format \"$archive_file\"."
    return 1
  fi

  local -a tar_args
  tar_args=(-xf "$archive_file" -C "$destination_path")

  if [ -n "$tar_flag" ]; then
    tar_args=("$tar_flag" "${tar_args[@]}")
  fi

  tar "${tar_args[@]}"
}

_archive_zip_dir_archive_aliases() {
  local source_dir=""
  local output_name=""
  local password=""
  local use_timestamp="0"

  while [ $# -gt 0 ]; do
    case "$1" in
      -p|--password)
        if [ $# -lt 2 ]; then
          _archive_error_archive_aliases "Missing value for option \"$1\"."
          return 1
        fi
        password="$2"
        shift 2
        ;;
      -t|--timestamp)
        use_timestamp="1"
        shift
        ;;
      -h|--help)
        echo -e "Compress a directory to ZIP.\nUsage:\n zip-utils dir <directory_path> [output_name] [-p password] [-t]"
        return 0
        ;;
      -*)
        _archive_error_archive_aliases "Unknown option \"$1\" for zip-utils dir."
        return 1
        ;;
      *)
        if [ -z "$source_dir" ]; then
          source_dir="$1"
        elif [ -z "$output_name" ]; then
          output_name="$1"
        else
          _archive_error_archive_aliases "Too many arguments for zip-utils dir."
          return 1
        fi
        shift
        ;;
    esac
  done

  if [ -z "$source_dir" ]; then
    echo -e "Compress a directory to ZIP.\nUsage:\n zip-utils dir <directory_path> [output_name] [-p password] [-t]"
    return 1
  fi

  _archive_validate_dir_archive_aliases "$source_dir" "Directory" || return 1
  _archive_require_command_archive_aliases "zip" || return 1

  local timestamp_suffix=""
  timestamp_suffix="$(_archive_timestamp_suffix_archive_aliases "$use_timestamp")"

  local source_parent=""
  source_parent="$(cd "$(dirname "$source_dir")" && pwd)"
  local source_name=""
  source_name="$(basename "$source_dir")"

  if [ -z "$output_name" ]; then
    output_name="${source_name}${timestamp_suffix}.zip"
  fi

  local archive_output=""
  archive_output="$(_archive_output_in_cwd_archive_aliases "$output_name")"

  echo "Creating ZIP archive \"$archive_output\" from directory \"$source_dir\""
  if ! (
    cd "$source_parent" || exit 1
    _archive_run_zip_archive_aliases "$archive_output" "$password" "$source_name"
  ); then
    _archive_error_archive_aliases "Failed to create ZIP archive from \"$source_dir\"."
    return 1
  fi

  echo "Saved to $archive_output"
}

_archive_zip_file_archive_aliases() {
  local source_file=""
  local output_name=""
  local password=""
  local use_timestamp="0"

  while [ $# -gt 0 ]; do
    case "$1" in
      -p|--password)
        if [ $# -lt 2 ]; then
          _archive_error_archive_aliases "Missing value for option \"$1\"."
          return 1
        fi
        password="$2"
        shift 2
        ;;
      -t|--timestamp)
        use_timestamp="1"
        shift
        ;;
      -h|--help)
        echo -e "Compress a file to ZIP.\nUsage:\n zip-utils file <file_path> [output_name] [-p password] [-t]"
        return 0
        ;;
      -*)
        _archive_error_archive_aliases "Unknown option \"$1\" for zip-utils file."
        return 1
        ;;
      *)
        if [ -z "$source_file" ]; then
          source_file="$1"
        elif [ -z "$output_name" ]; then
          output_name="$1"
        else
          _archive_error_archive_aliases "Too many arguments for zip-utils file."
          return 1
        fi
        shift
        ;;
    esac
  done

  if [ -z "$source_file" ]; then
    echo -e "Compress a file to ZIP.\nUsage:\n zip-utils file <file_path> [output_name] [-p password] [-t]"
    return 1
  fi

  _archive_validate_file_archive_aliases "$source_file" "File" || return 1
  _archive_require_command_archive_aliases "zip" || return 1

  local timestamp_suffix=""
  timestamp_suffix="$(_archive_timestamp_suffix_archive_aliases "$use_timestamp")"

  local source_parent=""
  source_parent="$(cd "$(dirname "$source_file")" && pwd)"
  local source_name=""
  source_name="$(basename "$source_file")"

  if [ -z "$output_name" ]; then
    output_name="${source_name}${timestamp_suffix}.zip"
  fi

  local archive_output=""
  archive_output="$(_archive_output_in_base_dir_archive_aliases "$source_parent" "$output_name")"

  echo "Creating ZIP archive \"$archive_output\" from file \"$source_file\""
  if ! (
    cd "$source_parent" || exit 1
    _archive_run_zip_archive_aliases "$archive_output" "$password" "$source_name"
  ); then
    _archive_error_archive_aliases "Failed to create ZIP archive from \"$source_file\"."
    return 1
  fi

  echo "Saved to $archive_output"
}

_archive_zip_cur_archive_aliases() {
  local output_name=""
  local password=""
  local use_timestamp="0"

  while [ $# -gt 0 ]; do
    case "$1" in
      -p|--password)
        if [ $# -lt 2 ]; then
          _archive_error_archive_aliases "Missing value for option \"$1\"."
          return 1
        fi
        password="$2"
        shift 2
        ;;
      -t|--timestamp)
        use_timestamp="1"
        shift
        ;;
      -h|--help)
        echo -e "Compress the current directory to ZIP.\nUsage:\n zip-utils cur [output_name] [-p password] [-t]"
        return 0
        ;;
      -*)
        _archive_error_archive_aliases "Unknown option \"$1\" for zip-utils cur."
        return 1
        ;;
      *)
        if [ -z "$output_name" ]; then
          output_name="$1"
        else
          _archive_error_archive_aliases "Too many arguments for zip-utils cur."
          return 1
        fi
        shift
        ;;
    esac
  done

  _archive_require_command_archive_aliases "zip" || return 1

  local timestamp_suffix=""
  timestamp_suffix="$(_archive_timestamp_suffix_archive_aliases "$use_timestamp")"

  if [ -z "$output_name" ]; then
    output_name="$(basename "$(pwd)")${timestamp_suffix}.zip"
  fi

  local archive_output=""
  archive_output="$(_archive_output_in_cwd_archive_aliases "$output_name")"

  local current_dir=""
  current_dir="$(pwd)"
  local archive_basename=""
  archive_basename="$(basename "$archive_output")"

  echo "Creating ZIP archive \"$archive_output\" from current directory"
  if [ "$(dirname "$archive_output")" = "$current_dir" ]; then
    if [ -n "$password" ]; then
      if ! zip -r -q -9 -P "$password" "$archive_output" . -x "*.DS_Store" "$archive_basename"; then
        _archive_error_archive_aliases "Failed to create ZIP archive from current directory."
        return 1
      fi
    else
      if ! zip -r -q -9 "$archive_output" . -x "*.DS_Store" "$archive_basename"; then
        _archive_error_archive_aliases "Failed to create ZIP archive from current directory."
        return 1
      fi
    fi
  else
    if ! _archive_run_zip_archive_aliases "$archive_output" "$password" "."; then
      _archive_error_archive_aliases "Failed to create ZIP archive from current directory."
      return 1
    fi
  fi

  echo "Saved to $archive_output"
}

_archive_zip_ext_archive_aliases() {
  local extension=""
  local target_dir="."
  local password=""
  local use_timestamp="0"

  while [ $# -gt 0 ]; do
    case "$1" in
      -p|--password)
        if [ $# -lt 2 ]; then
          _archive_error_archive_aliases "Missing value for option \"$1\"."
          return 1
        fi
        password="$2"
        shift 2
        ;;
      -t|--timestamp)
        use_timestamp="1"
        shift
        ;;
      -h|--help)
        echo -e "Compress files by extension to ZIP.\nUsage:\n zip-utils ext <file_extension> [target_directory] [-p password] [-t]"
        return 0
        ;;
      -*)
        _archive_error_archive_aliases "Unknown option \"$1\" for zip-utils ext."
        return 1
        ;;
      *)
        if [ -z "$extension" ]; then
          extension="$1"
        elif [ "$target_dir" = "." ]; then
          target_dir="$1"
        else
          _archive_error_archive_aliases "Too many arguments for zip-utils ext."
          return 1
        fi
        shift
        ;;
    esac
  done

  if [ -z "$extension" ]; then
    echo -e "Compress files by extension to ZIP.\nUsage:\n zip-utils ext <file_extension> [target_directory] [-p password] [-t]"
    return 1
  fi

  extension="${extension#.}"
  _archive_validate_dir_archive_aliases "$target_dir" "Directory" || return 1
  _archive_require_command_archive_aliases "zip" || return 1

  local timestamp_suffix=""
  timestamp_suffix="$(_archive_timestamp_suffix_archive_aliases "$use_timestamp")"

  local target_abs=""
  target_abs="$(cd "$target_dir" && pwd)"
  local output_name="${extension}${timestamp_suffix}.zip"
  local archive_output=""
  archive_output="$(_archive_output_in_base_dir_archive_aliases "$target_abs" "$output_name")"

  if ! find "$target_abs" -type f -name "*.${extension}" -print -quit | grep -q "."; then
    _archive_warn_archive_aliases "No files with extension \".$extension\" were found in \"$target_abs\"."
    return 1
  fi

  echo "Creating ZIP archive \"$archive_output\" for extension \".$extension\" in \"$target_abs\""
  if ! (
    cd "$target_abs" || exit 1
    if [ -n "$password" ]; then
      zip -q -9 -r -P "$password" "$archive_output" . -i "*.${extension}" -x "*.DS_Store"
    else
      zip -q -9 -r "$archive_output" . -i "*.${extension}" -x "*.DS_Store"
    fi
  ); then
    _archive_error_archive_aliases "Failed to create ZIP archive for extension \".$extension\"."
    return 1
  fi

  echo "Saved to $archive_output"
}

_archive_zip_sub_archive_aliases() {
  local target_dir="."
  local password=""
  local use_timestamp="0"

  while [ $# -gt 0 ]; do
    case "$1" in
      -p|--password)
        if [ $# -lt 2 ]; then
          _archive_error_archive_aliases "Missing value for option \"$1\"."
          return 1
        fi
        password="$2"
        shift 2
        ;;
      -t|--timestamp)
        use_timestamp="1"
        shift
        ;;
      -h|--help)
        echo -e "Compress each immediate subdirectory to ZIP.\nUsage:\n zip-utils sub [target_directory] [-p password] [-t]"
        return 0
        ;;
      -*)
        _archive_error_archive_aliases "Unknown option \"$1\" for zip-utils sub."
        return 1
        ;;
      *)
        if [ "$target_dir" = "." ]; then
          target_dir="$1"
        else
          _archive_error_archive_aliases "Too many arguments for zip-utils sub."
          return 1
        fi
        shift
        ;;
    esac
  done

  _archive_validate_dir_archive_aliases "$target_dir" "Directory" || return 1
  _archive_require_command_archive_aliases "zip" || return 1

  local timestamp_suffix=""
  timestamp_suffix="$(_archive_timestamp_suffix_archive_aliases "$use_timestamp")"
  local target_abs=""
  target_abs="$(cd "$target_dir" && pwd)"

  local processed_count="0"
  local failed_count="0"
  local sub_dir=""

  while IFS= read -r -d "" sub_dir; do
    local sub_name=""
    sub_name="$(basename "$sub_dir")"
    local archive_output="$target_abs/${sub_name}${timestamp_suffix}.zip"

    echo "Creating ZIP archive \"$archive_output\" from directory \"$sub_dir\""
    if ! (
      cd "$target_abs" || exit 1
      _archive_run_zip_archive_aliases "$archive_output" "$password" "$sub_name"
    ); then
      _archive_warn_archive_aliases "Failed to create ZIP archive for \"$sub_dir\"."
      failed_count=$((failed_count + 1))
      continue
    fi

    processed_count=$((processed_count + 1))
  done < <(find "$target_abs" -mindepth 1 -maxdepth 1 -type d -print0)

  if [ "$processed_count" -eq 0 ] && [ "$failed_count" -eq 0 ]; then
    _archive_warn_archive_aliases "No subdirectories were found in \"$target_abs\"."
    return 1
  fi

  echo "Created $processed_count ZIP archive(s)"
  if [ "$failed_count" -gt 0 ]; then
    _archive_warn_archive_aliases "$failed_count subdirectory archive(s) failed."
  fi
}

_archive_zip_each_archive_aliases() {
  local target_dir="."
  local password=""
  local use_timestamp="0"

  while [ $# -gt 0 ]; do
    case "$1" in
      -p|--password)
        if [ $# -lt 2 ]; then
          _archive_error_archive_aliases "Missing value for option \"$1\"."
          return 1
        fi
        password="$2"
        shift 2
        ;;
      -t|--timestamp)
        use_timestamp="1"
        shift
        ;;
      -h|--help)
        echo -e "Compress each immediate item to ZIP.\nUsage:\n zip-utils each [target_directory] [-p password] [-t]"
        return 0
        ;;
      -*)
        _archive_error_archive_aliases "Unknown option \"$1\" for zip-utils each."
        return 1
        ;;
      *)
        if [ "$target_dir" = "." ]; then
          target_dir="$1"
        else
          _archive_error_archive_aliases "Too many arguments for zip-utils each."
          return 1
        fi
        shift
        ;;
    esac
  done

  _archive_validate_dir_archive_aliases "$target_dir" "Directory" || return 1
  _archive_require_command_archive_aliases "zip" || return 1

  local target_abs=""
  target_abs="$(cd "$target_dir" && pwd)"
  local timestamp_suffix=""
  timestamp_suffix="$(_archive_timestamp_suffix_archive_aliases "$use_timestamp")"

  local manifest_path="$target_abs/password.txt"
  if [ -n "$password" ]; then
    echo "Filename:Password" > "$manifest_path"
  fi

  local processed_count="0"
  local failed_count="0"
  local item_path=""

  while IFS= read -r -d "" item_path; do
    local item_name=""
    item_name="$(basename "$item_path")"

    case "$item_name" in
      *.zip|password.txt)
        continue
        ;;
    esac

    local archive_output="$target_abs/${item_name}${timestamp_suffix}.zip"

    echo "Creating ZIP archive \"$archive_output\" from \"$item_path\""
    if ! (
      cd "$target_abs" || exit 1
      _archive_run_zip_archive_aliases "$archive_output" "$password" "$item_name"
    ); then
      _archive_warn_archive_aliases "Failed to create ZIP archive for \"$item_path\"."
      failed_count=$((failed_count + 1))
      continue
    fi

    if [ -n "$password" ]; then
      echo "$(basename "$archive_output"):$password" >> "$manifest_path"
    fi

    processed_count=$((processed_count + 1))
  done < <(find "$target_abs" -mindepth 1 -maxdepth 1 ! -name ".DS_Store" -print0)

  if [ "$processed_count" -eq 0 ]; then
    if [ -n "$password" ]; then
      rm -f "$manifest_path"
    fi
    _archive_warn_archive_aliases "No suitable items were found in \"$target_abs\"."
    return 1
  fi

  echo "Created $processed_count ZIP archive(s)"
  if [ "$failed_count" -gt 0 ]; then
    _archive_warn_archive_aliases "$failed_count item archive(s) failed."
  fi
}

_archive_zip_each_legacy_archive_aliases() {
  local target_dir=""
  local password=""
  local use_timestamp="0"

  while [ $# -gt 0 ]; do
    case "$1" in
      -d)
        use_timestamp="1"
        shift
        ;;
      -p)
        if [ $# -lt 2 ]; then
          _archive_error_archive_aliases "Missing value for option \"$1\"."
          return 1
        fi
        password="$2"
        shift 2
        ;;
      -h|--help)
        echo -e "Legacy ZIP each wrapper.\nUsage:\n zip-each [target_directory] [-d] [-p password]"
        return 0
        ;;
      -*)
        _archive_error_archive_aliases "Unknown option \"$1\" for zip-each."
        return 1
        ;;
      *)
        if [ -z "$target_dir" ]; then
          target_dir="$1"
        else
          _archive_error_archive_aliases "Too many arguments for zip-each."
          return 1
        fi
        shift
        ;;
    esac
  done

  if [ -n "$password" ]; then
    if [ "$use_timestamp" = "1" ]; then
      _archive_zip_each_archive_aliases "${target_dir:-.}" -p "$password" -t
    else
      _archive_zip_each_archive_aliases "${target_dir:-.}" -p "$password"
    fi
  else
    if [ "$use_timestamp" = "1" ]; then
      _archive_zip_each_archive_aliases "${target_dir:-.}" -t
    else
      _archive_zip_each_archive_aliases "${target_dir:-.}"
    fi
  fi
}

_archive_unzip_file_archive_aliases() {
  local archive_file=""
  local destination_path=""
  local password=""

  while [ $# -gt 0 ]; do
    case "$1" in
      -p|--password)
        if [ $# -lt 2 ]; then
          _archive_error_archive_aliases "Missing value for option \"$1\"."
          return 1
        fi
        password="$2"
        shift 2
        ;;
      -h|--help)
        echo -e "Extract a ZIP file.\nUsage:\n unzip-utils file <zip_file> [destination_path] [-p password]"
        return 0
        ;;
      -*)
        _archive_error_archive_aliases "Unknown option \"$1\" for unzip-utils file."
        return 1
        ;;
      *)
        if [ -z "$archive_file" ]; then
          archive_file="$1"
        elif [ -z "$destination_path" ]; then
          destination_path="$1"
        else
          _archive_error_archive_aliases "Too many arguments for unzip-utils file."
          return 1
        fi
        shift
        ;;
    esac
  done

  if [ -z "$archive_file" ]; then
    echo -e "Extract a ZIP file.\nUsage:\n unzip-utils file <zip_file> [destination_path] [-p password]"
    return 1
  fi

  _archive_validate_file_archive_aliases "$archive_file" "File" || return 1
  _archive_require_command_archive_aliases "unzip" || return 1

  if [ -z "$destination_path" ]; then
    destination_path="$(dirname "$archive_file")"
  fi

  _archive_ensure_dir_archive_aliases "$destination_path" || return 1

  echo "Extracting ZIP archive \"$archive_file\" to \"$destination_path\""
  if [ -n "$password" ]; then
    if ! unzip -q -P "$password" "$archive_file" -d "$destination_path"; then
      _archive_error_archive_aliases "Failed to extract ZIP archive \"$archive_file\"."
      return 1
    fi
  else
    if ! unzip -q "$archive_file" -d "$destination_path"; then
      _archive_error_archive_aliases "Failed to extract ZIP archive \"$archive_file\"."
      return 1
    fi
  fi

  echo "Extracted to $destination_path"
}

_archive_unzip_each_archive_aliases() {
  local target_dir="."
  local password=""

  while [ $# -gt 0 ]; do
    case "$1" in
      -p|--password)
        if [ $# -lt 2 ]; then
          _archive_error_archive_aliases "Missing value for option \"$1\"."
          return 1
        fi
        password="$2"
        shift 2
        ;;
      -h|--help)
        echo -e "Extract all ZIP archives in a directory.\nUsage:\n unzip-utils each [directory_path] [-p password]"
        return 0
        ;;
      -*)
        _archive_error_archive_aliases "Unknown option \"$1\" for unzip-utils each."
        return 1
        ;;
      *)
        if [ "$target_dir" = "." ]; then
          target_dir="$1"
        else
          _archive_error_archive_aliases "Too many arguments for unzip-utils each."
          return 1
        fi
        shift
        ;;
    esac
  done

  _archive_validate_dir_archive_aliases "$target_dir" "Directory" || return 1
  _archive_require_command_archive_aliases "unzip" || return 1

  local target_abs=""
  target_abs="$(cd "$target_dir" && pwd)"
  local processed_count="0"
  local failed_count="0"
  local archive_file=""

  while IFS= read -r -d "" archive_file; do
    local destination_path="$target_abs/$(_archive_strip_archive_suffix_archive_aliases "$archive_file")"
    _archive_ensure_dir_archive_aliases "$destination_path" || {
      failed_count=$((failed_count + 1))
      continue
    }

    echo "Extracting ZIP archive \"$archive_file\" to \"$destination_path\""
    if [ -n "$password" ]; then
      if ! unzip -q -P "$password" "$archive_file" -d "$destination_path"; then
        _archive_warn_archive_aliases "Failed to extract \"$archive_file\"."
        failed_count=$((failed_count + 1))
        continue
      fi
    else
      if ! unzip -q "$archive_file" -d "$destination_path"; then
        _archive_warn_archive_aliases "Failed to extract \"$archive_file\"."
        failed_count=$((failed_count + 1))
        continue
      fi
    fi

    processed_count=$((processed_count + 1))
  done < <(find "$target_abs" -mindepth 1 -maxdepth 1 -type f -name "*.zip" -print0)

  if [ "$processed_count" -eq 0 ] && [ "$failed_count" -eq 0 ]; then
    _archive_warn_archive_aliases "No ZIP archives were found in \"$target_abs\"."
    return 1
  fi

  echo "Extracted $processed_count ZIP archive(s)"
  if [ "$failed_count" -gt 0 ]; then
    _archive_warn_archive_aliases "$failed_count ZIP archive(s) failed."
  fi
}

_archive_tar_dir_archive_aliases() {
  local source_dir=""
  local output_name=""
  local format_name="gz"
  local use_timestamp="0"

  while [ $# -gt 0 ]; do
    case "$1" in
      -f|--format)
        if [ $# -lt 2 ]; then
          _archive_error_archive_aliases "Missing value for option \"$1\"."
          return 1
        fi
        format_name="$2"
        shift 2
        ;;
      -t|--timestamp)
        use_timestamp="1"
        shift
        ;;
      -h|--help)
        echo -e "Compress a directory to TAR.\nUsage:\n tar-utils dir <directory_path> [output_name] [-f format] [-t]"
        return 0
        ;;
      -*)
        _archive_error_archive_aliases "Unknown option \"$1\" for tar-utils dir."
        return 1
        ;;
      *)
        if [ -z "$source_dir" ]; then
          source_dir="$1"
        elif [ -z "$output_name" ]; then
          output_name="$1"
        else
          _archive_error_archive_aliases "Too many arguments for tar-utils dir."
          return 1
        fi
        shift
        ;;
    esac
  done

  if [ -z "$source_dir" ]; then
    echo -e "Compress a directory to TAR.\nUsage:\n tar-utils dir <directory_path> [output_name] [-f format] [-t]"
    return 1
  fi

  _archive_validate_dir_archive_aliases "$source_dir" "Directory" || return 1
  _archive_require_command_archive_aliases "tar" || return 1

  local tar_flag=""
  if ! tar_flag="$(_archive_tar_flag_archive_aliases "$format_name")"; then
    _archive_error_archive_aliases "Unsupported TAR format \"$format_name\"."
    return 1
  fi

  local file_extension=""
  file_extension="$(_archive_tar_extension_archive_aliases "$format_name")"
  local timestamp_suffix=""
  timestamp_suffix="$(_archive_timestamp_suffix_archive_aliases "$use_timestamp")"

  local source_parent=""
  source_parent="$(cd "$(dirname "$source_dir")" && pwd)"
  local source_name=""
  source_name="$(basename "$source_dir")"

  if [ -z "$output_name" ]; then
    output_name="${source_name}${timestamp_suffix}.${file_extension}"
  fi

  local archive_output=""
  archive_output="$(_archive_output_in_cwd_archive_aliases "$output_name")"

  echo "Creating TAR archive \"$archive_output\" from directory \"$source_dir\""
  if ! _archive_run_tar_archive_aliases "$tar_flag" "$archive_output" -C "$source_parent" "$source_name"; then
    _archive_error_archive_aliases "Failed to create TAR archive from \"$source_dir\"."
    return 1
  fi

  echo "Saved to $archive_output"
}

_archive_tar_file_archive_aliases() {
  local source_file=""
  local output_name=""
  local format_name="gz"
  local use_timestamp="0"

  while [ $# -gt 0 ]; do
    case "$1" in
      -f|--format)
        if [ $# -lt 2 ]; then
          _archive_error_archive_aliases "Missing value for option \"$1\"."
          return 1
        fi
        format_name="$2"
        shift 2
        ;;
      -t|--timestamp)
        use_timestamp="1"
        shift
        ;;
      -h|--help)
        echo -e "Compress a file to TAR.\nUsage:\n tar-utils file <file_path> [output_name] [-f format] [-t]"
        return 0
        ;;
      -*)
        _archive_error_archive_aliases "Unknown option \"$1\" for tar-utils file."
        return 1
        ;;
      *)
        if [ -z "$source_file" ]; then
          source_file="$1"
        elif [ -z "$output_name" ]; then
          output_name="$1"
        else
          _archive_error_archive_aliases "Too many arguments for tar-utils file."
          return 1
        fi
        shift
        ;;
    esac
  done

  if [ -z "$source_file" ]; then
    echo -e "Compress a file to TAR.\nUsage:\n tar-utils file <file_path> [output_name] [-f format] [-t]"
    return 1
  fi

  _archive_validate_file_archive_aliases "$source_file" "File" || return 1
  _archive_require_command_archive_aliases "tar" || return 1

  local tar_flag=""
  if ! tar_flag="$(_archive_tar_flag_archive_aliases "$format_name")"; then
    _archive_error_archive_aliases "Unsupported TAR format \"$format_name\"."
    return 1
  fi

  local file_extension=""
  file_extension="$(_archive_tar_extension_archive_aliases "$format_name")"
  local timestamp_suffix=""
  timestamp_suffix="$(_archive_timestamp_suffix_archive_aliases "$use_timestamp")"

  local source_parent=""
  source_parent="$(cd "$(dirname "$source_file")" && pwd)"
  local source_name=""
  source_name="$(basename "$source_file")"

  if [ -z "$output_name" ]; then
    output_name="${source_name}${timestamp_suffix}.${file_extension}"
  fi

  local archive_output=""
  archive_output="$(_archive_output_in_base_dir_archive_aliases "$source_parent" "$output_name")"

  echo "Creating TAR archive \"$archive_output\" from file \"$source_file\""
  if ! _archive_run_tar_archive_aliases "$tar_flag" "$archive_output" -C "$source_parent" "$source_name"; then
    _archive_error_archive_aliases "Failed to create TAR archive from \"$source_file\"."
    return 1
  fi

  echo "Saved to $archive_output"
}

_archive_tar_cur_archive_aliases() {
  local output_name=""
  local format_name="gz"
  local use_timestamp="0"

  while [ $# -gt 0 ]; do
    case "$1" in
      -f|--format)
        if [ $# -lt 2 ]; then
          _archive_error_archive_aliases "Missing value for option \"$1\"."
          return 1
        fi
        format_name="$2"
        shift 2
        ;;
      -t|--timestamp)
        use_timestamp="1"
        shift
        ;;
      -h|--help)
        echo -e "Compress the current directory to TAR.\nUsage:\n tar-utils cur [output_name] [-f format] [-t]"
        return 0
        ;;
      -*)
        _archive_error_archive_aliases "Unknown option \"$1\" for tar-utils cur."
        return 1
        ;;
      *)
        if [ -z "$output_name" ]; then
          output_name="$1"
        else
          _archive_error_archive_aliases "Too many arguments for tar-utils cur."
          return 1
        fi
        shift
        ;;
    esac
  done

  _archive_require_command_archive_aliases "tar" || return 1

  local tar_flag=""
  if ! tar_flag="$(_archive_tar_flag_archive_aliases "$format_name")"; then
    _archive_error_archive_aliases "Unsupported TAR format \"$format_name\"."
    return 1
  fi

  local file_extension=""
  file_extension="$(_archive_tar_extension_archive_aliases "$format_name")"
  local timestamp_suffix=""
  timestamp_suffix="$(_archive_timestamp_suffix_archive_aliases "$use_timestamp")"

  if [ -z "$output_name" ]; then
    output_name="$(basename "$(pwd)")${timestamp_suffix}.${file_extension}"
  fi

  local archive_output=""
  archive_output="$(_archive_output_in_cwd_archive_aliases "$output_name")"
  local current_dir=""
  current_dir="$(pwd)"
  local archive_basename=""
  archive_basename="$(basename "$archive_output")"

  local -a tar_args
  tar_args=("$tar_flag" -cf "$archive_output" --exclude=".DS_Store" --exclude="*/.DS_Store")

  if [ "$(dirname "$archive_output")" = "$current_dir" ]; then
    tar_args+=(--exclude="$archive_basename")
  fi

  echo "Creating TAR archive \"$archive_output\" from current directory"
  if ! tar "${tar_args[@]}" .; then
    _archive_error_archive_aliases "Failed to create TAR archive from current directory."
    return 1
  fi

  echo "Saved to $archive_output"
}

_archive_tar_ext_archive_aliases() {
  local extension=""
  local target_dir="."
  local format_name="gz"
  local use_timestamp="0"

  while [ $# -gt 0 ]; do
    case "$1" in
      -f|--format)
        if [ $# -lt 2 ]; then
          _archive_error_archive_aliases "Missing value for option \"$1\"."
          return 1
        fi
        format_name="$2"
        shift 2
        ;;
      -t|--timestamp)
        use_timestamp="1"
        shift
        ;;
      -h|--help)
        echo -e "Compress files by extension to TAR.\nUsage:\n tar-utils ext <file_extension> [target_directory] [-f format] [-t]"
        return 0
        ;;
      -*)
        _archive_error_archive_aliases "Unknown option \"$1\" for tar-utils ext."
        return 1
        ;;
      *)
        if [ -z "$extension" ]; then
          extension="$1"
        elif [ "$target_dir" = "." ]; then
          target_dir="$1"
        else
          _archive_error_archive_aliases "Too many arguments for tar-utils ext."
          return 1
        fi
        shift
        ;;
    esac
  done

  if [ -z "$extension" ]; then
    echo -e "Compress files by extension to TAR.\nUsage:\n tar-utils ext <file_extension> [target_directory] [-f format] [-t]"
    return 1
  fi

  extension="${extension#.}"
  _archive_validate_dir_archive_aliases "$target_dir" "Directory" || return 1
  _archive_require_command_archive_aliases "tar" || return 1

  local tar_flag=""
  if ! tar_flag="$(_archive_tar_flag_archive_aliases "$format_name")"; then
    _archive_error_archive_aliases "Unsupported TAR format \"$format_name\"."
    return 1
  fi

  local file_extension=""
  file_extension="$(_archive_tar_extension_archive_aliases "$format_name")"
  local timestamp_suffix=""
  timestamp_suffix="$(_archive_timestamp_suffix_archive_aliases "$use_timestamp")"
  local target_abs=""
  target_abs="$(cd "$target_dir" && pwd)"
  local list_file=""
  list_file="$(mktemp "$target_abs/.archive_tar_ext_list.XXXXXX")"

  if ! find "$target_abs" -type f -name "*.${extension}" -print -quit | grep -q "."; then
    rm -f "$list_file"
    _archive_warn_archive_aliases "No files with extension \".$extension\" were found in \"$target_abs\"."
    return 1
  fi

  local output_name="${extension}${timestamp_suffix}.${file_extension}"
  local archive_output=""
  archive_output="$(_archive_output_in_base_dir_archive_aliases "$target_abs" "$output_name")"

  echo "Creating TAR archive \"$archive_output\" for extension \".$extension\" in \"$target_abs\""
  if ! (
    cd "$target_abs" || exit 1
    find . -type f -name "*.${extension}" > "$list_file"
    tar "$tar_flag" -cf "$archive_output" --exclude=".DS_Store" --exclude="*/.DS_Store" -T "$list_file"
  ); then
    rm -f "$list_file"
    _archive_error_archive_aliases "Failed to create TAR archive for extension \".$extension\"."
    return 1
  fi

  rm -f "$list_file"
  echo "Saved to $archive_output"
}

_archive_tar_sub_archive_aliases() {
  local target_dir="."
  local format_name="gz"
  local use_timestamp="0"

  while [ $# -gt 0 ]; do
    case "$1" in
      -f|--format)
        if [ $# -lt 2 ]; then
          _archive_error_archive_aliases "Missing value for option \"$1\"."
          return 1
        fi
        format_name="$2"
        shift 2
        ;;
      -t|--timestamp)
        use_timestamp="1"
        shift
        ;;
      -h|--help)
        echo -e "Compress each immediate subdirectory to TAR.\nUsage:\n tar-utils sub [target_directory] [-f format] [-t]"
        return 0
        ;;
      -*)
        _archive_error_archive_aliases "Unknown option \"$1\" for tar-utils sub."
        return 1
        ;;
      *)
        if [ "$target_dir" = "." ]; then
          target_dir="$1"
        else
          _archive_error_archive_aliases "Too many arguments for tar-utils sub."
          return 1
        fi
        shift
        ;;
    esac
  done

  _archive_validate_dir_archive_aliases "$target_dir" "Directory" || return 1
  _archive_require_command_archive_aliases "tar" || return 1

  local tar_flag=""
  if ! tar_flag="$(_archive_tar_flag_archive_aliases "$format_name")"; then
    _archive_error_archive_aliases "Unsupported TAR format \"$format_name\"."
    return 1
  fi

  local file_extension=""
  file_extension="$(_archive_tar_extension_archive_aliases "$format_name")"
  local timestamp_suffix=""
  timestamp_suffix="$(_archive_timestamp_suffix_archive_aliases "$use_timestamp")"
  local target_abs=""
  target_abs="$(cd "$target_dir" && pwd)"

  local processed_count="0"
  local failed_count="0"
  local sub_dir=""

  while IFS= read -r -d "" sub_dir; do
    local sub_name=""
    sub_name="$(basename "$sub_dir")"
    local archive_output="$target_abs/${sub_name}${timestamp_suffix}.${file_extension}"

    echo "Creating TAR archive \"$archive_output\" from directory \"$sub_dir\""
    if ! _archive_run_tar_archive_aliases "$tar_flag" "$archive_output" -C "$target_abs" "$sub_name"; then
      _archive_warn_archive_aliases "Failed to create TAR archive for \"$sub_dir\"."
      failed_count=$((failed_count + 1))
      continue
    fi

    processed_count=$((processed_count + 1))
  done < <(find "$target_abs" -mindepth 1 -maxdepth 1 -type d -print0)

  if [ "$processed_count" -eq 0 ] && [ "$failed_count" -eq 0 ]; then
    _archive_warn_archive_aliases "No subdirectories were found in \"$target_abs\"."
    return 1
  fi

  echo "Created $processed_count TAR archive(s)"
  if [ "$failed_count" -gt 0 ]; then
    _archive_warn_archive_aliases "$failed_count subdirectory archive(s) failed."
  fi
}

_archive_tar_each_archive_aliases() {
  local target_dir="."
  local format_name="gz"
  local use_timestamp="0"

  while [ $# -gt 0 ]; do
    case "$1" in
      -f|--format)
        if [ $# -lt 2 ]; then
          _archive_error_archive_aliases "Missing value for option \"$1\"."
          return 1
        fi
        format_name="$2"
        shift 2
        ;;
      -t|--timestamp)
        use_timestamp="1"
        shift
        ;;
      -h|--help)
        echo -e "Compress each immediate item to TAR.\nUsage:\n tar-utils each [target_directory] [-f format] [-t]"
        return 0
        ;;
      -*)
        _archive_error_archive_aliases "Unknown option \"$1\" for tar-utils each."
        return 1
        ;;
      *)
        if [ "$target_dir" = "." ]; then
          target_dir="$1"
        else
          _archive_error_archive_aliases "Too many arguments for tar-utils each."
          return 1
        fi
        shift
        ;;
    esac
  done

  _archive_validate_dir_archive_aliases "$target_dir" "Directory" || return 1
  _archive_require_command_archive_aliases "tar" || return 1

  local tar_flag=""
  if ! tar_flag="$(_archive_tar_flag_archive_aliases "$format_name")"; then
    _archive_error_archive_aliases "Unsupported TAR format \"$format_name\"."
    return 1
  fi

  local file_extension=""
  file_extension="$(_archive_tar_extension_archive_aliases "$format_name")"
  local timestamp_suffix=""
  timestamp_suffix="$(_archive_timestamp_suffix_archive_aliases "$use_timestamp")"
  local target_abs=""
  target_abs="$(cd "$target_dir" && pwd)"

  local processed_count="0"
  local failed_count="0"
  local item_path=""

  while IFS= read -r -d "" item_path; do
    local item_name=""
    item_name="$(basename "$item_path")"

    if _archive_is_tar_archive_archive_aliases "$item_name"; then
      continue
    fi

    local archive_output="$target_abs/${item_name}${timestamp_suffix}.${file_extension}"

    echo "Creating TAR archive \"$archive_output\" from \"$item_path\""
    if ! _archive_run_tar_archive_aliases "$tar_flag" "$archive_output" -C "$target_abs" "$item_name"; then
      _archive_warn_archive_aliases "Failed to create TAR archive for \"$item_path\"."
      failed_count=$((failed_count + 1))
      continue
    fi

    processed_count=$((processed_count + 1))
  done < <(find "$target_abs" -mindepth 1 -maxdepth 1 ! -name ".DS_Store" -print0)

  if [ "$processed_count" -eq 0 ]; then
    _archive_warn_archive_aliases "No suitable items were found in \"$target_abs\"."
    return 1
  fi

  echo "Created $processed_count TAR archive(s)"
  if [ "$failed_count" -gt 0 ]; then
    _archive_warn_archive_aliases "$failed_count item archive(s) failed."
  fi
}

_archive_untar_file_archive_aliases() {
  local archive_file=""
  local destination_path=""

  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help)
        echo -e "Extract a TAR archive.\nUsage:\n untar-utils file <tar_file> [destination_path]"
        return 0
        ;;
      -*)
        _archive_error_archive_aliases "Unknown option \"$1\" for untar-utils file."
        return 1
        ;;
      *)
        if [ -z "$archive_file" ]; then
          archive_file="$1"
        elif [ -z "$destination_path" ]; then
          destination_path="$1"
        else
          _archive_error_archive_aliases "Too many arguments for untar-utils file."
          return 1
        fi
        shift
        ;;
    esac
  done

  if [ -z "$archive_file" ]; then
    echo -e "Extract a TAR archive.\nUsage:\n untar-utils file <tar_file> [destination_path]"
    return 1
  fi

  _archive_validate_file_archive_aliases "$archive_file" "File" || return 1
  _archive_require_command_archive_aliases "tar" || return 1

  if [ -z "$destination_path" ]; then
    destination_path="$(dirname "$archive_file")"
  fi

  _archive_ensure_dir_archive_aliases "$destination_path" || return 1

  echo "Extracting TAR archive \"$archive_file\" to \"$destination_path\""
  if ! _archive_extract_tar_archive_aliases "$archive_file" "$destination_path"; then
    _archive_error_archive_aliases "Failed to extract TAR archive \"$archive_file\"."
    return 1
  fi

  echo "Extracted to $destination_path"
}

_archive_untar_each_archive_aliases() {
  local target_dir="."

  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help)
        echo -e "Extract all TAR archives in a directory.\nUsage:\n untar-utils each [directory_path]"
        return 0
        ;;
      -*)
        _archive_error_archive_aliases "Unknown option \"$1\" for untar-utils each."
        return 1
        ;;
      *)
        if [ "$target_dir" = "." ]; then
          target_dir="$1"
        else
          _archive_error_archive_aliases "Too many arguments for untar-utils each."
          return 1
        fi
        shift
        ;;
    esac
  done

  _archive_validate_dir_archive_aliases "$target_dir" "Directory" || return 1
  _archive_require_command_archive_aliases "tar" || return 1

  local target_abs=""
  target_abs="$(cd "$target_dir" && pwd)"
  local processed_count="0"
  local failed_count="0"
  local archive_file=""

  while IFS= read -r -d "" archive_file; do
    local destination_path="$target_abs/$(_archive_strip_archive_suffix_archive_aliases "$archive_file")"
    _archive_ensure_dir_archive_aliases "$destination_path" || {
      failed_count=$((failed_count + 1))
      continue
    }

    echo "Extracting TAR archive \"$archive_file\" to \"$destination_path\""
    if ! _archive_extract_tar_archive_aliases "$archive_file" "$destination_path"; then
      _archive_warn_archive_aliases "Failed to extract \"$archive_file\"."
      failed_count=$((failed_count + 1))
      continue
    fi

    processed_count=$((processed_count + 1))
  done < <(find "$target_abs" -mindepth 1 -maxdepth 1 -type f \( -name "*.tar" -o -name "*.tar.gz" -o -name "*.tgz" -o -name "*.tar.bz2" -o -name "*.tbz2" -o -name "*.tar.xz" -o -name "*.txz" \) -print0)

  if [ "$processed_count" -eq 0 ] && [ "$failed_count" -eq 0 ]; then
    _archive_warn_archive_aliases "No TAR archives were found in \"$target_abs\"."
    return 1
  fi

  echo "Extracted $processed_count TAR archive(s)"
  if [ "$failed_count" -gt 0 ]; then
    _archive_warn_archive_aliases "$failed_count TAR archive(s) failed."
  fi
}

_archive_zip_utils_archive_aliases() {
  if [ $# -eq 0 ]; then
    _archive_zip_usage_archive_aliases
    return 1
  fi

  local subcommand="$1"
  shift

  case "$subcommand" in
    dir)
      _archive_zip_dir_archive_aliases "$@"
      ;;
    file)
      _archive_zip_file_archive_aliases "$@"
      ;;
    cur)
      _archive_zip_cur_archive_aliases "$@"
      ;;
    ext)
      _archive_zip_ext_archive_aliases "$@"
      ;;
    sub)
      _archive_zip_sub_archive_aliases "$@"
      ;;
    each)
      _archive_zip_each_archive_aliases "$@"
      ;;
    -h|--help|help)
      _archive_zip_usage_archive_aliases
      ;;
    *)
      _archive_error_archive_aliases "Unknown zip-utils command \"$subcommand\"."
      _archive_zip_usage_archive_aliases
      return 1
      ;;
  esac
}

_archive_unzip_utils_archive_aliases() {
  if [ $# -eq 0 ]; then
    _archive_unzip_usage_archive_aliases
    return 1
  fi

  local subcommand="$1"
  shift

  case "$subcommand" in
    file)
      _archive_unzip_file_archive_aliases "$@"
      ;;
    each)
      _archive_unzip_each_archive_aliases "$@"
      ;;
    -h|--help|help)
      _archive_unzip_usage_archive_aliases
      ;;
    *)
      _archive_error_archive_aliases "Unknown unzip-utils command \"$subcommand\"."
      _archive_unzip_usage_archive_aliases
      return 1
      ;;
  esac
}

_archive_tar_utils_archive_aliases() {
  if [ $# -eq 0 ]; then
    _archive_tar_usage_archive_aliases
    return 1
  fi

  local subcommand="$1"
  shift

  case "$subcommand" in
    dir)
      _archive_tar_dir_archive_aliases "$@"
      ;;
    file)
      _archive_tar_file_archive_aliases "$@"
      ;;
    cur)
      _archive_tar_cur_archive_aliases "$@"
      ;;
    ext)
      _archive_tar_ext_archive_aliases "$@"
      ;;
    sub)
      _archive_tar_sub_archive_aliases "$@"
      ;;
    each)
      _archive_tar_each_archive_aliases "$@"
      ;;
    -h|--help|help)
      _archive_tar_usage_archive_aliases
      ;;
    *)
      _archive_error_archive_aliases "Unknown tar-utils command \"$subcommand\"."
      _archive_tar_usage_archive_aliases
      return 1
      ;;
  esac
}

_archive_untar_utils_archive_aliases() {
  if [ $# -eq 0 ]; then
    _archive_untar_usage_archive_aliases
    return 1
  fi

  local subcommand="$1"
  shift

  case "$subcommand" in
    file)
      _archive_untar_file_archive_aliases "$@"
      ;;
    each)
      _archive_untar_each_archive_aliases "$@"
      ;;
    -h|--help|help)
      _archive_untar_usage_archive_aliases
      ;;
    *)
      _archive_error_archive_aliases "Unknown untar-utils command \"$subcommand\"."
      _archive_untar_usage_archive_aliases
      return 1
      ;;
  esac
}

_archive_combined_archive_aliases() {
  if [ $# -eq 1 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ "$1" = "help" ]; }; then
    _archive_combined_usage_archive_aliases
    return 0
  fi

  if [ $# -lt 2 ]; then
    _archive_combined_usage_archive_aliases
    return 1
  fi

  local action="$1"
  local archive_type="$2"
  shift 2

  case "$action" in
    compress)
      case "$archive_type" in
        zip)
          _archive_zip_utils_archive_aliases "$@"
          ;;
        tar)
          _archive_tar_utils_archive_aliases "$@"
          ;;
        *)
          _archive_error_archive_aliases "Unknown archive type \"$archive_type\"."
          return 1
          ;;
      esac
      ;;
    extract)
      case "$archive_type" in
        zip)
          _archive_unzip_utils_archive_aliases "$@"
          ;;
        tar)
          _archive_untar_utils_archive_aliases "$@"
          ;;
        *)
          _archive_error_archive_aliases "Unknown archive type \"$archive_type\"."
          return 1
          ;;
      esac
      ;;
    -h|--help|help)
      _archive_combined_usage_archive_aliases
      ;;
    *)
      _archive_error_archive_aliases "Unknown archive-utils action \"$action\"."
      _archive_combined_usage_archive_aliases
      return 1
      ;;
  esac
}

_archive_auto_extract_archive_aliases() {
  local archive_file="$1"
  local destination_path="$2"

  case "$archive_file" in
    *.zip)
      _archive_unzip_file_archive_aliases "$archive_file" "$destination_path"
      ;;
    *.tar|*.tar.gz|*.tgz|*.tar.bz2|*.tbz2|*.tar.xz|*.txz)
      _archive_untar_file_archive_aliases "$archive_file" "$destination_path"
      ;;
    *.rar)
      _archive_require_command_archive_aliases "unrar" || return 1
      if ! unrar x "$archive_file" "$destination_path"; then
        _archive_error_archive_aliases "Failed to extract RAR archive \"$archive_file\"."
        return 1
      fi
      ;;
    *.7z)
      _archive_require_command_archive_aliases "7z" || return 1
      if ! 7z x "$archive_file" "-o$destination_path"; then
        _archive_error_archive_aliases "Failed to extract 7z archive \"$archive_file\"."
        return 1
      fi
      ;;
    *)
      _archive_error_archive_aliases "Unsupported archive format \"$archive_file\"."
      return 1
      ;;
  esac
}

# ==========================
# Public Alias Entry Points
# ==========================

alias zip-utils='() { _archive_zip_utils_archive_aliases "$@"; }'  # Unified ZIP compression entry point
alias zip-cur='() { _archive_zip_cur_archive_aliases "$@"; }'  # Compress current directory to ZIP
alias zip-dir='() { _archive_zip_dir_archive_aliases "$@"; }'  # Compress a directory to ZIP
alias zip-dirp='() {
  local source_dir="$1"
  local password="$2"
  local output_name="${3:-}"

  if [ -n "$output_name" ]; then
    _archive_zip_dir_archive_aliases "$source_dir" "$output_name" -p "$password"
  else
    _archive_zip_dir_archive_aliases "$source_dir" -p "$password"
  fi
}'  # Compress a directory to ZIP with password
alias zip-ext='() { _archive_zip_ext_archive_aliases "$@"; }'  # Compress files by extension to ZIP
alias zip-sub='() { _archive_zip_sub_archive_aliases "$@"; }'  # Compress each subdirectory to ZIP
alias zip-each='() { _archive_zip_each_legacy_archive_aliases "$@"; }'  # Legacy ZIP each wrapper
alias zip-single='() { _archive_zip_file_archive_aliases "$@"; }'  # Compress one file to ZIP
alias zip-singlep='() {
  local source_file="$1"
  local password="$2"
  local output_name="${3:-}"

  if [ -n "$output_name" ]; then
    _archive_zip_file_archive_aliases "$source_file" "$output_name" -p "$password"
  else
    _archive_zip_file_archive_aliases "$source_file" -p "$password"
  fi
}'  # Compress one file to ZIP with password

alias unzip-utils='() { _archive_unzip_utils_archive_aliases "$@"; }'  # Unified ZIP extraction entry point
alias unzip-file='() { _archive_unzip_file_archive_aliases "$@"; }'  # Extract one ZIP archive
alias unzip-each='() { _archive_unzip_each_archive_aliases "$@"; }'  # Extract all ZIP archives in a directory
alias unzip-pwd='() {
  local archive_file="$1"
  local password="$2"
  local destination_path="${3:-}"

  if [ -n "$destination_path" ]; then
    _archive_unzip_file_archive_aliases "$archive_file" "$destination_path" -p "$password"
  else
    _archive_unzip_file_archive_aliases "$archive_file" -p "$password"
  fi
}'  # Extract one ZIP archive with password

alias tar-utils='() { _archive_tar_utils_archive_aliases "$@"; }'  # Unified TAR compression entry point
alias tar-dir='() { _archive_tar_dir_archive_aliases "$@"; }'  # Compress a directory to TAR
alias tar-file='() { _archive_tar_file_archive_aliases "$@"; }'  # Compress a file to TAR
alias tar-cur='() { _archive_tar_cur_archive_aliases "$@"; }'  # Compress current directory to TAR
alias tar-ext='() { _archive_tar_ext_archive_aliases "$@"; }'  # Compress files by extension to TAR
alias tar-sub='() { _archive_tar_sub_archive_aliases "$@"; }'  # Compress each subdirectory to TAR
alias tar-each='() { _archive_tar_each_archive_aliases "$@"; }'  # Compress each item to TAR
alias tgz-dir='() { _archive_tar_dir_archive_aliases "$@" -f gz; }'  # Compress a directory to tar.gz
alias tbz2-dir='() { _archive_tar_dir_archive_aliases "$@" -f bz2; }'  # Compress a directory to tar.bz2
alias txz-dir='() { _archive_tar_dir_archive_aliases "$@" -f xz; }'  # Compress a directory to tar.xz

alias untar-utils='() { _archive_untar_utils_archive_aliases "$@"; }'  # Unified TAR extraction entry point
alias untar-file='() { _archive_untar_file_archive_aliases "$@"; }'  # Extract one TAR archive
alias untar-each='() { _archive_untar_each_archive_aliases "$@"; }'  # Extract all TAR archives in a directory

alias archive-utils='() { _archive_combined_archive_aliases "$@"; }'  # Combined ZIP and TAR dispatcher
alias extract='() {
  if [ $# -eq 0 ]; then
    _archive_extract_usage_archive_aliases
    return 1
  fi

  local archive_file="$1"
  local destination_path="${2:-$(dirname "$archive_file")}"

  _archive_validate_file_archive_aliases "$archive_file" "File" || return 1
  _archive_ensure_dir_archive_aliases "$destination_path" || return 1

  echo "Extracting \"$archive_file\" to \"$destination_path\""
  _archive_auto_extract_archive_aliases "$archive_file" "$destination_path"
}'  # Auto-detect archive type and extract it

alias archive-help='() { _archive_help_archive_aliases; }'  # Display help for archive management aliases
