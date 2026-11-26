The implementer contract precedes this handoff — it is your contract.
Follow its build-discipline section while staying inside the plan footprint.

Work unit: /Users/cboyfly/Documents/repos/agentic-coding/work/notebook-gate/plan.md (read it in full; its Approach is the spec and its Acceptance criteria are the test list — implement every criterion as a test case)
Branch: wt/notebook-gate (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
- `harness/examples/gate.d/nb-exec.sh` (new)
- `harness/examples/gate.d/data-contract.sh` (new)
- `harness/tests/test-scripts.sh` (new cases only)
- `harness/profiles/machine-learning.md`
- `harness/profiles/work-slim.md`
- `harness/profiles/work.md` (lines 22 and 63)
- `ARCHI.md`

Every edit the plan names is authorized; stop only for an edit outside the footprint.
Nothing is committed while you work, so reads through `HEAD` (`git archive`, `git show HEAD:…`) will not see your changes.

Key constraints:
- Before writing any test, read `/Users/cboyfly/Documents/repos/agentic-coding/knowledge/test-helper-contract.md` (Decision 2026-11-26):
  - macOS `/bin/bash` is 3.2, so every non-final assertion needs `|| return 1` (or `|| exit 1`).
  - `check_exit` greps stderr only.
  - When a case needs two substrings, use the inline form the plan names.
  - Fixtures must be rich enough that each listed mutation actually fails a case.
- Test descriptions start with `nb-exec` or `data-contract`, so `TEST_FILTER='nb-exec|data-contract'` selects them.
- Follow the existing example-hook style: settings as env vars with in-file defaults, and `set -uo pipefail`. Unlike `nb-clean.sh`, the new hooks do NOT `cd` to the git toplevel; they run from the gate's cwd (the project root).
- Embed the data-contract check as a `python3 -I` heredoc inside the bash hook, using only the stdlib plus an optional lazy `import pyarrow`.
- Never write under the repo from either hook. In tests, set `TMPDIR` under the suite's `$TMP`.
- All shell must pass shellcheck. Leave `gate.sh`, `nb-clean.sh`, `ds-hygiene.sh`, `README.md`, `PLAN.md`, `config.yaml` and `work/` alone.

When done:
1. Run harness gate from the repo root — it must pass.
2. Print a final summary: what changed and why, each acceptance criterion with the test case that covers it, criteria partially met (if any), out-of-scope observations.
