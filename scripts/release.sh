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

The full release path never pushes. It commits, tags, fast-forward merges to
local main, then stops for the Owner-confirmed push step.
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
  grep -qx 'Verdict: APPROVE' "$plan_path" \
    || die "$plan_path must contain exact line: Verdict: APPROVE"
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

release() {
  local slug="$1"
  local confirm_delta="$2"
  local plan_path="work/$slug/plan.md"
  local branch
  local current_version
  local new_version
  local release_note

  [[ -f "$plan_path" ]] || die "missing work unit plan: $plan_path"
  [[ -f VERSION ]] || die "missing VERSION"

  branch=$(git branch --show-current)
  [[ -n "$branch" ]] || die "cannot release from detached HEAD"

  current_version=$(<VERSION)
  new_version=$(next_version "$current_version")

  check_verdict "$plan_path"
  check_gate
  check_archi_fresh
  check_version_exceeds "$new_version" "$current_version"

  release_note=$(extract_release_note "$plan_path")

  printf '%s\n' "$new_version" >VERSION
  prepend_changelog "$new_version" "$release_note" "$confirm_delta"

  git add VERSION CHANGELOG.md
  git commit -m "Release v$new_version"
  git tag "v$new_version"
  git switch main
  git merge --ff-only "$branch"

  cat <<EOF
release: prepared v$new_version on local main
release: stopped before push; push requires Owner confirmation in-session
EOF
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
