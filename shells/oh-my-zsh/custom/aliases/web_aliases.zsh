# Description: Web utilities for HTTP checks, encoding, QR, DNS, SSL, local serving and related diagnostics. Use `web-help` for more information.

# Helper functions for web aliases
_show_error_web_aliases() {
  echo "$1" >&2
  return 1
}

_show_usage_web_aliases() {
  echo -e "$1"
  return 0
}

_maybe_show_help_web_aliases() {
  local arg_value="$1"
  local usage_text="$2"

  if [ "$arg_value" = "-h" ] || [ "$arg_value" = "--help" ]; then
    _show_usage_web_aliases "$usage_text"
    return 0
  fi

  return 1
}

_check_command_web_aliases() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    _show_error_web_aliases "Error: Required command \"$command_name\" not found. Please install it first."
    return 1
  fi

  return 0
}

_validate_positive_integer_web_aliases() {
  local value_text="$1"
  local label_text="${2:-value}"

  case "$value_text" in
    ""|*[!0-9]*)
      _show_error_web_aliases "Error: $label_text must be a positive integer."
      return 1
      ;;
  esac

  if [ "$value_text" -le 0 ]; then
    _show_error_web_aliases "Error: $label_text must be greater than 0."
    return 1
  fi

  return 0
}

_validate_port_web_aliases() {
  local port_value="$1"

  if ! _validate_positive_integer_web_aliases "$port_value" "Port"; then
    return 1
  fi

  if [ "$port_value" -gt 65535 ]; then
    _show_error_web_aliases "Error: Port must be between 1 and 65535."
    return 1
  fi

  return 0
}

_validate_url_web_aliases() {
  local url_value="$1"

  case "$url_value" in
    http://*|https://*)
      return 0
      ;;
    *)
      _show_error_web_aliases "Error: URL must start with http:// or https://"
      return 1
      ;;
  esac
}

_read_input_web_aliases() {
  if [ $# -gt 0 ]; then
    printf "%s" "$*"
    return 0
  fi

  if [ ! -t 0 ]; then
    cat
    return 0
  fi

  return 1
}

_is_json_web_aliases() {
  local json_input="$1"

  if command -v jq >/dev/null 2>&1; then
    printf "%s" "$json_input" | jq . >/dev/null 2>&1
    return $?
  fi

  if command -v python3 >/dev/null 2>&1; then
    printf "%s" "$json_input" | python3 -m json.tool >/dev/null 2>&1
    return $?
  fi

  return 1
}

_validate_json_web_aliases() {
  local json_input="$1"

  if _is_json_web_aliases "$json_input"; then
    return 0
  fi

  _show_error_web_aliases "Error: Invalid JSON payload."
  return 1
}

_format_json_web_aliases() {
  local json_input="$1"

  if command -v jq >/dev/null 2>&1; then
    printf "%s" "$json_input" | jq .
    return $?
  fi

  if command -v python3 >/dev/null 2>&1; then
    printf "%s" "$json_input" | python3 -m json.tool
    return $?
  fi

  _show_error_web_aliases "Error: JSON formatting requires jq or python3."
  return 1
}

_minify_json_web_aliases() {
  local json_input="$1"

  if command -v jq >/dev/null 2>&1; then
    printf "%s" "$json_input" | jq -c .
    return $?
  fi

  if command -v python3 >/dev/null 2>&1; then
    printf "%s" "$json_input" | python3 -c "import json, sys; print(json.dumps(json.load(sys.stdin), separators=(\",\", \":\")))"
    return $?
  fi

  _show_error_web_aliases "Error: JSON minify requires jq or python3."
  return 1
}

_print_response_web_aliases() {
  local response_body="$1"

  if _is_json_web_aliases "$response_body"; then
    _format_json_web_aliases "$response_body"
    return $?
  fi

  printf "%s\n" "$response_body"
  return 0
}

_decode_base64_web_aliases() {
  local encoded_value="$1"

  if printf "%s" "$encoded_value" | base64 --decode >/dev/null 2>&1; then
    printf "%s" "$encoded_value" | base64 --decode
    return $?
  fi

  if printf "%s" "$encoded_value" | base64 -D >/dev/null 2>&1; then
    printf "%s" "$encoded_value" | base64 -D
    return $?
  fi

  if command -v python3 >/dev/null 2>&1; then
    python3 -c "import base64, sys
data = sys.argv[1].strip()
padding = \"=\" * (-len(data) % 4)
for decoder in (base64.b64decode, base64.urlsafe_b64decode):
    try:
        sys.stdout.write(decoder((data + padding).encode()).decode(\"utf-8\", \"replace\"))
        raise SystemExit(0)
    except Exception:
        pass
raise SystemExit(1)" "$encoded_value"
    return $?
  fi

  _show_error_web_aliases "Error: Failed to decode base64 data."
  return 1
}

_encode_base64url_web_aliases() {
  local raw_value="$1"

  if command -v python3 >/dev/null 2>&1; then
    python3 -c "import base64, sys; sys.stdout.write(base64.urlsafe_b64encode(sys.argv[1].encode()).decode().rstrip(\"=\"))" "$raw_value"
    return $?
  fi

  printf "%s" "$raw_value" | base64 | tr -d "\r\n=" | tr "+/" "-_"
  return $?
}

_encode_url_web_aliases() {
  local raw_value="$1"

  if command -v python3 >/dev/null 2>&1; then
    python3 -c "import sys, urllib.parse; sys.stdout.write(urllib.parse.quote(sys.argv[1], safe=\"\"))" "$raw_value"
    return $?
  fi

  if command -v perl >/dev/null 2>&1; then
    perl -MURI::Escape -e "print uri_escape(\$ARGV[0])" "$raw_value"
    return $?
  fi

  _show_error_web_aliases "Error: URL encoding requires python3 or perl."
  return 1
}

_decode_url_web_aliases() {
  local raw_value="$1"

  if command -v python3 >/dev/null 2>&1; then
    python3 -c "import sys, urllib.parse; sys.stdout.write(urllib.parse.unquote(sys.argv[1]))" "$raw_value"
    return $?
  fi

  if command -v perl >/dev/null 2>&1; then
    perl -MURI::Escape -e "print uri_unescape(\$ARGV[0])" "$raw_value"
    return $?
  fi

  _show_error_web_aliases "Error: URL decoding requires python3 or perl."
  return 1
}

_decode_jwt_segment_web_aliases() {
  local token_part="$1"

  if ! _check_command_web_aliases python3; then
    return 1
  fi

  python3 -c "import base64, sys
part = sys.argv[1].strip()
padding = \"=\" * (-len(part) % 4)
decoded = base64.urlsafe_b64decode((part + padding).encode())
sys.stdout.write(decoded.decode(\"utf-8\", \"replace\"))" "$token_part"
  return $?
}

_get_public_ip_web_aliases() {
  local ip_value=""
  local service_url=""

  for service_url in "https://api.ipify.org" "https://ifconfig.me/ip" "https://ipinfo.io/ip"; do
    ip_value=$(curl -fsSL --max-time 10 "$service_url" 2>/dev/null | tr -d "\r\n")
    if [ -n "$ip_value" ]; then
      printf "%s\n" "$ip_value"
      return 0
    fi
  done

  _show_error_web_aliases "Error: Failed to retrieve public IP address from all configured services."
  return 1
}

_get_local_ip_web_aliases() {
  local interface_name=""
  local ip_value=""

  case "$OSTYPE" in
    darwin*)
      interface_name=$(route -n get default 2>/dev/null | awk "/interface: / { print \$2; exit }")
      if [ -n "$interface_name" ]; then
        ip_value=$(ipconfig getifaddr "$interface_name" 2>/dev/null)
      fi
      if [ -z "$ip_value" ]; then
        ip_value=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)
      fi
      ;;
    *)
      ip_value=$(hostname -I 2>/dev/null | awk "{ print \$1 }")
      if [ -z "$ip_value" ] && command -v ip >/dev/null 2>&1; then
        ip_value=$(ip route get 1.1.1.1 2>/dev/null | awk "{ for (i = 1; i <= NF; i++) if (\$i == \"src\") { print \$(i + 1); exit } }")
      fi
      ;;
  esac

  if [ -z "$ip_value" ]; then
    _show_error_web_aliases "Error: Failed to determine local IP address."
    return 1
  fi

  printf "%s\n" "$ip_value"
  return 0
}

_start_http_server_web_aliases() {
  local port_value="$1"
  local root_value="${2:-.}"

  if [ ! -d "$root_value" ]; then
    _show_error_web_aliases "Error: Directory not found: $root_value"
    return 1
  fi

  if command -v python3 >/dev/null 2>&1; then
    cd "$root_value" || return 1
    python3 -m http.server "$port_value"
    return $?
  fi

  if command -v ruby >/dev/null 2>&1; then
    cd "$root_value" || return 1
    ruby -run -e httpd . -p "$port_value"
    return $?
  fi

  if command -v busybox >/dev/null 2>&1; then
    cd "$root_value" || return 1
    busybox httpd -f -p "$port_value" -h "."
    return $?
  fi

  if command -v http-server >/dev/null 2>&1; then
    cd "$root_value" || return 1
    command http-server -p "$port_value"
    return $?
  fi

  _show_error_web_aliases "Error: No supported local HTTP server found. Install python3, ruby, busybox, or http-server."
  return 1
}

_extract_links_web_aliases() {
  local page_url="$1"

  if command -v python3 >/dev/null 2>&1; then
    python3 -c "import sys
from html.parser import HTMLParser
from urllib.parse import urljoin

class LinkParser(HTMLParser):
    def __init__(self, base_url):
        super().__init__()
        self.base_url = base_url
        self.links = set()

    def handle_starttag(self, tag, attrs):
        if tag.lower() != \"a\":
            return
        for name, value in attrs:
            if name.lower() == \"href\" and value:
                self.links.add(urljoin(self.base_url, value))

parser = LinkParser(sys.argv[1])
parser.feed(sys.stdin.read())

for link in sorted(parser.links):
    print(link)" "$page_url"
    return $?
  fi

  grep -oE "href=\\\"[^\\\"]+\\\"" | sed -E "s/^href=\\\"//; s/\\\"$//" | sort -u
  return $?
}

# HTTP and local server aliases
alias web-serve='() {
  local usage_text="Start a local HTTP server.\nUsage:\n web-serve [port:8000] [directory:.]\nExamples:\n web-serve\n web-serve 9000\n web-serve 9000 ./dist"
  local port_value="${1:-8000}"
  local root_value="${2:-.}"

  if _maybe_show_help_web_aliases "$1" "$usage_text"; then
    return 0
  fi

  if ! _validate_port_web_aliases "$port_value"; then
    _show_usage_web_aliases "$usage_text"
    return 1
  fi

  echo "Serving \"$root_value\" at http://127.0.0.1:$port_value"
  _start_http_server_web_aliases "$port_value" "$root_value"
}' # Start a local HTTP server

alias web-speed='() {
  local usage_text="Run an internet speed test.\nUsage:\n web-speed [tool_options]\nNotes:\n Prefers official speedtest CLI, then speedtest-cli."

  if _maybe_show_help_web_aliases "$1" "$usage_text"; then
    return 0
  fi

  if command -v speedtest >/dev/null 2>&1; then
    command speedtest --accept-license --accept-gdpr "$@"
    return $?
  fi

  if command -v speedtest-cli >/dev/null 2>&1; then
    command speedtest-cli "$@"
    return $?
  fi

  _show_error_web_aliases "Error: No speed test CLI found. Install Ookla speedtest or speedtest-cli."
  echo "Install examples:" >&2
  echo "  macOS: brew install speedtest-cli" >&2
  echo "  Linux: pip install speedtest-cli" >&2
  return 1
}' # Run an internet speed test

alias web-ip='() {
  local usage_text="Show the current public IP address.\nUsage:\n web-ip"

  if _maybe_show_help_web_aliases "$1" "$usage_text"; then
    return 0
  fi

  if ! _check_command_web_aliases curl; then
    return 1
  fi

  _get_public_ip_web_aliases
}' # Show the current public IP address

alias web-ip-local='() {
  local usage_text="Show the current local IP address.\nUsage:\n web-ip-local"

  if _maybe_show_help_web_aliases "$1" "$usage_text"; then
    return 0
  fi

  _get_local_ip_web_aliases
}' # Show the current local IP address

alias web-ports='() {
  local usage_text="List local listening TCP ports.\nUsage:\n web-ports"

  if _maybe_show_help_web_aliases "$1" "$usage_text"; then
    return 0
  fi

  case "$OSTYPE" in
    darwin*)
      if ! _check_command_web_aliases lsof; then
        return 1
      fi
      lsof -nP -iTCP -sTCP:LISTEN
      return $?
      ;;
    *)
      if command -v ss >/dev/null 2>&1; then
        ss -lntp
        return $?
      fi
      if command -v lsof >/dev/null 2>&1; then
        lsof -nP -iTCP -sTCP:LISTEN
        return $?
      fi
      _show_error_web_aliases "Error: No supported port inspection tool found. Install ss or lsof."
      return 1
      ;;
  esac
}' # List local listening TCP ports

alias web-whois='() {
  local usage_text="Run WHOIS for a domain or IP.\nUsage:\n web-whois <domain_or_ip>\nExample:\n web-whois example.com"

  if _maybe_show_help_web_aliases "$1" "$usage_text"; then
    return 0
  fi

  if [ $# -eq 0 ]; then
    _show_usage_web_aliases "$usage_text"
    return 1
  fi

  if ! _check_command_web_aliases whois; then
    return 1
  fi

  whois "$1"
}' # Run WHOIS for a domain or IP

alias web-code='() {
  local usage_text="Show the final HTTP status code for a URL.\nUsage:\n web-code <url>\nExample:\n web-code https://example.com"

  if _maybe_show_help_web_aliases "$1" "$usage_text"; then
    return 0
  fi

  if [ $# -eq 0 ] || ! _validate_url_web_aliases "$1"; then
    _show_usage_web_aliases "$usage_text"
    return 1
  fi

  if ! _check_command_web_aliases curl; then
    return 1
  fi

  curl -sS -L -o /dev/null -w "%{http_code}\n" "$1"
}' # Show the final HTTP status code for a URL

alias web-head='() {
  local usage_text="Show response headers for a URL.\nUsage:\n web-head <url>\nExample:\n web-head https://example.com"

  if _maybe_show_help_web_aliases "$1" "$usage_text"; then
    return 0
  fi

  if [ $# -eq 0 ] || ! _validate_url_web_aliases "$1"; then
    _show_usage_web_aliases "$usage_text"
    return 1
  fi

  if ! _check_command_web_aliases curl; then
    return 1
  fi

  curl -sS -L -D - -o /dev/null "$1"
}' # Show response headers for a URL

alias web-time='() {
  local usage_text="Measure request timing for a URL.\nUsage:\n web-time <url>\nExample:\n web-time https://example.com"

  if _maybe_show_help_web_aliases "$1" "$usage_text"; then
    return 0
  fi

  if [ $# -eq 0 ] || ! _validate_url_web_aliases "$1"; then
    _show_usage_web_aliases "$usage_text"
    return 1
  fi

  if ! _check_command_web_aliases curl; then
    return 1
  fi

  curl -sS -L -o /dev/null -w "DNS Lookup: %{time_namelookup}s\nTCP Connect: %{time_connect}s\nTLS Handshake: %{time_appconnect}s\nTTFB: %{time_starttransfer}s\nTotal: %{time_total}s\n" "$1"
}' # Measure request timing for a URL

alias web-check='() {
  local usage_text="Show a compact HTTP summary for a URL.\nUsage:\n web-check <url>\nExample:\n web-check https://example.com"

  if _maybe_show_help_web_aliases "$1" "$usage_text"; then
    return 0
  fi

  if [ $# -eq 0 ] || ! _validate_url_web_aliases "$1"; then
    _show_usage_web_aliases "$usage_text"
    return 1
  fi

  if ! _check_command_web_aliases curl; then
    return 1
  fi

  curl -sS -L -o /dev/null -w "Final URL: %{url_effective}\nHTTP Code: %{http_code}\nRemote IP: %{remote_ip}\nScheme: %{scheme}\nRedirects: %{num_redirects}\nContent-Type: %{content_type}\nDownloaded: %{size_download} bytes\nTotal Time: %{time_total}s\n" "$1"
}' # Show a compact HTTP summary for a URL

alias web-post='() {
  local usage_text="Send JSON via HTTP POST and pretty print the response when possible.\nUsage:\n web-post <url> <json_data>\nExamples:\n web-post https://example.com/api \"{\\\"ping\\\":true}\""
  local url_value="$1"
  local json_value="$2"
  local response_body=""

  if _maybe_show_help_web_aliases "$1" "$usage_text"; then
    return 0
  fi

  if [ $# -lt 2 ] || ! _validate_url_web_aliases "$url_value"; then
    _show_usage_web_aliases "$usage_text"
    return 1
  fi

  if ! _validate_json_web_aliases "$json_value"; then
    return 1
  fi

  if ! _check_command_web_aliases curl; then
    return 1
  fi

  response_body=$(curl -sS -X POST -H "Content-Type: application/json" -d "$json_value" "$url_value")
  if [ $? -ne 0 ]; then
    _show_error_web_aliases "Error: POST request failed."
    return 1
  fi

  _print_response_web_aliases "$response_body"
}' # Send JSON via HTTP POST and pretty print the response

alias web-cors='() {
  local usage_text="Inspect CORS headers for a URL.\nUsage:\n web-cors <url> [origin:https://example.com] [method:GET]\nExamples:\n web-cors https://example.com/api\n web-cors https://example.com/api https://foo.bar POST"
  local url_value="$1"
  local origin_value="${2:-https://example.com}"
  local method_value="${3:-GET}"
  local header_output=""

  if _maybe_show_help_web_aliases "$1" "$usage_text"; then
    return 0
  fi

  if [ $# -eq 0 ] || ! _validate_url_web_aliases "$url_value"; then
    _show_usage_web_aliases "$usage_text"
    return 1
  fi

  if ! _check_command_web_aliases curl; then
    return 1
  fi

  header_output=$(curl -sS -D - -o /dev/null -X OPTIONS -H "Origin: $origin_value" -H "Access-Control-Request-Method: $method_value" "$url_value")
  if [ $? -ne 0 ]; then
    _show_error_web_aliases "Error: Failed to inspect CORS headers."
    return 1
  fi

  printf "%s\n" "$header_output" | grep -Ei "^(HTTP/|access-control-|vary:|allow:)" >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    printf "%s\n" "$header_output" | grep -Ei "^(HTTP/|access-control-|vary:|allow:)"
    return 0
  fi

  printf "%s\n" "$header_output"
}' # Inspect CORS headers for a URL

alias web-ua='() {
  local usage_text="Request a URL with a custom User-Agent.\nUsage:\n web-ua <url> [user_agent]\nExample:\n web-ua https://example.com \"Mozilla/5.0\""
  local url_value="$1"
  local agent_value="${2:-Mozilla/5.0 (compatible; web-ua/1.0)}"

  if _maybe_show_help_web_aliases "$1" "$usage_text"; then
    return 0
  fi

  if [ $# -eq 0 ] || ! _validate_url_web_aliases "$url_value"; then
    _show_usage_web_aliases "$usage_text"
    return 1
  fi

  if ! _check_command_web_aliases curl; then
    return 1
  fi

  curl -sS -A "$agent_value" "$url_value"
}' # Request a URL with a custom User-Agent

alias web-watch='() {
  local usage_text="Periodically request a URL and print HTTP code with latency.\nUsage:\n web-watch <url> [interval_seconds:5]\nExample:\n web-watch https://example.com 3"
  local url_value="$1"
  local interval_value="${2:-5}"
  local line_output=""

  if _maybe_show_help_web_aliases "$1" "$usage_text"; then
    return 0
  fi

  if [ $# -eq 0 ] || ! _validate_url_web_aliases "$url_value"; then
    _show_usage_web_aliases "$usage_text"
    return 1
  fi

  if ! _validate_positive_integer_web_aliases "$interval_value" "Interval"; then
    return 1
  fi

  if ! _check_command_web_aliases curl; then
    return 1
  fi

  echo "Watching $url_value every ${interval_value}s. Press Ctrl+C to stop."
  while true; do
    line_output=$(curl -sS -L -o /dev/null -w "[%{time_total}s] HTTP %{http_code} -> %{url_effective}" --max-time 15 "$url_value" 2>/dev/null)
    if [ $? -eq 0 ]; then
      echo "$(date "+%Y-%m-%d %H:%M:%S") $line_output"
    else
      echo "$(date "+%Y-%m-%d %H:%M:%S") ERROR request failed" >&2
    fi
    sleep "$interval_value"
  done
}' # Periodically request a URL and print HTTP code with latency

# JSON, JWT, and encoding aliases
alias web-json='() {
  local usage_text="Pretty print JSON from an argument or stdin.\nUsage:\n web-json <json_string>\n echo \"{\\\"a\\\":1}\" | web-json"
  local input_value=""

  if _maybe_show_help_web_aliases "$1" "$usage_text"; then
    return 0
  fi

  input_value=$(_read_input_web_aliases "$@")
  if [ $? -ne 0 ] || [ -z "$input_value" ]; then
    _show_usage_web_aliases "$usage_text"
    return 1
  fi

  if ! _validate_json_web_aliases "$input_value"; then
    return 1
  fi

  _format_json_web_aliases "$input_value"
}' # Pretty print JSON from an argument or stdin

alias web-json-min='() {
  local usage_text="Minify JSON from an argument or stdin.\nUsage:\n web-json-min <json_string>\n echo \"{\\\"a\\\":1}\" | web-json-min"
  local input_value=""

  if _maybe_show_help_web_aliases "$1" "$usage_text"; then
    return 0
  fi

  input_value=$(_read_input_web_aliases "$@")
  if [ $? -ne 0 ] || [ -z "$input_value" ]; then
    _show_usage_web_aliases "$usage_text"
    return 1
  fi

  if ! _validate_json_web_aliases "$input_value"; then
    return 1
  fi

  _minify_json_web_aliases "$input_value"
}' # Minify JSON from an argument or stdin

alias web-jwt='() {
  local usage_text="Decode a JWT header and payload.\nUsage:\n web-jwt <token>\nExample:\n web-jwt eyJhbGciOi..."
  local token_value="$1"
  local header_value=""
  local payload_value=""

  if _maybe_show_help_web_aliases "$1" "$usage_text"; then
    return 0
  fi

  if [ $# -eq 0 ]; then
    _show_usage_web_aliases "$usage_text"
    return 1
  fi

  case "$token_value" in
    *.*.*)
      ;;
    *)
      _show_error_web_aliases "Error: Invalid JWT format."
      return 1
      ;;
  esac

  header_value=$(_decode_jwt_segment_web_aliases "${token_value%%.*}")
  if [ $? -ne 0 ]; then
    _show_error_web_aliases "Error: Failed to decode JWT header."
    return 1
  fi

  payload_value=$(_decode_jwt_segment_web_aliases "$(printf "%s" "$token_value" | cut -d "." -f 2)")
  if [ $? -ne 0 ]; then
    _show_error_web_aliases "Error: Failed to decode JWT payload."
    return 1
  fi

  echo "Header:"
  if _is_json_web_aliases "$header_value"; then
    _format_json_web_aliases "$header_value"
  else
    printf "%s\n" "$header_value"
  fi

  echo
  echo "Payload:"
  if _is_json_web_aliases "$payload_value"; then
    _format_json_web_aliases "$payload_value"
  else
    printf "%s\n" "$payload_value"
  fi
}' # Decode a JWT header and payload

alias web-b64='() {
  local usage_text="Encode text to base64 from an argument or stdin.\nUsage:\n web-b64 <text>\n echo \"hello\" | web-b64"
  local input_value=""

  if _maybe_show_help_web_aliases "$1" "$usage_text"; then
    return 0
  fi

  input_value=$(_read_input_web_aliases "$@")
  if [ $? -ne 0 ]; then
    _show_usage_web_aliases "$usage_text"
    return 1
  fi

  printf "%s" "$input_value" | base64 | tr -d "\r\n"
  echo
}' # Encode text to base64 from an argument or stdin

alias web-b64d='() {
  local usage_text="Decode base64 or base64url text.\nUsage:\n web-b64d <encoded_text>\nExample:\n web-b64d aGVsbG8="
  local input_value="$1"

  if _maybe_show_help_web_aliases "$1" "$usage_text"; then
    return 0
  fi

  if [ $# -eq 0 ]; then
    _show_usage_web_aliases "$usage_text"
    return 1
  fi

  _decode_base64_web_aliases "$input_value"
  local decode_status=$?
  if [ $decode_status -ne 0 ]; then
    return $decode_status
  fi
  echo
}' # Decode base64 or base64url text

alias web-b64url='() {
  local usage_text="Encode text to URL-safe base64 without padding.\nUsage:\n web-b64url <text>\n echo \"hello\" | web-b64url"
  local input_value=""

  if _maybe_show_help_web_aliases "$1" "$usage_text"; then
    return 0
  fi

  input_value=$(_read_input_web_aliases "$@")
  if [ $? -ne 0 ]; then
    _show_usage_web_aliases "$usage_text"
    return 1
  fi

  _encode_base64url_web_aliases "$input_value"
  echo
}' # Encode text to URL-safe base64 without padding

alias web-urlenc='() {
  local usage_text="Percent-encode text for URLs.\nUsage:\n web-urlenc <text>\n echo \"a b\" | web-urlenc"
  local input_value=""

  if _maybe_show_help_web_aliases "$1" "$usage_text"; then
    return 0
  fi

  input_value=$(_read_input_web_aliases "$@")
  if [ $? -ne 0 ]; then
    _show_usage_web_aliases "$usage_text"
    return 1
  fi

  _encode_url_web_aliases "$input_value"
  echo
}' # Percent-encode text for URLs

alias web-urldec='() {
  local usage_text="Decode percent-encoded URL text.\nUsage:\n web-urldec <encoded_text>\nExample:\n web-urldec hello%20world"
  local input_value=""

  if _maybe_show_help_web_aliases "$1" "$usage_text"; then
    return 0
  fi

  input_value=$(_read_input_web_aliases "$@")
  if [ $? -ne 0 ]; then
    _show_usage_web_aliases "$usage_text"
    return 1
  fi

  _decode_url_web_aliases "$input_value"
  echo
}' # Decode percent-encoded URL text

alias web-qr='() {
  local usage_text="Generate a terminal QR code from text.\nUsage:\n web-qr <text>\n echo \"https://example.com\" | web-qr"
  local input_value=""

  if _maybe_show_help_web_aliases "$1" "$usage_text"; then
    return 0
  fi

  if ! _check_command_web_aliases qrencode; then
    return 1
  fi

  input_value=$(_read_input_web_aliases "$@")
  if [ $? -ne 0 ] || [ -z "$input_value" ]; then
    _show_usage_web_aliases "$usage_text"
    return 1
  fi

  qrencode -t UTF8 "$input_value"
}' # Generate a terminal QR code from text

alias web-qrd='() {
  local usage_text="Decode a QR code from an image.\nUsage:\n web-qrd <image_path>\nExample:\n web-qrd ./qr.png"

  if _maybe_show_help_web_aliases "$1" "$usage_text"; then
    return 0
  fi

  if [ $# -eq 0 ]; then
    _show_usage_web_aliases "$usage_text"
    return 1
  fi

  if [ ! -f "$1" ]; then
    _show_error_web_aliases "Error: File not found: $1"
    return 1
  fi

  if ! _check_command_web_aliases zbarimg; then
    return 1
  fi

  zbarimg --quiet --raw "$1"
}' # Decode a QR code from an image

# DNS, SSL, and web content aliases
alias web-dns='() {
  local usage_text="Run a quick DNS lookup.\nUsage:\n web-dns <domain> [record_type:A]\nExamples:\n web-dns example.com\n web-dns example.com MX"
  local domain_value="$1"
  local type_value="${2:-A}"

  if _maybe_show_help_web_aliases "$1" "$usage_text"; then
    return 0
  fi

  if [ $# -eq 0 ]; then
    _show_usage_web_aliases "$usage_text"
    return 1
  fi

  if ! _check_command_web_aliases dig; then
    return 1
  fi

  dig +short "$domain_value" "$type_value"
}' # Run a quick DNS lookup

alias web-dns-flush='() {
  local usage_text="Flush the local DNS cache.\nUsage:\n web-dns-flush"

  if _maybe_show_help_web_aliases "$1" "$usage_text"; then
    return 0
  fi

  case "$OSTYPE" in
    darwin*)
      sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder
      return $?
      ;;
    *)
      if command -v resolvectl >/dev/null 2>&1; then
        sudo resolvectl flush-caches
        return $?
      fi
      if command -v systemd-resolve >/dev/null 2>&1; then
        sudo systemd-resolve --flush-caches
        return $?
      fi
      if command -v service >/dev/null 2>&1; then
        sudo service nscd restart >/dev/null 2>&1 && return 0
        sudo service dnsmasq restart >/dev/null 2>&1 && return 0
      fi
      _show_error_web_aliases "Error: Could not find a supported DNS cache service to flush."
      return 1
      ;;
  esac
}' # Flush the local DNS cache

alias web-cert='() {
  local usage_text="Show certificate subject, issuer, dates, and SANs.\nUsage:\n web-cert <host> [port:443]\nExamples:\n web-cert example.com\n web-cert example.com 8443"
  local host_value="$1"
  local port_value="${2:-443}"
  local cert_output=""

  if _maybe_show_help_web_aliases "$1" "$usage_text"; then
    return 0
  fi

  if [ $# -eq 0 ]; then
    _show_usage_web_aliases "$usage_text"
    return 1
  fi

  if ! _validate_port_web_aliases "$port_value"; then
    return 1
  fi

  if ! _check_command_web_aliases openssl; then
    return 1
  fi

  cert_output=$(echo | openssl s_client -servername "$host_value" -connect "$host_value:$port_value" 2>/dev/null | openssl x509 -noout -subject -issuer -dates -ext subjectAltName 2>/dev/null)
  if [ $? -ne 0 ] || [ -z "$cert_output" ]; then
    _show_error_web_aliases "Error: Failed to fetch certificate from $host_value:$port_value"
    return 1
  fi

  printf "%s\n" "$cert_output"
}' # Show certificate subject, issuer, dates, and SANs

alias web-cert-exp='() {
  local usage_text="Show certificate expiry and remaining days.\nUsage:\n web-cert-exp <host> [port:443]\nExamples:\n web-cert-exp example.com\n web-cert-exp example.com 8443"
  local host_value="$1"
  local port_value="${2:-443}"
  local expiry_line=""

  if _maybe_show_help_web_aliases "$1" "$usage_text"; then
    return 0
  fi

  if [ $# -eq 0 ]; then
    _show_usage_web_aliases "$usage_text"
    return 1
  fi

  if ! _validate_port_web_aliases "$port_value"; then
    return 1
  fi

  if ! _check_command_web_aliases openssl; then
    return 1
  fi

  if ! _check_command_web_aliases python3; then
    return 1
  fi

  expiry_line=$(echo | openssl s_client -servername "$host_value" -connect "$host_value:$port_value" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null)
  if [ $? -ne 0 ] || [ -z "$expiry_line" ]; then
    _show_error_web_aliases "Error: Failed to read certificate expiry from $host_value:$port_value"
    return 1
  fi

  python3 -c "import datetime, sys
raw = sys.argv[1].split(\"=\", 1)[1]
expiry = datetime.datetime.strptime(raw, \"%b %d %H:%M:%S %Y %Z\").replace(tzinfo=datetime.timezone.utc)
now = datetime.datetime.now(datetime.timezone.utc)
remaining = expiry - now
print(f\"Expires: {raw}\")
print(f\"Days Left: {remaining.days}\")" "$expiry_line"
}' # Show certificate expiry and remaining days

alias web-links='() {
  local usage_text="Extract links from a web page.\nUsage:\n web-links <url>\nExample:\n web-links https://example.com"
  local url_value="$1"
  local html_content=""

  if _maybe_show_help_web_aliases "$1" "$usage_text"; then
    return 0
  fi

  if [ $# -eq 0 ] || ! _validate_url_web_aliases "$url_value"; then
    _show_usage_web_aliases "$usage_text"
    return 1
  fi

  if ! _check_command_web_aliases curl; then
    return 1
  fi

  html_content=$(curl -fsSL --compressed "$url_value")
  if [ $? -ne 0 ] || [ -z "$html_content" ]; then
    _show_error_web_aliases "Error: Failed to fetch HTML from $url_value"
    return 1
  fi

  printf "%s" "$html_content" | _extract_links_web_aliases "$url_value"
}' # Extract links from a web page

alias web-mirror='() {
  local usage_text="Mirror a site for offline viewing.\nUsage:\n web-mirror <url> [output_directory:.]\nExample:\n web-mirror https://example.com ./mirror"
  local url_value="$1"
  local output_value="${2:-.}"

  if _maybe_show_help_web_aliases "$1" "$usage_text"; then
    return 0
  fi

  if [ $# -eq 0 ] || ! _validate_url_web_aliases "$url_value"; then
    _show_usage_web_aliases "$usage_text"
    return 1
  fi

  if ! _check_command_web_aliases wget; then
    return 1
  fi

  mkdir -p "$output_value"
  if [ $? -ne 0 ]; then
    _show_error_web_aliases "Error: Failed to create output directory: $output_value"
    return 1
  fi

  wget --mirror --convert-links --adjust-extension --page-requisites --no-parent --directory-prefix="$output_value" "$url_value"
}' # Mirror a site for offline viewing

# Help and compatibility aliases
alias web-help='() {
  echo "Web aliases with unified \"web-\" prefix:"
  echo ""
  echo "HTTP and local server:"
  echo "  web-serve [port] [dir]      Start a local HTTP server"
  echo "  web-speed                   Run an internet speed test"
  echo "  web-code <url>              Show final HTTP status code"
  echo "  web-head <url>              Show response headers"
  echo "  web-time <url>              Show request timing details"
  echo "  web-check <url>             Show compact HTTP summary"
  echo "  web-post <url> <json>       POST JSON and pretty print response"
  echo "  web-cors <url> [origin] [method] Inspect CORS headers"
  echo "  web-ua <url> [ua]           Request with a custom User-Agent"
  echo "  web-watch <url> [seconds]   Poll a URL repeatedly"
  echo ""
  echo "Network and DNS:"
  echo "  web-ip                      Show public IP"
  echo "  web-ip-local                Show local IP"
  echo "  web-ports                   Show local listening TCP ports"
  echo "  web-whois <host>            WHOIS lookup"
  echo "  web-dns <domain> [type]     Quick DNS lookup"
  echo "  web-dns-flush               Flush local DNS cache"
  echo ""
  echo "JSON, JWT, and encoding:"
  echo "  web-json [json]             Pretty print JSON"
  echo "  web-json-min [json]         Minify JSON"
  echo "  web-jwt <token>             Decode JWT header and payload"
  echo "  web-b64 [text]              Base64 encode"
  echo "  web-b64d <text>             Base64 or base64url decode"
  echo "  web-b64url [text]           URL-safe base64 encode"
  echo "  web-urlenc [text]           URL encode"
  echo "  web-urldec [text]           URL decode"
  echo "  web-qr [text]               Generate a QR code"
  echo "  web-qrd <image>             Decode a QR code image"
  echo ""
  echo "Certificates and content:"
  echo "  web-cert <host> [port]      Show certificate summary"
  echo "  web-cert-exp <host> [port]  Show certificate expiry"
  echo "  web-links <url>             Extract page links"
  echo "  web-mirror <url> [dir]      Mirror a site with wget"
  echo ""
  echo "Backward-compatible legacy aliases are still available and map to the new web-* names."
}' # Show help for unified web aliases

alias qr="web-qr"
alias qrdecode="web-qrd"
alias urlencode="web-urlenc"
alias urldecode="web-urldec"
alias b64encode="web-b64"
alias b64decode="web-b64d"
alias b64urlencode="web-b64url"
alias speedtest="web-speed"
alias http-server="web-serve"
alias myip="web-ip"
alias localip="web-ip-local"
alias ports="web-ports"
alias whois-ip="web-whois"
alias httpcode="web-code"
alias headers="web-head"
alias curl-time="web-time"
alias postjson="web-post"
alias jsonformat="web-json"
alias jsonminify="web-json-min"
alias jwtdecode="web-jwt"
alias sslcheck="web-cert"
alias sslexpiry="web-cert-exp"
alias dnsflush="web-dns-flush"
alias digshort="web-dns"
alias wget-mirror="web-mirror"
alias extract-links="web-links"
alias cors-test="web-cors"
alias useragent="web-ua"
alias webping="web-watch"
