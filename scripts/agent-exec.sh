#!/usr/bin/env bash
# Dispatch the implementer agent into a worktree with a handoff on stdin.
# Usage: scripts/agent-exec.sh <worktree-path> <handoff-file>
#
# The implementer command comes from config.yaml (implementer.command) —
# this script is the ONLY place an external agent is invoked, so swapping
# vendors is a one-line config change, not a script rewrite.
set -euo pipefail

ROOT=$(git rev-parse --show-toplevel)
WORKTREE=${1:?usage: agent-exec.sh <worktree-path> <handoff-file>}
HANDOFF=${2:?usage: agent-exec.sh <worktree-path> <handoff-file>}

[[ -d "$WORKTREE" ]] || { echo "Error: worktree not found: $WORKTREE" >&2; exit 1; }
[[ -s "$HANDOFF" ]] || { echo "Error: handoff missing or empty: $HANDOFF" >&2; exit 1; }

CMD=$(awk "/^implementer:/{f=1;next} f&&/command:/{sub(/^[[:space:]]*command:[[:space:]]*'/,\"\");sub(/'[[:space:]]*\$/,\"\");print;exit}" "$ROOT/config.yaml")
[[ -n "$CMD" ]] || { echo "Error: implementer.command not set in config.yaml" >&2; exit 1; }

HANDOFF_ABS=$(cd "$(dirname "$HANDOFF")" && pwd -P)/$(basename "$HANDOFF")

echo "Dispatching implementer in $WORKTREE" >&2
echo "  $CMD < $HANDOFF_ABS" >&2
cd "$WORKTREE"
eval "$CMD" < "$HANDOFF_ABS"
