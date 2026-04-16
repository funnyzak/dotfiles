# Description: Azure Speech Service aliases for text-to-speech processing with support for single text, file, and batch operations.

# Environment variables required:
# AZURE_SPEECH_KEY - Azure Speech Service API key
# AZURE_SPEECH_REGION - Azure Speech Service region (e.g., eastus, westus2)

# Azure TTS - Convert text to speech using Azure Speech Service
alias azure-tts='() {
    echo -e "Convert text to speech using Azure Speech Service.\nUsage:\n azure-tts [options] <text_or_file_path>\nOptions:\n --key <key>          Azure Speech Service key (overrides AZURE_SPEECH_KEY)\n --region <region>    Azure Speech Service region (overrides AZURE_SPEECH_REGION)\n --lang <language>    Language code (default: zh-CN)\n --voice <voice_name> Voice name (default: zh-CN-XiaochenMultilingualNeural)\n --gender <male|female> Voice gender (default: female)\n --format <format>    Audio format: wav, mp3, ogg, webm (default: wav)\n --output <path>      Output file path (default: current directory)\nExamples:\n azure-tts \"Hello World\"\n azure-tts --voice zh-CN-YunxiNeural --format mp3 input.txt\n azure-tts --lang en-US --gender male \"Hello World\""

    # Check dependencies
    if ! _azure_speech_check_dependencies; then
        return 1
    fi

    # Parse options and arguments
    local speech_key="${AZURE_SPEECH_KEY}"
    local speech_region="${AZURE_SPEECH_REGION}"
    local voice_lang="zh-CN"
    local voice_name="zh-CN-XiaochenMultilingualNeural"
    local voice_gender="female"
    local audio_format="wav"
    local output_path="."
    local input_text=""
    local is_file_input=false

    # Parse command line options
    while [ $# -gt 0 ]; do
        case "$1" in
            --key)
                speech_key="$2"
                shift 2
                ;;
            --region)
                speech_region="$2"
                shift 2
                ;;
            --lang)
                voice_lang="$2"
                shift 2
                ;;
            --voice)
                voice_name="$2"
                shift 2
                ;;
            --gender)
                if [ "$2" = "male" ] || [ "$2" = "female" ]; then
                    voice_gender="$2"
                else
                    echo "Error: Invalid gender. Use \"male\" or \"female\"." >&2
                    return 1
                fi
                shift 2
                ;;
            --format)
                case "$2" in
                    wav|mp3|ogg|webm)
                        audio_format="$2"
                        ;;
                    *)
                        echo "Error: Unsupported audio format \"$2\". Use wav, mp3, ogg, or webm." >&2
                        return 1
                        ;;
                esac
                shift 2
                ;;
            --output)
                output_path="$2"
                shift 2
                ;;
            -*)
                echo "Error: Unknown option \"$1\"." >&2
                return 1
                ;;
            *)
                input_text="$1"
                break
                ;;
        esac
    done

    # Validate required parameters
    if [ -z "$speech_key" ]; then
        echo "Error: Azure Speech Service key not provided. Set AZURE_SPEECH_KEY environment variable or use --key option." >&2
        return 1
    fi

    if [ -z "$speech_region" ]; then
        echo "Error: Azure Speech Service region not provided. Set AZURE_SPEECH_REGION environment variable or use --region option." >&2
        return 1
    fi

    if [ -z "$input_text" ]; then
        echo "Error: No text or file path provided." >&2
        return 1
    fi

    # Check if input is a file
    if [ -f "$input_text" ]; then
        is_file_input=true
        # Read text from file
        if ! input_text=$(cat "$input_text" 2>/dev/null); then
            echo "Error: Failed to read file \"$input_text\"." >&2
            return 1
        fi
        if [ -z "$input_text" ]; then
            echo "Error: File \"$1\" is empty." >&2
            return 1
        fi
        local base_filename=$(basename "$1" | sed "s/\.[^.]*$//")
        local output_filename="${base_filename}_$(date +%Y%m%d_%H%M%S).${audio_format}"
    else
        # Generate filename from timestamp for direct text input
        local output_filename="tts_$(date +%Y%m%d_%H%M%S).${audio_format}"
    fi

    # Set audio format for Azure API
    local content_type
    case "$audio_format" in
        wav)
            content_type="riff-24khz-16bit-mono-pcm"
            ;;
        mp3)
            content_type="audio-24khz-160kbitrate-mono-mp3"
            ;;
        ogg)
            content_type="ogg-24khz-16bit-mono-opus"
            ;;
        webm)
            content_type="webm-24khz-16bit-mono-opus"
            ;;
    esac

    # Adjust voice name based on gender if default voice is used
    if [ "$voice_name" = "zh-CN-XiaochenMultilingualNeural" ] && [ "$voice_gender" = "male" ]; then
        voice_name="zh-CN-YunxiNeural"
    fi

    # Create output directory if it doesnt exist
    if [ ! -d "$output_path" ]; then
        if ! mkdir -p "$output_path" 2>/dev/null; then
            echo "Error: Failed to create output directory \"$output_path\"." >&2
            return 1
        fi
    fi

    local full_output_path="${output_path}/${output_filename}"

    # Call helper function to perform TTS
    _azure_speech_tts_request "$speech_key" "$speech_region" "$voice_lang" "$voice_name" "$input_text" "$content_type" "$full_output_path"
    local tts_result=$?

    if [ $tts_result -eq 0 ]; then
        echo "Successfully converted text to speech: $full_output_path"
    else
        echo "Error: Failed to convert text to speech." >&2
        return 1
    fi
}'

# Azure TTS Batch - Convert multiple text files to speech
alias azure-tts-batch='() {
    echo -e "Batch convert text files to speech using Azure Speech Service.\nUsage:\n azure-tts-batch [options] <directory_path>\nOptions:\n --key <key>          Azure Speech Service key (overrides AZURE_SPEECH_KEY)\n --region <region>    Azure Speech Service region (overrides AZURE_SPEECH_REGION)\n --lang <language>    Language code (default: zh-CN)\n --voice <voice_name> Voice name (default: zh-CN-XiaochenMultilingualNeural)\n --gender <male|female> Voice gender (default: female)\n --format <format>    Audio format: wav, mp3, ogg, webm (default: wav)\n --extension <ext>    File extension to search (default: txt)\n --output <path>      Output directory (default: same as input directory)\nExamples:\n azure-tts-batch ./text_files\n azure-tts-batch --format mp3 --extension md ./documents\n azure-tts-batch --voice zh-CN-YunxiNeural --output ./audio ./text_files"

    # Check dependencies
    if ! _azure_speech_check_dependencies; then
        return 1
    fi

    # Parse options and arguments
    local speech_key="${AZURE_SPEECH_KEY}"
    local speech_region="${AZURE_SPEECH_REGION}"
    local voice_lang="zh-CN"
    local voice_name="zh-CN-XiaochenMultilingualNeural"
    local voice_gender="female"
    local audio_format="wav"
    local file_extension="txt"
    local input_directory=""
    local output_path=""

    # Parse command line options
    while [ $# -gt 0 ]; do
        case "$1" in
            --key)
                speech_key="$2"
                shift 2
                ;;
            --region)
                speech_region="$2"
                shift 2
                ;;
            --lang)
                voice_lang="$2"
                shift 2
                ;;
            --voice)
                voice_name="$2"
                shift 2
                ;;
            --gender)
                if [ "$2" = "male" ] || [ "$2" = "female" ]; then
                    voice_gender="$2"
                else
                    echo "Error: Invalid gender. Use \"male\" or \"female\"." >&2
                    return 1
                fi
                shift 2
                ;;
            --format)
                case "$2" in
                    wav|mp3|ogg|webm)
                        audio_format="$2"
                        ;;
                    *)
                        echo "Error: Unsupported audio format \"$2\". Use wav, mp3, ogg, or webm." >&2
                        return 1
                        ;;
                esac
                shift 2
                ;;
            --extension)
                file_extension="$2"
                shift 2
                ;;
            --output)
                output_path="$2"
                shift 2
                ;;
            -*)
                echo "Error: Unknown option \"$1\"." >&2
                return 1
                ;;
            *)
                input_directory="$1"
                break
                ;;
        esac
    done

    # Validate required parameters
    if [ -z "$speech_key" ]; then
        echo "Error: Azure Speech Service key not provided. Set AZURE_SPEECH_KEY environment variable or use --key option." >&2
        return 1
    fi

    if [ -z "$speech_region" ]; then
        echo "Error: Azure Speech Service region not provided. Set AZURE_SPEECH_REGION environment variable or use --region option." >&2
        return 1
    fi

    if [ -z "$input_directory" ]; then
        echo "Error: No directory path provided." >&2
        return 1
    fi

    if [ ! -d "$input_directory" ]; then
        echo "Error: Directory \"$input_directory\" does not exist." >&2
        return 1
    fi

    # Set default output path to input directory if not specified
    if [ -z "$output_path" ]; then
        output_path="$input_directory"
    fi

    # Create output directory if it doesnt exist
    if [ ! -d "$output_path" ]; then
        if ! mkdir -p "$output_path" 2>/dev/null; then
            echo "Error: Failed to create output directory \"$output_path\"." >&2
            return 1
        fi
    fi

    # Set audio format for Azure API
    local content_type
    case "$audio_format" in
        wav)
            content_type="riff-24khz-16bit-mono-pcm"
            ;;
        mp3)
            content_type="audio-24khz-160kbitrate-mono-mp3"
            ;;
        ogg)
            content_type="ogg-24khz-16bit-mono-opus"
            ;;
        webm)
            content_type="webm-24khz-16bit-mono-opus"
            ;;
    esac

    # Adjust voice name based on gender if default voice is used
    if [ "$voice_name" = "zh-CN-XiaochenMultilingualNeural" ] && [ "$voice_gender" = "male" ]; then
        voice_name="zh-CN-YunxiNeural"
    fi

    # Find all text files recursively
    local file_count=0
    local success_count=0
    local failed_count=0

    echo "Searching for *.${file_extension} files in \"$input_directory\"..."

    # Use find to recursively search for files
    find "$input_directory" -type f -name "*.${file_extension}" | while IFS= read -r text_file; do
        file_count=$((file_count + 1))
        echo "Processing file $file_count: $(basename "$text_file")"

        # Read text from file
        local file_content
        if ! file_content=$(cat "$text_file" 2>/dev/null); then
            echo "Warning: Failed to read file \"$text_file\". Skipping..." >&2
            failed_count=$((failed_count + 1))
            continue
        fi

        if [ -z "$file_content" ]; then
            echo "Warning: File \"$text_file\" is empty. Skipping..." >&2
            failed_count=$((failed_count + 1))
            continue
        fi

        # Generate output filename
        local base_filename=$(basename "$text_file" | sed "s/\.[^.]*$//")
        local output_filename="${base_filename}_$(date +%Y%m%d_%H%M%S).${audio_format}"
        local full_output_path="${output_path}/${output_filename}"

        # Call helper function to perform TTS
        if _azure_speech_tts_request "$speech_key" "$speech_region" "$voice_lang" "$voice_name" "$file_content" "$content_type" "$full_output_path"; then
            echo "✓ Successfully converted: $output_filename"
            success_count=$((success_count + 1))
        else
            echo "✗ Failed to convert: $(basename "$text_file")" >&2
            failed_count=$((failed_count + 1))
        fi

        # Small delay to avoid overwhelming the API
        sleep 1
    done

    echo "Batch processing completed."
    echo "Total files processed: $file_count"
    echo "Successful conversions: $success_count"
    echo "Failed conversions: $failed_count"
}'

# Azure TTS Voices - List available voices for Azure Speech Service
alias azure-tts-voices='() {
    echo "List available voices for Azure Speech Service."

    # Check dependencies
    if ! _azure_speech_check_dependencies; then
        return 1
    fi

    local speech_key="${AZURE_SPEECH_KEY}"
    local speech_region="${AZURE_SPEECH_REGION}"
    local lang_filter=""

    # Parse command line options
    while [ $# -gt 0 ]; do
        case "$1" in
            --key)
                speech_key="$2"
                shift 2
                ;;
            --region)
                speech_region="$2"
                shift 2
                ;;
            --lang)
                lang_filter="$2"
                shift 2
                ;;
            -*)
                echo "Error: Unknown option \"$1\"." >&2
                return 1
                ;;
            *)
                echo "Error: Unexpected argument \"$1\"." >&2
                return 1
                ;;
        esac
    done

    # Validate required parameters
    if [ -z "$speech_key" ]; then
        echo "Error: Azure Speech Service key not provided. Set AZURE_SPEECH_KEY environment variable or use --key option." >&2
        return 1
    fi

    if [ -z "$speech_region" ]; then
        echo "Error: Azure Speech Service region not provided. Set AZURE_SPEECH_REGION environment variable or use --region option." >&2
        return 1
    fi

    echo "Fetching available voices..."

    # Make API request to get voices list
    local api_url="https://${speech_region}.tts.speech.microsoft.com/cognitiveservices/voices/list"
    local voices_response

    if ! voices_response=$(curl -s -H "Ocp-Apim-Subscription-Key: $speech_key" "$api_url" 2>/dev/null); then
        echo "Error: Failed to fetch voices list from Azure Speech Service." >&2
        return 1
    fi

    # Check if response is valid JSON
    if ! echo "$voices_response" | jq . >/dev/null 2>&1; then
        echo "Error: Invalid response from Azure Speech Service API." >&2
        echo "Response: $voices_response" >&2
        return 1
    fi

    # Parse and display voices
    if [ -n "$lang_filter" ]; then
        echo "Available voices for language: $lang_filter"
        echo "$voices_response" | jq -r ".[] | select(.Locale | startswith(\"$lang_filter\")) | \"\(.ShortName) - \(.DisplayName) (\(.Gender))\""
    else
        echo "Available voices (showing first 20):"
        echo "$voices_response" | jq -r ".[0:20][] | \"\(.ShortName) - \(.DisplayName) (\(.Gender), \(.Locale))\""

        local total_count
        total_count=$(echo "$voices_response" | jq ". | length")
        echo "Total available voices: $total_count"
        echo "Use --lang <language_code> to filter by language (e.g., --lang zh-CN)"
    fi
}'

# Helper function to check required tools
_azure_speech_check_dependencies() {
    # Check for curl
    if ! command -v curl >/dev/null 2>&1; then
        echo "Error: curl is required but not installed. Please install curl first." >&2
        return 1
    fi

    # Check for jq for voice list parsing
    if ! command -v jq >/dev/null 2>&1; then
        echo "Warning: jq is recommended for better voice list formatting. Install jq for enhanced output." >&2
    fi

    return 0
}

# Helper Functions
### --- ###

# Helper function to make TTS API request
_azure_speech_tts_request() {
    local api_key="$1"
    local region="$2"
    local language="$3"
    local voice_name="$4"
    local text_content="$5"
    local content_type="$6"
    local output_file="$7"

    # Validate parameters
    if [ -z "$api_key" ] || [ -z "$region" ] || [ -z "$language" ] || [ -z "$voice_name" ] || [ -z "$text_content" ] || [ -z "$content_type" ] || [ -z "$output_file" ]; then
        echo "Error: Missing required parameters for TTS request." >&2
        return 1
    fi

    # Escape XML special characters in text
    local escaped_text
    escaped_text=$(echo "$text_content" | sed "s/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/\"/\&quot;/g; s/'/\&apos;/g")

    # Check text length (approximately 3000 characters for 10 minutes of speech)
    local text_length=${#text_content}
    if [ $text_length -gt 3000 ]; then
        echo "Warning: Text is very long ($text_length characters). Azure TTS may truncate audio to 10 minutes." >&2
    fi

    # Create SSML content
    local ssml_content="<speak version=\"1.0\" xmlns=\"http://www.w3.org/2001/10/synthesis\" xml:lang=\"$language\"><voice name=\"$voice_name\">$escaped_text</voice></speak>"

    # API endpoint
    local api_url="https://${region}.tts.speech.microsoft.com/cognitiveservices/v1"

    # Make API request
    local http_status
    http_status=$(curl -s -w "%{http_code}" -o "$output_file" \
        -X POST \
        -H "Ocp-Apim-Subscription-Key: $api_key" \
        -H "Content-Type: application/ssml+xml" \
        -H "X-Microsoft-OutputFormat: $content_type" \
        -H "User-Agent: azure-tts-shell-script/1.0" \
        --data-raw "$ssml_content" \
        "$api_url" 2>/dev/null)

    # Check HTTP status
    case "$http_status" in
        200)
            # Success - do nothing
            ;;
        400)
            echo "Error: Bad Request (400) - Required parameter missing, empty, or invalid." >&2
            if [ -f "$output_file" ]; then
                echo "Error details: $(cat "$output_file")" >&2
                rm -f "$output_file" 2>/dev/null
            fi
            return 1
            ;;
        401)
            echo "Error: Unauthorized (401) - Invalid API key or wrong region." >&2
            if [ -f "$output_file" ]; then
                echo "Error details: $(cat "$output_file")" >&2
                rm -f "$output_file" 2>/dev/null
            fi
            return 1
            ;;
        415)
            echo "Error: Unsupported Media Type (415) - Wrong Content-Type. Should be application/ssml+xml." >&2
            if [ -f "$output_file" ]; then
                echo "Error details: $(cat "$output_file")" >&2
                rm -f "$output_file" 2>/dev/null
            fi
            return 1
            ;;
        429)
            echo "Error: Too Many Requests (429) - Request quota or rate limit exceeded." >&2
            if [ -f "$output_file" ]; then
                echo "Error details: $(cat "$output_file")" >&2
                rm -f "$output_file" 2>/dev/null
            fi
            return 1
            ;;
        502)
            echo "Error: Bad Gateway (502) - Network or server-side issue." >&2
            if [ -f "$output_file" ]; then
                echo "Error details: $(cat "$output_file")" >&2
                rm -f "$output_file" 2>/dev/null
            fi
            return 1
            ;;
        503)
            echo "Error: Service Unavailable (503) - Service temporarily unavailable." >&2
            if [ -f "$output_file" ]; then
                echo "Error details: $(cat "$output_file")" >&2
                rm -f "$output_file" 2>/dev/null
            fi
            return 1
            ;;
        *)
            echo "Error: Azure Speech Service API returned unexpected HTTP status $http_status." >&2
            if [ -f "$output_file" ]; then
                echo "Error details: $(cat "$output_file")" >&2
                rm -f "$output_file" 2>/dev/null
            fi
            return 1
            ;;
    esac

    # Verify output file was created and has content
    if [ ! -f "$output_file" ] || [ ! -s "$output_file" ]; then
        echo "Error: Failed to create audio file or file is empty." >&2
        return 1
    fi

    return 0
}

# Help function
### --- ###

alias azure-tts-help='() {
    echo "Azure Speech Service Aliases Help"
    echo "================================="
    echo ""
    echo "Text-to-Speech Functions:"
    echo "  azure-tts [options] <text_or_file>       - Convert text or file to speech"
    echo "  azure-tts-batch [options] <directory>    - Batch convert text files to speech"
    echo "  azure-tts-voices [options]               - List available voices"
    echo ""
    echo "Common Options:"
    echo "  --key <key>          Azure Speech Service API key"
    echo "  --region <region>    Azure Speech Service region"
    echo "  --lang <language>    Language code (default: zh-CN)"
    echo "  --voice <voice_name> Voice name (default: zh-CN-XiaochenMultilingualNeural)"
    echo "  --gender <male|female> Voice gender (default: female)"
    echo "  --format <format>    Audio format: wav, mp3, ogg, webm (default: wav)"
    echo "  --output <path>      Output directory (default: current directory)"
    echo ""
    echo "Additional Options for Batch Processing:"
    echo "  --extension <ext>    File extension to search (default: txt)"
    echo ""
    echo "Environment Variables:"
    echo "  AZURE_SPEECH_KEY     Azure Speech Service API key"
    echo "  AZURE_SPEECH_REGION  Azure Speech Service region (e.g., eastus, westus2)"
    echo ""
    echo "Examples:"
    echo "  azure-tts \"Hello World\""
    echo "  azure-tts --voice zh-CN-YunxiNeural --format mp3 input.txt"
    echo "  azure-tts-batch --format wav --extension md ./documents"
    echo "  azure-tts-voices --lang zh-CN"
    echo ""
    echo "For detailed usage of any command, run it without parameters."
}' # Display help information for all Azure TTS aliases
