#!/usr/bin/env bash
# Manage isolated implementation worktrees.
# Usage:
#   scripts/worktree.sh add <slug>      # create worktree + branch wt/<slug>, print its path
#   scripts/worktree.sh remove <slug>   # remove worktree, keep the branch
#   scripts/worktree.sh list
set -euo pipefail

ROOT=$(git rev-parse --show-toplevel)
cd "$ROOT"

# Naive-but-sufficient config read; override with WORKTREES_DIR env var.
WT_DIR=${WORKTREES_DIR:-$(awk '/^worktrees:/{f=1;next} f&&/dir:/{print $2; exit}' config.yaml)}
WT_DIR=${WT_DIR:-../$(basename "$ROOT")-worktrees}

cmd=${1:-}
slug=${2:-}

case "$cmd" in
  add)
    [[ -n "$slug" ]] || { echo "usage: worktree.sh add <slug>" >&2; exit 1; }
    mkdir -p "$WT_DIR"
    path="$WT_DIR/$slug"
    [[ -e "$path" ]] && { echo "Error: $path already exists" >&2; exit 1; }
    if git show-ref --verify --quiet "refs/heads/wt/$slug"; then
      git worktree add "$path" "wt/$slug" >&2
    else
      git worktree add -b "wt/$slug" "$path" >&2
    fi
    # stdout carries only the path, so callers can capture it
    cd "$path" && pwd -P
    ;;
  remove)
    [[ -n "$slug" ]] || { echo "usage: worktree.sh remove <slug>" >&2; exit 1; }
    git worktree remove "$WT_DIR/$slug"
    echo "Removed worktree. Branch wt/$slug kept; delete with: git branch -D wt/$slug" >&2
    ;;
  list)
    git worktree list
    ;;
  *)
    echo "usage: worktree.sh {add|remove|list} [slug]" >&2
    exit 1
    ;;
esac
