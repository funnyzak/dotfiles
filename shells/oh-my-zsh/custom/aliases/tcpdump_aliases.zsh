# Description: tcpdump related aliases for network packet analysis.

# Basic Packet Capturing Commands
# ------------------------------

alias tcpdump_basic='() {
  echo "Basic tcpdump with IP addresses."
  echo "Usage: tcpdump_basic"
  echo "Running basic tcpdump..."
  sudo tcpdump -nS
}' # Listen to all ports, directly display IP addresses

alias tcpdump_detail='() {
  echo "Detailed tcpdump with verbose output."
  echo "Usage: tcpdump_detail"
  echo "Running detailed tcpdump..."
  sudo tcpdump -nnvvS
}' # Display more detailed data packets, including tos, ttl, checksum, etc.

alias tcpdump_full='() {
  echo "Full tcpdump with hex and ascii output."
  echo "Usage: tcpdump_full"
  echo "Running full tcpdump with hex and ascii output..."
  sudo tcpdump -nnvvXS
}' # Display all data information with hex and ascii output

# Interface Monitoring Commands
# ----------------------------

alias tcpdump_interface='() {
  if [ $# -eq 0 ]; then
    echo "Monitor specific interface."
    echo "Usage: tcpdump_interface <interface>"
    return 1
  fi

  echo "Monitoring interface: $1"
  sudo tcpdump -i "$1"
}' # Listen to the specified network interface

# Port Monitoring Commands
# ----------------------

alias tcpdump_port='() {
  if [ $# -lt 2 ]; then
    echo "Monitor specific interface and port."
    echo "Usage: tcpdump_port <interface> <port>"
    return 1
  fi

  echo "Monitoring interface $1 for port $2"
  sudo tcpdump -i "$1" port "$2"
}' # Filter by specified interface and port

alias tcpdump_port_detail='() {
  if [ $# -lt 2 ]; then
    echo "Monitor specific interface and port with detailed output."
    echo "Usage: tcpdump_port_detail <interface> <port>"
    return 1
  fi

  echo "Monitoring interface $1 for port $2 with detailed output"
  sudo tcpdump -nvvvXS -i "$1" port "$2"
}' # Filter with detailed information

alias tcpdump_any_port='() {
  if [ $# -eq 0 ]; then
    echo "Monitor any interface for specific port with detailed output."
    echo "Usage: tcpdump_any_port <port>"
    return 1
  fi

  echo "Monitoring any interface for port $1 with detailed output"
  sudo tcpdump -nvvvXS -i any port "$1"
}' # View detailed packets on any interface for a specific port

alias tcpdump_src_port='() {
  if [ $# -lt 3 ]; then
    echo "Monitor traffic from source IP to specific port."
    echo "Usage: tcpdump_src_port <interface> <source_ip> <port>"
    return 1
  fi

  echo "Monitoring interface $1 for traffic from $2 to port $3"
  sudo tcpdump -i "$1" -nvvvXS src "$2" and port "$3"
}' # Filter source IP and port data packets

alias tcpdump_portrange='() {
  if [ $# -lt 2 ]; then
    echo "Monitor port range with size filter."
    echo "Usage: tcpdump_portrange <port_range> <size_op>"
    echo "Example: tcpdump_portrange 21-23 greater 1000"
    return 1
  fi

  echo "Monitoring port range $1 with size filter $2"
  sudo tcpdump portrange "$1" and "$2"
}' # Monitor port range and filter by size

# Network Monitoring Commands
# -------------------------

alias tcpdump_network='() {
  if [ $# -lt 2 ]; then
    echo "Monitor traffic between networks."
    echo "Usage: tcpdump_network <src_network/mask> <dst_network1/mask> [dst_network2/mask]"
    echo "Example: tcpdump_network 192.168.1.0/24 10.0.0.0/8"
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

alias tcpdump_subnet='() {
  if [ $# -eq 0 ]; then
    echo "Monitor subnet traffic."
    echo "Usage: tcpdump_subnet <network/mask>"
    echo "Example: tcpdump_subnet 192.168.1.0/24"
    return 1
  fi

  echo "Monitoring subnet traffic for $1"
  sudo tcpdump net "$1"
}' # Monitor subnet traffic

alias tcpdump_src_dst='() {
  if [ $# -lt 2 ]; then
    echo "Monitor traffic from source IP to destination port."
    echo "Usage: tcpdump_src_dst <source_ip> <destination_port>"
    return 1
  fi

  echo "Monitoring traffic from $1 to destination port $2"
  sudo tcpdump -nnvS src "$1" and dst port "$2"
}' # Monitor traffic from source IP to destination port

# Advanced Filtering Commands
# -------------------------

alias tcpdump_size='() {
  if [ $# -eq 0 ]; then
    echo "Filter packets by size."
    echo "Usage: tcpdump_size <comparison_operator>"
    echo "Example: tcpdump_size \"greater 1000\""
    return 1
  fi

  echo "Filtering packets by size: $1"
  sudo tcpdump "$1"
}' # Filter data packets by size

alias tcpdump_complex='() {
  if [ $# -lt 4 ]; then
    echo "Complex filtering with multiple conditions."
    echo "Usage: tcpdump_complex <interface> <port> <min_size> <network/mask>"
    echo "Example: tcpdump_complex eth0 80 1000 192.168.1.0/24"
    return 1
  fi

  echo "Monitoring interface $1 for port $2, packets larger than $3 bytes, on network $4"
  sudo tcpdump -i "$1" -nvvXS port "$2" and greater "$3" and net "$4"
}' # Complex filtering condition combination

# Utility Commands
# --------------

alias tcpdump_save='() {
  if [ $# -lt 2 ]; then
    echo "Save packet capture to file."
    echo "Usage: tcpdump_save <filename.pcap> <filter_expression>"
    echo "Example: tcpdump_save capture.pcap \"port 80\""
    return 1
  fi

  echo "Saving packet capture to $1 with filter: ${@:2}"
  sudo tcpdump -w "$1" "${@:2}"
}' # Save the captured data packets to a file
