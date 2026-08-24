#!/usr/bin/env bash
# Release driver. Exit 0 = release staged locally. Non-zero = stop and report.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

usage() {
  cat <<'EOF'
Usage:
  scripts/release.sh <slug> [--confirm-delta <text>]
  scripts/release.sh check-version <new-version> [current-version]
  scripts/release.sh next-version [current-version]

The full release path never pushes. In self-review mode it commits, tags,
fast-forward merges to local main, then stops for the Owner-confirmed push step.
In platform-team mode it commits the bump on the release branch for PR review.
EOF
}

die() {
  echo "release: $*" >&2
  exit 1
}

valid_version() {
  [[ "$1" =~ ^([1-9][0-9]{3})\.([1-9]|1[0-2])\.(0|[1-9][0-9]*)$ ]]
}

version_gt() {
  local new="$1"
  local old="$2"
  local new_year new_month new_micro old_year old_month old_micro

  valid_version "$new" || die "invalid new version '$new' (expected YYYY.M.MICRO)"
  valid_version "$old" || die "invalid current version '$old' (expected YYYY.M.MICRO)"

  IFS=. read -r new_year new_month new_micro <<<"$new"
  IFS=. read -r old_year old_month old_micro <<<"$old"

  if (( new_year > old_year )); then return 0; fi
  if (( new_year < old_year )); then return 1; fi
  if (( new_month > old_month )); then return 0; fi
  if (( new_month < old_month )); then return 1; fi
  (( new_micro > old_micro ))
}

next_version() {
  local current="$1"
  local today year month current_year current_month current_micro

  valid_version "$current" || die "invalid current version '$current' (expected YYYY.M.MICRO)"
  today=$(date +%Y.%-m)
  IFS=. read -r year month <<<"$today"
  IFS=. read -r current_year current_month current_micro <<<"$current"

  if (( year == current_year && month == current_month )); then
    printf '%s.%s.%s\n' "$current_year" "$current_month" "$((current_micro + 1))"
  else
    printf '%s.%s.0\n' "$year" "$month"
  fi
}

extract_release_note() {
  local plan_path="$1"
  local note

  # Release notes are intentionally one line so changelog assembly stays deterministic.
  note=$(
    sed -n -E 's/^\**Release note:\**[[:space:]]*//p' "$plan_path" | head -n 1
  )
  [[ -n "$note" ]] || die "$plan_path is missing a Release note: line"
  printf '%s\n' "$note"
}

prepend_changelog() {
  local version="$1"
  local release_note="$2"
  local confirm_delta="$3"
  local date_stamp
  local tmp

  date_stamp=$(date +%F)
  tmp=$(mktemp)

  {
    if [[ -f CHANGELOG.md ]]; then
      sed -n '1,/^## /{ /^## /q; p; }' CHANGELOG.md
    else
      printf '# Changelog\n\n'
      printf 'All notable changes to this project are documented in this file.\n\n'
    fi
    printf '## [%s] - %s\n\n' "$version" "$date_stamp"
    printf '%s\n' "- $release_note"
    printf '%s\n\n' "- Confirm-delta: $confirm_delta"
    if [[ -f CHANGELOG.md ]]; then
      sed -n '/^## /,$p' CHANGELOG.md
    fi
  } >"$tmp"

  mv "$tmp" CHANGELOG.md
}

check_verdict() {
  local plan_path="$1"
  grep -qx 'Code-review verdict: APPROVE' "$plan_path" \
    || die "$plan_path must contain exact line: Code-review verdict: APPROVE"
}

check_gate() {
  bash scripts/gate.sh || die "scripts/gate.sh failed"
}

check_archi_fresh() {
  local archi_epoch source_epoch

  archi_epoch=$(git log -1 --format=%ct -- ARCHI.md)
  source_epoch=$(git log -1 --format=%ct -- scripts/ skills/ profiles/ config.yaml CLAUDE.md)

  [[ -n "$archi_epoch" ]] || die "ARCHI.md has no git history"
  [[ -n "$source_epoch" ]] || die "source paths have no git history"

  if (( archi_epoch < source_epoch )); then
    die "ARCHI.md is stale; run /compact first"
  fi
}

check_version_exceeds() {
  local new_version="$1"
  local current_version="$2"

  version_gt "$new_version" "$current_version" \
    || die "new version $new_version must exceed VERSION $current_version"
}

worktree_for_branch() {
  local branch="$1"

  git worktree list --porcelain | awk -v branch="refs/heads/$branch" '
    $1 == "worktree" {
      path = substr($0, 10)
      next
    }
    $1 == "branch" && $2 == branch {
      print path
      found = 1
      exit
    }
    END {
      if (!found) exit 1
    }
  '
}

check_clean_worktree() {
  local checkout="$1"
  local label="$2"

  git -C "$checkout" diff --quiet || die "$label has unstaged changes"
  git -C "$checkout" diff --cached --quiet || die "$label has staged changes"
  [[ -z "$(git -C "$checkout" ls-files --others --exclude-standard)" ]] \
    || die "$label has untracked files"
}

check_ff_possible() {
  local main_checkout="$1"
  local release_branch="$2"

  git -C "$main_checkout" rev-parse --verify --quiet "$release_branch" >/dev/null \
    || die "missing release branch: $release_branch"
  git -C "$main_checkout" merge-base --is-ancestor main "$release_branch" \
    || die "main cannot fast-forward to $release_branch"
}

human_pr_review_mode() {
  local mode

  mode=$(awk '/^review:/{f=1;next} f&&/human_pr_review:/{print $2; exit}' config.yaml)
  mode=${mode:-self}
  case "$mode" in
    self|platform-team) printf '%s\n' "$mode" ;;
    *) die "invalid review.human_pr_review '$mode' (expected self or platform-team)" ;;
  esac
}

check_origin_main_ancestor() {
  local release_branch="$1"

  git fetch origin main
  git rev-parse --verify --quiet origin/main >/dev/null \
    || die "missing origin/main after fetch"
  git merge-base --is-ancestor origin/main "$release_branch" \
    || die "$release_branch is stale; rebase/sync your branch onto origin/main"
}

rollback_release() {
  local status=$?
  local pre_release_head="$1"
  local new_version="$2"

  trap - ERR
  set +e
  git tag -d "v$new_version" >/dev/null 2>&1
  git reset --hard "$pre_release_head" >/dev/null 2>&1
  echo "release: irreversible step failed; release commit and tag changes were rolled back" >&2
  exit "$status"
}

release() {
  local slug="$1"
  local confirm_delta="$2"
  local plan_path="work/$slug/plan.md"
  local release_branch="wt/$slug"
  local main_checkout
  local release_checkout
  local current_version
  local new_version
  local release_note
  local pre_release_head
  local review_mode

  main_checkout=$(worktree_for_branch main) \
    || die "main must be checked out in the primary worktree"
  release_checkout=$(worktree_for_branch "$release_branch") \
    || die "$release_branch must be checked out in a linked worktree"

  [[ -f "$release_checkout/$plan_path" ]] || die "missing work unit plan: $plan_path"
  [[ -f "$release_checkout/VERSION" ]] || die "missing VERSION"

  cd "$release_checkout"
  current_version=$(<VERSION)
  new_version=$(next_version "$current_version")
  review_mode=$(human_pr_review_mode)

  check_verdict "$plan_path"
  check_clean_worktree "$release_checkout" "$release_branch"
  check_clean_worktree "$main_checkout" "main checkout"
  if [[ "$review_mode" == self ]]; then
    check_ff_possible "$main_checkout" "$release_branch"
    git rev-parse --verify --quiet "refs/tags/v$new_version" >/dev/null \
      && die "tag v$new_version already exists"
  else
    check_origin_main_ancestor "$release_branch"
  fi
  check_gate
  check_clean_worktree "$release_checkout" "$release_branch"
  check_archi_fresh
  check_version_exceeds "$new_version" "$current_version"
  check_clean_worktree "$main_checkout" "main checkout"
  if [[ "$review_mode" == self ]]; then
    check_ff_possible "$main_checkout" "$release_branch"
  else
    check_origin_main_ancestor "$release_branch"
  fi

  release_note=$(extract_release_note "$plan_path")
  pre_release_head=$(git rev-parse HEAD)
  trap 'rollback_release "$pre_release_head" "$new_version"' ERR

  printf '%s\n' "$new_version" >VERSION
  prepend_changelog "$new_version" "$release_note" "$confirm_delta"

  git add VERSION CHANGELOG.md
  git commit -m "Release v$new_version"
  if [[ "$review_mode" == self ]]; then
    git tag "v$new_version"
    git -C "$main_checkout" merge --ff-only "$release_branch"
  fi
  trap - ERR

  if [[ "$review_mode" == self ]]; then
    cat <<EOF
release: prepared v$new_version on local main
release: stopped before push; push requires Owner confirmation in-session
EOF
  else
    cat <<EOF
release: prepared v$new_version on $release_branch
release: no tag created; local main untouched
release: push $release_branch, open a Bitbucket PR, and have a platform engineer merge it
EOF
  fi
}

if [[ $# -eq 0 ]]; then
  usage
  exit 2
fi

case "$1" in
  check-version)
    [[ $# -eq 2 || $# -eq 3 ]] || { usage; exit 2; }
    current=${3:-$(<VERSION)}
    check_version_exceeds "$2" "$current"
    ;;
  next-version)
    [[ $# -le 2 ]] || { usage; exit 2; }
    next_version "${2:-$(<VERSION)}"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    slug="$1"
    confirm_delta="none"
    shift
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --confirm-delta)
          [[ $# -ge 2 ]] || die "--confirm-delta requires a value"
          confirm_delta="$2"
          shift 2
          ;;
        *)
          usage
          exit 2
          ;;
      esac
    done
    release "$slug" "$confirm_delta"
    ;;
esac
