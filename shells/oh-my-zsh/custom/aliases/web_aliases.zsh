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

# ============================================
# IP and Network Utilities
# ============================================

alias myip='() {
  echo "Get your public IP address."
  echo "Usage:"
  echo "  myip"

  if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed." >&2
    return 1
  fi

  echo "Fetching public IP address..."
  local ip=$(curl -s https://api.ipify.org)
  if [ -z "$ip" ]; then
    echo "Error: Failed to retrieve public IP address." >&2
    return 1
  fi
  echo "Public IP: $ip"
}' # Get your public IP address

alias localip='() {
  echo "Get your local IP address."
  echo "Usage:"
  echo "  localip"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    local ip=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)
    if [ -z "$ip" ]; then
      echo "Error: Could not determine local IP address." >&2
      return 1
    fi
    echo "Local IP: $ip"
  else
    # Linux
    local ip=$(hostname -I 2>/dev/null | awk "{print \$1}")
    if [ -z "$ip" ]; then
      echo "Error: Could not determine local IP address." >&2
      return 1
    fi
    echo "Local IP: $ip"
  fi
}' # Get your local IP address

alias ports='() {
  echo "List all open ports and listening services."
  echo "Usage:"
  echo "  ports"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    echo "Open ports and listening services:"
    sudo lsof -iTCP -sTCP:LISTEN -n -P
  else
    # Linux
    if command -v netstat &> /dev/null; then
      netstat -tuln
    elif command -v ss &> /dev/null; then
      ss -tuln
    else
      echo "Error: Neither netstat nor ss is installed." >&2
      return 1
    fi
  fi
}' # List all open ports

alias whois-ip='() {
  echo "Get WHOIS information for an IP address or domain."
  echo "Usage:"
  echo "  whois-ip <ip_or_domain>"

  if [ -z "$1" ]; then
    echo "Error: No IP address or domain provided." >&2
    echo "Usage: whois-ip <ip_or_domain>" >&2
    return 1
  fi

  if ! command -v whois &> /dev/null; then
    echo "Error: whois is not installed." >&2
    echo "Install it using: brew install whois (macOS) or apt-get install whois (Linux)" >&2
    return 1
  fi

  whois "$1"
}' # Get WHOIS information

# ============================================
# HTTP Testing and Debugging
# ============================================

alias httpcode='() {
  echo "Get HTTP status code for a URL."
  echo "Usage:"
  echo "  httpcode <url>"

  if [ -z "$1" ]; then
    echo "Error: No URL provided." >&2
    echo "Usage: httpcode <url>" >&2
    return 1
  fi

  if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed." >&2
    return 1
  fi

  local code=$(curl -o /dev/null -s -w "%{http_code}" "$1")
  echo "HTTP Status Code: $code"
}' # Get HTTP status code

alias headers='() {
  echo "Get HTTP headers for a URL."
  echo "Usage:"
  echo "  headers <url>"

  if [ -z "$1" ]; then
    echo "Error: No URL provided." >&2
    echo "Usage: headers <url>" >&2
    return 1
  fi

  if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed." >&2
    return 1
  fi

  curl -I "$1"
}' # Get HTTP headers

alias curl-time='() {
  echo "Measure request timing for a URL."
  echo "Usage:"
  echo "  curl-time <url>"

  if [ -z "$1" ]; then
    echo "Error: No URL provided." >&2
    echo "Usage: curl-time <url>" >&2
    return 1
  fi

  if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed." >&2
    return 1
  fi

  curl -o /dev/null -s -w "DNS Lookup: %{time_namelookup}s\nTCP Connection: %{time_connect}s\nTLS Handshake: %{time_appconnect}s\nServer Processing: %{time_starttransfer}s\nTotal Time: %{time_total}s\n" "$1"
}' # Measure request timing

alias postjson='() {
  echo "POST JSON data to a URL."
  echo "Usage:"
  echo "  postjson <url> <json_data>"

  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Error: Missing arguments." >&2
    echo "Usage: postjson <url> <json_data>" >&2
    return 1
  fi

  if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed." >&2
    return 1
  fi

  curl -X POST -H "Content-Type: application/json" -d "$2" "$1"
}' # POST JSON data

# ============================================
# JSON and Data Utilities
# ============================================

alias jsonformat='() {
  echo "Format/prettify JSON data."
  echo "Usage:"
  echo "  jsonformat <json_string>"
  echo "  echo <json_string> | jsonformat"

  if [ -n "$1" ]; then
    echo "$1" | python3 -m json.tool
  else
    python3 -m json.tool
  fi
}' # Format JSON data

alias jsonminify='() {
  echo "Minify JSON data."
  echo "Usage:"
  echo "  jsonminify <json_string>"
  echo "  echo <json_string> | jsonminify"

  if [ -n "$1" ]; then
    echo "$1" | python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin),separators=(",",":")))"
  else
    python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin),separators=(",",":")))"
  fi
}' # Minify JSON data

alias jwtdecode='() {
  echo "Decode a JWT token (header and payload only)."
  echo "Usage:"
  echo "  jwtdecode <jwt_token>"

  if [ -z "$1" ]; then
    echo "Error: No JWT token provided." >&2
    echo "Usage: jwtdecode <jwt_token>" >&2
    return 1
  fi

  local header=$(echo "$1" | cut -d"." -f1 | base64 --decode 2>/dev/null)
  local payload=$(echo "$1" | cut -d"." -f2 | base64 --decode 2>/dev/null)
  
  echo "Header:"
  echo "$header" | python3 -m json.tool 2>/dev/null || echo "$header"
  echo ""
  echo "Payload:"
  echo "$payload" | python3 -m json.tool 2>/dev/null || echo "$payload"
}' # Decode JWT token

# ============================================
# SSL/TLS and Security
# ============================================

alias sslcheck='() {
  echo "Check SSL certificate for a domain."
  echo "Usage:"
  echo "  sslcheck <domain>"

  if [ -z "$1" ]; then
    echo "Error: No domain provided." >&2
    echo "Usage: sslcheck <domain>" >&2
    return 1
  fi

  if ! command -v openssl &> /dev/null; then
    echo "Error: openssl is not installed." >&2
    return 1
  fi

  echo | openssl s_client -servername "$1" -connect "$1:443" 2>/dev/null | openssl x509 -noout -text
}' # Check SSL certificate

alias sslexpiry='() {
  echo "Check SSL certificate expiry date."
  echo "Usage:"
  echo "  sslexpiry <domain>"

  if [ -z "$1" ]; then
    echo "Error: No domain provided." >&2
    echo "Usage: sslexpiry <domain>" >&2
    return 1
  fi

  if ! command -v openssl &> /dev/null; then
    echo "Error: openssl is not installed." >&2
    return 1
  fi

  echo | openssl s_client -servername "$1" -connect "$1:443" 2>/dev/null | openssl x509 -noout -dates
}' # Check SSL expiry

# ============================================
# DNS Utilities
# ============================================

alias dnsflush='() {
  echo "Flush DNS cache."
  echo "Usage:"
  echo "  dnsflush"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder
    echo "DNS cache flushed successfully."
  else
    # Linux
    if command -v systemd-resolve &> /dev/null; then
      sudo systemd-resolve --flush-caches
      echo "DNS cache flushed successfully."
    elif command -v nscd &> /dev/null; then
      sudo /etc/init.d/nscd restart
      echo "DNS cache flushed successfully."
    else
      echo "Error: Unable to flush DNS cache. No supported DNS service found." >&2
      return 1
    fi
  fi
}' # Flush DNS cache

alias digshort='() {
  echo "Quick DNS lookup (A records only)."
  echo "Usage:"
  echo "  digshort <domain>"

  if [ -z "$1" ]; then
    echo "Error: No domain provided." >&2
    echo "Usage: digshort <domain>" >&2
    return 1
  fi

  if ! command -v dig &> /dev/null; then
    echo "Error: dig is not installed." >&2
    return 1
  fi

  dig +short "$1"
}' # Quick DNS lookup

# ============================================
# Download and Web Scraping
# ============================================

alias wget-mirror='() {
  echo "Mirror a website for offline viewing."
  echo "Usage:"
  echo "  wget-mirror <url>"

  if [ -z "$1" ]; then
    echo "Error: No URL provided." >&2
    echo "Usage: wget-mirror <url>" >&2
    return 1
  fi

  if ! command -v wget &> /dev/null; then
    echo "Error: wget is not installed." >&2
    echo "Install it using: brew install wget (macOS) or apt-get install wget (Linux)" >&2
    return 1
  fi

  wget --mirror --convert-links --adjust-extension --page-requisites --no-parent "$1"
}' # Mirror a website

alias extract-links='() {
  echo "Extract all links from a webpage."
  echo "Usage:"
  echo "  extract-links <url>"

  if [ -z "$1" ]; then
    echo "Error: No URL provided." >&2
    echo "Usage: extract-links <url>" >&2
    return 1
  fi

  if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed." >&2
    return 1
  fi

  curl -s "$1" | grep -oE "href=\"[^\"]*\"" | sed "s/href=\"\([^\"]*\)\"/\1/" | sort -u
}' # Extract all links from a webpage

# ============================================
# Web Development Helpers
# ============================================

alias cors-test='() {
  echo "Test CORS headers for a URL."
  echo "Usage:"
  echo "  cors-test <url> [origin]"

  if [ -z "$1" ]; then
    echo "Error: No URL provided." >&2
    echo "Usage: cors-test <url> [origin]" >&2
    return 1
  fi

  if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed." >&2
    return 1
  fi

  local origin="${2:-https://example.com}"
  echo "Testing CORS with origin: $origin"
  curl -I -H "Origin: $origin" -H "Access-Control-Request-Method: GET" "$1"
}' # Test CORS headers

alias useragent='() {
  echo "Make a request with a custom user agent."
  echo "Usage:"
  echo "  useragent <url> <user_agent_string>"

  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Error: Missing arguments." >&2
    echo "Usage: useragent <url> <user_agent_string>" >&2
    echo "Example: useragent https://example.com \"Mozilla/5.0\"" >&2
    return 1
  fi

  if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed." >&2
    return 1
  fi

  curl -A "$2" "$1"
}' # Request with custom user agent

alias webping='() {
  echo "Continuously ping a web server (HTTP)."
  echo "Usage:"
  echo "  webping <url> [interval_seconds]"

  if [ -z "$1" ]; then
    echo "Error: No URL provided." >&2
    echo "Usage: webping <url> [interval_seconds]" >&2
    return 1
  fi

  if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed." >&2
    return 1
  fi

  local interval="${2:-5}"
  echo "Pinging $1 every $interval seconds (Ctrl+C to stop)..."
  
  while true; do
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local code=$(curl -o /dev/null -s -w "%{http_code}" --max-time 10 "$1")
    local time=$(curl -o /dev/null -s -w "%{time_total}" --max-time 10 "$1")
    echo "[$timestamp] HTTP $code - ${time}s"
    sleep "$interval"
  done
}' # Continuously ping web server


alias web-help='() {
  echo "Web-related aliases and functions:"
  echo ""
  echo "📡 IP and Network Utilities:"
  echo "  myip                Get your public IP address"
  echo "  localip             Get your local IP address"
  echo "  ports               List all open ports and listening services"
  echo "  whois-ip <domain>   Get WHOIS information for an IP or domain"
  echo ""
  echo "🌐 HTTP Testing and Debugging:"
  echo "  httpcode <url>      Get HTTP status code for a URL"
  echo "  headers <url>       Get HTTP headers for a URL"
  echo "  curl-time <url>     Measure request timing for a URL"
  echo "  postjson <url> <json> POST JSON data to a URL"
  echo "  cors-test <url> [origin] Test CORS headers"
  echo "  useragent <url> <ua> Make request with custom user agent"
  echo "  webping <url> [sec] Continuously ping a web server"
  echo ""
  echo "🔐 SSL/TLS and Security:"
  echo "  sslcheck <domain>   Check SSL certificate for a domain"
  echo "  sslexpiry <domain>  Check SSL certificate expiry date"
  echo ""
  echo "🗂️  JSON and Data Utilities:"
  echo "  jsonformat [json]   Format/prettify JSON data"
  echo "  jsonminify [json]   Minify JSON data"
  echo "  jwtdecode <token>   Decode a JWT token (header and payload)"
  echo ""
  echo "🔤 Encoding/Decoding:"
  echo "  qr <string>         Generate a QR code from a string"
  echo "  qrdecode <file>     Decode a QR code from an image file"
  echo "  urlencode <string>  Encode a string to URL format"
  echo "  urldecode <string>  Decode a URL encoded string"
  echo "  b64encode <string>  Encode a string to base64"
  echo "  b64decode <string>  Decode a base64 encoded string"
  echo "  b64urlencode <str>  Encode a string to base64 URL format"
  echo ""
  echo "🌍 DNS Utilities:"
  echo "  dnsflush            Flush DNS cache"
  echo "  digshort <domain>   Quick DNS lookup (A records only)"
  echo ""
  echo "📥 Download and Web Scraping:"
  echo "  wget-mirror <url>   Mirror a website for offline viewing"
  echo "  extract-links <url> Extract all links from a webpage"
  echo ""
  echo "🛠️  Web Development:"
  echo "  http-server [port]  Start a simple HTTP server (default: 8080)"
  echo "  speedtest           Test internet connection speed"
}' # Display help for web-related aliases and functions
