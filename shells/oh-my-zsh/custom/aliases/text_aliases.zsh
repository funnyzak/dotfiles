# Description: Text processing aliases for common text manipulation tasks.

# Text deduplication function
alias text-dedup='() {
    # Function usage
    echo -e "Remove duplicate lines from text files.\nUsage:\n text-dedup [options] <files_or_dirs...>\n\nOptions:\n -o, --output <file>    Output file path (default: overwrite original)\n -p, --pattern <glob>   File pattern to match (default: *.txt)\n -r, --recursive        Process directories recursively\n -v, --verbose         Show detailed processing information"

    # Initialize variables
    local output_file=""
    local pattern="*.txt"
    local recursive=false
    local verbose=false
    local files=()

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -o|--output)
                output_file="$2"
                shift 2
                ;;
            -p|--pattern)
                pattern="$2"
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
            *)
                files+=("$1")
                shift
                ;;
        esac
    done

    # Check if files are provided
    if [[ ${#files[@]} -eq 0 ]]; then
        echo "Error: No files or directories specified" >&2
        return 1
    fi

    # Process each input
    for input in "${files[@]}"; do
        if [[ -f "$input" ]]; then
            # Process single file
            if [[ "$verbose" == true ]]; then
                echo "Processing file: $input"
            fi

            if [[ -n "$output_file" ]]; then
                sort -u "$input" > "$output_file"
                if [[ "$verbose" == true ]]; then
                    echo "Output written to: $output_file"
                fi
            else
                local temp_file=$(mktemp)
                sort -u "$input" > "$temp_file"
                mv "$temp_file" "$input"
                if [[ "$verbose" == true ]]; then
                    echo "File updated: $input"
                fi
            fi
        elif [[ -d "$input" ]]; then
            # Process directory
            if [[ "$verbose" == true ]]; then
                echo "Processing directory: $input"
            fi

            # Find files based on pattern and recursive flag
            local find_cmd="find \"$input\""
            if [[ "$recursive" == false ]]; then
                find_cmd+=" -maxdepth 1"
            fi
            find_cmd+=" -type f -name \"$pattern\""

            # Process each file in directory
            while IFS= read -r file; do
                if [[ -n "$output_file" ]]; then
                    sort -u "$file" >> "$output_file"
                    if [[ "$verbose" == true ]]; then
                        echo "Appended to output file: $output_file"
                    fi
                else
                    local temp_file=$(mktemp)
                    sort -u "$file" > "$temp_file"
                    mv "$temp_file" "$file"
                    if [[ "$verbose" == true ]]; then
                        echo "File updated: $file"
                    fi
                fi
            done < <(eval "$find_cmd")
        else
            echo "Error: Invalid input: $input" >&2
            continue
        fi
    done
}'

# Text case conversion function
alias text-case='() {
    # Function usage
    echo -e "Convert text case in files.\nUsage:\n text-case [options] <files_or_dirs...>\n\nOptions:\n -o, --output <file>    Output file path (default: overwrite original)\n -p, --pattern <glob>   File pattern to match (default: *.txt)\n -r, --recursive        Process directories recursively\n -v, --verbose         Show detailed processing information\n -m, --mode <mode>     Case conversion mode (upper/lower/title, default: lower)"

    # Initialize variables
    local output_file=""
    local pattern="*.txt"
    local recursive=false
    local verbose=false
    local mode="lower"
    local files=()

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -o|--output)
                output_file="$2"
                shift 2
                ;;
            -p|--pattern)
                pattern="$2"
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
            -m|--mode)
                mode="$2"
                shift 2
                ;;
            *)
                files+=("$1")
                shift
                ;;
        esac
    done

    # Validate mode
    if [[ ! "$mode" =~ ^(upper|lower|title)$ ]]; then
        echo "Error: Invalid mode. Use upper, lower, or title" >&2
        return 1
    fi

    # Process each input
    for input in "${files[@]}"; do
        if [[ -f "$input" ]]; then
            # Process single file
            if [[ "$verbose" == true ]]; then
                echo "Processing file: $input"
            fi

            case "$mode" in
                upper)
                    if [[ -n "$output_file" ]]; then
                        tr "[:lower:]" "[:upper:]" < "$input" > "$output_file"
                    else
                        local temp_file=$(mktemp)
                        tr "[:lower:]" "[:upper:]" < "$input" > "$temp_file"
                        mv "$temp_file" "$input"
                    fi
                    ;;
                lower)
                    if [[ -n "$output_file" ]]; then
                        tr "[:upper:]" "[:lower:]" < "$input" > "$output_file"
                    else
                        local temp_file=$(mktemp)
                        tr "[:upper:]" "[:lower:]" < "$input" > "$temp_file"
                        mv "$temp_file" "$input"
                    fi
                    ;;
                title)
                    if [[ -n "$output_file" ]]; then
                        awk "{print toupper(substr(\$0,1,1)) tolower(substr(\$0,2))}" "$input" > "$output_file"
                    else
                        local temp_file=$(mktemp)
                        awk "{print toupper(substr(\$0,1,1)) tolower(substr(\$0,2))}" "$input" > "$temp_file"
                        mv "$temp_file" "$input"
                    fi
                    ;;
            esac

            if [[ "$verbose" == true ]]; then
                echo "File processed: $input"
            fi
        elif [[ -d "$input" ]]; then
            # Process directory
            if [[ "$verbose" == true ]]; then
                echo "Processing directory: $input"
            fi

            # Find files based on pattern and recursive flag
            local find_cmd="find \"$input\""
            if [[ "$recursive" == false ]]; then
                find_cmd+=" -maxdepth 1"
            fi
            find_cmd+=" -type f -name \"$pattern\""

            # Process each file in directory
            while IFS= read -r file; do
                case "$mode" in
                    upper)
                        if [[ -n "$output_file" ]]; then
                            tr "[:lower:]" "[:upper:]" < "$file" >> "$output_file"
                        else
                            local temp_file=$(mktemp)
                            tr "[:lower:]" "[:upper:]" < "$file" > "$temp_file"
                            mv "$temp_file" "$file"
                        fi
                        ;;
                    lower)
                        if [[ -n "$output_file" ]]; then
                            tr "[:upper:]" "[:lower:]" < "$file" >> "$output_file"
                        else
                            local temp_file=$(mktemp)
                            tr "[:upper:]" "[:lower:]" < "$file" > "$temp_file"
                            mv "$temp_file" "$file"
                        fi
                        ;;
                    title)
                        if [[ -n "$output_file" ]]; then
                            awk "{print toupper(substr(\$0,1,1)) tolower(substr(\$0,2))}" "$file" >> "$output_file"
                        else
                            local temp_file=$(mktemp)
                            awk "{print toupper(substr(\$0,1,1)) tolower(substr(\$0,2))}" "$file" > "$temp_file"
                            mv "$temp_file" "$file"
                        fi
                        ;;
                esac

                if [[ "$verbose" == true ]]; then
                    echo "File processed: $file"
                fi
            done < <(eval "$find_cmd")
        else
            echo "Error: Invalid input: $input" >&2
            continue
        fi
    done
}'

# Text line number function
alias text-linenum='() {
    # Function usage
    echo -e "Add or remove line numbers from text files.\nUsage:\n text-linenum [options] <files_or_dirs...>\n\nOptions:\n -o, --output <file>    Output file path (default: overwrite original)\n -p, --pattern <glob>   File pattern to match (default: *.txt)\n -r, --recursive        Process directories recursively\n -v, --verbose         Show detailed processing information\n -a, --action <action> Action to perform (add/remove, default: add)\n -f, --format <fmt>    Line number format (default: \"%d: \")"

    # Initialize variables
    local output_file=""
    local pattern="*.txt"
    local recursive=false
    local verbose=false
    local action="add"
    local format="%d: "
    local files=()

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -o|--output)
                output_file="$2"
                shift 2
                ;;
            -p|--pattern)
                pattern="$2"
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
            -a|--action)
                action="$2"
                shift 2
                ;;
            -f|--format)
                format="$2"
                shift 2
                ;;
            *)
                files+=("$1")
                shift
                ;;
        esac
    done

    # Validate action
    if [[ ! "$action" =~ ^(add|remove)$ ]]; then
        echo "Error: Invalid action. Use add or remove" >&2
        return 1
    fi

    # Process each input
    for input in "${files[@]}"; do
        if [[ -f "$input" ]]; then
            # Process single file
            if [[ "$verbose" == true ]]; then
                echo "Processing file: $input"
            fi

            if [[ "$action" == "add" ]]; then
                if [[ -n "$output_file" ]]; then
                    awk -v fmt="$format" "{printf fmt, NR; print}" "$input" > "$output_file"
                else
                    local temp_file=$(mktemp)
                    awk -v fmt="$format" "{printf fmt, NR; print}" "$input" > "$temp_file"
                    mv "$temp_file" "$input"
                fi
            else
                if [[ -n "$output_file" ]]; then
                    sed -E "s/^[0-9]+: //" "$input" > "$output_file"
                else
                    local temp_file=$(mktemp)
                    sed -E "s/^[0-9]+: //" "$input" > "$temp_file"
                    mv "$temp_file" "$input"
                fi
            fi

            if [[ "$verbose" == true ]]; then
                echo "File processed: $input"
            fi
        elif [[ -d "$input" ]]; then
            # Process directory
            if [[ "$verbose" == true ]]; then
                echo "Processing directory: $input"
            fi

            # Find files based on pattern and recursive flag
            local find_cmd="find \"$input\""
            if [[ "$recursive" == false ]]; then
                find_cmd+=" -maxdepth 1"
            fi
            find_cmd+=" -type f -name \"$pattern\""

            # Process each file in directory
            while IFS= read -r file; do
                if [[ "$action" == "add" ]]; then
                    if [[ -n "$output_file" ]]; then
                        awk -v fmt="$format" "{printf fmt, NR; print}" "$file" >> "$output_file"
                    else
                        local temp_file=$(mktemp)
                        awk -v fmt="$format" "{printf fmt, NR; print}" "$file" > "$temp_file"
                        mv "$temp_file" "$file"
                    fi
                else
                    if [[ -n "$output_file" ]]; then
                        sed -E "s/^[0-9]+: //" "$file" >> "$output_file"
                    else
                        local temp_file=$(mktemp)
                        sed -E "s/^[0-9]+: //" "$file" > "$temp_file"
                        mv "$temp_file" "$file"
                    fi
                fi

                if [[ "$verbose" == true ]]; then
                    echo "File processed: $file"
                fi
            done < <(eval "$find_cmd")
        else
            echo "Error: Invalid input: $input" >&2
            continue
        fi
    done
}'

# Text help function
alias text-help='() {
    echo -e "Text Processing Aliases Help\n\nAvailable commands:\n\n1. text-dedup\n   Remove duplicate lines from text files\n   Usage: text-dedup [options] <files_or_dirs...>\n\n2. text-case\n   Convert text case in files\n   Usage: text-case [options] <files_or_dirs...>\n\n3. text-linenum\n   Add or remove line numbers from text files\n   Usage: text-linenum [options] <files_or_dirs...>\n\nFor detailed help on each command, run the command without arguments."
}'
