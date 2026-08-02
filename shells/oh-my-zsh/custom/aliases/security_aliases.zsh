# Description: Defensive server security aliases for authorized external reconnaissance, DNS, TCP, TLS, and HTTP checks.

# Shared helpers
# --------------

_show_error_security_aliases() {
  local error_message="$1"
  echo "$error_message" >&2
  return 1
}

_show_warning_security_aliases() {
  local warning_message="$1"
  echo "Warning: $warning_message" >&2
  return 0
}

_show_usage_security_aliases() {
  local usage_message="$1"
  echo -e "$usage_message"
  return 0
}

_print_section_security_aliases() {
  local section_title="$1"
  echo ""
  echo "===== $section_title ====="
}

_require_command_security_aliases() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    _show_error_security_aliases "Error: Required command \"$command_name\" was not found. Install it and retry."
    return 1
  fi

  return 0
}

_is_integer_security_aliases() {
  local integer_value="$1"
  echo "$integer_value" | grep -qE "^[0-9]+$"
}

_is_ipv4_security_aliases() {
  local target_value="$1"
  local octet_one=""
  local octet_two=""
  local octet_three=""
  local octet_four=""
  local octet_value=""

  if ! echo "$target_value" | grep -qE "^([0-9]{1,3}\.){3}[0-9]{1,3}$"; then
    return 1
  fi

  IFS="." read -r octet_one octet_two octet_three octet_four <<< "$target_value"
  for octet_value in "$octet_one" "$octet_two" "$octet_three" "$octet_four"; do
    if [ "$octet_value" -lt 0 ] || [ "$octet_value" -gt 255 ]; then
      return 1
    fi
  done

  return 0
}

_is_hostname_security_aliases() {
  local target_value="$1"

  if [ -z "$target_value" ] || [ "${#target_value}" -gt 253 ]; then
    return 1
  fi

  if ! echo "$target_value" | grep -qE "^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$"; then
    return 1
  fi

  if echo "$target_value" | grep -qE "^[0-9.]+$"; then
    return 1
  fi

  case "$target_value" in
    *".."*) return 1 ;;
  esac

  if ! printf "%s\n" "$target_value" | awk -F "." "{for (i=1; i<=NF; i++) {if (length(\$i) > 63 || \$i !~ /^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?\$/) exit 1}}"; then
    return 1
  fi

  return 0
}

_validate_target_security_aliases() {
  local target_value="$1"

  if _is_ipv4_security_aliases "$target_value" || _is_hostname_security_aliases "$target_value"; then
    return 0
  fi

  _show_error_security_aliases "Error: Invalid target \"$target_value\". Use an IPv4 address or hostname without a URL scheme or port."
  return 1
}

_validate_port_security_aliases() {
  local port_value="$1"

  if ! _is_integer_security_aliases "$port_value" || [ "$port_value" -lt 1 ] || [ "$port_value" -gt 65535 ]; then
    _show_error_security_aliases "Error: Port must be an integer between 1 and 65535."
    return 1
  fi

  return 0
}

_require_authorization_security_aliases() {
  local authorization_value="$1"

  if [ "$authorization_value" = "yes" ] || [ "${DOTFILES_SECURITY_SCAN_ACK:-0}" = "1" ]; then
    return 0
  fi

  _show_error_security_aliases "Error: Active scanning requires authorization. Add --authorized, or set DOTFILES_SECURITY_SCAN_ACK=1 for targets you are permitted to test."
  return 1
}

_report_header_security_aliases() {
  local header_payload="$1"
  local header_name="$2"

  if printf "%s\n" "$header_payload" | grep -qi "^${header_name}:"; then
    echo "Present: $header_name"
  else
    echo "Missing: $header_name"
  fi
}

# Internal check runners
# ----------------------

_run_reverse_ip_security_aliases() {
  local target_ip="$1"
  local provider_url="${SECURITY_REVERSE_IP_URL:-https://api.hackertarget.com/reverseiplookup/}"
  local domain_payload=""
  local domain_name=""
  local address_payload=""
  local domain_count="0"

  if ! _is_ipv4_security_aliases "$target_ip"; then
    _show_error_security_aliases "Error: Reverse IP lookup requires an IPv4 address."
    return 1
  fi

  if ! _require_command_security_aliases curl; then
    return 1
  fi

  case "$provider_url" in
    https://*) ;;
    *)
      _show_error_security_aliases "Error: SECURITY_REVERSE_IP_URL must use HTTPS."
      return 1
      ;;
  esac

  if ! domain_payload=$(curl -fsS --connect-timeout 8 --max-time 20 "${provider_url}?q=${target_ip}"); then
    _show_error_security_aliases "Error: Passive reverse IP lookup failed for $target_ip. Check network access or the provider rate limit."
    return 1
  fi

  case "$domain_payload" in
    ""|*"API count exceeded"*|*"No DNS A records found"*|*"error check your search parameter"*)
      _show_warning_security_aliases "The reverse IP provider returned no usable domains for $target_ip: $domain_payload"
      return 0
      ;;
  esac

  echo "Passive domains reported for $target_ip:"

  if ! command -v dig >/dev/null 2>&1; then
    printf "%s\n" "$domain_payload"
    _show_warning_security_aliases "dig was not found, so current A records were not verified."
    return 0
  fi

  domain_count=$(printf "%s\n" "$domain_payload" | awk "NF{count++} END{print count+0}")
  if [ "$domain_count" -gt 100 ]; then
    _show_warning_security_aliases "The provider returned $domain_count lines. Only the first 100 valid hostnames will be verified."
  fi

  printf "%s\n" "$domain_payload" | sed -n "1,100p" | while IFS= read -r domain_name; do
    if [ -z "$domain_name" ]; then
      continue
    fi

    if ! _is_hostname_security_aliases "$domain_name"; then
      echo "  invalid   $domain_name"
      continue
    fi

    address_payload=$(dig +short A "$domain_name" 2>/dev/null)
    if printf "%s\n" "$address_payload" | grep -Fxq "$target_ip"; then
      echo "  verified  $domain_name"
    else
      echo "  stale     $domain_name"
    fi
  done

  echo "Note: Passive reverse IP data may be incomplete or stale. Verified means the current A record includes the target IP."
  return 0
}

_run_port_scan_security_aliases() {
  local target_value="$1"
  local scan_mode="$2"
  local scan_value="$3"
  local service_scan="$4"
  local host_timeout="$5"
  local scan_payload=""
  local open_count="0"

  if ! _require_command_security_aliases nmap; then
    return 1
  fi

  echo "Target: $target_value"
  echo "Mode: $scan_mode"
  echo "Service detection: $service_scan"
  echo "Host timeout: $host_timeout"

  case "$scan_mode:$service_scan" in
    "top:yes")
      scan_payload=$(nmap -Pn -sT -T3 --top-ports "$scan_value" --open --reason -sV --version-light --host-timeout "$host_timeout" "$target_value" 2>&1)
      ;;
    "top:no")
      scan_payload=$(nmap -Pn -sT -T3 --top-ports "$scan_value" --open --reason --host-timeout "$host_timeout" "$target_value" 2>&1)
      ;;
    "ports:yes")
      scan_payload=$(nmap -Pn -sT -T3 -p "$scan_value" --open --reason -sV --version-light --host-timeout "$host_timeout" "$target_value" 2>&1)
      ;;
    "ports:no")
      scan_payload=$(nmap -Pn -sT -T3 -p "$scan_value" --open --reason --host-timeout "$host_timeout" "$target_value" 2>&1)
      ;;
    "full:no")
      scan_payload=$(nmap -Pn -sT -T3 -p- --open --reason --host-timeout "$host_timeout" "$target_value" 2>&1)
      ;;
    *)
      _show_error_security_aliases "Error: Unsupported scan configuration: mode=$scan_mode, service=$service_scan."
      return 1
      ;;
  esac

  if [ $? -ne 0 ]; then
    _show_error_security_aliases "Error: Nmap scan failed for $target_value. Check connectivity, target syntax, and local permissions."
    printf "%s\n" "$scan_payload" >&2
    return 1
  fi

  printf "%s\n" "$scan_payload"
  open_count=$(printf "%s\n" "$scan_payload" | awk "/^[0-9]+\\/tcp[[:space:]]+open/{count++} END{print count+0}")
  echo "Detected open TCP entries: $open_count"

  if [ "$scan_mode" = "top" ] && [ "$scan_value" -ge 100 ] && [ "$open_count" -eq "$scan_value" ]; then
    _show_warning_security_aliases "Every scanned top TCP port appeared open. Verify at the application layer; this often indicates Portspoof, a SYN proxy, a tarpit, or transparent interception."
  elif [ "$scan_mode" = "full" ] && [ "$open_count" -ge 1000 ]; then
    _show_warning_security_aliases "An unusually large number of TCP ports appeared open. Check cloud security groups, Portspoof, TProxy, NAT, and connection-tarpit rules."
  fi

  return 0
}

_run_dns_check_security_aliases() {
  local target_value="$1"
  local probe_name="sec-check-$(date +%s).invalid"
  local udp_response=""
  local invalid_response=""
  local tcp_response=""
  local chaos_response=""

  if ! _require_command_security_aliases dig; then
    return 1
  fi

  echo "Testing whether $target_value answers public DNS queries."

  if udp_response=$(dig @"$target_value" example.com A +time=3 +tries=1 +stats 2>&1); then
    echo "UDP 53 responded to a recursive query:"
    printf "%s\n" "$udp_response" | sed -n "1,28p"
    if printf "%s\n" "$udp_response" | grep -qE "flags:.* ra[; ]"; then
      _show_warning_security_aliases "The target advertises recursion availability to the public client. Restrict UDP/TCP 53 unless this is an intentional public resolver."
    fi
  else
    echo "UDP 53 did not return a usable DNS response."
  fi

  if invalid_response=$(dig @"$target_value" "$probe_name" A +time=3 +tries=1 +stats 2>&1); then
    echo ""
    echo "Response for reserved invalid name $probe_name:"
    printf "%s\n" "$invalid_response" | sed -n "1,28p"
    if printf "%s\n" "$invalid_response" | grep -qE "198\.18\.|198\.19\."; then
      _show_warning_security_aliases "The DNS response uses 198.18.0.0/15, which commonly indicates Fake-IP proxy DNS behavior."
    elif printf "%s\n" "$invalid_response" | grep -q "status: NOERROR" && ! printf "%s\n" "$invalid_response" | grep -q "ANSWER: 0"; then
      _show_warning_security_aliases "The reserved .invalid name received an answer. Investigate wildcard DNS, interception, or synthetic DNS behavior."
    fi
  else
    echo "Reserved invalid name query received no usable response."
  fi

  if tcp_response=$(dig @"$target_value" example.com A +tcp +time=3 +tries=1 +stats 2>&1); then
    echo ""
    echo "TCP 53 responded:"
    printf "%s\n" "$tcp_response" | sed -n "1,24p"
  else
    echo "TCP 53 did not return a usable DNS response."
  fi

  if chaos_response=$(dig @"$target_value" version.bind CH TXT +time=3 +tries=1 +stats 2>&1); then
    echo ""
    echo "CHAOS version query response:"
    printf "%s\n" "$chaos_response" | sed -n "1,24p"
  else
    echo "CHAOS version query received no usable response."
  fi

  return 0
}

_run_tls_check_security_aliases() {
  local domain_name="$1"
  local connect_host="$2"
  local port_value="$3"
  local certificate_payload=""
  local protocol_payload=""
  local protocol_option=""
  local verification_line=""

  if ! _require_command_security_aliases openssl; then
    return 1
  fi

  if [ -z "$connect_host" ]; then
    connect_host="$domain_name"
  fi

  echo "TLS endpoint: $connect_host:$port_value"
  echo "SNI hostname: $domain_name"

  if ! certificate_payload=$(printf "" | openssl s_client -connect "$connect_host:$port_value" -servername "$domain_name" -status -showcerts 2>&1); then
    _show_error_security_aliases "Error: TLS handshake failed for $domain_name at $connect_host:$port_value."
    printf "%s\n" "$certificate_payload" | sed -n "1,24p" >&2
    return 1
  fi

  if ! printf "%s\n" "$certificate_payload" | grep -q "BEGIN CERTIFICATE"; then
    _show_error_security_aliases "Error: TLS endpoint returned no certificate for SNI $domain_name."
    printf "%s\n" "$certificate_payload" | sed -n "1,24p" >&2
    return 1
  fi

  echo "Certificate summary:"
  if ! printf "%s\n" "$certificate_payload" | openssl x509 -noout -subject -issuer -dates; then
    _show_error_security_aliases "Error: Failed to parse the peer certificate."
    return 1
  fi

  verification_line=$(printf "%s\n" "$certificate_payload" | grep "Verify return code:" | tail -n 1)
  if [ -n "$verification_line" ]; then
    echo "$verification_line"
    if ! printf "%s\n" "$verification_line" | grep -q "Verify return code: 0"; then
      _show_warning_security_aliases "The certificate chain did not verify successfully with the local trust store."
    fi
  else
    _show_warning_security_aliases "The TLS client did not report a certificate verification result."
  fi

  echo "Subject alternative names:"
  if ! printf "%s\n" "$certificate_payload" | openssl x509 -noout -ext subjectAltName 2>/dev/null; then
    _show_warning_security_aliases "This OpenSSL build could not print subject alternative names with -ext."
  fi

  if printf "%s\n" "$certificate_payload" | grep -qiE "OCSP response(s)?: no response(s)? sent"; then
    echo "OCSP stapling: not provided"
  elif printf "%s\n" "$certificate_payload" | grep -q "OCSP Response Status: successful"; then
    echo "OCSP stapling: provided"
  else
    echo "OCSP stapling: undetermined"
  fi

  echo "Protocol checks:"
  for protocol_option in "tls1_2" "tls1_3"; do
    protocol_payload=$(printf "" | openssl s_client -connect "$connect_host:$port_value" -servername "$domain_name" "-$protocol_option" -brief 2>&1)
    if printf "%s\n" "$protocol_payload" | grep -q "CONNECTION ESTABLISHED"; then
      echo "  supported  $protocol_option"
      printf "%s\n" "$protocol_payload" | grep -E "Protocol version|Ciphersuite" | sed "s/^/             /"
    elif printf "%s\n" "$protocol_payload" | grep -qiE "unknown option|no protocols available"; then
      echo "  local-client-unsupported  $protocol_option"
    else
      echo "  rejected-or-failed  $protocol_option"
    fi
  done

  return 0
}

_run_http_check_security_aliases() {
  local domain_name="$1"
  local connect_host="$2"
  local http_port="$3"
  local https_port="$4"
  local http_headers=""
  local https_headers=""
  local resolve_http=""
  local resolve_https=""

  if ! _require_command_security_aliases curl; then
    return 1
  fi

  if [ -n "$connect_host" ]; then
    resolve_http="$domain_name:$http_port:$connect_host"
    resolve_https="$domain_name:$https_port:$connect_host"
  fi

  echo "HTTP host: $domain_name"
  if [ -n "$connect_host" ]; then
    echo "Forced address: $connect_host"
  fi

  if [ -n "$resolve_http" ]; then
    http_headers=$(curl -sS --resolve "$resolve_http" --connect-timeout 5 --max-time 12 -D - -o /dev/null "http://$domain_name:$http_port/" 2>/dev/null)
  else
    http_headers=$(curl -sS --connect-timeout 5 --max-time 12 -D - -o /dev/null "http://$domain_name:$http_port/" 2>/dev/null)
  fi

  if [ -n "$http_headers" ]; then
    echo "HTTP response headers:"
    printf "%s\n" "$http_headers" | sed -n "1,24p"
    if ! printf "%s\n" "$http_headers" | grep -qE "^HTTP/[0-9.]+ (301|302|307|308)"; then
      _show_warning_security_aliases "HTTP did not return a standard redirect status to HTTPS at the tested root path."
    elif ! printf "%s\n" "$http_headers" | grep -qi "^location: https://"; then
      _show_warning_security_aliases "HTTP redirected, but the Location header did not clearly point to HTTPS."
    fi
  else
    echo "HTTP did not return response headers."
  fi

  if [ -n "$resolve_https" ]; then
    https_headers=$(curl -sS --resolve "$resolve_https" --connect-timeout 5 --max-time 12 -D - -o /dev/null "https://$domain_name:$https_port/" 2>/dev/null)
  else
    https_headers=$(curl -sS --connect-timeout 5 --max-time 12 -D - -o /dev/null "https://$domain_name:$https_port/" 2>/dev/null)
  fi

  if [ -z "$https_headers" ]; then
    _show_warning_security_aliases "Verified HTTPS failed. Retrying without certificate verification only to inspect headers."
    if [ -n "$resolve_https" ]; then
      https_headers=$(curl -ksS --resolve "$resolve_https" --connect-timeout 5 --max-time 12 -D - -o /dev/null "https://$domain_name:$https_port/" 2>/dev/null)
    else
      https_headers=$(curl -ksS --connect-timeout 5 --max-time 12 -D - -o /dev/null "https://$domain_name:$https_port/" 2>/dev/null)
    fi
  fi

  if [ -z "$https_headers" ]; then
    _show_error_security_aliases "Error: HTTPS did not return response headers for $domain_name:$https_port."
    return 1
  fi

  echo "HTTPS response headers:"
  printf "%s\n" "$https_headers" | sed -n "1,28p"

  echo "Security header presence:"
  _report_header_security_aliases "$https_headers" "strict-transport-security"
  _report_header_security_aliases "$https_headers" "content-security-policy"
  _report_header_security_aliases "$https_headers" "x-content-type-options"
  _report_header_security_aliases "$https_headers" "referrer-policy"
  _report_header_security_aliases "$https_headers" "permissions-policy"

  return 0
}

# Public aliases
# --------------

_sec_reverse_ip_security_aliases() {
  _show_usage_security_aliases "Find public domains associated with an IPv4 address and verify current A records.\nUsage:\n  sec-reverse-ip <ipv4>\nExample:\n  sec-reverse-ip 203.0.113.10\nPrivacy:\n  Sends the IP to SECURITY_REVERSE_IP_URL, default: api.hackertarget.com"

  if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    return 0
  fi

  if [ $# -ne 1 ]; then
    _show_error_security_aliases "Error: sec-reverse-ip requires exactly one IPv4 address."
    return 1
  fi

  _run_reverse_ip_security_aliases "$1"
}

alias sec-reverse-ip='_sec_reverse_ip_security_aliases' # Find passive domains for an IPv4 address and verify current A records

_sec_port_scan_security_aliases() {
  _show_usage_security_aliases "Run an authorized, rate-limited TCP scan with safe defaults.\nUsage:\n  sec-port-scan <target> --authorized [--top-ports count:1000 | --ports range | --full] [--service] [--host-timeout duration:5m]\nExamples:\n  sec-port-scan 203.0.113.10 --authorized\n  sec-port-scan example.com --authorized --ports 22,80,443 --service\n  sec-port-scan 203.0.113.10 --authorized --full --host-timeout 10m\nEnvironment:\n  DOTFILES_SECURITY_SCAN_ACK=1 skips the repeated --authorized flag for approved targets."

  local target_value=""
  local scan_mode="top"
  local scan_value="1000"
  local service_scan="no"
  local host_timeout="5m"
  local authorization_value="no"
  local selector_count="0"

  if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    return 0
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
      --authorized)
        authorization_value="yes"
        shift
        ;;
      --top-ports)
        if [ -z "$2" ]; then
          _show_error_security_aliases "Error: Missing value for --top-ports."
          return 1
        fi
        scan_mode="top"
        scan_value="$2"
        selector_count=$((selector_count + 1))
        shift 2
        ;;
      --ports)
        if [ -z "$2" ]; then
          _show_error_security_aliases "Error: Missing value for --ports."
          return 1
        fi
        scan_mode="ports"
        scan_value="$2"
        selector_count=$((selector_count + 1))
        shift 2
        ;;
      --full)
        scan_mode="full"
        scan_value="all"
        selector_count=$((selector_count + 1))
        shift
        ;;
      --service)
        service_scan="yes"
        shift
        ;;
      --host-timeout)
        if [ -z "$2" ]; then
          _show_error_security_aliases "Error: Missing value for --host-timeout."
          return 1
        fi
        host_timeout="$2"
        shift 2
        ;;
      --help|-h)
        return 0
        ;;
      --*)
        _show_error_security_aliases "Error: Unknown option: $1"
        return 1
        ;;
      *)
        if [ -n "$target_value" ]; then
          _show_error_security_aliases "Error: Unexpected parameter: $1"
          return 1
        fi
        target_value="$1"
        shift
        ;;
    esac
  done

  if [ -z "$target_value" ]; then
    _show_error_security_aliases "Error: Target is required."
    return 1
  fi

  if ! _validate_target_security_aliases "$target_value" || ! _require_authorization_security_aliases "$authorization_value"; then
    return 1
  fi

  if [ "$selector_count" -gt 1 ]; then
    _show_error_security_aliases "Error: Choose only one of --top-ports, --ports, or --full."
    return 1
  fi

  if [ "$scan_mode" = "top" ]; then
    if ! _is_integer_security_aliases "$scan_value" || [ "$scan_value" -lt 1 ] || [ "$scan_value" -gt 65535 ]; then
      _show_error_security_aliases "Error: --top-ports must be an integer between 1 and 65535."
      return 1
    fi
  elif [ "$scan_mode" = "ports" ]; then
    if ! echo "$scan_value" | grep -qE "^[0-9][0-9,-]*$"; then
      _show_error_security_aliases "Error: --ports accepts only numbers, commas, and hyphens, for example 22,80,443 or 1-1000."
      return 1
    fi
  elif [ "$scan_mode" = "full" ] && [ "$service_scan" = "yes" ]; then
    _show_error_security_aliases "Error: --service cannot be combined with --full. Scan ports first, then run service detection on the open port list."
    return 1
  fi

  if ! echo "$host_timeout" | grep -qE "^[1-9][0-9]*[smh]$"; then
    _show_error_security_aliases "Error: --host-timeout must use a positive number followed by s, m, or h, for example 90s or 5m."
    return 1
  fi

  _run_port_scan_security_aliases "$target_value" "$scan_mode" "$scan_value" "$service_scan" "$host_timeout"
}

alias sec-port-scan='_sec_port_scan_security_aliases' # Run an authorized TCP port scan with safe defaults and optional service detection

_sec_dns_check_security_aliases() {
  _show_usage_security_aliases "Check whether a target exposes recursive or Fake-IP DNS behavior.\nUsage:\n  sec-dns-check <target> --authorized\nExample:\n  sec-dns-check 203.0.113.10 --authorized"

  local target_value=""
  local authorization_value="no"

  if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    return 0
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
      --authorized)
        authorization_value="yes"
        shift
        ;;
      --help|-h)
        return 0
        ;;
      --*)
        _show_error_security_aliases "Error: Unknown option: $1"
        return 1
        ;;
      *)
        if [ -n "$target_value" ]; then
          _show_error_security_aliases "Error: Unexpected parameter: $1"
          return 1
        fi
        target_value="$1"
        shift
        ;;
    esac
  done

  if [ -z "$target_value" ]; then
    _show_error_security_aliases "Error: Target is required."
    return 1
  fi

  if ! _validate_target_security_aliases "$target_value" || ! _require_authorization_security_aliases "$authorization_value"; then
    return 1
  fi

  _run_dns_check_security_aliases "$target_value"
}

alias sec-dns-check='_sec_dns_check_security_aliases' # Check public recursive DNS, invalid-name, TCP DNS, and version-query behavior

_sec_tls_check_security_aliases() {
  _show_usage_security_aliases "Inspect a TLS certificate, OCSP stapling, TLS 1.2, and TLS 1.3 with explicit SNI.\nUsage:\n  sec-tls-check <domain> [--ip ipv4] [--port value:443]\nExamples:\n  sec-tls-check example.com\n  sec-tls-check app.example.com --ip 203.0.113.10"

  local domain_name=""
  local connect_host=""
  local port_value="443"

  if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    return 0
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
      --ip)
        if [ -z "$2" ]; then
          _show_error_security_aliases "Error: Missing value for --ip."
          return 1
        fi
        connect_host="$2"
        shift 2
        ;;
      --port)
        if [ -z "$2" ]; then
          _show_error_security_aliases "Error: Missing value for --port."
          return 1
        fi
        port_value="$2"
        shift 2
        ;;
      --help|-h)
        return 0
        ;;
      --*)
        _show_error_security_aliases "Error: Unknown option: $1"
        return 1
        ;;
      *)
        if [ -n "$domain_name" ]; then
          _show_error_security_aliases "Error: Unexpected parameter: $1"
          return 1
        fi
        domain_name="$1"
        shift
        ;;
    esac
  done

  if [ -z "$domain_name" ] || ! _is_hostname_security_aliases "$domain_name"; then
    _show_error_security_aliases "Error: A valid SNI hostname is required."
    return 1
  fi

  if [ -n "$connect_host" ] && ! _is_ipv4_security_aliases "$connect_host"; then
    _show_error_security_aliases "Error: --ip requires a valid IPv4 address."
    return 1
  fi

  if ! _validate_port_security_aliases "$port_value"; then
    return 1
  fi

  _run_tls_check_security_aliases "$domain_name" "$connect_host" "$port_value"
}

alias sec-tls-check='_sec_tls_check_security_aliases' # Inspect TLS certificate details, OCSP stapling, and modern protocol support

_sec_http_check_security_aliases() {
  _show_usage_security_aliases "Inspect HTTP redirects, HTTPS verification, and common security response headers.\nUsage:\n  sec-http-check <domain> [--ip ipv4] [--http-port value:80] [--https-port value:443]\nExamples:\n  sec-http-check example.com\n  sec-http-check app.example.com --ip 203.0.113.10"

  local domain_name=""
  local connect_host=""
  local http_port="80"
  local https_port="443"

  if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    return 0
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
      --ip)
        if [ -z "$2" ]; then
          _show_error_security_aliases "Error: Missing value for --ip."
          return 1
        fi
        connect_host="$2"
        shift 2
        ;;
      --http-port)
        if [ -z "$2" ]; then
          _show_error_security_aliases "Error: Missing value for --http-port."
          return 1
        fi
        http_port="$2"
        shift 2
        ;;
      --https-port)
        if [ -z "$2" ]; then
          _show_error_security_aliases "Error: Missing value for --https-port."
          return 1
        fi
        https_port="$2"
        shift 2
        ;;
      --help|-h)
        return 0
        ;;
      --*)
        _show_error_security_aliases "Error: Unknown option: $1"
        return 1
        ;;
      *)
        if [ -n "$domain_name" ]; then
          _show_error_security_aliases "Error: Unexpected parameter: $1"
          return 1
        fi
        domain_name="$1"
        shift
        ;;
    esac
  done

  if [ -z "$domain_name" ] || ! _is_hostname_security_aliases "$domain_name"; then
    _show_error_security_aliases "Error: A valid HTTP hostname is required."
    return 1
  fi

  if [ -n "$connect_host" ] && ! _is_ipv4_security_aliases "$connect_host"; then
    _show_error_security_aliases "Error: --ip requires a valid IPv4 address."
    return 1
  fi

  if ! _validate_port_security_aliases "$http_port" || ! _validate_port_security_aliases "$https_port"; then
    return 1
  fi

  _run_http_check_security_aliases "$domain_name" "$connect_host" "$http_port" "$https_port"
}

alias sec-http-check='_sec_http_check_security_aliases' # Inspect redirects, certificate verification, and common HTTP security headers

_sec_server_scan_security_aliases() {
  _show_usage_security_aliases "Run a defensive external server assessment against an authorized target.\nUsage:\n  sec-server-scan <target> --authorized [--domain sni_hostname] [--top-ports count:1000] [--service] [--skip-reverse-ip] [--host-timeout duration:5m]\nExamples:\n  sec-server-scan 203.0.113.10 --authorized\n  sec-server-scan 203.0.113.10 --authorized --domain app.example.com --service\n  sec-server-scan example.com --authorized --top-ports 100"

  local target_value=""
  local domain_name=""
  local top_ports="1000"
  local service_scan="no"
  local host_timeout="5m"
  local authorization_value="no"
  local reverse_lookup="yes"
  local whois_payload=""
  local endpoint_ip=""
  local scan_errors="0"

  if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    return 0
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
      --authorized)
        authorization_value="yes"
        shift
        ;;
      --domain)
        if [ -z "$2" ]; then
          _show_error_security_aliases "Error: Missing value for --domain."
          return 1
        fi
        domain_name="$2"
        shift 2
        ;;
      --top-ports)
        if [ -z "$2" ]; then
          _show_error_security_aliases "Error: Missing value for --top-ports."
          return 1
        fi
        top_ports="$2"
        shift 2
        ;;
      --service)
        service_scan="yes"
        shift
        ;;
      --skip-reverse-ip)
        reverse_lookup="no"
        shift
        ;;
      --host-timeout)
        if [ -z "$2" ]; then
          _show_error_security_aliases "Error: Missing value for --host-timeout."
          return 1
        fi
        host_timeout="$2"
        shift 2
        ;;
      --help|-h)
        return 0
        ;;
      --*)
        _show_error_security_aliases "Error: Unknown option: $1"
        return 1
        ;;
      *)
        if [ -n "$target_value" ]; then
          _show_error_security_aliases "Error: Unexpected parameter: $1"
          return 1
        fi
        target_value="$1"
        shift
        ;;
    esac
  done

  if [ -z "$target_value" ]; then
    _show_error_security_aliases "Error: Target is required."
    return 1
  fi

  if ! _validate_target_security_aliases "$target_value" || ! _require_authorization_security_aliases "$authorization_value"; then
    return 1
  fi

  if ! _is_integer_security_aliases "$top_ports" || [ "$top_ports" -lt 1 ] || [ "$top_ports" -gt 65535 ]; then
    _show_error_security_aliases "Error: --top-ports must be an integer between 1 and 65535."
    return 1
  fi

  if ! echo "$host_timeout" | grep -qE "^[1-9][0-9]*[smh]$"; then
    _show_error_security_aliases "Error: --host-timeout must use a positive number followed by s, m, or h."
    return 1
  fi

  if [ -n "$domain_name" ] && ! _is_hostname_security_aliases "$domain_name"; then
    _show_error_security_aliases "Error: --domain requires a valid hostname."
    return 1
  fi

  if _is_ipv4_security_aliases "$target_value"; then
    endpoint_ip="$target_value"
  else
    if [ -n "$domain_name" ] && [ "$domain_name" != "$target_value" ]; then
      _show_error_security_aliases "Error: --domain may differ from the target only when the target is an IPv4 address."
      return 1
    fi
    domain_name="$target_value"
  fi

  _print_section_security_aliases "Target Summary"
  echo "Target: $target_value"
  if [ -n "$domain_name" ]; then
    echo "Application domain: $domain_name"
  fi

  if command -v whois >/dev/null 2>&1; then
    if whois_payload=$(whois "$target_value" 2>/dev/null); then
      printf "%s\n" "$whois_payload" | grep -Ei "^(inetnum|netname|descr|country|org-name|origin):" | head -n 24
    else
      _show_warning_security_aliases "WHOIS lookup failed for $target_value."
    fi
  else
    _show_warning_security_aliases "whois was not found; ownership data was skipped."
  fi

  if _is_ipv4_security_aliases "$target_value" && command -v dig >/dev/null 2>&1; then
    echo "PTR: $(dig +short -x "$target_value" 2>/dev/null | head -n 1)"
  fi

  if [ "$reverse_lookup" = "yes" ] && _is_ipv4_security_aliases "$target_value"; then
    _print_section_security_aliases "Passive Reverse IP"
    if ! _run_reverse_ip_security_aliases "$target_value"; then
      scan_errors=$((scan_errors + 1))
    fi
  fi

  _print_section_security_aliases "TCP Exposure"
  if ! _run_port_scan_security_aliases "$target_value" "top" "$top_ports" "$service_scan" "$host_timeout"; then
    scan_errors=$((scan_errors + 1))
  fi

  _print_section_security_aliases "DNS Exposure"
  if ! _run_dns_check_security_aliases "$target_value"; then
    scan_errors=$((scan_errors + 1))
  fi

  if [ -n "$domain_name" ]; then
    _print_section_security_aliases "TLS"
    if ! _run_tls_check_security_aliases "$domain_name" "$endpoint_ip" "443"; then
      scan_errors=$((scan_errors + 1))
    fi

    _print_section_security_aliases "HTTP"
    if ! _run_http_check_security_aliases "$domain_name" "$endpoint_ip" "80" "443"; then
      scan_errors=$((scan_errors + 1))
    fi
  else
    _show_warning_security_aliases "TLS and HTTP virtual-host checks were skipped. Add --domain with the expected SNI hostname."
  fi

  _print_section_security_aliases "Assessment Notes"
  echo "TCP handshakes alone do not prove that an application service is exposed."
  echo "Reverse IP providers can return incomplete or historical domain data."
  echo "This check does not inspect operating system patches, accounts, application code, cloud security groups, or authenticated routes."

  if [ "$scan_errors" -gt 0 ]; then
    _show_error_security_aliases "Error: Assessment completed with $scan_errors failed check group(s). Review the messages above."
    return 1
  fi

  return 0
}

alias sec-server-scan='_sec_server_scan_security_aliases' # Run a combined external server assessment for an authorized target

_security_help_security_aliases() {
  _show_usage_security_aliases "Defensive server security aliases. Use active checks only on systems you own or are authorized to test.\n\nCommands:\n  sec-reverse-ip    Find passive domains for an IPv4 address and verify A records\n  sec-port-scan     Run a bounded TCP port scan with optional service detection\n  sec-dns-check     Test public recursive, Fake-IP, TCP DNS, and version behavior\n  sec-tls-check     Inspect certificate, OCSP stapling, TLS 1.2, and TLS 1.3\n  sec-http-check    Inspect redirects, certificate verification, and security headers\n  sec-server-scan   Run the combined external assessment\n  security-help     Show this command overview\n\nSafety:\n  Active scan commands require --authorized.\n  Set DOTFILES_SECURITY_SCAN_ACK=1 only when your routine targets are approved.\n  Full scans are explicit and never enable service detection automatically.\n\nExamples:\n  sec-reverse-ip 203.0.113.10\n  sec-port-scan 203.0.113.10 --authorized --ports 22,80,443 --service\n  sec-server-scan 203.0.113.10 --authorized --domain app.example.com"

  if [ $# -gt 0 ] && [ "$1" != "--help" ] && [ "$1" != "-h" ]; then
    _show_error_security_aliases "Error: security-help does not accept parameters."
    return 1
  fi

  return 0
}

alias security-help='_security_help_security_aliases' # Show defensive server security alias usage and safety notes
