# Description: Download related aliases for file downloading operations with various options.

# Helper functions for download aliases
_show_error_download_aliases() {
  echo "$1" >&2
  return 1
}

_check_command_download_aliases() {
  if ! command -v "$1" &> /dev/null; then
    _show_error_download_aliases "Error: Required command \"$1\" not found. Please install it first."
    return 1
  fi
  return 0
}

_check_integrity_download_aliases() {
  local file="$1"
  local hash_type="$2"
  local expected_hash="$3"

  if [ ! -f "$file" ]; then
    _show_error_download_aliases "Error: File \"$file\" not found."
    return 1
  fi

  # Generate hash based on type
  local actual_hash=""
  case "$hash_type" in
    md5)
      if command -v md5sum &> /dev/null; then
        actual_hash=$(md5sum "$file" | awk "{print \$1}")
      elif command -v md5 &> /dev/null; then
        # macOS uses md5 instead of md5sum
        actual_hash=$(md5 -q "$file")
      else
        _show_error_download_aliases "Error: Neither md5sum nor md5 command found."
        return 1
      fi
      ;;
    sha1)
      if command -v sha1sum &> /dev/null; then
        actual_hash=$(sha1sum "$file" | awk "{print \$1}")
      elif command -v shasum &> /dev/null; then
        actual_hash=$(shasum -a 1 "$file" | awk "{print \$1}")
      else
        _show_error_download_aliases "Error: Neither sha1sum nor shasum command found."
        return 1
      fi
      ;;
    sha256)
      if command -v sha256sum &> /dev/null; then
        actual_hash=$(sha256sum "$file" | awk "{print \$1}")
      elif command -v shasum &> /dev/null; then
        actual_hash=$(shasum -a 256 "$file" | awk "{print \$1}")
      else
        _show_error_download_aliases "Error: Neither sha256sum nor shasum command found."
        return 1
      fi
      ;;
    *)
      _show_error_download_aliases "Error: Unsupported hash type \"$hash_type\". Supported types: md5, sha1, sha256."
      return 1
      ;;
  esac

  # Compare hashes (case insensitive)
  if [ "$(echo "$actual_hash" | tr '[:upper:]' '[:lower:]')" = "$(echo "$expected_hash" | tr '[:upper:]' '[:lower:]')" ]; then
    echo "Integrity verification passed: $hash_type hash matches."
    return 0
  else
    _show_error_download_aliases "Integrity verification failed: $hash_type hash mismatch."
    _show_error_download_aliases "Expected: $expected_hash"
    _show_error_download_aliases "Actual:   $actual_hash"
    return 1
  fi
}

_extract_file_download_aliases() {
  local file="$1"
  local target_dir="${2:-$(dirname $file)}"

  if [ ! -f "$file" ]; then
    _show_error_download_aliases "Error: File \"$file\" not found."
    return 1
  fi

  # Create target directory if it doesn"t exist
  if [ ! -d "$target_dir" ]; then
    mkdir -p "$target_dir" || {
      _show_error_download_aliases "Error: Failed to create directory $target_dir."
      return 1
    }
  fi

  echo "Extracting $file to $target_dir..."

  # Extract based on file extension
  case "$file" in
    *.tar.gz|*.tgz)
      tar -xzf "$file" -C "$target_dir"
      ;;
    *.tar.bz2|*.tbz2)
      tar -xjf "$file" -C "$target_dir"
      ;;
    *.tar.xz|*.txz)
      tar -xJf "$file" -C "$target_dir"
      ;;
    *.tar)
      tar -xf "$file" -C "$target_dir"
      ;;
    *.gz)
      gunzip -c "$file" > "$target_dir/$(basename "${file%.gz}")"
      ;;
    *.bz2)
      bunzip2 -c "$file" > "$target_dir/$(basename "${file%.bz2}")"
      ;;
    *.zip)
      unzip -q "$file" -d "$target_dir"
      ;;
    *.rar)
      if command -v unrar &> /dev/null; then
        unrar x "$file" "$target_dir"
      else
        _show_error_download_aliases "Error: unrar command not found. Please install it first."
        return 1
      fi
      ;;
    *.7z)
      if command -v 7z &> /dev/null; then
        7z x "$file" -o"$target_dir"
      else
        _show_error_download_aliases "Error: 7z command not found. Please install it first."
        return 1
      fi
      ;;
    *)
      _show_error_download_aliases "Error: Unsupported archive format for \"$file\"."
      return 1
      ;;
  esac

  if [ $? -eq 0 ]; then
    echo "Successfully extracted \"$file\" to \"$target_dir\"."
    return 0
  else
    _show_error_download_aliases "Extraction failed for \"$file\"."
    return 1
  fi
}

# Single file download
alias dl-file='() {
  if ! _check_command_download_aliases curl; then
    return 1
  fi

  # Parse usage and help
  if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo -e "Download a single file.\nUsage:\n dl-file <url:required> [options]\n\nOptions:\n  -o, --output PATH      : Output path (default: derived from URL)\n  -r, --retries N        : Number of retries (default: 3)\n  -l, --limit SPEED      : Limit download speed (e.g., 1m = 1MB/s)\n  -a, --auto-extract     : Auto extract archive after download\n  -L, --log              : Log download progress to file\n  -H, --header HEADER    : Add custom header (can be used multiple times)\n  -v, --verify HASH:TYPE : Verify file integrity (TYPE: md5, sha1, sha256)\n  -h, --help             : Show this help message\n\nExamples:\n  dl-file https://example.com/file.zip\n  dl-file https://example.com/file.zip -o ~/Downloads/myfile.zip -r 5 -l 1m\n  dl-file https://example.com/file.zip -a -H \"Authorization: Bearer token\"\n  dl-file https://example.com/file.zip -v d41d8cd98f00b204e9800998ecf8427e:md5"
    return 0
  fi

  local url="$1"
  shift

  # Default values
  local output_path=""
  local retries=3
  local limit_speed=""
  local auto_extract=false
  local log_enabled=false
  local log_file=""
  local headers=()
  local verify_hash=""
  local verify_type=""

  # Parse options
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -o|--output)
        output_path="$2"
        shift 2
        ;;
      -r|--retries)
        retries="$2"
        shift 2
        ;;
      -l|--limit)
        limit_speed="$2"
        shift 2
        ;;
      -a|--auto-extract)
        auto_extract=true
        shift
        ;;
      -L|--log)
        log_enabled=true
        shift
        ;;
      -H|--header)
        headers+=("$2")
        shift 2
        ;;
      -v|--verify)
        IFS=":" read -r verify_hash verify_type <<< "$2"
        shift 2
        ;;
      *)
        _show_error_download_aliases "Error: Unknown option \"$1\""
        return 1
        ;;
    esac
  done

  # Determine output path if not provided
  if [ -z "$output_path" ]; then
    output_path="$(basename "$url")"
  fi

  # Create directory if it doesn"t exist
  local dir_path=$(dirname "$output_path")
  if [ ! -d "$dir_path" ] && [ "$dir_path" != "." ]; then
    if ! mkdir -p "$dir_path"; then
      _show_error_download_aliases "Failed to create directory: $dir_path"
      return 1
    fi
  fi

  # Set up logging
  if $log_enabled; then
    log_file="${output_path}.log"
    echo "Download started at $(date)" > "$log_file"
    echo "URL: $url" >> "$log_file"
  fi

  # Prepare curl command
  local curl_opts=("-L" "-o" "$output_path" "--retry" "$retries")

  # Add limit speed option
  if [ -n "$limit_speed" ]; then
    curl_opts+=("--limit-rate" "$limit_speed")
    [ $log_enabled = true ] && echo "Speed limit: $limit_speed" >> "$log_file"
  fi

  # Add headers
  for header in "${headers[@]}"; do
    curl_opts+=("-H" "$header")
    [ $log_enabled = true ] && echo "Header: $header" >> "$log_file"
  done

  # Download progress settings
  if [ -t 1 ]; then  # If terminal is interactive
    curl_opts+=("--progress-bar")
  else
    curl_opts+=("-s")
  fi

  echo "Downloading from $url to $output_path..."

  # Run the download
  if $log_enabled; then
    curl "${curl_opts[@]}" "$url" 2>> "$log_file"
  else
    curl "${curl_opts[@]}" "$url"
  fi

  local status=$?
  if [ $status -ne 0 ]; then
    _show_error_download_aliases "Download failed. Check the URL and your internet connection."
    [ $log_enabled = true ] && echo "Download failed with status $status at $(date)" >> "$log_file"
    return 1
  fi

  echo "Download complete: $output_path"
  [ $log_enabled = true ] && echo "Download completed successfully at $(date)" >> "$log_file"

  # Verify file integrity if requested
  if [ -n "$verify_hash" ] && [ -n "$verify_type" ]; then
    echo "Verifying file integrity using $verify_type hash..."
    [ $log_enabled = true ] && echo "Verifying file integrity using $verify_type hash..." >> "$log_file"

    if ! _check_integrity_download_aliases "$output_path" "$verify_type" "$verify_hash"; then
      [ $log_enabled = true ] && echo "Integrity verification failed" >> "$log_file"
      return 1
    fi

    [ $log_enabled = true ] && echo "Integrity verification passed" >> "$log_file"
  fi

  # Auto extract if requested
  if $auto_extract; then
    echo "Auto-extracting downloaded file..."
    [ $log_enabled = true ] && echo "Auto-extracting downloaded file..." >> "$log_file"

    if ! _extract_file_download_aliases "$output_path"; then
      [ $log_enabled = true ] && echo "Extraction failed" >> "$log_file"
      return 1
    fi

    [ $log_enabled = true ] && echo "Extraction completed successfully" >> "$log_file"
  fi

  return 0
}' # Download a single file with options

# Batch download from a list of URLs
alias dl-batch='() {
  if ! _check_command_download_aliases curl; then
    return 1
  fi

  # Parse usage and help
  if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo -e "Batch download multiple files from a list of URLs.\nUsage:\n dl-batch <url_list_file:required|url1 url2...> [options]\n\nOptions:\n  -o, --output-dir DIR   : Output directory (default: current directory)\n  -r, --retries N        : Number of retries (default: 3)\n  -l, --limit SPEED      : Limit download speed (e.g., 1m = 1MB/s)\n  -a, --auto-extract     : Auto extract archives after download\n  -L, --log              : Log download progress to file\n  -H, --header HEADER    : Add custom header (can be used multiple times)\n  -p, --parallel N       : Number of parallel downloads (default: 1)\n  -h, --help             : Show this help message\n\nExamples:\n  dl-batch urls.txt -o ~/Downloads -r 5 -l 1m\n  dl-batch https://example.com/file1.zip https://example.com/file2.zip -a\n  dl-batch urls.txt -p 3 -H \"Authorization: Bearer token\""
    return 0
  fi

  # Check if first argument is a file or a URL
  local url_list=()
  if [ -f "$1" ]; then
    # Read URLs from file
    while IFS= read -r line || [ -n "$line" ]; do
      # Skip empty lines and comments
      [[ -z "$line" || "$line" =~ ^# ]] && continue
      url_list+=("$line")
    done < "$1"
    shift
  else
    # Collect URLs from command line until we hit an option
    while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
      url_list+=("$1")
      shift
    done
  fi

  # Check if we have any URLs
  if [ ${#url_list[@]} -eq 0 ]; then
    _show_error_download_aliases "Error: No URLs provided."
    return 1
  fi

  # Default values
  local output_dir="."
  local retries=3
  local limit_speed=""
  local auto_extract=false
  local log_enabled=false
  local log_file="dl-batch.log"
  local headers=()
  local parallel=1

  # Parse options
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -o|--output-dir)
        output_dir="$2"
        shift 2
        ;;
      -r|--retries)
        retries="$2"
        shift 2
        ;;
      -l|--limit)
        limit_speed="$2"
        shift 2
        ;;
      -a|--auto-extract)
        auto_extract=true
        shift
        ;;
      -L|--log)
        log_enabled=true
        shift
        ;;
      -H|--header)
        headers+=("$2")
        shift 2
        ;;
      -p|--parallel)
        parallel="$2"
        shift 2
        ;;
      *)
        _show_error_download_aliases "Error: Unknown option \"$1\""
        return 1
        ;;
    esac
  done

  # Create output directory if it doesn"t exist
  if [ ! -d "$output_dir" ]; then
    if ! mkdir -p "$output_dir"; then
      _show_error_download_aliases "Failed to create directory: $output_dir"
      return 1
    fi
  fi

  # Set up logging
  if $log_enabled; then
    log_file="${output_dir}/${log_file}"
    echo "Batch download started at $(date)" > "$log_file"
    echo "Number of URLs: ${#url_list[@]}" >> "$log_file"
  fi

  # Download files
  echo "Starting batch download of ${#url_list[@]} files to $output_dir..."

  # Check for parallel download capabilities
  local use_parallel=false
  if [ "$parallel" -gt 1 ]; then
    if ! _check_command_download_aliases xargs; then
      echo "Warning: xargs not found, falling back to sequential downloads."
    elif ! _check_command_download_aliases parallel; then
      echo "Warning: GNU parallel not found, falling back to sequential downloads."
    else
      use_parallel=true
    fi
  fi

  local success_count=0
  local fail_count=0

  if $use_parallel; then
    # Create a temporary file for the URLs
    local tmp_file=$(mktemp)
    for url in "${url_list[@]}"; do
      echo "$url" >> "$tmp_file"
    done

    # Build the download command with options
    local cmd="dl-file {} -o ${output_dir}/\$(basename {}) -r $retries"
    [ -n "$limit_speed" ] && cmd+=" -l $limit_speed"
    $auto_extract && cmd+=" -a"
    $log_enabled && cmd+=" -L"
    for header in "${headers[@]}"; do
      cmd+=" -H \"$header\""
    done

    # Run the parallel downloads
    echo "Running $parallel parallel downloads..."
    cat "$tmp_file" | parallel -j "$parallel" "$cmd"

    # Count results (approximate)
    success_count=$(ls -la "$output_dir" | wc -l)
    success_count=$((success_count - 2))  # Adjust for . and .. entries
    fail_count=$((${#url_list[@]} - success_count))

    # Clean up
    rm "$tmp_file"
  else
    # Sequential downloads
    for url in "${url_list[@]}"; do
      local filename=$(basename "$url")
      local output_path="${output_dir}/${filename}"

      echo "Downloading $url to $output_path..."
      [ $log_enabled = true ] && echo "Downloading $url to $output_path..." >> "$log_file"

      # Prepare curl command
      local curl_opts=("-L" "-o" "$output_path" "--retry" "$retries")

      # Add limit speed option
      [ -n "$limit_speed" ] && curl_opts+=("--limit-rate" "$limit_speed")

      # Add headers
      for header in "${headers[@]}"; do
        curl_opts+=("-H" "$header")
      done

      # Download progress settings
      if [ -t 1 ]; then  # If terminal is interactive
        curl_opts+=("--progress-bar")
      else
        curl_opts+=("-s")
      fi

      # Run the download
      curl "${curl_opts[@]}" "$url"

      if [ $? -eq 0 ]; then
        echo "Successfully downloaded $url"
        [ $log_enabled = true ] && echo "Successfully downloaded $url" >> "$log_file"
        ((success_count++))

        # Auto extract if requested
        if $auto_extract; then
          echo "Auto-extracting $output_path..."
          [ $log_enabled = true ] && echo "Auto-extracting $output_path..." >> "$log_file"

          if _extract_file_download_aliases "$output_path" "$output_dir"; then
            [ $log_enabled = true ] && echo "Extraction completed successfully" >> "$log_file"
          else
            [ $log_enabled = true ] && echo "Extraction failed" >> "$log_file"
          fi
        fi
      else
        echo "Failed to download $url"
        [ $log_enabled = true ] && echo "Failed to download $url" >> "$log_file"
        ((fail_count++))
      fi
    done
  fi

  # Print summary
  echo "Batch download summary:"
  echo "  Successfully downloaded: $success_count"
  echo "  Failed: $fail_count"

  if $log_enabled; then
    echo "Batch download completed at $(date)" >> "$log_file"
    echo "Summary:" >> "$log_file"
    echo "  Successfully downloaded: $success_count" >> "$log_file"
    echo "  Failed: $fail_count" >> "$log_file"
  fi

  # Return error if any downloads failed
  if [ $fail_count -gt 0 ]; then
    return 1
  fi

  return 0
}' # Batch download multiple files from a list of URLs

# Download from URL with options to resume downloads
alias dl-resume='() {
  if ! _check_command_download_aliases curl; then
    return 1
  fi

  # Parse usage and help
  if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo -e "Download a file with resume capability.\nUsage:\n dl-resume <url:required> [options]\n\nOptions:\n  -o, --output PATH      : Output path (default: derived from URL)\n  -r, --retries N        : Number of retries (default: 3)\n  -l, --limit SPEED      : Limit download speed (e.g., 1m = 1MB/s)\n  -a, --auto-extract     : Auto extract archive after download\n  -L, --log              : Log download progress to file\n  -H, --header HEADER    : Add custom header (can be used multiple times)\n  -v, --verify HASH:TYPE : Verify file integrity (TYPE: md5, sha1, sha256)\n  -h, --help             : Show this help message\n\nExamples:\n  dl-resume https://example.com/large-file.zip\n  dl-resume https://example.com/large-file.zip -o ~/Downloads/myfile.zip -r 5 -l 1m\n  dl-resume https://example.com/large-file.zip -a -H \"Authorization: Bearer token\""
    return 0
  fi

  local url="$1"
  shift

  # Default values
  local output_path=""
  local retries=3
  local limit_speed=""
  local auto_extract=false
  local log_enabled=false
  local log_file=""
  local headers=()
  local verify_hash=""
  local verify_type=""

  # Parse options (same as dl-file)
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -o|--output)
        output_path="$2"
        shift 2
        ;;
      -r|--retries)
        retries="$2"
        shift 2
        ;;
      -l|--limit)
        limit_speed="$2"
        shift 2
        ;;
      -a|--auto-extract)
        auto_extract=true
        shift
        ;;
      -L|--log)
        log_enabled=true
        shift
        ;;
      -H|--header)
        headers+=("$2")
        shift 2
        ;;
      -v|--verify)
        IFS=":" read -r verify_hash verify_type <<< "$2"
        shift 2
        ;;
      *)
        _show_error_download_aliases "Error: Unknown option \"$1\""
        return 1
        ;;
    esac
  done

  # Determine output path if not provided
  if [ -z "$output_path" ]; then
    output_path="$(basename "$url")"
  fi

  # Create directory if it doesn"t exist
  local dir_path=$(dirname "$output_path")
  if [ ! -d "$dir_path" ] && [ "$dir_path" != "." ]; then
    if ! mkdir -p "$dir_path"; then
      _show_error_download_aliases "Failed to create directory: $dir_path"
      return 1
    fi
  fi

  # Set up logging
  if $log_enabled; then
    log_file="${output_path}.log"
    echo "Download started at $(date)" > "$log_file"
    echo "URL: $url" >> "$log_file"
  fi

  # Prepare curl command with resume
  local curl_opts=("-L" "-C" "-" "-o" "$output_path" "--retry" "$retries")

  # Add limit speed option
  if [ -n "$limit_speed" ]; then
    curl_opts+=("--limit-rate" "$limit_speed")
    [ $log_enabled = true ] && echo "Speed limit: $limit_speed" >> "$log_file"
  fi

  # Add headers
  for header in "${headers[@]}"; do
    curl_opts+=("-H" "$header")
    [ $log_enabled = true ] && echo "Header: $header" >> "$log_file"
  fi

  # Download progress settings
  if [ -t 1 ]; then  # If terminal is interactive
    curl_opts+=("--progress-bar")
  else
    curl_opts+=("-s")
  fi

  echo "Downloading from $url to $output_path (with resume capability)..."

  # Run the download
  if $log_enabled; then
    curl "${curl_opts[@]}" "$url" 2>> "$log_file"
  else
    curl "${curl_opts[@]}" "$url"
  fi

  local status=$?
  if [ $status -ne 0 ]; then
    _show_error_download_aliases "Download failed. Check the URL and your internet connection."
    [ $log_enabled = true ] && echo "Download failed with status $status at $(date)" >> "$log_file"
    return 1
  fi

  echo "Download complete: $output_path"
  [ $log_enabled = true ] && echo "Download completed successfully at $(date)" >> "$log_file"

  # Verify file integrity if requested (same as dl-file)
  if [ -n "$verify_hash" ] && [ -n "$verify_type" ]; then
    echo "Verifying file integrity using $verify_type hash..."
    [ $log_enabled = true ] && echo "Verifying file integrity using $verify_type hash..." >> "$log_file"

    if ! _check_integrity_download_aliases "$output_path" "$verify_type" "$verify_hash"; then
      [ $log_enabled = true ] && echo "Integrity verification failed" >> "$log_file"
      return 1
    fi

    [ $log_enabled = true ] && echo "Integrity verification passed" >> "$log_file"
  fi

  # Auto extract if requested (same as dl-file)
  if $auto_extract; then
    echo "Auto-extracting downloaded file..."
    [ $log_enabled = true ] && echo "Auto-extracting downloaded file..." >> "$log_file"

    if ! _extract_file_download_aliases "$output_path"; then
      [ $log_enabled = true ] && echo "Extraction failed" >> "$log_file"
      return 1
    fi

    [ $log_enabled = true ] && echo "Extraction completed successfully" >> "$log_file"
  fi

  return 0
}' # Download a file with resume capability

# Mirror an entire website for offline viewing
alias dl-mirror='() {
  if ! _check_command_download_aliases wget; then
    return 1
  fi

  # Parse usage and help
  if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo -e "Mirror a website for offline viewing.\nUsage:\n dl-mirror <url:required> [options]\n\nOptions:\n  -o, --output-dir DIR   : Output directory (default: ./mirror)\n  -d, --depth LEVEL      : Maximum depth level for recursion (default: 5)\n  -l, --limit SPEED      : Limit download speed (e.g., 1m = 1MB/s)\n  -w, --wait SECONDS     : Wait between retrievals (default: 1)\n  -H, --header HEADER    : Add custom header (can be used multiple times)\n  -h, --help             : Show this help message\n\nExamples:\n  dl-mirror https://example.com\n  dl-mirror https://example.com -o ~/websites/example -d 3 -l 500k\n  dl-mirror https://example.com -H \"Authorization: Bearer token\""
    return 0
  fi

  local url="$1"
  shift

  # Default values
  local output_dir="./mirror"
  local depth=5
  local limit_speed=""
  local wait_time=1
  local headers=()

  # Parse options
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -o|--output-dir)
        output_dir="$2"
        shift 2
        ;;
      -d|--depth)
        depth="$2"
        shift 2
        ;;
      -l|--limit)
        limit_speed="$2"
        shift 2
        ;;
      -w|--wait)
        wait_time="$2"
        shift 2
        ;;
      -H|--header)
        headers+=("$2")
        shift 2
        ;;
      *)
        _show_error_download_aliases "Error: Unknown option \"$1\""
        return 1
        ;;
    esac
  done

  # Create output directory if it doesn"t exist
  if [ ! -d "$output_dir" ]; then
    if ! mkdir -p "$output_dir"; then
      _show_error_download_aliases "Failed to create directory: $output_dir"
      return 1
    fi
  fi

  # Prepare wget command
  local wget_opts=(
    "--mirror"
    "--convert-links"
    "--adjust-extension"
    "--page-requisites"
    "--no-parent"
    "-P" "$output_dir"
    "--level=$depth"
    "--wait=$wait_time"
    "--random-wait"
    "--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
  )

  # Add limit speed option
  if [ -n "$limit_speed" ]; then
    wget_opts+=("--limit-rate=$limit_speed")
  fi

  # Add headers
  for header in "${headers[@]}"; do
    wget_opts+=("--header=$header")
  done

  echo "Mirroring website $url to $output_dir (depth: $depth)..."
  wget "${wget_opts[@]}" "$url"

  local status=$?
  if [ $status -ne 0 ]; then
    _show_error_download_aliases "Website mirroring failed."
    return 1
  fi

  echo "Website mirroring complete: $output_dir"
  return 0
}' # Mirror a website for offline viewing

# Download and extract in one step
alias dl-extract='() {
  if ! _check_command_download_aliases curl; then
    return 1
  fi

  # Parse usage and help
  if [ $# -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo -e "Download and extract archive in one step.\nUsage:\n dl-extract <url:required> [options]\n\nOptions:\n  -o, --output-dir DIR   : Output directory (default: current directory)\n  -r, --retries N        : Number of retries (default: 3)\n  -l, --limit SPEED      : Limit download speed (e.g., 1m = 1MB/s)\n  -k, --keep-archive     : Keep the archive file after extraction\n  -H, --header HEADER    : Add custom header (can be used multiple times)\n  -h, --help             : Show this help message\n\nExamples:\n  dl-extract https://example.com/archive.zip\n  dl-extract https://example.com/archive.tar.gz -o ~/extracted -r 5 -l 1m\n  dl-extract https://example.com/archive.zip -k -H \"Authorization: Bearer token\""
    return 0
  fi

  local url="$1"
  shift

  # Default values
  local output_dir="."
  local retries=3
  local limit_speed=""
  local keep_archive=false
  local headers=()

  # Parse options
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -o|--output-dir)
        output_dir="$2"
        shift 2
        ;;
      -r|--retries)
        retries="$2"
        shift 2
        ;;
      -l|--limit)
        limit_speed="$2"
        shift 2
        ;;
      -k|--keep-archive)
        keep_archive=true
        shift
        ;;
      -H|--header)
        headers+=("$2")
        shift 2
        ;;
      *)
        _show_error_download_aliases "Error: Unknown option \"$1\""
        return 1
        ;;
    esac
  done

  # Create output directory if it doesn"t exist
  if [ ! -d "$output_dir" ]; then
    if ! mkdir -p "$output_dir"; then
      _show_error_download_aliases "Failed to create directory: $output_dir"
      return 1
    fi
  fi

  # Get filename from URL
  local filename=$(basename "$url")
  local temp_dir=$(mktemp -d)
  local archive_path="${temp_dir}/${filename}"

  echo "Downloading from $url..."

  # Prepare curl command
  local curl_opts=("-L" "-o" "$archive_path" "--retry" "$retries")

  # Add limit speed option
  [ -n "$limit_speed" ] && curl_opts+=("--limit-rate" "$limit_speed")

  # Add headers
  for header in "${headers[@]}"; do
    curl_opts+=("-H" "$header")
  done

  # Download progress settings
  if [ -t 1 ]; then  # If terminal is interactive
    curl_opts+=("--progress-bar")
  else
    curl_opts+=("-s")
  fi

  # Run the download
  curl "${curl_opts[@]}" "$url"

  if [ $? -ne 0 ]; then
    _show_error_download_aliases "Download failed. Check the URL and your internet connection."
    rm -rf "$temp_dir"
    return 1
  fi

  echo "Download complete, extracting..."

  # Extract the archive
  if ! _extract_file_download_aliases "$archive_path" "$output_dir"; then
    _show_error_download_aliases "Extraction failed."
    rm -rf "$temp_dir"
    return 1
  fi

  # Keep or remove the archive
  if $keep_archive; then
    echo "Moving archive to output directory..."
    mv "$archive_path" "$output_dir/"
  fi

  # Clean up
  rm -rf "$temp_dir"

  echo "Download and extraction complete!"
  return 0
}' # Download and extract archive in one step

# Help function that lists all available download aliases
alias dl-help='() {
  echo "Download Aliases Help"
  echo "===================="
  echo ""
  echo "Available commands:"
  echo ""
  echo "dl-file <url> [options]            - Download a single file"
  echo "dl-batch <url_list> [options]      - Batch download multiple files"
  echo "dl-resume <url> [options]          - Download with resume capability"
  echo "dl-mirror <url> [options]          - Mirror a website for offline viewing"
  echo "dl-extract <url> [options]         - Download and extract in one step"
  echo "dl-help                            - Show this help message"
  echo ""
  echo "Use any command with -h or --help for detailed usage information."
}' # Show help for download aliases
