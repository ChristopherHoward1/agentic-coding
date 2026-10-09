#!/usr/bin/env bash
# Export committed capabilities, replacing instance state with committed skeletons.
set -uo pipefail

usage() { echo 'Usage: scripts/export-template.sh <dest>' >&2; }
error() { echo "export: $*" >&2; exit 2; }
if [[ $# -ne 1 ]]; then
  usage
  exit 1
fi
dest=$1
if [[ -d "$dest" ]]; then
  entries=$(ls -A -- "$dest") || error "cannot inspect $dest"
  if [[ -n "$entries" ]]; then
    echo "export: destination is non-empty: $dest" >&2
    exit 1
  fi
elif [[ -e "$dest" || -L "$dest" ]]; then
  echo "export: destination is not a directory: $dest" >&2
  exit 1
fi
if [[ -n "$dest" && "$dest" != /* ]]; then
  dest="$PWD/$dest"
fi
root=$(git rev-parse --show-toplevel) || error 'cannot resolve repository root'
cd "$root" || error 'cannot enter repository root'
mkdir -p -- "$dest" || error "cannot create $dest"
git archive HEAD | tar -x -C "$dest" || error 'cannot extract HEAD'
paths=$(git ls-tree -r --name-only HEAD -- template/) || error 'cannot list overlay'
while IFS= read -r path; do
  [[ -n "$path" ]] || continue
  target="$dest/${path#template/}"
  mkdir -p -- "$(dirname "$target")" || error "cannot create overlay directory"
  git show "HEAD:$path" >"$target" || error "cannot overlay $path"
done <<<"$paths"
printf '%s\n' "$dest"
