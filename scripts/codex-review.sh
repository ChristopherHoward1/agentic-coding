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

reviewer_command=$(
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
      if ($0 ~ /^'\''/) {
        sub(/^'\''/, "")
        sub(/'\''[[:space:]]*$/, "")
      } else {
        sub(/[[:space:]]*#.*$/, "")
      }
      print
      found = 1
      exit
    }
    END {
      if (!found) exit 1
    }
  ' <<<"$config"
) || die2 "reviewer.command missing in $branch:config.yaml"

[[ -n "$reviewer_command" ]] || die2 "reviewer.command empty in $branch:config.yaml"
[[ -d "$root/work/$slug" ]] || die2 "missing work directory: $root/work/$slug"

prompt=$(mktemp)
trap 'rm -f "$prompt"' EXIT

{
  printf "You are an independent code reviewer for work unit \`%s\`.\n\n" "$slug"
  printf 'Review the plan body and diff below. Report substantive findings first.\n'
  printf 'Your final line must be exactly one of:\n'
  printf 'Codex verdict: APPROVE\n'
  printf 'Codex verdict: REQUEST CHANGES\n\n'
  printf '%s\n' "--- PLAN ($branch:$plan_path) ---"
} >"$prompt"

git show "$branch:$plan_path" >>"$prompt" \
  || die2 "cannot read plan from $branch:$plan_path"

printf '\n%s\n' "--- DIFF (main...$branch) ---" >>"$prompt"
git diff "main...$branch" >>"$prompt" \
  || die2 "cannot diff main...$branch"

bash -c "$reviewer_command" <"$prompt" >"$artifact"
reviewer_status=$?
if [[ "$reviewer_status" -ne 0 ]]; then
  die2 "reviewer command failed (exit $reviewer_status)"
fi

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
