# Description: tcpdump related aliases for network packet analysis and monitoring.

# Helper functions
# ---------------

# Helper function to check if tcpdump is installed
_tcpdump_check_installed() {
  if ! command -v tcpdump >/dev/null 2>&1; then
    echo >&2 "Error: tcpdump is not installed. Please install it first."
    return 1
  fi
  return 0
}

# Helper function to display error message
_tcpdump_error() {
  echo >&2 "Error: $1"
  return 1
}

# Basic Packet Capturing Commands
# ------------------------------

alias tcpd_basic='() {
  echo "Basic tcpdump with IP addresses."
  echo "Usage: tcpd_basic"

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  echo "Running basic tcpdump..."
  sudo tcpdump -nS
}' # Listen to all ports, directly display IP addresses

alias tcpd_detail='() {
  echo "Detailed tcpdump with verbose output."
  echo "Usage: tcpd_detail"

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  echo "Running detailed tcpdump..."
  sudo tcpdump -nnvvS
}' # Display detailed data packets with tos, ttl, checksum

alias tcpd_full='() {
  echo "Full tcpdump with hex and ascii output."
  echo "Usage: tcpd_full"

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  echo "Running full tcpdump with hex and ascii output..."
  sudo tcpdump -nnvvXS
}' # Display all data information with hex and ascii output

# Interface Monitoring Commands
# ----------------------------

alias tcpd_iface='() {
  echo "Monitor specific network interface."
  echo "Usage: tcpd_iface <interface_name>"

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Verify parameters
  if [ $# -eq 0 ]; then
    _tcpdump_error "No interface specified. Please provide an interface name."
    return 1
  fi

  echo "Monitoring interface: $1"
  sudo tcpdump -i "$1"
}' # Listen to the specified network interface

# Port Monitoring Commands
# ----------------------

alias tcpd_port='() {
  echo "Monitor specific interface and port."
  echo "Usage: tcpd_port <interface_name> <port_number>"
  echo "Example: tcpd_port eth0 80"

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Verify parameters
  if [ $# -lt 2 ]; then
    _tcpdump_error "Insufficient parameters. Please provide both interface and port."
    return 1
  fi

  echo "Monitoring interface $1 for port $2"
  sudo tcpdump -i "$1" port "$2"
}' # Filter by specified interface and port

alias tcpd_port_detail='() {
  echo "Monitor specific interface and port with detailed output."
  echo "Usage: tcpd_port_detail <interface_name> <port_number>"
  echo "Example: tcpd_port_detail eth0 443"

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Verify parameters
  if [ $# -lt 2 ]; then
    _tcpdump_error "Insufficient parameters. Please provide both interface and port."
    return 1
  fi

  echo "Monitoring interface $1 for port $2 with detailed output"
  sudo tcpdump -nvvvXS -i "$1" port "$2"
}' # Filter with detailed hex and ascii output

alias tcpd_any_port='() {
  echo "Monitor any interface for specific port with detailed output."
  echo "Usage: tcpd_any_port <port_number>"
  echo "Example: tcpd_any_port 8080"

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Verify parameters
  if [ $# -eq 0 ]; then
    _tcpdump_error "No port specified. Please provide a port number."
    return 1
  fi

  echo "Monitoring any interface for port $1 with detailed output"
  sudo tcpdump -nvvvXS -i any port "$1"
}' # View detailed packets on any interface for a specific port

alias tcpd_src_port='() {
  echo "Monitor traffic from source IP to specific port."
  echo "Usage: tcpd_src_port <interface_name> <source_ip> <port_number>"
  echo "Example: tcpd_src_port eth0 192.168.1.10 80"

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Verify parameters
  if [ $# -lt 3 ]; then
    _tcpdump_error "Insufficient parameters. Please provide interface, source IP, and port."
    return 1
  fi

  echo "Monitoring interface $1 for traffic from $2 to port $3"
  sudo tcpdump -i "$1" -nvvvXS src "$2" and port "$3"
}' # Filter source IP and port data packets

alias tcpd_portrange='() {
  echo "Monitor port range with size filter."
  echo "Usage: tcpd_portrange <port_range> <size_operator>"
  echo "Example: tcpd_portrange 21-23 \"greater 1000\""

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Verify parameters
  if [ $# -lt 2 ]; then
    _tcpdump_error "Insufficient parameters. Please provide port range and size operator."
    return 1
  fi

  echo "Monitoring port range $1 with size filter $2"
  sudo tcpdump portrange "$1" and "$2"
}' # Monitor port range and filter by size

# Network Monitoring Commands
# -------------------------

alias tcpd_network='() {
  echo "Monitor traffic between networks."
  echo "Usage: tcpd_network <src_network/mask> <dst_network1/mask> [dst_network2/mask]"
  echo "Example: tcpd_network 192.168.1.0/24 10.0.0.0/8"

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Verify parameters
  if [ $# -lt 2 ]; then
    _tcpdump_error "Insufficient parameters. Please provide source and destination networks."
    return 1
  fi

  if [ $# -eq 3 ]; then
    echo "Monitoring traffic from $1 to $2 or $3"
    sudo tcpdump -nvX src net "$1" and dst net "$2" or "$3"
  else
    echo "Monitoring traffic from $1 to $2"
    sudo tcpdump -nvX src net "$1" and dst net "$2"
  fi
}' # Monitor traffic between network segments

alias tcpd_subnet='() {
  echo "Monitor subnet traffic."
  echo "Usage: tcpd_subnet <network/mask>"
  echo "Example: tcpd_subnet 192.168.1.0/24"

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Verify parameters
  if [ $# -eq 0 ]; then
    _tcpdump_error "No subnet specified. Please provide a network with mask."
    return 1
  fi

  echo "Monitoring subnet traffic for $1"
  sudo tcpdump net "$1"
}' # Monitor subnet traffic

alias tcpd_src_dst='() {
  echo "Monitor traffic from source IP to destination port."
  echo "Usage: tcpd_src_dst <source_ip> <destination_port>"
  echo "Example: tcpd_src_dst 192.168.1.10 443"

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Verify parameters
  if [ $# -lt 2 ]; then
    _tcpdump_error "Insufficient parameters. Please provide source IP and destination port."
    return 1
  fi

  echo "Monitoring traffic from $1 to destination port $2"
  sudo tcpdump -nnvS src "$1" and dst port "$2"
}' # Monitor traffic from source IP to destination port

# Advanced Filtering Commands
# -------------------------

alias tcpd_size='() {
  echo "Filter packets by size."
  echo "Usage: tcpd_size <comparison_operator>"
  echo "Example: tcpd_size \"greater 1000\""

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Verify parameters
  if [ $# -eq 0 ]; then
    _tcpdump_error "No size filter specified. Please provide a comparison operator."
    return 1
  fi

  echo "Filtering packets by size: $1"
  sudo tcpdump "$1"
}' # Filter data packets by size

alias tcpd_complex='() {
  echo "Complex filtering with multiple conditions."
  echo "Usage: tcpd_complex <interface_name> <port_number> <min_size> <network/mask>"
  echo "Example: tcpd_complex eth0 80 1000 192.168.1.0/24"

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Verify parameters
  if [ $# -lt 4 ]; then
    _tcpdump_error "Insufficient parameters. Please provide interface, port, size, and network."
    return 1
  fi

  echo "Monitoring interface $1 for port $2, packets larger than $3 bytes, on network $4"
  sudo tcpdump -i "$1" -nvvXS port "$2" and greater "$3" and net "$4"
}' # Complex filtering condition combination

# Utility Commands
# --------------

alias tcpd_save='() {
  echo "Save packet capture to file."
  echo "Usage: tcpd_save <filename.pcap> <filter_expression>"
  echo "Example: tcpd_save capture.pcap \"port 80\""

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Verify parameters
  if [ $# -lt 2 ]; then
    _tcpdump_error "Insufficient parameters. Please provide filename and filter expression."
    return 1
  fi

  echo "Saving packet capture to $1 with filter: ${@:2}"
  sudo tcpdump -w "$1" "${@:2}"
}' # Save the captured data packets to a file

alias tcpd_read='() {
  echo "Read packet capture from file."
  echo "Usage: tcpd_read <filename.pcap> [filter_expression]"
  echo "Example: tcpd_read capture.pcap \"port 80\""

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Verify parameters
  if [ $# -lt 1 ]; then
    _tcpdump_error "No filename specified. Please provide a pcap file to read."
    return 1
  fi

  if [ ! -f "$1" ]; then
    _tcpdump_error "File not found: $1"
    return 1
  fi

  if [ $# -eq 1 ]; then
    echo "Reading packet capture from $1"
    sudo tcpdump -r "$1" -nnvvXS
  else
    echo "Reading packet capture from $1 with filter: ${@:2}"
    sudo tcpdump -r "$1" -nnvvXS "${@:2}"
  fi
}' # Read captured data from a pcap file

# Advanced Usage Commands
# ---------------------

alias tcpd_help='() {
  echo "tcpdump aliases help guide"
  echo "-------------------------"
  echo ""
  echo "Basic Commands:"
  echo "  tcpd_basic        - Basic packet capturing with IP addresses"
  echo "  tcpd_detail       - Detailed packet capturing with verbose output"
  echo "  tcpd_full         - Full packet capturing with hex and ascii output"
  echo ""
  echo "Interface Commands:"
  echo "  tcpd_iface        - Monitor specific network interface"
  echo ""
  echo "Port Commands:"
  echo "  tcpd_port         - Monitor specific interface and port"
  echo "  tcpd_port_detail  - Monitor interface and port with detailed output"
  echo "  tcpd_any_port     - Monitor any interface for specific port"
  echo "  tcpd_src_port     - Monitor traffic from source IP to port"
  echo "  tcpd_portrange    - Monitor port range with size filter"
  echo ""
  echo "Network Commands:"
  echo "  tcpd_network      - Monitor traffic between networks"
  echo "  tcpd_subnet       - Monitor subnet traffic"
  echo "  tcpd_src_dst      - Monitor source IP to destination port"
  echo ""
  echo "Advanced Commands:"
  echo "  tcpd_size         - Filter packets by size"
  echo "  tcpd_complex      - Complex filtering with multiple conditions"
  echo ""
  echo "Utility Commands:"
  echo "  tcpd_save         - Save packet capture to file"
  echo "  tcpd_read         - Read packet capture from file"
  echo ""
  echo "For more detailed help on each command, run the command without parameters."
}' # Display help information for all tcpdump aliases
