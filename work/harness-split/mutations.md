# Dispatcher mutation pins

Ran the actual dispatcher cases extracted from `harness/tests/test-scripts.sh`, with its unchanged check helpers, ROOT setup, and dispatcher fixture. Each mutation was applied individually to `harness/bin/harness`, verified with `grep -nF`, run, then restored. The restored cases all pass (exit 0).

| Mutation | Landed verification | Named failing case | Result |
|---|---|---|---|
| Remove the entire symlink-resolution loop | `grep -nF 'while [[ -L' harness/bin/harness` exits 1 | dispatcher (a): symlink chain resolves root and demo help outside repo | FAIL; runner exits 1 |
| Replace unknown-name fallback with `exit 0` | `grep -nF '|| exit 0' harness/bin/harness` prints line 31 | dispatcher (b): unknown name | exit 0, expected 2; runner exits 1 |
| Remove the name regex check | `grep -nF '^[a-z-]+$' harness/bin/harness` exits 1 | dispatcher (b): traversal name | exit 0, expected 2; runner exits 1 |

The traversal fixture includes a real `x.sh` outside `scripts/` that exits 0. This isolates the regex guard from the unknown-file guard, avoiding a vacuous rejection. The symlink case uses an absolute first link and relative second link outside any repository.

## Sandbox pre-checks

- Explicit footprint-wide shellcheck: PASS, including the extensionless dispatcher.
- `bash harness/tests/test-scripts.sh`: 204 passed, 1 failed. The sole failure is `gate.sh runs on this repo`; direct diagnosis with `TEST_SCRIPTS_RUNNING=1 bash harness/bin/harness gate` shows shellcheck reading old moved paths from the unchanged index (for example `scripts/agent-exec.sh` and `tests/test-scripts.sh`). All dispatcher cases pass.
- `bash tests/test-export.sh`: 0 passed, 12 failed. Exposing the existing fixture diagnostics without modifying the suite confirms `fixture` aborts while copying indexed `profiles/database.md`, which has moved to `harness/profiles/database.md`. Every case uses this fixture. No export/sync implementation or fixture workaround was added; rerun after orchestrator staging.
- Reference acceptance greps and `git diff --check`: PASS. Symlinks resolve to the three agent files; direct demo forwarder help prints `Usage: harness demo <slug> [<dir>]`.
- Commit, clean-tree demo, index modes/history, full green gate, and fresh Claude agent discovery remain orchestrator checks under Dispatch 2.

## Round-1 review: directory invocation regression

Added the named case `command references avoid bash harness directory invocation`. It runs `grep -rnE 'bash harness( |$)'` against the requested skills, agents, profiles, constitution, ARCHI and README paths under `$ROOT`, requiring exit 1 (no matches).

Reintroduced `bash harness release <slug>` in `harness/skills/4-release/SKILL.md`. Verified the mutation landed with `grep -nE 'bash harness( |$)' harness/skills/4-release/SKILL.md`, which printed line 12. Ran the actual new case extracted from the suite with its unchanged helpers and ROOT setup: it failed with `exit 0, expected 1`, and the runner exited 1. Restored the file; the same case passed and the runner exited 0.

Round-1 review pre-checks on `wt/harness-split`:
- Requested footprint-wide shellcheck: PASS.
- `bash harness/tests/test-scripts.sh`: 206 passed, 0 failed, including the new reference check and self-gate.
- `bash tests/test-export.sh`: 12 passed, 0 failed.
- Diagnostic `TEST_SCRIPTS_RUNNING=1 bash harness/bin/harness gate`: PASS (suite recursion skipped).
- `git diff --check`: PASS. No index-dependent failures this round.
- No worktree index writes, staging, commits or demo runs performed; full gate and demo remain with the orchestrator as dispatched.
