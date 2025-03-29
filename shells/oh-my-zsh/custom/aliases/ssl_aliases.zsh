# Description: SSL certificate management and tools related aliases

# Install and manage acme.sh SSL tool
# ------------------------------

# Helper functions for SSL operations
# Check if command is available
_check_command_ssl_aliases() {
  command -v "$1" &> /dev/null
  return $?
}

# Check if running as root
_check_root_ssl_aliases() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "This operation requires root privileges" >&2
    return 1
  fi
  return 0
} # Check if running as root

# Install acme.sh SSL certificate tool
alias install-acmesh='() {
  echo -e "Install acme.sh SSL certificate tool.\nUsage:\n install-acmesh [email:acmesh@gmail.com] [source:github|gitee]"

  # Check for help flag
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    return 0
  fi

  local default_email="acmesh@gmail.com"
  local email="${1:-$default_email}"
  local source="${2:-github}"
  local repo_url

  # Set repository URL based on source
  case "$source" in
    github)
      repo_url="https://github.com/acmesh-official/acme.sh.git"
      ;;
    gitee)
      repo_url="https://gitee.com/neilpang/acme.sh.git"
      ;;
    *)
      echo "Error: Invalid source. Use 'github' or 'gitee'" >&2
      return 1
      ;;
  esac

  # Check for git
  if ! _check_command_ssl_aliases "git"; then
    echo "Error: Git is not installed. Please install git first." >&2
    return 1
  fi

  # Check for root privileges
  if ! _check_root_ssl_aliases; then
    return 1
  fi

  # Check if already installed
  if _check_command_ssl_aliases "/root/.acme.sh/acme.sh"; then
    echo "acme.sh is already installed"
    return 0
  fi

  echo "Installing acme.sh with email: $email from $source"

  # Create temporary directory
  local temp_dir
  temp_dir=$(mktemp -d)
  if [ $? -ne 0 ]; then
    echo "Error: Failed to create temporary directory" >&2
    return 1
  fi

  cd "$temp_dir" || { echo "Error: Failed to change directory to $temp_dir" >&2; return 1; }

  if ! git clone "$repo_url"; then
    echo "Error: Failed to clone acme.sh repository from $source" >&2
    cd - > /dev/null || true
    rm -rf "$temp_dir"
    return 1
  fi

  cd acme.sh || { echo "Error: Failed to change directory to acme.sh" >&2; return 1; }

  if ! ./acme.sh --install -m "$email" --force; then
    echo "Error: Failed to install acme.sh" >&2
    cd - > /dev/null || true
    rm -rf "$temp_dir"
    return 1
  fi

  cd - > /dev/null || true
  rm -rf "$temp_dir"
  echo "Success: acme.sh installed successfully from $source"
  return 0
}' # Install acme.sh SSL certificate tool

# Create alias for acme.sh if installed
alias acme.sh='() {
  if [ -x "/root/.acme.sh/acme.sh" ]; then
    /root/.acme.sh/acme.sh "$@"
  else
    echo "Error: acme.sh is not installed. Run install-acmesh to install it first." >&2
    return 1
  fi
}' # Quick access to acme.sh SSL tool

# SSL certificate generation and management
# ------------------------------

# Generate a self-signed certificate
alias ssl-self-signed='() {
  echo -e "Generate a self-signed SSL certificate.\nUsage:\n ssl-self-signed <domain:localhost> [days:365] [bits:2048] [output_dir:./ssl]"

  # Check for help flag
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    return 0
  fi

  local domain="${1:-localhost}"
  local days="${2:-365}"
  local bits="${3:-2048}"
  local output_dir="${4:-./ssl}"

  # Check for openssl
  if ! _check_command_ssl_aliases "openssl"; then
    echo "Error: OpenSSL is not installed. Please install OpenSSL first." >&2
    return 1
  fi

  # Create output directory if it doesn"t exist
  if [ ! -d "$output_dir" ]; then
    mkdir -p "$output_dir"
    if [ $? -ne 0 ]; then
      echo "Error: Failed to create output directory: $output_dir" >&2
      return 1
    fi
  fi

  # Generate private key
  if ! openssl genrsa -out "$output_dir/$domain.key" "$bits"; then
    echo "Error: Failed to generate private key" >&2
    return 1
  fi

  # Create CSR configuration
  local config_file="$output_dir/$domain.cnf"
  cat > "$config_file" << EOF
[req]
default_bits = $bits
prompt = no
default_md = sha256
distinguished_name = dn
x509_extensions = v3_req

[dn]
C = CN
ST = State
L = City
O = Organization
OU = Unit
CN = $domain

[v3_req]
subjectAltName = @alt_names
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment

[alt_names]
DNS.1 = $domain
DNS.2 = www.$domain
EOF

  # Generate self-signed certificate
  if ! openssl req -new -x509 -sha256 -key "$output_dir/$domain.key" -out "$output_dir/$domain.crt" -days "$days" -config "$config_file"; then
    echo "Error: Failed to generate self-signed certificate" >&2
    return 1
  fi

  echo "Success: Generated self-signed certificate for $domain"
  echo "Key: $output_dir/$domain.key"
  echo "Certificate: $output_dir/$domain.crt"
  echo "Config: $output_dir/$domain.cnf"
  return 0
}'

# View certificate information
alias ssl-info='() {
  echo -e "View SSL certificate information.\nUsage:\n ssl-info <cert_file>"

  # Check for help flag
  if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ -z "$1" ]; then
    return 0
  fi

  local cert_file="$1"

  # Check if file exists
  if [ ! -f "$cert_file" ]; then
    echo "Error: Certificate file not found: $cert_file" >&2
    return 1
  fi

  # Check for openssl
  if ! _check_command_ssl_aliases "openssl"; then
    echo "Error: OpenSSL is not installed. Please install OpenSSL first." >&2
    return 1
  fi

  # Determine certificate format
  local cert_type
  if grep -q "BEGIN CERTIFICATE" "$cert_file"; then
    cert_type="x509"
  elif grep -q "BEGIN TRUSTED CERTIFICATE" "$cert_file"; then
    cert_type="x509 -trustout"
  elif grep -q "BEGIN PKCS7" "$cert_file"; then
    cert_type="pkcs7"
  elif grep -q "BEGIN PKCS12" "$cert_file"; then
    cert_type="pkcs12"
  else
    echo "Error: Unknown certificate format" >&2
    return 1
  fi

  # View certificate information
  if [ "$cert_type" = "pkcs12" ]; then
    echo "PKCS#12 certificate detected. Displaying information..."
    openssl pkcs12 -info -in "$cert_file" -nokeys
  else
    openssl "$cert_type" -text -noout -in "$cert_file"
  fi

  return $?
}'

# Check SSL/TLS connection to a server
alias ssl-check='() {
  echo -e "Check SSL/TLS connection to a server.\nUsage:\n ssl-check <domain:example.com> [port:443]"

  # Check for help flag
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    return 0
  fi

  local domain="${1:-example.com}"
  local port="${2:-443}"

  # Check for openssl
  if ! _check_command_ssl_aliases "openssl"; then
    echo "Error: OpenSSL is not installed. Please install OpenSSL first." >&2
    return 1
  fi

  echo "Checking SSL connection to $domain:$port..."
  if ! openssl s_client -connect "$domain:$port" -servername "$domain" </dev/null 2>/dev/null | openssl x509 -noout -dates -subject -issuer; then
    echo "Error: Failed to connect to $domain:$port" >&2
    return 1
  fi

  return 0
}'

# Check certificate expiration
alias ssl-expires='() {
  echo -e "Check SSL certificate expiration.\nUsage:\n ssl-expires <domain:example.com> [port:443]"

  # Check for help flag
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    return 0
  fi

  local domain="${1:-example.com}"
  local port="${2:-443}"

  # Check for openssl
  if ! _check_command_ssl_aliases "openssl"; then
    echo "Error: OpenSSL is not installed. Please install OpenSSL first." >&2
    return 1
  fi

  echo "Checking certificate expiration for $domain:$port..."
  local expiry_date
  expiry_date=$(openssl s_client -connect "$domain:$port" -servername "$domain" </dev/null 2>/dev/null | openssl x509 -noout -enddate | cut -d= -f2)

  if [ -z "$expiry_date" ]; then
    echo "Error: Failed to get certificate expiration date" >&2
    return 1
  fi

  local expiry_seconds
  if command -v date &>/dev/null; then
    # Use date command (available on most systems)
    if date --version 2>&1 | grep -q "GNU"; then
      # GNU date (Linux)
      expiry_seconds=$(date -d "$expiry_date" +%s 2>/dev/null)
    else
      # BSD date (macOS)
      expiry_seconds=$(date -j -f "%b %d %H:%M:%S %Y %Z" "$expiry_date" +%s 2>/dev/null)
    fi
  fi

  if [ -n "$expiry_seconds" ]; then
    local now_seconds
    now_seconds=$(date +%s)
    local days_left
    days_left=$(( (expiry_seconds - now_seconds) / 86400 ))

    echo "Certificate for $domain expires on: $expiry_date"
    echo "Days left: $days_left"

    if [ "$days_left" -lt 30 ]; then
      echo "Warning: Certificate will expire in less than 30 days!" >&2
    fi
  else
    # Fallback if date conversion fails
    echo "Certificate for $domain expires on: $expiry_date"
  fi

  return 0
}'

# Convert certificate formats
alias ssl-convert='() {
  echo -e "Convert SSL certificate between formats.\nUsage:\n ssl-convert <input_file> <output_format:pem|der|p12|pfx> <output_file> [key_file] [ca_file]"

  # Check for help flag
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    return 0
  fi

  # Check required arguments
  if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Error: Missing required arguments" >&2
    return 1
  fi

  local input_file="$1"
  local output_format="$2"
  local output_file="$3"
  local key_file="$4"
  local ca_file="$5"

  # Check if input file exists
  if [ ! -f "$input_file" ]; then
    echo "Error: Input file not found: $input_file" >&2
    return 1
  fi

  # Check for openssl
  if ! _check_command_ssl_aliases "openssl"; then
    echo "Error: OpenSSL is not installed. Please install OpenSSL first." >&2
    return 1
  fi

  # Convert certificate based on output format
  case "$output_format" in
    pem)
      if grep -q "BEGIN CERTIFICATE" "$input_file"; then
        # Already in PEM format
        cp "$input_file" "$output_file"
      else
        # Convert DER to PEM
        openssl x509 -inform der -in "$input_file" -out "$output_file"
      fi
      ;;
    der)
      openssl x509 -outform der -in "$input_file" -out "$output_file"
      ;;
    p12|pfx)
      if [ -z "$key_file" ]; then
        echo "Error: Key file is required for P12/PFX conversion" >&2
        return 1
      fi
      if [ ! -f "$key_file" ]; then
        echo "Error: Key file not found: $key_file" >&2
        return 1
      fi

      local ca_arg=""
      if [ -n "$ca_file" ] && [ -f "$ca_file" ]; then
        ca_arg="-certfile $ca_file"
      fi

      # Create PKCS#12 file
      openssl pkcs12 -export -out "$output_file" -inkey "$key_file" -in "$input_file" $ca_arg
      ;;
    *)
      echo "Error: Unsupported output format: $output_format" >&2
      echo "Supported formats: pem, der, p12, pfx" >&2
      return 1
      ;;
  esac

  if [ $? -ne 0 ]; then
    echo "Error: Failed to convert certificate" >&2
    return 1
  fi

  echo "Success: Converted certificate to $output_format format: $output_file"
  return 0
}'

# Extract certificates from domain
alias ssl-extract='() {
  echo -e "Extract SSL certificates from a domain.\nUsage:\n ssl-extract <domain:example.com> [port:443] [output_file:./domain.pem]"

  # Check for help flag
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    return 0
  fi

  local domain="${1:-example.com}"
  local port="${2:-443}"
  local output_file="${3:-./$(echo "$domain" | tr -d ":")_cert.pem}"

  # Check for openssl
  if ! _check_command_ssl_aliases "openssl"; then
    echo "Error: OpenSSL is not installed. Please install OpenSSL first." >&2
    return 1
  fi

  echo "Extracting certificate from $domain:$port to $output_file..."
  if ! openssl s_client -connect "$domain:$port" -servername "$domain" </dev/null 2>/dev/null | openssl x509 -outform PEM > "$output_file"; then
    echo "Error: Failed to extract certificate from $domain:$port" >&2
    return 1
  fi

  echo "Success: Certificate saved to $output_file"
  return 0
}'

# Generate certificate signing request (CSR)
alias ssl-csr='() {
  echo -e "Generate a Certificate Signing Request (CSR).\nUsage:\n ssl-csr <domain:example.com> [bits:2048] [output_dir:./ssl]"

  # Check for help flag
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    return 0
  fi

  local domain="${1:-example.com}"
  local bits="${2:-2048}"
  local output_dir="${3:-./ssl}"

  # Check for openssl
  if ! _check_command_ssl_aliases "openssl"; then
    echo "Error: OpenSSL is not installed. Please install OpenSSL first." >&2
    return 1
  fi

  # Create output directory if it doesn"t exist
  if [ ! -d "$output_dir" ]; then
    mkdir -p "$output_dir"
    if [ $? -ne 0 ]; then
      echo "Error: Failed to create output directory: $output_dir" >&2
      return 1
    fi
  fi

  # Generate private key
  if ! openssl genrsa -out "$output_dir/$domain.key" "$bits"; then
    echo "Error: Failed to generate private key" >&2
    return 1
  fi

  # Create CSR configuration
  local config_file="$output_dir/$domain.cnf"
  cat > "$config_file" << EOF
[req]
default_bits = $bits
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = req_ext

[dn]
C = CN
ST = State
L = City
O = Organization
OU = Unit
CN = $domain

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = $domain
DNS.2 = www.$domain
EOF

  # Generate CSR
  if ! openssl req -new -key "$output_dir/$domain.key" -out "$output_dir/$domain.csr" -config "$config_file"; then
    echo "Error: Failed to generate CSR" >&2
    return 1
  fi

  # Verify CSR
  echo "Verifying CSR..."
  openssl req -text -noout -in "$output_dir/$domain.csr"

  echo "Success: Generated CSR for $domain"
  echo "Key: $output_dir/$domain.key"
  echo "CSR: $output_dir/$domain.csr"
  echo "Config: $output_dir/$domain.cnf"
  return 0
}'
