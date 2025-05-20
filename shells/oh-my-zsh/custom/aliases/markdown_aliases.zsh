# Description: Markdown processing aliases for document conversion and manipulation.

# --------------------------------
# Helper Functions
# --------------------------------

# Helper function to check if markitdown is installed
_markdown_aliases_check_markitdown() {
  if ! command -v markitdown &> /dev/null; then
    echo "Error: markitdown is not installed. Please install it first." >&2
    echo "Installation guide:" >&2
    echo "  1. Install Python 3.8 or later" >&2
    echo "  2. Install markitdown:" >&2
    echo "     pip install \"markitdown[all]\"" >&2
    echo "  Or install from source:" >&2
    echo "     git clone git@github.com:microsoft/markitdown.git" >&2
    echo "     cd markitdown" >&2
    echo "     pip install -e \"packages/markitdown[all]\"" >&2
    return 1
  fi
  return 0
}

# Helper function to validate file existence
_markdown_aliases_validate_file() {
  if [ $# -lt 1 ]; then
    echo "Error: No file path provided for validation." >&2
    return 1
  fi

  if [ ! -f "$1" ]; then
    echo "Error: File \"$1\" not found." >&2
    return 1
  fi
  return 0
} # Helper function to validate file existence

# Helper function to validate directory existence
_markdown_aliases_validate_dir() {
  if [ $# -lt 1 ]; then
    echo "Error: No directory path provided for validation." >&2
    return 1
  fi

  if [ ! -d "$1" ]; then
    echo "Error: Directory \"$1\" not found." >&2
    return 1
  fi
  return 0
} # Helper function to validate directory existence

# Helper function to get supported file extensions
_markdown_aliases_get_supported_extensions() {
  echo "pdf,pptx,docx,xlsx,xls,html,txt,csv,json,xml,epub"
} # Helper function to get supported file extensions

# --------------------------------
# Main Conversion Function
# --------------------------------

alias md-convert='() {
  export PATH="/usr/local/bin:$PATH"
  echo "Convert various document formats to Markdown using markitdown."
  echo "Usage: md-convert [options] <file_or_dir> [more_files_or_dirs...]"
  echo
  echo "Options:"
  echo "  -o, --output <dir>     Output directory (default: same as input)"
  echo "  -f, --format <list>    File formats to process (default: all supported)"
  echo "                         Example: pdf,docx,pptx"
  echo "  -r, --recursive        Process directories recursively"
  echo "  -v, --verbose          Show detailed conversion progress"
  echo "  -h, --help            Show this help message"
  echo
  echo "Examples:"
  echo "  md-convert document.pdf"
  echo "  md-convert -o ./output docs/"
  echo "  md-convert -f pdf,docx ./docs"
  echo "  md-convert -r -f pdf ./docs"

  # Check if markitdown is installed
  _markdown_aliases_check_markitdown || return 1

  # Default values
  local output_dir=""
  local formats=""
  local recursive=false
  local verbose=false
  local paths=()

  # Parse arguments
  while [ $# -gt 0 ]; do
    case "$1" in
      -o|--output)
        output_dir="$2"
        shift 2
        ;;
      -f|--format)
        formats="$2"
        shift 2
        ;;
      -r|--recursive)
        recursive=true
        shift
        ;;
      -v|--verbose)
        verbose=true
        shift
        ;;
      -h|--help)
        return 0
        ;;
      *)
        paths+=("$1")
        shift
        ;;
    esac
  done

  # Validate at least one path is provided
  if [ ${#paths[@]} -eq 0 ]; then
    echo "Error: No input files or directories specified." >&2
    return 1
  fi

  # Set default formats if not specified
  if [ -z "$formats" ]; then
    formats=$(_markdown_aliases_get_supported_extensions)
  fi

  # Convert comma-separated formats to find pattern
  local find_pattern=$(echo "$formats" | tr "," "|")

  # Process each path
  local processed=0
  local errors=0

  for path in "${paths[@]}"; do
    if [ -f "$path" ]; then
      # Process single file
      local target_dir="${output_dir:-$(dirname $path)}"
      mkdir -p "$target_dir"

      if [ "$verbose" = true ]; then
        echo "Converting: $path"
      fi

      if markitdown "$path" -o "$target_dir"; then
        processed=$((processed+1))
      else
        echo "Error: Failed to convert $path" >&2
        errors=$((errors+1))
      fi
    elif [ -d "$path" ]; then
      # Process directory
      local target_dir="${output_dir:-$path}"
      mkdir -p "$target_dir"

      # Build find command
      local find_cmd="find \"$path\""
      if [ "$recursive" = false ]; then
        find_cmd="$find_cmd -maxdepth 1"
      fi
      find_cmd="$find_cmd -type f -regex \".*\\.($find_pattern)$\""

      # Process each file in directory
      while IFS= read -r file; do
        if [ "$verbose" = true ]; then
          echo "Converting: $file"
        fi

        if markitdown "$file" -o "$target_dir"; then
          processed=$((processed+1))
        else
          echo "Error: Failed to convert $file" >&2
          errors=$((errors+1))
        fi
      done < <(eval "$find_cmd")
    else
      echo "Error: Path \"$path\" does not exist." >&2
      errors=$((errors+1))
    fi
  done

  echo "Conversion complete: $processed files processed, $errors errors"
  [ $errors -eq 0 ] || return 1
}' # Convert various document formats to Markdown using markitdown

# --------------------------------
# Help Function
# --------------------------------

alias md-help='() {
  echo "Markdown Processing Aliases Help"
  echo "==============================="
  echo "This module provides aliases for markdown processing operations."
  echo
  echo "Document Conversion:"
  echo "  md-convert           - Convert various document formats to Markdown"
  echo "                         Supports: PDF, PowerPoint, Word, Excel, HTML,"
  echo "                         Text, CSV, JSON, XML, EPUB, and more"
  echo
  echo "For more details about a specific command, just run the command without arguments."
}' # Help function showing all available markdown processing aliases

alias md-aliases='() {
  md-help
}' # Alias to call the help function
