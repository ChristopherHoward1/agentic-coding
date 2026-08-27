# Implementer notes — ds-hygiene-hook

Runtime: codex (`implementer.runtime: codex`), single dispatch, fan=1.

## Changed

- `scripts/gate.d/examples/ds-hygiene.sh` — new opt-in hook.
- `tests/test-scripts.sh` — hermetic DS-hygiene fixtures + cases.
- `profiles/machine-learning.md` — REPO_HYGIENE guidance.
- `profiles/work.md` — pointer section to the ML hygiene/notebook sections.
- `ARCHI.md` — four references, incl. check count 76 → 87.

## Verified by the implementer

- `bash tests/test-scripts.sh` → `passed: 87, failed: 0`
- `bash scripts/gate.sh` → `GATE: PASS`
- `bash -n` + `shellcheck` on the new hook and the test file.

## Partial

The implementer could not commit: the codex `workspace-write` sandbox denies writing the
parent repo's git metadata —
`fatal: Unable to create .../.git/worktrees/ds-hygiene-hook/index.lock: Operation not permitted`.
Per `/2-implement` step 6 the Orchestrator committed the (unmodified) tree after
independently re-running the gate in the worktree: `passed: 87, failed: 0`, `GATE: PASS`.

Out-of-scope observations reported: none.
