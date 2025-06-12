# Description: Aliases for VPS management, benchmarking and system auditing.

# VPS Benchmarking and Quality Testing
# ====================================

# Run NodeQuality benchmark (tests hardware, IP quality, and network quality)
alias vps-benchmark='() {
  echo "NodeQuality Benchmark - Tests hardware, IP and network quality."
  echo "Usage:"
  echo "  vps-benchmark"

  if ! bash <(curl -sL https://run.NodeQuality.com); then
    echo "Failed to run NodeQuality benchmark" >&2
    return 1
  fi
}' # Run NodeQuality benchmark

# Run NodeQuality benchmark and save results to a file
alias vps-benchmark-save='() {
  echo "NodeQuality Benchmark with saved results."
  echo "Usage:"
  echo "  vps-benchmark-save"

  echo "Running NodeQuality benchmark and saving results..."
  local result_file="~/vps-benchmark-results-$(date +%Y%m%d-%H%M%S).txt"

  if ! bash <(curl -sL https://run.NodeQuality.com) | tee "$result_file"; then
    echo "Failed to run NodeQuality benchmark" >&2
    return 1
  fi

  echo "Benchmark results saved to $result_file"
}' # Run NodeQuality benchmark with saved results

# VPS Audit Tool
alias vps-audit='() {
  echo "Audit VPS system information"
  echo "Usage:"
  echo "  vps-audit"

  echo "Running VPS audit..."
  if ! curl -sSL https://cdn.jsdelivr.net/gh/vernu/vps-audit@main/vps-audit.sh | sudo bash; then
    echo "Failed to run VPS audit" >&2
    return 1
  fi
}' # Audit VPS system information

# Help function for VPS aliases
alias vps-help='() {
  echo "VPS Management Aliases Help"
  echo "=========================="
  echo "Available commands:"
  echo "  vps-benchmark       - Run NodeQuality benchmark to test hardware, IP and network quality"
  echo "  vps-benchmark-save  - Run NodeQuality benchmark and save results to a file"
  echo "  vps-audit          - Audit VPS system information"
  echo "  vps-help           - Display this help message"
}' # Display help for VPS management aliases
