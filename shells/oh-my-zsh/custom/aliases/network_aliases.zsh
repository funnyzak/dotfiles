# Description: Network related aliases for connectivity testing, information gathering, port scanning, monitoring and downloads.

# Network information
alias myip='curl -s ipinfo.io/ip'  # Get public IP address
alias ipinfo='() {
  if [ $# -eq 0 ]; then
    echo "Get IP information.\nUsage:\n ipinfo [ip_address]"
    curl -s ipinfo.io
  else
    curl -s ipinfo.io/${1}
  fi
}'  # Get IP information for your IP or specified address

alias domainip='dig +short'  # Get IP address for a domain name

# Network connectivity testing
alias ping='ping -c 5'  # Limit ping to 5 attempts
alias nc_zv='() {
  if [ $# -eq 0 ]; then
    echo "Test port connectivity using netcat.\nUsage:\n nc_zv <host> <port>"
    return 1
  else
    nc -zv $1 $2
  fi
}'  # Test if a port is open using netcat

# Network port monitoring
alias ports='lsof -i -P'  # List all network connections
alias portusage='lsof -n -P -i'  # Show port usage information
alias lsport='lsof -i -P -n | grep LISTEN'  # List all listening ports

# Network devices
alias networkdevices='arp -a'  # Show devices on local network

# Network bandwidth monitoring
alias bandwidth='iftop'  # Monitor network bandwidth
alias watchnet='watch -d -n 1 iftop -t -s 1'  # Real-time network traffic monitoring

# Network downloads
alias dl='() {
  if [ $# -eq 0 ]; then
    echo "Download file from URL.\nUsage:\n dl <url> <output_path>"
    return 1
  else
    wget --no-check-certificate --progress=bar:force $1 -O $2 && 
    echo -e "\nDownload complete, saved to $2"
  fi
}'  # Download file from URL

alias dl_all='() {
  if [ $# -eq 0 ]; then
    echo "Download all files from URL list file.\nUsage:\n dl_all <url_list_file>"
    return 1
  else
    mkdir -p ./download && 
    cat $1 | xargs -n1 wget -P ./download --no-check-certificate --progress=bar:force && 
    echo "Download complete, files saved in ./download directory"
  fi
}'  # Download all files from a list of URLs

# HTTP requests
alias get='curl -sS'  # Send GET request
alias post='curl -sSX POST'  # Send POST request
alias headers='curl -I'  # Get HTTP headers only

# DNS operations
alias flushdns='sudo killall -HUP mDNSResponder'  # Flush DNS cache (macOS)

alias dnslookup='() {
  if [ $# -eq 0 ]; then
    echo "DNS lookup for domain.\nUsage:\n dnslookup <domain>"
    return 1
  else
    dig +short $1
  fi
}'  # Look up DNS records for a domain

# URL shortening services
alias yourls_surl='() {
  if [ $# -eq 0 ]; then
    echo "Generate short URL using YOURLS.\nUsage:\n shorturl <url>"
    return 1
  else
    curl -X POST "$YOURLS_BASE_URL/yourls-api.php" --data "format=json&signature=$YOURLS_TOKEN&action=shorturl&url=$1" | jq .
  fi
}'  # Generate short URL using YOURLS

alias sink_surl='() {
  if [ $# -eq 0 ]; then
    echo "Generate short URL using sink.\nUsage: sink <url> [custom_code]"
    return 1
  else 
    shorten_url_by_sink $SINK_BASE_URL $SINK_TOKEN $@
  fi
}'  # Generate short URL using sink service