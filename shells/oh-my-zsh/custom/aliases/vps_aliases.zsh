# Description: Aliases for Linux VPS benchmarking, auditing and quick diagnostics.

# Helper functions
# -----------------------------

_show_error_vps_aliases() {
  echo "Error: $1" >&2
  return 1
}

_show_usage_vps_aliases() {
  echo -e "$1"
  return 0
}

_require_command_vps_aliases() {
  if ! command -v "$1" >/dev/null 2>&1; then
    _show_error_vps_aliases "Required command not found: $1"
    return 1
  fi

  return 0
}

_require_linux_vps_aliases() {
  local alias_name="$1"

  if [ "$(uname -s)" != "Linux" ]; then
    _show_error_vps_aliases "$alias_name is intended for Linux VPS hosts."
    return 1
  fi

  return 0
}

_expand_home_vps_aliases() {
  local raw_value="$1"

  case "$raw_value" in
    "~")
      printf "%s\n" "$HOME"
      ;;
    "~/"*)
      printf "%s/%s\n" "$HOME" "${raw_value#"~/"}"
      ;;
    *)
      printf "%s\n" "$raw_value"
      ;;
  esac
}

_default_log_vps_aliases() {
  local tool_key="$1"
  printf "%s\n" "$HOME/vps-${tool_key}-$(date +%Y%m%d-%H%M%S).log"
}

_prepare_output_vps_aliases() {
  local output_target="$1"
  local store_root=""

  if [ -z "$output_target" ]; then
    return 0
  fi

  output_target="$(_expand_home_vps_aliases "$output_target")"
  store_root="$(dirname "$output_target")"

  if [ ! -d "$store_root" ]; then
    if ! mkdir -p "$store_root"; then
      _show_error_vps_aliases "Failed to create output directory: $store_root"
      return 1
    fi
  fi

  printf "%s\n" "$output_target"
}

_fetch_remote_script_vps_aliases() {
  local download_target="$1"
  local source_url=""

  shift

  if ! _require_command_vps_aliases curl; then
    return 1
  fi

  if [ -z "$download_target" ] || [ $# -eq 0 ]; then
    _show_error_vps_aliases "Remote script downloader received invalid arguments."
    return 1
  fi

  for source_url in "$@"; do
    echo "Trying source: $source_url"

    if curl -fsSL --connect-timeout 10 --max-time 180 "$source_url" -o "$download_target"; then
      if [ -s "$download_target" ]; then
        chmod +x "$download_target" 2>/dev/null
        echo "Downloaded script from: $source_url"
        return 0
      fi
    fi
  done

  rm -f "$download_target"
  _show_error_vps_aliases "Failed to download remote script from all configured sources."
  return 1
}

_run_command_with_output_vps_aliases() {
  local label_name="$1"
  local output_target="$2"
  local exit_code=0

  shift 2

  if [ -n "$output_target" ]; then
    output_target="$(_prepare_output_vps_aliases "$output_target")" || return 1

    (
      set -o pipefail
      "$@" 2>&1 | tee "$output_target"
    )
    exit_code=$?

    if [ $exit_code -eq 0 ]; then
      echo "Saved ${label_name} log to $output_target"
    fi
  else
    "$@"
    exit_code=$?
  fi

  if [ $exit_code -ne 0 ]; then
    _show_error_vps_aliases "${label_name} execution failed."
    return 1
  fi

  return 0
}

_run_nodequality_vps_aliases() {
  local output_target="$1"
  local script_cache=""
  local exit_code=0

  shift

  script_cache="$(mktemp "${TMPDIR:-/tmp}/nodequality.XXXXXX")" || {
    _show_error_vps_aliases "Failed to allocate temporary workspace for NodeQuality."
    return 1
  }

  if ! _fetch_remote_script_vps_aliases \
    "$script_cache" \
    "https://run.NodeQuality.com" \
    "https://raw.githubusercontent.com/LloydAsp/NodeQuality/main/NodeQuality.sh"; then
    rm -f "$script_cache"
    return 1
  fi

  _run_command_with_output_vps_aliases "NodeQuality" "$output_target" bash "$script_cache" "$@"
  exit_code=$?
  rm -f "$script_cache"

  return $exit_code
}

_run_yabs_vps_aliases() {
  local output_target="$1"
  local script_cache=""
  local exit_code=0

  shift

  script_cache="$(mktemp "${TMPDIR:-/tmp}/yabs.XXXXXX")" || {
    _show_error_vps_aliases "Failed to allocate temporary workspace for YABS."
    return 1
  }

  if ! _fetch_remote_script_vps_aliases \
    "$script_cache" \
    "https://yabs.sh" \
    "https://raw.githubusercontent.com/masonr/yet-another-bench-script/master/yabs.sh"; then
    rm -f "$script_cache"
    return 1
  fi

  _run_command_with_output_vps_aliases "YABS" "$output_target" bash "$script_cache" "$@"
  exit_code=$?
  rm -f "$script_cache"

  return $exit_code
}

_run_audit_vps_aliases() {
  local output_target="$1"
  local use_privilege="$2"
  local script_cache=""
  local exit_code=0
  local runner_args=()

  shift 2

  script_cache="$(mktemp "${TMPDIR:-/tmp}/vps-audit.XXXXXX")" || {
    _show_error_vps_aliases "Failed to allocate temporary workspace for vps-audit."
    return 1
  }

  if ! _fetch_remote_script_vps_aliases \
    "$script_cache" \
    "https://raw.githubusercontent.com/vernu/vps-audit/main/vps-audit.sh" \
    "https://cdn.jsdelivr.net/gh/vernu/vps-audit@main/vps-audit.sh"; then
    rm -f "$script_cache"
    return 1
  fi

  if [ "$use_privilege" = "yes" ]; then
    if ! _require_command_vps_aliases sudo; then
      rm -f "$script_cache"
      return 1
    fi

    runner_args=(sudo bash "$script_cache")
  else
    runner_args=(bash "$script_cache")
  fi

  _run_command_with_output_vps_aliases "vps-audit" "$output_target" "${runner_args[@]}" "$@"
  exit_code=$?
  rm -f "$script_cache"

  return $exit_code
}

# VPS benchmarking
# -----------------------------

alias vps-benchmark='() {
  _show_usage_vps_aliases "Run the NodeQuality benchmark on a Linux VPS.\nUsage:\n  vps-benchmark [--output path] [nodequality_args]\nExamples:\n  vps-benchmark\n  vps-benchmark --output ~/bench.log -E\n  vps-benchmark -- -4 -d /root"

  local output_target=""
  local upstream_args=()

  if [ "$1" = "--help" ]; then
    return 0
  fi

  if ! _require_linux_vps_aliases "vps-benchmark"; then
    return 1
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
      -o|--output)
        if [ -z "$2" ]; then
          _show_error_vps_aliases "Missing value for --output."
          return 1
        fi
        output_target="$2"
        shift 2
        ;;
      --help)
        return 0
        ;;
      --)
        shift
        while [ $# -gt 0 ]; do
          upstream_args+=("$1")
          shift
        done
        ;;
      *)
        upstream_args+=("$1")
        shift
        ;;
    esac
  done

  echo "Running NodeQuality benchmark..."
  _run_nodequality_vps_aliases "$output_target" "${upstream_args[@]}"
}' # Run NodeQuality benchmark with optional log capture

alias vps-benchmark-save='() {
  _show_usage_vps_aliases "Run NodeQuality and save the console log.\nUsage:\n  vps-benchmark-save [output_path:$HOME/vps-nodequality-<timestamp>.log] [nodequality_args]\nExamples:\n  vps-benchmark-save\n  vps-benchmark-save ~/nodequality.log -E\n  vps-benchmark-save -4"

  local output_target=""

  if [ "$1" = "--help" ]; then
    return 0
  fi

  if ! _require_linux_vps_aliases "vps-benchmark-save"; then
    return 1
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
      -o|--output)
        if [ -z "$2" ]; then
          _show_error_vps_aliases "Missing value for --output."
          return 1
        fi
        output_target="$2"
        shift 2
        ;;
      --)
        shift
        break
        ;;
      *)
        if [ "${1#-}" = "$1" ] && [ -z "$output_target" ]; then
          output_target="$1"
          shift
        fi
        break
        ;;
    esac
  done

  if [ -z "$output_target" ]; then
    output_target="$(_default_log_vps_aliases "nodequality")"
  fi

  echo "Running NodeQuality benchmark and saving the console log..."
  _run_nodequality_vps_aliases "$output_target" "$@"
}' # Run NodeQuality and save the console log

alias vps-yabs='() {
  _show_usage_vps_aliases "Run YABS for CPU, disk and network benchmarking.\nUsage:\n  vps-yabs [--output path] [yabs_args]\nExamples:\n  vps-yabs\n  vps-yabs -r\n  vps-yabs --output ~/yabs.log -- -f -i"

  local output_target=""
  local upstream_args=()

  if [ "$1" = "--help" ]; then
    return 0
  fi

  if ! _require_linux_vps_aliases "vps-yabs"; then
    return 1
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
      -o|--output)
        if [ -z "$2" ]; then
          _show_error_vps_aliases "Missing value for --output."
          return 1
        fi
        output_target="$2"
        shift 2
        ;;
      --help)
        return 0
        ;;
      --)
        shift
        while [ $# -gt 0 ]; do
          upstream_args+=("$1")
          shift
        done
        ;;
      *)
        upstream_args+=("$1")
        shift
        ;;
    esac
  done

  echo "Running YABS benchmark..."
  _run_yabs_vps_aliases "$output_target" "${upstream_args[@]}"
}' # Run YABS with optional log capture

# VPS auditing and diagnostics
# -----------------------------

alias vps-audit='() {
  _show_usage_vps_aliases "Run the vps-audit security and health checks.\nUsage:\n  vps-audit [--output path] [--no-sudo]\nExamples:\n  vps-audit\n  vps-audit --output ~/vps-audit.log\n  vps-audit --no-sudo"

  local output_target=""
  local use_privilege="auto"
  local upstream_args=()

  if [ "$1" = "--help" ]; then
    return 0
  fi

  if ! _require_linux_vps_aliases "vps-audit"; then
    return 1
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
      -o|--output)
        if [ -z "$2" ]; then
          _show_error_vps_aliases "Missing value for --output."
          return 1
        fi
        output_target="$2"
        shift 2
        ;;
      --no-sudo)
        use_privilege="no"
        shift
        ;;
      --help)
        return 0
        ;;
      --)
        shift
        while [ $# -gt 0 ]; do
          upstream_args+=("$1")
          shift
        done
        ;;
      *)
        upstream_args+=("$1")
        shift
        ;;
    esac
  done

  if [ "$use_privilege" = "auto" ]; then
    if [ "$(id -u)" -eq 0 ]; then
      use_privilege="no"
    else
      use_privilege="yes"
    fi
  fi

  echo "Running VPS audit..."
  _run_audit_vps_aliases "$output_target" "$use_privilege" "${upstream_args[@]}"
}' # Run vps-audit with safer download and optional log capture

alias vps-quick-info='() {
  _show_usage_vps_aliases "Show a quick local Linux VPS overview.\nUsage:\n  vps-quick-info"

  local host_name=""
  local os_name="unknown"
  local kernel_name=""

  if [ "$1" = "--help" ]; then
    return 0
  fi

  if ! _require_linux_vps_aliases "vps-quick-info"; then
    return 1
  fi

  host_name="$(hostname 2>/dev/null || echo "unknown")"
  kernel_name="$(uname -r 2>/dev/null || echo "unknown")"

  if [ -r "/etc/os-release" ]; then
    os_name="$(awk -F= "/^PRETTY_NAME=/{gsub(/\\\"/, \"\", \$2); print \$2}" /etc/os-release)"
  fi

  echo "Hostname: $host_name"
  echo "Operating System: $os_name"
  echo "Kernel: $kernel_name"
  echo "Uptime:"
  uptime 2>/dev/null || true
  echo ""
  echo "CPU:"
  if command -v lscpu >/dev/null 2>&1; then
    LC_ALL=C lscpu | grep -E "^Architecture|^CPU\\(s\\)|^Model name|^Thread|^Core|^Socket"
  else
    uname -m
  fi
  echo ""
  echo "Memory:"
  if command -v free >/dev/null 2>&1; then
    free -h
  else
    grep -E "MemTotal|MemAvailable|SwapTotal|SwapFree" /proc/meminfo 2>/dev/null || true
  fi
  echo ""
  echo "Disk:"
  df -h /
}' # Show a quick local Linux VPS overview

# Help
# -----------------------------

alias vps-help='() {
  _show_usage_vps_aliases "VPS aliases overview.\nUsage:\n  vps-help\n\nAvailable commands:\n  vps-benchmark      Run NodeQuality for IP, route and mixed VPS quality checks\n  vps-benchmark-save Run NodeQuality and save the console log to a local file\n  vps-yabs           Run YABS for CPU, disk and network benchmarking\n  vps-audit          Run a safer vps-audit wrapper with download fallback support\n  vps-quick-info     Show a quick local Linux VPS summary\n  vps-help           Show this help message\n\nNotes:\n  NodeQuality: best for route, IP and mixed VPS quality checks\n  YABS: better fallback for common CPU, disk and network benchmarks\n  vps-audit: targeted at Linux servers, especially Debian and Ubuntu\n  Use --help for wrapper help, or pass upstream flags directly when supported."
}' # Display help for VPS aliases
