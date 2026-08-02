# Description: Domain related aliases for DNS queries, domain analysis, connectivity checks, WHOIS lookups and domain management tools.

# Helper functions for domain aliases
_show_error_domain_aliases() {
  echo "$1" >&2
  return 1
}

_show_usage_domain_aliases() {
  echo -e "$1"
  return 0
}

_check_command_domain_aliases() {
  if ! command -v "$1" &> /dev/null; then
    _show_error_domain_aliases "Error: Required command \"$1\" not found. Please install it first."
    return 1
  fi
  return 0
}

_validate_domain_domain_aliases() {
  local domain_name="$1"
  if [[ -z "$domain_name" ]]; then
    return 1
  fi

  # Basic domain validation - check for valid characters and structure
  if [[ ! "$domain_name" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
    return 1
  fi

  return 0
}

_format_dns_output_domain_aliases() {
  local record_type="$1"
  local domain_name="$2"
  local output="$3"

  if [[ -n "$output" ]]; then
    echo "=== $record_type Records for $domain_name ==="
    echo "$output"
    echo ""
  else
    echo "No $record_type records found for $domain_name"
    echo ""
  fi
}

#===================================
# DNS Query Operations
#===================================

alias domain-dns='() {
  if ! _check_command_domain_aliases dig; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_domain_aliases "Perform comprehensive DNS lookup for a domain.\nUsage:\n domain-dns <domain> [record_type:ALL]\nExamples:\n domain-dns google.com\n domain-dns google.com A\n domain-dns google.com MX"
    return 1
  fi

  local domain_name="$1"
  local record_type="${2:-ALL}"

  if ! _validate_domain_domain_aliases "$domain_name"; then
    _show_error_domain_aliases "Error: Invalid domain name format: $domain_name"
    return 1
  fi

  echo "DNS Lookup for: $domain_name"
  echo "================================"

  if [[ "$record_type" == "ALL" ]]; then
    # Query all common record types
    local record_types=("A" "AAAA" "MX" "NS" "TXT" "CNAME" "SOA")

    for rtype in "${record_types[@]}"; do
      local result
      result=$(dig +short "$domain_name" "$rtype" 2>/dev/null)
      _format_dns_output_domain_aliases "$rtype" "$domain_name" "$result"
    done
  else
    local result
    result=$(dig +short "$domain_name" "$record_type" 2>/dev/null)
    if [[ $? -ne 0 ]]; then
      _show_error_domain_aliases "DNS query failed for $domain_name ($record_type)"
      return 1
    fi
    _format_dns_output_domain_aliases "$record_type" "$domain_name" "$result"
  fi
}'  # Perform comprehensive DNS lookup for a domain

alias domain-a='() {
  if ! _check_command_domain_aliases dig; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_domain_aliases "Get A records (IPv4 addresses) for a domain.\nUsage:\n domain-a <domain>\nExample:\n domain-a google.com"
    return 1
  fi

  local domain_name="$1"

  if ! _validate_domain_domain_aliases "$domain_name"; then
    _show_error_domain_aliases "Error: Invalid domain name format: $domain_name"
    return 1
  fi

  echo "A Records for $domain_name:"
  if ! dig +short "$domain_name" A; then
    _show_error_domain_aliases "Failed to query A records for $domain_name"
    return 1
  fi
}'  # Get A records (IPv4 addresses) for a domain

alias domain-aaaa='() {
  if ! _check_command_domain_aliases dig; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_domain_aliases "Get AAAA records (IPv6 addresses) for a domain.\nUsage:\n domain-aaaa <domain>\nExample:\n domain-aaaa google.com"
    return 1
  fi

  local domain_name="$1"

  if ! _validate_domain_domain_aliases "$domain_name"; then
    _show_error_domain_aliases "Error: Invalid domain name format: $domain_name"
    return 1
  fi

  echo "AAAA Records for $domain_name:"
  if ! dig +short "$domain_name" AAAA; then
    _show_error_domain_aliases "Failed to query AAAA records for $domain_name"
    return 1
  fi
}'  # Get AAAA records (IPv6 addresses) for a domain

alias domain-mx='() {
  if ! _check_command_domain_aliases dig; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_domain_aliases "Get MX records (mail servers) for a domain.\nUsage:\n domain-mx <domain>\nExample:\n domain-mx google.com"
    return 1
  fi

  local domain_name="$1"

  if ! _validate_domain_domain_aliases "$domain_name"; then
    _show_error_domain_aliases "Error: Invalid domain name format: $domain_name"
    return 1
  fi

  echo "MX Records for $domain_name:"
  if ! dig +short "$domain_name" MX; then
    _show_error_domain_aliases "Failed to query MX records for $domain_name"
    return 1
  fi
}'  # Get MX records (mail servers) for a domain

alias domain-ns='() {
  if ! _check_command_domain_aliases dig; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_domain_aliases "Get NS records (name servers) for a domain.\nUsage:\n domain-ns <domain>\nExample:\n domain-ns google.com"
    return 1
  fi

  local domain_name="$1"

  if ! _validate_domain_domain_aliases "$domain_name"; then
    _show_error_domain_aliases "Error: Invalid domain name format: $domain_name"
    return 1
  fi

  echo "NS Records for $domain_name:"
  if ! dig +short "$domain_name" NS; then
    _show_error_domain_aliases "Failed to query NS records for $domain_name"
    return 1
  fi
}'  # Get NS records (name servers) for a domain

alias domain-txt='() {
  if ! _check_command_domain_aliases dig; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_domain_aliases "Get TXT records for a domain.\nUsage:\n domain-txt <domain>\nExample:\n domain-txt google.com"
    return 1
  fi

  local domain_name="$1"

  if ! _validate_domain_domain_aliases "$domain_name"; then
    _show_error_domain_aliases "Error: Invalid domain name format: $domain_name"
    return 1
  fi

  echo "TXT Records for $domain_name:"
  if ! dig +short "$domain_name" TXT; then
    _show_error_domain_aliases "Failed to query TXT records for $domain_name"
    return 1
  fi
}'  # Get TXT records for a domain

alias domain-cname='() {
  if ! _check_command_domain_aliases dig; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_domain_aliases "Get CNAME records for a domain.\nUsage:\n domain-cname <domain>\nExample:\n domain-cname www.google.com"
    return 1
  fi

  local domain_name="$1"

  if ! _validate_domain_domain_aliases "$domain_name"; then
    _show_error_domain_aliases "Error: Invalid domain name format: $domain_name"
    return 1
  fi

  echo "CNAME Records for $domain_name:"
  if ! dig +short "$domain_name" CNAME; then
    _show_error_domain_aliases "Failed to query CNAME records for $domain_name"
    return 1
  fi
}'  # Get CNAME records for a domain

alias domain-soa='() {
  if ! _check_command_domain_aliases dig; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_domain_aliases "Get SOA record (Start of Authority) for a domain.\nUsage:\n domain-soa <domain>\nExample:\n domain-soa google.com"
    return 1
  fi

  local domain_name="$1"

  if ! _validate_domain_domain_aliases "$domain_name"; then
    _show_error_domain_aliases "Error: Invalid domain name format: $domain_name"
    return 1
  fi

  echo "SOA Record for $domain_name:"
  if ! dig +short "$domain_name" SOA; then
    _show_error_domain_aliases "Failed to query SOA record for $domain_name"
    return 1
  fi
}'  # Get SOA record (Start of Authority) for a domain

alias domain-reverse='() {
  if ! _check_command_domain_aliases dig; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_domain_aliases "Perform reverse DNS lookup for an IP address.\nUsage:\n domain-reverse <ip_address>\nExample:\n domain-reverse 8.8.8.8"
    return 1
  fi

  local ip_address="$1"

  # Basic IP validation
  if [[ ! "$ip_address" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    _show_error_domain_aliases "Error: Invalid IP address format: $ip_address"
    return 1
  fi

  echo "Reverse DNS lookup for $ip_address:"
  if ! dig +short -x "$ip_address"; then
    _show_error_domain_aliases "Failed to perform reverse DNS lookup for $ip_address"
    return 1
  fi
}'  # Perform reverse DNS lookup for an IP address

#===================================
# Domain Analysis and Information
#===================================

alias domain-whois='() {
  if ! _check_command_domain_aliases whois; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_domain_aliases "Get WHOIS information for a domain.\nUsage:\n domain-whois <domain>\nExample:\n domain-whois google.com"
    return 1
  fi

  local domain_name="$1"

  if ! _validate_domain_domain_aliases "$domain_name"; then
    _show_error_domain_aliases "Error: Invalid domain name format: $domain_name"
    return 1
  fi

  echo "WHOIS Information for $domain_name:"
  echo "=================================="
  if ! whois "$domain_name"; then
    _show_error_domain_aliases "Failed to retrieve WHOIS information for $domain_name"
    return 1
  fi
}'  # Get WHOIS information for a domain

alias domain-info='() {
  if ! _check_command_domain_aliases dig; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_domain_aliases "Get comprehensive domain information including DNS records and basic analysis.\nUsage:\n domain-info <domain>\nExample:\n domain-info google.com"
    return 1
  fi

  local domain_name="$1"

  if ! _validate_domain_domain_aliases "$domain_name"; then
    _show_error_domain_aliases "Error: Invalid domain name format: $domain_name"
    return 1
  fi

  echo "Domain Information for: $domain_name"
  echo "===================================="
  echo ""

  # Get A records
  local a_records
  a_records=$(dig +short "$domain_name" A 2>/dev/null)
  _format_dns_output_domain_aliases "A" "$domain_name" "$a_records"

  # Get AAAA records
  local aaaa_records
  aaaa_records=$(dig +short "$domain_name" AAAA 2>/dev/null)
  _format_dns_output_domain_aliases "AAAA" "$domain_name" "$aaaa_records"

  # Get MX records
  local mx_records
  mx_records=$(dig +short "$domain_name" MX 2>/dev/null)
  _format_dns_output_domain_aliases "MX" "$domain_name" "$mx_records"

  # Get NS records
  local ns_records
  ns_records=$(dig +short "$domain_name" NS 2>/dev/null)
  _format_dns_output_domain_aliases "NS" "$domain_name" "$ns_records"

  # Get TXT records
  local txt_records
  txt_records=$(dig +short "$domain_name" TXT 2>/dev/null)
  _format_dns_output_domain_aliases "TXT" "$domain_name" "$txt_records"

  # Additional information
  echo "=== Additional Information ==="
  if command -v host &> /dev/null; then
    echo "Host command output:"
    host "$domain_name" 2>/dev/null || echo "Host command failed"
  fi
}'  # Get comprehensive domain information including DNS records and basic analysis

alias domain-trace='() {
  if ! _check_command_domain_aliases dig; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_domain_aliases "Trace DNS resolution path for a domain.\nUsage:\n domain-trace <domain>\nExample:\n domain-trace google.com"
    return 1
  fi

  local domain_name="$1"

  if ! _validate_domain_domain_aliases "$domain_name"; then
    _show_error_domain_aliases "Error: Invalid domain name format: $domain_name"
    return 1
  fi

  echo "DNS Resolution Trace for $domain_name:"
  echo "====================================="
  if ! dig +trace "$domain_name"; then
    _show_error_domain_aliases "Failed to trace DNS resolution for $domain_name"
    return 1
  fi
}'  # Trace DNS resolution path for a domain

alias domain-propagation='() {
  if ! _check_command_domain_aliases dig; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_domain_aliases "Check DNS propagation across multiple DNS servers.\nUsage:\n domain-propagation <domain> [record_type:A]\nExample:\n domain-propagation google.com A"
    return 1
  fi

  local domain_name="$1"
  local record_type="${2:-A}"

  if ! _validate_domain_domain_aliases "$domain_name"; then
    _show_error_domain_aliases "Error: Invalid domain name format: $domain_name"
    return 1
  fi

  echo "DNS Propagation Check for $domain_name ($record_type records):"
  echo "============================================================"

  # List of popular DNS servers
  local dns_servers=(
    "8.8.8.8@Google"
    "1.1.1.1@Cloudflare"
    "208.67.222.222@OpenDNS"
    "9.9.9.9@Quad9"
    "8.26.56.26@Comodo"
    "64.6.64.6@Verisign"
  )

  for server_info in "${dns_servers[@]}"; do
    local server="${server_info%@*}"
    local provider="${server_info#*@}"

    echo ""
    echo "Checking $provider ($server):"
    echo "----------------------------"

    local result
    result=$(dig @"$server" +short "$domain_name" "$record_type" 2>/dev/null)

    if [[ $? -eq 0 && -n "$result" ]]; then
      echo "$result"
    else
      echo "No records found or query failed"
    fi
  done
}'  # Check DNS propagation across multiple DNS servers

#===================================
# Connectivity and Performance Testing
#===================================

alias domain-ping='() {
  if ! _check_command_domain_aliases ping; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_domain_aliases "Ping a domain with specified count.\nUsage:\n domain-ping <domain> [count:5]\nExample:\n domain-ping google.com 10"
    return 1
  fi

  local domain_name="$1"
  local count="${2:-5}"

  if ! _validate_domain_domain_aliases "$domain_name"; then
    _show_error_domain_aliases "Error: Invalid domain name format: $domain_name"
    return 1
  fi

  # Validate count is a positive number
  if ! [[ "$count" =~ ^[0-9]+$ ]] || [ "$count" -lt 1 ]; then
    _show_error_domain_aliases "Error: Count must be a positive integer"
    return 1
  fi

  echo "Pinging $domain_name ($count packets):"
  if ! ping -c "$count" "$domain_name"; then
    _show_error_domain_aliases "Failed to ping $domain_name"
    return 1
  fi
}'  # Ping a domain with specified count

alias domain-traceroute='() {
  local traceroute_cmd=""

  # Check for available traceroute command
  if command -v traceroute &> /dev/null; then
    traceroute_cmd="traceroute"
  elif command -v tracert &> /dev/null; then
    traceroute_cmd="tracert"
  else
    _show_error_domain_aliases "Error: Neither traceroute nor tracert command found"
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_domain_aliases "Trace network route to a domain.\nUsage:\n domain-traceroute <domain>\nExample:\n domain-traceroute google.com"
    return 1
  fi

  local domain_name="$1"

  if ! _validate_domain_domain_aliases "$domain_name"; then
    _show_error_domain_aliases "Error: Invalid domain name format: $domain_name"
    return 1
  fi

  echo "Tracing route to $domain_name:"
  if ! "$traceroute_cmd" "$domain_name"; then
    _show_error_domain_aliases "Failed to trace route to $domain_name"
    return 1
  fi
}'  # Trace network route to a domain

alias domain-mtr='() {
  if ! _check_command_domain_aliases mtr; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_domain_aliases "Run MTR (My Traceroute) to a domain.\nUsage:\n domain-mtr <domain> [count:10]\nExample:\n domain-mtr google.com 20"
    return 1
  fi

  local domain_name="$1"
  local count="${2:-10}"

  if ! _validate_domain_domain_aliases "$domain_name"; then
    _show_error_domain_aliases "Error: Invalid domain name format: $domain_name"
    return 1
  fi

  # Validate count is a positive number
  if ! [[ "$count" =~ ^[0-9]+$ ]] || [ "$count" -lt 1 ]; then
    _show_error_domain_aliases "Error: Count must be a positive integer"
    return 1
  fi

  echo "Running MTR to $domain_name ($count cycles):"
  if ! mtr -c "$count" "$domain_name"; then
    _show_error_domain_aliases "Failed to run MTR to $domain_name"
    return 1
  fi
}'  # Run MTR (My Traceroute) to a domain

alias domain-port='() {
  if ! _check_command_domain_aliases nc; then
    return 1
  fi

  if [ $# -lt 2 ]; then
    _show_usage_domain_aliases "Test port connectivity for a domain.\nUsage:\n domain-port <domain> <port> [timeout:5]\nExample:\n domain-port google.com 80 10"
    return 1
  fi

  local domain_name="$1"
  local port="$2"
  local timeout="${3:-5}"

  if ! _validate_domain_domain_aliases "$domain_name"; then
    _show_error_domain_aliases "Error: Invalid domain name format: $domain_name"
    return 1
  fi

  # Validate port is a number between 1 and 65535
  if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    _show_error_domain_aliases "Error: Port must be a number between 1 and 65535"
    return 1
  fi

  # Validate timeout is a positive number
  if ! [[ "$timeout" =~ ^[0-9]+$ ]] || [ "$timeout" -lt 1 ]; then
    _show_error_domain_aliases "Error: Timeout must be a positive integer"
    return 1
  fi

  echo "Testing connection to $domain_name:$port (timeout: ${timeout}s):"
  if nc -zv -w "$timeout" "$domain_name" "$port" 2>&1; then
    echo "Connection successful!"
  else
    _show_error_domain_aliases "Connection failed to $domain_name:$port"
    return 1
  fi
}'  # Test port connectivity for a domain

alias domain-ports='() {
  if ! _check_command_domain_aliases nmap; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_domain_aliases "Scan common ports on a domain.\nUsage:\n domain-ports <domain> [port_range:1-1000]\nExample:\n domain-ports google.com 80-443"
    return 1
  fi

  local domain_name="$1"
  local port_range="${2:-1-1000}"

  if ! _validate_domain_domain_aliases "$domain_name"; then
    _show_error_domain_aliases "Error: Invalid domain name format: $domain_name"
    return 1
  fi

  echo "Scanning ports on $domain_name (range: $port_range):"
  if ! nmap -p "$port_range" "$domain_name"; then
    _show_error_domain_aliases "Port scan failed for $domain_name"
    return 1
  fi
}'  # Scan common ports on a domain

#===================================
# SSL/TLS Certificate Information
#===================================

alias domain-ssl='() {
  if ! _check_command_domain_aliases openssl; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_domain_aliases "Get SSL certificate information for a domain.\nUsage:\n domain-ssl <domain> [port:443]\nExample:\n domain-ssl google.com 443"
    return 1
  fi

  local domain_name="$1"
  local port="${2:-443}"

  if ! _validate_domain_domain_aliases "$domain_name"; then
    _show_error_domain_aliases "Error: Invalid domain name format: $domain_name"
    return 1
  fi

  # Validate port is a number between 1 and 65535
  if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    _show_error_domain_aliases "Error: Port must be a number between 1 and 65535"
    return 1
  fi

  echo "SSL Certificate Information for $domain_name:$port:"
  echo "================================================="

  # Get certificate information
  local cert_info
  cert_info=$(echo | openssl s_client -servername "$domain_name" -connect "$domain_name:$port" 2>/dev/null | openssl x509 -noout -text 2>/dev/null)

  if [[ $? -ne 0 || -z "$cert_info" ]]; then
    _show_error_domain_aliases "Failed to retrieve SSL certificate information for $domain_name:$port"
    return 1
  fi

  # Extract and display key information
  echo "Subject:"
  echo "$cert_info" | grep "Subject:" | head -1
  echo ""

  echo "Issuer:"
  echo "$cert_info" | grep "Issuer:" | head -1
  echo ""

  echo "Validity:"
  echo "$cert_info" | grep -A 2 "Validity"
  echo ""

  echo "Subject Alternative Names:"
  echo "$cert_info" | grep -A 1 "Subject Alternative Name" | tail -1 || echo "None found"
  echo ""

  # Check certificate expiration
  local expiry_date
  expiry_date=$(echo | openssl s_client -servername "$domain_name" -connect "$domain_name:$port" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)

  if [[ -n "$expiry_date" ]]; then
    echo "Certificate expires: $expiry_date"

    # Calculate days until expiration
    if command -v date &> /dev/null; then
      local expiry_epoch
      local current_epoch
      local days_until_expiry

      if [[ "$(uname)" == "Darwin" ]]; then
        expiry_epoch=$(date -j -f "%b %d %H:%M:%S %Y %Z" "$expiry_date" "+%s" 2>/dev/null)
      else
        expiry_epoch=$(date -d "$expiry_date" "+%s" 2>/dev/null)
      fi

      if [[ -n "$expiry_epoch" ]]; then
        current_epoch=$(date "+%s")
        days_until_expiry=$(( (expiry_epoch - current_epoch) / 86400 ))

        if [[ $days_until_expiry -gt 0 ]]; then
          echo "Days until expiration: $days_until_expiry"
        else
          echo "Certificate has expired!"
        fi
      fi
    fi
  fi
}'  # Get SSL certificate information for a domain

alias domain-ssl-check='() {
  if ! _check_command_domain_aliases openssl; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_domain_aliases "Quick SSL certificate validity check for a domain.\nUsage:\n domain-ssl-check <domain> [port:443]\nExample:\n domain-ssl-check google.com 443"
    return 1
  fi

  local domain_name="$1"
  local port="${2:-443}"

  if ! _validate_domain_domain_aliases "$domain_name"; then
    _show_error_domain_aliases "Error: Invalid domain name format: $domain_name"
    return 1
  fi

  # Validate port is a number between 1 and 65535
  if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    _show_error_domain_aliases "Error: Port must be a number between 1 and 65535"
    return 1
  fi

  echo "SSL Certificate Check for $domain_name:$port:"
  echo "============================================"

  # Test SSL connection and get basic info
  local ssl_output
  ssl_output=$(echo | openssl s_client -servername "$domain_name" -connect "$domain_name:$port" 2>&1)

  if [[ $? -ne 0 ]]; then
    _show_error_domain_aliases "Failed to connect to $domain_name:$port for SSL check"
    return 1
  fi

  # Check if connection was successful
  if echo "$ssl_output" | grep -q "Verify return code: 0 (ok)"; then
    echo "✓ SSL certificate is valid"
  else
    echo "✗ SSL certificate validation failed"
    echo "Error details:"
    echo "$ssl_output" | grep "Verify return code" || echo "Unknown error"
  fi

  # Extract and show expiration date
  local expiry_date
  expiry_date=$(echo "$ssl_output" | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)

  if [[ -n "$expiry_date" ]]; then
    echo "Certificate expires: $expiry_date"
  fi
}'  # Quick SSL certificate validity check for a domain

#===================================
# Domain Monitoring and Utilities
#===================================

alias domain-monitor='() {
  if ! _check_command_domain_aliases ping; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _show_usage_domain_aliases "Monitor domain connectivity with continuous ping.\nUsage:\n domain-monitor <domain> [interval:1]\nExample:\n domain-monitor google.com 5"
    return 1
  fi

  local domain_name="$1"
  local interval="${2:-1}"

  if ! _validate_domain_domain_aliases "$domain_name"; then
    _show_error_domain_aliases "Error: Invalid domain name format: $domain_name"
    return 1
  fi

  # Validate interval is a positive number
  if ! [[ "$interval" =~ ^[0-9]+$ ]] || [ "$interval" -lt 1 ]; then
    _show_error_domain_aliases "Error: Interval must be a positive integer"
    return 1
  fi

  echo "Starting domain monitoring for $domain_name (interval: ${interval}s)"
  echo "Press Ctrl+C to stop monitoring"
  echo "================================"

  while true; do
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    echo -n "$timestamp - $domain_name - "

    if ping -c 1 -W 3 "$domain_name" >/dev/null 2>&1; then
      echo "Status: UP"
    else
      echo "Status: DOWN"
    fi

    sleep "$interval"
  done
}'  # Monitor domain connectivity with continuous ping

alias domain-batch='() {
  if [ $# -eq 0 ]; then
    _show_usage_domain_aliases "Perform batch DNS lookup for multiple domains.\nUsage:\n domain-batch <domain1> [domain2] [domain3] ...\nExample:\n domain-batch google.com github.com stackoverflow.com"
    return 1
  fi

  echo "Batch Domain Lookup"
  echo "=================="
  echo ""

  for domain_name in "$@"; do
    if ! _validate_domain_domain_aliases "$domain_name"; then
      echo "Skipping invalid domain: $domain_name"
      continue
    fi

    echo "Domain: $domain_name"
    echo "-------------------"

    # Get A records
    local a_records
    a_records=$(dig +short "$domain_name" A 2>/dev/null)
    if [[ -n "$a_records" ]]; then
      echo "A Records: $a_records"
    else
      echo "A Records: None found"
    fi

    # Test connectivity
    if ping -c 1 -W 3 "$domain_name" >/dev/null 2>&1; then
      echo "Status: Reachable"
    else
      echo "Status: Unreachable"
    fi

    echo ""
  done
}'  # Perform batch DNS lookup for multiple domains

alias domain-compare='() {
  if [ $# -lt 2 ]; then
    _show_usage_domain_aliases "Compare DNS records between two domains.\nUsage:\n domain-compare <domain1> <domain2>\nExample:\n domain-compare google.com googl.com"
    return 1
  fi

  local domain1="$1"
  local domain2="$2"

  if ! _validate_domain_domain_aliases "$domain1"; then
    _show_error_domain_aliases "Error: Invalid domain name format: $domain1"
    return 1
  fi

  if ! _validate_domain_domain_aliases "$domain2"; then
    _show_error_domain_aliases "Error: Invalid domain name format: $domain2"
    return 1
  fi

  echo "Domain Comparison: $domain1 vs $domain2"
  echo "======================================="
  echo ""

  local record_types=("A" "AAAA" "MX" "NS" "TXT")

  for rtype in "${record_types[@]}"; do
    echo "$rtype Records:"
    echo "-------------"

    local records1
    local records2
    records1=$(dig +short "$domain1" "$rtype" 2>/dev/null | sort)
    records2=$(dig +short "$domain2" "$rtype" 2>/dev/null | sort)

    echo "$domain1:"
    if [[ -n "$records1" ]]; then
      echo "$records1"
    else
      echo "  (none)"
    fi

    echo "$domain2:"
    if [[ -n "$records2" ]]; then
      echo "$records2"
    else
      echo "  (none)"
    fi

    # Check if records are identical
    if [[ "$records1" == "$records2" ]]; then
      echo "Status: ✓ Identical"
    else
      echo "Status: ✗ Different"
    fi

    echo ""
  done
}'  # Compare DNS records between two domains

# Help function for Domain aliases
alias domain-help='() {
  echo "Domain Aliases Help"
  echo "=================="
  echo "Available commands:"
  echo ""
  echo "DNS Query Operations:"
  echo "  domain-dns          - Perform comprehensive DNS lookup for a domain"
  echo "  domain-a            - Get A records (IPv4 addresses) for a domain"
  echo "  domain-aaaa         - Get AAAA records (IPv6 addresses) for a domain"
  echo "  domain-mx           - Get MX records (mail servers) for a domain"
  echo "  domain-ns           - Get NS records (name servers) for a domain"
  echo "  domain-txt          - Get TXT records for a domain"
  echo "  domain-cname        - Get CNAME records for a domain"
  echo "  domain-soa          - Get SOA record (Start of Authority) for a domain"
  echo "  domain-reverse      - Perform reverse DNS lookup for an IP address"
  echo ""
  echo "Domain Analysis and Information:"
  echo "  domain-whois        - Get WHOIS information for a domain"
  echo "  domain-info         - Get comprehensive domain information"
  echo "  domain-trace        - Trace DNS resolution path for a domain"
  echo "  domain-propagation  - Check DNS propagation across multiple DNS servers"
  echo ""
  echo "Connectivity and Performance Testing:"
  echo "  domain-ping         - Ping a domain with specified count"
  echo "  domain-traceroute   - Trace network route to a domain"
  echo "  domain-mtr          - Run MTR (My Traceroute) to a domain"
  echo "  domain-port         - Test port connectivity for a domain"
  echo "  domain-ports        - Scan common ports on a domain"
  echo ""
  echo "SSL/TLS Certificate Information:"
  echo "  domain-ssl          - Get SSL certificate information for a domain"
  echo "  domain-ssl-check    - Quick SSL certificate validity check for a domain"
  echo ""
  echo "Domain Monitoring and Utilities:"
  echo "  domain-monitor      - Monitor domain connectivity with continuous ping"
  echo "  domain-batch        - Perform batch DNS lookup for multiple domains"
  echo "  domain-compare      - Compare DNS records between two domains"
  echo "  domain-help         - Display this help message"
  echo ""
  echo "For detailed usage information, run any command without arguments"
}' # Display help for domain aliases
