#!/usr/bin/env bash
# Derive one work unit's execution state from observable repo facts.
set -uo pipefail

HERE=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)

usage() {
  echo "Usage: harness state <slug>" >&2
}

die() {
  echo "state: $*" >&2
  exit 1
}

has_line() {
  local line="$1"
  grep -qx -- "$line" <<<"$plan"
}

if [[ $# -ne 1 ]]; then
  usage
  exit 2
fi

slug="$1"
branch="wt/$slug"
plan_path="work/$slug/plan.md"
root=$(git rev-parse --show-toplevel) || die "not inside a git checkout"
# shellcheck source=/dev/null
source "$HERE/lib/project.sh"
resolve_project
if [[ "$PROJECT_MODE" == registry ]]; then plan_path="$STATE_DIR/work/$slug/plan.md"; fi
cd "$root" || die "cannot cd to repo root: $root"

[[ -f "$plan_path" ]] || die "not a work unit: $slug"

branch_exists=false
if git rev-parse --verify --quiet "$branch" >/dev/null; then
  branch_exists=true
fi

if [[ "$branch_exists" == true && "$PROJECT_MODE" == repo ]]; then
  plan=$(git show "$branch:$plan_path") \
    || die "cannot read plan from $branch:$plan_path"
else
  plan=$(<"$plan_path")
fi

if [[ "$PROJECT_MODE" == repo ]] && has_line 'Code-review verdict: APPROVE' && has_line 'Codex-review verdict: APPROVE'; then
  review=approve
else
  review=pending
fi

unit_dir="$STATE_DIR/work/$slug"
# ponytail: registry stops at review; pr-release will define release and done.
last_released=
if [[ -f work/.last-released ]]; then
  last_released=$(
    awk '
      NR == 1 {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "")
        print
        exit
      }
    ' work/.last-released
  )
fi

if ! has_line 'Plan verdict: APPROVE'; then
  stage=plan
  next_action='finish /1-plan'
elif [[ ! -f "$unit_dir/handoff.md" && ( "$PROJECT_MODE" == registry || "$branch_exists" == false ) ]]; then
  stage=implement
  next_action='/2-implement'
elif [[ "$review" != approve ]]; then
  stage=review
  if [[ -f "$unit_dir/codex-review.md" ]]; then
    next_action='/3-review'
  else
    next_action='run harness gate'
  fi
elif [[ "$last_released" != "$slug" ]]; then
  stage=release
  next_action='/4-release'
elif [[ ! -s "work/$slug/retro.md" ]]; then
  stage=release
  next_action='/5-retro'
else
  stage='done'
  next_action=none
fi

printf 'slug: %s\n' "$slug"
printf 'stage: %s\n' "$stage"
printf 'review: %s\n' "$review"
printf 'next_action: %s\n' "$next_action"
