#!/usr/bin/env bash
# Export tests use committed copies of working-tree files, never the live HEAD.
# Test functions are invoked indirectly by check.
# shellcheck disable=SC2317,SC2329 # SC2317 on shellcheck <0.10 (CI), SC2329 on >=0.10
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
  for path in work template .gitattributes scripts/export-template.sh scripts/sync-template.sh tests/test-export.sh scripts/gate.d/test-scripts.sh; do
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
subdirectory_destination() {
  fixture subdirectory || return 1
  dest="$repo/scripts/out"
  (cd "$repo/scripts" && bash ./export-template.sh out) &&
    [[ -f "$dest/CLAUDE.md" ]] &&
    [[ $(cat "$dest/VERSION") == 1970.1.0 ]] &&
    [[ ! -e "$repo/out" ]]
}
sync_fixture() {
  fixture "$1" || return 1
  version=$(cat "$repo/VERSION") || return 1
  git -C "$repo" tag "v$version" || return 1
  template="$TMP/$1/template.git"
  local seed="$TMP/$1/seed"
  mkdir -p "$seed/conventions" || return 1
  printf 'stale\n' >"$seed/conventions/x"
  printf 'old README\n' >"$seed/README.md"
  git init -q -b main "$seed" && git -C "$seed" add -A &&
    git -C "$seed" -c user.email=t@t -c user.name=t commit -qm old &&
    git clone -q --bare "$seed" "$template" || return 1
  original=$(git -C "$template" rev-parse main) || return 1
  refs=$(git -C "$template" for-each-ref) || return 1
  tempdir="$TMP/$1/temps"
  mkdir -p "$tempdir"
}
sync_tree() {
  (cd "$repo" && TMPDIR="$tempdir" TEMPLATE_REPO="$template" \
    GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t \
    bash scripts/sync-template.sh "$@")
}
sync_first() {
  sync_fixture sync-first || return 1
  local out clone branch sha
  out=$(sync_tree) || return 1
  clone=$(head -1 <<<"$out")
  branch=$(tail -1 <<<"$out")
  sha=$(git -C "$repo" rev-parse --short HEAD) || return 1
  [[ -d "$clone" && "$branch" == "template-sync/v$version" ]] &&
    [[ $(git -C "$clone" branch --show-current) == "$branch" ]] &&
    [[ $(git -C "$clone" log -1 --format=%s) == "Sync from agentic-coding v$version ($sha)" ]] &&
    [[ $(git -C "$clone" rev-parse HEAD~1) == "$original" ]] &&
    [[ $(git -C "$template" for-each-ref) == "$refs" ]] || return 1
  export_tree "$dest" && git -C "$dest" init -q && git -C "$dest" add -Af &&
    git -C "$dest" -c user.email=t@t -c user.name=t commit -qm export || return 1
  [[ $(git -C "$clone" rev-parse 'HEAD^{tree}') == $(git -C "$dest" rev-parse 'HEAD^{tree}') ]]
}
sync_noop() {
  sync_fixture sync-noop || return 1
  local out clone
  out=$(sync_tree) || return 1
  clone=$(head -1 <<<"$out")
  git -C "$clone" push -q origin HEAD:main || return 1
  rm -rf "$clone" || return 1
  refs=$(git -C "$template" for-each-ref) || return 1
  [[ -z $(ls -A "$tempdir") ]] || return 1
  out=$(sync_tree) || return 1
  [[ "$out" == 'up to date' && -z $(ls -A "$tempdir") ]] &&
    [[ $(git -C "$template" for-each-ref) == "$refs" ]]
}
sync_tags() {
  sync_fixture sync-tags || return 1
  git -C "$repo" tag -d "v$version" || return 1
  sync_tree >"$TMP/stdout" 2>"$TMP/stderr"
  local status=$?
  [[ $status == 1 && ! -s "$TMP/stdout" ]] &&
    grep -Fq "HEAD must carry v$version" "$TMP/stderr" || return 1
  git -C "$repo" tag "v$version" && git -C "$repo" tag other-tag || return 1
  local out
  out=$(sync_tree) || return 1
  [[ -d $(head -1 <<<"$out") && $(tail -1 <<<"$out") == "template-sync/v$version" ]]
}
sync_arguments() {
  sync_fixture sync-arguments || return 1
  sync_tree extra >"$TMP/stdout" 2>"$TMP/stderr"
  local status=$?
  [[ $status == 1 && ! -s "$TMP/stdout" && -z $(ls -A "$tempdir") ]] &&
    grep -Fq 'Usage:' "$TMP/stderr"
}
check 'sync (a): exact export tree, preserved parent and clone, no push' sync_first
check 'sync (b): up to date leaves TMPDIR empty and refs unchanged' sync_noop
check 'sync (c): missing release tag refuses; two lightweight tags succeed' sync_tags
check 'sync (d): arguments refuse without writes' sync_arguments

check 'clean export and consumer gate/freshness' success
check 'no arguments refuses with usage' arguments noargs
check 'extra arguments refuses with usage and writes nothing' arguments extra "$TMP/extra/out" extra
check 'non-empty destination refuses without writes' nonempty
check 'file destination refuses without writes' file_destination
check 'base and overlay both reflect HEAD' head_content
check 'existing empty destination succeeds' empty_destination
check 'subdirectory export resolves relative destination against caller cwd' subdirectory_destination

echo
echo "passed: $pass, failed: $fail"
exit "$((fail > 0 ? 1 : 0))"
