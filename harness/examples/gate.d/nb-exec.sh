#!/usr/bin/env bash
# Opt-in notebook execution gate. Copy to scripts/gate.d/nb-exec.sh to enable.
set -uo pipefail
: "${NB_EXEC_NOTEBOOKS=}" "${NB_EXEC_CELL_TIMEOUT=600}" "${NB_EXEC_KERNEL=}"
[[ -n "$NB_EXEC_NOTEBOOKS" ]] || { echo 'nb-exec: no notebooks listed; skipping'; exit 0; }
command -v papermill >/dev/null 2>&1 || { echo 'nb-exec: papermill not found' >&2; exit 1; }
if [[ -f "$(dirname "$0")/data-contract.sh" ]] && ! bash "$(dirname "$0")/data-contract.sh"; then
  echo 'nb-exec: skipped; data contracts failed' >&2; exit 1
fi
primary=$(git worktree list --porcelain | awk 'NR == 1 {sub(/^worktree /, ""); print; exit}')
prefix=$(git rev-parse --show-prefix) || exit 1
root=${NB_DATA_ROOT:-$primary/$prefix}
root=$(cd -P "$root" 2>/dev/null && pwd) || { echo "nb-exec: no $root in the primary checkout" >&2; exit 1; }
IFS=: read -r -a notebooks <<<"$NB_EXEC_NOTEBOOKS"
failed=0
for nb in "${notebooks[@]}"; do
  if [[ ! -f "$nb" ]]; then
    echo "nb-exec: missing notebook $nb" >&2; failed=1; continue
  fi
  if ! python3 -I - "$nb" <<'PY'
import json, sys
try:
    with open(sys.argv[1], encoding='utf-8') as f:
        notebook = json.load(f)
    sys.exit(not any('parameters' in cell.get('metadata', {}).get('tags', [])
                     for cell in notebook.get('cells', [])))
except (OSError, ValueError, AttributeError, TypeError):
    sys.exit(1)
PY
  then
    echo "nb-exec: $nb has no parameters-tagged cell" >&2; failed=1; continue
  fi
  : "${TMPDIR:=/tmp}"
  tmp=$(mktemp -d "${TMPDIR%/}/nb-exec.XXXXXX") || exit 1
  mkdir -p "$tmp/out"
  args=("$nb" "$tmp/${nb##*/}" --cwd "$(dirname "$nb")" -p data_dir "$root" -p out_dir "$tmp/out" -p smoke 1 --execution-timeout "$NB_EXEC_CELL_TIMEOUT")
  [[ -z "$NB_EXEC_KERNEL" ]] || args+=(-k "$NB_EXEC_KERNEL")
  if papermill "${args[@]}" 2>"$tmp/stderr"; then
    rm -rf "$tmp"
    echo "nb-exec: ok $nb"
  else
    echo "nb-exec: FAILED $nb" >&2
    tail -n 20 "$tmp/stderr" >&2
    echo "nb-exec: kept output $tmp" >&2
    failed=1
  fi
done
exit "$failed"
