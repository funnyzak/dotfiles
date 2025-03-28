# Description: Some url services and functions for URL shortening, validation, and more.

#===================================
# URL shortening services
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

# Generate short URL using YOURLS
alias url_shorten_yourls='() {
  if ! _network_check_command curl && ! _network_check_command jq; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Generate short URL using YOURLS.\nUsage:\n url_shorten_yourls <url>"
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
  curl -X POST "$YOURLS_BASE_URL/yourls-api.php" --data "format=json&signature=$YOURLS_TOKEN&action=shorturl&url=$1" | jq .
}' # Generate short URL using YOURLS

# Generate short URL using sink
alias url_shorten_sink='() {
  if [ $# -eq 0 ]; then
    echo "Generate short URL using sink.\nUsage: url_shorten_sink <url> [custom_code]"
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
alias url_shorten_tinyurl='() {
  if ! _network_check_command curl; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Generate short URL using TinyURL.\nUsage:\n url_shorten_tinyurl <url>"
    return 1
  fi

  if ! _url_validate_url "$1"; then
    return 1
  fi

  echo "Generating short URL for $1..."
  curl -s "http://tinyurl.com/api-create.php?url=$1"
}' # Generate short URL using TinyURL

# Generate short URL using Bitly
alias url_shorten_bitly='() {
  if ! _network_check_command curl && ! _network_check_command jq; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Generate short URL using Bitly.\nUsage:\n url_shorten_bitly <url>"
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
  curl -X POST "https://api-ssl.bitly.com/v4/shorten" \
    -H "Authorization: Bearer $BITLY_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"long_url\": \"$1\"}" | jq .
}' # Generate short URL using Bitly

# Generate short URL using is.gd
alias url_shorten_isgd='() {
  if ! _network_check_command curl; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Generate short URL using is.gd.\nUsage:\n url_shorten_isgd <url>"
    return 1
  fi

  if ! _url_validate_url "$1"; then
    return 1
  fi

  echo "Generating short URL for $1..."
  curl -s "https://is.gd/create.php?format=simple&url=$1"
}' # Generate short URL using is.gd

# Generate short URL using v.gd
alias url_shorten_vgd='() {
  if ! _network_check_command curl; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Generate short URL using v.gd.\nUsage:\n url_shorten_vgd <url>"
    return 1
  fi

  if ! _url_validate_url "$1"; then
    return 1
  fi

  echo "Generating short URL for $1..."
  curl -s "https://v.gd/create.php?format=simple&url=$1"
}' # Generate short URL using v.gd

# Generate short URL using shrtcode
alias url_shorten_shrtcode='() {
  if ! _network_check_command curl; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Generate short URL using shrtcode.\nUsage:\n url_shorten_shrtcode <url>"
    return 1
  fi

  if ! _url_validate_url "$1"; then
    return 1
  fi

  echo "Generating short URL for $1..."
  curl -s "https://shrtco.de/api/v2/shorten?url=$1" | jq .
}' # Generate short URL using shrtcode

# Generate short URL using T2M
alias url_shorten_t2m='() {
  if ! _network_check_command curl && ! _network_check_command jq; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Generate short URL using T2M.\nUsage:\n url_shorten_t2m <url>"
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
  curl -X POST "https://t2m.io/api/v1/shorten" \
    -H "Authorization: Bearer $T2M_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"long_url\": \"$1\"}" | jq .
}' # Generate short URL using T2M

# Generate short URL using Rebrandly
alias url_shorten_rebrandly='() {
  if ! _network_check_command curl && ! _network_check_command jq; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Generate short URL using Rebrandly.\nUsage:\n url_shorten_rebrandly <url>"
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
  curl -X POST "https://api.rebrandly.com/v1/links" \
    -H "Content-Type: application/json" \
    -H "apikey: $REBRANDLY_API_KEY" \
    -d "{\"destination\": \"$1\"}" | jq .
}' # Generate short URL using Rebrandly
