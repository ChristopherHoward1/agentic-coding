#!/usr/bin/env bash
# Smoke tests for the deterministic layer. Run from repo root: bash tests/test-scripts.sh
set -uo pipefail

pass=0; fail=0
check() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "ok: $desc"; pass=$((pass+1))
  else
    echo "FAIL: $desc"; fail=$((fail+1))
  fi
}
check_fails() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "FAIL: $desc (expected non-zero exit)"; fail=$((fail+1))
  else
    echo "ok: $desc"; pass=$((pass+1))
  fi
}

ROOT=$(git rev-parse --show-toplevel)
cd "$ROOT" || exit 1

# --- shellcheck the scripts themselves (gate.sh covers this too; belt+braces)
if command -v shellcheck >/dev/null; then
  check "shellcheck scripts" shellcheck scripts/*.sh tests/*.sh
fi

# --- worktree.sh lifecycle in a throwaway repo
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
(
  cd "$TMP"
  git init -q -b main sandbox && cd sandbox
  git commit -q --allow-empty -m init
  cp "$ROOT/scripts/worktree.sh" wt.sh
  printf 'worktrees:\n  dir: ../wts\n' > config.yaml
  git add -A && git commit -qm files
) || { echo "FAIL: sandbox setup"; exit 1; }

SB="$TMP/sandbox"
WT_PATH=$(cd "$SB" && bash wt.sh add demo 2>/dev/null)
check "worktree add creates directory" test -d "$WT_PATH"
check "worktree branch checked out" bash -c "cd '$WT_PATH' && [ \"\$(git branch --show-current)\" = wt/demo ]"
check "worktree.sh works FROM INSIDE a worktree (.git-as-file)" bash -c "cd '$WT_PATH' && bash wt.sh list"
check "worktree remove" bash -c "cd '$SB' && bash wt.sh remove demo"
check_fails "worktree add without slug fails" bash -c "cd '$SB' && bash wt.sh add"

# --- agent-exec.sh argument validation
check_fails "agent-exec rejects missing handoff" bash scripts/agent-exec.sh /tmp nonexistent-handoff.md

# --- gate.sh runs and exits cleanly on this repo
check "gate.sh runs on this repo" bash scripts/gate.sh

echo
echo "passed: $pass, failed: $fail"
exit "$((fail > 0 ? 1 : 0))"
