# Description: Network related aliases for connectivity testing, information gathering, port scanning, monitoring and downloads.

#===================================
# Network information aliases
#===================================

# Helper function for network aliases
_network_check_command() {
  if ! command -v "$1" &> /dev/null; then
    echo "Error: Required command '$1' not found. Please install it first." >&2
    return 1
  fi
  return 0
}

# Get public IP address
alias net_myip='() {
  echo "Getting public IP address..."
  if ! _network_check_command curl; then
    return 1
  fi
  curl -s ipinfo.io/ip
}'

# Get IP information for your IP or specified address
alias net_ipinfo='() {
  if ! _network_check_command curl; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Get IP information.\nUsage:\n net_ipinfo [ip_address]"
    curl -s ipinfo.io
  else
    curl -s ipinfo.io/${1}
  fi
}'

# Get IP address for a domain name
alias net_domainip='() {
  if ! _network_check_command dig; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Get IP address for a domain.\nUsage:\n net_domainip <domain>"
    return 1
  fi

  echo "IP address for $1:"
  dig +short "$1"
}'

#===================================
# Network connectivity testing
#===================================

# Limit ping to 5 attempts
alias net_ping='() {
  if ! _network_check_command ping; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Ping a host with 5 attempts.\nUsage:\n net_ping <host>"
    return 1
  fi

  ping -c 5 "$@"
}'

# Test if a port is open using netcat
alias net_port_test='() {
  if ! _network_check_command nc; then
    return 1
  fi

  if [ $# -lt 2 ]; then
    echo "Test port connectivity using netcat.\nUsage:\n net_port_test <host> <port>"
    return 1
  fi

  echo "Testing connection to $1:$2..."
  nc -zv "$1" "$2"
}'

#===================================
# Network port monitoring
#===================================

# List all network connections
alias net_ports='() {
  if ! _network_check_command lsof; then
    return 1
  fi

  echo "Listing all network connections..."
  lsof -i -P
}'

# Show port usage information
alias net_port_usage='() {
  if ! _network_check_command lsof; then
    return 1
  fi

  echo "Showing port usage information..."
  lsof -n -P -i
}'

# List all listening ports
alias net_listening='() {
  if ! _network_check_command lsof; then
    return 1
  fi

  echo "Listing all listening ports..."
  lsof -i -P -n | grep LISTEN
}'

#===================================
# Network devices
#===================================

# Show devices on local network
alias net_devices='() {
  if ! _network_check_command arp; then
    return 1
  fi

  echo "Showing devices on local network..."
  arp -a
}'

#===================================
# Network bandwidth monitoring
#===================================

# Monitor network bandwidth
alias net_bandwidth='() {
  if ! _network_check_command iftop; then
    return 1
  fi

  echo "Monitoring network bandwidth. Press q to quit."
  iftop
}'

# Real-time network traffic monitoring
alias net_watch='() {
  if ! _network_check_command iftop && ! _network_check_command watch; then
    return 1
  fi

  echo "Real-time network traffic monitoring. Press Ctrl+C to quit."
  watch -d -n 1 "iftop -t -s 1"
}'

#===================================
# Network downloads
#===================================

# Download file from URL
alias net_download='() {
  if ! _network_check_command wget; then
    return 1
  fi

  if [ $# -lt 2 ]; then
    echo "Download file from URL.\nUsage:\n net_download <url> <output_path>"
    return 1
  fi

  echo "Downloading $1 to $2..."
  wget --no-check-certificate --progress=bar:force "$1" -O "$2" &&
  echo -e "\nDownload complete, saved to $2"
}'

# Download all files from a list of URLs
alias net_download_all='() {
  if ! _network_check_command wget; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Download all files from URL list file.\nUsage:\n net_download_all <url_list_file>"
    return 1
  fi

  if [ ! -f "$1" ]; then
    echo "Error: File $1 not found." >&2
    return 1
  fi

  echo "Downloading files from list in $1..."
  mkdir -p ./download &&
  cat "$1" | xargs -n1 wget -P ./download --no-check-certificate --progress=bar:force &&
  echo "Download complete, files saved in ./download directory"
}'

#===================================
# HTTP requests
#===================================

# Send GET request
alias net_get='() {
  if ! _network_check_command curl; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Send HTTP GET request.\nUsage:\n net_get <url>"
    return 1
  fi

  curl -sS "$@"
}'

# Send POST request
alias net_post='() {
  if ! _network_check_command curl; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Send HTTP POST request.\nUsage:\n net_post <url> [data]"
    return 1
  fi

  curl -sSX POST "$@"
}'

# Get HTTP headers only
alias net_headers='() {
  if ! _network_check_command curl; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Get HTTP headers only.\nUsage:\n net_headers <url>"
    return 1
  fi

  curl -I "$@"
}'

#===================================
# DNS operations
#===================================

# Flush DNS cache (macOS)
alias net_flush_dns='() {
  echo "Flushing DNS cache..."
  if [ "$(uname)" = "Darwin" ]; then
    sudo killall -HUP mDNSResponder && echo "DNS cache flushed (macOS)"
  elif [ -f /etc/debian_version ]; then
    sudo systemd-resolve --flush-caches && echo "DNS cache flushed (Debian/Ubuntu)"
  elif [ -f /etc/redhat-release ]; then
    sudo systemctl restart nscd && echo "DNS cache flushed (RHEL/CentOS)"
  else
    echo "Error: Unsupported operating system." >&2
    return 1
  fi
}'

# Look up DNS records for a domain
alias net_dns_lookup='() {
  if ! _network_check_command dig; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "DNS lookup for domain.\nUsage:\n net_dns_lookup <domain>"
    return 1
  fi

  echo "Looking up DNS records for $1..."
  dig +short "$1"
}'
