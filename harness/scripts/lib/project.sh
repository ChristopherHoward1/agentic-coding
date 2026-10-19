# shellcheck shell=bash
# shellcheck disable=SC2034
resolve_project() {
  local entry key value root subdir resolved matches=0 names=
  GIT_ROOT=$(git -C "${1:-.}" rev-parse --show-toplevel) || exit 2
  PRIMARY_ROOT=$(git -C "${1:-.}" worktree list --porcelain | awk '/^worktree / {print substr($0,10); exit}') || exit 2
  PRIMARY_ROOT=$(cd -P "$PRIMARY_ROOT" && pwd) || exit 2
  HARNESS_HOME=${HARNESS_HOME:-$HOME/.harness}
  PROJECT_MODE=repo
  STATE_DIR=$GIT_ROOT
  PROJECT_SUBDIR=
  PROJECT_ROOT=$GIT_ROOT
  for entry in "$HARNESS_HOME"/projects/*/project; do
    [[ -f "$entry" ]] || continue
    root='' subdir=''
    while IFS='=' read -r key value || [[ -n "$key" ]]; do
      case "$key" in root) root=$value ;; subdir) subdir=$value ;; esac
    done <"$entry"
    [[ -n "$root" ]] || continue
    if resolved=$(cd -P "$root" 2>/dev/null && pwd); then
      [[ "$resolved" == "$PRIMARY_ROOT" ]] || continue
    else
      continue
    fi
    matches=$((matches + 1))
    names="$names ${entry%/project}"
    STATE_DIR=${entry%/project}
    PROJECT_SUBDIR=$subdir
  done
  # ponytail: one project per repo; add multi-project selection when real use asks.
  if (( matches > 1 )); then
    echo "project: multiple registry entries:$names" >&2
    exit 2
  fi
  if (( matches == 1 )); then
    PROJECT_MODE=registry
    PROJECT_ROOT=$GIT_ROOT${PROJECT_SUBDIR:+/$PROJECT_SUBDIR}
    [[ -d "$PROJECT_ROOT" ]] || { echo "project: missing project root: $PROJECT_ROOT" >&2; exit 2; }
  fi
}
