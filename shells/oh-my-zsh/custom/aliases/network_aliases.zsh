# Description: Network related aliases for connectivity testing, information gathering, port scanning, monitoring and downloads.

# Helper functions for network aliases
_show_error_network_aliases() {
  echo "$1" >&2
  return 1
}

_show_usage_network_aliases() {
  echo -e "$1"
  return 0
}

_check_command_network_aliases() {
  if ! command -v "$1" &> /dev/null; then
    _show_error_network_aliases "Error: Required command '$1' not found. Please install it first."
    return 1
  fi
  return 0
}

# System Information
alias net-myip='() {
  _show_usage_network_aliases "Get your public IP address."

  if ! _check_command_network_aliases curl; then
    return 1
  fi

  if ! curl -s ipinfo.io/ip; then
    _show_error_network_aliases "Failed to retrieve public IP address. Check your internet connection."
    return 1
  fi
}'  # Get public IP address

alias net-ipinfo='() {
  if ! _check_command_network_aliases curl; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_network_aliases "Get IP information.\nUsage:\n net-ipinfo [ip_address:current]"

    if ! curl -s ipinfo.io; then
      _show_error_network_aliases "Failed to retrieve IP information. Check your internet connection."
      return 1
    fi
  else
    if ! curl -s ipinfo.io/${1}; then
      _show_error_network_aliases "Failed to retrieve IP information for ${1}. Check the IP address and your internet connection."
      return 1
    fi
  fi
}'  # Get IP information for your IP or specified address

alias net-domainip='() {
  if ! _check_command_network_aliases dig; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_network_aliases "Get IP address for a domain.\nUsage:\n net-domainip <domain>"
    return 1
  fi

  echo "IP address for $1:"
  if ! dig +short "$1"; then
    _show_error_network_aliases "Failed to resolve domain '$1'. Check the domain name and your DNS configuration."
    return 1
  fi
}'  # Get IP address for a domain name

#===================================
# Network connectivity testing
#===================================

alias net-ping='() {
  if ! _check_command_network_aliases ping; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_network_aliases "Ping a host with 5 attempts.\nUsage:\n net-ping <host>"
    return 1
  fi

  echo "Pinging $1 (5 attempts)..."
  ping -c 5 "$@"

  if [ $? -ne 0 ]; then
    _show_error_network_aliases "Failed to ping $1. Check the hostname and your network connection."
    return 1
  fi
}'  # Limit ping to 5 attempts

alias net-port-test='() {
  if ! _check_command_network_aliases nc; then
    return 1
  fi

  if [ $# -lt 2 ]; then
    _show_usage_network_aliases "Test port connectivity using netcat.\nUsage:\n net-port-test <host> <port>"
    return 1
  fi

  echo "Testing connection to $1:$2..."
  if ! nc -zv "$1" "$2" 2>&1; then
    _show_error_network_aliases "Connection to $1:$2 failed. Check the host, port, and your network connection."
    return 1
  fi
}'  # Test if a port is open using netcat

alias net-ports='() {
  if ! _check_command_network_aliases lsof; then
    return 1
  fi

  _show_usage_network_aliases "Listing all network connections..."

  if ! lsof -i -P; then
    _show_error_network_aliases "Failed to list network connections. Check if you have sufficient permissions."
    return 1
  fi
}'  # List all network connections

alias net-port-usage='() {
  if ! _check_command_network_aliases lsof; then
    return 1
  fi

  _show_usage_network_aliases "Showing port usage information..."

  if ! lsof -n -P -i; then
    _show_error_network_aliases "Failed to show port usage information. Check if you have sufficient permissions."
    return 1
  fi
}'  # Show port usage information

alias net-listening='() {
  if ! _check_command_network_aliases lsof; then
    return 1
  fi

  _show_usage_network_aliases "Listing all listening ports..."

  if ! lsof -i -P -n | grep LISTEN; then
    echo "No listening ports found."
  fi
}'  # List all listening ports

alias net-devices='() {
  if ! _check_command_network_aliases arp; then
    return 1
  fi

  _show_usage_network_aliases "Showing devices on local network..."

  if ! arp -a; then
    _show_error_network_aliases "Failed to list devices on local network."
    return 1
  fi
}'  # Show devices on local network

alias net-bandwidth='() {
  if ! _check_command_network_aliases iftop; then
    return 1
  fi

  _show_usage_network_aliases "Monitor network bandwidth.\nUsage:\n net-bandwidth [interface]"

  echo "Monitoring network bandwidth. Press q to quit."
  if [ $# -eq 0 ]; then
    iftop
  else
    iftop -i "$1"
  fi
}'  # Monitor network bandwidth

alias net-watch='() {
  if ! _check_command_network_aliases watch; then
    return 1
  fi

  if ! _check_command_network_aliases iftop; then
    return 1
  fi

  _show_usage_network_aliases "Real-time network traffic monitoring. Press Ctrl+C to quit."

  watch -d -n 1 "iftop -t -s 1"
}'  # Real-time network traffic monitoring

# File Downloads and HTTP Operations
alias net-download='() {
  if ! _check_command_network_aliases wget; then
    return 1
  fi

  if [ $# -lt 2 ]; then
    _show_usage_network_aliases "Download file from URL.\nUsage:\n net-download <url> <output_path>"
    return 1
  fi

  echo "Downloading $1 to $2..."
  if ! wget --no-check-certificate --progress=bar:force "$1" -O "$2"; then
    _show_error_network_aliases "Download failed. Check the URL and your internet connection."
    return 1
  fi
  echo -e "\nDownload complete, saved to $2"
}'  # Download file from URL

alias net-download-all='() {
  if ! _check_command_network_aliases wget; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_network_aliases "Download all files from URL list file.\nUsage:\n net-download-all <url_list_file> [output_directory:./download]"
    return 1
  fi

  if [ ! -f "$1" ]; then
    _show_error_network_aliases "Error: File $1 not found."
    return 1
  fi

  local output_dir="${2:-./download}"

  echo "Downloading files from list in $1 to $output_dir..."
  if ! mkdir -p "$output_dir"; then
    _show_error_network_aliases "Failed to create output directory: $output_dir"
    return 1
  fi

  if ! cat "$1" | xargs -n1 wget -P "$output_dir" --no-check-certificate --progress=bar:force; then
    _show_error_network_aliases "Some downloads failed. Check the URLs and your internet connection."
    return 1
  fi
  echo "Download complete, files saved in $output_dir directory"
}'  # Download all files from a list of URLs

alias net-get='() {
  if ! _check_command_network_aliases curl; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_network_aliases "Send HTTP GET request.\nUsage:\n net-get <url> [curl_options]"
    return 1
  fi

  if ! curl -sS "$@"; then
    _show_error_network_aliases "GET request failed. Check the URL and your internet connection."
    return 1
  fi
}'  # Send GET request

alias net-post='() {
  if ! _check_command_network_aliases curl; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_network_aliases "Send HTTP POST request.\nUsage:\n net-post <url> [data] [curl_options]"
    return 1
  fi

  if ! curl -sSX POST "$@"; then
    _show_error_network_aliases "POST request failed. Check the URL, data format, and your internet connection."
    return 1
  fi
}'  # Send POST request

alias net-headers='() {
  if ! _check_command_network_aliases curl; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_network_aliases "Get HTTP headers only.\nUsage:\n net-headers <url> [curl_options]"
    return 1
  fi

  if ! curl -I "$@"; then
    _show_error_network_aliases "Failed to retrieve HTTP headers. Check the URL and your internet connection."
    return 1
  fi
}'  # Get HTTP headers only

# DNS Operations
alias net-flush-dns='() {
  _show_usage_network_aliases "Flush DNS cache on the system."

  echo "Flushing DNS cache..."
  if [ "$(uname)" = "Darwin" ]; then
    if ! sudo killall -HUP mDNSResponder; then
      _show_error_network_aliases "Failed to flush DNS cache on macOS."
      return 1
    fi
    echo "DNS cache flushed (macOS)"
  elif [ -f /etc/debian_version ]; then
    if ! sudo systemd-resolve --flush-caches; then
      _show_error_network_aliases "Failed to flush DNS cache on Debian/Ubuntu."
      return 1
    fi
    echo "DNS cache flushed (Debian/Ubuntu)"
  elif [ -f /etc/redhat-release ]; then
    if ! sudo systemctl restart nscd; then
      _show_error_network_aliases "Failed to flush DNS cache on RHEL/CentOS."
      return 1
    fi
    echo "DNS cache flushed (RHEL/CentOS)"
  else
    _show_error_network_aliases "Error: Unsupported operating system."
    return 1
  fi
}'  # Flush DNS cache

alias net-dns-lookup='() {
  if ! _check_command_network_aliases dig; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_network_aliases "DNS lookup for domain.\nUsage:\n net-dns-lookup <domain> [record_type:A]"
    return 1
  fi

  local domain="$1"
  local record="${2:-A}"

  echo "Looking up DNS $record records for $domain..."
  if ! dig +short "$domain" "$record"; then
    _show_error_network_aliases "Failed to lookup DNS records for '$domain'. Check the domain name and DNS record type."
    return 1
  fi
}'  # Look up DNS records for a domain

# Network Interfaces Information
alias net-interfaces='() {
  _show_usage_network_aliases "Show all network interfaces."

  if [ "$(uname)" = "Darwin" ]; then
    if ! ifconfig; then
      _show_error_network_aliases "Failed to list network interfaces on macOS."
      return 1
    fi
  else
    if ! ip addr show; then
      # Fallback to ifconfig if ip command fails
      if ! ifconfig; then
        _show_error_network_aliases "Failed to list network interfaces."
        return 1
      fi
    fi
  fi
}'  # Show all network interfaces

alias net-ips='() {
  _show_usage_network_aliases "Show all IP addresses for this device."

  if [ "$(uname)" = "Darwin" ]; then
    if ! ifconfig | grep "inet " | grep -v 127.0.0.1 | awk "{print \$2}"; then
      _show_error_network_aliases "Failed to list IP addresses on macOS."
      return 1
    fi
  else
    if ! ip -4 addr show | grep -oP "(?<=inet ).*(?=/)" | grep -v 127.0.0.1; then
      # Fallback to ifconfig if ip command fails
      if ! ifconfig | grep "inet " | grep -v 127.0.0.1 | awk "{print \$2}"; then
        _show_error_network_aliases "Failed to list IP addresses."
        return 1
      fi
    fi
  fi
}'  # Show all IP addresses for this device

alias net-routes='() {
  _show_usage_network_aliases "Show routing table."

  if [ "$(uname)" = "Darwin" ]; then
    if ! netstat -rn; then
      _show_error_network_aliases "Failed to show routing table on macOS."
      return 1
    fi
  else
    if ! ip route; then
      # Fallback to route if ip command fails
      if ! route -n; then
        _show_error_network_aliases "Failed to show routing table."
        return 1
      fi
    fi
  fi
}'  # Show routing table

alias net-stats='() {
  _show_usage_network_aliases "Show network statistics."

  if ! _check_command_network_aliases netstat; then
    return 1
  fi

  if ! netstat -s; then
    _show_error_network_aliases "Failed to show network statistics."
    return 1
  fi
}'  # Show network statistics

alias net-scan='() {
  if ! _check_command_network_aliases nmap; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_network_aliases "Scan network for devices.\nUsage:\n net-scan <network_range>\nExample: net-scan 192.168.1.0/24"
    return 1
  fi

  echo "Scanning network $1..."
  if ! nmap -sn "$1"; then
    _show_error_network_aliases "Network scan failed. Check the network range and your permissions."
    return 1
  fi
}'  # Scan network for devices

alias net-mtr='() {
  if ! _check_command_network_aliases mtr; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_network_aliases "Run MTR (My Traceroute).\nUsage:\n net-mtr <hostname/ip>"
    return 1
  fi

  echo "Running MTR to $1..."
  if ! mtr -n "$1"; then
    _show_error_network_aliases "MTR failed. Check the hostname/IP and your network connection."
    return 1
  fi
}'  # Run MTR (My Traceroute)

alias net-speed='() {
  if ! _check_command_network_aliases speedtest-cli; then
    _show_error_network_aliases "speedtest-cli is not installed. Install with: pip install speedtest-cli"
    return 1
  fi

  _show_usage_network_aliases "Test internet connection speed."

  echo "Testing internet connection speed..."
  if ! speedtest-cli --simple; then
    _show_error_network_aliases "Speed test failed. Check your internet connection."
    return 1
  fi
}'  # Test internet connection speed

alias net-open-ports='() {
  if ! _check_command_network_aliases nmap; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_network_aliases "Scan for open ports on a host.\nUsage:\n net-open-ports <host> [port_range:1-1000]"
    return 1
  fi

  local host="$1"
  local port_range="${2:-1-1000}"

  echo "Scanning $host for open ports in range $port_range..."
  if ! nmap -p "$port_range" "$host"; then
    _show_error_network_aliases "Port scan failed. Check the hostname and your network connection."
    return 1
  fi
}'  # Scan for open ports on a host

alias net-wifi-networks='() {
  _show_usage_network_aliases "Show available WiFi networks."

  if [ "$(uname)" = "Darwin" ]; then
    if ! /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -s; then
      _show_error_network_aliases "Failed to list WiFi networks on macOS."
      return 1
    fi
  else
    if ! _check_command_network_aliases nmcli; then
      if ! _check_command_network_aliases iwlist; then
        _show_error_network_aliases "Required commands not found. Install NetworkManager or wireless-tools."
        return 1
      fi
      if ! sudo iwlist scan | grep ESSID; then
        _show_error_network_aliases "Failed to scan WiFi networks with iwlist."
        return 1
      fi
    else
      if ! nmcli device wifi list; then
        _show_error_network_aliases "Failed to list WiFi networks."
        return 1
      fi
    fi
  fi
}'  # Show available WiFi networks

alias net-wifi-status='() {
  _show_usage_network_aliases "Show current WiFi connection status."

  if [ "$(uname)" = "Darwin" ]; then
    if ! /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I; then
      _show_error_network_aliases "Failed to get WiFi status on macOS."
      return 1
    fi
  else
    if ! _check_command_network_aliases nmcli; then
      if ! _check_command_network_aliases iwconfig; then
        _show_error_network_aliases "Required commands not found. Install NetworkManager or wireless-tools."
        return 1
      fi
      if ! iwconfig; then
        _show_error_network_aliases "Failed to get WiFi status with iwconfig."
        return 1
      fi
    else
      if ! nmcli device wifi; then
        _show_error_network_aliases "Failed to get WiFi status."
        return 1
      fi
    fi
  fi
}'  # Show current WiFi connection status

# Help function for Network aliases
alias net-help='() {
  echo "Network Aliases Help"
  echo "===================="
  echo "Available commands:"
  echo "  net-myip          - Get your public IP address"
  echo "  net-ipinfo        - Get IP information for your IP or specified address"
  echo "  net-domainip      - Get IP address for a domain name"
  echo "  net-ping          - Ping a host with 5 attempts"
  echo "  net-port-test     - Test if a port is open using netcat"
  echo "  net-ports         - List all network connections"
  echo "  net-port-usage    - Show port usage information"
  echo "  net-listening     - List all listening ports"
  echo "  net-devices       - Show devices on local network"
  echo "  net-bandwidth     - Monitor network bandwidth"
  echo "  net-watch         - Real-time network traffic monitoring"
  echo "  net-download      - Download file from URL"
  echo "  net-download-all  - Download all files from a list of URLs"
  echo "  net-get           - Send GET request"
  echo "  net-post          - Send POST request"
  echo "  net-headers       - Get HTTP headers only"
  echo "  net-flush-dns     - Flush DNS cache"
  echo "  net-dns-lookup    - Look up DNS records for a domain"
  echo "  net-interfaces    - Show all network interfaces"
  echo "  net-ips           - Show all IP addresses for this device"
  echo "  net-routes        - Show routing table"
  echo "  net-stats         - Show network statistics"
  echo "  net-scan          - Scan network for devices"
  echo "  net-mtr           - Run MTR (My Traceroute)"
  echo "  net-speed         - Test internet connection speed"
  echo "  net-open-ports    - Scan for open ports on a host"
  echo "  net-wifi-networks - Show available WiFi networks"
  echo "  net-wifi-status   - Show current WiFi connection status"
  echo "  net-help          - Display this help message"
  echo
  echo "For detailed usage information, run any command without arguments or with -h/--help flag"
