# Description: Codex aliases

_check_command_codex_aliases() {
  if ! command -v $1 &> /dev/null; then
    return 1
  fi
  return 0
}

alias codex-free='() {
  codex --dangerously-bypass-approvals-and-sandbox $@
}'

alias codex-help='() {
  echo "Codex"
  echo "Usage:"
  echo "  codex-free - Codex bypass permission"
}'
