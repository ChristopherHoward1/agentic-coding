# shellcheck shell=bash
stack_parent() {
  local slug="$1" plan
  if [[ "$PROJECT_MODE" == repo ]] && git cat-file -e "wt/$slug:work/$slug/plan.md" 2>/dev/null; then
    plan=$(git show "wt/$slug:work/$slug/plan.md") || return 2
  else
    local root="$PRIMARY_ROOT"
    [[ "$PROJECT_MODE" != registry ]] || root=$STATE_DIR
    [[ -f "$root/work/$slug/plan.md" ]] || return 0
    plan=$(cat "$root/work/$slug/plan.md") || return 2
  fi
  awk '/^## / {exit} /^Stacked on: [a-z0-9-]+$/ {print substr($0,13); exit}' <<<"$plan"
}

stack_fork() {
  git merge-base --fork-point "wt/$2" "wt/$1"
}

review_base() {
  local slug="$1" parent mainref=main fork status ref plan wt
  git fetch origin --quiet 2>/dev/null || true
  if git show-ref --verify --quiet refs/remotes/origin/main; then mainref=origin/main; fi
  parent=$(stack_parent "$slug") || return 2
  if [[ -z "$parent" ]]; then printf '%s\n' "$mainref"; return 0; fi
  plan="wt/$slug:work/$slug/plan.md and commit that in the worktree"
  if [[ "$PROJECT_MODE" == registry ]]; then
    plan="$STATE_DIR/work/$slug/plan.md"
  elif ! git cat-file -e "wt/$slug:work/$slug/plan.md" 2>/dev/null; then
    plan="$PRIMARY_ROOT/work/$slug/plan.md"
  fi
  if ! git show-ref --verify --quiet "refs/heads/wt/$parent"; then
    echo "wt/$parent missing; if $parent has landed, delete the Stacked on: line from $plan" >&2
    return 2
  fi
  git show-ref --verify --quiet "refs/heads/wt/$slug" || { echo "wt/$slug missing" >&2; return 2; }
  if fork=$(stack_fork "$slug" "$parent"); then :; else
    status=$?
    [[ "$status" -eq 1 ]] || return 2
    printf '%s\n' "$mainref"
    return 0
  fi
  for ref in "$mainref" "wt/$parent"; do
    if git merge-base --is-ancestor "$fork" "$ref"; then
      printf '%s\n' "$ref"
      return 0
    else
      status=$?
      [[ "$status" -eq 1 ]] || return 2
    fi
  done
  wt=$(git worktree list --porcelain | awk -v branch="refs/heads/wt/$slug" '/^worktree / {path=substr($0,10)} $1 == "branch" && $2 == branch {print path; exit}') || return 2
  printf '%s\n' "$fork"
  if [[ -n "$wt" ]]; then
    echo "note: $parent was rewritten since $slug branched; to pick it up: git -C $(printf '%q' "$wt") rebase --onto wt/$parent $fork" >&2
  else
    echo "note: $parent was rewritten since $slug branched; to pick it up, recreate the worktree (harness worktree add $slug) and re-run harness worktree base $slug" >&2
  fi
}
