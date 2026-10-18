#!/usr/bin/env bash
# Link this harness into the user's command and Claude Code directories.
set -euo pipefail

usage() { echo 'Usage: harness install'; }
if [[ $# -eq 1 && ( "$1" == --help || "$1" == -h ) ]]; then
  usage
  exit 0
fi
if [[ $# -ne 0 ]]; then
  usage >&2
  exit 2
fi
HERE=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd -P "$HERE/.." && pwd)
claude_dir=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
sources=("$root/bin/harness")
targets=("$HOME/.local/bin/harness")
for source in "$root"/skills/*/ "$root"/agents/*.md; do
  source=${source%/}
  if [[ -d "$source" ]]; then
    target="$claude_dir/skills/${source##*/}"
  else
    target="$claude_dir/agents/${source##*/}"
  fi
  sources+=("$source")
  targets+=("$target")
done
conflict=0
for target in "${targets[@]}"; do
  if [[ -e "$target" && ! -L "$target" ]]; then
    echo "Error: refusing to replace non-symlink: $target" >&2
    conflict=1
  fi
done
[[ $conflict -eq 0 ]] || exit 1
# ponytail: removed entries leave old links; add explicit pruning when entries are removed.
for ((i=0; i<${#sources[@]}; i++)); do
  mkdir -p "$(dirname "${targets[$i]}")"
  ln -sfn "${sources[$i]}" "${targets[$i]}"
  printf '%s -> %s\n' "${targets[$i]}" "${sources[$i]}"
done
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) echo "Note: add $HOME/.local/bin to PATH" >&2 ;;
esac
