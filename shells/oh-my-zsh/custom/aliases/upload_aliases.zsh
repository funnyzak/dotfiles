# Description: Upload related aliases for file uploading operations with various options.

# Helper functions for upload aliases
_show_error_upload_aliases() {
  echo "$1" >&2
  return 1
}

alias upload-alist='() {
  echo -e "Upload files to alist with enhanced features.\nUsage:\n upload-alist [options] <file_path> [file_path2] [file_path3] ..."
  echo -e "Options:\n  -a, --api-url URL       API base URL\n  -u, --username USER     Username for authentication"
  echo -e "  -p, --password PASS     Password for authentication\n  -t, --token TOKEN       Pre-existing token"
  echo -e "  -r, --remote-path PATH  Remote upload path (default: /)\n  --no-cache              Disable token caching"
  echo -e "  -v, --verbose           Enable verbose output\n  -h, --help              Show help message"
  echo -e "Examples:\n  upload-alist file1.txt file2.pdf\n  upload-alist -r /documents file1.txt file2.pdf"
  echo -e "  upload-alist --no-cache file1.txt\n  upload-alist -a https://api.example.com -u user -p pass file1.txt"

  local script_url="https://gitee.com/funnyzak/dotfiles/raw/main/utilities/shell/alist/alist_upload.sh"
  local tmp_file=$(mktemp)

  if ! curl -sSL "$script_url" -o "$tmp_file"; then
    _show_error_upload_aliases "Failed to download alist upload script"
    rm -f "$tmp_file"
    return 1
  fi

  chmod +x "$tmp_file"

  if ! "$tmp_file" "$@"; then
    local exit_code=$?
    rm -f "$tmp_file"
    return $exit_code
  fi

  rm -f "$tmp_file"
}' # Upload files to alist with multiple file support and enhanced features

alias upload-help='() {
  echo "Upload Aliases Help"
  echo "==================="
  echo ""
  echo "Available commands:"
  echo ""
  echo "upload-alist [options] <file_path> [file_path2] ... - Upload multiple files to alist"
  echo ""
}' # Upload Aliases Help
