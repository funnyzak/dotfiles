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

_maybe_show_usage_ip_aliases() {
  local first_argument="$1"
  local usage_text="$2"

  case "$first_argument" in
    "-h"|"--help"|"help")
      _show_usage_ip_aliases "$usage_text"
      return 0
      ;;
  esac

  return 1
}

_is_integer_ip_aliases() {
  echo "$1" | grep -qE "^[0-9]+$"
}

_trim_response_ip_aliases() {
  printf "%s" "$1" | tr -d "\r\n"
}

_validate_ip_ip_aliases() {
  local ip_addr="$1"
  local octet1=""
  local octet2=""
  local octet3=""
  local octet4=""

  if ! echo "$ip_addr" | grep -qE "^([0-9]{1,3}\.){3}[0-9]{1,3}$"; then
    return 1
  fi

  IFS="." read -r octet1 octet2 octet3 octet4 <<< "$ip_addr"

  for octet in "$octet1" "$octet2" "$octet3" "$octet4"; do
    if [ "$octet" -gt 255 ] || [ "$octet" -lt 0 ]; then
      return 1
    fi
  done

  return 0
}

_validate_cidr_ip_aliases() {
  local cidr="$1"
  local ip_part=""
  local prefix_part=""

  if ! echo "$cidr" | grep -qE "^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$"; then
    return 1
  fi

  ip_part=$(echo "$cidr" | cut -d"/" -f1)
  prefix_part=$(echo "$cidr" | cut -d"/" -f2)

  if ! _validate_ip_ip_aliases "$ip_part"; then
    return 1
  fi

  if ! _is_integer_ip_aliases "$prefix_part" || [ "$prefix_part" -gt 32 ] || [ "$prefix_part" -lt 0 ]; then
    return 1
  fi

  return 0
}

_ip_to_decimal_ip_aliases() {
  local ip="$1"
  local octet1=""
  local octet2=""
  local octet3=""
  local octet4=""

  IFS="." read -r octet1 octet2 octet3 octet4 <<< "$ip"

  echo $((octet1 * 16777216 + octet2 * 65536 + octet3 * 256 + octet4))
}

_decimal_to_ip_ip_aliases() {
  local decimal="$1"
  local octet1=$((decimal / 16777216))
  local octet2=$(((decimal % 16777216) / 65536))
  local octet3=$(((decimal % 65536) / 256))
  local octet4=$((decimal % 256))

  echo "$octet1.$octet2.$octet3.$octet4"
}

_prefix_to_mask_decimal_ip_aliases() {
  local prefix_length="$1"

  if [ "$prefix_length" -eq 0 ]; then
    echo "0"
    return 0
  fi

  echo $((((0xFFFFFFFF << (32 - prefix_length)) & 0xFFFFFFFF)))
}

_mask_to_prefix_ip_aliases() {
  local subnet_mask="$1"
  local mask_decimal=$(_ip_to_decimal_ip_aliases "$subnet_mask")
  local wildcard_decimal=$(((0xFFFFFFFF ^ mask_decimal) & 0xFFFFFFFF))
  local prefix_length=0
  local temp_mask="$mask_decimal"

  if [ $((wildcard_decimal & (wildcard_decimal + 1))) -ne 0 ]; then
    return 1
  fi

  while [ "$temp_mask" -ne 0 ]; do
    prefix_length=$((prefix_length + (temp_mask & 1)))
    temp_mask=$((temp_mask >> 1))
  done

  echo "$prefix_length"
}

_usable_hosts_for_prefix_ip_aliases() {
  local prefix_length="$1"
  local total_hosts=$((2 ** (32 - prefix_length)))

  case "$prefix_length" in
    32)
      echo "1"
      ;;
    31)
      echo "2"
      ;;
    *)
      echo $((total_hosts - 2))
      ;;
  esac
}

_calculate_host_details_ip_aliases() {
  local network_decimal="$1"
  local broadcast_decimal="$2"
  local prefix_length="$3"
  local first_usable_decimal="$network_decimal"
  local last_usable_decimal="$broadcast_decimal"
  local usable_hosts=$(_usable_hosts_for_prefix_ip_aliases "$prefix_length")

  case "$prefix_length" in
    32)
      ;;
    31)
      ;;
    *)
      first_usable_decimal=$((network_decimal + 1))
      last_usable_decimal=$((broadcast_decimal - 1))
      ;;
  esac

  echo "$first_usable_decimal|$last_usable_decimal|$usable_hosts"
}

_http_get_ip_aliases() {
  local request_url="$1"

  if ! _check_command_ip_aliases curl; then
    return 1
  fi

  curl -fsSL --connect-timeout 8 --max-time 12 "$request_url" 2>/dev/null
}

_build_ipinfo_url_ip_aliases() {
  local target_ip="$1"

  if [ -n "$target_ip" ]; then
    echo "https://ipinfo.io/$target_ip/json"
  else
    echo "https://ipinfo.io/json"
  fi
}

_fetch_ipinfo_json_ip_aliases() {
  local target_ip="$1"
  local request_url=$(_build_ipinfo_url_ip_aliases "$target_ip")

  _http_get_ip_aliases "$request_url"
}

_pretty_print_json_ip_aliases() {
  local json_payload="$1"

  if command -v jq &> /dev/null; then
    printf "%s\n" "$json_payload" | jq .
    return 0
  fi

  if command -v python3 &> /dev/null; then
    printf "%s\n" "$json_payload" | python3 -m json.tool 2>/dev/null
    return 0
  fi

  printf "%s\n" "$json_payload"
}

_extract_json_string_field_ip_aliases() {
  local json_payload="$1"
  local field_name="$2"

  if command -v jq &> /dev/null; then
    printf "%s\n" "$json_payload" | jq -r --arg field_name "$field_name" ".[\$field_name] // empty"
    return 0
  fi

  if command -v python3 &> /dev/null; then
    printf "%s\n" "$json_payload" | python3 -c "import json, sys; data = json.load(sys.stdin); value = data.get(sys.argv[1], \"\"); print(value if value is not None else \"\")" "$field_name" 2>/dev/null
    return 0
  fi

  printf "%s" "$json_payload" | tr -d "\n" | sed -n "s/.*\"$field_name\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" | head -n 1
}

_print_named_value_ip_aliases() {
  local field_label="$1"
  local field_value="${2:-N/A}"

  printf "%-14s %s\n" "$field_label:" "$field_value"
}

_public_ip_service_url_ip_aliases() {
  local service_name="$1"

  case "$service_name" in
    "ipinfo")
      echo "https://ipinfo.io/ip"
      ;;
    "ipify")
      echo "https://api64.ipify.org"
      ;;
    "ifconfig")
      echo "https://ifconfig.me/ip"
      ;;
    "aws")
      echo "https://checkip.amazonaws.com"
      ;;
    "icanhazip")
      echo "https://icanhazip.com"
      ;;
    *)
      return 1
      ;;
  esac
}

_get_public_ip_ip_aliases() {
  local requested_service="${1:-auto}"
  local candidate_services=""

  case "$requested_service" in
    ""|"auto")
      candidate_services="ipinfo
ipify
ifconfig
aws
icanhazip"
      ;;
    "ipinfo"|"ipify"|"ifconfig"|"aws"|"icanhazip")
      candidate_services="$requested_service"
      ;;
    *)
      _show_error_ip_aliases "Error: Unknown service \"$requested_service\". Available services: auto, ipinfo, ipify, ifconfig, aws, icanhazip"
      return 1
      ;;
  esac

  local candidate_service=""
  while IFS= read -r candidate_service; do
    local request_url=""
    local result=""
    local trimmed_result=""

    if [ -z "$candidate_service" ]; then
      continue
    fi

    request_url=$(_public_ip_service_url_ip_aliases "$candidate_service") || continue
    result=$(_http_get_ip_aliases "$request_url") || continue
    trimmed_result=$(_trim_response_ip_aliases "$result")

    if _validate_ip_ip_aliases "$trimmed_result"; then
      printf "%s\n" "$trimmed_result"
      return 0
    fi
  done <<EOF
$candidate_services
EOF

  return 1
}

_is_special_use_ipv4_ip_aliases() {
  local ip_addr="$1"
  local octet1=""
  local octet2=""
  local octet3=""
  local octet4=""

  IFS="." read -r octet1 octet2 octet3 octet4 <<< "$ip_addr"

  if [ "$octet1" -eq 10 ] || \
     ([ "$octet1" -eq 100 ] && [ "$octet2" -ge 64 ] && [ "$octet2" -le 127 ]) || \
     [ "$octet1" -eq 127 ] || \
     ([ "$octet1" -eq 169 ] && [ "$octet2" -eq 254 ]) || \
     ([ "$octet1" -eq 172 ] && [ "$octet2" -ge 16 ] && [ "$octet2" -le 31 ]) || \
     ([ "$octet1" -eq 192 ] && [ "$octet2" -eq 0 ] && [ "$octet3" -eq 2 ]) || \
     ([ "$octet1" -eq 192 ] && [ "$octet2" -eq 168 ]) || \
     ([ "$octet1" -eq 198 ] && [ "$octet2" -eq 18 ]) || \
     ([ "$octet1" -eq 198 ] && [ "$octet2" -eq 19 ]) || \
     ([ "$octet1" -eq 198 ] && [ "$octet2" -eq 51 ] && [ "$octet3" -eq 100 ]) || \
     ([ "$octet1" -eq 203 ] && [ "$octet2" -eq 0 ] && [ "$octet3" -eq 113 ]); then
    return 0
  fi

  return 1
}

# IP Information and Query Functions
### --- ###

alias ip-myip='() {
  if _maybe_show_usage_ip_aliases "$1" "Get your public IP address.\nUsage:\n ip-myip [service:auto]\n ip-myip --service <auto|ipinfo|ipify|ifconfig|aws|icanhazip>\nServices: auto, ipinfo, ipify, ifconfig, aws, icanhazip\nExamples:\n ip-myip\n ip-myip ipify\n ip-myip --service ifconfig"; then
    return 0
  fi

  local service="auto"

  while [ $# -gt 0 ]; do
    case "$1" in
      "-s"|"--service")
        if [ -z "$2" ]; then
          _show_error_ip_aliases "Error: Missing service name after $1."
          return 1
        fi
        service="$2"
        shift 2
        ;;
      *)
        if [ "$service" != "auto" ]; then
          _show_error_ip_aliases "Error: Too many parameters."
          return 1
        fi
        service="$1"
        shift
        ;;
    esac
  done

  local result=""
  if ! result=$(_get_public_ip_ip_aliases "$service"); then
    _show_error_ip_aliases "Failed to retrieve public IP address. Tried service selection: $service"
    return 1
  fi

  printf "%s\n" "$result"
}' # Get your public IP address from various services

alias ip-info='() {
  if _maybe_show_usage_ip_aliases "$1" "Get detailed IP information.\nUsage:\n ip-info [ip_address:current] [--json]\nExamples:\n ip-info\n ip-info 8.8.8.8\n ip-info --json 1.1.1.1"; then
    return 0
  fi

  local target_ip=""
  local output_mode="pretty"

  while [ $# -gt 0 ]; do
    case "$1" in
      "-j"|"--json")
        output_mode="json"
        shift
        ;;
      *)
        if [ -n "$target_ip" ]; then
          _show_error_ip_aliases "Error: Too many parameters."
          return 1
        fi
        target_ip="$1"
        shift
        ;;
    esac
  done

  if [ -n "$target_ip" ] && ! _validate_ip_ip_aliases "$target_ip"; then
    _show_error_ip_aliases "Error: Invalid IP address format: $target_ip"
    return 1
  fi

  local result=""
  if ! result=$(_fetch_ipinfo_json_ip_aliases "$target_ip"); then
    _show_error_ip_aliases "Failed to retrieve IP information. Check your internet connection or service availability."
    return 1
  fi

  if [ "$output_mode" = "json" ]; then
    printf "%s\n" "$result"
  else
    _pretty_print_json_ip_aliases "$result"
  fi
}' # Get detailed IP information including location, ISP, and organization

alias ip-geolocate='() {
  if _maybe_show_usage_ip_aliases "$1" "Get geolocation information for an IP address.\nUsage:\n ip-geolocate [ip_address:current]\nExamples:\n ip-geolocate\n ip-geolocate 8.8.8.8"; then
    return 0
  fi

  local target_ip="$1"

  if [ -n "$target_ip" ] && ! _validate_ip_ip_aliases "$target_ip"; then
    _show_error_ip_aliases "Error: Invalid IP address format: $target_ip"
    return 1
  fi

  local result=""
  if ! result=$(_fetch_ipinfo_json_ip_aliases "$target_ip"); then
    _show_error_ip_aliases "Failed to retrieve geolocation information. Check your internet connection or service availability."
    return 1
  fi

  _print_named_value_ip_aliases "IP Address" "$(_extract_json_string_field_ip_aliases "$result" "ip")"
  _print_named_value_ip_aliases "City" "$(_extract_json_string_field_ip_aliases "$result" "city")"
  _print_named_value_ip_aliases "Region" "$(_extract_json_string_field_ip_aliases "$result" "region")"
  _print_named_value_ip_aliases "Country" "$(_extract_json_string_field_ip_aliases "$result" "country")"
  _print_named_value_ip_aliases "Location" "$(_extract_json_string_field_ip_aliases "$result" "loc")"
  _print_named_value_ip_aliases "Organization" "$(_extract_json_string_field_ip_aliases "$result" "org")"
  _print_named_value_ip_aliases "Timezone" "$(_extract_json_string_field_ip_aliases "$result" "timezone")"
  _print_named_value_ip_aliases "Postal" "$(_extract_json_string_field_ip_aliases "$result" "postal")"
}' # Get geolocation information for IP addresses

alias ip-whois='() {
  if _maybe_show_usage_ip_aliases "$1" "Get WHOIS information for an IP address.\nUsage:\n ip-whois <ip_address>\nExample:\n ip-whois 8.8.8.8"; then
    return 0
  fi

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
  if _maybe_show_usage_ip_aliases "$1" "Get detailed information about a CIDR block.\nUsage:\n ip-cidr-info <cidr_notation>\nExamples:\n ip-cidr-info 192.168.1.0/24\n ip-cidr-info 10.0.0.0/8"; then
    return 0
  fi

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
  local mask_decimal=$(_prefix_to_mask_decimal_ip_aliases "$prefix_length")
  local subnet_mask=$(_decimal_to_ip_ip_aliases "$mask_decimal")

  local network_decimal=$(_ip_to_decimal_ip_aliases "$network_ip")
  local network_addr_decimal=$((network_decimal & mask_decimal))
  local network_addr=$(_decimal_to_ip_ip_aliases "$network_addr_decimal")
  local wildcard_decimal=$(((0xFFFFFFFF ^ mask_decimal) & 0xFFFFFFFF))
  local wildcard_mask=$(_decimal_to_ip_ip_aliases "$wildcard_decimal")
  local broadcast_decimal=$((network_addr_decimal | wildcard_decimal))
  local broadcast_addr=$(_decimal_to_ip_ip_aliases "$broadcast_decimal")
  local total_hosts=$((broadcast_decimal - network_addr_decimal + 1))
  local host_details=$(_calculate_host_details_ip_aliases "$network_addr_decimal" "$broadcast_decimal" "$prefix_length")
  local first_usable_decimal=""
  local last_usable_decimal=""
  local usable_hosts=""
  IFS="|" read -r first_usable_decimal last_usable_decimal usable_hosts <<< "$host_details"

  local first_usable=$(_decimal_to_ip_ip_aliases "$first_usable_decimal")
  local last_usable=$(_decimal_to_ip_ip_aliases "$last_usable_decimal")

  echo "CIDR Block: $cidr"
  echo "Network Address: $network_addr"
  echo "Subnet Mask: $subnet_mask"
  echo "Wildcard Mask: $wildcard_mask"
  echo "Broadcast Address: $broadcast_addr"
  echo "First Usable IP: $first_usable"
  echo "Last Usable IP: $last_usable"
  echo "Total Hosts: $total_hosts"
  echo "Usable Hosts: $usable_hosts"
  echo "Prefix Length: /$prefix_length"
}' # Get detailed information about a CIDR block

alias ip-subnet-calc='() {
  if _maybe_show_usage_ip_aliases "$1" "Calculate subnet information from IP and subnet mask.\nUsage:\n ip-subnet-calc <ip_address> <subnet_mask>\nExamples:\n ip-subnet-calc 192.168.1.100 255.255.255.0\n ip-subnet-calc 10.0.0.50 255.0.0.0"; then
    return 0
  fi

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

  local ip_decimal=$(_ip_to_decimal_ip_aliases "$ip_addr")
  local mask_decimal=$(_ip_to_decimal_ip_aliases "$subnet_mask")
  local prefix_length=""

  if ! prefix_length=$(_mask_to_prefix_ip_aliases "$subnet_mask"); then
    _show_error_ip_aliases "Error: Invalid subnet mask. The mask must contain contiguous 1 bits followed by contiguous 0 bits."
    return 1
  fi

  local network_decimal=$((ip_decimal & mask_decimal))
  local network_addr=$(_decimal_to_ip_ip_aliases "$network_decimal")
  local wildcard_decimal=$(((0xFFFFFFFF ^ mask_decimal) & 0xFFFFFFFF))
  local wildcard_mask=$(_decimal_to_ip_ip_aliases "$wildcard_decimal")
  local broadcast_decimal=$((network_decimal | wildcard_decimal))
  local broadcast_addr=$(_decimal_to_ip_ip_aliases "$broadcast_decimal")
  local total_hosts=$((broadcast_decimal - network_decimal + 1))
  local host_details=$(_calculate_host_details_ip_aliases "$network_decimal" "$broadcast_decimal" "$prefix_length")
  local first_usable_decimal=""
  local last_usable_decimal=""
  local usable_hosts=""
  IFS="|" read -r first_usable_decimal last_usable_decimal usable_hosts <<< "$host_details"

  local first_usable=$(_decimal_to_ip_ip_aliases "$first_usable_decimal")
  local last_usable=$(_decimal_to_ip_ip_aliases "$last_usable_decimal")

  echo "Input IP: $ip_addr"
  echo "Subnet Mask: $subnet_mask"
  echo "Wildcard Mask: $wildcard_mask"
  echo "CIDR Notation: $network_addr/$prefix_length"
  echo "Network Address: $network_addr"
  echo "Broadcast Address: $broadcast_addr"
  echo "First Usable IP: $first_usable"
  echo "Last Usable IP: $last_usable"
  echo "Total Hosts: $total_hosts"
  echo "Usable Hosts: $usable_hosts"
}' # Calculate subnet information from IP and subnet mask

alias ip-cidr-contains='() {
  if _maybe_show_usage_ip_aliases "$1" "Check if an IP address is within a CIDR block.\nUsage:\n ip-cidr-contains <cidr_block> <ip_address>\nExamples:\n ip-cidr-contains 192.168.1.0/24 192.168.1.100\n ip-cidr-contains 10.0.0.0/8 10.5.5.5"; then
    return 0
  fi

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
  local mask_decimal=$(_prefix_to_mask_decimal_ip_aliases "$prefix_length")
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
  if _maybe_show_usage_ip_aliases "$1" "Split a CIDR block into smaller subnets.\nUsage:\n ip-cidr-split <cidr_block> <new_prefix_length>\nExamples:\n ip-cidr-split 192.168.1.0/24 26\n ip-cidr-split 10.0.0.0/16 24"; then
    return 0
  fi

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

  if ! _is_integer_ip_aliases "$new_prefix" || [ "$new_prefix" -lt 1 ] || [ "$new_prefix" -gt 32 ]; then
    _show_error_ip_aliases "Error: New prefix length must be between 1 and 32."
    return 1
  fi

  local network_ip=$(echo "$cidr" | cut -d"/" -f1)
  local old_prefix=$(echo "$cidr" | cut -d"/" -f2)

  if [ "$new_prefix" -le "$old_prefix" ]; then
    _show_error_ip_aliases "Error: New prefix length must be greater than current prefix length ($old_prefix)."
    return 1
  fi

  local subnet_bits=$((new_prefix - old_prefix))
  local num_subnets=$((2 ** subnet_bits))
  local subnet_size=$((2 ** (32 - new_prefix)))
  local old_mask_decimal=$(_prefix_to_mask_decimal_ip_aliases "$old_prefix")
  local network_decimal=$(_ip_to_decimal_ip_aliases "$network_ip")
  local base_network_decimal=$((network_decimal & old_mask_decimal))
  local hosts_per_subnet=$(_usable_hosts_for_prefix_ip_aliases "$new_prefix")

  echo "Splitting $cidr into /$new_prefix subnets:"
  echo "Number of subnets: $num_subnets"
  echo "Hosts per subnet: $hosts_per_subnet"
  echo ""

  local current_network="$base_network_decimal"

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
  if _maybe_show_usage_ip_aliases "$1" "Convert IP address to decimal format.\nUsage:\n ip-to-decimal <ip_address>\nExamples:\n ip-to-decimal 192.168.1.1\n ip-to-decimal 8.8.8.8"; then
    return 0
  fi

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
  if _maybe_show_usage_ip_aliases "$1" "Convert decimal number to IP address format.\nUsage:\n ip-from-decimal <decimal_number>\nExamples:\n ip-from-decimal 3232235777\n ip-from-decimal 134744072"; then
    return 0
  fi

  if [ $# -eq 0 ]; then
    _show_error_ip_aliases "Error: Decimal number parameter is required."
    return 1
  fi

  local decimal="$1"

  if ! _is_integer_ip_aliases "$decimal"; then
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
  if _maybe_show_usage_ip_aliases "$1" "Convert IP address to binary format.\nUsage:\n ip-to-binary <ip_address>\nExamples:\n ip-to-binary 192.168.1.1\n ip-to-binary 255.255.255.0"; then
    return 0
  fi

  if [ $# -eq 0 ]; then
    _show_error_ip_aliases "Error: IP address parameter is required."
    return 1
  fi

  local ip_addr="$1"

  if ! _validate_ip_ip_aliases "$ip_addr"; then
    _show_error_ip_aliases "Error: Invalid IP address format: $ip_addr"
    return 1
  fi

  local octet1=""
  local octet2=""
  local octet3=""
  local octet4=""
  local binary_result=""
  IFS="." read -r octet1 octet2 octet3 octet4 <<< "$ip_addr"

  for octet in "$octet1" "$octet2" "$octet3" "$octet4"; do
    local binary_octet=""
    local temp_octet="$octet"

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
  if _maybe_show_usage_ip_aliases "$1" "List all IP addresses in a given range.\nUsage:\n ip-range-list <start_ip> <end_ip>\nExamples:\n ip-range-list 192.168.1.1 192.168.1.10\n ip-range-list 10.0.0.1 10.0.0.5"; then
    return 0
  fi

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
  if _maybe_show_usage_ip_aliases "$1" "Generate random IP addresses.\nUsage:\n ip-random [count:1] [class:any]\nClasses: a, b, c, private, public, any\nExamples:\n ip-random\n ip-random 5\n ip-random 3 private\n ip-random 10 public"; then
    return 0
  fi

  local count="${1:-1}"
  local ip_class="${2:-any}"

  if ! _is_integer_ip_aliases "$count" || [ "$count" -lt 1 ] || [ "$count" -gt 100 ]; then
    _show_error_ip_aliases "Error: Count must be a number between 1 and 100."
    return 1
  fi

  local i=0
  while [ "$i" -lt "$count" ]; do
    local octet1=""
    local octet2=""
    local octet3=""
    local octet4=""

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
        local attempts=0
        local candidate_ip=""
        local found_candidate="false"
        while [ "$attempts" -lt 100 ]; do
          octet1=$((RANDOM % 223 + 1))  # 1-223
          octet2=$((RANDOM % 256))
          octet3=$((RANDOM % 256))
          octet4=$((RANDOM % 254 + 1))
          candidate_ip="$octet1.$octet2.$octet3.$octet4"

          if [ "$ip_class" = "public" ] && _is_special_use_ipv4_ip_aliases "$candidate_ip"; then
            attempts=$((attempts + 1))
            continue
          fi

          found_candidate="true"
          break
        done

        if [ "$ip_class" = "public" ] && [ "$found_candidate" != "true" ]; then
          _show_error_ip_aliases "Error: Failed to generate a valid public IPv4 address after multiple attempts."
          return 1
        fi
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
  if _maybe_show_usage_ip_aliases "$1" "Validate IP address format.\nUsage:\n ip-validate <ip_address>\nExamples:\n ip-validate 192.168.1.1\n ip-validate 256.1.1.1"; then
    return 0
  fi

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
  if _maybe_show_usage_ip_aliases "$1" "Ping an IP address with customizable options.\nUsage:\n ip-ping <ip_address> [count:4] [interval:1]\nExamples:\n ip-ping 8.8.8.8\n ip-ping 192.168.1.1 10\n ip-ping 1.1.1.1 5 2"; then
    return 0
  fi

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

  if ! _is_integer_ip_aliases "$ping_count" || [ "$ping_count" -lt 1 ] || [ "$ping_count" -gt 100 ]; then
    _show_error_ip_aliases "Error: Ping count must be a number between 1 and 100."
    return 1
  fi

  if ! _is_integer_ip_aliases "$ping_interval" || [ "$ping_interval" -lt 1 ] || [ "$ping_interval" -gt 60 ]; then
    _show_error_ip_aliases "Error: Ping interval must be a number between 1 and 60 seconds."
    return 1
  fi

  if ! _check_command_ip_aliases ping; then
    return 1
  fi

  echo "Pinging $target_ip with $ping_count packets (interval: ${ping_interval}s)..."

  ping -c "$ping_count" -i "$ping_interval" "$target_ip"

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
  echo "  ip-myip [service]           - Get your public IP address with fallback services"
  echo "  ip-info [ip] [--json]       - Get detailed IP information"
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
  echo "Supported public IP services: auto, ipinfo, ipify, ifconfig, aws, icanhazip"
  echo ""
  echo "Examples:"
  echo "  ip-myip                     - Get your public IP"
  echo "  ip-myip --service ifconfig  - Force a specific public IP provider"
  echo "  ip-cidr-info 192.168.1.0/24 - Analyze subnet"
  echo "  ip-random 5 private         - Generate 5 private IPs"
  echo "  ip-ping 8.8.8.8 10 2        - Ping Google DNS 10 times, 2s interval"
}' # Display help information for all IP aliases
