# Description: SSL certificate management, inspection, packaging, and acme.sh helper aliases.

# Helper Functions
# ----------------

_check_command_ssl_aliases() {
  command -v "$1" >/dev/null 2>&1
}

_show_usage_ssl_aliases() {
  printf "%b\n" "$1"
}

_show_error_ssl_aliases() {
  echo "$1" >&2
}

_maybe_show_help_ssl_aliases() {
  local first_arg="$1"
  local usage_text="$2"

  if [ "$first_arg" = "-h" ] || [ "$first_arg" = "--help" ]; then
    _show_usage_ssl_aliases "$usage_text"
    return 0
  fi

  return 1
}

_ensure_commands_ssl_aliases() {
  local command_name=""

  for command_name in "$@"; do
    if ! _check_command_ssl_aliases "$command_name"; then
      _show_error_ssl_aliases "Error: Required command not found: $command_name"
      return 1
    fi
  done

  return 0
}

_validate_port_ssl_aliases() {
  local port_value="$1"

  if ! [[ "$port_value" =~ ^[0-9]+$ ]] || [ "$port_value" -lt 1 ] || [ "$port_value" -gt 65535 ]; then
    _show_error_ssl_aliases "Error: Port must be a number between 1 and 65535"
    return 1
  fi

  return 0
}

_sanitize_name_ssl_aliases() {
  printf "%s" "$1" | LC_ALL=C tr ":/* " "____" | LC_ALL=C tr -c "A-Za-z0-9._-" "_"
}

_ensure_parent_root_ssl_aliases() {
  local target_name="$1"
  local parent_root="."

  case "$target_name" in
    */*)
      parent_root="${target_name%/*}"
      ;;
  esac

  if [ -n "$parent_root" ] && [ ! -d "$parent_root" ]; then
    if ! mkdir -p "$parent_root"; then
      _show_error_ssl_aliases "Error: Failed to create parent directory: $parent_root"
      return 1
    fi
  fi

  return 0
}

_resolve_acme_home_ssl_aliases() {
  if [ -n "$ACME_HOME" ]; then
    printf "%s\n" "$ACME_HOME"
    return 0
  fi

  printf "%s\n" "$HOME/.acme.sh"
}

_resolve_acme_binary_ssl_aliases() {
  local acme_home=""
  local acme_exec=""

  acme_home="$(_resolve_acme_home_ssl_aliases)"
  acme_exec="$acme_home/acme.sh"

  if [ -x "$acme_exec" ]; then
    printf "%s\n" "$acme_exec"
    return 0
  fi

  if [ -x "$HOME/.acme.sh/acme.sh" ]; then
    printf "%s\n" "$HOME/.acme.sh/acme.sh"
    return 0
  fi

  if [ -x "/root/.acme.sh/acme.sh" ]; then
    printf "%s\n" "/root/.acme.sh/acme.sh"
    return 0
  fi

  return 1
}

_resolve_acme_repo_ssl_aliases() {
  local source_name="${1:-github}"

  case "$source_name" in
    github)
      printf "%s\n" "https://github.com/acmesh-official/acme.sh.git"
      return 0
      ;;
    gitee|cn)
      printf "%s\n" "https://gitee.com/acmesh-official/acme.sh.git"
      return 0
      ;;
    *)
      _show_error_ssl_aliases "Error: Unsupported source: $source_name"
      _show_error_ssl_aliases "Supported sources: github, gitee"
      return 1
      ;;
  esac
}

_date_to_epoch_ssl_aliases() {
  local raw_date="$1"
  local epoch_value=""

  if _check_command_ssl_aliases "python3"; then
    epoch_value=$(python3 -c "import datetime, sys; raw=sys.argv[1]; expiry=datetime.datetime.strptime(raw, \"%b %d %H:%M:%S %Y %Z\").replace(tzinfo=datetime.timezone.utc); print(int(expiry.timestamp()))" "$raw_date" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$epoch_value" ]; then
      printf "%s\n" "$epoch_value"
      return 0
    fi
  fi

  if date -d "$raw_date" "+%s" >/dev/null 2>&1; then
    date -d "$raw_date" "+%s"
    return 0
  fi

  if date -j -f "%b %d %H:%M:%S %Y %Z" "$raw_date" "+%s" >/dev/null 2>&1; then
    date -j -f "%b %d %H:%M:%S %Y %Z" "$raw_date" "+%s"
    return 0
  fi

  return 1
}

_remaining_days_ssl_aliases() {
  local raw_date="$1"
  local expiry_epoch=""
  local now_epoch=""

  expiry_epoch="$(_date_to_epoch_ssl_aliases "$raw_date")"
  if [ $? -ne 0 ] || [ -z "$expiry_epoch" ]; then
    return 1
  fi

  now_epoch=$(date "+%s" 2>/dev/null)
  if [ $? -ne 0 ] || [ -z "$now_epoch" ]; then
    return 1
  fi

  printf "%s\n" "$(( (expiry_epoch - now_epoch) / 86400 ))"
}

_build_san_csv_ssl_aliases() {
  local common_name="$1"
  local extra_sans="$2"
  local san_csv="$common_name"

  case "$common_name" in
    localhost)
      san_csv="localhost,127.0.0.1,::1"
      ;;
    *.*)
      case "$common_name" in
        \*.*|www.*)
          san_csv="$common_name"
          ;;
        *)
          san_csv="$common_name,www.$common_name"
          ;;
      esac
      ;;
  esac

  if [ -n "$extra_sans" ]; then
    san_csv="$san_csv,$extra_sans"
  fi

  printf "%s\n" "$san_csv" | awk -F"," "
{
  for (item_idx = 1; item_idx <= NF; item_idx++) {
    item = \$item_idx
    gsub(/^[[:space:]]+|[[:space:]]+$/, \"\", item)
    if (item != \"\" && !seen[item]++) {
      values[++count] = item
    }
  }
}
END {
  for (item_idx = 1; item_idx <= count; item_idx++) {
    printf \"%s\", values[item_idx]
    if (item_idx < count) {
      printf \",\"
    }
  }
  printf \"\n\"
}"
}

_write_req_config_ssl_aliases() {
  local config_target="$1"
  local common_name="$2"
  local san_csv="$3"

  awk -v common_name="$common_name" -v san_csv="$san_csv" "
BEGIN {
  print \"[req]\"
  print \"default_bits = 2048\"
  print \"prompt = no\"
  print \"default_md = sha256\"
  print \"distinguished_name = dn\"
  print \"req_extensions = req_ext\"
  print \"x509_extensions = req_ext\"
  print \"\"
  print \"[dn]\"
  print \"CN = \" common_name
  print \"\"
  print \"[req_ext]\"
  print \"subjectAltName = @alt_names\"
  print \"basicConstraints = CA:FALSE\"
  print \"keyUsage = digitalSignature, keyEncipherment\"
  print \"extendedKeyUsage = serverAuth, clientAuth\"
  print \"\"
  print \"[alt_names]\"

  san_count = split(san_csv, values, \",\")
  for (item_idx = 1; item_idx <= san_count; item_idx++) {
    item = values[item_idx]
    gsub(/^[[:space:]]+|[[:space:]]+$/, \"\", item)
    if (item == \"\") {
      continue
    }
    if (item ~ /^[0-9a-fA-F:.]+$/) {
      ip_count++
      printf \"IP.%d = %s\\n\", ip_count, item
    } else {
      dns_count++
      printf \"DNS.%d = %s\\n\", dns_count, item
    }
  }
}
" > "$config_target"

  if [ $? -ne 0 ] || [ ! -s "$config_target" ]; then
    _show_error_ssl_aliases "Error: Failed to write OpenSSL config: $config_target"
    return 1
  fi

  return 0
}

_fetch_sclient_output_ssl_aliases() {
  local host_value="$1"
  local port_value="$2"
  local output_target="$3"

  if ! openssl s_client -connect "$host_value:$port_value" -servername "$host_value" -showcerts </dev/null >"$output_target" 2>&1; then
    _show_error_ssl_aliases "Error: Failed to connect to $host_value:$port_value"
    return 1
  fi

  if [ ! -s "$output_target" ]; then
    _show_error_ssl_aliases "Error: No TLS response received from $host_value:$port_value"
    return 1
  fi

  return 0
}

_extract_leaf_cert_ssl_aliases() {
  local source_target="$1"
  local output_target="$2"

  awk "
BEGIN {
  inside = 0
  found = 0
}
/BEGIN CERTIFICATE/ {
  inside = 1
  found = 1
}
inside {
  print
}
/END CERTIFICATE/ {
  exit
}
END {
  if (found == 0) {
    exit 1
  }
}
" "$source_target" > "$output_target"

  if [ $? -ne 0 ] || [ ! -s "$output_target" ]; then
    _show_error_ssl_aliases "Error: Failed to extract certificate from TLS response"
    return 1
  fi

  return 0
}

_extract_cert_to_pem_ssl_aliases() {
  local cert_source="$1"
  local output_target="$2"
  local source_name="${cert_source##*/}"
  local bundle_target=""

  case "$source_name" in
    *.p12|*.P12|*.pfx|*.PFX)
      if ! openssl pkcs12 -in "$cert_source" -nokeys -clcerts 2>/dev/null | openssl x509 -out "$output_target" 2>/dev/null; then
        _show_error_ssl_aliases "Error: Failed to extract certificate from PKCS#12 bundle: $cert_source"
        return 1
      fi
      ;;
    *.p7b|*.P7B|*.p7c|*.P7C)
      bundle_target=$(mktemp 2>/dev/null)
      if [ -z "$bundle_target" ]; then
        _show_error_ssl_aliases "Error: Failed to create temporary file for PKCS#7 conversion"
        return 1
      fi

      if ! openssl pkcs7 -print_certs -in "$cert_source" 2>/dev/null >"$bundle_target"; then
        rm -f "$bundle_target"
        _show_error_ssl_aliases "Error: Failed to extract certificate from PKCS#7 bundle: $cert_source"
        return 1
      fi

      if ! _extract_leaf_cert_ssl_aliases "$bundle_target" "$output_target"; then
        rm -f "$bundle_target"
        return 1
      fi

      rm -f "$bundle_target"
      ;;
    *)
      if openssl x509 -in "$cert_source" -out "$output_target" 2>/dev/null; then
        :
      elif openssl x509 -inform der -in "$cert_source" -out "$output_target" 2>/dev/null; then
        :
      else
        _show_error_ssl_aliases "Error: Unsupported or unreadable certificate format: $cert_source"
        return 1
      fi
      ;;
  esac

  if [ ! -s "$output_target" ]; then
    _show_error_ssl_aliases "Error: Extracted certificate is empty: $output_target"
    return 1
  fi

  return 0
}

_show_cert_summary_from_pem_ssl_aliases() {
  local cert_source="$1"

  if ! openssl x509 -in "$cert_source" -noout -subject -issuer -dates -serial -fingerprint -sha256; then
    _show_error_ssl_aliases "Error: Failed to read certificate summary from $cert_source"
    return 1
  fi

  openssl x509 -in "$cert_source" -noout -ext subjectAltName 2>/dev/null || true
  return 0
}

_show_cert_summary_ssl_aliases() {
  local cert_source="$1"
  local work_target=""
  local command_exit=0

  work_target=$(mktemp 2>/dev/null)
  if [ -z "$work_target" ]; then
    _show_error_ssl_aliases "Error: Failed to create temporary file for certificate summary"
    return 1
  fi

  if ! _extract_cert_to_pem_ssl_aliases "$cert_source" "$work_target"; then
    rm -f "$work_target"
    return 1
  fi

  _show_cert_summary_from_pem_ssl_aliases "$work_target"
  command_exit=$?
  rm -f "$work_target"
  return "$command_exit"
}

_fetch_remote_leaf_ssl_aliases() {
  local host_value="$1"
  local port_value="$2"
  local bundle_target="$3"
  local leaf_target="$4"

  if ! _fetch_sclient_output_ssl_aliases "$host_value" "$port_value" "$bundle_target"; then
    return 1
  fi

  if ! _extract_leaf_cert_ssl_aliases "$bundle_target" "$leaf_target"; then
    return 1
  fi

  return 0
}

_split_chain_ssl_aliases() {
  local source_target="$1"
  local output_root="$2"
  local prefix_name="$3"
  local count_value=""

  count_value=$(awk -v output_root="$output_root" -v prefix_name="$prefix_name" "
/BEGIN CERTIFICATE/ {
  count++
  current = sprintf(\"%s/%s-%02d.pem\", output_root, prefix_name, count)
}
count > 0 {
  print > current
}
/END CERTIFICATE/ {
  close(current)
}
END {
  if (count == 0) {
    exit 1
  }
  print count
}
" "$source_target")

  if [ $? -ne 0 ] || [ -z "$count_value" ]; then
    _show_error_ssl_aliases "Error: Failed to split certificate chain"
    return 1
  fi

  printf "%s\n" "$count_value"
}

_cert_pubkey_sha_ssl_aliases() {
  local cert_source="$1"
  local digest_value=""

  digest_value=$(openssl x509 -in "$cert_source" -pubkey -noout 2>/dev/null | openssl pkey -pubin -outform der 2>/dev/null | openssl dgst -sha256 2>/dev/null | awk "{print \$2}")
  if [ -z "$digest_value" ]; then
    digest_value=$(openssl x509 -inform der -in "$cert_source" -pubkey -noout 2>/dev/null | openssl pkey -pubin -outform der 2>/dev/null | openssl dgst -sha256 2>/dev/null | awk "{print \$2}")
  fi

  if [ -z "$digest_value" ]; then
    _show_error_ssl_aliases "Error: Failed to derive certificate public key digest from $cert_source"
    return 1
  fi

  printf "%s\n" "$digest_value"
}

_key_pubkey_sha_ssl_aliases() {
  local key_source="$1"
  local digest_value=""

  digest_value=$(openssl pkey -in "$key_source" -pubout -outform der 2>/dev/null | openssl dgst -sha256 2>/dev/null | awk "{print \$2}")
  if [ -z "$digest_value" ]; then
    _show_error_ssl_aliases "Error: Failed to derive private key public digest from $key_source"
    return 1
  fi

  printf "%s\n" "$digest_value"
}

_run_acme_ssl_aliases() {
  local acme_exec=""

  acme_exec="$(_resolve_acme_binary_ssl_aliases)"
  if [ $? -ne 0 ] || [ -z "$acme_exec" ]; then
    _show_error_ssl_aliases "Error: acme.sh is not installed for the current shell."
    _show_error_ssl_aliases "Run ssl-acme-install first, or set ACME_HOME to the existing install directory."
    return 1
  fi

  "$acme_exec" "$@"
}

_convert_cert_ssl_aliases() {
  local input_source="$1"
  local format_name="$2"
  local output_target="$3"
  local key_source="$4"
  local ca_source="$5"
  local work_target=""

  if ! _ensure_parent_root_ssl_aliases "$output_target"; then
    return 1
  fi

  case "$format_name" in
    pem)
      if ! _extract_cert_to_pem_ssl_aliases "$input_source" "$output_target"; then
        return 1
      fi
      ;;
    der)
      work_target=$(mktemp 2>/dev/null)
      if [ -z "$work_target" ]; then
        _show_error_ssl_aliases "Error: Failed to create temporary file for DER conversion"
        return 1
      fi

      if ! _extract_cert_to_pem_ssl_aliases "$input_source" "$work_target"; then
        rm -f "$work_target"
        return 1
      fi

      if ! openssl x509 -in "$work_target" -outform der -out "$output_target"; then
        rm -f "$work_target"
        _show_error_ssl_aliases "Error: Failed to convert certificate to DER: $output_target"
        return 1
      fi

      rm -f "$work_target"
      ;;
    p12|pfx)
      if [ -z "$key_source" ]; then
        _show_error_ssl_aliases "Error: A private key is required when exporting PKCS#12"
        return 1
      fi

      if [ ! -f "$key_source" ]; then
        _show_error_ssl_aliases "Error: Private key not found: $key_source"
        return 1
      fi

      if [ -n "$ca_source" ] && [ ! -f "$ca_source" ]; then
        _show_error_ssl_aliases "Error: CA bundle not found: $ca_source"
        return 1
      fi

      work_target=$(mktemp 2>/dev/null)
      if [ -z "$work_target" ]; then
        _show_error_ssl_aliases "Error: Failed to create temporary file for PKCS#12 export"
        return 1
      fi

      if ! _extract_cert_to_pem_ssl_aliases "$input_source" "$work_target"; then
        rm -f "$work_target"
        return 1
      fi

      if [ -n "$ca_source" ]; then
        if ! openssl pkcs12 -export -out "$output_target" -inkey "$key_source" -in "$work_target" -certfile "$ca_source"; then
          rm -f "$work_target"
          _show_error_ssl_aliases "Error: Failed to export PKCS#12 bundle: $output_target"
          return 1
        fi
      else
        if ! openssl pkcs12 -export -out "$output_target" -inkey "$key_source" -in "$work_target"; then
          rm -f "$work_target"
          _show_error_ssl_aliases "Error: Failed to export PKCS#12 bundle: $output_target"
          return 1
        fi
      fi

      rm -f "$work_target"
      ;;
    *)
      _show_error_ssl_aliases "Error: Unsupported output format: $format_name"
      _show_error_ssl_aliases "Supported formats: pem, der, p12, pfx"
      return 1
      ;;
  esac

  echo "Success: Wrote $output_target"
  return 0
}

# acme.sh aliases
# ---------------

alias ssl-acme-install='() {
  local usage_text="Install acme.sh into the current user environment.\nUsage:\n ssl-acme-install [email:ACME_DEFAULT_EMAIL|EMAIL] [source:github|gitee] [home_root:$HOME/.acme.sh]\nExamples:\n ssl-acme-install ops@example.com\n ssl-acme-install ops@example.com gitee ~/.acme.sh"
  local email_value="$1"
  local source_name="${2:-github}"
  local home_root="${3:-$(_resolve_acme_home_ssl_aliases)}"
  local repo_url=""
  local work_root=""

  if _maybe_show_help_ssl_aliases "$1" "$usage_text"; then
    return 0
  fi

  if ! _ensure_commands_ssl_aliases git mktemp rm; then
    return 1
  fi

  if [ -z "$email_value" ]; then
    email_value="${ACME_DEFAULT_EMAIL:-${EMAIL:-}}"
  fi

  if [ -z "$email_value" ]; then
    _show_error_ssl_aliases "Error: Missing account email."
    _show_error_ssl_aliases "Provide it explicitly or export ACME_DEFAULT_EMAIL."
    return 1
  fi

  repo_url="$(_resolve_acme_repo_ssl_aliases "$source_name")"
  if [ $? -ne 0 ] || [ -z "$repo_url" ]; then
    return 1
  fi

  if [ -x "$home_root/acme.sh" ]; then
    echo "acme.sh is already installed: $home_root/acme.sh"
    return 0
  fi

  work_root=$(mktemp -d 2>/dev/null)
  if [ -z "$work_root" ] || [ ! -d "$work_root" ]; then
    _show_error_ssl_aliases "Error: Failed to create temporary directory for acme.sh install"
    return 1
  fi

  if ! git clone --depth 1 "$repo_url" "$work_root/acme.sh"; then
    rm -rf "$work_root"
    _show_error_ssl_aliases "Error: Failed to clone acme.sh from $source_name"
    return 1
  fi

  if ! (
    cd "$work_root/acme.sh" &&
    ./acme.sh --install -m "$email_value" --home "$home_root" --force
  ); then
    rm -rf "$work_root"
    _show_error_ssl_aliases "Error: Failed to install acme.sh into $home_root"
    return 1
  fi

  rm -rf "$work_root"
  echo "Success: acme.sh installed at $home_root"
  echo "Run ssl-acme --list to verify the install."
}' # Install acme.sh with user-scoped defaults and official mirrors

alias ssl-acme='() {
  local usage_text="Run the installed acme.sh client.\nUsage:\n ssl-acme <acme_args...>\nExamples:\n ssl-acme --list\n ssl-acme --issue -d example.com --webroot /var/www/html"

  if [ $# -eq 0 ]; then
    _show_usage_ssl_aliases "$usage_text"
    return 0
  fi

  _run_acme_ssl_aliases "$@"
}' # Run acme.sh without remembering the install path

# Certificate generation aliases
# ------------------------------

alias ssl-self='() {
  local usage_text="Generate a self-signed certificate with SAN support.\nUsage:\n ssl-self <common_name:localhost> [days:365] [rsa_bits:2048] [output_root:./ssl] [--san dns1,dns2]\nExamples:\n ssl-self localhost\n ssl-self api.example.com 825 4096 ./ssl --san api.example.com,internal.example.com"
  local common_name="${1:-localhost}"
  local days_value="${2:-365}"
  local bits_value="${3:-2048}"
  local output_root="${4:-./ssl}"
  local san_input=""
  local san_csv=""
  local base_name=""
  local config_target=""
  local cert_target=""
  local key_target=""

  if _maybe_show_help_ssl_aliases "$1" "$usage_text"; then
    return 0
  fi

  if ! _ensure_commands_ssl_aliases openssl mkdir; then
    return 1
  fi

  if ! [[ "$days_value" =~ ^[0-9]+$ ]] || [ "$days_value" -lt 1 ]; then
    _show_error_ssl_aliases "Error: Days must be a positive integer"
    return 1
  fi

  if ! [[ "$bits_value" =~ ^[0-9]+$ ]] || [ "$bits_value" -lt 2048 ]; then
    _show_error_ssl_aliases "Error: RSA bits must be an integer greater than or equal to 2048"
    return 1
  fi

  if [ $# -gt 4 ]; then
    shift 4
    while [ $# -gt 0 ]; do
      case "$1" in
        --san)
          san_input="$2"
          if [ -z "$san_input" ]; then
            _show_error_ssl_aliases "Error: --san requires a comma-separated value"
            return 1
          fi
          shift 2
          ;;
        *)
          _show_error_ssl_aliases "Error: Unknown option: $1"
          return 1
          ;;
      esac
    done
  fi

  if ! mkdir -p "$output_root"; then
    _show_error_ssl_aliases "Error: Failed to create output directory: $output_root"
    return 1
  fi

  san_csv="$(_build_san_csv_ssl_aliases "$common_name" "$san_input")"
  base_name="$(_sanitize_name_ssl_aliases "$common_name")"
  config_target="$output_root/$base_name.cnf"
  cert_target="$output_root/$base_name.crt"
  key_target="$output_root/$base_name.key"

  if ! _write_req_config_ssl_aliases "$config_target" "$common_name" "$san_csv"; then
    return 1
  fi

  if ! openssl req -x509 -newkey "rsa:$bits_value" -nodes -sha256 -days "$days_value" -keyout "$key_target" -out "$cert_target" -config "$config_target" -extensions req_ext; then
    _show_error_ssl_aliases "Error: Failed to generate self-signed certificate for $common_name"
    return 1
  fi

  echo "Success: Generated self-signed certificate for $common_name"
  echo "Key: $key_target"
  echo "Certificate: $cert_target"
  echo "Config: $config_target"
  _show_cert_summary_from_pem_ssl_aliases "$cert_target"
}' # Generate a self-signed certificate with sensible SAN defaults

alias ssl-csr='() {
  local usage_text="Generate a CSR and private key with SAN support.\nUsage:\n ssl-csr <common_name:example.com> [rsa_bits:2048] [output_root:./ssl] [--san dns1,dns2]\nExamples:\n ssl-csr example.com\n ssl-csr api.example.com 4096 ./ssl --san api.example.com,internal.example.com"
  local common_name="${1:-example.com}"
  local bits_value="${2:-2048}"
  local output_root="${3:-./ssl}"
  local san_input=""
  local san_csv=""
  local base_name=""
  local config_target=""
  local csr_target=""
  local key_target=""

  if _maybe_show_help_ssl_aliases "$1" "$usage_text"; then
    return 0
  fi

  if ! _ensure_commands_ssl_aliases openssl mkdir; then
    return 1
  fi

  if ! [[ "$bits_value" =~ ^[0-9]+$ ]] || [ "$bits_value" -lt 2048 ]; then
    _show_error_ssl_aliases "Error: RSA bits must be an integer greater than or equal to 2048"
    return 1
  fi

  if [ $# -gt 3 ]; then
    shift 3
    while [ $# -gt 0 ]; do
      case "$1" in
        --san)
          san_input="$2"
          if [ -z "$san_input" ]; then
            _show_error_ssl_aliases "Error: --san requires a comma-separated value"
            return 1
          fi
          shift 2
          ;;
        *)
          _show_error_ssl_aliases "Error: Unknown option: $1"
          return 1
          ;;
      esac
    done
  fi

  if ! mkdir -p "$output_root"; then
    _show_error_ssl_aliases "Error: Failed to create output directory: $output_root"
    return 1
  fi

  san_csv="$(_build_san_csv_ssl_aliases "$common_name" "$san_input")"
  base_name="$(_sanitize_name_ssl_aliases "$common_name")"
  config_target="$output_root/$base_name.cnf"
  csr_target="$output_root/$base_name.csr"
  key_target="$output_root/$base_name.key"

  if ! _write_req_config_ssl_aliases "$config_target" "$common_name" "$san_csv"; then
    return 1
  fi

  if ! openssl req -new -newkey "rsa:$bits_value" -nodes -sha256 -keyout "$key_target" -out "$csr_target" -config "$config_target"; then
    _show_error_ssl_aliases "Error: Failed to generate CSR for $common_name"
    return 1
  fi

  echo "Success: Generated CSR for $common_name"
  echo "Key: $key_target"
  echo "CSR: $csr_target"
  echo "Config: $config_target"
  openssl req -in "$csr_target" -noout -subject -verify 2>/dev/null || true
}' # Generate a CSR and private key with SAN support

# Certificate inspection aliases
# ------------------------------

alias ssl-show='() {
  local usage_text="Show certificate summary from PEM, DER, PKCS#7, or PKCS#12.\nUsage:\n ssl-show <cert_source>\nExamples:\n ssl-show ./example.crt\n ssl-show ./bundle.p12"
  local cert_source="$1"

  if _maybe_show_help_ssl_aliases "$1" "$usage_text"; then
    return 0
  fi

  if [ $# -eq 0 ]; then
    _show_usage_ssl_aliases "$usage_text"
    return 1
  fi

  if [ ! -f "$cert_source" ]; then
    _show_error_ssl_aliases "Error: Certificate source not found: $cert_source"
    return 1
  fi

  if ! _ensure_commands_ssl_aliases openssl mktemp rm; then
    return 1
  fi

  _show_cert_summary_ssl_aliases "$cert_source"
}' # Show a concise certificate summary from common certificate formats

alias ssl-probe='() {
  local usage_text="Probe a remote TLS service and show certificate summary.\nUsage:\n ssl-probe <host> [port:443]\nExamples:\n ssl-probe example.com\n ssl-probe example.com 8443"
  local host_value="$1"
  local port_value="${2:-443}"
  local bundle_target=""
  local leaf_target=""
  local verify_line=""
  local command_exit=0

  if _maybe_show_help_ssl_aliases "$1" "$usage_text"; then
    return 0
  fi

  if [ $# -eq 0 ]; then
    _show_usage_ssl_aliases "$usage_text"
    return 1
  fi

  if ! _validate_port_ssl_aliases "$port_value"; then
    return 1
  fi

  if ! _ensure_commands_ssl_aliases openssl mktemp rm awk; then
    return 1
  fi

  bundle_target=$(mktemp 2>/dev/null)
  leaf_target=$(mktemp 2>/dev/null)
  if [ -z "$bundle_target" ] || [ -z "$leaf_target" ]; then
    rm -f "$bundle_target" "$leaf_target"
    _show_error_ssl_aliases "Error: Failed to create temporary files for TLS probe"
    return 1
  fi

  if ! _fetch_remote_leaf_ssl_aliases "$host_value" "$port_value" "$bundle_target" "$leaf_target"; then
    rm -f "$bundle_target" "$leaf_target"
    return 1
  fi

  echo "Remote certificate summary for $host_value:$port_value"
  echo "----------------------------------------"
  _show_cert_summary_from_pem_ssl_aliases "$leaf_target"
  command_exit=$?

  verify_line=$(awk "/Verify return code:/ { line = \$0 } END { if (line != \"\") print line }" "$bundle_target")
  if [ -n "$verify_line" ]; then
    echo "$verify_line"
  fi

  rm -f "$bundle_target" "$leaf_target"
  return "$command_exit"
}' # Show subject, issuer, dates, SANs, and verify code for a remote TLS service

alias ssl-exp='() {
  local usage_text="Show remote certificate expiration and remaining days.\nUsage:\n ssl-exp <host> [port:443]\nExamples:\n ssl-exp example.com\n ssl-exp example.com 8443"
  local host_value="$1"
  local port_value="${2:-443}"
  local bundle_target=""
  local leaf_target=""
  local expiry_line=""
  local expiry_date=""
  local days_left=""

  if _maybe_show_help_ssl_aliases "$1" "$usage_text"; then
    return 0
  fi

  if [ $# -eq 0 ]; then
    _show_usage_ssl_aliases "$usage_text"
    return 1
  fi

  if ! _validate_port_ssl_aliases "$port_value"; then
    return 1
  fi

  if ! _ensure_commands_ssl_aliases openssl mktemp rm; then
    return 1
  fi

  bundle_target=$(mktemp 2>/dev/null)
  leaf_target=$(mktemp 2>/dev/null)
  if [ -z "$bundle_target" ] || [ -z "$leaf_target" ]; then
    rm -f "$bundle_target" "$leaf_target"
    _show_error_ssl_aliases "Error: Failed to create temporary files for expiry check"
    return 1
  fi

  if ! _fetch_remote_leaf_ssl_aliases "$host_value" "$port_value" "$bundle_target" "$leaf_target"; then
    rm -f "$bundle_target" "$leaf_target"
    return 1
  fi

  expiry_line=$(openssl x509 -in "$leaf_target" -noout -enddate 2>/dev/null)
  rm -f "$bundle_target" "$leaf_target"

  if [ -z "$expiry_line" ]; then
    _show_error_ssl_aliases "Error: Failed to read remote certificate expiry for $host_value:$port_value"
    return 1
  fi

  expiry_date="${expiry_line#*=}"
  echo "Expires: $expiry_date"

  days_left="$(_remaining_days_ssl_aliases "$expiry_date")"
  if [ -n "$days_left" ]; then
    echo "Days Left: $days_left"
    if [ "$days_left" -lt 0 ]; then
      _show_error_ssl_aliases "Warning: The certificate is already expired."
    elif [ "$days_left" -lt 30 ]; then
      _show_error_ssl_aliases "Warning: The certificate will expire in less than 30 days."
    fi
  fi
}' # Show remote certificate expiration time and remaining days

alias ssl-fetch='() {
  local usage_text="Fetch the leaf certificate from a remote TLS service.\nUsage:\n ssl-fetch <host> [port:443] [output_target:./host-port.pem]\nExamples:\n ssl-fetch example.com\n ssl-fetch example.com 8443 ./example.pem"
  local host_value="$1"
  local port_value="${2:-443}"
  local default_name=""
  local output_target="${3:-}"
  local bundle_target=""
  local leaf_target=""

  if _maybe_show_help_ssl_aliases "$1" "$usage_text"; then
    return 0
  fi

  if [ $# -eq 0 ]; then
    _show_usage_ssl_aliases "$usage_text"
    return 1
  fi

  if ! _validate_port_ssl_aliases "$port_value"; then
    return 1
  fi

  if ! _ensure_commands_ssl_aliases openssl mktemp rm cp; then
    return 1
  fi

  if [ -z "$output_target" ]; then
    default_name="$(_sanitize_name_ssl_aliases "$host_value-$port_value")"
    output_target="./$default_name.pem"
  fi

  if ! _ensure_parent_root_ssl_aliases "$output_target"; then
    return 1
  fi

  bundle_target=$(mktemp 2>/dev/null)
  leaf_target=$(mktemp 2>/dev/null)
  if [ -z "$bundle_target" ] || [ -z "$leaf_target" ]; then
    rm -f "$bundle_target" "$leaf_target"
    _show_error_ssl_aliases "Error: Failed to create temporary files for certificate fetch"
    return 1
  fi

  if ! _fetch_remote_leaf_ssl_aliases "$host_value" "$port_value" "$bundle_target" "$leaf_target"; then
    rm -f "$bundle_target" "$leaf_target"
    return 1
  fi

  if ! cp "$leaf_target" "$output_target"; then
    rm -f "$bundle_target" "$leaf_target"
    _show_error_ssl_aliases "Error: Failed to write certificate to $output_target"
    return 1
  fi

  rm -f "$bundle_target" "$leaf_target"
  echo "Success: Saved certificate to $output_target"
}' # Fetch the leaf certificate from a remote TLS endpoint

alias ssl-chain='() {
  local usage_text="Fetch and split the remote certificate chain into numbered PEM files.\nUsage:\n ssl-chain <host> [port:443] [output_root:./ssl-chain-host-port]\nExamples:\n ssl-chain example.com\n ssl-chain example.com 443 ./ssl-chain"
  local host_value="$1"
  local port_value="${2:-443}"
  local output_root="${3:-}"
  local default_name=""
  local bundle_target=""
  local split_count=""

  if _maybe_show_help_ssl_aliases "$1" "$usage_text"; then
    return 0
  fi

  if [ $# -eq 0 ]; then
    _show_usage_ssl_aliases "$usage_text"
    return 1
  fi

  if ! _validate_port_ssl_aliases "$port_value"; then
    return 1
  fi

  if ! _ensure_commands_ssl_aliases openssl mktemp rm mkdir cp cat; then
    return 1
  fi

  if [ -z "$output_root" ]; then
    default_name="$(_sanitize_name_ssl_aliases "$host_value-$port_value")"
    output_root="./ssl-chain-$default_name"
  fi

  if ! mkdir -p "$output_root"; then
    _show_error_ssl_aliases "Error: Failed to create output directory: $output_root"
    return 1
  fi

  bundle_target=$(mktemp 2>/dev/null)
  if [ -z "$bundle_target" ]; then
    _show_error_ssl_aliases "Error: Failed to create temporary file for certificate chain"
    return 1
  fi

  if ! _fetch_sclient_output_ssl_aliases "$host_value" "$port_value" "$bundle_target"; then
    rm -f "$bundle_target"
    return 1
  fi

  split_count="$(_split_chain_ssl_aliases "$bundle_target" "$output_root" "cert")"
  rm -f "$bundle_target"
  if [ $? -ne 0 ] || [ -z "$split_count" ]; then
    return 1
  fi

  if ! cp "$output_root/cert-01.pem" "$output_root/leaf.pem"; then
    _show_error_ssl_aliases "Error: Failed to create leaf.pem inside $output_root"
    return 1
  fi

  if ! cat "$output_root"/cert-*.pem >"$output_root/fullchain.pem"; then
    _show_error_ssl_aliases "Error: Failed to create fullchain.pem inside $output_root"
    return 1
  fi

  echo "Success: Saved $split_count certificates into $output_root"
  echo "Leaf: $output_root/leaf.pem"
  echo "Full Chain: $output_root/fullchain.pem"
}' # Fetch and split the full remote certificate chain

alias ssl-key-match='() {
  local usage_text="Verify that a certificate matches a private key.\nUsage:\n ssl-key-match <cert_source> <key_source>\nExamples:\n ssl-key-match ./example.crt ./example.key"
  local cert_source="$1"
  local key_source="$2"
  local cert_digest=""
  local key_digest=""

  if _maybe_show_help_ssl_aliases "$1" "$usage_text"; then
    return 0
  fi

  if [ $# -lt 2 ]; then
    _show_usage_ssl_aliases "$usage_text"
    return 1
  fi

  if [ ! -f "$cert_source" ]; then
    _show_error_ssl_aliases "Error: Certificate source not found: $cert_source"
    return 1
  fi

  if [ ! -f "$key_source" ]; then
    _show_error_ssl_aliases "Error: Private key not found: $key_source"
    return 1
  fi

  if ! _ensure_commands_ssl_aliases openssl awk; then
    return 1
  fi

  cert_digest="$(_cert_pubkey_sha_ssl_aliases "$cert_source")" || return 1
  key_digest="$(_key_pubkey_sha_ssl_aliases "$key_source")" || return 1

  echo "Certificate Public Key SHA256: $cert_digest"
  echo "Private Key Public SHA256:    $key_digest"

  if [ "$cert_digest" = "$key_digest" ]; then
    echo "Match: yes"
    return 0
  fi

  _show_error_ssl_aliases "Match: no"
  return 1
}' # Check whether a certificate and private key belong together

# Certificate packaging aliases
# -----------------------------

alias ssl-convert='() {
  local usage_text="Convert certificate formats and export PKCS#12 bundles.\nUsage:\n ssl-convert <input_source> <output_format:pem|der|p12|pfx> <output_target> [key_source] [ca_source]\nExamples:\n ssl-convert ./example.crt der ./example.der\n ssl-convert ./example.crt p12 ./example.p12 ./example.key ./chain.pem"
  local input_source="$1"
  local format_name="$2"
  local output_target="$3"
  local key_source="$4"
  local ca_source="$5"

  if _maybe_show_help_ssl_aliases "$1" "$usage_text"; then
    return 0
  fi

  if [ $# -lt 3 ]; then
    _show_usage_ssl_aliases "$usage_text"
    return 1
  fi

  if [ ! -f "$input_source" ]; then
    _show_error_ssl_aliases "Error: Input certificate not found: $input_source"
    return 1
  fi

  if ! _ensure_commands_ssl_aliases openssl mktemp rm; then
    return 1
  fi

  _convert_cert_ssl_aliases "$input_source" "$format_name" "$output_target" "$key_source" "$ca_source"
}' # Convert between PEM, DER, and PKCS#12 certificate bundles

alias ssl-p12='() {
  local usage_text="Pack certificate and key into a PKCS#12 bundle.\nUsage:\n ssl-p12 <cert_source> <key_source> [output_target:./name.p12] [ca_source]\nExamples:\n ssl-p12 ./example.crt ./example.key\n ssl-p12 ./example.crt ./example.key ./example.p12 ./chain.pem"
  local cert_source="$1"
  local key_source="$2"
  local output_target="${3:-}"
  local ca_source="$4"
  local base_name=""

  if _maybe_show_help_ssl_aliases "$1" "$usage_text"; then
    return 0
  fi

  if [ $# -lt 2 ]; then
    _show_usage_ssl_aliases "$usage_text"
    return 1
  fi

  if [ ! -f "$cert_source" ]; then
    _show_error_ssl_aliases "Error: Certificate source not found: $cert_source"
    return 1
  fi

  if [ ! -f "$key_source" ]; then
    _show_error_ssl_aliases "Error: Private key not found: $key_source"
    return 1
  fi

  if [ -z "$output_target" ]; then
    base_name="${cert_source##*/}"
    base_name="${base_name%.*}"
    output_target="./$base_name.p12"
  fi

  if ! _ensure_commands_ssl_aliases openssl mktemp rm; then
    return 1
  fi

  _convert_cert_ssl_aliases "$cert_source" "p12" "$output_target" "$key_source" "$ca_source"
}' # Create a PKCS#12 bundle from a certificate and private key

# Help and compatibility aliases
# ------------------------------

alias ssl-help='() {
  echo "SSL Alias Toolkit"
  echo "================="
  echo "Canonical commands:"
  echo "  ssl-acme-install  Install acme.sh with user-scoped defaults"
  echo "  ssl-acme          Run the installed acme.sh client"
  echo "  ssl-self          Generate a self-signed certificate with SANs"
  echo "  ssl-csr           Generate a CSR and private key with SANs"
  echo "  ssl-show          Show certificate summary from local files"
  echo "  ssl-probe         Probe a remote TLS endpoint and show summary"
  echo "  ssl-exp           Show remote certificate expiration"
  echo "  ssl-fetch         Fetch the remote leaf certificate"
  echo "  ssl-chain         Fetch and split the remote certificate chain"
  echo "  ssl-key-match     Verify that a certificate matches a private key"
  echo "  ssl-convert       Convert PEM, DER, and PKCS#12 formats"
  echo "  ssl-p12           Pack certificate and key into PKCS#12"
  echo ""
  echo "Compatibility aliases:"
  echo "  install-acmesh    -> ssl-acme-install"
  echo "  acme.sh           -> ssl-acme"
  echo "  ssl-self-signed   -> ssl-self"
  echo "  ssl-info          -> ssl-show"
  echo "  ssl-check         -> ssl-probe"
  echo "  ssl-expires       -> ssl-exp"
  echo "  ssl-extract       -> ssl-fetch"
}' # Show the SSL toolkit command index and compatibility aliases

alias install-acmesh='() {
  ssl-acme-install "$@"
}' # Backward-compatible alias for ssl-acme-install

alias acme.sh='() {
  _run_acme_ssl_aliases "$@"
}' # Backward-compatible alias for ssl-acme

alias ssl-self-signed='() {
  ssl-self "$@"
}' # Backward-compatible alias for ssl-self

alias ssl-info='() {
  ssl-show "$@"
}' # Backward-compatible alias for ssl-show

alias ssl-check='() {
  ssl-probe "$@"
}' # Backward-compatible alias for ssl-probe

alias ssl-expires='() {
  ssl-exp "$@"
}' # Backward-compatible alias for ssl-exp

alias ssl-extract='() {
  ssl-fetch "$@"
}' # Backward-compatible alias for ssl-fetch
