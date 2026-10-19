#!/usr/bin/env bash
set -uo pipefail
case "${1:-}" in
  ''|mode|root) [[ $# -le 1 ]] || exit 2 ;;
  -h|--help) echo 'Usage: harness project [mode|root]'; exit 0 ;;
  *) echo 'Usage: harness project [mode|root]' >&2; exit 2 ;;
esac
HERE=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=/dev/null
source "$HERE/lib/project.sh"
resolve_project
case "${1:-}" in
  '') echo "$STATE_DIR" ;;
  mode) echo "$PROJECT_MODE" ;;
  root) echo "$PROJECT_ROOT" ;;
esac
