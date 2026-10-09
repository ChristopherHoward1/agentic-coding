#!/usr/bin/env bash
# Prepare a template sync commit; publishing belongs to the release skill.
set -uo pipefail

error() { echo "sync: $*" >&2; exit 2; }
if [[ $# -ne 0 ]]; then
  echo 'Usage: scripts/sync-template.sh' >&2
  exit 1
fi
root=$(git rev-parse --show-toplevel) || error 'cannot resolve repository root'
cd "$root" || error 'cannot enter repository root'
version=$(cat VERSION) || error 'cannot read VERSION'
tags=$(git tag --points-at HEAD) || error 'cannot list HEAD tags'
if ! grep -qx "v$version" <<<"$tags"; then
  echo "sync: HEAD must carry v$version" >&2
  exit 1
fi
sha=$(git rev-parse --short HEAD) || error 'cannot resolve HEAD'
clone=$(mktemp -d) || error 'cannot create clone directory'
exp=$(mktemp -d) || error 'cannot create export directory'
trap 'rm -rf "$exp"' EXIT
TEMPLATE_REPO=${TEMPLATE_REPO:-https://github.com/ChristopherHoward1/agentic-coding-template.git}
git clone -q "$TEMPLATE_REPO" "$clone" || error 'cannot clone template repository'
bash scripts/export-template.sh "$exp" >/dev/null || error 'cannot export template'
branch="template-sync/v$version"
cd "$clone" || error 'cannot enter clone'
git switch -c "$branch" >&2 || error 'cannot create sync branch'
git rm -rq --ignore-unmatch . || error 'cannot remove old tree'
cp -R "$exp/." "$clone/" || error 'cannot copy export'
git add -Af || error 'cannot stage export'
git diff --cached --quiet
status=$?
if [[ $status == 0 ]]; then
  rm -rf "$clone" || error 'cannot delete up-to-date clone'
  echo 'up to date'
  exit 0
fi
[[ $status == 1 ]] || error 'cannot compare staged tree'
git commit -qm "Sync from agentic-coding v$version ($sha)" || error 'cannot commit sync'
printf '%s\n' "$clone" "$branch"
