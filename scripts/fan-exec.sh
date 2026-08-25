#!/usr/bin/env bash
# Deterministic best-of-N implementer fan-out.
# Usage:
#   scripts/fan-exec.sh dispatch <slug> <handoff> <N>
#   scripts/fan-exec.sh adopt <slug> <sample-branch>
set -uo pipefail

ROOT=$(git rev-parse --show-toplevel) || exit 1
cd "$ROOT" || exit 1

usage() {
  echo "usage: fan-exec.sh {dispatch <slug> <handoff> <N>|adopt <slug> <sample-branch>}" >&2
  exit 1
}

worktree_dir() {
  awk '/^worktrees:/{f=1;next} f&&/dir:/{print $2; exit}' config.yaml
}

sample_ref() {
  local sample="$1"
  if [[ "$sample" == wt/* ]]; then
    printf '%s\n' "$sample"
  else
    printf 'wt/%s\n' "$sample"
  fi
}

seed_work_dir() {
  local slug="$1"
  local wt="$2"

  if [[ -d "$ROOT/work/$slug" ]]; then
    mkdir -p "$wt/work"
    rm -rf "$wt/work/$slug"
    cp -R "$ROOT/work/$slug" "$wt/work/" || {
      echo "Error: failed to seed work/$slug into $wt" >&2
      exit 1
    }
  fi
}

dispatch() {
  local slug="${1:-}"
  local handoff="${2:-}"
  local n="${3:-}"
  local k wt branch gate_status
  local passers=()

  [[ -n "$slug" && -n "$handoff" && -n "$n" ]] || usage
  [[ "$n" =~ ^[1-9][0-9]*$ ]] || { echo "Error: N must be a positive integer" >&2; exit 1; }
  [[ -s "$handoff" ]] || { echo "Error: handoff missing or empty: $handoff" >&2; exit 1; }

  for ((k = 1; k <= n; k++)); do
    branch="wt/$slug-fan-$k"
    wt=$(scripts/worktree.sh add "$slug-fan-$k") || exit 1
    seed_work_dir "$slug" "$wt"

    if scripts/agent-exec.sh "$wt" "$handoff"; then
      (
        cd "$wt" || exit 1
        bash scripts/gate.sh
      )
      gate_status=$?
    else
      gate_status=$?
    fi

    if [[ $gate_status -eq 0 ]]; then
      passers+=("$branch")
    else
      echo "fan sample failed gate: $branch" >&2
    fi
  done

  if [[ ${#passers[@]} -gt 0 ]]; then
    printf '%s\n' "${passers[@]}"
  fi
}

adopt() {
  local slug="${1:-}"
  local sample="${2:-}"
  local sample_branch wt_dir wt_path ref branch
  local branches=()

  [[ -n "$slug" && -n "$sample" ]] || usage
  sample_branch=$(sample_ref "$sample")
  git show-ref --verify --quiet "refs/heads/$sample_branch" || {
    echo "Error: sample branch not found: $sample_branch" >&2
    exit 1
  }

  git branch -f "wt/$slug" "$sample_branch" || exit 1
  scripts/worktree.sh add "$slug" >/dev/null || exit 1

  wt_dir=${WORKTREES_DIR:-$(worktree_dir)}
  wt_dir=${wt_dir:-../$(basename "$ROOT")-worktrees}
  for wt_path in "$wt_dir"/"$slug"-fan-*; do
    [[ -e "$wt_path" ]] || continue
    git worktree remove "$wt_path" || exit 1
  done

  while IFS= read -r ref; do
    branch=${ref#refs/heads/}
    branches+=("$branch")
  done < <(git for-each-ref --format='%(refname)' "refs/heads/wt/$slug-fan-*")

  if [[ ${#branches[@]} -gt 0 ]]; then
    git branch -D "${branches[@]}" || exit 1
  fi
}

cmd="${1:-}"
case "$cmd" in
  dispatch)
    shift
    dispatch "$@"
    ;;
  adopt)
    shift
    adopt "$@"
    ;;
  *)
    usage
    ;;
esac
