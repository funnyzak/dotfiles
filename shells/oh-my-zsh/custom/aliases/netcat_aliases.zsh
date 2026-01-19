# Description: Netcat (nc) utility aliases for network connections, port scanning, data transfer, and network testing.

# Helper functions for netcat aliases
_show_error_netcat_aliases() {
  echo "$1" >&2
  return 1
}

_show_usage_netcat_aliases() {
  echo -e "$1"
  return 0
}

_check_command_netcat_aliases() {
  if ! command -v "$1" &> /dev/null; then
    _show_error_netcat_aliases "Error: Required command \"$1\" not found. Please install it first."
    return 1
  fi
  return 0
}

_validate_port_netcat_aliases() {
  local port="$1"
  if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    _show_error_netcat_aliases "Error: Port must be between 1 and 65535."
    return 1
  fi
  return 0
}

_validate_timeout_netcat_aliases() {
  local timeout="$1"
  if ! [[ "$timeout" =~ ^[0-9]+$ ]] || [ "$timeout" -lt 1 ]; then
    _show_error_netcat_aliases "Error: Timeout must be a positive integer."
    return 1
  fi
  return 0
}

# Connection Testing
# ==================

alias nc-test='() {
  echo -e "Test TCP connection to a host and port.\nUsage:\n nc-test <host> <port> [--timeout seconds:5]\nExample:\n nc-test google.com 80"

  if [ $# -lt 2 ]; then
    _show_error_netcat_aliases "Error: Missing required parameters."
    return 1
  fi

  if ! _check_command_netcat_aliases nc; then
    return 1
  fi

  local host="$1"
  local port="$2"
  local timeout="5"

  # Parse optional parameters
  while [ $# -gt 2 ]; do
    case "$3" in
      --timeout|-t)
        timeout="$4"
        shift 2
        ;;
      *)
        _show_error_netcat_aliases "Error: Unknown option: $3"
        return 1
        ;;
    esac
  done

  if ! _validate_port_netcat_aliases "$port"; then
    return 1
  fi

  if ! _validate_timeout_netcat_aliases "$timeout"; then
    return 1
  fi

  echo "Testing connection to $host:$port (timeout: ${timeout}s)..."
  if nc -zv -w "$timeout" "$host" "$port" 2>&1; then
    echo "Connection successful: $host:$port is OPEN"
  else
    echo "Connection failed: $host:$port is CLOSED or unreachable"
    return 1
  fi
}'  # Test TCP connection to host and port

alias nc-listen='() {
  echo -e "Start TCP listener on specified port.\nUsage:\n nc-listen <port> [--verbose]\nExample:\n nc-listen 8080\n nc-listen 8080 --verbose"

  if [ $# -eq 0 ]; then
    _show_error_netcat_aliases "Error: Missing required parameter: port"
    return 1
  fi

  if ! _check_command_netcat_aliases nc; then
    return 1
  fi

  local port="$1"
  local verbose=false

  # Parse optional parameters
  while [ $# -gt 1 ]; do
    case "$2" in
      --verbose|-v)
        verbose=true
        shift
        ;;
      *)
        _show_error_netcat_aliases "Error: Unknown option: $2"
        return 1
        ;;
    esac
  done

  if ! _validate_port_netcat_aliases "$port"; then
    return 1
  fi

  echo "Starting TCP listener on port $port..."
  echo "Press Ctrl+C to stop listening"

  if [ "$verbose" = true ]; then
    echo "Verbose mode enabled - showing connection details"
    nc -lv "$port"
  else
    nc -l "$port"
  fi
}'  # Start TCP listener on specified port

alias nc-udp-listen='() {
  echo -e "Start UDP listener on specified port.\nUsage:\n nc-udp-listen <port> [--verbose]\nExample:\n nc-udp-listen 8080"

  if [ $# -eq 0 ]; then
    _show_error_netcat_aliases "Error: Missing required parameter: port"
    return 1
  fi

  if ! _check_command_netcat_aliases nc; then
    return 1
  fi

  local port="$1"
  local verbose=false

  # Parse optional parameters
  while [ $# -gt 1 ]; do
    case "$2" in
      --verbose|-v)
        verbose=true
        shift
        ;;
      *)
        _show_error_netcat_aliases "Error: Unknown option: $2"
        return 1
        ;;
    esac
  done

  if ! _validate_port_netcat_aliases "$port"; then
    return 1
  fi

  echo "Starting UDP listener on port $port..."
  echo "Press Ctrl+C to stop listening"

  if [ "$verbose" = true ]; then
    echo "Verbose mode enabled - showing packet details"
    nc -luv "$port"
  else
    nc -lu "$port"
  fi
}'  # Start UDP listener on specified port

# Port Scanning
# ============

alias nc-scan='() {
  echo -e "Scan ports on a host to find open ports.\nUsage:\n nc-scan <host> <start_port> <end_port> [--timeout seconds:1]\nExample:\n nc-scan localhost 1 1000\n nc-scan example.com 80 443 --timeout 2"

  if [ $# -lt 3 ]; then
    _show_error_netcat_aliases "Error: Missing required parameters: host, start_port, end_port"
    return 1
  fi

  if ! _check_command_netcat_aliases nc; then
    return 1
  fi

  local host="$1"
  local start_port="$2"
  local end_port="$3"
  local timeout="1"

  # Parse optional parameters
  while [ $# -gt 3 ]; do
    case "$4" in
      --timeout|-t)
        timeout="$5"
        shift 2
        ;;
      *)
        _show_error_netcat_aliases "Error: Unknown option: $4"
        return 1
        ;;
    esac
  done

  if ! _validate_port_netcat_aliases "$start_port"; then
    return 1
  fi

  if ! _validate_port_netcat_aliases "$end_port"; then
    return 1
  fi

  if [ "$start_port" -gt "$end_port" ]; then
    _show_error_netcat_aliases "Error: Start port must be less than or equal to end port"
    return 1
  fi

  if ! _validate_timeout_netcat_aliases "$timeout"; then
    return 1
  fi

  echo "Scanning $host for open ports from $start_port to $end_port..."
  echo "Timeout per port: ${timeout}s"
  echo "Open ports:"

  local open_ports=()
  for port in $(seq "$start_port" "$end_port"); do
    if nc -zv -w "$timeout" "$host" "$port" 2>/dev/null; then
      echo "  $port/tcp - OPEN"
      open_ports+=("$port")
    fi
  done

  if [ ${#open_ports[@]} -eq 0 ]; then
    echo "  No open ports found in range $start_port-$end_port"
  else
    echo "Scan complete. Found ${#open_ports[@]} open port(s)."
  fi
}'  # Scan ports on a host to find open ports

alias nc-scan-common='() {
  echo -e "Scan common ports on a host.\nUsage:\n nc-scan-common <host> [--timeout seconds:2]\nExample:\n nc-scan-common example.com"

  if [ $# -eq 0 ]; then
    _show_error_netcat_aliases "Error: Missing required parameter: host"
    return 1
  fi

  if ! _check_command_netcat_aliases nc; then
    return 1
  fi

  local host="$1"
  local timeout="2"

  # Parse optional parameters
  while [ $# -gt 1 ]; do
    case "$2" in
      --timeout|-t)
        timeout="$3"
        shift 2
        ;;
      *)
        _show_error_netcat_aliases "Error: Unknown option: $2"
        return 1
        ;;
    esac
  done

  if ! _validate_timeout_netcat_aliases "$timeout"; then
    return 1
  fi

  local common_ports=(21 22 23 25 53 80 110 143 443 993 995 1433 3306 3389 5432 6379 8080 8443 9200)

  echo "Scanning common ports on $host..."
  echo "Timeout per port: ${timeout}s"
  echo "Open ports:"

  local open_ports=()
  for port in "${common_ports[@]}"; do
    if nc -zv -w "$timeout" "$host" "$port" 2>/dev/null; then
      local service_name=""
      case "$port" in
        21) service_name="FTP" ;;
        22) service_name="SSH" ;;
        23) service_name="Telnet" ;;
        25) service_name="SMTP" ;;
        53) service_name="DNS" ;;
        80) service_name="HTTP" ;;
        110) service_name="POP3" ;;
        143) service_name="IMAP" ;;
        443) service_name="HTTPS" ;;
        993) service_name="IMAPS" ;;
        995) service_name="POP3S" ;;
        1433) service_name="MSSQL" ;;
        3306) service_name="MySQL" ;;
        3389) service_name="RDP" ;;
        5432) service_name="PostgreSQL" ;;
        6379) service_name="Redis" ;;
        8080) service_name="HTTP-Alt" ;;
        8443) service_name="HTTPS-Alt" ;;
        9200) service_name="Elasticsearch" ;;
      esac
      echo "  $port/tcp - OPEN ($service_name)"
      open_ports+=("$port")
    fi
  done

  if [ ${#open_ports[@]} -eq 0 ]; then
    echo "  No common ports found open"
  else
    echo "Scan complete. Found ${#open_ports[@]} open common port(s)."
  fi
}'  # Scan common ports on a host

# Data Transfer
# ============

alias nc-send-file='() {
  echo -e "Send file content to a host and port.\nUsage:\n nc-send-file <host> <port> <file_path>\nExample:\n nc-send-file example.com 8080 ./data.txt"

  if [ $# -lt 3 ]; then
    _show_error_netcat_aliases "Error: Missing required parameters: host, port, file_path"
    return 1
  fi

  if ! _check_command_netcat_aliases nc; then
    return 1
  fi

  local host="$1"
  local port="$2"
  local file_path="$3"

  if ! _validate_port_netcat_aliases "$port"; then
    return 1
  fi

  if [ ! -f "$file_path" ]; then
    _show_error_netcat_aliases "Error: File not found: $file_path"
    return 1
  fi

  if [ ! -r "$file_path" ]; then
    _show_error_netcat_aliases "Error: File is not readable: $file_path"
    return 1
  fi

  local file_size
  if command -v stat >/dev/null 2>&1; then
    if [ "$(uname)" = "Darwin" ]; then
      file_size=$(stat -f%z "$file_path" 2>/dev/null || echo "unknown")
    else
      file_size=$(stat -c%s "$file_path" 2>/dev/null || echo "unknown")
    fi
  else
    file_size="unknown"
  fi

  echo "Sending file: $file_path (${file_size} bytes) to $host:$port..."

  if nc "$host" "$port" < "$file_path"; then
    echo "File sent successfully"
  else
    _show_error_netcat_aliases "Error: Failed to send file to $host:$port"
    return 1
  fi
}'  # Send file content to a host and port

alias nc-send-text='() {
  echo -e "Send text content to a host and port.\nUsage:\n nc-send-text <host> <port> <text>\nExample:\n nc-send-text example.com 8080 \"Hello, world!\""

  if [ $# -lt 3 ]; then
    _show_error_netcat_aliases "Error: Missing required parameters: host, port, text"
    return 1
  fi

  if ! _check_command_netcat_aliases nc; then
    return 1
  fi

  if ! _validate_port_netcat_aliases "$port"; then
    return 1
  fi

  local host="$1"
  local port="$2"
  local text="$3"

  if nc "$host" "$port" <<< "$text"; then
    echo "Text sent successfully"
  else
    _show_error_netcat_aliases "Error: Failed to send text to $host:$port"
    return 1
  fi
}'  # Send text content to a host and port

alias nc-receive='() {
  echo -e "Receive data and save to file.\nUsage:\n nc-receive <port> <output_file>\nExample:\n nc-receive 8080 ./received_data.txt"

  if [ $# -lt 2 ]; then
    _show_error_netcat_aliases "Error: Missing required parameters: port, output_file"
    return 1
  fi

  if ! _check_command_netcat_aliases nc; then
    return 1
  fi

  local port="$1"
  local output_file="$2"

  if ! _validate_port_netcat_aliases "$port"; then
    return 1
  fi

  local output_dir
  output_dir=$(dirname "$output_file")

  if [ ! -d "$output_dir" ]; then
    if ! mkdir -p "$output_dir"; then
      _show_error_netcat_aliases "Error: Failed to create directory: $output_dir"
      return 1
    fi
  fi

  echo "Listening on port $port, saving data to: $output_file"
  echo "Press Ctrl+C to stop receiving"

  if nc -l "$port" > "$output_file"; then
    echo "Data received successfully and saved to: $output_file"
    if [ -f "$output_file" ]; then
      local file_size
      if command -v stat >/dev/null 2>&1; then
        if [ "$(uname)" = "Darwin" ]; then
          file_size=$(stat -f%z "$output_file" 2>/dev/null || echo "unknown")
        else
          file_size=$(stat -c%s "$output_file" 2>/dev/null || echo "unknown")
        fi
      else
        file_size="unknown"
      fi
      echo "File size: ${file_size} bytes"
    fi
  else
    _show_error_netcat_aliases "Error: Failed to receive data on port $port"
    return 1
  fi
}'  # Receive data and save to file

alias nc-chat='() {
  echo -e "Start simple chat server/client.\nUsage:\n Server: nc-chat <port>\n Client: nc-chat <host> <port>\nExample:\n nc-chat 12345\n nc-chat localhost 12345"

  if [ $# -eq 0 ]; then
    _show_error_netcat_aliases "Error: Missing required parameters"
    return 1
  fi

  if ! _check_command_netcat_aliases nc; then
    return 1
  fi

  if [ $# -eq 1 ]; then
    # Server mode
    local port="$1"
    if ! _validate_port_netcat_aliases "$port"; then
      return 1
    fi
    echo "Starting chat server on port $port..."
    echo "Waiting for client to connect..."
    echo "Type messages and press Enter to send. Press Ctrl+C to exit."
    nc -l "$port"
  else
    # Client mode
    local host="$1"
    local port="$2"
    if ! _validate_port_netcat_aliases "$port"; then
      return 1
    fi
    echo "Connecting to chat server at $host:$port..."
    echo "Type messages and press Enter to send. Press Ctrl+C to exit."
    nc "$host" "$port"
  fi
}'  # Start simple chat server/client

# Network Testing
# ===============

alias nc-proxy='() {
  echo -e "Create simple TCP proxy between two ports.\nUsage:\n nc-proxy <listen_port> <target_host> <target_port>\nExample:\n nc-proxy 8080 google.com 80"

  if [ $# -lt 3 ]; then
    _show_error_netcat_aliases "Error: Missing required parameters: listen_port, target_host, target_port"
    return 1
  fi

  if ! _check_command_netcat_aliases nc; then
    return 1
  fi

  local listen_port="$1"
  local target_host="$2"
  local target_port="$3"

  if ! _validate_port_netcat_aliases "$listen_port"; then
    return 1
  fi

  if ! _validate_port_netcat_aliases "$target_port"; then
    return 1
  fi

  echo "Starting TCP proxy: localhost:$listen_port -> $target_host:$target_port"
  echo "Press Ctrl+C to stop proxy"

  # Create named pipe for bidirectional communication
  local temp_pipe=$(mktemp -u)
  if ! mkfifo "$temp_pipe"; then
    _show_error_netcat_aliases "Error: Failed to create named pipe"
    return 1
  fi

  # Set up cleanup
  trap "rm -f \"$temp_pipe\"" EXIT

  # Start proxy
  nc -l "$listen_port" < "$temp_pipe" | nc "$target_host" "$target_port" > "$temp_pipe"
}'  # Create simple TCP proxy

alias nc-web-server='() {
  echo -e "Start simple HTTP server serving current directory.\nUsage:\n nc-web-server <port:8080>\nExample:\n nc-web-server 8080"

  local port="${1:-8080}"

  if ! _check_command_netcat_aliases nc; then
    return 1
  fi

  if ! _validate_port_netcat_aliases "$port"; then
    return 1
  fi

  echo "Starting simple HTTP server on port $port..."
  echo "Serving files from: $(pwd)"
  echo "Access URLs:"
  echo "  http://localhost:$port/"
  echo "Press Ctrl+C to stop server"

  # Function to generate HTTP response
  _nc_http_response() {
    local request="$1"
    local file_path

    # Extract file path from HTTP request
    file_path=$(echo "$request" | head -n1 | awk "{print \$2}")

    # Remove leading slash and default to index.html
    if [ "$file_path" = "/" ]; then
      file_path="/index.html"
    fi

    file_path=".$file_path"

    if [ -f "$file_path" ] && [ -r "$file_path" ]; then
      local content_type="text/plain"
      case "${file_path##*.}" in
        html) content_type="text/html" ;;
        css) content_type="text/css" ;;
        js) content_type="application/javascript" ;;
        json) content_type="application/json" ;;
        png) content_type="image/png" ;;
        jpg|jpeg) content_type="image/jpeg" ;;
        gif) content_type="image/gif" ;;
        svg) content_type="image/svg+xml" ;;
      esac

      echo -e "HTTP/1.1 200 OK\r\nContent-Type: $content_type\r\nConnection: close\r\n\r\n$(cat "$file_path")"
    else
      echo -e "HTTP/1.1 404 Not Found\r\nContent-Type: text/html\r\nConnection: close\r\n\r\n<h1>404 Not Found</h1><p>The requested file was not found.</p>"
    fi
  }

  export -f _nc_http_response
  while true; do
    {
      read request
      _nc_http_response "$request"
    } | nc -l "$port"
  done
}'  # Start simple HTTP server

# Advanced Testing
# ================

alias nc-bandwidth='() {
  echo -e "Test network bandwidth between two hosts.\nUsage:\n Server: nc-bandwidth server <port:5001>\n Client: nc-bandwidth client <host> <port:5001> [--size MB:100]\nExample:\n nc-bandwidth server 5001\n nc-bandwidth client server.example.com 5001 --size 100"

  if [ $# -eq 0 ]; then
    _show_error_netcat_aliases "Error: Missing required parameters"
    return 1
  fi

  if ! _check_command_netcat_aliases nc; then
    return 1
  fi

  local mode="$1"

  case "$mode" in
    server)
      local port="${2:-5001}"
      if ! _validate_port_netcat_aliases "$port"; then
        return 1
      fi

      echo "Starting bandwidth test server on port $port..."
      echo "Waiting for client connection..."
      echo "Press Ctrl+C to stop server"

      # Receive data and discard
      nc -l "$port" > /dev/null
      ;;

    client)
      if [ $# -lt 2 ]; then
        _show_error_netcat_aliases "Error: Client mode requires host parameter"
        return 1
      fi

      local host="$2"
      local port="${3:-5001}"
      local size_mb="100"

      # Parse optional parameters
      while [ $# -gt 3 ]; do
        case "$4" in
          --size|-s)
            size_mb="$5"
            shift 2
            ;;
          *)
            _show_error_netcat_aliases "Error: Unknown option: $4"
            return 1
            ;;
        esac
      done

      if ! _validate_port_netcat_aliases "$port"; then
        return 1
      fi

      if ! [[ "$size_mb" =~ ^[0-9]+$ ]] || [ "$size_mb" -lt 1 ]; then
        _show_error_netcat_aliases "Error: Size must be a positive integer (MB)"
        return 1
      fi

      echo "Testing bandwidth to $host:$port with ${size_mb}MB of data..."

      # Generate test data and send
      local start_time
      start_time=$(date +%s)

      if dd if=/dev/zero bs=1M count="$size_mb" 2>/dev/null | nc "$host" "$port"; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))

        if [ "$duration" -gt 0 ]; then
          local bandwidth_mbps
          bandwidth_mbps=$((size_mb / duration))
          echo "Bandwidth test completed:"
          echo "  Data transferred: ${size_mb}MB"
          echo "  Time taken: ${duration}s"
          echo "  Average bandwidth: ${bandwidth_mbps}MB/s"
        else
          echo "Bandwidth test completed in less than 1 second"
        fi
      else
        _show_error_netcat_aliases "Error: Bandwidth test failed"
        return 1
      fi
      ;;

    *)
      _show_error_netcat_aliases "Error: Invalid mode. Use \"server\" or \"client\""
      return 1
      ;;
  esac
}'  # Test network bandwidth between two hosts

alias nc-ping='() {
  echo -e "Ping a host:port using TCP connection attempts.\nUsage:\n nc-ping <host> <port> [--count 4] [--interval 1]\nExample:\n nc-ping google.com 80\n nc-ping example.com 443 --count 10 --interval 2"

  if [ $# -lt 2 ]; then
    _show_error_netcat_aliases "Error: Missing required parameters: host, port"
    return 1
  fi

  if ! _check_command_netcat_aliases nc; then
    return 1
  fi

  local host="$1"
  local port="$2"
  local count="4"
  local interval="1"

  # Parse optional parameters
  while [ $# -gt 2 ]; do
    case "$3" in
      --count|-c)
        count="$4"
        shift 2
        ;;
      --interval|-i)
        interval="$4"
        shift 2
        ;;
      *)
        _show_error_netcat_aliases "Error: Unknown option: $3"
        return 1
        ;;
    esac
  done

  if ! _validate_port_netcat_aliases "$port"; then
    return 1
  fi

  if ! [[ "$count" =~ ^[0-9]+$ ]] || [ "$count" -lt 1 ]; then
    _show_error_netcat_aliases "Error: Count must be a positive integer"
    return 1
  fi

  if ! [[ "$interval" =~ ^[0-9]+$ ]] || [ "$interval" -lt 1 ]; then
    _show_error_netcat_aliases "Error: Interval must be a positive integer"
    return 1
  fi

  echo "TCP pinging $host:$port (${count} attempts, ${interval}s interval)..."

  local success_count=0
  local failed_count=0

  for i in $(seq 1 "$count"); do
    echo -n "Ping $i/$count: "
    local start_time
    start_time=$(date +%s%3N)

    if nc -zv -w 3 "$host" "$port" 2>/dev/null; then
      local end_time
      end_time=$(date +%s%3N)
      local duration=$((end_time - start_time))
      echo "Success (${duration}ms)"
      success_count=$((success_count + 1))
    else
      echo "Failed"
      failed_count=$((failed_count + 1))
    fi

    if [ "$i" -lt "$count" ]; then
      sleep "$interval"
    fi
  done

  echo "TCP ping statistics:"
  echo "  Packets: Sent = $count, Received = $success_count, Lost = $failed_count ($((failed_count * 100 / count))% loss)"
}'  # Ping a host:port using TCP connection attempts

# Help Function
# ============

alias nc-help='() {
  echo "Netcat (nc) Utility Aliases Help"
  echo "================================="
  echo
  echo "Connection Testing:"
  echo "  nc-test <host> <port> [--timeout secs]  - Test TCP connection"
  echo "  nc-listen <port> [--verbose]            - Start TCP listener"
  echo "  nc-udp-listen <port> [--verbose]        - Start UDP listener"
  echo
  echo "Port Scanning:"
  echo "  nc-scan <host> <start> <end> [--timeout]  - Scan port range"
  echo "  nc-scan-common <host> [--timeout]         - Scan common ports"
  echo
  echo "Data Transfer:"
  echo "  nc-send-file <host> <port> <file>       - Send file to host:port"
  echo "  nc-send-text <host> <port> <text>       - Send text to host:port"
  echo "  nc-receive <port> <output_file>         - Receive data from port"
  echo "  nc-chat <port>                          - Start chat server"
  echo "  nc-chat <host> <port>                   - Connect to chat server"
  echo
  echo "Network Testing:"
  echo "  nc-proxy <listen_port> <target_host> <target_port> - Create TCP proxy"
  echo "  nc-web-server [port]                    - Start simple HTTP server"
  echo "  nc-bandwidth server <port>              - Start bandwidth server"
  echo "  nc-bandwidth client <host> <port> [--size] - Test bandwidth"
  echo "  nc-ping <host> <port> [--count] [--interval] - TCP ping"
  echo
  echo "Examples:"
  echo "  nc-test google.com 80"
  echo "  nc-listen 8080 --verbose"
  echo "  nc-scan localhost 1 1000"
  echo "  nc-send-file example.com 8080 ./data.txt"
  echo "  nc-send-text example.com 8080 \"Hello, world!\""
  echo "  nc-receive 8080 ./received.txt"
  echo "  nc-chat 12345"
  echo "  nc-web-server 8080"
  echo
  echo "For detailed usage information, run any command without arguments"
}'  # Display help for netcat aliases
