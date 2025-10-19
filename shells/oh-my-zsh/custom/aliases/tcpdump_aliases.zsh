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

# Common filter for data payload packets (non-empty packets)
_TCPDUMP_DATA_FILTER="(((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)"

# Helper function to get only packets with actual data payload
_tcpdump_data_only_filter() {
  local base_filter="$1"
  if [ -n "$base_filter" ]; then
    echo "($base_filter) and $_TCPDUMP_DATA_FILTER"
  else
    echo "$_TCPDUMP_DATA_FILTER"
  fi
}

# Helper function for HTTP output formatting
_tcpdump_format_http() {
  local format_type="$1"
  local port="$2"
  local interface="$3"
  local custom_filter="$4"
  local format_options=""

  # Set formatting options based on type
  case "$format_type" in
    "full")
      # Full output with hex and ASCII
      format_options="-nnvvXSs 0"
      ;;
    "ascii")
      # Human-readable ASCII output
      format_options="-nnvvAs 0"
      ;;
    "headers")
      # Just the headers in ASCII
      format_options="-nnAs 0"
      ;;
    *)
      _tcpdump_error "Unknown format type: $format_type"
      return 1
      ;;
  esac

  # Build and execute the tcpdump command
  local filter="tcp port $port"
  if [ -n "$custom_filter" ]; then
    filter="$filter and $custom_filter"
  fi

  echo "Running tcpdump with format: $format_type"
  sudo tcpdump -i "$interface" $format_options "$filter"
}

# Helper function for common IP protocol filtering
_tcpdump_ip_proto() {
  local proto="$1"
  local interface="$2"
  local extra_filter="$3"
  local options="$4"

  local filter="ip proto $proto"
  if [ -n "$extra_filter" ]; then
    filter="$filter and $extra_filter"
  fi

  # If no specific options provided, use default
  if [ -z "$options" ]; then
    options="-nnvvS"
  fi

  sudo tcpdump -i "$interface" $options "$filter"
}

# Basic Packet Capturing Commands
# ------------------------------

alias tcpd-basic='() {
  echo -e "Basic tcpdump with IP addresses and filtering options.\nUsage:\n tcpd-basic [--source-ip ip] [--dest-ip ip] [--min-size size] [--max-size size] [--port port] [--interface interface] [--data-only] [--count] [--help]"
  echo ""
  echo "Options:"
  echo "  --source-ip ip      Filter by source IP address"
  echo "  --dest-ip ip        Filter by destination IP address"
  echo "  --min-size size     Filter packets with minimum size (bytes)"
  echo "  --max-size size     Filter packets with maximum size (bytes)"
  echo "  --port port         Filter by port number"
  echo "  --interface iface   Network interface (default: any)"
  echo "  --data-only         Show only packets with data payload"
  echo "  --count             Count packets instead of displaying content"
  echo "  --help              Show this help message"
  echo ""
  echo "Examples:"
  echo "  tcpd-basic --source-ip 192.168.1.100 --port 80"
  echo "  tcpd-basic --min-size 1000 --data-only"
  echo "  tcpd-basic --dest-ip 10.0.0.1 --interface eth0"

  # Check for help flag
  if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    return 0
  fi

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Initialize variables
  local source_ip=""
  local dest_ip=""
  local min_size=""
  local max_size=""
  local port_filter=""
  local interface_name="any"
  local data_only=false
  local count_only=false
  local filter_parts=()
  local options="-nS"

  # Parse named parameters
  while [ $# -gt 0 ]; do
    case "$1" in
      --source-ip)
        source_ip="$2"
        shift 2
        ;;
      --dest-ip)
        dest_ip="$2"
        shift 2
        ;;
      --min-size)
        min_size="$2"
        shift 2
        ;;
      --max-size)
        max_size="$2"
        shift 2
        ;;
      --port)
        port_filter="$2"
        shift 2
        ;;
      --interface|-i)
        interface_name="$2"
        shift 2
        ;;
      --data-only|-d)
        data_only=true
        shift
        ;;
      --count|-c)
        count_only=true
        shift
        ;;
      *)
        echo "Error: Unknown option: $1" >&2
        echo "Use --help for usage information." >&2
        return 1
        ;;
    esac
  done

  # Validate IP addresses
  if [ -n "$source_ip" ]; then
    if [[ "$source_ip" != *.*.*.* ]]; then
      echo "Error: Invalid source IP format: $source_ip" >&2
      return 1
    fi
    filter_parts+=("src $source_ip")
  fi

  if [ -n "$dest_ip" ]; then
    if [[ "$dest_ip" != *.*.*.* ]]; then
      echo "Error: Invalid destination IP format: $dest_ip" >&2
      return 1
    fi
    filter_parts+=("dst $dest_ip")
  fi

  # Validate size parameters
  if [ -n "$min_size" ]; then
    if ! [[ "$min_size" =~ ^[0-9]+$ ]]; then
      echo "Error: Invalid minimum size: $min_size. Must be a number." >&2
      return 1
    fi
    filter_parts+=("greater $min_size")
  fi

  if [ -n "$max_size" ]; then
    if ! [[ "$max_size" =~ ^[0-9]+$ ]]; then
      echo "Error: Invalid maximum size: $max_size. Must be a number." >&2
      return 1
    fi
    filter_parts+=("less $max_size")
  fi

  # Validate port
  if [ -n "$port_filter" ]; then
    if ! [[ "$port_filter" =~ ^[0-9]+$ ]]; then
      echo "Error: Invalid port number: $port_filter. Must be a number." >&2
      return 1
    fi
    filter_parts+=("port $port_filter")
  fi

  # Add data payload filter
  if [ "$data_only" = true ]; then
    filter_parts+=("$_TCPDUMP_DATA_FILTER")
  fi

  # Build final filter
  local final_filter=""
  if [ ${#filter_parts[@]} -gt 0 ]; then
    final_filter=$(IFS=" and "; echo "${filter_parts[*]}")
  fi

  # Set count option
  if [ "$count_only" = true ]; then
    options="$options -c 0"
    echo "Counting packets instead of displaying content..."
  fi

  # Display what we are monitoring
  echo "Running basic tcpdump..."
  [ -n "$source_ip" ] && echo "  Source IP: $source_ip"
  [ -n "$dest_ip" ] && echo "  Destination IP: $dest_ip"
  [ -n "$min_size" ] && echo "  Minimum size: $min_size bytes"
  [ -n "$max_size" ] && echo "  Maximum size: $max_size bytes"
  [ -n "$port_filter" ] && echo "  Port: $port_filter"
  [ "$data_only" = true ] && echo "  Data payload only: yes"
  [ "$count_only" = true ] && echo "  Count mode: yes"
  echo "  Interface: $interface_name"

  # Execute tcpdump
  if [ -n "$final_filter" ]; then
    sudo tcpdump -i "$interface_name" $options "$final_filter"
  else
    sudo tcpdump -i "$interface_name" $options
  fi
}' # Enhanced basic tcpdump with IP and size filtering options

alias tcpd-detail='() {
  echo -e "Detailed tcpdump with verbose output and advanced filtering.\nUsage:\n tcpd-detail [--source-ip ip] [--dest-ip ip] [--min-size size] [--max-size size] [--port port] [--interface interface] [--protocol proto] [--data-only] [--count count] [--help]"
  echo ""
  echo "Options:"
  echo "  --source-ip ip      Filter by source IP address"
  echo "  --dest-ip ip        Filter by destination IP address"
  echo "  --min-size size     Filter packets with minimum size (bytes)"
  echo "  --max-size size     Filter packets with maximum size (bytes)"
  echo "  --port port         Filter by port number"
  echo "  --interface iface   Network interface (default: any)"
  echo "  --protocol proto    Filter by protocol (tcp, udp, icmp, ip)"
  echo "  --data-only         Show only packets with data payload"
  echo "  --count count       Show only specified number of packets"
  echo "  --help              Show this help message"
  echo ""
  echo "Examples:"
  echo "  tcpd-detail --source-ip 192.168.1.100 --protocol tcp"
  echo "  tcpd-detail --port 443 --min-size 500 --count 20"
  echo "  tcpd-detail --dest-ip 10.0.0.0/24 --interface eth0"

  # Check for help flag
  if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    return 0
  fi

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Initialize variables
  local source_ip=""
  local dest_ip=""
  local min_size=""
  local max_size=""
  local port_filter=""
  local interface_name="any"
  local protocol_filter=""
  local data_only=false
  local packet_count=""
  local filter_parts=()
  local options="-nnvvS"

  # Parse named parameters
  while [ $# -gt 0 ]; do
    case "$1" in
      --source-ip)
        source_ip="$2"
        shift 2
        ;;
      --dest-ip)
        dest_ip="$2"
        shift 2
        ;;
      --min-size)
        min_size="$2"
        shift 2
        ;;
      --max-size)
        max_size="$2"
        shift 2
        ;;
      --port)
        port_filter="$2"
        shift 2
        ;;
      --interface|-i)
        interface_name="$2"
        shift 2
        ;;
      --protocol)
        protocol_filter="$2"
        shift 2
        ;;
      --data-only|-d)
        data_only=true
        shift
        ;;
      --count|-c)
        packet_count="$2"
        shift 2
        ;;
      *)
        echo "Error: Unknown option: $1" >&2
        echo "Use --help for usage information." >&2
        return 1
        ;;
    esac
  done

  # Validate IP addresses and CIDR notation
  if [ -n "$source_ip" ]; then
    if [[ "$source_ip" != *.*.*.* ]] && [[ "$source_ip" != *.*.*.*/* ]]; then
      echo "Error: Invalid source IP/network format: $source_ip" >&2
      return 1
    fi
    if echo "$source_ip" | grep -q "/"; then
      filter_parts+=("src net $source_ip")
    else
      filter_parts+=("src $source_ip")
    fi
  fi

  if [ -n "$dest_ip" ]; then
    if [[ "$dest_ip" != *.*.*.* ]] && [[ "$dest_ip" != *.*.*.*/* ]]; then
      echo "Error: Invalid destination IP/network format: $dest_ip" >&2
      return 1
    fi
    if echo "$dest_ip" | grep -q "/"; then
      filter_parts+=("dst net $dest_ip")
    else
      filter_parts+=("dst $dest_ip")
    fi
  fi

  # Validate size parameters
  if [ -n "$min_size" ]; then
    if ! [[ "$min_size" =~ ^[0-9]+$ ]]; then
      echo "Error: Invalid minimum size: $min_size. Must be a number." >&2
      return 1
    fi
    filter_parts+=("greater $min_size")
  fi

  if [ -n "$max_size" ]; then
    if ! [[ "$max_size" =~ ^[0-9]+$ ]]; then
      echo "Error: Invalid maximum size: $max_size. Must be a number." >&2
      return 1
    fi
    filter_parts+=("less $max_size")
  fi

  # Validate port
  if [ -n "$port_filter" ]; then
    if ! [[ "$port_filter" =~ ^[0-9]+$ ]]; then
      echo "Error: Invalid port number: $port_filter. Must be a number." >&2
      return 1
    fi
    filter_parts+=("port $port_filter")
  fi

  # Validate protocol
  if [ -n "$protocol_filter" ]; then
    case "$protocol_filter" in
      tcp|udp|icmp|ip)
        filter_parts+=("$protocol_filter")
        ;;
      *)
        echo "Error: Invalid protocol: $protocol_filter. Use tcp, udp, icmp, or ip" >&2
        return 1
        ;;
    esac
  fi

  # Validate packet count
  if [ -n "$packet_count" ]; then
    if ! [[ "$packet_count" =~ ^[0-9]+$ ]]; then
      echo "Error: Invalid packet count: $packet_count. Must be a number." >&2
      return 1
    fi
    options="$options -c $packet_count"
  fi

  # Add data payload filter
  if [ "$data_only" = true ]; then
    filter_parts+=("$_TCPDUMP_DATA_FILTER")
  fi

  # Build final filter
  local final_filter=""
  if [ ${#filter_parts[@]} -gt 0 ]; then
    final_filter=$(IFS=" and "; echo "${filter_parts[*]}")
  fi

  # Display what we are monitoring
  echo "Running detailed tcpdump with verbose output..."
  [ -n "$source_ip" ] && echo "  Source IP/Network: $source_ip"
  [ -n "$dest_ip" ] && echo "  Destination IP/Network: $dest_ip"
  [ -n "$min_size" ] && echo "  Minimum size: $min_size bytes"
  [ -n "$max_size" ] && echo "  Maximum size: $max_size bytes"
  [ -n "$port_filter" ] && echo "  Port: $port_filter"
  [ -n "$protocol_filter" ] && echo "  Protocol: $protocol_filter"
  [ "$data_only" = true ] && echo "  Data payload only: yes"
  [ -n "$packet_count" ] && echo "  Packet count: $packet_count"
  echo "  Interface: $interface_name"

  # Execute tcpdump
  if [ -n "$final_filter" ]; then
    sudo tcpdump -i "$interface_name" $options "$final_filter"
  else
    sudo tcpdump -i "$interface_name" $options
  fi
}' # Enhanced detailed tcpdump with advanced filtering options

alias tcpd-full='() {
  echo "Full tcpdump with hex and ascii output."
  echo "Usage: tcpd-full [options]"
  echo "Options:"
  echo "  -d      Show only packets with data payload (no TCP control packets)"
  echo "  -c <count:10>  Show only specified number of packets"
  echo "  -s <snaplen:0> Set snapshot length (0 = capture whole packet)"

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Parse options
  local data_only=false
  local packet_count=""
  local snap_len="0"
  local OPTIND=1

  while getopts ":dc:s:" opt; do
    case "$opt" in
      d) data_only=true ;;
      c) packet_count="$OPTARG" ;;
      s) snap_len="$OPTARG" ;;
      \?) _tcpdump_error "Invalid option: -$OPTARG"; return 1 ;;
    esac
  done
  shift $((OPTIND-1))

  local filter=""
  local options="-nnvvXSs $snap_len"

  if [ "$data_only" = true ]; then
    filter="$_TCPDUMP_DATA_FILTER"
    echo "Running full tcpdump with data payload only..."
  else
    echo "Running full tcpdump with hex and ascii output..."
  fi

  if [ -n "$packet_count" ]; then
    options="$options -c $packet_count"
    echo "Limiting output to $packet_count packets..."
  fi

  if [ -n "$filter" ]; then
    sudo tcpdump $options "$filter"
  else
    sudo tcpdump $options
  fi
}' # Display all data information with hex and ascii output

# Interface Monitoring Commands
# ----------------------------

alias tcpd-iface='() {
  echo "Monitor specific network interface."
  echo "Usage: tcpd-iface <interface_name> [options]"
  echo "Options:"
  echo "  -d      Show only packets with data payload"
  echo "  -v      Verbose output with more details"
  echo "  -x      Show hex and ASCII output"

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Parse options
  local data_only=false
  local verbose=false
  local hex_ascii=false
  local OPTIND=1

  while getopts ":dvx" opt; do
    case "$opt" in
      d) data_only=true ;;
      v) verbose=true ;;
      x) hex_ascii=true ;;
      \?) _tcpdump_error "Invalid option: -$OPTARG"; return 1 ;;
    esac
  done
  shift $((OPTIND-1))

  # Verify parameters
  if [ $# -eq 0 ]; then
    _tcpdump_error "No interface specified. Please provide an interface name."
    return 1
  fi

  local interface="$1"
  local filter=""
  local options=""

  if [ "$data_only" = true ]; then
    filter="$_TCPDUMP_DATA_FILTER"
    echo "Monitoring interface $interface with data payload only..."
  else
    echo "Monitoring interface: $interface"
  fi

  if [ "$verbose" = true ]; then
    options="$options -nvv"
  fi

  if [ "$hex_ascii" = true ]; then
    options="$options -XS"
  fi

  if [ -z "$options" ]; then
    options=""
  fi

  if [ -n "$filter" ]; then
    sudo tcpdump -i "$interface" $options "$filter"
  else
    sudo tcpdump -i "$interface" $options
  fi
}' # Listen to the specified network interface

# Port Monitoring Commands
# ----------------------

alias tcpd-port='() {
  echo -e "Monitor specific port with advanced filtering options.\nUsage:\n tcpd-port <port_number> [--source-ip ip] [--dest-ip ip] [--min-size size] [--max-size size] [--interface interface] [--data-only] [--verbose] [--hex] [--count count] [--help]"
  echo ""
  echo "Required:"
  echo "  port_number         Port number to monitor"
  echo ""
  echo "Options:"
  echo "  --source-ip ip      Filter by source IP address"
  echo "  --dest-ip ip        Filter by destination IP address"
  echo "  --min-size size     Filter packets with minimum size (bytes)"
  echo "  --max-size size     Filter packets with maximum size (bytes)"
  echo "  --interface iface   Network interface (default: any)"
  echo "  --data-only         Show only packets with data payload"
  echo "  --verbose           Verbose output with more details"
  echo "  --hex               Show hex and ASCII dump"
  echo "  --count count       Show only specified number of packets"
  echo "  --help              Show this help message"
  echo ""
  echo "Examples:"
  echo "  tcpd-port 80 --source-ip 192.168.1.100 --verbose"
  echo "  tcpd-port 443 --min-size 1000 --hex --count 50"
  echo "  tcpd-port 22 --dest-ip 10.0.0.0/24 --interface eth0"

  # Check for help flag
  [ "$1" = "--help" ] || [ "$1" = "-h" ] && return 0

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Initialize variables
  local port_number=""
  local source_ip=""
  local dest_ip=""
  local min_size=""
  local max_size=""
  local interface_name="any"
  local data_only=false
  local verbose=false
  local hex_ascii=false
  local packet_count=""
  local filter_parts=()
  local options=""

  # Parse named parameters
  while [ $# -gt 0 ]; do
    case "$1" in
      --source-ip)
        source_ip="$2"
        shift 2
        ;;
      --dest-ip)
        dest_ip="$2"
        shift 2
        ;;
      --min-size)
        min_size="$2"
        shift 2
        ;;
      --max-size)
        max_size="$2"
        shift 2
        ;;
      --interface|-i)
        interface_name="$2"
        shift 2
        ;;
      --data-only|-d)
        data_only=true
        shift
        ;;
      --verbose|-v)
        verbose=true
        shift
        ;;
      --hex|-x)
        hex_ascii=true
        shift
        ;;
      --count|-c)
        packet_count="$2"
        shift 2
        ;;
      *)
        # If parameter looks like a port number and port is not set
        if [ -z "$port_number" ] && [[ "$1" =~ ^[0-9]+$ ]]; then
          port_number="$1"
          shift
        else
          echo "Error: Unknown option or missing port number: $1" >&2
          echo "Use --help for usage information." >&2
          return 1
        fi
        ;;
    esac
  done

  # Verify required port number
  if [ -z "$port_number" ]; then
    echo "Error: Port number is required. Please provide a port number." >&2
    return 1
  fi

  # Validate port number
  if ! [[ "$port_number" =~ ^[0-9]+$ ]] || [ "$port_number" -lt 1 ] || [ "$port_number" -gt 65535 ]; then
    echo "Error: Invalid port number: $port_number. Must be between 1 and 65535." >&2
    return 1
  fi

  # Validate IP addresses and CIDR notation
  if [ -n "$source_ip" ]; then
    if [[ "$source_ip" != *.*.*.* ]] && [[ "$source_ip" != *.*.*.*/* ]]; then
      echo "Error: Invalid source IP/network format: $source_ip" >&2
      return 1
    fi
    if echo "$source_ip" | grep -q "/"; then
      filter_parts+=("src net $source_ip")
    else
      filter_parts+=("src $source_ip")
    fi
  fi

  if [ -n "$dest_ip" ]; then
    if [[ "$dest_ip" != *.*.*.* ]] && [[ "$dest_ip" != *.*.*.*/* ]]; then
      echo "Error: Invalid destination IP/network format: $dest_ip" >&2
      return 1
    fi
    if echo "$dest_ip" | grep -q "/"; then
      filter_parts+=("dst net $dest_ip")
    else
      filter_parts+=("dst $dest_ip")
    fi
  fi

  # Validate size parameters
  if [ -n "$min_size" ]; then
    if ! [[ "$min_size" =~ ^[0-9]+$ ]]; then
      echo "Error: Invalid minimum size: $min_size. Must be a number." >&2
      return 1
    fi
    filter_parts+=("greater $min_size")
  fi

  if [ -n "$max_size" ]; then
    if ! [[ "$max_size" =~ ^[0-9]+$ ]]; then
      echo "Error: Invalid maximum size: $max_size. Must be a number." >&2
      return 1
    fi
    filter_parts+=("less $max_size")
  fi

  # Validate packet count
  if [ -n "$packet_count" ]; then
    if ! [[ "$packet_count" =~ ^[0-9]+$ ]]; then
      echo "Error: Invalid packet count: $packet_count. Must be a number." >&2
      return 1
    fi
    options="$options -c $packet_count"
  fi

  # Build tcpdump options
  if [ "$verbose" = true ]; then
    options="$options -nvv"
  else
    options="$options -n"
  fi

  if [ "$hex_ascii" = true ]; then
    options="$options -XS"
  fi

  # Add port filter and data payload filter
  filter_parts+=("port $port_number")
  if [ "$data_only" = true ]; then
    filter_parts+=("$_TCPDUMP_DATA_FILTER")
  fi

  # Build final filter
  local final_filter=$(IFS=" and "; echo "${filter_parts[*]}")

  # Display what we are monitoring
  echo "Monitoring port $port_number..."
  [ -n "$source_ip" ] && echo "  Source IP/Network: $source_ip"
  [ -n "$dest_ip" ] && echo "  Destination IP/Network: $dest_ip"
  [ -n "$min_size" ] && echo "  Minimum size: $min_size bytes"
  [ -n "$max_size" ] && echo "  Maximum size: $max_size bytes"
  [ "$data_only" = true ] && echo "  Data payload only: yes"
  [ "$verbose" = true ] && echo "  Verbose output: yes"
  [ "$hex_ascii" = true ] && echo "  Hex/ASCII dump: yes"
  [ -n "$packet_count" ] && echo "  Packet count: $packet_count"
  echo "  Interface: $interface_name"

  # Execute tcpdump
  sudo tcpdump -i "$interface_name" $options "$final_filter"
}' # Enhanced port monitoring with advanced filtering options

alias tcpd-port-detail='() {
  echo "Monitor specific port and interface with detailed output."
  echo "Usage: tcpd-port-detail [port_number] [interface_name:any] [options]"
  echo "Example: tcpd-port-detail 443 eth0 -d"
  echo "Options:"
  echo "  -d      Show only packets with data payload (no TCP control packets)"
  echo "  -c <count:10>  Show only specified number of packets"
  echo "  -a      Show ASCII only (no hex dump)"

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Parse options
  local data_only=false
  local packet_count=""
  local ascii_only=false
  local OPTIND=1

  while getopts ":dc:a" opt; do
    case "$opt" in
      d) data_only=true ;;
      c) packet_count="$OPTARG" ;;
      a) ascii_only=true ;;
      \?) _tcpdump_error "Invalid option: -$OPTARG"; return 1 ;;
    esac
  done
  shift $((OPTIND-1))

  # Set default values
  local port_number="${1}"
  local interface_name="${2:-any}"

  # Verify parameters
  if [ -z "$port_number" ]; then
    _tcpdump_error "No port specified. Please provide a port number."
    return 1
  fi

  # Validate port number
  if ! [[ "$port_number" =~ ^[0-9]+$ ]]; then
    _tcpdump_error "Invalid port number: $port_number. Must be a number."
    return 1
  fi

  # Build options string
  local options="-nvvv"
  if [ "$ascii_only" = true ]; then
    options="$options -AS"
  else
    options="$options -XS"
  fi

  if [ -n "$packet_count" ]; then
    options="$options -c $packet_count"
    echo "Limiting output to $packet_count packets..."
  fi

  # Build filter
  local filter="port $port_number"
  if [ "$data_only" = true ]; then
    filter="$filter and $_TCPDUMP_DATA_FILTER"
    echo "Monitoring port $port_number on interface $interface_name with detailed output (data packets only)"
  else
    echo "Monitoring port $port_number on interface $interface_name with detailed output"
  fi

  sudo tcpdump -i "$interface_name" $options "$filter"
}' # Filter with detailed hex and ascii output for specified port

alias tcpd-any-port='() {
  echo "Monitor any interface for specific port with detailed output."
  echo "Usage: tcpd-any-port <port_number> [options]"
  echo "Example: tcpd-any-port 8080 -v"
  echo "Options:"
  echo "  -v      Verbose output (less detailed)"
  echo "  -x      Show hex and ASCII output (default)"
  echo "  -a      ASCII output only (more readable for text)"

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Default options
  local detail_option="-nvvvXS"
  local OPTIND=1

  while getopts ":vxa" opt; do
    case "$opt" in
      v) detail_option="-nvv" ;;
      x) detail_option="-nvvvXS" ;;
      a) detail_option="-nvvvAS" ;;
      \?) _tcpdump_error "Invalid option: -$OPTARG"; return 1 ;;
    esac
  done
  shift $((OPTIND-1))

  # Verify parameters
  local port_number="$1"
  if [ -z "$port_number" ]; then
    _tcpdump_error "No port specified. Please provide a port number."
    return 1
  fi

  # Validate port number
  if ! [[ "$port_number" =~ ^[0-9]+$ ]]; then
    _tcpdump_error "Invalid port number: $port_number. Must be a number."
    return 1
  fi

  echo "Monitoring any interface for port $port_number with $detail_option output"
  sudo tcpdump $detail_option -i any port "$port_number"
}' # View detailed packets on any interface for a specific port

alias tcpd-src-port='() {
  echo "Monitor traffic from source IP to specific port."
  echo "Usage: tcpd-src-port <interface_name> <source_ip> <port_number>"
  echo "Example: tcpd-src-port eth0 192.168.1.10 80"

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

alias tcpd-portrange='() {
  echo "Monitor port range with size filter."
  echo "Usage: tcpd-portrange <port_range> <size_operator>"
  echo "Example: tcpd-portrange 21-23 \"greater 1000\""

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

alias tcpd-network='() {
  echo "Monitor traffic between networks."
  echo "Usage: tcpd-network <src_network/mask> <dst_network1/mask> [dst_network2/mask]"
  echo "Example: tcpd-network 192.168.1.0/24 10.0.0.0/8"

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

alias tcpd-subnet='() {
  echo "Monitor subnet traffic."
  echo "Usage: tcpd-subnet <network/mask>"
  echo "Example: tcpd-subnet 192.168.1.0/24"

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

alias tcpd-src-dst='() {
  echo "Monitor traffic from source IP to destination port."
  echo "Usage: tcpd-src-dst <source_ip> <destination_port>"
  echo "Example: tcpd-src-dst 192.168.1.10 443"

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

alias tcpd-size='() {
  echo "Filter packets by size."
  echo "Usage: tcpd-size <comparison_operator>"
  echo "Example: tcpd-size \"greater 1000\""

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

alias tcpd-complex='() {
  echo "Complex filtering with multiple conditions."
  echo "Usage: tcpd-complex <interface_name> <port_number> <min_size> <network/mask>"
  echo "Example: tcpd-complex eth0 80 1000 192.168.1.0/24"

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

alias tcpd-save='() {
  echo "Save packet capture to file."
  echo "Usage: tcpd-save <filename.pcap> <filter_expression>"
  echo "Example: tcpd-save capture.pcap \"port 80\""

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

alias tcpd-read='() {
  echo "Read packet capture from file."
  echo "Usage: tcpd-read <filename.pcap> [filter_expression]"
  echo "Example: tcpd-read capture.pcap \"port 80\""

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

# HTTP Traffic Analysis Commands
# ---------------------------

alias tcpd-http='() {
  echo "Monitor HTTP traffic with content."
  echo "Usage: tcpd-http [port_number:80] [interface_name:any] [options]"
  echo "Example: tcpd-http 8080 eth0 -a"
  echo "Options:"
  echo "  -a      Show ASCII output only (more readable for text content)"
  echo "  -x      Show hex and ASCII output (default)"
  echo "  -h      Show headers only"
  echo "  -f      Filter only packets with data payload"

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Parse options
  local format_type="full"
  local filter_data=false
  local OPTIND=1
  while getopts ":axhf" opt; do
    case "$opt" in
      a) format_type="ascii" ;;
      x) format_type="full" ;;
      h) format_type="headers" ;;
      f) filter_data=true ;;
      \?) _tcpdump_error "Invalid option: -$OPTARG"; return 1 ;;
    esac
  done
  shift $((OPTIND-1))

  # Set default values
  local port_number="${1:-80}"
  local interface_name="${2:-any}"

  # Validate port number
  if ! [[ "$port_number" =~ ^[0-9]+$ ]]; then
    _tcpdump_error "Invalid port number: $port_number. Must be a number."
    return 1
  fi

  echo "Monitoring HTTP traffic on port $port_number, interface $interface_name"
  # HTTP filter for packets with data (not just SYN, ACK, etc.)
  local http_filter=""
  if [ "$filter_data" = true ]; then
    http_filter="(((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)"
  fi
  _tcpdump_format_http "$format_type" "$port_number" "$interface_name" "$http_filter"
}' # Monitor HTTP traffic with content in human-readable format

alias tcpd-http-headers='() {
  echo "Display HTTP headers from captured traffic."
  echo "Usage: tcpd-http-headers [port_number:80] [interface_name:any]"
  echo "Example: tcpd-http-headers 8080 eth0"

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Set default values
  local port_number="${1:-80}"
  local interface_name="${2:-any}"

  # Validate port number
  if ! [[ "$port_number" =~ ^[0-9]+$ ]]; then
    _tcpdump_error "Invalid port number: $port_number. Must be a number."
    return 1
  fi

  echo "Monitoring HTTP headers on port $port_number, interface $interface_name"
  # HTTP filter for packets with data, optimized for header display
  local http_filter="(((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)"
  _tcpdump_format_http "headers" "$port_number" "$interface_name" "$http_filter"
}' # Display only HTTP headers in a readable format

alias tcpd-https='() {
  echo "Monitor HTTPS traffic on a specific port and interface."
  echo "Usage: tcpd-https [port_number:443] [interface_name:any]"
  echo "Example: tcpd-https 8443 eth0"
  echo "Options:"
  echo "  -a      Show ASCII output only"
  echo "  -x      Show hex and ASCII output (default)"

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Parse options
  local format_type="full"
  local OPTIND=1
  while getopts ":ax" opt; do
    case "$opt" in
      a) format_type="ascii" ;;
      x) format_type="full" ;;
      \?) _tcpdump_error "Invalid option: -$OPTARG"; return 1 ;;
    esac
  done
  shift $((OPTIND-1))

  # Set default values
  local port_number="${1:-443}"
  local interface_name="${2:-any}"

  # Validate port number
  if ! [[ "$port_number" =~ ^[0-9]+$ ]]; then
    _tcpdump_error "Invalid port number: $port_number. Must be a number."
    return 1
  fi

  echo "Monitoring HTTPS traffic on port $port_number, interface $interface_name"
  _tcpdump_format_http "$format_type" "$port_number" "$interface_name" ""
}' # Monitor HTTPS encrypted traffic with options for display format

alias tcpd-http-get='() {
  echo "Monitor HTTP GET requests."
  echo "Usage: tcpd-http-get [port_number:80] [interface_name:any] [options]"
  echo "Example: tcpd-http-get 8080 eth0 -v"
  echo "Options:"
  echo "  -v      Verbose output (show more details)"

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Parse options
  local verbose=false
  local OPTIND=1
  while getopts ":v" opt; do
    case "$opt" in
      v) verbose=true ;;
      \?) _tcpdump_error "Invalid option: -$OPTARG"; return 1 ;;
    esac
  done
  shift $((OPTIND-1))

  # Set default values
  local port_number="${1:-80}"
  local interface_name="${2:-any}"

  # Validate port number
  if ! [[ "$port_number" =~ ^[0-9]+$ ]]; then
    _tcpdump_error "Invalid port number: $port_number. Must be a number."
    return 1
  fi

  echo "Monitoring HTTP GET requests on port $port_number, interface $interface_name"
  # Match the "GET " string in ASCII
  local options="-s 0 -A"
  [ "$verbose" = true ] && options="-nvvvs 0 -A"
  sudo tcpdump -i "$interface_name" $options "tcp port $port_number and (tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x47455420)" # GET
}' # Monitor HTTP GET requests with human-readable output

alias tcpd-http-post='() {
  echo "Monitor HTTP POST requests."
  echo "Usage: tcpd-http-post [port_number:80] [interface_name:any]"
  echo "Example: tcpd-http-post 8080 eth0"

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Set default values
  local port_number="${1:-80}"
  local interface_name="${2:-any}"

  # Validate port number
  if ! [[ "$port_number" =~ ^[0-9]+$ ]]; then
    _tcpdump_error "Invalid port number: $port_number. Must be a number."
    return 1
  fi

  echo "Monitoring HTTP POST requests on port $port_number, interface $interface_name"
  # Match the "POST " string in ASCII
  sudo tcpdump -i "$interface_name" -s 0 -A "tcp port $port_number and (tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x504f5354)" # POST
}' # Monitor HTTP POST requests with human-readable output

alias tcpd-http-request='() {
  echo "Monitor HTTP request methods (GET, POST, PUT, DELETE, etc)."
  echo "Usage: tcpd-http-request [method:all] [port_number:80] [interface_name:any]"
  echo "Example: tcpd-http-request GET 8080 eth0"
  echo "Available methods: GET, POST, PUT, DELETE, HEAD, PATCH, OPTIONS, or all"
  echo "Options:"
  echo "  -v      Verbose output (show more packet details)"

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Parse options
  local verbose=false
  local OPTIND=1
  while getopts ":v" opt; do
    case "$opt" in
      v) verbose=true ;;
      \?) _tcpdump_error "Invalid option: -$OPTARG"; return 1 ;;
    esac
  done
  shift $((OPTIND-1))

  # Set default values
  local method="${1:-all}"
  local port_number="${2:-80}"
  local interface_name="${3:-any}"

  # Validate port number
  if ! [[ "$port_number" =~ ^[0-9]+$ ]]; then
    _tcpdump_error "Invalid port number: $port_number. Must be a number."
    return 1
  fi

  # Convert method to uppercase
  method=$(echo "$method" | tr "[:lower:]" "[:upper:]")

  local filter_expr=""
  case "$method" in
    "GET")
      filter_expr="tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x47455420" # GET
      ;;
    "POST")
      filter_expr="tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x504f5354" # POST
      ;;
    "PUT")
      filter_expr="tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x50555420" # PUT
      ;;
    "DELETE")
      filter_expr="tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x44454c45" # DELE
      ;;
    "HEAD")
      filter_expr="tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x48454144" # HEAD
      ;;
    "PATCH")
      filter_expr="tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x50415443" # PATC
      ;;
    "OPTIONS")
      filter_expr="tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x4f505449" # OPTI
      ;;
    "ALL")
      filter_expr="(((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)" # Any HTTP traffic with payload
      ;;
    *)
      _tcpdump_error "Unknown HTTP method: $method"
      return 1
      ;;
  esac

  echo "Monitoring HTTP $method requests on port $port_number, interface $interface_name"
  local cmd_options="-s 0 -A"
  [ "$verbose" = true ] && cmd_options="-nvvvs 0 -A"
  sudo tcpdump -i "$interface_name" $cmd_options "tcp port $port_number and ($filter_expr)"
}' # Monitor specific HTTP request methods with human-readable output

alias tcpd-http-url='() {
  echo "Monitor HTTP traffic containing specific URL patterns."
  echo "Usage: tcpd-http-url <url_pattern> [port_number:80] [interface_name:any]"
  echo "Example: tcpd-http-url \"login\" 80 any"
  echo "         This will capture packets containing \"login\" in the URL"

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Verify parameters
  if [ $# -eq 0 ]; then
    _tcpdump_error "URL pattern not specified. Please provide a URL pattern to search for."
    return 1
  fi

  # Set parameters
  local url_pattern="$1"
  local port_number="${2:-80}"
  local interface_name="${3:-any}"

  # Validate port number
  if ! [[ "$port_number" =~ ^[0-9]+$ ]]; then
    _tcpdump_error "Invalid port number: $port_number. Must be a number."
    return 1
  fi

  echo "Monitoring HTTP traffic containing \"$url_pattern\" on port $port_number, interface $interface_name"
  # Use ASCII display and grep for the pattern
  sudo tcpdump -i "$interface_name" -s 0 -A "tcp port $port_number" | grep --line-buffered "$url_pattern"
}' # Monitor HTTP traffic containing specific URL patterns

# Protocol-Specific Monitoring Commands
# ---------------------------------

alias tcpd-dns='() {
  echo "Monitor DNS traffic."
  echo "Usage: tcpd-dns [interface_name:any] [options]"
  echo "Example: tcpd-dns eth0 -v"
  echo "Options:"
  echo "  -v      Verbose output (show more packet details)"
  echo "  -q      Show DNS query packets only"
  echo "  -r      Show DNS response packets only"
  echo "  -c <count:10>  Show only specified number of packets"
  echo "  -p <port:53>   Specify DNS port number (default: 53)"

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Parse options
  local verbose=false
  local queries_only=false
  local responses_only=false
  local packet_count=""
  local dns_port="53"
  local OPTIND=1

  while getopts ":vqrc:p:" opt; do
    case "$opt" in
      v) verbose=true ;;
      q) queries_only=true ;;
      r) responses_only=true ;;
      c) packet_count="$OPTARG" ;;
      p) dns_port="$OPTARG" ;;
      \?) _tcpdump_error "Invalid option: -$OPTARG"; return 1 ;;
    esac
  done
  shift $((OPTIND-1))

  # Set interface
  local interface_name="${1:-any}"

  # Build options string
  local options="-n"
  if [ "$verbose" = true ]; then
    options="$options -vv"
  fi

  if [ -n "$packet_count" ]; then
    options="$options -c $packet_count"
    echo "Limiting output to $packet_count packets..."
  fi

  # Build filter
  local filter="port $dns_port"

  if [ "$queries_only" = true ] && [ "$responses_only" = true ]; then
    # If both are set, just show all DNS traffic
    echo "Showing both DNS queries and responses"
  elif [ "$queries_only" = true ]; then
    # DNS queries have QR bit = 0 in flags
    filter="$filter and udp[10] & 0x80 = 0"
    echo "Showing DNS queries only"
  elif [ "$responses_only" = true ]; then
    # DNS responses have QR bit = 1 in flags
    filter="$filter and udp[10] & 0x80 = 0x80"
    echo "Showing DNS responses only"
  fi

  echo "Monitoring DNS traffic on port $dns_port, interface $interface_name"
  sudo tcpdump -i "$interface_name" $options "$filter"
}' # Monitor DNS queries and responses

alias tcpd-icmp='() {
  echo "Monitor ICMP traffic."
  echo "Usage: tcpd-icmp [interface_name:any] [options]"
  echo "Example: tcpd-icmp eth0 -t echo-request"
  echo "Options:"
  echo "  -v      Verbose output (show more packet details)"
  echo "  -t <type>   ICMP type filter (echo-request, echo-reply, time-exceeded)"
  echo "  -c <count:10>  Show only specified number of packets"

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Parse options
  local verbose=false
  local icmp_type=""
  local packet_count=""
  local OPTIND=1

  while getopts ":vt:c:" opt; do
    case "$opt" in
      v) verbose=true ;;
      t) icmp_type="$OPTARG" ;;
      c) packet_count="$OPTARG" ;;
      \?) _tcpdump_error "Invalid option: -$OPTARG"; return 1 ;;
    esac
  done
  shift $((OPTIND-1))

  # Set interface
  local interface_name="${1:-any}"

  # Build options string
  local options="-n"
  if [ "$verbose" = true ]; then
    options="$options -vv"
  fi

  if [ -n "$packet_count" ]; then
    options="$options -c $packet_count"
    echo "Limiting output to $packet_count packets..."
  fi

  # Build filter
  local filter="icmp"

  case "$icmp_type" in
    "echo-request"|"ping")
      # ICMP echo request (ping)
      filter="$filter and icmp[icmptype] = icmp-echo"
      echo "Filtering for ICMP echo requests (ping)"
      ;;
    "echo-reply"|"pong")
      # ICMP echo reply (ping response)
      filter="$filter and icmp[icmptype] = icmp-echoreply"
      echo "Filtering for ICMP echo replies (ping responses)"
      ;;
    "time-exceeded"|"ttl")
      # ICMP time exceeded (TTL exceeded)
      filter="$filter and icmp[icmptype] = icmp-timxceed"
      echo "Filtering for ICMP time exceeded messages"
      ;;
    "")
      # No specific type, show all ICMP
      echo "Showing all ICMP traffic"
      ;;
    *)
      _tcpdump_error "Unknown ICMP type: $icmp_type"
      echo "Available types: echo-request/ping, echo-reply/pong, time-exceeded/ttl"
      return 1
      ;;
  esac

  echo "Monitoring ICMP traffic on interface $interface_name"
  sudo tcpdump -i "$interface_name" $options "$filter"
}' # Monitor ICMP traffic (ping, traceroute, etc.)

alias tcpd-tcp-flags='() {
  echo "Monitor TCP traffic with specific flag combinations."
  echo "Usage: tcpd-tcp-flags [flag_type] [interface_name:any] [options]"
  echo "Example: tcpd-tcp-flags syn eth0 -v"
  echo "Flag types:"
  echo "  syn       - SYN packets (connection initialization)"
  echo "  syn-ack   - SYN+ACK packets (connection response)"
  echo "  fin       - FIN packets (connection termination)"
  echo "  rst       - RST packets (connection reset)"
  echo "  ack       - ACK packets only"
  echo "  push      - PUSH packets (data packets)"
  echo "Options:"
  echo "  -v      Verbose output (show more packet details)"
  echo "  -p <port>   Filter by port number"
  echo "  -c <count:10>  Show only specified number of packets"

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Parse options
  local verbose=false
  local port_filter=""
  local packet_count=""
  local OPTIND=1

  while getopts ":vp:c:" opt; do
    case "$opt" in
      v) verbose=true ;;
      p) port_filter="$OPTARG" ;;
      c) packet_count="$OPTARG" ;;
      \?) _tcpdump_error "Invalid option: -$OPTARG"; return 1 ;;
    esac
  done
  shift $((OPTIND-1))

  # Set flag type and interface
  local flag_type="${1:-syn}"
  local interface_name="${2:-any}"

  # Build options string
  local options="-n"
  if [ "$verbose" = true ]; then
    options="$options -vv"
  fi

  if [ -n "$packet_count" ]; then
    options="$options -c $packet_count"
    echo "Limiting output to $packet_count packets..."
  fi

  # Build filter
  local flag_filter=""
  case "$flag_type" in
    "syn")
      # SYN packets (TCP flags: SYN=1, ACK=0, FIN=0, RST=0)
      flag_filter="tcp[tcpflags] & (tcp-syn|tcp-ack|tcp-fin|tcp-rst) == tcp-syn"
      echo "Monitoring SYN packets (connection initialization)"
      ;;
    "syn-ack")
      # SYN+ACK packets (TCP flags: SYN=1, ACK=1)
      flag_filter="tcp[tcpflags] & (tcp-syn|tcp-ack) == (tcp-syn|tcp-ack)"
      echo "Monitoring SYN+ACK packets (connection response)"
      ;;
    "fin")
      # FIN packets
      flag_filter="tcp[tcpflags] & tcp-fin != 0"
      echo "Monitoring FIN packets (connection termination)"
      ;;
    "rst")
      # RST packets
      flag_filter="tcp[tcpflags] & tcp-rst != 0"
      echo "Monitoring RST packets (connection reset)"
      ;;
    "ack")
      # Pure ACK packets (no SYN, FIN, RST, PSH)
      flag_filter="tcp[tcpflags] & (tcp-syn|tcp-fin|tcp-rst|tcp-push) == 0 and tcp[tcpflags] & tcp-ack != 0"
      echo "Monitoring pure ACK packets"
      ;;
    "push")
      # PUSH packets (data packets)
      flag_filter="tcp[tcpflags] & tcp-push != 0"
      echo "Monitoring PUSH packets (data packets)"
      ;;
    *)
      _tcpdump_error "Unknown flag type: $flag_type"
      return 1
      ;;
  esac

  local filter="tcp and $flag_filter"

  # Add port filter if specified
  if [ -n "$port_filter" ]; then
    filter="$filter and port $port_filter"
    echo "Filtering by port: $port_filter"
  fi

  echo "Monitoring TCP flags on interface $interface_name"
  sudo tcpdump -i "$interface_name" $options "$filter"
}' # Monitor specific TCP flag combinations

alias tcpd-tcp-handshake='() {
  echo "Monitor TCP 3-way handshake traffic."
  echo "Usage: tcpd-tcp-handshake [interface_name:any] [options]"
  echo "Example: tcpd-tcp-handshake eth0 -p 80"
  echo "Options:"
  echo "  -p <port>   Filter by port number"
  echo "  -h <host>   Filter by host IP address"
  echo "  -v          Verbose output (show more details)"

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Parse options
  local port_filter=""
  local host_filter=""
  local verbose=false
  local OPTIND=1

  while getopts ":p:h:v" opt; do
    case "$opt" in
      p) port_filter="$OPTARG" ;;
      h) host_filter="$OPTARG" ;;
      v) verbose=true ;;
      \?) _tcpdump_error "Invalid option: -$OPTARG"; return 1 ;;
    esac
  done
  shift $((OPTIND-1))

  # Set interface
  local interface_name="${1:-any}"

  # Build options string
  local options="-n"
  if [ "$verbose" = true ]; then
    options="$options -vv"
  fi

  # Build filter for handshake packets (SYN, SYN+ACK, ACK)
  local filter="tcp[tcpflags] & (tcp-syn|tcp-ack) != 0 and tcp[tcpflags] & (tcp-fin|tcp-rst) == 0"

  # Add port filter if specified
  if [ -n "$port_filter" ]; then
    filter="$filter and port $port_filter"
    echo "Filtering by port: $port_filter"
  fi

  # Add host filter if specified
  if [ -n "$host_filter" ]; then
    filter="$filter and host $host_filter"
    echo "Filtering by host: $host_filter"
  fi

  echo "Monitoring TCP handshake traffic on interface $interface_name"
  sudo tcpdump -i "$interface_name" $options "$filter"
}' # Monitor TCP 3-way handshake connections

alias tcpd-udp='() {
  echo "Monitor UDP traffic."
  echo "Usage: tcpd-udp [interface_name:any] [options]"
  echo "Example: tcpd-udp eth0 -p 53"
  echo "Options:"
  echo "  -p <port>   Filter by port number"
  echo "  -v          Verbose output with packet content"
  echo "  -x          Show hex and ASCII dump of packet content"
  echo "  -c <count:10>  Show only specified number of packets"

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Parse options
  local port_filter=""
  local verbose=false
  local hex_dump=false
  local packet_count=""
  local OPTIND=1

  while getopts ":p:vxc:" opt; do
    case "$opt" in
      p) port_filter="$OPTARG" ;;
      v) verbose=true ;;
      x) hex_dump=true ;;
      c) packet_count="$OPTARG" ;;
      \?) _tcpdump_error "Invalid option: -$OPTARG"; return 1 ;;
    esac
  done
  shift $((OPTIND-1))

  # Set interface
  local interface_name="${1:-any}"

  # Build options string
  local options="-n"
  if [ "$verbose" = true ]; then
    options="$options -vv"
  fi

  if [ "$hex_dump" = true ]; then
    if [ "$verbose" = true ]; then
      options="$options -XSs 0"
    else
      options="$options -Xs 0"
    fi
  fi

  if [ -n "$packet_count" ]; then
    options="$options -c $packet_count"
    echo "Limiting output to $packet_count packets..."
  fi

  # Build filter
  local filter="udp"

  # Add port filter if specified
  if [ -n "$port_filter" ]; then
    filter="$filter and port $port_filter"
    echo "Filtering by port: $port_filter"
  fi

  echo "Monitoring UDP traffic on interface $interface_name"
  sudo tcpdump -i "$interface_name" $options "$filter"
}' # Monitor UDP traffic

alias tcpd-tcp-retransmit='() {
  echo "Monitor TCP retransmissions."
  echo "Usage: tcpd-tcp-retransmit [interface_name:any] [options]"
  echo "Example: tcpd-tcp-retransmit eth0 -v"
  echo "Options:"
  echo "  -v          Verbose output"
  echo "  -p <port>   Filter by port number"

  # Check if tcpdump is installed
  _tcpdump_check_installed || return 1

  # Parse options
  local verbose=false
  local port_filter=""
  local OPTIND=1

  while getopts ":vp:" opt; do
    case "$opt" in
      v) verbose=true ;;
      p) port_filter="$OPTARG" ;;
      \?) _tcpdump_error "Invalid option: -$OPTARG"; return 1 ;;
    esac
  done
  shift $((OPTIND-1))

  # Set interface
  local interface_name="${1:-any}"

  # Build options string
  local options="-nn"
  if [ "$verbose" = true ]; then
    options="$options -v"
  fi

  # TCP retransmission filter
  # This is a simplified approach - detecting retransmissions
  # correctly requires stateful connection tracking
  local filter="tcp and (tcp[tcpflags] & tcp-syn) == 0 and (tcp[tcpflags] & tcp-rst) == 0 and (tcp[4:4] = 1 or tcp[4:4] = 2)"

  # Add port filter if specified
  if [ -n "$port_filter" ]; then
    filter="$filter and port $port_filter"
    echo "Filtering by port: $port_filter"
  fi

  echo "Monitoring TCP retransmissions on interface $interface_name"
  echo "Note: This is an approximate detection. Some retransmissions might be missed."
  sudo tcpdump -i "$interface_name" $options "$filter"
}' # Monitor TCP retransmissions (approximate)

# Advanced Usage Commands
# ---------------------

alias tcpd-help='() {
  echo -e "tcpdump aliases help guide - Enhanced with Advanced Filtering\n------------------------------------------------------"
  echo ""
  echo "Enhanced Basic Commands (with IP/Size filtering):"
  echo "  tcpd-basic        - Basic packet capturing with advanced filtering"
  echo "                      Options: --source-ip ip, --dest-ip ip, --min-size size,"
  echo "                               --max-size size, --port port, --interface iface,"
  echo "                               --data-only, --count, --help"
  echo "                      Example: tcpd-basic --source-ip 192.168.1.100 --port 80"
  echo "  tcpd-detail       - Detailed packet capturing with verbose output"
  echo "                      Options: --source-ip ip, --dest-ip ip, --min-size size,"
  echo "                               --max-size size, --port port, --interface iface,"
  echo "                               --protocol proto, --data-only, --count count, --help"
  echo "                      Example: tcpd-detail --dest-ip 10.0.0.0/24 --protocol tcp"
  echo "  tcpd-full         - Full packet capturing with hex and ascii output"
  echo "                      Options: -d (data payload only), -c (packet count), -s (snap length)"
  echo ""
  echo "Enhanced Port Commands (with IP/Size filtering):"
  echo "  tcpd-port         - Monitor specific port with advanced filtering"
  echo "                      Usage: tcpd-port <port> [--source-ip ip] [--dest-ip ip]"
  echo "                             [--min-size size] [--max-size size] [--interface iface]"
  echo "                             [--data-only] [--verbose] [--hex] [--count count]"
  echo "                      Example: tcpd-port 443 --source-ip 192.168.1.100 --min-size 1000"
  echo "  tcpd-port-detail  - Monitor interface and port with detailed output"
  echo "                      Options: -d (data payload only), -c (packet count), -a (ASCII only)"
  echo "  tcpd-any-port     - Monitor any interface for specific port"
  echo "                      Options: -v (verbose), -x (hex+ASCII), -a (ASCII only)"
  echo "  tcpd-src-port     - Monitor traffic from source IP to port"
  echo "  tcpd-portrange    - Monitor port range with size filter"
  echo ""
  echo "Interface Commands:"
  echo "  tcpd-iface        - Monitor specific network interface"
  echo "                      Options: -d (data payload only), -v (verbose), -x (hex+ASCII)"
  echo ""
  echo "Network Commands:"
  echo "  tcpd-network      - Monitor traffic between networks"
  echo "  tcpd-subnet       - Monitor subnet traffic"
  echo "  tcpd-src-dst      - Monitor source IP to destination port"
  echo ""
  echo "Protocol Commands:"
  echo "  tcpd-dns          - Monitor DNS queries and responses"
  echo "                      Options: -q (queries only), -r (responses only), -v (verbose)"
  echo "  tcpd-icmp         - Monitor ICMP traffic (ping, traceroute)"
  echo "                      Options: -t <type> (echo-request, echo-reply, time-exceeded)"
  echo "  tcpd-tcp-flags    - Monitor TCP packets with specific flags"
  echo "                      Types: syn, syn-ack, fin, rst, ack, push"
  echo "  tcpd-tcp-handshake - Monitor TCP 3-way handshake connections"
  echo "  tcpd-udp          - Monitor UDP traffic"
  echo "                      Options: -p <port>, -v (verbose), -x (hex+ASCII dump)"
  echo "  tcpd-tcp-retransmit - Monitor TCP retransmissions"
  echo ""
  echo "HTTP Analysis Commands:"
  echo "  tcpd-http         - Monitor HTTP traffic with human-readable format"
  echo "                      Options: -a (ASCII), -x (hex+ASCII), -h (headers), -f (data only)"
  echo "  tcpd-http-headers - Display HTTP headers in readable format"
  echo "  tcpd-https        - Monitor HTTPS encrypted traffic"
  echo "                      Options: -a (ASCII), -x (hex+ASCII)"
  echo "  tcpd-http-get     - Monitor HTTP GET requests"
  echo "                      Options: -v (verbose)"
  echo "  tcpd-http-post    - Monitor HTTP POST requests"
  echo "  tcpd-http-request - Monitor specific HTTP request methods"
  echo "                      Options: -v (verbose)"
  echo "  tcpd-http-url     - Monitor HTTP traffic with specific URL patterns"
  echo ""
  echo "Advanced Commands:"
  echo "  tcpd-size         - Filter packets by size"
  echo "  tcpd-complex      - Complex filtering with multiple conditions"
  echo ""
  echo "Utility Commands:"
  echo "  tcpd-save         - Save packet capture to file"
  echo "  tcpd-read         - Read packet capture from file"
  echo ""
  echo "New Filtering Features:"
  echo "  • Source/Destination IP filtering with CIDR support (e.g., 192.168.1.0/24)"
  echo "  • Packet size filtering (minimum/maximum bytes)"
  echo "  • Protocol filtering (tcp, udp, icmp, ip)"
  echo "  • Combined filters with logical AND operations"
  echo "  • Comprehensive parameter validation"
  echo ""
  echo "Usage Examples:"
  echo "  tcpd-basic --source-ip 192.168.1.100 --dest-ip 10.0.0.1 --min-size 1000"
  echo "  tcpd-detail --protocol tcp --port 443 --max-size 5000 --count 100"
  echo "  tcpd-port 80 --source-ip 192.168.1.0/24 --verbose --hex"
  echo ""
  echo "For more detailed help on each command, run: command_name --help"
}' # Enhanced help information with new filtering features
