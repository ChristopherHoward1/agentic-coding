#!/usr/bin/env bash
# Export tests use committed copies of working-tree files, never the live HEAD.
# Test functions are invoked indirectly by check.
# shellcheck disable=SC2329
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
ROOT=$(git rev-parse --show-toplevel) || exit 2
cd "$ROOT" || exit 2
unset GATE_REQUIRED_TOOLS
TMP=$(mktemp -d) || exit 2
trap 'rm -rf "$TMP"' EXIT

fixture() {
  repo="$TMP/$1/repo"
  dest="$TMP/$1/out"
  mkdir -p "$repo" || return 2
  local path
  local files
  files=$(mktemp "$TMP/files.XXXXXX") || return 2
  git ls-files -z --cached --others --exclude-standard >"$files" || return 2
  while IFS= read -r -d '' path; do
    mkdir -p "$repo/$(dirname "$path")" || return 2
    cp -P "$ROOT/$path" "$repo/$path" || return 2
  done <"$files"
  git init -q -b main "$repo" &&
    git -C "$repo" add -A &&
    git -C "$repo" -c user.email=t@t -c user.name=t commit -qm init
}
export_tree() { (cd "$repo" && bash scripts/export-template.sh "$@"); }

success() {
  fixture success && export_tree "$dest" || return 1
  local path
  for path in work template .gitattributes scripts/export-template.sh tests/test-export.sh scripts/gate.d/test-scripts.sh; do
    [[ ! -e "$dest/$path" ]] || return 1
  done
  [[ -f "$dest/tests/test-scripts.sh" && -d "$dest/knowledge" ]] &&
    [[ $(cat "$dest/VERSION") == 1970.1.0 ]] &&
    cmp "$repo/template/CHANGELOG.md" "$dest/CHANGELOG.md" &&
    ! grep -q '^## ' "$dest/CHANGELOG.md" &&
    cmp "$repo/template/PLAN.md" "$dest/PLAN.md" &&
    cmp "$repo/template/ARCHI.md" "$dest/ARCHI.md" || return 1
  if grep -rn 'agentic-coding-worktrees\|promoted 2026\|Confirm-delta releases\|export-template' "$dest"; then return 1; fi
  git init -q -b main "$dest" && git -C "$dest" add -A &&
    git -C "$dest" -c user.email=t@t -c user.name=t commit -qm init &&
    (cd "$dest" && bash scripts/gate.sh && bash scripts/archi-fresh.sh)
}
arguments() {
  fixture "$1" || return 1
  shift
  export_tree "$@" >"$TMP/stdout" 2>"$TMP/stderr"
  local status=$?
  [[ $status == 1 ]] && grep -Fq 'Usage:' "$TMP/stderr" &&
    [[ ! -s "$TMP/stdout" && ! -e "$dest" ]]
}
nonempty() {
  fixture nonempty && mkdir -p "$dest" || return 1
  printf 'keep\n' >"$dest/.sentinel"
  export_tree "$dest" >"$TMP/stdout" 2>"$TMP/stderr"
  local status=$?
  [[ $status == 1 && $(ls -A "$dest") == .sentinel ]] &&
    [[ $(cat "$dest/.sentinel") == keep && ! -s "$TMP/stdout" ]]
}
file_destination() {
  fixture file || return 1
  printf 'keep\n' >"$dest"
  export_tree "$dest" >/dev/null 2>&1
  local status=$?
  [[ $status == 1 && $(cat "$dest") == keep ]]
}
head_content() {
  fixture head || return 1
  printf 'uncommitted\n' >"$repo/CLAUDE.md"
  printf '2099.1.0\n' >"$repo/template/VERSION"
  export_tree "$dest" &&
    git -C "$repo" show HEAD:CLAUDE.md >"$TMP/committed" &&
    cmp "$TMP/committed" "$dest/CLAUDE.md" &&
    [[ $(cat "$dest/VERSION") == 1970.1.0 ]]
}
empty_destination() {
  fixture empty && mkdir -p "$dest" && export_tree "$dest" &&
    [[ -f "$dest/CLAUDE.md" ]]
}
check 'clean export and consumer gate/freshness' success
check 'no arguments refuses with usage' arguments noargs
check 'extra arguments refuses with usage and writes nothing' arguments extra "$TMP/extra/out" extra
check 'non-empty destination refuses without writes' nonempty
check 'file destination refuses without writes' file_destination
check 'base and overlay both reflect HEAD' head_content
check 'existing empty destination succeeds' empty_destination

echo
echo "passed: $pass, failed: $fail"
exit "$((fail > 0 ? 1 : 0))"
