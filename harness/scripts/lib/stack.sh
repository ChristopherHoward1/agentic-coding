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
  awk '
    /^## / {exit}
    { lines[NR]=$0 }
    /^Stacked on: [a-z0-9-]+$/ {print substr($0,13); found=1; exit}
    END {
      if (!found) for (i=1; i<=NR; i++) {
        line=lines[i]; clean=line
        gsub(/[*_]/, "", clean); sub(/^[[:space:]]*/, "", clean)
        if (tolower(clean) ~ /^stacked[[:space:]]*on([^a-z]|$)/)
          printf "warning: ignoring near-miss stack line \"%s\"; expected: Stacked on: <slug>\n", line > "/dev/stderr"
      }
    }' <<<"$plan"
}

stack_fork() {
  git merge-base --fork-point "wt/$2" "wt/$1"
}

integration_branch() {
  [[ -f "$STATE_DIR/config.yaml" ]] || return 0
  local branch
  branch=$(awk '/^integration_branch:/{print $2; exit}' "$STATE_DIR/config.yaml")
  case "$branch" in \"*\"|\'*\') branch=${branch:1:${#branch}-2} ;; esac
  printf '%s\n' "$branch"
}

integration_ref() {
  local branch
  branch=$(integration_branch)
  [[ -n "$branch" && "$branch" != main ]] || return 1
  if ! git check-ref-format --branch "$branch" >/dev/null 2>&1; then
    echo "invalid integration_branch: $branch" >&2; return 2
  fi
  git fetch origin --quiet 2>/dev/null || true
  if ! git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    echo "integration_branch $branch has no origin/$branch ref" >&2; return 2
  fi
  printf 'origin/%s\n' "$branch"
}

review_base() {
  local slug="$1" parent mainref=main fork status ref plan wt
  git fetch origin --quiet 2>/dev/null || true
  if git show-ref --verify --quiet refs/remotes/origin/main; then mainref=origin/main; fi
  if ref=$(integration_ref); then mainref=$ref; else status=$?; [[ "$status" -eq 1 ]] || return "$status"; fi
  parent=$(stack_parent "$slug") || return 2
  if [[ -z "$parent" ]]; then printf '%s\n' "$mainref"; return 0; fi
  plan="wt/$slug:work/$slug/plan.md and commit that in the worktree"
  if [[ "$PROJECT_MODE" == registry ]]; then
    plan="$STATE_DIR/work/$slug/plan.md"
  elif ! git cat-file -e "wt/$slug:work/$slug/plan.md" 2>/dev/null; then
    plan="$PRIMARY_ROOT/work/$slug/plan.md"
  fi
  wt=$(git worktree list --porcelain | awk -v branch="refs/heads/wt/$slug" '/^worktree / {path=substr($0,10)} $1 == "branch" && $2 == branch {print path; exit}') || return 2
  if ! git show-ref --verify --quiet "refs/heads/wt/$parent"; then
    local remedy=""
    [[ -z "$wt" ]] || remedy="; its fork point is gone, so drop the parent's commits by hand first: git -C $(printf '%q' "$wt") rebase -i $mainref"
    echo "wt/$parent missing; if $parent has landed, delete the Stacked on: line from $plan$remedy" >&2
    return 2
  fi
  git show-ref --verify --quiet "refs/heads/wt/$slug" || { echo "wt/$slug missing" >&2; return 2; }
  if fork=$(stack_fork "$slug" "$parent"); then :; else
    status=$?
    [[ "$status" -eq 1 ]] || return 2
    if [[ -n "$wt" ]]; then
      echo "warning: no fork point for wt/$slug on wt/$parent; the review diff may include the parent's commits; rebase by hand: git -C $(printf '%q' "$wt") rebase -i $mainref" >&2
    else
      echo "warning: no fork point for wt/$slug on wt/$parent; the review diff may include the parent's commits; recreate the worktree (harness worktree add $slug) and re-run harness worktree base $slug" >&2
    fi
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
  printf '%s\n' "$fork"
  if [[ -n "$wt" ]]; then
    echo "note: $parent was rewritten since $slug branched; run: harness worktree restack $slug, or to pick it up: git -C $(printf '%q' "$wt") rebase --onto wt/$parent $fork" >&2
  else
    echo "note: $parent was rewritten since $slug branched; to pick it up, recreate the worktree (harness worktree add $slug) and re-run harness worktree base $slug" >&2
  fi
}

restack() {
  local slug="$1" parent mainref=main ref status wt target fork upstream
  git fetch origin --quiet 2>/dev/null || true
  if git show-ref --verify --quiet refs/remotes/origin/main; then mainref=origin/main; fi
  if ref=$(integration_ref); then mainref=$ref; else status=$?; [[ "$status" -eq 1 ]] || return "$status"; fi
  parent=$(stack_parent "$slug") || return 2
  [[ -n "$parent" ]] || { echo "wt/$slug is not stacked" >&2; return 1; }
  wt=$(worktree_for_branch "wt/$slug") || { echo "no worktree for $slug" >&2; return 1; }
  [[ "$(git -C "$wt" rev-parse --git-dir)" != "$(git -C "$wt" rev-parse --git-common-dir)" ]] || { echo "no worktree for $slug" >&2; return 1; }
  git show-ref --verify --quiet "refs/heads/wt/$parent" || { echo "wt/$parent is gone, so the fork point is lost; drop the parent's commits by hand: git -C $(printf '%q' "$wt") rebase -i $mainref" >&2; return 1; }
  [[ -z "$(git -C "$wt" status --porcelain)" ]] || { echo "$wt has uncommitted changes" >&2; return 1; }
  target="wt/$parent"
  if [[ "$PROJECT_MODE" == repo ]]; then
    if git cat-file -e "$mainref:work/$parent/plan.md" 2>/dev/null; then target=$mainref; fi
  elif git merge-base --is-ancestor "wt/$parent" "$mainref"; then target=$mainref
  else status=$?; [[ "$status" -eq 1 ]] || return 2
  fi
  if fork=$(stack_fork "$slug" "$parent"); then :; else
    status=$?; [[ "$status" -eq 1 ]] || return 2
    echo "no fork point for wt/$slug on wt/$parent; rebase by hand: git -C $(printf '%q' "$wt") rebase -i $target" >&2; return 1
  fi
  if git merge-base --is-ancestor "$target" "wt/$slug"; then
    echo "wt/$slug is already on $target"
    if [[ "$PROJECT_MODE" == registry && "$target" == "wt/$parent" ]]; then
      echo "if $parent was squash- or rebase-merged, drop its commits by hand: git -C $(printf '%q' "$wt") rebase -i $mainref" >&2
    fi
    return 0
  else status=$?; [[ "$status" -eq 1 ]] || return 2; fi
  upstream=$fork
  if git merge-base --is-ancestor "$fork" "$target"; then
    upstream=$(git merge-base "$target" "wt/$slug") || return 2
  else status=$?; [[ "$status" -eq 1 ]] || return 2; fi
  if ! git -C "$wt" rebase --onto "$target" "$upstream"; then
    git -C "$wt" rebase --abort || true
    echo "restack conflicted; aborted. By hand: git -C $(printf '%q' "$wt") rebase --onto $target $upstream" >&2
    return 1
  fi
  echo "restacked wt/$slug onto $target"
  review_base "$slug"
}
