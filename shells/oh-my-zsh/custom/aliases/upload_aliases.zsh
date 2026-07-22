# Description: Upload related aliases for file uploading operations with various options.

# Helper functions for upload aliases
_show_error_upload_aliases() {
  echo "$1" >&2
  return 1
}

_upload_aliases_check_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    _show_error_upload_aliases "Error: Required command \"$1\" not found."
    return 1
  fi
  return 0
}

_upload_aliases_print_imgloc_help() {
  cat <<EOF
Upload image files to imgloc.com.
Usage:
 upload-imgloc [options] <image_path> [image_path2] [image_path3] ...

Options:
  -k, --api-key KEY        ImgLoc API key. Defaults to IMGLOC_API_KEY.
  -o, --output FORMAT      Output format: direct, viewer, delete, markdown, html, bbcode, json.
  --json                   Shortcut for --output json.
  -h, --help               Show help message.

Examples:
  export IMGLOC_API_KEY="your_api_key"
  upload-imgloc image.png
  upload-imgloc image.png image2.webp
  upload-imgloc --api-key "your_api_key" --output markdown image.png
  IMGLOC_API_KEY="your_api_key" upload-imgloc --output viewer image.png
EOF
}

_upload_aliases_print_freeimage_help() {
  cat <<EOF
Upload image files to freeimage.host.
Usage:
 upload-freeimage [options] <image_path> [image_path2] [image_path3] ...

Options:
  -k, --api-key KEY        Freeimage API key. Defaults to FREEIMAGE_HOST_API_KEY or FREEIMAGE_API_KEY.
  -o, --output FORMAT      Output format: direct, viewer, markdown, html, bbcode, json.
  --json                   Shortcut for --output json.
  -h, --help               Show help message.

Examples:
  export FREEIMAGE_HOST_API_KEY="your_api_key"
  upload-freeimage image.png
  upload-freeimage image.png image2.webp
  upload-freeimage --api-key "your_api_key" --output markdown image.png
  FREEIMAGE_API_KEY="your_api_key" upload-freeimage --output viewer image.png
EOF
}

_upload_aliases_print_catbox_help() {
  cat <<EOF
Upload files to catbox.moe.
Usage:
 upload-catbox [options] <file_path> [file_path2] [file_path3] ...

Options:
  -u, --userhash HASH      Catbox userhash. Defaults to CATBOX_USERHASH. Optional for anonymous upload.
  -o, --output FORMAT      Output format: direct, markdown, html, bbcode.
  -h, --help               Show help message.

Examples:
  upload-catbox image.png
  upload-catbox image.png image2.webp
  upload-catbox --output markdown image.png
  CATBOX_USERHASH="your_userhash" upload-catbox image.png
EOF
}

_upload_aliases_print_litterbox_help() {
  cat <<EOF
Upload files to litterbox.catbox.moe temporary storage.
Usage:
 upload-litterbox [options] <file_path> [file_path2] [file_path3] ...

Options:
  -t, --time DURATION      Retention time. Allowed values: 1h, 12h, 24h, 72h. Default: 1h.
  -o, --output FORMAT      Output format: direct, markdown, html, bbcode.
  -h, --help               Show help message.

Examples:
  upload-litterbox image.png
  upload-litterbox --time 24h image.png
  upload-litterbox --output markdown image.png
  upload-litterbox --time 72h image.png image2.webp
EOF
}

_upload_aliases_extract_json_value() {
  local json_content="$1"
  local value_path="${2#.}"

  if command -v jq >/dev/null 2>&1; then
    printf "%s" "$json_content" | jq -r ".${value_path} // empty"
    return $?
  fi

  if command -v python3 >/dev/null 2>&1; then
    UPLOAD_ALIASES_JSON_CONTENT="$json_content" python3 - "$value_path" <<"PY"
import json
import os
import sys

path = sys.argv[1]
content = os.environ.get("UPLOAD_ALIASES_JSON_CONTENT", "")

if not content:
    sys.exit(0)

try:
    data = json.loads(content)
except json.JSONDecodeError:
    sys.exit(1)

value = data
for part in path.split("."):
    if not part:
        continue
    if isinstance(value, dict):
        value = value.get(part)
    else:
        value = None
    if value is None:
        break

if value is None:
    sys.exit(0)

if isinstance(value, (dict, list)):
    print(json.dumps(value, ensure_ascii=False))
else:
    print(value)
PY
    return $?
  fi

  _show_error_upload_aliases "Error: Either jq or python3 is required to parse API responses."
  return 1
}

_upload_aliases_print_json() {
  local json_content="$1"

  if command -v jq >/dev/null 2>&1; then
    printf "%s" "$json_content" | jq .
    return $?
  fi

  if command -v python3 >/dev/null 2>&1; then
    printf "%s" "$json_content" | python3 -m json.tool
    return $?
  fi

  printf "%s\n" "$json_content"
  return 0
}

_upload_aliases_format_direct_output() {
  local direct_url="$1"
  local output_format="$2"
  local file_path="$3"
  local viewer_url="${4:-}"
  local delete_url="${5:-}"
  local json_content="${6:-}"
  local original_filename

  original_filename=$(basename "$file_path")

  case "$output_format" in
    direct)
      [ -n "$direct_url" ] || return 1
      printf "%s\n" "$direct_url"
      ;;
    viewer)
      [ -n "$viewer_url" ] || return 1
      printf "%s\n" "$viewer_url"
      ;;
    delete)
      [ -n "$delete_url" ] || return 1
      printf "%s\n" "$delete_url"
      ;;
    markdown)
      [ -n "$direct_url" ] || return 1
      printf "![%s](%s)\n" "$original_filename" "$direct_url"
      ;;
    html)
      [ -n "$direct_url" ] || return 1
      printf "<img src=\"%s\" alt=\"%s\" />\n" "$direct_url" "$original_filename"
      ;;
    bbcode)
      [ -n "$direct_url" ] || return 1
      printf "[img]%s[/img]\n" "$direct_url"
      ;;
    json)
      [ -n "$json_content" ] || return 1
      _upload_aliases_print_json "$json_content"
      ;;
    *)
      _show_error_upload_aliases "Error: Unsupported output format \"$output_format\"."
      return 1
      ;;
  esac

  return 0
}

_upload_aliases_emit_json_image_output() {
  local json_content="$1"
  local output_format="$2"
  local file_path="$3"
  local direct_url
  local viewer_url
  local delete_url
  local original_filename

  direct_url=$(_upload_aliases_extract_json_value "$json_content" ".image.url") || return 1
  viewer_url=$(_upload_aliases_extract_json_value "$json_content" ".image.url_viewer") || return 1
  delete_url=$(_upload_aliases_extract_json_value "$json_content" ".image.delete_url") || return 1
  original_filename=$(_upload_aliases_extract_json_value "$json_content" ".image.original_filename") || return 1

  if [ -n "$original_filename" ]; then
    file_path="$original_filename"
  fi

  _upload_aliases_format_direct_output "$direct_url" "$output_format" "$file_path" "$viewer_url" "$delete_url" "$json_content"
}

_upload_aliases_validate_litterbox_time() {
  case "$1" in
    1h|12h|24h|72h)
      return 0
      ;;
    *)
      _show_error_upload_aliases "Error: Invalid Litterbox time \"$1\". Allowed values: 1h, 12h, 24h, 72h."
      return 1
      ;;
  esac
}

_upload_aliases_upload_file_to_imgloc() {
  local api_key="$1"
  local file_path="$2"
  local output_format="$3"
  local response_file
  local error_file
  local response_body
  local http_code
  local curl_exit
  local error_message

  response_file=$(mktemp)
  error_file=$(mktemp)

  if [ -z "$response_file" ] || [ -z "$error_file" ]; then
    [ -n "$response_file" ] && rm -f "$response_file"
    [ -n "$error_file" ] && rm -f "$error_file"
    _show_error_upload_aliases "Error: Failed to create temporary files for ImgLoc upload."
    return 1
  fi

  http_code=$(curl -sS -o "$response_file" -w "%{http_code}" \
    -X POST \
    -H "X-API-Key: $api_key" \
    -F "source=@$file_path" \
    "https://imgloc.com/api/1/upload" 2>"$error_file")
  curl_exit=$?

  response_body=$(cat "$response_file")
  rm -f "$response_file"

  if [ $curl_exit -ne 0 ]; then
    _show_error_upload_aliases "Error: Failed to upload \"$file_path\" to imgloc.com."
    if [ -s "$error_file" ]; then
      cat "$error_file" >&2
    fi
    rm -f "$error_file"
    return 1
  fi

  rm -f "$error_file"

  if [ "$http_code" != "200" ]; then
    error_message=$(_upload_aliases_extract_json_value "$response_body" ".error.message")
    if [ -z "$error_message" ]; then
      error_message=$(_upload_aliases_extract_json_value "$response_body" ".status_txt")
    fi
    if [ -z "$error_message" ]; then
      error_message="ImgLoc API request failed with HTTP $http_code."
    fi

    _show_error_upload_aliases "Error: ${error_message}"
    if [ -n "$response_body" ]; then
      _upload_aliases_print_json "$response_body" >&2
    fi
    return 1
  fi

  if ! _upload_aliases_emit_json_image_output "$response_body" "$output_format" "$file_path"; then
    _show_error_upload_aliases "Error: Failed to parse ImgLoc response for \"$file_path\"."
    if [ -n "$response_body" ]; then
      _upload_aliases_print_json "$response_body" >&2
    fi
    return 1
  fi

  return 0
}

_upload_aliases_upload_file_to_freeimage() {
  local api_key="$1"
  local file_path="$2"
  local output_format="$3"
  local response_file
  local error_file
  local response_body
  local http_code
  local curl_exit
  local error_message

  response_file=$(mktemp)
  error_file=$(mktemp)

  if [ -z "$response_file" ] || [ -z "$error_file" ]; then
    [ -n "$response_file" ] && rm -f "$response_file"
    [ -n "$error_file" ] && rm -f "$error_file"
    _show_error_upload_aliases "Error: Failed to create temporary files for Freeimage upload."
    return 1
  fi

  http_code=$(curl -sS -o "$response_file" -w "%{http_code}" \
    -X POST \
    -F "key=$api_key" \
    -F "action=upload" \
    -F "format=json" \
    -F "source=@$file_path" \
    "https://freeimage.host/api/1/upload" 2>"$error_file")
  curl_exit=$?

  response_body=$(cat "$response_file")
  rm -f "$response_file"

  if [ $curl_exit -ne 0 ]; then
    _show_error_upload_aliases "Error: Failed to upload \"$file_path\" to freeimage.host."
    if [ -s "$error_file" ]; then
      cat "$error_file" >&2
    fi
    rm -f "$error_file"
    return 1
  fi

  rm -f "$error_file"

  if [ "$http_code" != "200" ]; then
    error_message=$(_upload_aliases_extract_json_value "$response_body" ".error.message")
    if [ -z "$error_message" ]; then
      error_message=$(_upload_aliases_extract_json_value "$response_body" ".status_txt")
    fi
    if [ -z "$error_message" ]; then
      error_message="Freeimage API request failed with HTTP $http_code."
    fi

    _show_error_upload_aliases "Error: ${error_message}"
    if [ -n "$response_body" ]; then
      _upload_aliases_print_json "$response_body" >&2
    fi
    return 1
  fi

  if ! _upload_aliases_emit_json_image_output "$response_body" "$output_format" "$file_path"; then
    _show_error_upload_aliases "Error: Failed to parse Freeimage response for \"$file_path\"."
    if [ -n "$response_body" ]; then
      _upload_aliases_print_json "$response_body" >&2
    fi
    return 1
  fi

  return 0
}

_upload_aliases_upload_file_to_catbox() {
  local userhash="$1"
  local file_path="$2"
  local output_format="$3"
  local response_file
  local error_file
  local direct_url
  local curl_exit

  response_file=$(mktemp)
  error_file=$(mktemp)

  if [ -z "$response_file" ] || [ -z "$error_file" ]; then
    [ -n "$response_file" ] && rm -f "$response_file"
    [ -n "$error_file" ] && rm -f "$error_file"
    _show_error_upload_aliases "Error: Failed to create temporary files for Catbox upload."
    return 1
  fi

  if [ -n "$userhash" ]; then
    curl -sS \
      -F "reqtype=fileupload" \
      -F "userhash=$userhash" \
      -F "fileToUpload=@$file_path" \
      "https://catbox.moe/user/api.php" >"$response_file" 2>"$error_file"
  else
    curl -sS \
      -F "reqtype=fileupload" \
      -F "fileToUpload=@$file_path" \
      "https://catbox.moe/user/api.php" >"$response_file" 2>"$error_file"
  fi
  curl_exit=$?

  direct_url=$(tr -d "\r" <"$response_file")
  rm -f "$response_file"

  if [ $curl_exit -ne 0 ]; then
    _show_error_upload_aliases "Error: Failed to upload \"$file_path\" to catbox.moe."
    if [ -s "$error_file" ]; then
      cat "$error_file" >&2
    fi
    rm -f "$error_file"
    return 1
  fi

  rm -f "$error_file"

  if [[ "$direct_url" != https://* ]] && [[ "$direct_url" != http://* ]]; then
    _show_error_upload_aliases "Error: Catbox upload failed for \"$file_path\"."
    if [ -n "$direct_url" ]; then
      printf "%s\n" "$direct_url" >&2
    fi
    return 1
  fi

  if ! _upload_aliases_format_direct_output "$direct_url" "$output_format" "$file_path"; then
    _show_error_upload_aliases "Error: Failed to format Catbox response for \"$file_path\"."
    return 1
  fi

  return 0
}

_upload_aliases_upload_file_to_litterbox() {
  local retention_time="$1"
  local file_path="$2"
  local output_format="$3"
  local response_file
  local error_file
  local direct_url
  local curl_exit

  response_file=$(mktemp)
  error_file=$(mktemp)

  if [ -z "$response_file" ] || [ -z "$error_file" ]; then
    [ -n "$response_file" ] && rm -f "$response_file"
    [ -n "$error_file" ] && rm -f "$error_file"
    _show_error_upload_aliases "Error: Failed to create temporary files for Litterbox upload."
    return 1
  fi

  curl -sS \
    -F "reqtype=fileupload" \
    -F "time=$retention_time" \
    -F "fileToUpload=@$file_path" \
    "https://litterbox.catbox.moe/resources/internals/api.php" >"$response_file" 2>"$error_file"
  curl_exit=$?

  direct_url=$(tr -d "\r" <"$response_file")
  rm -f "$response_file"

  if [ $curl_exit -ne 0 ]; then
    _show_error_upload_aliases "Error: Failed to upload \"$file_path\" to litterbox.catbox.moe."
    if [ -s "$error_file" ]; then
      cat "$error_file" >&2
    fi
    rm -f "$error_file"
    return 1
  fi

  rm -f "$error_file"

  if [[ "$direct_url" != https://* ]] && [[ "$direct_url" != http://* ]]; then
    _show_error_upload_aliases "Error: Litterbox upload failed for \"$file_path\"."
    if [ -n "$direct_url" ]; then
      printf "%s\n" "$direct_url" >&2
    fi
    return 1
  fi

  if ! _upload_aliases_format_direct_output "$direct_url" "$output_format" "$file_path"; then
    _show_error_upload_aliases "Error: Failed to format Litterbox response for \"$file_path\"."
    return 1
  fi

  return 0
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

alias upload-imgloc='() {
  local api_key="${IMGLOC_API_KEY:-}"
  local output_format="direct"
  local has_error=0
  local file_path=""
  local input_files=()

  while [ $# -gt 0 ]; do
    case "$1" in
      -k|--api-key)
        if [ -z "$2" ] || [[ "$2" == -* ]]; then
          _show_error_upload_aliases "Error: Missing value for $1."
          return 1
        fi
        api_key="$2"
        shift 2
        continue
        ;;
      -o|--output)
        if [ -z "$2" ] || [[ "$2" == -* ]]; then
          _show_error_upload_aliases "Error: Missing value for $1."
          return 1
        fi
        output_format="$2"
        shift 2
        continue
        ;;
      --json)
        output_format="json"
        shift
        continue
        ;;
      -h|--help)
        _upload_aliases_print_imgloc_help
        return 0
        ;;
      --)
        shift
        while [ $# -gt 0 ]; do
          input_files+=("$1")
          shift
        done
        break
        ;;
      -*)
        _show_error_upload_aliases "Error: Unknown option \"$1\"."
        _upload_aliases_print_imgloc_help
        return 1
        ;;
      *)
        input_files+=("$1")
        shift
        continue
        ;;
    esac
  done

  if [ ${#input_files[@]} -eq 0 ]; then
    _upload_aliases_print_imgloc_help
    return 1
  fi

  case "$output_format" in
    direct|viewer|delete|markdown|html|bbcode|json)
      ;;
    *)
      _show_error_upload_aliases "Error: Unsupported output format \"$output_format\"."
      return 1
      ;;
  esac

  _upload_aliases_check_command "curl" || return 1

  if ! command -v jq >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
    _show_error_upload_aliases "Error: Either jq or python3 is required to parse API responses."
    return 1
  fi

  if [ -z "$api_key" ]; then
    _show_error_upload_aliases "Error: IMGLOC_API_KEY is not set. Use --api-key or export IMGLOC_API_KEY."
    return 1
  fi

  for file_path in "${input_files[@]}"; do
    if [ ! -f "$file_path" ]; then
      _show_error_upload_aliases "Error: File \"$file_path\" not found."
      has_error=1
      continue
    fi

    if ! _upload_aliases_upload_file_to_imgloc "$api_key" "$file_path" "$output_format"; then
      has_error=1
    fi
  done

  [ $has_error -eq 0 ]
}' # Upload image files to imgloc.com via API

alias upload-freeimage='() {
  local api_key="${FREEIMAGE_HOST_API_KEY:-${FREEIMAGE_API_KEY:-}}"
  local output_format="direct"
  local has_error=0
  local file_path=""
  local input_files=()

  while [ $# -gt 0 ]; do
    case "$1" in
      -k|--api-key)
        if [ -z "$2" ] || [[ "$2" == -* ]]; then
          _show_error_upload_aliases "Error: Missing value for $1."
          return 1
        fi
        api_key="$2"
        shift 2
        continue
        ;;
      -o|--output)
        if [ -z "$2" ] || [[ "$2" == -* ]]; then
          _show_error_upload_aliases "Error: Missing value for $1."
          return 1
        fi
        output_format="$2"
        shift 2
        continue
        ;;
      --json)
        output_format="json"
        shift
        continue
        ;;
      -h|--help)
        _upload_aliases_print_freeimage_help
        return 0
        ;;
      --)
        shift
        while [ $# -gt 0 ]; do
          input_files+=("$1")
          shift
        done
        break
        ;;
      -*)
        _show_error_upload_aliases "Error: Unknown option \"$1\"."
        _upload_aliases_print_freeimage_help
        return 1
        ;;
      *)
        input_files+=("$1")
        shift
        continue
        ;;
    esac
  done

  if [ ${#input_files[@]} -eq 0 ]; then
    _upload_aliases_print_freeimage_help
    return 1
  fi

  case "$output_format" in
    direct|viewer|markdown|html|bbcode|json)
      ;;
    *)
      _show_error_upload_aliases "Error: Unsupported output format \"$output_format\"."
      return 1
      ;;
  esac

  _upload_aliases_check_command "curl" || return 1

  if ! command -v jq >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
    _show_error_upload_aliases "Error: Either jq or python3 is required to parse Freeimage API responses."
    return 1
  fi

  if [ -z "$api_key" ]; then
    _show_error_upload_aliases "Error: FREEIMAGE_HOST_API_KEY is not set. Use --api-key or export FREEIMAGE_HOST_API_KEY or FREEIMAGE_API_KEY."
    return 1
  fi

  for file_path in "${input_files[@]}"; do
    if [ ! -f "$file_path" ]; then
      _show_error_upload_aliases "Error: File \"$file_path\" not found."
      has_error=1
      continue
    fi

    if ! _upload_aliases_upload_file_to_freeimage "$api_key" "$file_path" "$output_format"; then
      has_error=1
    fi
  done

  [ $has_error -eq 0 ]
}' # Upload image files to freeimage.host via API

alias upload-catbox='() {
  local userhash="${CATBOX_USERHASH:-}"
  local output_format="direct"
  local has_error=0
  local file_path=""
  local input_files=()

  while [ $# -gt 0 ]; do
    case "$1" in
      -u|--userhash)
        if [ -z "$2" ] || [[ "$2" == -* ]]; then
          _show_error_upload_aliases "Error: Missing value for $1."
          return 1
        fi
        userhash="$2"
        shift 2
        continue
        ;;
      -o|--output)
        if [ -z "$2" ] || [[ "$2" == -* ]]; then
          _show_error_upload_aliases "Error: Missing value for $1."
          return 1
        fi
        output_format="$2"
        shift 2
        continue
        ;;
      -h|--help)
        _upload_aliases_print_catbox_help
        return 0
        ;;
      --)
        shift
        while [ $# -gt 0 ]; do
          input_files+=("$1")
          shift
        done
        break
        ;;
      -*)
        _show_error_upload_aliases "Error: Unknown option \"$1\"."
        _upload_aliases_print_catbox_help
        return 1
        ;;
      *)
        input_files+=("$1")
        shift
        continue
        ;;
    esac
  done

  if [ ${#input_files[@]} -eq 0 ]; then
    _upload_aliases_print_catbox_help
    return 1
  fi

  case "$output_format" in
    direct|markdown|html|bbcode)
      ;;
    *)
      _show_error_upload_aliases "Error: Unsupported output format \"$output_format\"."
      return 1
      ;;
  esac

  _upload_aliases_check_command "curl" || return 1

  for file_path in "${input_files[@]}"; do
    if [ ! -f "$file_path" ]; then
      _show_error_upload_aliases "Error: File \"$file_path\" not found."
      has_error=1
      continue
    fi

    if ! _upload_aliases_upload_file_to_catbox "$userhash" "$file_path" "$output_format"; then
      has_error=1
    fi
  done

  [ $has_error -eq 0 ]
}' # Upload files to catbox.moe

alias upload-litterbox='() {
  local retention_time="1h"
  local output_format="direct"
  local has_error=0
  local file_path=""
  local input_files=()

  while [ $# -gt 0 ]; do
    case "$1" in
      -t|--time)
        if [ -z "$2" ] || [[ "$2" == -* ]]; then
          _show_error_upload_aliases "Error: Missing value for $1."
          return 1
        fi
        retention_time="$2"
        shift 2
        continue
        ;;
      -o|--output)
        if [ -z "$2" ] || [[ "$2" == -* ]]; then
          _show_error_upload_aliases "Error: Missing value for $1."
          return 1
        fi
        output_format="$2"
        shift 2
        continue
        ;;
      -h|--help)
        _upload_aliases_print_litterbox_help
        return 0
        ;;
      --)
        shift
        while [ $# -gt 0 ]; do
          input_files+=("$1")
          shift
        done
        break
        ;;
      -*)
        _show_error_upload_aliases "Error: Unknown option \"$1\"."
        _upload_aliases_print_litterbox_help
        return 1
        ;;
      *)
        input_files+=("$1")
        shift
        continue
        ;;
    esac
  done

  if [ ${#input_files[@]} -eq 0 ]; then
    _upload_aliases_print_litterbox_help
    return 1
  fi

  case "$output_format" in
    direct|markdown|html|bbcode)
      ;;
    *)
      _show_error_upload_aliases "Error: Unsupported output format \"$output_format\"."
      return 1
      ;;
  esac

  _upload_aliases_validate_litterbox_time "$retention_time" || return 1
  _upload_aliases_check_command "curl" || return 1

  for file_path in "${input_files[@]}"; do
    if [ ! -f "$file_path" ]; then
      _show_error_upload_aliases "Error: File \"$file_path\" not found."
      has_error=1
      continue
    fi

    if ! _upload_aliases_upload_file_to_litterbox "$retention_time" "$file_path" "$output_format"; then
      has_error=1
    fi
  done

  [ $has_error -eq 0 ]
}' # Upload files to litterbox.catbox.moe temporary storage

alias upload-help='() {
  echo "Upload Aliases Help"
  echo "==================="
  echo ""
  echo "Available commands:"
  echo "  upload-alist [options] <file_path> [file_path2] ... - Upload multiple files to alist"
  echo "  upload-catbox [options] <file_path> [file_path2] ... - Upload files to catbox.moe"
  echo "  upload-litterbox [options] <file_path> [file_path2] ... - Upload files to litterbox.catbox.moe temporary storage"
  echo "  upload-freeimage [options] <image_path> [image_path2] ... - Upload images to freeimage.host"
  echo "  upload-imgloc [options] <image_path> [image_path2] ... - Upload images to imgloc.com"
  echo ""
  echo "Environment variables:"
  echo "  CATBOX_USERHASH - Optional Catbox userhash for account uploads"
  echo "  FREEIMAGE_HOST_API_KEY - Default API key for upload-freeimage"
  echo "  FREEIMAGE_API_KEY - Alternate API key variable for upload-freeimage"
  echo "  IMGLOC_API_KEY - Default API key for upload-imgloc"
}' # Upload Aliases Help
