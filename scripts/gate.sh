#!/usr/bin/env bash
# The gate. Exit 0 = pass. Non-zero = fail, and everything printed is the
# feedback the implementer gets. Agents do not overrule this script.
#
# Auto-detects the stacks present and runs every applicable check.
# Profile- or project-specific checks go in scripts/gate.d/*.sh (run last).
set -uo pipefail

cd "$(git rev-parse --show-toplevel)" || exit 1

fail=0
run() {
  echo "▶ $*"
  if ! "$@"; then
    fail=1
    echo "✗ FAILED: $*"
  fi
}

# --- Node ---------------------------------------------------------------
if [[ -f package.json ]] && command -v node >/dev/null; then
  for s in lint typecheck test; do
    if node -e "process.exit(require('./package.json').scripts?.['$s'] ? 0 : 1)" 2>/dev/null; then
      run npm run --silent "$s"
    fi
  done
fi

# --- Python -------------------------------------------------------------
if [[ -f pyproject.toml || -f setup.py || -f requirements.txt ]]; then
  command -v ruff >/dev/null && run ruff check .
  if command -v pytest >/dev/null && compgen -G "tests/*" >/dev/null; then
    run pytest -q
  fi
fi

# --- Shell --------------------------------------------------------------
if command -v shellcheck >/dev/null; then
  shell_files=()
  while IFS= read -r f; do shell_files+=("$f"); done \
    < <(git ls-files '*.sh' 2>/dev/null)
  [[ ${#shell_files[@]} -gt 0 ]] && run shellcheck "${shell_files[@]}"
fi

# --- Rust / Go ----------------------------------------------------------
[[ -f Cargo.toml ]] && command -v cargo >/dev/null && { run cargo clippy -q -- -D warnings; run cargo test -q; }
[[ -f go.mod ]] && command -v go >/dev/null && { run go vet ./...; run go test ./...; }

# --- Profile / project extensions ---------------------------------------
for hook in scripts/gate.d/*.sh; do
  [[ -f "$hook" ]] && run bash "$hook"
done

if [[ $fail -eq 0 ]]; then
  echo "GATE: PASS"
else
  echo "GATE: FAIL — fix everything marked ✗ above."
fi
exit $fail
