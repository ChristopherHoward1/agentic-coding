#!/usr/bin/env bash
# Check whether ARCHI.md is at least as fresh as architecture-relevant source paths.
set -uo pipefail

HERE=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)

cd "$(git rev-parse --show-toplevel)" || exit 2

SOURCE_PATHS=(harness/ scripts/ config.yaml CLAUDE.md)

usage() {
  cat <<'EOF'
Usage: harness archi-fresh [<ref>]

Checks ARCHI.md freshness against source paths at <ref>. Defaults to HEAD.
EOF
}

if [[ "${1:-}" == --help || "${1:-}" == -h ]]; then
  usage
  exit 0
fi

if [[ $# -gt 1 ]]; then
  usage >&2
  exit 2
fi

ref="${1:-HEAD}"

# shellcheck source=/dev/null
source "$HERE/lib/project.sh"
resolve_project
if [[ "$PROJECT_MODE" == registry ]]; then
  cd "$PROJECT_ROOT" || exit 2
  SOURCE_PATHS=(.)
  config=
  [[ ! -f "$STATE_DIR/config.yaml" ]] || config=$(<"$STATE_DIR/config.yaml")
else
  config=$(git show "$ref:config.yaml" 2>/dev/null) || config=
fi
sources=$(awk '
    /^[^[:space:]#][^:]*:/ {
      f = ($0 ~ /^archi:[[:space:]]*($|#)/)
      next
    }
    f && /^[[:space:]]*sources:/ {
      sub(/^[[:space:]]*sources:[[:space:]]*/, "")
      sub(/[[:space:]]+#.*$/, "")
      gsub(/^[[:space:]]+|[[:space:]]+$/, "")
      if (($0 ~ /^".*"$/) || ($0 ~ /^'\''.*'\''$/)) {
        sub(/^["'\'']/, "")
        sub(/["'\'']$/, "")
      }
      print
      exit
    }
  ' <<<"$config")
if [[ -n "$sources" ]]; then
  IFS=: read -r -a SOURCE_PATHS <<<"$sources"
fi

if [[ "$PROJECT_MODE" == registry ]]; then
  [[ -f "$STATE_DIR/ARCHI.md" ]] || { echo 'ARCHI.md missing' >&2; exit 2; }
  archi_epoch=$(date -r "$STATE_DIR/ARCHI.md" +%s) || exit 2
else
  archi_epoch=$(git log -1 --format=%ct "$ref" -- ARCHI.md)
fi
source_epoch=$(git log -1 --format=%ct "$ref" -- "${SOURCE_PATHS[@]}")

if [[ -z "$archi_epoch" ]]; then
  echo "ARCHI.md has no git history at $ref" >&2
  exit 2
fi

if [[ -z "$source_epoch" ]]; then
  echo "source paths have no git history at $ref" >&2
  exit 2
fi

if (( archi_epoch < source_epoch )); then
  newer_paths=()
  for path in "${SOURCE_PATHS[@]}"; do
    path_epoch=$(git log -1 --format=%ct "$ref" -- "$path")
    if [[ -n "$path_epoch" && "$path_epoch" -gt "$archi_epoch" ]]; then
      newer_paths+=("$path")
    fi
  done
  printf 'ARCHI.md is stale at %s; newer source path(s): %s; refresh ARCHI on the branch\n' \
    "$ref" "${newer_paths[*]}" >&2
  exit 1
fi
