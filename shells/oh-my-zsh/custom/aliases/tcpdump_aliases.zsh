# Description: tcpdump related aliases for network packet analysis.

alias tcpdump-basic='() {
  echo "Basic tcpdump with IP addresses.\nUsage:\n tcpdump-basic"
  echo "Running basic tcpdump..."
  sudo tcpdump -nS
}' # Listen to all ports, directly display IP addresses

alias tcpdump-detail='() {
  echo "Detailed tcpdump with verbose output.\nUsage:\n tcpdump-detail"
  echo "Running detailed tcpdump..."
  sudo tcpdump -nnvvS
}' # Display more detailed data packets, including tos, ttl, checksum, etc.

alias tcpdump-full='() {
  echo "Full tcpdump with hex and ascii output.\nUsage:\n tcpdump-full"
  echo "Running full tcpdump with hex and ascii output..."
  sudo tcpdump -nnvvXS
}' # Display all data information of the data packet, and output it in two columns of hex and ascii for comparison.

alias tcpdump-iface='() {
  if [ $# -eq 0 ]; then
    echo "Monitor specific interface.\nUsage:\n tcpdump-iface <interface>"
    return 1
  fi
  echo "Monitoring interface: $1"
  sudo tcpdump -i $1
}' # Listen to the specified network port

alias tcpdump-port='() {
  if [ $# -lt 2 ]; then
    echo "Monitor specific interface and port.\nUsage:\n tcpdump-port <interface> <port>"
    return 1
  fi
  echo "Monitoring interface $1 for port $2"
  sudo tcpdump -i $1 port $2
}' # Filter the specified network port and port

alias tcpdump-port-detail='() {
  if [ $# -lt 2 ]; then
    echo "Monitor specific interface and port with detailed output.\nUsage:\n tcpdump-port-detail <interface> <port>"
    return 1
  fi
  echo "Monitoring interface $1 for port $2 with detailed output"
  sudo tcpdump -nvvvXS -i $1 port $2
}' # Filter the specified network port and port and display detailed information

alias tcpdump-any-port='() {
  if [ $# -eq 0 ]; then
    echo "Monitor any interface for specific port with detailed output.\nUsage:\n tcpdump-any-port <port>"
    return 1
  fi
  echo "Monitoring any interface for port $1 with detailed output"
  sudo tcpdump -nvvvXS -i any port $1
}' # View detailed data packets of the specified port on any network port

alias tcpdump-src-port='() {
  if [ $# -lt 3 ]; then
    echo "Monitor traffic from source IP to specific port.\nUsage:\n tcpdump-src-port <interface> <source_ip> <port>"
    return 1
  fi
  echo "Monitoring interface $1 for traffic from $2 to port $3"
  sudo tcpdump -i $1 -nvvvXS src $2 and port $3
}' # Filter source IP and port data packets

alias tcpdump-net='() {
  if [ $# -lt 3 ]; then
    echo "Monitor traffic between networks.\nUsage:\n tcpdump-net <src_network/mask> <dst_network1/mask> [dst_network2/mask]"
    return 1
  fi

  if [ $# -eq 3 ]; then
    echo "Monitoring traffic from $1 to $2 or $3"
    sudo tcpdump -nvX src net $1 and dst net $2 or $3
  else
    echo "Monitoring traffic from $1 to $2"
    sudo tcpdump -nvX src net $1 and dst net $2
  fi
}' # Monitor traffic between network segments

alias tcpdump-subnet='() {
  if [ $# -eq 0 ]; then
    echo "Monitor subnet traffic.\nUsage:\n tcpdump-subnet <network/mask>"
    return 1
  fi
  echo "Monitoring subnet traffic for $1"
  sudo tcpdump net $1
}' # Monitor subnet traffic

alias tcpdump-save='() {
  if [ $# -lt 2 ]; then
    echo "Save packet capture to file.\nUsage:\n tcpdump-save <filename.pcap> <filter_expression>"
    return 1
  fi
  echo "Saving packet capture to $1 with filter: ${@:2}"
  sudo tcpdump -w $1 ${@:2}
}' # Save the captured data packets to a file

alias tcpdump-portrange='() {
  if [ $# -lt 2 ]; then
    echo "Monitor port range with size filter.\nUsage:\n tcpdump-portrange <port_range> <size_op>"
    return 1
  fi
  echo "Monitoring port range $1 with size filter $2"
  sudo tcpdump portrange $1 and $2
}' # Monitor port range and filter by size

alias tcpdump-size='() {
  if [ $# -eq 0 ]; then
    echo "Filter packets by size.\nUsage:\n tcpdump-size <comparison_operator>"
    return 1
  fi
  echo "Filtering packets by size: $1"
  sudo tcpdump $1
}' # Filter data packets by size

alias tcpdump-src-dst='() {
  if [ $# -lt 3 ]; then
    echo "Monitor traffic from source IP to destination port.\nUsage:\n tcpdump-src-dst <source_ip> <destination_port>"
    return 1
  fi
  echo "Monitoring traffic from $1 to destination port $2"
  sudo tcpdump -nnvS src $1 and dst port $2
}' # Monitor traffic from source IP to destination port

alias tcpdump-complex='() {
  if [ $# -lt 4 ]; then
    echo "Complex filtering with multiple conditions.\nUsage:\n tcpdump-complex <interface> <port> <min_size> <network/mask>"
    return 1
  fi
  echo "Monitoring interface $1 for port $2, packets larger than $3 bytes, on network $4"
  sudo tcpdump -i $1 -nvvXS port $2 and greater $3 and net $4
}' # Complex filtering condition combination
