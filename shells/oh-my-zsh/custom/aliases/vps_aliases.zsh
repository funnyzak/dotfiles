# Description of the aliases used for managing VPS instances.

# VPS Benchmarking and Quality Testing

# Run NodeQuality benchmark (tests hardware, IP quality, and network quality)
alias vps-benchmark='() {
  echo "NodeQuality Benchmark - Tests hardware, IP and network quality."
  bash <(curl -sL https://run.NodeQuality.com)
}' # Run NodeQuality benchmark

# Run NodeQuality benchmark and save results to a file
alias vps-benchmark-save='() {
  echo "NodeQuality Benchmark with saved results."
  echo "Running NodeQuality benchmark and saving results..."
  bash <(curl -sL https://run.NodeQuality.com) | tee ~/vps-benchmark-results-$(date +%Y%m%d-%H%M%S).txt
  echo "Benchmark results saved to ~/vps-benchmark-results-$(date +%Y%m%d-%H%M%S).txt"
}' # Run NodeQuality benchmark with saved results
