# Description: HTTP request related aliases for common operations like GET, POST, PUT, DELETE, file upload/download and API testing.

# Helper functions for request aliases
_show_error_request_aliases() {
  echo "$1" >&2
  return 1
}

# Helper function removed as requested

_check_command_request_aliases() {
  if ! command -v "$1" &> /dev/null; then
    _show_error_request_aliases "Error: Required command \"$1\" not found. Please install it first."
    return 1
  fi
  return 0
}

_check_json_validity_request_aliases() {
  if ! echo "$1" | jq . >/dev/null 2>&1; then
    _show_error_request_aliases "Error: Invalid JSON format."
    return 1
  fi
  return 0
}

_format_json_request_aliases() {
  if ! _check_command_request_aliases jq; then
    echo "$1"
    return 1
  fi

  echo "$1" | jq .
  return 0
}

#===================================
# Basic HTTP Request Methods
#===================================

alias req-get='() {
  if ! _check_command_request_aliases curl; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo -e "Send HTTP GET request with formatted output.\nUsage:\n req-get <url:required> [curl_options:optional]\nExamples:\n req-get https://api.example.com/users\n req-get https://api.example.com/users -H \"Authorization: Bearer token\""
    return 1
  fi

  local url="$1"
  shift

  echo "Sending GET request to $url..."
  local response=$(curl -sS "$url" "$@")
  local status=$?

  if [ $status -ne 0 ]; then
    _show_error_request_aliases "GET request failed. Check the URL and your internet connection."
    return 1
  fi

  # Try to format as JSON if possible
  if echo "$response" | jq . >/dev/null 2>&1; then
    echo "$response" | jq .
  else
    echo "$response"
  fi
}' # Send HTTP GET request with formatted output

alias req-post='() {
  if ! _check_command_request_aliases curl; then
    return 1
  fi

  if [ $# -lt 2 ]; then
    echo -e "Send HTTP POST request with JSON data.\nUsage:\n req-post <url:required> <json_data:required> [curl_options:optional]\nExamples:\n req-post https://api.example.com/users '{\"name\":\"John\",\"email\":\"john@example.com\"}'\n req-post https://api.example.com/users '{\"name\":\"John\"}' -H \"Authorization: Bearer token\""
    return 1
  fi

  local url="$1"
  local data="$2"
  shift 2

  # Validate JSON data
  if ! _check_json_validity_request_aliases "$data"; then
    return 1
  fi

  echo "Sending POST request to $url..."
  local response=$(curl -sS -X POST -H "Content-Type: application/json" -d "$data" "$url" "$@")
  local status=$?

  if [ $status -ne 0 ]; then
    _show_error_request_aliases "POST request failed. Check the URL, data format, and your internet connection."
    return 1
  fi

  # Try to format as JSON if possible
  if echo "$response" | jq . >/dev/null 2>&1; then
    echo "$response" | jq .
  else
    echo "$response"
  fi
}' # Send HTTP POST request with JSON data

alias req-put='() {
  if ! _check_command_request_aliases curl; then
    return 1
  fi

  if [ $# -lt 2 ]; then
    echo -e "Send HTTP PUT request with JSON data.\nUsage:\n req-put <url:required> <json_data:required> [curl_options:optional]\nExamples:\n req-put https://api.example.com/users/1 \"{your json data}\" -H \"Authorization: Bearer token\""
    return 1
  fi

  local url="$1"
  local data="$2"
  shift 2

  # Validate JSON data
  if ! _check_json_validity_request_aliases "$data"; then
    return 1
  fi

  echo "Sending PUT request to $url..."
  local response=$(curl -sS -X PUT -H "Content-Type: application/json" -d "$data" "$url" "$@")
  local status=$?

  if [ $status -ne 0 ]; then
    _show_error_request_aliases "PUT request failed. Check the URL, data format, and your internet connection."
    return 1
  fi

  # Try to format as JSON if possible
  if echo "$response" | jq . >/dev/null 2>&1; then
    echo "$response" | jq .
  else
    echo "$response"
  fi
}' # Send HTTP PUT request with JSON data

alias req-delete='() {
  if ! _check_command_request_aliases curl; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo -e "Send HTTP DELETE request.\nUsage:\n req-delete <url:required> [curl_options:optional]\nExamples:\n req-delete https://api.example.com/users/1\n req-delete https://api.example.com/users/1 -H \"Authorization: Bearer token\""
    return 1
  fi

  local url="$1"
  shift

  echo "Sending DELETE request to $url..."
  local response=$(curl -sS -X DELETE "$url" "$@")
  local status=$?

  if [ $status -ne 0 ]; then
    _show_error_request_aliases "DELETE request failed. Check the URL and your internet connection."
    return 1
  fi

  # Try to format as JSON if possible
  if echo "$response" | jq . >/dev/null 2>&1; then
    echo "$response" | jq .
  else
    echo "$response"
  fi
}' # Send HTTP DELETE request

alias req-patch='() {
  if ! _check_command_request_aliases curl; then
    return 1
  fi

  if [ $# -lt 2 ]; then
    echo -e "Send HTTP PATCH request with JSON data.\nUsage:\n req-patch <url:required> <json_data:required> [curl_options:optional]\nExamples:\n req-patch https://api.example.com/users/1 \"{your json data}\"\n req-patch https://api.example.com/users/1 \"{your json data}\" -H \"Authorization: Bearer token\""
    return 1
  fi

  local url="$1"
  local data="$2"
  shift 2

  # Validate JSON data
  if ! _check_json_validity_request_aliases "$data"; then
    return 1
  fi

  echo "Sending PATCH request to $url..."
  local response=$(curl -sS -X PATCH -H "Content-Type: application/json" -d "$data" "$url" "$@")
  local status=$?

  if [ $status -ne 0 ]; then
    _show_error_request_aliases "PATCH request failed. Check the URL, data format, and your internet connection."
    return 1
  fi

  # Try to format as JSON if possible
  if echo "$response" | jq . >/dev/null 2>&1; then
    echo "$response" | jq .
  else
    echo "$response"
  fi
}' # Send HTTP PATCH request with JSON data

alias req-head='() {
  if ! _check_command_request_aliases curl; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo -e "Get HTTP headers only.\nUsage:\n req-head <url:required> [curl_options:optional]\nExamples:\n req-head https://api.example.com/users\n req-head https://api.example.com/users -H \"Authorization: Bearer token\""
    return 1
  fi

  local url="$1"
  shift

  echo "Getting headers from $url..."
  if ! curl -sS -I "$url" "$@"; then
    _show_error_request_aliases "Failed to retrieve HTTP headers. Check the URL and your internet connection."
    return 1
  fi
}' # Get HTTP headers only

#===================================
# File Upload and Download
#===================================

alias req-upload-file='() {
  if ! _check_command_request_aliases curl; then
    return 1
  fi

  if [ $# -lt 2 ]; then
    echo -e "Upload a file using HTTP POST request.\nUsage:\n req-upload-file <url:required> <file_path:required> [form_field_name:file] [curl_options:optional]\nExamples:\n req-upload-file https://api.example.com/upload /path/to/file.jpg\n req-upload-file https://api.example.com/upload /path/to/file.jpg document -H \"Authorization: Bearer token\""
    return 1
  fi

  local url="$1"
  local file_path="$2"
  local field_name="${3:-file}"
  shift 3

  if [ ! -f "$file_path" ]; then
    _show_error_request_aliases "Error: File '$file_path' not found."
    return 1
  fi

  echo "Uploading file '$file_path' to $url..."
  local response=$(curl -sS -X POST -F "$field_name=@$file_path" "$url" "$@")
  local status=$?

  if [ $status -ne 0 ]; then
    _show_error_request_aliases "File upload failed. Check the URL, file path, and your internet connection."
    return 1
  fi

  # Try to format as JSON if possible
  if echo "$response" | jq . >/dev/null 2>&1; then
    echo "$response" | jq .
  else
    echo "$response"
  fi
}' # Upload a file using HTTP POST request

alias req-download-file='() {
  if ! _check_command_request_aliases curl; then
    return 1
  fi

  if [ $# -lt 2 ]; then
    echo -e "Download a file from URL.\nUsage:\n req-download-file <url:required> <output_path:required> [curl_options:optional]\nExamples:\n req-download-file https://example.com/file.zip ./downloads/file.zip\n req-download-file https://example.com/file.zip ./downloads/file.zip -H \"Authorization: Bearer token\""
    return 1
  fi

  local url="$1"
  local output_path="$2"
  shift 2

  # Create directory if it doesn"t exist
  local dir_path=$(dirname "$output_path")
  if [ ! -d "$dir_path" ]; then
    if ! mkdir -p "$dir_path"; then
      _show_error_request_aliases "Failed to create directory: $dir_path"
      return 1
    fi
  fi

  echo "Downloading file from $url to $output_path..."
  if ! curl -sS -L -o "$output_path" "$url" "$@"; then
    _show_error_request_aliases "Download failed. Check the URL and your internet connection."
    return 1
  fi

  echo "Download complete, saved to $output_path"
}' # Download a file from URL

#===================================
# API Testing and Utilities
#===================================

alias req-json='() {
  if ! _check_command_request_aliases curl || ! _check_command_request_aliases jq; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo -e "Send HTTP request and format JSON response.\nUsage:\n req-json <method:required> <url:required> [data:optional] [curl_options:optional]\nExamples:\n req-json GET https://api.example.com/users\n req-json POST https://api.example.com/users \"{your json data}\"\n req-json PUT https://api.example.com/users/1 \"{your json data}\" -H \"Authorization: Bearer token\""
    return 1
  fi

  local method=$(echo "$1" | tr "[:lower:]" "[:upper:]")
  local url="$2"
  local data=""
  local curl_args=()

  if [ -z "$method" ] || [ -z "$url" ]; then
    _show_error_request_aliases "Error: Method and URL are required."
    return 1
  fi

  shift 2

  # Check if the next argument is JSON data (for POST, PUT, PATCH)
  if [ "$method" = "POST" ] || [ "$method" = "PUT" ] || [ "$method" = "PATCH" ]; then
    if [ $# -gt 0 ]; then
      data="$1"
      shift

      # Validate JSON data
      if ! _check_json_validity_request_aliases "$data"; then
        return 1
      fi

      curl_args+=(-H "Content-Type: application/json" -d "$data")
    fi
  fi

  # Add remaining arguments as curl options
  while [ $# -gt 0 ]; do
    curl_args+=("$1")
    shift
  done

  echo "Sending $method request to $url..."
  local response=$(curl -sS -X "$method" "${curl_args[@]}" "$url")
  local status=$?

  if [ $status -ne 0 ]; then
    _show_error_request_aliases "$method request failed. Check the URL, data format, and your internet connection."
    return 1
  fi

  # Format JSON response
  if ! _format_json_request_aliases "$response"; then
    echo "$response"
  fi
}' # Send HTTP request and format JSON response

alias req-form='() {
  if ! _check_command_request_aliases curl; then
    return 1
  fi

  if [ $# -lt 2 ]; then
    echo -e "Send HTTP POST request with form data.\nUsage:\n req-form <url:required> <field1=value1:required> [field2=value2:optional] [curl_options:optional]\nExamples:\n req-form https://api.example.com/submit name=John email=john@example.com\n req-form https://api.example.com/submit name=John -H \"Authorization: Bearer token\""
    return 1
  fi

  local url="$1"
  shift

  local form_data=()
  local curl_args=()

  # Process arguments to separate form fields from curl options
  while [ $# -gt 0 ]; do
    if [[ "$1" == *=* ]]; then
      form_data+=("$1")
    else
      curl_args+=("$1")
    fi
    shift
  done

  echo "Sending POST form request to $url..."
  local response=$(curl -sS -X POST "${form_data[@]/#/-d }" "${curl_args[@]}" "$url")
  local status=$?

  if [ $status -ne 0 ]; then
    _show_error_request_aliases "Form submission failed. Check the URL, form data, and your internet connection."
    return 1
  fi

  # Try to format as JSON if possible
  if echo "$response" | jq . >/dev/null 2>&1; then
    echo "$response" | jq .
  else
    echo "$response"
  fi
}' # Send HTTP POST request with form data


alias req-auth='() {
  if ! _check_command_request_aliases curl; then
    return 1
  fi

  if [ $# -lt 3 ]; then
    echo -e "Send HTTP request with Basic Authentication.\nUsage:\n req-auth <method:required> <url:required> <username:required> <password:required> [curl_options:optional]\nExamples:\n req-auth GET https://api.example.com/secure user pass123\n req-auth POST https://api.example.com/secure user pass123 -d \"{your json data}\""
    return 1
  fi

  local method=$(echo "$1" | tr "[:lower:]" "[:upper:]")
  local url="$2"
  local username="$3"
  local password="$4"
  shift 4

  echo "Sending $method request to $url with Basic Authentication..."
  local response=$(curl -sS -X "$method" -u "$username:$password" "$url" "$@")
  local status=$?

  if [ $status -ne 0 ]; then
    _show_error_request_aliases "$method request with authentication failed. Check the URL, credentials, and your internet connection."
    return 1
  fi

  # Try to format as JSON if possible
  if echo "$response" | jq . >/dev/null 2>&1; then
    echo "$response" | jq .
  else
    echo "$response"
  fi
}' # Send HTTP request with Basic Authentication

alias req-token='() {
  if ! _check_command_request_aliases curl; then
    return 1
  fi

  if [ $# -lt 3 ]; then
    echo -e "Send HTTP request with Bearer Token Authentication.\nUsage:\n req-token <method:required> <url:required> <token:required> [curl_options:optional]\nExamples:\n req-token GET https://api.example.com/secure my_token_123\n req-token POST https://api.example.com/secure my_token_123 -d \"{your json data}\""
    return 1
  fi

  local method=$(echo "$1" | tr "[:lower:]" "[:upper:]")
  local url="$2"
  local token="$3"
  shift 3

  echo "Sending $method request to $url with Bearer Token..."
  local response=$(curl -sS -X "$method" -H "Authorization: Bearer $token" "$url" "$@")
  local status=$?

  if [ $status -ne 0 ]; then
    _show_error_request_aliases "$method request with token authentication failed. Check the URL, token, and your internet connection."
    return 1
  fi

  # Try to format as JSON if possible
  if echo "$response" | jq . >/dev/null 2>&1; then
    echo "$response" | jq .
  else
    echo "$response"
  fi
}' # Send HTTP request with Bearer Token Authentication

alias req-status='() {
  if ! _check_command_request_aliases curl; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo -e "Check HTTP status code of a URL.\nUsage:\n req-status <url:required> [curl_options:optional]\nExamples:\n req-status https://example.com\n req-status https://api.example.com -H \"Authorization: Bearer token\""
    return 1
  fi

  local url="$1"
  shift

  echo "Checking HTTP status for $url..."
  local status_code=$(curl -sS -o /dev/null -w "%{http_code}" "$url" "$@")
  local status=$?

  if [ $status -ne 0 ]; then
    _show_error_request_aliases "Failed to check HTTP status. Check the URL and your internet connection."
    return 1
  fi

  echo "HTTP Status: $status_code"

  # Interpret status code
  if [ "$status_code" -ge 200 ] && [ "$status_code" -lt 300 ]; then
    echo "Success (2xx)"
  elif [ "$status_code" -ge 300 ] && [ "$status_code" -lt 400 ]; then
    echo "Redirection (3xx)"
  elif [ "$status_code" -ge 400 ] && [ "$status_code" -lt 500 ]; then
    echo "Client Error (4xx)"
  elif [ "$status_code" -ge 500 ]; then
    echo "Server Error (5xx)"
  fi
}' # Check HTTP status code of a URL

alias req-time='() {
  if ! _check_command_request_aliases curl; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo -e "Measure response time of a URL.\nUsage:\n req-time <url:required> [curl_options:optional]\nExamples:\n req-time https://example.com\n req-time https://api.example.com -H \"Authorization: Bearer token\""
    return 1
  fi

  local url="$1"
  shift

  echo "Measuring response time for $url..."
  local result=$(curl -sS -o /dev/null -w "\nDNS Lookup: %{time_namelookup}s\nConnect: %{time_connect}s\nTLS Setup: %{time_appconnect}s\nPre-transfer: %{time_pretransfer}s\nRedirect: %{time_redirect}s\nStart Transfer: %{time_starttransfer}s\n\nTotal: %{time_total}s" "$url" "$@")
  local status=$?

  if [ $status -ne 0 ]; then
    _show_error_request_aliases "Failed to measure response time. Check the URL and your internet connection."
    return 1
  fi

  echo "$result"
}' # Measure response time of a URL

#===================================
# Help and Documentation
#===================================

alias req-help='() {
  local help_text="HTTP Request Aliases Help
Basic HTTP Methods:
  req-get    <url> [curl_options]                    - Send HTTP GET request
  req-post   <url> <json_data> [curl_options]        - Send HTTP POST request with JSON data
  req-put    <url> <json_data> [curl_options]        - Send HTTP PUT request with JSON data
  req-delete <url> [curl_options]                    - Send HTTP DELETE request
  req-patch  <url> <json_data> [curl_options]        - Send HTTP PATCH request with JSON data
  req-head   <url> [curl_options]                    - Get HTTP headers only

File Operations:
  req-upload-file   <url> <file_path> [field_name] [curl_options] - Upload a file
  req-download-file <url> <output_path> [curl_options]            - Download a file

API Testing and Utilities:
  req-json   <method> <url> [data] [curl_options]                      - Send request and format JSON response
  req-form   <url> <field1=value1> [field2=value2] [curl_options]     - Send form data
  req-auth   <method> <url> <username> <password> [curl_options]       - Basic Authentication
  req-token  <method> <url> <token> [curl_options]                     - Bearer Token Authentication
  req-status <url> [curl_options]                                      - Check HTTP status code
  req-time   <url> [curl_options]                                      - Measure response time"

  echo -e "$help_text"
}' # Show help for request aliases