#!/usr/bin/env bash
# Run only the registry release flow under bash 5 with tracing.
set -uo pipefail
ROOT=$1
TMP=$(mktemp -d)
src=$(sed -n '/^# --- Registry state stays outside the work repo./,/^check "registry release and state flow"/p' "$ROOT/harness/tests/test-scripts.sh" | grep -v '^check ')
export ROOT TMP
eval "$src"
bash -e -x -c registry_release_flow 2>&1 | tail -25
echo "rc=${PIPESTATUS[0]}"
