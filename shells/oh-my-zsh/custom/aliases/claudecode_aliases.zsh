# Description: Claude Code aliases

_check_command_claudecode_aliases() {
  if ! command -v $1 &> /dev/null; then
    return 1
  fi
  return 0
}

alias cc-usage='() {
  if ! _check_command_claudecode_aliases ccusage; then
    return 1
  fi
  npx ccusage $@
}'

alias cc-monitor='() {
  if ! _check_command_claudecode_aliases claude-monitor; then
    return 1
  fi
  claude-monitor $@
}'

alias cc-help='() {
  echo "Claude Code"
  echo "Usage:"
  echo "  cc-usage"
  echo "  cc-monitor"
}'
