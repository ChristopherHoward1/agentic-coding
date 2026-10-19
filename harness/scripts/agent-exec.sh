#!/usr/bin/env bash
# Dispatch the implementer agent into a worktree with a handoff on stdin.
# Usage: harness agent-exec <worktree-path> <handoff-file>
#
# The implementer command comes from config.yaml (implementer.command) —
# this script is the ONLY place an external agent is invoked, so swapping
# vendors is a one-line config change, not a script rewrite.
set -euo pipefail

HERE=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CONTRACT="$HERE/../AGENTS.md"
[[ -s "$CONTRACT" ]] || { echo "Error: contract missing or empty: $CONTRACT" >&2; exit 1; }

git rev-parse --show-toplevel >/dev/null
WORKTREE=${1:?usage: harness agent-exec <worktree-path> <handoff-file>}
HANDOFF=${2:?usage: harness agent-exec <worktree-path> <handoff-file>}

[[ -d "$WORKTREE" ]] || { echo "Error: worktree not found: $WORKTREE" >&2; exit 1; }
WORKTREE=$(cd "$WORKTREE" && pwd -P)
[[ -s "$HANDOFF" ]] || { echo "Error: handoff missing or empty: $HANDOFF" >&2; exit 1; }

# shellcheck source=/dev/null
source "$HERE/lib/project.sh"
resolve_project
config="$STATE_DIR/config.yaml"
if [[ "$PROJECT_MODE" == registry && ! -f "$config" ]]; then config=/dev/null; fi

CMD=$(awk "/^implementer:/{f=1;next} f&&/command:/{sub(/^[[:space:]]*command:[[:space:]]*'/,\"\");sub(/'[[:space:]]*\$/,\"\");print;exit}" "$config")
[[ -n "$CMD" ]] || { echo "Error: implementer.command not set in config.yaml" >&2; exit 1; }

HANDOFF_ABS=$(cd "$(dirname "$HANDOFF")" && pwd -P)/$(basename "$HANDOFF")
HEAD_BEFORE=$(git -C "$WORKTREE" rev-parse HEAD)
STATUS_BEFORE=$(git -C "$WORKTREE" status --porcelain)

INPUT=$(mktemp)
trap 'rm -f "$INPUT"' EXIT
{ cat "$CONTRACT"; printf '%s\n' '---'; cat "$HANDOFF_ABS"; } >"$INPUT"

echo "Dispatching implementer in $WORKTREE" >&2
echo "  $CMD < $CONTRACT + $HANDOFF_ABS" >&2
cd "$WORKTREE${PROJECT_SUBDIR:+/$PROJECT_SUBDIR}"
set +e
eval "$CMD" < "$INPUT"
status=$?
set -e
if [[ "$status" -ne 0 ]]; then
  exit "$status"
fi

HEAD_AFTER=$(git -C "$WORKTREE" rev-parse HEAD)
if [[ -z "$STATUS_BEFORE" && "$HEAD_AFTER" == "$HEAD_BEFORE" && -z "$(git -C "$WORKTREE" status --porcelain)" ]]; then
  echo "Error: implementer produced no new commit and left no worktree changes" >&2
  exit 1
fi
