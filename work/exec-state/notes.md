# Implementer notes — exec-state

- Added `scripts/state.sh`: read-only deriver printing `slug`, `stage`, `review`, `next_action`.
- Added hermetic state fixtures in `tests/test-scripts.sh`: all 7 stage rules, branch-vs-local sentinel read, missing-plan failure, read-only behavior, two-sentinel AND guard.
- Verification: `shellcheck` clean; `bash scripts/gate.sh` → 170 passed, 0 failed.
- `scripts/state.sh exec-state` currently prints `stage: review`, `review: pending`, `next_action: run scripts/gate.sh` (correct: pre-review, no codex-review.md yet).
- Mutation pin: flipped the review AND→OR; suite went red on "state requires both review approval sentinels"; reverted; gate green.
- Could not self-commit (sandbox denied `.git/.../index.lock`); left uncommitted for the orchestrator.
