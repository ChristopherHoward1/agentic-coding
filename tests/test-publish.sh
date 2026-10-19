#!/usr/bin/env bash
# Publish tests use committed copies of working-tree files, never the live HEAD.
# Test functions are invoked indirectly by check.
# shellcheck disable=SC2317,SC2329 # SC2317 on shellcheck <0.10, SC2329 on >=0.10
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
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
export HARNESS_HOME="$TMP/harness-home"
trap 'rm -rf "$TMP"' EXIT

fixture() {
  repo="$TMP/$1/repo"
  mkdir -p "$repo" || return 2
  local path
  local files
  files=$(mktemp "$TMP/files.XXXXXX") || return 2
  git ls-files -z --cached --others --exclude-standard >"$files" || return 2
  while IFS= read -r -d '' path; do
    [[ -e "$ROOT/$path" || -L "$ROOT/$path" ]] || continue
    mkdir -p "$repo/$(dirname "$path")" || return 2
    cp -P "$ROOT/$path" "$repo/$path" || return 2
  done <"$files"
  git init -q -b main "$repo" &&
    git -C "$repo" add -A &&
    git -C "$repo" -c user.email=t@t -c user.name=t commit -qm init
}
publish_fixture() {
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
    git init -q --bare --initial-branch=main "$template" &&
    git -C "$seed" push -q "$template" HEAD:main || return 1
  original=$(git -C "$template" rev-parse main) || return 1
  refs=$(git -C "$template" for-each-ref) || return 1
  tempdir="$TMP/$1/temps"
  mkdir -p "$tempdir"
}
publish_tree() {
  (cd "$repo" && TMPDIR="$tempdir" TEMPLATE_REPO="$template" \
    GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t \
    bash scripts/publish.sh "$@")
}
publish_first() {
  publish_fixture sync-first || return 1
  local out clone branch sha
  out=$(publish_tree) || return 1
  clone=$(head -1 <<<"$out")
  branch=$(tail -1 <<<"$out")
  sha=$(git -C "$repo" rev-parse --short HEAD) || return 1
  [[ -d "$clone" && "$branch" == "template-sync/v$version" ]] &&
    [[ $(git -C "$clone" branch --show-current) == "$branch" ]] &&
    [[ $(git -C "$clone" log -1 --format=%s) == "Sync from agentic-coding v$version ($sha)" ]] &&
    [[ $(git -C "$clone" rev-parse HEAD~1) == "$original" ]] &&
    [[ $(git -C "$template" for-each-ref) == "$refs" ]] || return 1
  git -C "$repo" ls-tree -r HEAD -- harness README.md LICENSE >"$TMP/expected" &&
    git -C "$clone" ls-tree -r HEAD >"$TMP/actual" &&
    cmp "$TMP/expected" "$TMP/actual" &&
    [[ $(ls -A "$tempdir") == "${clone##*/}" ]] || return 1
  local path
  for path in config.yaml ARCHI.md PLAN.md VERSION CHANGELOG.md; do
    cmp "$repo/harness/skeleton/$path" "$clone/harness/skeleton/$path" || return 1
  done
}
publish_noop() {
  publish_fixture sync-noop || return 1
  local out clone
  out=$(publish_tree) || return 1
  clone=$(head -1 <<<"$out")
  git -C "$clone" push -q origin HEAD:main || return 1
  rm -rf "$clone" || return 1
  refs=$(git -C "$template" for-each-ref) || return 1
  [[ -z $(ls -A "$tempdir") ]] || return 1
  out=$(publish_tree) || return 1
  [[ "$out" == 'up to date' && -z $(ls -A "$tempdir") ]] &&
    [[ $(git -C "$template" for-each-ref) == "$refs" ]]
}
publish_tags() {
  publish_fixture sync-tags || return 1
  git -C "$repo" tag -d "v$version" || return 1
  publish_tree >"$TMP/stdout" 2>"$TMP/stderr"
  local status=$?
  [[ $status == 1 && ! -s "$TMP/stdout" && -z $(ls -A "$tempdir") ]] &&
    grep -Fq "HEAD must carry v$version" "$TMP/stderr" || return 1
  git -C "$repo" tag "v${version//./x}" || return 1
  publish_tree >"$TMP/stdout" 2>"$TMP/stderr"
  status=$?
  [[ $status == 1 && ! -s "$TMP/stdout" && -z $(ls -A "$tempdir") ]] &&
    grep -Fq "HEAD must carry v$version" "$TMP/stderr" || return 1
  git -C "$repo" tag -d "v${version//./x}" || return 1
  git -C "$repo" tag "v$version" && git -C "$repo" tag other-tag || return 1
  local out
  out=$(publish_tree) || return 1
  [[ -d $(head -1 <<<"$out") && $(tail -1 <<<"$out") == "template-sync/v$version" ]]
}
publish_arguments() {
  publish_fixture sync-arguments || return 1
  publish_tree extra >"$TMP/stdout" 2>"$TMP/stderr"
  local status=$?
  [[ $status == 1 && ! -s "$TMP/stdout" && -z $(ls -A "$tempdir") ]] &&
    grep -Fq 'Usage:' "$TMP/stderr"
}
head_content() {
  publish_fixture head-content || return 1
  printf 'uncommitted\n' >"$repo/README.md"
  printf 'untracked\n' >"$repo/harness/untracked"
  local out clone
  out=$(publish_tree) || return 1
  clone=$(head -1 <<<"$out")
  git -C "$repo" show HEAD:README.md >"$TMP/committed" &&
    cmp "$TMP/committed" "$clone/README.md" && [[ ! -e "$clone/harness/untracked" ]]
}
consumer() {
  publish_fixture consumer || return 1
  local out clone project="$TMP/consumer/project"
  out=$(publish_tree) || return 1
  clone=$(head -1 <<<"$out")
  mkdir -p "$project" || return 1
  cp "$clone/harness/skeleton/"{config.yaml,ARCHI.md,PLAN.md} "$project/" || return 1
  printf '@%s/harness/CONSTITUTION.md\n@ARCHI.md\n@PLAN.md\n' "$clone" >"$project/CLAUDE.md"
  git init -q -b main "$project" && git -C "$project" add -A &&
    git -C "$project" commit -qm init &&
    (cd "$project" && bash "$clone/harness/bin/harness" gate &&
      bash "$clone/harness/bin/harness" archi-fresh)
}
check 'publish (a): exact published tree, preserved parent and clone, no push' publish_first
check 'publish (b): up to date leaves TMPDIR empty and refs unchanged' publish_noop
check 'publish (c): missing and near-match release tags refuse; two lightweight tags succeed' publish_tags
check 'publish (d): arguments refuse without writes' publish_arguments
check 'publish reflects HEAD only' head_content
check 'published skeleton consumer gate and freshness' consumer

echo
echo "passed: $pass, failed: $fail"
exit "$((fail > 0 ? 1 : 0))"
