#!/usr/bin/env bash
set -euo pipefail
usage() { echo 'Usage: harness register [--name <name>] [--subdir <path>]'; }
die() { echo "register: $*" >&2; exit 1; }
name='' subdir=''
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name|--subdir)
      [[ $# -ge 2 ]] || die "$1 requires a value"
      if [[ "$1" == --name ]]; then name=$2; else subdir=$2; fi
      shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 1 ;;
  esac
done
HERE=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=/dev/null
source "$HERE/lib/project.sh"
resolve_project
cd "$GIT_ROOT"
[[ "$(git rev-parse --git-dir)" == "$(git rev-parse --git-common-dir)" ]] || die 'must run from the primary checkout'
case "$subdir" in /*|*..*) die 'subdir must be relative and contain no ..' ;; esac
subdir=${subdir%/}
[[ -d "$GIT_ROOT${subdir:+/$subdir}" ]] || die 'subdir must be an existing directory'
name=${name:-${PRIMARY_ROOT##*/}${subdir:+-${subdir//\//-}}}
[[ "$name" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || die 'invalid name; use --name'
state="$HARNESS_HOME/projects/$name"
local_md="$GIT_ROOT${subdir:+/$subdir}/CLAUDE.local.md"
expected="@$state/CLAUDE.md"
if [[ "$PROJECT_MODE" == registry && ( "$STATE_DIR" != "$state" || "$PROJECT_SUBDIR" != "$subdir" ) ]]; then
  die 'remove the existing entry, its CLAUDE.local.md and exclude line by hand first'
fi
[[ ! -e "$state" || "$STATE_DIR" == "$state" ]] || die 'name already used by another root; use --name'
[[ -z "$(git ls-files -- "${subdir:+$subdir/}CLAUDE.local.md")" ]] || die 'CLAUDE.local.md is tracked'
if [[ -e "$local_md" ]]; then
  [[ "$(cat "$local_md")" == "$expected" && "$(wc -l <"$local_md")" -eq 1 ]] || die 'foreign CLAUDE.local.md'
fi
mkdir -p "$state/work" "$state/knowledge"
printf 'root=%s\nsubdir=%s\n' "$PRIMARY_ROOT" "$subdir" >"$state/project"
harness_root=$(cd -P "$HERE/.." && pwd)
printf '@%s/CONSTITUTION.md\n@%s/ARCHI.md\n@%s/PLAN.md\n\nThis project runs in registry mode. Its harness files live in %s; nothing harness-related is committed to the repository.\n' "$harness_root" "$state" "$state" "$state" >"$state/CLAUDE.md"
printf '%s\n' "$expected" >"$local_md"
exclude=$(git rev-parse --git-path info/exclude)
mkdir -p "${exclude%/*}"
line="/${subdir:+$subdir/}CLAUDE.local.md"
if [[ ! -f "$exclude" ]] || ! grep -qxF "$line" "$exclude"; then printf '\n%s\n' "$line" >>"$exclude"; fi
echo "$state"
echo "Owner: run /add-dir $state or add it to permissions.additionalDirectories" >&2
