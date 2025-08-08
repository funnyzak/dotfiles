# Description: Markdown processing aliases using markitdown for document conversion

# Helper Functions
### --- ###

# Check if markitdown is installed and accessible
_markdown_check_markitdown() {
    if ! command -v markitdown >/dev/null 2>&1; then
        echo "Error: markitdown is not installed or not in PATH." >&2
        echo "Install it with: pip install \"markitdown[all]\"" >&2
        return 1
    fi
    return 0
}

# Validate that a file exists and is readable
_markdown_validate_file() {
    local file_path="$1"

    if [ -z "$file_path" ]; then
        echo "Error: File path is required for validation." >&2
        return 1
    fi

    if [ ! -f "$file_path" ]; then
        echo "Error: File does not exist: $file_path" >&2
        return 1
    fi

    if [ ! -r "$file_path" ]; then
        echo "Error: File is not readable: $file_path" >&2
        return 1
    fi

    return 0
}

# Validate that a directory exists and is accessible
_markdown_validate_dir() {
    local dir_path="$1"

    if [ -z "$dir_path" ]; then
        echo "Error: Directory path is required for validation." >&2
        return 1
    fi

    if [ ! -d "$dir_path" ]; then
        echo "Error: Directory does not exist: $dir_path" >&2
        return 1
    fi

    if [ ! -r "$dir_path" ]; then
        echo "Error: Directory is not readable: $dir_path" >&2
        return 1
    fi

    return 0
}

# Get supported file extensions
_markdown_get_supported_extensions() {
    echo "pdf pptx docx xlsx xls html txt csv json xml epub"
}

# Create output directory safely
_markdown_create_output_dir() {
    local output_dir="$1"

    if [ -z "$output_dir" ]; then
        echo "Error: Output directory path is required." >&2
        return 1
    fi

    if [ ! -d "$output_dir" ]; then
        if ! mkdir -p "$output_dir" 2>/dev/null; then
            echo "Error: Failed to create output directory: $output_dir" >&2
            return 1
        fi
    fi

    if [ ! -w "$output_dir" ]; then
        echo "Error: Output directory is not writable: $output_dir" >&2
        return 1
    fi

    return 0
}

# Convert a single file to markdown
_markdown_convert_single_file() {
    local input_file="$1"
    local output_dir="$2"
    local show_errors="$3"
    local verbose="$4"

    local base_name output_file error_output

    if ! _markdown_validate_file "$input_file"; then
        return 1
    fi

    base_name=$(basename "$input_file")
    output_file="$output_dir/${base_name%.*}.md"

    if [ "$verbose" = "true" ]; then
        echo "Converting: $input_file -> $output_file"
    fi

    if [ "$show_errors" = "true" ]; then
        markitdown "$input_file" > "$output_file" 2>&1
        error_output=$?
    else
        markitdown "$input_file" > "$output_file" 2>/dev/null
        error_output=$?
    fi

    if [ $error_output -eq 0 ]; then
        if [ "$verbose" = "true" ]; then
            echo "Successfully converted: $input_file"
        fi
        return 0
    else
        echo "Error: Failed to convert $input_file" >&2
        if [ "$show_errors" = "false" ]; then
            echo "Use -e flag for detailed error information" >&2
        fi
        return 1
    fi
}

# Main Functions
### --- ###

# Main document conversion function
alias md-convert='() {
    echo -e "Convert various document formats to Markdown using markitdown.\nUsage:\n md-convert [options] <file_or_dir:current_dir> [more_files_or_dirs...]"
    echo -e "Options:\n -o, --output <dir>  Output directory (default: same as input)\n -f, --format <list> File formats to process (default: all supported)\n -r, --recursive     Process directories recursively\n -v, --verbose       Show detailed conversion progress\n -e, --show-errors   Show detailed error messages\n -q, --quiet         Suppress progress messages\n -h, --help          Show help message"

    if ! _markdown_check_markitdown; then
        return 1
    fi

    local output_dir="" formats="" recursive="false" verbose="false" show_errors="false" quiet="false"
    local input_paths=() processed_files=0 failed_files=0 temp_args=()
    local current_arg next_arg

    # Parse arguments
    while [ $# -gt 0 ]; do
        current_arg="$1"
        case "$current_arg" in
            -h|--help)
                echo -e "\nSupported formats: $(_markdown_get_supported_extensions)"
                echo -e "\nExamples:\n md-convert document.pdf\n md-convert -o ./output docs/\n md-convert -f pdf,docx ./docs\n md-convert -r -v -f pdf ./docs"
                return 0
                ;;
            -o|--output)
                if [ -z "$2" ]; then
                    echo "Error: Output directory is required after $current_arg" >&2
                    return 1
                fi
                output_dir="$2"
                shift 2
                ;;
            -f|--format)
                if [ -z "$2" ]; then
                    echo "Error: Format list is required after $current_arg" >&2
                    return 1
                fi
                formats="$2"
                shift 2
                ;;
            -r|--recursive)
                recursive="true"
                shift
                ;;
            -v|--verbose)
                verbose="true"
                shift
                ;;
            -e|--show-errors)
                show_errors="true"
                shift
                ;;
            -q|--quiet)
                quiet="true"
                shift
                ;;
            -*)
                echo "Error: Unknown option: $current_arg" >&2
                return 1
                ;;
            *)
                input_paths+=("$current_arg")
                shift
                ;;
        esac
    done

    # Set default input if none provided
    if [ ${#input_paths[@]} -eq 0 ]; then
        input_paths=(".")
    fi

    # Set default formats if not specified
    if [ -z "$formats" ]; then
        formats="$(_markdown_get_supported_extensions)"
    fi

    # Convert comma-separated formats to space-separated array
    formats=$(echo "$formats" | tr "," " ")
    # Convert to array for proper iteration
    local format_array=($=formats)

    # Process each input path
    local input_path
    for input_path in "${input_paths[@]}"; do
        if [ -f "$input_path" ]; then
            # Single file processing
            local current_output_dir file_dir
            if [ -z "$output_dir" ]; then
                file_dir=$(dirname "$input_path")
                current_output_dir="$file_dir"
            else
                current_output_dir="$output_dir"
            fi

            if ! _markdown_create_output_dir "$current_output_dir"; then
                continue
            fi

            if [ "$quiet" = "false" ]; then
                echo "Processing file: $input_path"
            fi

            if _markdown_convert_single_file "$input_path" "$current_output_dir" "$show_errors" "$verbose"; then
                processed_files=$((processed_files + 1))
            else
                failed_files=$((failed_files + 1))
            fi

        elif [ -d "$input_path" ]; then
            # Directory processing
            local current_output_dir find_args find_format extension
            if [ -z "$output_dir" ]; then
                current_output_dir="$input_path"
            else
                current_output_dir="$output_dir"
            fi

            if ! _markdown_create_output_dir "$current_output_dir"; then
                continue
            fi

            if [ "$quiet" = "false" ]; then
                echo "Processing directory: $input_path"
            fi

                        # Process files using find with proper format filtering
            local extension temp_file_list
            temp_file_list=$(mktemp)

            # Create find command conditions for each extension
            local find_conditions=""
            local first_ext="true"
            for extension in "${format_array[@]}"; do
                if [ "$first_ext" = "true" ]; then
                    find_conditions="-iname \"*.$extension\""
                    first_ext="false"
                else
                    find_conditions="$find_conditions -o -iname \"*.$extension\""
                fi
            done

            # Execute find command based on recursive flag
            if [ "$recursive" = "false" ]; then
                eval "find \"$input_path\" -maxdepth 1 -type f \\( $find_conditions \\)" > "$temp_file_list" 2>/dev/null
            else
                eval "find \"$input_path\" -type f \\( $find_conditions \\)" > "$temp_file_list" 2>/dev/null
            fi

            # Debug output
            if [ "$verbose" = "true" ]; then
                local file_count
                file_count=$(wc -l < "$temp_file_list")
                echo "Found $file_count files to process"
            fi

            # Process found files
            local found_file
            while IFS= read -r found_file; do
                # Skip if empty line
                [ -z "$found_file" ] && continue

                local relative_dir target_output_dir
                if [ "$output_dir" != "$input_path" ] && [ -n "$output_dir" ]; then
                    relative_dir=$(dirname "${found_file#$input_path/}")
                    if [ "$relative_dir" = "." ]; then
                        target_output_dir="$output_dir"
                    else
                        target_output_dir="$output_dir/$relative_dir"
                    fi
                    if ! _markdown_create_output_dir "$target_output_dir"; then
                        continue
                    fi
                else
                    target_output_dir=$(dirname "$found_file")
                fi

                if _markdown_convert_single_file "$found_file" "$target_output_dir" "$show_errors" "$verbose"; then
                    processed_files=$((processed_files + 1))
                else
                    failed_files=$((failed_files + 1))
                fi
            done < "$temp_file_list"

            # Cleanup temp file
            rm -f "$temp_file_list"

        else
            echo "Error: Path does not exist: $input_path" >&2
            failed_files=$((failed_files + 1))
        fi
    done

    # Summary
    if [ "$quiet" = "false" ]; then
        echo
        echo "Conversion Summary:"
        echo "  Files processed successfully: $processed_files"
        echo "  Files failed: $failed_files"
        echo "  Total files: $((processed_files + failed_files))"
    fi

    if [ $failed_files -gt 0 ]; then
        return 1
    fi
    return 0
}' # Convert various document formats to Markdown

# Display comprehensive help information
alias md-help='() {
    echo "Markdown Processing Aliases Help"
    echo "=============================="
    echo
    echo "Available Commands:"
    echo "  md-convert   - Convert documents to Markdown format"
    echo "  md-help      - Show this help information"
    echo "  md-aliases   - Quick help (alias for md-help)"
    echo "  md-version   - Show markitdown version"
    echo "  md-check     - Verify markitdown installation"
    echo
    echo "Main Function: md-convert"
    echo "------------------------"
    echo "Convert various document formats to Markdown using Microsoft markitdown."
    echo
    echo "Usage: md-convert [options] <file_or_dir> [more_files_or_dirs...]"
    echo
    echo "Options:"
    echo "  -o, --output <dir>     Output directory (default: same as input)"
    echo "  -f, --format <list>    Comma-separated formats to process"
    echo "  -r, --recursive        Process directories recursively"
    echo "  -v, --verbose          Show detailed conversion progress"
    echo "  -e, --show-errors      Show detailed error messages"
    echo "  -q, --quiet            Suppress progress messages"
    echo "  -h, --help             Show help message"
    echo
    echo "Supported Formats:"
    echo "  $(_markdown_get_supported_extensions)"
    echo
    echo "Examples:"
    echo "  md-convert document.pdf"
    echo "  md-convert -o ./output docs/"
    echo "  md-convert -f pdf,docx ./docs"
    echo "  md-convert -r -v -f pdf ./docs"
    echo "  md-convert -e document.pdf"
    echo
    echo "Installation:"
    echo "  pip install \"markitdown[all]\""
    echo
}' # Show comprehensive help for markdown aliases

# Quick help alias
alias md-aliases='() {
    md-help
}' # Quick access to markdown aliases help

# Show markitdown version
alias md-version='() {
    echo "Checking markitdown version..."

    if ! _markdown_check_markitdown; then
        return 1
    fi

    echo "Markitdown version information:"
    markitdown --version 2>/dev/null || {
        echo "Version information not available through --version flag."
        echo "Markitdown is installed and accessible."
        python -c "import markitdown; print(f\"markitdown {markitdown.__version__}\")" 2>/dev/null || {
            echo "Unable to retrieve version information."
        }
    }
}' # Show markitdown version information

# Check markitdown installation and configuration
alias md-check='() {
    echo "Markitdown Installation Check"
    echo "============================"
    echo

    # Check Python installation
    if command -v python >/dev/null 2>&1; then
        local python_version
        python_version=$(python --version 2>&1)
        echo "✓ Python: $python_version"
    elif command -v python3 >/dev/null 2>&1; then
        local python3_version
        python3_version=$(python3 --version 2>&1)
        echo "✓ Python3: $python3_version"
    else
        echo "✗ Python: Not found"
        echo "  Install Python 3.8+ to use markitdown"
        return 1
    fi

    # Check pip installation
    if command -v pip >/dev/null 2>&1; then
        echo "✓ pip: Available"
    elif command -v pip3 >/dev/null 2>&1; then
        echo "✓ pip3: Available"
    else
        echo "✗ pip: Not found"
        echo "  Install pip to install markitdown"
        return 1
    fi

    # Check markitdown installation
    if _markdown_check_markitdown; then
        echo "✓ markitdown: Installed and accessible"

        # Try to get version
        local version_info
        version_info=$(python -c "import markitdown; print(markitdown.__version__)" 2>/dev/null)
        if [ -n "$version_info" ]; then
            echo "  Version: $version_info"
        fi

        # Check markitdown path
        local markitdown_path
        markitdown_path=$(command -v markitdown)
        echo "  Location: $markitdown_path"

    else
        echo "✗ markitdown: Not installed or not accessible"
        echo "  Install with: pip install \"markitdown[all]\""
        return 1
    fi

    # Check supported formats
    echo
    echo "Supported file formats:"
    local extension
    for extension in $(_markdown_get_supported_extensions); do
        echo "  • .$extension"
    done

    echo
    echo "Configuration:"
    echo "  Current directory: $(pwd)"
    echo "  Default output: Same as input directory"

    echo
    echo "Everything looks good! You can start using the markdown aliases."
    echo "Try: md-help for usage information"

    return 0
}' # Check markitdown installation and show configuration
