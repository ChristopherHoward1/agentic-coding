#!/usr/bin/env bash
# Run the first shell block in a plan's Demonstration section.
set -uo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/demo.sh <slug> [<dir>]

Runs the plan's Demonstration from <dir> (default .).
Exit 0 = pass, 1 = demo failure, 2 = plan or tooling error.
USAGE
}
error() { echo "demo: $*" >&2; exit 2; }
if [[ "${1:-}" == --help || "${1:-}" == -h ]]; then
  usage
  exit 0
fi
if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage >&2
  exit 2
fi
dir=${2:-.}
[[ $(git -C "$dir" rev-parse --is-inside-work-tree 2>/dev/null) == true ]] || error "$dir is not a git work tree"
plan="$dir/work/$1/plan.md"
[[ -f "$plan" ]] || error "no plan: $plan"
block=$(mktemp) || error "cannot create temporary file"
trap 'rm -f "$block"' EXIT
section=0
fence=
capture=0
found=0
fence_re='^(`{3,}|~{3,})(.*)$'
while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ -n "$fence" ]]; then
    close_re="^${fence}[${fence:0:1}]*[[:space:]]*$"
    if [[ "$line" =~ $close_re ]]; then
      fence=
      if (( capture )); then found=1; break; fi
    elif (( capture )); then
      printf '%s\n' "$line" >>"$block" || error "cannot write temporary file"
    fi
    continue
  fi
  if [[ "$line" == '## Demonstration' ]]; then
    section=1
    continue
  fi
  if (( section )) && [[ "$line" == '## '* ]]; then break; fi
  if [[ "$line" =~ $fence_re ]]; then
    fence=${BASH_REMATCH[1]}
    language=${BASH_REMATCH[2]}
    if (( section )) && [[ "$fence" == '```' ]] && [[ "$language" == sh || "$language" == bash ]]; then
      capture=1
    fi
  elif (( section )) && [[ "$line" == 'None: '* ]]; then
    echo "demo: none — ${line#None: }"
    exit 0
  fi
done <"$plan"
(( section )) || error 'no ## Demonstration section'
(( found )) || error 'no shell block or None: in ## Demonstration'
before=$(git -C "$dir" status --porcelain) || error "cannot read worktree status"
(cd "$dir" && bash "$block")
status=$?
after=$(git -C "$dir" status --porcelain) || error "cannot read worktree status"
verdict=0
if (( status != 0 )); then
  echo "demo: block exited with code $status" >&2
  verdict=1
fi
if [[ "$before" != "$after" ]]; then
  echo 'demo dirtied the worktree' >&2
  verdict=1
fi
exit "$verdict"
