#!/usr/bin/env bash
# Run a read-only Codex code review for wt/<slug>. The only write is the
# reviewer stdout artifact in the primary checkout's work/<slug>/ directory.
set -uo pipefail

usage() {
  echo "Usage: scripts/codex-review.sh <slug>" >&2
}

die2() {
  echo "codex-review: $*" >&2
  exit 2
}

if [[ $# -ne 1 ]]; then
  usage
  exit 2
fi

slug="$1"
branch="wt/$slug"
plan_path="work/$slug/plan.md"
root=$(git rev-parse --show-toplevel) || die2 "not inside a git checkout"
artifact="$root/work/$slug/codex-review.md"

git rev-parse --verify --quiet "$branch" >/dev/null \
  || die2 "missing branch: $branch"

config=$(git show "$branch:config.yaml") \
  || die2 "cannot read config.yaml from $branch"

command=$(
  awk '
    /^[^[:space:]#][^:]*:/ {
      if (f) exit
      if ($0 ~ /^reviewer:/) {
        f = 1
      }
      next
    }
    f && /^[[:space:]]*command:/ {
      sub(/^[[:space:]]*command:[[:space:]]*/, "")
      sub(/[[:space:]]*#.*$/, "")
      sub(/^'\''/, "")
      sub(/'\''[[:space:]]*$/, "")
      print
      found = 1
      exit
    }
    END {
      if (!found) exit 1
    }
  ' <<<"$config"
) || die2 "reviewer.command missing in $branch:config.yaml"

[[ -n "$command" ]] || die2 "reviewer.command empty in $branch:config.yaml"
[[ -d "$root/work/$slug" ]] || die2 "missing work directory: $root/work/$slug"

{
  printf "You are an independent code reviewer for work unit \`%s\`.\n\n" "$slug"
  printf 'Review the plan body and diff below. Report substantive findings first.\n'
  printf 'Your final line must be exactly one of:\n'
  printf 'Codex verdict: APPROVE\n'
  printf 'Codex verdict: REQUEST CHANGES\n\n'
  printf '--- PLAN (%s:%s) ---\n' "$branch" "$plan_path"
  git show "$branch:$plan_path" || exit 2
  printf '\n--- DIFF (main...%s) ---\n' "$branch"
  git diff "main...$branch" || exit 2
} | bash -c "$command" >"$artifact"

verdict_line=$(grep -E '^[[:space:]]*Codex verdict:' "$artifact" | tail -n 1 || true)
if [[ -z "$verdict_line" ]]; then
  die2 "no verdict in $artifact"
fi

verdict=${verdict_line#"${verdict_line%%[![:space:]]*}"}
verdict=${verdict#Codex verdict:}
verdict=${verdict#"${verdict%%[![:space:]]*}"}
verdict=${verdict%"${verdict##*[![:space:]]}"}

case "$verdict" in
  APPROVE)
    exit 0
    ;;
  "REQUEST CHANGES")
    exit 1
    ;;
  *)
    die2 "malformed verdict in $artifact: $verdict"
    ;;
esac
