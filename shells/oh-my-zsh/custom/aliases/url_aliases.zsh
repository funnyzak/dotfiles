# Description: URL services and functions for URL shortening, validation, encoding/decoding and analysis

#===================================
# URL utilities and helpers
#===================================

# Helper function for URL validation
_url_validate_url() {
  if [[ "$1" =~ ^https?:// ]]; then
    return 0
  else
    echo "Error: URL must start with http:// or https://" >&2
    return 1
  fi
}

# Helper function for checking required commands
_url_check_command() {
  if ! command -v "$1" &>/dev/null; then
    echo "Error: Required command '$1' not found. Please install it first." >&2
    return 1
  fi
  return 0
}

# Helper function to check network connectivity
_url_check_connectivity() {
  local test_url="${1:-https://www.google.com}"
  if ! curl --silent --head --fail "$test_url" >/dev/null 2>&1; then
    echo "Error: Network connectivity issue. Cannot connect to $test_url" >&2
    return 1
  fi
  return 0
}

#===================================
# URL shortening services
#===================================

# Generate short URL using YOURLS
alias url-shorten-yourls='() {
  echo "Generate short URL using YOURLS.
Usage:
 url-shorten-yourls <url>"
  
  if [ $# -eq 0 ]; then
    return 1
  fi
  
  if ! _url_check_command "curl" || ! _url_check_command "jq"; then
    return 1
  fi

  if [ -z "$YOURLS_BASE_URL" ] || [ -z "$YOURLS_TOKEN" ]; then
    echo "Error: YOURLS_BASE_URL and YOURLS_TOKEN environment variables must be set." >&2
    return 1
  fi

  if ! _url_validate_url "$1"; then
    return 1
  fi

  echo "Generating short URL for $1..."
  if ! _url_check_connectivity "$YOURLS_BASE_URL"; then
    return 1
  fi
  
  curl -X POST "$YOURLS_BASE_URL/yourls-api.php" --data "format=json&signature=$YOURLS_TOKEN&action=shorturl&url=$1" | jq .
}' # Generate short URL using YOURLS

# Generate short URL using sink
alias url-shorten-sink='() {
  echo "Generate short URL using sink.
Usage:
 url-shorten-sink <url> [custom_code]"
  
  if [ $# -eq 0 ]; then
    return 1
  fi

  if [ -z "$SINK_BASE_URL" ] || [ -z "$SINK_TOKEN" ]; then
    echo "Error: SINK_BASE_URL and SINK_TOKEN environment variables must be set." >&2
    return 1
  fi

  if ! _url_validate_url "$1"; then
    return 1
  fi

  echo "Generating short URL for $1..."
  shorten_url_by_sink "$SINK_BASE_URL" "$SINK_TOKEN" "$@"
}' # Generate short URL using sink

# Generate short URL using TinyURL
alias url-shorten-tinyurl='() {
  echo "Generate short URL using TinyURL.
Usage:
 url-shorten-tinyurl <url>"
  
  if [ $# -eq 0 ]; then
    return 1
  fi

  if ! _url_check_command "curl"; then
    return 1
  fi

  if ! _url_validate_url "$1"; then
    return 1
  fi

  echo "Generating short URL for $1..."
  if ! _url_check_connectivity "https://tinyurl.com"; then
    return 1
  fi
  
  local result=$(curl -s "https://tinyurl.com/api-create.php?url=$1")
  if [ -z "$result" ]; then
    echo "Error: Failed to generate short URL" >&2
    return 1
  fi
  echo "$result"
}' # Generate short URL using TinyURL

# Generate short URL using Bitly
alias url-shorten-bitly='() {
  echo "Generate short URL using Bitly.
Usage:
 url-shorten-bitly <url>"
  
  if [ $# -eq 0 ]; then
    return 1
  fi

  if ! _url_check_command "curl" || ! _url_check_command "jq"; then
    return 1
  fi

  if [ -z "$BITLY_TOKEN" ]; then
    echo "Error: BITLY_TOKEN environment variable must be set." >&2
    return 1
  fi

  if ! _url_validate_url "$1"; then
    return 1
  fi

  echo "Generating short URL for $1..."
  if ! _url_check_connectivity "https://api-ssl.bitly.com"; then
    return 1
  fi
  
  curl -X POST "https://api-ssl.bitly.com/v4/shorten" \
    -H "Authorization: Bearer $BITLY_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"long_url\": \"$1\"}" | jq .
}' # Generate short URL using Bitly

# Generate short URL using is.gd
alias url-shorten-isgd='() {
  echo "Generate short URL using is.gd.
Usage:
 url-shorten-isgd <url>"
  
  if [ $# -eq 0 ]; then
    return 1
  fi

  if ! _url_check_command "curl"; then
    return 1
  fi

  if ! _url_validate_url "$1"; then
    return 1
  fi

  echo "Generating short URL for $1..."
  if ! _url_check_connectivity "https://is.gd"; then
    return 1
  fi
  
  local result=$(curl -s "https://is.gd/create.php?format=simple&url=$1")
  if [ -z "$result" ] || [[ "$result" == *"Error"* ]]; then
    echo "Error: Failed to generate short URL" >&2
    return 1
  fi
  echo "$result"
}' # Generate short URL using is.gd

# Generate short URL using v.gd
alias url-shorten-vgd='() {
  echo "Generate short URL using v.gd.
Usage:
 url-shorten-vgd <url>"
  
  if [ $# -eq 0 ]; then
    return 1
  fi

  if ! _url_check_command "curl"; then
    return 1
  fi

  if ! _url_validate_url "$1"; then
    return 1
  fi

  echo "Generating short URL for $1..."
  if ! _url_check_connectivity "https://v.gd"; then
    return 1
  fi
  
  local result=$(curl -s "https://v.gd/create.php?format=simple&url=$1")
  if [ -z "$result" ] || [[ "$result" == *"Error"* ]]; then
    echo "Error: Failed to generate short URL" >&2
    return 1
  fi
  echo "$result"
}' # Generate short URL using v.gd

# Generate short URL using shrtco.de
alias url-shorten-shrtcode='() {
  echo "Generate short URL using shrtco.de.
Usage:
 url-shorten-shrtcode <url>"
  
  if [ $# -eq 0 ]; then
    return 1
  fi

  if ! _url_check_command "curl" || ! _url_check_command "jq"; then
    return 1
  fi

  if ! _url_validate_url "$1"; then
    return 1
  fi

  echo "Generating short URL for $1..."
  if ! _url_check_connectivity "https://api.shrtco.de"; then
    return 1
  fi
  
  curl -s "https://api.shrtco.de/v2/shorten?url=$1" | jq .
}' # Generate short URL using shrtco.de

# Generate short URL using T2M
alias url-shorten-t2m='() {
  echo "Generate short URL using T2M.
Usage:
 url-shorten-t2m <url>"
  
  if [ $# -eq 0 ]; then
    return 1
  fi

  if ! _url_check_command "curl" || ! _url_check_command "jq"; then
    return 1
  fi

  if [ -z "$T2M_API_KEY" ]; then
    echo "Error: T2M_API_KEY environment variable must be set." >&2
    return 1
  fi

  if ! _url_validate_url "$1"; then
    return 1
  fi

  echo "Generating short URL for $1..."
  if ! _url_check_connectivity "https://t2m.io"; then
    return 1
  fi
  
  curl -X POST "https://t2m.io/api/v1/shorten" \
    -H "Authorization: Bearer $T2M_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"long_url\": \"$1\"}" | jq .
}' # Generate short URL using T2M

# Generate short URL using Rebrandly
alias url-shorten-rebrandly='() {
  echo "Generate short URL using Rebrandly.
Usage:
 url-shorten-rebrandly <url>"
  
  if [ $# -eq 0 ]; then
    return 1
  fi

  if ! _url_check_command "curl" || ! _url_check_command "jq"; then
    return 1
  fi

  if [ -z "$REBRANDLY_API_KEY" ]; then
    echo "Error: REBRANDLY_API_KEY environment variable must be set." >&2
    return 1
  fi

  if ! _url_validate_url "$1"; then
    return 1
  fi

  echo "Generating short URL for $1..."
  if ! _url_check_connectivity "https://api.rebrandly.com"; then
    return 1
  fi
  
  curl -X POST "https://api.rebrandly.com/v1/links" \
    -H "Content-Type: application/json" \
    -H "apikey: $REBRANDLY_API_KEY" \
    -d "{\"destination\": \"$1\"}" | jq .
}' # Generate short URL using Rebrandly

#===================================
# URL encoding/decoding
#===================================

# URL encode a string
alias url-encode='() {
  echo "URL encode a string.
Usage:
 url-encode <text>"
  
  if [ $# -eq 0 ]; then
    return 1
  fi

  if ! _url_check_command "python3"; then
    echo "Error: python3 is required for URL encoding" >&2
    return 1
  fi
  
  python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))" "$1"
}' # URL encode a string

# URL decode a string
alias url-decode='() {
  echo "URL decode a string.
Usage:
 url-decode <encoded_text>"
  
  if [ $# -eq 0 ]; then
    return 1
  fi

  if ! _url_check_command "python3"; then
    echo "Error: python3 is required for URL decoding" >&2
    return 1
  fi
  
  python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.argv[1]))" "$1"
}' # URL decode a string

#===================================
# URL analysis and tools
#===================================

# Extract domain from URL
alias url-extract-domain='() {
  echo "Extract domain from URL.
Usage:
 url-extract-domain <url>"
  
  if [ $# -eq 0 ]; then
    return 1
  fi

  if ! _url_validate_url "$1"; then
    return 1
  fi
  
  python3 -c "import sys, urllib.parse; print(urllib.parse.urlparse(sys.argv[1]).netloc)" "$1"
}' # Extract domain from URL

# Get URL status code
alias url-status='() {
  echo "Check HTTP status code of a URL.
Usage:
 url-status <url>"
  
  if [ $# -eq 0 ]; then
    return 1
  fi

  if ! _url_check_command "curl"; then
    return 1
  fi

  if ! _url_validate_url "$1"; then
    return 1
  fi
  
  local status=$(curl -s -o /dev/null -w "%{http_code}" "$1")
  echo "HTTP Status code for $1: $status"
}' # Check HTTP status code of a URL

# Check if URL is accessible
alias url-check='() {
  echo "Check if a URL is accessible.
Usage:
 url-check <url>"
  
  if [ $# -eq 0 ]; then
    return 1
  fi

  if ! _url_check_command "curl"; then
    return 1
  fi

  if ! _url_validate_url "$1"; then
    return 1
  fi
  
  if curl --silent --head --fail "$1" >/dev/null; then
    echo "✅ URL is accessible: $1"
    return 0
  else
    echo "❌ URL is not accessible: $1"
    return 1
  fi
}' # Check if URL is accessible

# Get URL headers
alias url-headers='() {
  echo "Get HTTP headers of a URL.
Usage:
 url-headers <url>"
  
  if [ $# -eq 0 ]; then
    return 1
  fi

  if ! _url_check_command "curl"; then
    return 1
  fi

  if ! _url_validate_url "$1"; then
    return 1
  fi
  
  curl -s -I "$1"
}' # Get HTTP headers of a URL

# Open URL in default browser
alias url-open='() {
  echo "Open URL in default browser.
Usage:
 url-open <url>"
  
  if [ $# -eq 0 ]; then
    return 1
  fi

  if ! _url_validate_url "$1"; then
    return 1
  fi
  
  if [[ "$OSTYPE" == "darwin"* ]]; then
    open "$1"
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v xdg-open &>/dev/null; then
      xdg-open "$1"
    else
      echo "Error: Could not determine how to open URLs on this system" >&2
      return 1
    fi
  else
    echo "Error: Unsupported operating system" >&2
    return 1
  fi
}' # Open URL in default browser

# Get QR code for URL
alias url-to-qr='() {
  echo "Generate QR code for URL.
Usage:
 url-to-qr <url> [size:300]"
  
  if [ $# -eq 0 ]; then
    return 1
  fi

  if ! _url_validate_url "$1"; then
    return 1
  fi
  
  local url="$1"
  local size="${2:-300}"
  
  if ! _url_check_connectivity "https://api.qrserver.com"; then
    return 1
  fi
  
  local qr_url="https://api.qrserver.com/v1/create-qr-code/?size=${size}x${size}&data=${url}"
  
  echo "QR code URL: $qr_url"
  
  if [[ "$OSTYPE" == "darwin"* ]]; then
    open "$qr_url"
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v xdg-open &>/dev/null; then
      xdg-open "$qr_url"
    else
      echo "QR code generated but cannot open automatically on this system"
      echo "Visit: $qr_url"
    fi
  else
    echo "QR code generated but cannot open automatically on this system"
    echo "Visit: $qr_url"
  fi
}' # Generate QR code for URL

#===================================
# URL help function
#===================================

# Show help for URL aliases
alias url-help='() {
  echo "URL Aliases Help"
  echo "================="
  echo ""
  echo "URL Shortening:"
  echo "  url-shorten-tinyurl <url>     - Shorten URL using TinyURL"
  echo "  url-shorten-bitly <url>       - Shorten URL using Bitly (requires BITLY_TOKEN)"
  echo "  url-shorten-isgd <url>        - Shorten URL using is.gd"
  echo "  url-shorten-vgd <url>         - Shorten URL using v.gd"
  echo "  url-shorten-shrtcode <url>    - Shorten URL using shrtco.de"
  echo "  url-shorten-yourls <url>      - Shorten URL using YOURLS (requires YOURLS_BASE_URL and YOURLS_TOKEN)"
  echo "  url-shorten-t2m <url>         - Shorten URL using T2M (requires T2M_API_KEY)"
  echo "  url-shorten-rebrandly <url>   - Shorten URL using Rebrandly (requires REBRANDLY_API_KEY)"
  echo "  url-shorten-sink <url>        - Shorten URL using sink (requires SINK_BASE_URL and SINK_TOKEN)"
  echo ""
  echo "URL Encoding/Decoding:"
  echo "  url-encode <text>             - URL encode a string"
  echo "  url-decode <encoded_text>     - URL decode a string"
  echo ""
  echo "URL Analysis and Tools:"
  echo "  url-extract-domain <url>      - Extract domain from URL"
  echo "  url-status <url>              - Check HTTP status code of a URL"
  echo "  url-check <url>               - Check if URL is accessible"
  echo "  url-headers <url>             - Get HTTP headers of a URL"
  echo "  url-open <url>                - Open URL in default browser"
  echo "  url-to-qr <url> [size:300]    - Generate QR code for URL"
}' # Show help for URL aliases
