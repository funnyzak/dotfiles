# Description: IP related aliases for IP address operations, CIDR calculations, subnet analysis, and network utilities.

# Helper functions for IP aliases
_show_error_ip_aliases() {
  echo "$1" >&2
  return 1
}

_show_usage_ip_aliases() {
  echo -e "$1"
  return 0
}

_check_command_ip_aliases() {
  if ! command -v "$1" &> /dev/null; then
    _show_error_ip_aliases "Error: Required command \"$1\" not found. Please install it first."
    return 1
  fi
  return 0
}

_validate_ip_ip_aliases() {
  local ip_addr="$1"
  if echo "$ip_addr" | grep -qE "^([0-9]{1,3}\.){3}[0-9]{1,3}$"; then
    # Check each octet is between 0-255
    local IFS="."
    for octet in $ip_addr; do
      if [ "$octet" -gt 255 ] || [ "$octet" -lt 0 ]; then
        return 1
      fi
    done
    return 0
  fi
  return 1
}

_validate_cidr_ip_aliases() {
  local cidr="$1"
  if echo "$cidr" | grep -qE "^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$"; then
    local ip_part=$(echo "$cidr" | cut -d"/" -f1)
    local prefix_part=$(echo "$cidr" | cut -d"/" -f2)

    if ! _validate_ip_ip_aliases "$ip_part"; then
      return 1
    fi

    if [ "$prefix_part" -gt 32 ] || [ "$prefix_part" -lt 0 ]; then
      return 1
    fi

    return 0
  fi
  return 1
}

_ip_to_decimal_ip_aliases() {
  local ip="$1"
  local IFS="."
  local decimal=0
  local multiplier=16777216  # 256^3

  for octet in $ip; do
    decimal=$((decimal + octet * multiplier))
    multiplier=$((multiplier / 256))
  done

  echo "$decimal"
}

_decimal_to_ip_ip_aliases() {
  local decimal="$1"
  local octet1=$((decimal / 16777216))
  local octet2=$(((decimal % 16777216) / 65536))
  local octet3=$(((decimal % 65536) / 256))
  local octet4=$((decimal % 256))

  echo "$octet1.$octet2.$octet3.$octet4"
}

# IP Information and Query Functions
### --- ###

alias ip-myip='() {
  _show_usage_ip_aliases "Get your public IP address.\nUsage:\n ip-myip [service:ipinfo]\nServices: ipinfo, ipify, icanhazip\nExample:\n ip-myip\n ip-myip ipify"

  local service="${1:-ipinfo}"
  local url=""

  case "$service" in
    "ipinfo")
      url="https://ipinfo.io/ip"
      ;;
    "ipify")
      url="https://api.ipify.org"
      ;;
    "icanhazip")
      url="https://icanhazip.com"
      ;;
    *)
      _show_error_ip_aliases "Error: Unknown service \"$service\". Available services: ipinfo, ipify, icanhazip"
      return 1
      ;;
  esac

  if ! _check_command_ip_aliases curl; then
    return 1
  fi

  local result
  result=$(curl -s --connect-timeout 10 "$url" 2>/dev/null)

  if [ $? -ne 0 ] || [ -z "$result" ]; then
    _show_error_ip_aliases "Failed to retrieve public IP address from $service. Check your internet connection."
    return 1
  fi

  echo "$result" | tr -d "\\n\\r"
  echo
}' # Get your public IP address from various services

alias ip-info='() {
  _show_usage_ip_aliases "Get detailed IP information.\nUsage:\n ip-info [ip_address:current]\nExamples:\n ip-info\n ip-info 8.8.8.8\n ip-info 1.1.1.1"

  if ! _check_command_ip_aliases curl; then
    return 1
  fi

  local target_ip="$1"
  local url="https://ipinfo.io"

  if [ -n "$target_ip" ]; then
    if ! _validate_ip_ip_aliases "$target_ip"; then
      _show_error_ip_aliases "Error: Invalid IP address format: $target_ip"
      return 1
    fi
    url="$url/$target_ip"
  fi

  local result
  result=$(curl -s --connect-timeout 10 "$url" 2>/dev/null)

  if [ $? -ne 0 ] || [ -z "$result" ]; then
    _show_error_ip_aliases "Failed to retrieve IP information. Check your internet connection."
    return 1
  fi

  echo "$result"
}' # Get detailed IP information including location, ISP, and organization

alias ip-geolocate='() {
  _show_usage_ip_aliases "Get geolocation information for an IP address.\nUsage:\n ip-geolocate [ip_address:current]\nExamples:\n ip-geolocate\n ip-geolocate 8.8.8.8"

  if ! _check_command_ip_aliases curl; then
    return 1
  fi

  local target_ip="$1"
  local url="https://ipinfo.io"

  if [ -n "$target_ip" ]; then
    if ! _validate_ip_ip_aliases "$target_ip"; then
      _show_error_ip_aliases "Error: Invalid IP address format: $target_ip"
      return 1
    fi
    url="$url/$target_ip/json"
  else
    url="$url/json"
  fi

  local result
  result=$(curl -s --connect-timeout 10 "$url" 2>/dev/null)

  if [ $? -ne 0 ] || [ -z "$result" ]; then
    _show_error_ip_aliases "Failed to retrieve geolocation information. Check your internet connection."
    return 1
  fi

  # Extract key information using basic text processing
  echo "IP Address: $(echo "$result" | grep -o "\\\"ip\\\":\\\"[^\\\"]*\\\"" | cut -d"\"" -f4)"
  echo "City: $(echo "$result" | grep -o "\\\"city\\\":\\\"[^\\\"]*\\\"" | cut -d"\"" -f4)"
  echo "Region: $(echo "$result" | grep -o "\\\"region\\\":\\\"[^\\\"]*\\\"" | cut -d"\"" -f4)"
  echo "Country: $(echo "$result" | grep -o "\\\"country\\\":\\\"[^\\\"]*\\\"" | cut -d"\"" -f4)"
  echo "Location: $(echo "$result" | grep -o "\\\"loc\\\":\\\"[^\\\"]*\\\"" | cut -d"\"" -f4)"
  echo "Organization: $(echo "$result" | grep -o "\\\"org\\\":\\\"[^\\\"]*\\\"" | cut -d"\"" -f4)"
  echo "Timezone: $(echo "$result" | grep -o "\\\"timezone\\\":\\\"[^\\\"]*\\\"" | cut -d"\"" -f4)"
}' # Get geolocation information for IP addresses

alias ip-whois='() {
  _show_usage_ip_aliases "Get WHOIS information for an IP address.\nUsage:\n ip-whois <ip_address>\nExample:\n ip-whois 8.8.8.8"

  if [ $# -eq 0 ]; then
    _show_error_ip_aliases "Error: IP address parameter is required."
    return 1
  fi

  local target_ip="$1"

  if ! _validate_ip_ip_aliases "$target_ip"; then
    _show_error_ip_aliases "Error: Invalid IP address format: $target_ip"
    return 1
  fi

  if ! _check_command_ip_aliases whois; then
    return 1
  fi

  if ! whois "$target_ip"; then
    _show_error_ip_aliases "Failed to retrieve WHOIS information for $target_ip."
    return 1
  fi
}' # Get WHOIS information for an IP address

# CIDR and Subnet Calculation Functions
### --- ###

alias ip-cidr-info='() {
  _show_usage_ip_aliases "Get detailed information about a CIDR block.\nUsage:\n ip-cidr-info <cidr_notation>\nExamples:\n ip-cidr-info 192.168.1.0/24\n ip-cidr-info 10.0.0.0/8"

  if [ $# -eq 0 ]; then
    _show_error_ip_aliases "Error: CIDR notation parameter is required."
    return 1
  fi

  local cidr="$1"

  if ! _validate_cidr_ip_aliases "$cidr"; then
    _show_error_ip_aliases "Error: Invalid CIDR notation: $cidr"
    return 1
  fi

  local network_ip=$(echo "$cidr" | cut -d"/" -f1)
  local prefix_length=$(echo "$cidr" | cut -d"/" -f2)

  # Calculate subnet mask
  local mask_decimal=$((0xFFFFFFFF << (32 - prefix_length)))
  local subnet_mask=$(_decimal_to_ip_ip_aliases "$mask_decimal")

  # Calculate network address
  local network_decimal=$(_ip_to_decimal_ip_aliases "$network_ip")
  local network_addr_decimal=$((network_decimal & mask_decimal))
  local network_addr=$(_decimal_to_ip_ip_aliases "$network_addr_decimal")

  # Calculate broadcast address
  local wildcard_decimal=$((0xFFFFFFFF >> prefix_length))
  local broadcast_decimal=$((network_addr_decimal | wildcard_decimal))
  local broadcast_addr=$(_decimal_to_ip_ip_aliases "$broadcast_decimal")

  # Calculate first and last usable IPs
  local first_usable_decimal=$((network_addr_decimal + 1))
  local last_usable_decimal=$((broadcast_decimal - 1))
  local first_usable=$(_decimal_to_ip_ip_aliases "$first_usable_decimal")
  local last_usable=$(_decimal_to_ip_ip_aliases "$last_usable_decimal")

  # Calculate total hosts
  local total_hosts=$((2 ** (32 - prefix_length)))
  local usable_hosts=$((total_hosts - 2))

  echo "CIDR Block: $cidr"
  echo "Network Address: $network_addr"
  echo "Subnet Mask: $subnet_mask"
  echo "Broadcast Address: $broadcast_addr"
  echo "First Usable IP: $first_usable"
  echo "Last Usable IP: $last_usable"
  echo "Total Hosts: $total_hosts"
  echo "Usable Hosts: $usable_hosts"
  echo "Prefix Length: /$prefix_length"
}' # Get detailed information about a CIDR block

alias ip-subnet-calc='() {
  _show_usage_ip_aliases "Calculate subnet information from IP and subnet mask.\nUsage:\n ip-subnet-calc <ip_address> <subnet_mask>\nExamples:\n ip-subnet-calc 192.168.1.100 255.255.255.0\n ip-subnet-calc 10.0.0.50 255.0.0.0"

  if [ $# -ne 2 ]; then
    _show_error_ip_aliases "Error: Both IP address and subnet mask parameters are required."
    return 1
  fi

  local ip_addr="$1"
  local subnet_mask="$2"

  if ! _validate_ip_ip_aliases "$ip_addr"; then
    _show_error_ip_aliases "Error: Invalid IP address format: $ip_addr"
    return 1
  fi

  if ! _validate_ip_ip_aliases "$subnet_mask"; then
    _show_error_ip_aliases "Error: Invalid subnet mask format: $subnet_mask"
    return 1
  fi

  # Convert to decimal
  local ip_decimal=$(_ip_to_decimal_ip_aliases "$ip_addr")
  local mask_decimal=$(_ip_to_decimal_ip_aliases "$subnet_mask")

  # Calculate prefix length
  local prefix_length=0
  local temp_mask="$mask_decimal"
  while [ $((temp_mask & 1)) -eq 0 ] && [ "$temp_mask" -ne 0 ]; do
    temp_mask=$((temp_mask >> 1))
  done
  while [ $((temp_mask & 1)) -eq 1 ]; do
    prefix_length=$((prefix_length + 1))
    temp_mask=$((temp_mask >> 1))
  done
  prefix_length=$((32 - (32 - prefix_length)))

  # Calculate network address
  local network_decimal=$((ip_decimal & mask_decimal))
  local network_addr=$(_decimal_to_ip_ip_aliases "$network_decimal")

  # Calculate broadcast address
  local wildcard_decimal=$((0xFFFFFFFF ^ mask_decimal))
  local broadcast_decimal=$((network_decimal | wildcard_decimal))
  local broadcast_addr=$(_decimal_to_ip_ip_aliases "$broadcast_decimal")

  # Calculate first and last usable IPs
  local first_usable_decimal=$((network_decimal + 1))
  local last_usable_decimal=$((broadcast_decimal - 1))
  local first_usable=$(_decimal_to_ip_ip_aliases "$first_usable_decimal")
  local last_usable=$(_decimal_to_ip_ip_aliases "$last_usable_decimal")

  # Calculate total hosts
  local total_hosts=$((wildcard_decimal + 1))
  local usable_hosts=$((total_hosts - 2))

  echo "Input IP: $ip_addr"
  echo "Subnet Mask: $subnet_mask"
  echo "CIDR Notation: $network_addr/$prefix_length"
  echo "Network Address: $network_addr"
  echo "Broadcast Address: $broadcast_addr"
  echo "First Usable IP: $first_usable"
  echo "Last Usable IP: $last_usable"
  echo "Total Hosts: $total_hosts"
  echo "Usable Hosts: $usable_hosts"
}' # Calculate subnet information from IP and subnet mask

alias ip-cidr-contains='() {
  _show_usage_ip_aliases "Check if an IP address is within a CIDR block.\nUsage:\n ip-cidr-contains <cidr_block> <ip_address>\nExamples:\n ip-cidr-contains 192.168.1.0/24 192.168.1.100\n ip-cidr-contains 10.0.0.0/8 10.5.5.5"

  if [ $# -ne 2 ]; then
    _show_error_ip_aliases "Error: Both CIDR block and IP address parameters are required."
    return 1
  fi

  local cidr="$1"
  local test_ip="$2"

  if ! _validate_cidr_ip_aliases "$cidr"; then
    _show_error_ip_aliases "Error: Invalid CIDR notation: $cidr"
    return 1
  fi

  if ! _validate_ip_ip_aliases "$test_ip"; then
    _show_error_ip_aliases "Error: Invalid IP address format: $test_ip"
    return 1
  fi

  local network_ip=$(echo "$cidr" | cut -d"/" -f1)
  local prefix_length=$(echo "$cidr" | cut -d"/" -f2)

  # Calculate subnet mask
  local mask_decimal=$((0xFFFFFFFF << (32 - prefix_length)))

  # Calculate network addresses
  local network_decimal=$(_ip_to_decimal_ip_aliases "$network_ip")
  local test_decimal=$(_ip_to_decimal_ip_aliases "$test_ip")

  local network_addr_decimal=$((network_decimal & mask_decimal))
  local test_network_decimal=$((test_decimal & mask_decimal))

  if [ "$network_addr_decimal" -eq "$test_network_decimal" ]; then
    echo "YES: $test_ip is within the CIDR block $cidr"
    return 0
  else
    echo "NO: $test_ip is NOT within the CIDR block $cidr"
    return 1
  fi
}' # Check if an IP address is within a CIDR block

alias ip-cidr-split='() {
  _show_usage_ip_aliases "Split a CIDR block into smaller subnets.\nUsage:\n ip-cidr-split <cidr_block> <new_prefix_length>\nExamples:\n ip-cidr-split 192.168.1.0/24 26\n ip-cidr-split 10.0.0.0/16 24"

  if [ $# -ne 2 ]; then
    _show_error_ip_aliases "Error: Both CIDR block and new prefix length parameters are required."
    return 1
  fi

  local cidr="$1"
  local new_prefix="$2"

  if ! _validate_cidr_ip_aliases "$cidr"; then
    _show_error_ip_aliases "Error: Invalid CIDR notation: $cidr"
    return 1
  fi

  if ! echo "$new_prefix" | grep -q "^[0-9]\+$" || [ "$new_prefix" -lt 1 ] || [ "$new_prefix" -gt 32 ]; then
    _show_error_ip_aliases "Error: New prefix length must be between 1 and 32."
    return 1
  fi

  local network_ip=$(echo "$cidr" | cut -d"/" -f1)
  local old_prefix=$(echo "$cidr" | cut -d"/" -f2)

  if [ "$new_prefix" -le "$old_prefix" ]; then
    _show_error_ip_aliases "Error: New prefix length must be greater than current prefix length ($old_prefix)."
    return 1
  fi

  # Calculate number of subnets
  local subnet_bits=$((new_prefix - old_prefix))
  local num_subnets=$((2 ** subnet_bits))
  local subnet_size=$((2 ** (32 - new_prefix)))

  echo "Splitting $cidr into /$new_prefix subnets:"
  echo "Number of subnets: $num_subnets"
  echo "Hosts per subnet: $((subnet_size - 2))"
  echo ""

  # Calculate and display each subnet
  local network_decimal=$(_ip_to_decimal_ip_aliases "$network_ip")
  local current_network="$network_decimal"

  local count=0
  while [ "$count" -lt "$num_subnets" ]; do
    local subnet_ip=$(_decimal_to_ip_ip_aliases "$current_network")
    echo "$subnet_ip/$new_prefix"
    current_network=$((current_network + subnet_size))
    count=$((count + 1))
  done
}' # Split a CIDR block into smaller subnets

# IP Conversion and Utility Functions
### --- ###

alias ip-to-decimal='() {
  _show_usage_ip_aliases "Convert IP address to decimal format.\nUsage:\n ip-to-decimal <ip_address>\nExamples:\n ip-to-decimal 192.168.1.1\n ip-to-decimal 8.8.8.8"

  if [ $# -eq 0 ]; then
    _show_error_ip_aliases "Error: IP address parameter is required."
    return 1
  fi

  local ip_addr="$1"

  if ! _validate_ip_ip_aliases "$ip_addr"; then
    _show_error_ip_aliases "Error: Invalid IP address format: $ip_addr"
    return 1
  fi

  local decimal=$(_ip_to_decimal_ip_aliases "$ip_addr")
  echo "$ip_addr = $decimal"
}' # Convert IP address to decimal format

alias ip-from-decimal='() {
  _show_usage_ip_aliases "Convert decimal number to IP address format.\nUsage:\n ip-from-decimal <decimal_number>\nExamples:\n ip-from-decimal 3232235777\n ip-from-decimal 134744072"

  if [ $# -eq 0 ]; then
    _show_error_ip_aliases "Error: Decimal number parameter is required."
    return 1
  fi

  local decimal="$1"

  if ! echo "$decimal" | grep -q "^[0-9]\+$"; then
    _show_error_ip_aliases "Error: Input must be a decimal number."
    return 1
  fi

  if [ "$decimal" -gt 4294967295 ] || [ "$decimal" -lt 0 ]; then
    _show_error_ip_aliases "Error: Decimal number must be between 0 and 4294967295."
    return 1
  fi

  local ip_addr=$(_decimal_to_ip_ip_aliases "$decimal")
  echo "$decimal = $ip_addr"
}' # Convert decimal number to IP address format

alias ip-to-binary='() {
  _show_usage_ip_aliases "Convert IP address to binary format.\nUsage:\n ip-to-binary <ip_address>\nExamples:\n ip-to-binary 192.168.1.1\n ip-to-binary 255.255.255.0"

  if [ $# -eq 0 ]; then
    _show_error_ip_aliases "Error: IP address parameter is required."
    return 1
  fi

  local ip_addr="$1"

  if ! _validate_ip_ip_aliases "$ip_addr"; then
    _show_error_ip_aliases "Error: Invalid IP address format: $ip_addr"
    return 1
  fi

  local IFS="."
  local binary_result=""

  for octet in $ip_addr; do
    local binary_octet=""
    local temp_octet="$octet"

    # Convert octet to 8-bit binary
    local bit_position=7
    while [ "$bit_position" -ge 0 ]; do
      local bit_value=$((2 ** bit_position))
      if [ "$temp_octet" -ge "$bit_value" ]; then
        binary_octet="${binary_octet}1"
        temp_octet=$((temp_octet - bit_value))
      else
        binary_octet="${binary_octet}0"
      fi
      bit_position=$((bit_position - 1))
    done

    if [ -z "$binary_result" ]; then
      binary_result="$binary_octet"
    else
      binary_result="$binary_result.$binary_octet"
    fi
  done

  echo "$ip_addr = $binary_result"
}' # Convert IP address to binary format

alias ip-range-list='() {
  _show_usage_ip_aliases "List all IP addresses in a given range.\nUsage:\n ip-range-list <start_ip> <end_ip>\nExamples:\n ip-range-list 192.168.1.1 192.168.1.10\n ip-range-list 10.0.0.1 10.0.0.5"

  if [ $# -ne 2 ]; then
    _show_error_ip_aliases "Error: Both start and end IP address parameters are required."
    return 1
  fi

  local start_ip="$1"
  local end_ip="$2"

  if ! _validate_ip_ip_aliases "$start_ip"; then
    _show_error_ip_aliases "Error: Invalid start IP address format: $start_ip"
    return 1
  fi

  if ! _validate_ip_ip_aliases "$end_ip"; then
    _show_error_ip_aliases "Error: Invalid end IP address format: $end_ip"
    return 1
  fi

  local start_decimal=$(_ip_to_decimal_ip_aliases "$start_ip")
  local end_decimal=$(_ip_to_decimal_ip_aliases "$end_ip")

  if [ "$start_decimal" -gt "$end_decimal" ]; then
    _show_error_ip_aliases "Error: Start IP address must be less than or equal to end IP address."
    return 1
  fi

  local range_size=$((end_decimal - start_decimal + 1))
  if [ "$range_size" -gt 1000 ]; then
    echo "Warning: Large IP range detected ($range_size addresses). Continue? (y/N)"
    read -r response
    if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
      echo "Operation cancelled."
      return 0
    fi
  fi

  echo "IP addresses from $start_ip to $end_ip:"
  local current_decimal="$start_decimal"

  while [ "$current_decimal" -le "$end_decimal" ]; do
    local current_ip=$(_decimal_to_ip_ip_aliases "$current_decimal")
    echo "$current_ip"
    current_decimal=$((current_decimal + 1))
  done
}' # List all IP addresses in a given range

alias ip-random='() {
  _show_usage_ip_aliases "Generate random IP addresses.\nUsage:\n ip-random [count:1] [class:any]\nClasses: a, b, c, private, public, any\nExamples:\n ip-random\n ip-random 5\n ip-random 3 private\n ip-random 10 public"

  local count="${1:-1}"
  local ip_class="${2:-any}"

  if ! echo "$count" | grep -q "^[0-9]\+$" || [ "$count" -lt 1 ] || [ "$count" -gt 100 ]; then
    _show_error_ip_aliases "Error: Count must be a number between 1 and 100."
    return 1
  fi

  local i=0
  while [ "$i" -lt "$count" ]; do
    local octet1 octet2 octet3 octet4

    case "$ip_class" in
      "a")
        octet1=$((RANDOM % 126 + 1))  # 1-126 (Class A)
        octet2=$((RANDOM % 256))
        octet3=$((RANDOM % 256))
        octet4=$((RANDOM % 254 + 1))  # 1-254 (avoid .0 and .255)
        ;;
      "b")
        octet1=$((RANDOM % 64 + 128))  # 128-191 (Class B)
        octet2=$((RANDOM % 256))
        octet3=$((RANDOM % 256))
        octet4=$((RANDOM % 254 + 1))
        ;;
      "c")
        octet1=$((RANDOM % 32 + 192))  # 192-223 (Class C)
        octet2=$((RANDOM % 256))
        octet3=$((RANDOM % 256))
        octet4=$((RANDOM % 254 + 1))
        ;;
      "private")
        local private_range=$((RANDOM % 3))
        case "$private_range" in
          0)  # 10.0.0.0/8
            octet1=10
            octet2=$((RANDOM % 256))
            octet3=$((RANDOM % 256))
            octet4=$((RANDOM % 254 + 1))
            ;;
          1)  # 172.16.0.0/12
            octet1=172
            octet2=$((RANDOM % 16 + 16))  # 16-31
            octet3=$((RANDOM % 256))
            octet4=$((RANDOM % 254 + 1))
            ;;
          2)  # 192.168.0.0/16
            octet1=192
            octet2=168
            octet3=$((RANDOM % 256))
            octet4=$((RANDOM % 254 + 1))
            ;;
        esac
        ;;
      "public"|"any")
        # Generate any IP, but avoid private ranges for "public"
        local attempts=0
        while [ "$attempts" -lt 10 ]; do
          octet1=$((RANDOM % 223 + 1))  # 1-223
          octet2=$((RANDOM % 256))
          octet3=$((RANDOM % 256))
          octet4=$((RANDOM % 254 + 1))

          # Skip private ranges if "public" is specified
          if [ "$ip_class" = "public" ]; then
            if [ "$octet1" -eq 10 ] || \
               ([ "$octet1" -eq 172 ] && [ "$octet2" -ge 16 ] && [ "$octet2" -le 31 ]) || \
               ([ "$octet1" -eq 192 ] && [ "$octet2" -eq 168 ]); then
              attempts=$((attempts + 1))
              continue
            fi
          fi
          break
        done
        ;;
      *)
        _show_error_ip_aliases "Error: Invalid IP class \"$ip_class\". Available classes: a, b, c, private, public, any"
        return 1
        ;;
    esac

    echo "$octet1.$octet2.$octet3.$octet4"
    i=$((i + 1))
  done
}' # Generate random IP addresses

# IP Validation and Testing Functions
### --- ###

alias ip-validate='() {
  _show_usage_ip_aliases "Validate IP address format.\nUsage:\n ip-validate <ip_address>\nExamples:\n ip-validate 192.168.1.1\n ip-validate 256.1.1.1"

  if [ $# -eq 0 ]; then
    _show_error_ip_aliases "Error: IP address parameter is required."
    return 1
  fi

  local ip_addr="$1"

  if _validate_ip_ip_aliases "$ip_addr"; then
    echo "VALID: $ip_addr is a valid IP address"
    return 0
  else
    echo "INVALID: $ip_addr is not a valid IP address"
    return 1
  fi
}' # Validate IP address format

alias ip-ping='() {
  _show_usage_ip_aliases "Ping an IP address with customizable options.\nUsage:\n ip-ping <ip_address> [count:4] [interval:1]\nExamples:\n ip-ping 8.8.8.8\n ip-ping 192.168.1.1 10\n ip-ping 1.1.1.1 5 2"

  if [ $# -eq 0 ]; then
    _show_error_ip_aliases "Error: IP address parameter is required."
    return 1
  fi

  local target_ip="$1"
  local ping_count="${2:-4}"
  local ping_interval="${3:-1}"

  if ! _validate_ip_ip_aliases "$target_ip"; then
    _show_error_ip_aliases "Error: Invalid IP address format: $target_ip"
    return 1
  fi

  if ! echo "$ping_count" | grep -q "^[0-9]\+$" || [ "$ping_count" -lt 1 ] || [ "$ping_count" -gt 100 ]; then
    _show_error_ip_aliases "Error: Ping count must be a number between 1 and 100."
    return 1
  fi

  if ! echo "$ping_interval" | grep -q "^[0-9]\+$" || [ "$ping_interval" -lt 1 ] || [ "$ping_interval" -gt 60 ]; then
    _show_error_ip_aliases "Error: Ping interval must be a number between 1 and 60 seconds."
    return 1
  fi

  if ! _check_command_ip_aliases ping; then
    return 1
  fi

  echo "Pinging $target_ip with $ping_count packets (interval: ${ping_interval}s)..."

  # Different ping syntax for macOS and Linux
  if [ "$(uname)" = "Darwin" ]; then
    ping -c "$ping_count" -i "$ping_interval" "$target_ip"
  else
    ping -c "$ping_count" -i "$ping_interval" "$target_ip"
  fi

  if [ $? -ne 0 ]; then
    _show_error_ip_aliases "Ping to $target_ip failed. Check the IP address and network connectivity."
    return 1
  fi
}' # Ping an IP address with customizable options

# IP Help Function
### --- ###

alias ip-help='() {
  echo "IP Aliases Help - Available Commands:"
  echo ""
  echo "IP Information and Query:"
  echo "  ip-myip [service]           - Get your public IP address"
  echo "  ip-info [ip]                - Get detailed IP information"
  echo "  ip-geolocate [ip]           - Get geolocation for IP address"
  echo "  ip-whois <ip>               - Get WHOIS information"
  echo ""
  echo "CIDR and Subnet Calculations:"
  echo "  ip-cidr-info <cidr>         - Get CIDR block information"
  echo "  ip-subnet-calc <ip> <mask>  - Calculate subnet from IP and mask"
  echo "  ip-cidr-contains <cidr> <ip> - Check if IP is in CIDR block"
  echo "  ip-cidr-split <cidr> <bits> - Split CIDR into smaller subnets"
  echo ""
  echo "IP Conversion and Utilities:"
  echo "  ip-to-decimal <ip>          - Convert IP to decimal"
  echo "  ip-from-decimal <decimal>   - Convert decimal to IP"
  echo "  ip-to-binary <ip>           - Convert IP to binary"
  echo "  ip-range-list <start> <end> - List IPs in range"
  echo "  ip-random [count] [class]   - Generate random IPs"
  echo ""
  echo "IP Validation and Testing:"
  echo "  ip-validate <ip>            - Validate IP address format"
  echo "  ip-ping <ip> [count] [int]  - Ping IP with options"
  echo ""
  echo "Examples:"
  echo "  ip-myip                     - Get your public IP"
  echo "  ip-cidr-info 192.168.1.0/24 - Analyze subnet"
  echo "  ip-random 5 private         - Generate 5 private IPs"
  echo "  ip-ping 8.8.8.8 10 2       - Ping Google DNS 10 times, 2s interval"
}' # Display help information for all IP aliases
