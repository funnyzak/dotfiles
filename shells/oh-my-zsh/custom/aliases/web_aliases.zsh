# Description: Base aliases for web-related tasks and functions.

# Web Aliases
# ============================================================

# Function: Generate a QR code from a given string.
# Usage: qr "string to encode"
alias qr='() {
  if [ -z "$1" ]; then
    echo "Usage: qr \"string to encode\"" >&2
    return 1
  fi

  # Check if qrencode is installed
  if ! command -v qrencode &> /dev/null; then
    echo "Error: qrencode is not installed. Please install it using your system's package manager." >&2
    return 1
  fi

  qrencode -t UTF8 "$1"
}'

# Function: Start a simple HTTP server in the current directory.
# Usage: serve [port]
# Default port is 8000.
alias serve='() {
  local port="${1:-8000}"

  if ! [[ "$port" =~ ^[0-9]+$ ]]; then
    echo "Error: Invalid port number. Please provide a valid port number." >&2
    echo "Usage: serve [port]" >&2
    return 1
  fi

  # Check if python3 is installed
  if ! command -v python3 &> /dev/null; then
    echo "Error: python3 is not installed. Please install it using your system's package manager." >&2
    return 1
  fi

  python3 -m http.server "$port"
}'

# Function: Decode a base64 encoded string.
# Usage: b64decode "base64 encoded string"
alias b64decode='() {
  if [ -z "$1" ]; then
    echo "Usage: b64decode \"base64 encoded string\"" >&2
    return 1
  fi

  # Check if base64 is installed
  if ! command -v base64 &> /dev/null; then
    echo "Error: base64 is not installed. Please install it using your system's package manager." >&2
    return 1
  fi

  echo "$1" | base64 --decode
}'

# Function: Encode a string to base64.
# Usage: b64encode "string to encode"
alias b64encode='() {
  if [ -z "$1" ]; then
    echo "Usage: b64encode \"string to encode\"" >&2
    return 1
  fi

  # Check if base64 is installed
  if ! command -v base64 &> /dev/null; then
    echo "Error: base64 is not installed. Please install it using your system's package manager." >&2
    return 1
  fi

  echo "$1" | base64
}'