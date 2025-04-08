# Description: Web related aliases for common web tasks and utilities

alias qr='() {
  echo "Generate QR code from a string."
  echo "Usage:"
  echo "  qr <string_to_encode>"

  if [ -z "$1" ]; then
    echo "Error: No input string provided." >&2
    echo "Usage: qr <string_to_encode>" >&2
    return 1
  fi

  # Check if qrencode is installed
  if ! command -v qrencode &> /dev/null; then
    echo "Error: qrencode is not installed." >&2
    echo "Please install it using your system package manager:" >&2
    echo "  - macOS: brew install qrencode" >&2
    echo "  - Ubuntu/Debian: sudo apt-get install qrencode" >&2
    return 1
  fi

  qrencode -t UTF8 "$1"
}' # Generate QR code from a string

alias qrdecode='() {
  echo "Decode a QR code from an image file."
  echo "Usage:"
  echo "  qrdecode <image_file>"

  if [ -z "$1" ]; then
    echo "Error: No input image file provided." >&2
    echo "Usage: qrdecode <image_file>" >&2
    return 1
  fi

  # Check if zbarimg is installed
  if ! command -v zbarimg &> /dev/null; then
    echo "Error: zbarimg is not installed." >&2
    echo "Please install it using your system package manager:" >&2
    echo "  - macOS: brew install zbar" >&2
    echo "  - Ubuntu/Debian: sudo apt-get install zbar-tools" >&2
    return 1
  fi

  zbarimg "$1"
}' # Decode a QR code from an image file

alias urlencode='() {
  echo "Encode a string to URL format."
  echo "Usage:"
  echo "  urlencode <string_to_encode>"

  if [ -z "$1" ]; then
    echo "Error: No input string provided." >&2
    echo "Usage: urlencode <string_to_encode>" >&2
    return 1
  fi

  # Check if curl is installed
  if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed." >&2
    echo "Please install it using your system package manager:" >&2
    echo "  - macOS: brew install curl" >&2
    echo "  - Ubuntu/Debian: sudo apt-get install curl" >&2
    return 1
  fi

  # Encode the string using curl"s URL encoding feature
  local encoded_string=$(curl -s -G --data-urlencode "$1" "" | sed "s/.*=//")
  echo "$encoded_string"
}' # Encode a string to URL format

alias urldecode='() {
  echo "Decode a URL encoded string."
  echo "Usage:"
  echo "  urldecode <url_encoded_string>"

  if [ -z "$1" ]; then
    echo "Error: No input string provided." >&2
    echo "Usage: urldecode <url_encoded_string>" >&2
    return 1
  fi

  # Check if curl is installed
  if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed." >&2
    echo "Please install it using your system package manager:" >&2
    echo "  - macOS: brew install curl" >&2
    echo "  - Ubuntu/Debian: sudo apt-get install curl" >&2
    return 1
  fi

  # Decode the string using curl"s URL decoding feature
  local decoded_string=$(echo "$1" | sed "s/%/\\x/g" | xargs -0 printf "%b")
  echo "$decoded_string"
}' # Decode a URL encoded string

alias b64urlencode='() {
  echo "Encode a string to base64 URL format."
  echo "Usage:"
  echo "  b64urlencode <string_to_encode>"

  if [ -z "$1" ]; then
    echo "Error: No input string provided." >&2
    echo "Usage: b64urlencode <string_to_encode>" >&2
    return 1
  fi

  # Check if base64 is installed
  if ! command -v base64 &> /dev/null; then
    echo "Error: base64 command not found." >&2
    echo "It should be available by default on most systems." >&2
    return 1
  fi

  # Encode the string to base64 and replace '+' with '-' and '/' with '_'
  local encoded_string=$(echo -n "$1" | base64 | tr '+/' '-_' | tr -d '=')
  echo "$encoded_string"
}' # Encode a string to base64 URL format

alias b64decode='() {
  echo "Decode a base64 encoded string."
  echo "Usage:"
  echo "  b64decode <base64_encoded_string>"

  if [ -z "$1" ]; then
    echo "Error: No input string provided." >&2
    echo "Usage: b64decode <base64_encoded_string>" >&2
    return 1
  fi

  # Check if base64 is installed
  if ! command -v base64 &> /dev/null; then
    echo "Error: base64 command not found." >&2
    echo "It should be available by default on most systems." >&2
    return 1
  fi

  echo "$1" | base64 --decode
}' # Decode a base64 encoded string

alias b64encode='() {
  echo "Encode a string to base64."
  echo "Usage:"
  echo "  b64encode <string_to_encode>"

  if [ -z "$1" ]; then
    echo "Error: No input string provided." >&2
    echo "Usage: b64encode <string_to_encode>" >&2
    return 1
  fi

  # Check if base64 is installed
  if ! command -v base64 &> /dev/null; then
    echo "Error: base64 command not found." >&2
    echo "It should be available by default on most systems." >&2
    return 1
  fi

  echo "$1" | base64
}' # Encode a string to base64

alias speedtest='() {
  echo "Test internet connection speed."
  echo "Usage:"
  echo "  speedtest"

  # Check for required tools
  if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed." >&2
    echo "Please install curl using your system package manager:" >&2
    echo "  - macOS: brew install curl" >&2
    echo "  - Ubuntu/Debian: sudo apt-get install curl" >&2
    return 1
  fi

  if command -v speedtest-cli &> /dev/null; then
    echo "Running internet speed test using speedtest-cli..."
    speedtest-cli
    return $?
  elif command -v python3 &> /dev/null; then
    echo "Running internet speed test using speedtest-cli script with Python 3..."
    curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -
    return $?
  elif command -v python &> /dev/null; then
    echo "Running internet speed test using speedtest-cli script with Python..."
    curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -
    return $?
  else
    echo "Error: Neither speedtest-cli nor python is installed." >&2
    echo "Please install either:" >&2
    echo "  - speedtest-cli: pip install speedtest-cli" >&2
    echo "  - python: using your system package manager" >&2
    return 1
  fi
}' # Test internet connection speed

alias http-server='() {
  echo "Start a simple HTTP server on specified port."
  echo "Usage:"
  echo "  http-server [port:8080]"

  local port="${1:-8080}"

  # Validate port number
  if ! [[ "$port" =~ ^[0-9]+$ ]]; then
    echo "Error: Invalid port number: $port" >&2
    echo "Port must be a positive number." >&2
    return 1
  fi

  if [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    echo "Error: Port number out of range: $port" >&2
    echo "Port must be between 1 and 65535." >&2
    return 1
  fi

  echo "Starting HTTP server on http://localhost:$port"

  # Try different methods to start an HTTP server
  if command -v python3 &> /dev/null; then
    python3 -m http.server "$port"
    local status=$?
    if [ $status -ne 0 ]; then
      echo "Error: Failed to start HTTP server with python3." >&2
      return $status
    fi
  elif command -v python &> /dev/null; then
    # Try Python 3 module first, fall back to Python 2 if needed
    python -m http.server "$port" 2>/dev/null || python -m SimpleHTTPServer "$port"
    local status=$?
    if [ $status -ne 0 ]; then
      echo "Error: Failed to start HTTP server with python." >&2
      return $status
    fi
  elif command -v npx &> /dev/null; then
    echo "Using Node.js http-server..."
    npx http-server -p "$port"
    local status=$?
    if [ $status -ne 0 ]; then
      echo "Error: Failed to start HTTP server with npx." >&2
      return $status
    fi
  else
    echo "Error: No suitable HTTP server found." >&2
    echo "Please install one of the following:" >&2
    echo "  - Python: using your system package manager" >&2
    echo "  - Node.js http-server: npm install -g http-server" >&2
    return 1
  fi
}' # Start a simple HTTP server


alias web-help='() {
  echo "Web-related aliases and functions:"
  echo "  qr <string>         Generate a QR code from a string"
  echo "  qrdecode <file>     Decode a QR code from an image file"
  echo "  urlencode <string>   Encode a string to URL format"
  echo "  urldecode <string>   Decode a URL encoded string"
  echo "  b64urlencode <string> Encode a string to base64 URL format"
  echo "  b64decode <string>   Decode a base64 encoded string"
  echo "  b64encode <string>   Encode a string to base64"
  echo "  speedtest           Test internet connection speed"
  echo "  http-server [port]  Start a simple HTTP server on specified port (default: 8080)"
}' # Display help for web-related aliases and functions
