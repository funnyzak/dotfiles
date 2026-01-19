# Description: Calculation related aliases for common math operations and conversions.

# Basic Calculation Functions
### --- ###

alias calc-basic='() {
  echo "Basic calculator with support for standard math operations."
  echo "Usage:"
  echo " calc-basic <expression>"
  echo "Examples:"
  echo " calc-basic \"2 + 2\""
  echo " calc-basic \"(5 * 7) / 2\""

  if [ -z "$1" ]; then
    echo "Error: Missing expression parameter." >&2
    return 1
  fi

  # Use bc for calculation
  result=$(echo "$1" | bc -l)
  if [ $? -ne 0 ]; then
    echo "Error: Invalid expression or bc command failed." >&2
    return 1
  fi

  # Remove trailing zeros for better readability
  echo "$result" | sed "/\./ s/\.\{0,1\}0\{1,\}$//"
}' # Basic calculator for mathematical expressions

# Base Conversion Functions
### --- ###

alias calc-hex='() {
  echo "Convert decimal number to hexadecimal."
  echo "Usage:"
  echo " calc-hex <decimal_number>"
  echo "Examples:"
  echo " calc-hex 255  # Output: 0xFF"
  echo " calc-hex 16   # Output: 0x10"

  if [ -z "$1" ]; then
    echo "Error: Missing decimal number parameter." >&2
    return 1
  fi

  # Validate input is a number
  if ! echo "$1" | grep -q "^[0-9]\+$"; then
    echo "Error: Input must be a decimal number." >&2
    return 1
  fi

  printf "0x%X\n" "$1"
}' # Convert decimal to hexadecimal

alias calc-bin='() {
  echo "Convert decimal number to binary."
  echo "Usage:"
  echo " calc-bin <decimal_number>"

  if [ -z "$1" ]; then
    echo "Error: Missing decimal number parameter." >&2
    return 1
  fi

  # Validate input is a number
  if ! echo "$1" | grep -q "^[0-9]\+$"; then
    echo "Error: Input must be a decimal number." >&2
    return 1
  fi

  echo "obase=2; $1" | bc
}' # Convert decimal to binary

alias calc-oct='() {
  echo "Convert decimal number to octal."
  echo "Usage:"
  echo " calc-oct <decimal_number>"

  if [ -z "$1" ]; then
    echo "Error: Missing decimal number parameter." >&2
    return 1
  fi

  # Validate input is a number
  if ! echo "$1" | grep -q "^[0-9]\+$"; then
    echo "Error: Input must be a decimal number." >&2
    return 1
  fi

  printf "0%o\n" "$1"
}' # Convert decimal to octal

alias calc-from-hex='() {
  echo "Convert hexadecimal number to decimal."
  echo "Usage:"
  echo " calc-from-hex <hex_number>"

  if [ -z "$1" ]; then
    echo "Error: Missing hexadecimal number parameter." >&2
    return 1
  fi

  # Remove 0x prefix if present
  hex_value=${1#0x}

  # Validate input is a hexadecimal number
  if ! echo "$hex_value" | grep -q "^[0-9A-Fa-f]\+$"; then
    echo "Error: Input must be a valid hexadecimal number." >&2
    return 1
  fi
  hex_value=$(echo "$hex_value" | tr "[:lower:]" "[:upper:]")
  echo "ibase=16; $hex_value" | bc
}' # Convert hexadecimal to decimal

alias calc-from-bin='() {
  echo "Convert binary number to decimal."
  echo "Usage:"
  echo " calc-from-bin <binary_number>"

  if [ -z "$1" ]; then
    echo "Error: Missing binary number parameter." >&2
    return 1
  fi

  # Remove 0b prefix if present
  bin_value=${1#0b}

  # Validate input is a binary number
  if ! echo "$bin_value" | grep -q "^[01]\+$"; then
    echo "Error: Input must be a valid binary number." >&2
    return 1
  fi

  echo "ibase=2; $bin_value" | bc
}' # Convert binary to decimal

alias calc-from-oct='() {
  echo "Convert octal number to decimal."
  echo "Usage:"
  echo " calc-from-oct <octal_number>"

  if [ -z "$1" ]; then
    echo "Error: Missing octal number parameter." >&2
    return 1
  fi

  # Remove 0 prefix if present
  oct_value=${1#0}

  # Validate input is an octal number
  if ! echo "$oct_value" | grep -q "^[0-7]\+$"; then
    echo "Error: Input must be a valid octal number." >&2
    return 1
  fi

  echo "ibase=8; $oct_value" | bc
}' # Convert octal to decimal

# Base Conversion Utilities
### --- ###

alias calc-base-convert='() {
  echo "Convert number between arbitrary bases (2-36)."
  echo "Usage:"
  echo " calc-base-convert <number> <from_base> <to_base>"
  echo "Examples:"
  echo " calc-base-convert 255 10 16  # Decimal to hex"
  echo " calc-base-convert FF 16 2    # Hex to binary"

  if [ $# -ne 3 ]; then
    echo "Error: Requires exactly 3 parameters: number, from_base, and to_base." >&2
    return 1
  fi

  local number="$1"
  local from_base="$2"
  local to_base="$3"

  # Validate bases are within range
  if ! echo "$from_base" | grep -q "^[0-9]\+$" || [ "$from_base" -lt 2 ] || [ "$from_base" -gt 36 ]; then
    echo "Error: Source base must be a number between 2 and 36." >&2
    return 1
  fi

  if ! echo "$to_base" | grep -q "^[0-9]\+$" || [ "$to_base" -lt 2 ] || [ "$to_base" -gt 36 ]; then
    echo "Error: Target base must be a number between 2 and 36." >&2
    return 1
  fi

  # Validate the number is valid in the source base
  local valid_chars=$(printf "%s\n" {0..9} {A..Z} | head -n "$from_base" | tr -d "\n")
  if ! echo "${number^^}" | grep -q "^[$valid_chars]\+$"; then
    echo "Error: Input number contains digits invalid for base $from_base." >&2
    return 1
  fi

  # Use bc for conversion
  result=$(echo "obase=$to_base; ibase=$from_base; ${number^^}" | bc 2>/dev/null)

  if [ $? -ne 0 ] || [ -z "$result" ]; then
    echo "Error: Conversion failed. Verify your inputs." >&2
    return 1
  fi

  echo "$result"
}' # Convert between arbitrary number bases

# Scientific and Advanced Calculations
### --- ###

alias calc-scientific='() {
  echo "Scientific calculator with support for advanced math functions."
  echo "Usage:"
  echo " calc-scientific <expression>"
  echo "Examples:"
  echo " calc-scientific \"sqrt(16)\""
  echo " calc-scientific \"s(3.14159/2)\" # sine"
  echo " calc-scientific \"c(0)\"          # cosine"
  echo " calc-scientific \"l(10)\"         # natural log"

  if [ -z "$1" ]; then
    echo "Error: Missing expression parameter." >&2
    return 1
  fi

  # Use bc with math library for calculation
  result=$(echo "$1" | bc -l 2>/dev/null)

  if [ $? -ne 0 ]; then
    echo "Error: Invalid expression or bc command failed." >&2
    echo "Available functions: sqrt(x), s(x), c(x), a(x), l(x), e(x)" >&2
    return 1
  fi

  # Format result to remove trailing zeros
  printf "%.10g\n" "$result"
}' # Scientific calculator with math functions

alias calc-percentage='() {
  echo "Calculate percentage value or change."
  echo "Usage:"
  echo " calc-percentage <value> <total>          # Calculate what percentage value is of total"
  echo " calc-percentage <value> <percentage> %    # Calculate percentage of a value"
  echo " calc-percentage <old> <new> change       # Calculate percentage change"

  if [ $# -lt 2 ]; then
    echo "Error: Insufficient parameters." >&2
    return 1
  fi

  # Validate parameters are numbers
  if ! echo "$1" | grep -q "^[0-9.]\+$" || ! echo "$2" | grep -q "^[0-9.]\+$"; then
    echo "Error: Parameters must be numeric values." >&2
    return 1
  fi

  if [ $# -eq 2 ]; then
    # Calculate what percentage value is of total
    local value="$1"
    local total="$2"
    local percentage=$(echo "scale=2; ($value / $total) * 100" | bc -l)
    echo "$value is $percentage% of $total"

  elif [ "$3" = "%" ]; then
    # Calculate percentage of a value
    local value="$1"
    local percentage="$2"
    local result=$(echo "scale=2; ($value * $percentage) / 100" | bc -l)
    echo "$percentage% of $value is $result"

  elif [ "$3" = "change" ]; then
    # Calculate percentage change
    local old="$1"
    local new="$2"
    local change=$(echo "scale=2; (($new - $old) / $old) * 100" | bc -l)
    echo "Change from $old to $new is $change%"

  else
    echo "Error: Invalid format. Use one of the formats shown in usage." >&2
    return 1
  fi
}' # Calculate percentages and percentage changes

# Unit Conversion
### --- ###

alias calc-temperature='() {
  echo "Convert between temperature units (Celsius, Fahrenheit, Kelvin)."
  echo "Usage:"
  echo " calc-temperature <value> <from_unit> <to_unit>"
  echo "Supported units: C (Celsius), F (Fahrenheit), K (Kelvin)"
  echo "Examples:"
  echo " calc-temperature 32 F C  # Convert 32°F to Celsius"
  echo " calc-temperature 100 C K # Convert 100°C to Kelvin"

  if [ $# -ne 3 ]; then
    echo "Error: Requires exactly 3 parameters: value, from_unit, and to_unit." >&2
    return 1
  fi

  local value="$1"
  local from="${2^^}"
  local to="${3^^}"

  # Validate temperature value
  if ! echo "$value" | grep -q "^-\{0,1\}[0-9.]\+$"; then
    echo "Error: Value must be a number." >&2
    return 1
  fi

  # Validate units
  if ! echo "$from" | grep -q "^[CFK]$" || ! echo "$to" | grep -q "^[CFK]$"; then
    echo "Error: Units must be C (Celsius), F (Fahrenheit), or K (Kelvin)." >&2
    return 1
  fi

  local result

  # Convert to Celsius first
  case "$from" in
    C) celsius="$value" ;;
    F) celsius=$(echo "scale=2; ($value - 32) * 5/9" | bc -l) ;;
    K) celsius=$(echo "scale=2; $value - 273.15" | bc -l) ;;
  esac

  # Convert from Celsius to target unit
  case "$to" in
    C) result="$celsius" ;;
    F) result=$(echo "scale=2; ($celsius * 9/5) + 32" | bc -l) ;;
    K) result=$(echo "scale=2; $celsius + 273.15" | bc -l) ;;
  esac

  # Output result with appropriate unit symbol
  case "$to" in
    C) echo "$result°C" ;;
    F) echo "$result°F" ;;
    K) echo "$result K" ;;
  esac
}' # Convert between temperature units

# Help function
### --- ###

alias calc-help='() {
  echo "Calculator Aliases Help"
  echo "======================="
  echo ""
  echo "Basic Calculations:"
  echo "  calc-basic <expression>              - Basic calculator for math expressions"
  echo ""
  echo "Base Conversions:"
  echo "  calc-hex <decimal>                   - Convert decimal to hexadecimal"
  echo "  calc-bin <decimal>                   - Convert decimal to binary"
  echo "  calc-oct <decimal>                   - Convert decimal to octal"
  echo "  calc-from-hex <hex>                  - Convert hexadecimal to decimal"
  echo "  calc-from-bin <binary>               - Convert binary to decimal"
  echo "  calc-from-oct <octal>                - Convert octal to decimal"
  echo "  calc-base-convert <num> <from> <to>  - Convert between arbitrary bases (2-36)"
  echo ""
  echo "Advanced Calculations:"
  echo "  calc-scientific <expression>         - Scientific calculator with advanced functions"
  echo "  calc-percentage <args...>            - Calculate percentages in various formats"
  echo ""
  echo "Unit Conversions:"
  echo "  calc-temperature <val> <from> <to>   - Convert between temperature units (C/F/K)"
  echo ""
  echo "For more details on any command, run it without parameters to see usage information."
}' # Display help information for all calculator aliases
