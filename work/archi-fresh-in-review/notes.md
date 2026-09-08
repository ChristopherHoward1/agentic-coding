# Implementer notes — archi-fresh-in-review

- Added `scripts/archi-fresh.sh`: ref-aware ARCHI freshness check, strict `<` stale semantics, `--help`, exit 0/1/2, newer-path reporting.
- `scripts/release.sh` `check_archi_fresh` now delegates to `scripts/archi-fresh.sh`.
- `skills/3-review/SKILL.md`: post-APPROVE freshness/heal loop + explicit re-review exemption.
- `tests/test-scripts.sh`: hermetic cases (fresh, stale, equal-epoch, explicit ref, missing-history exit 2, help), existing release stale-ARCHI refusal preserved.

Verification (implementer): shellcheck clean; `bash tests/test-scripts.sh` → passed 181, failed 0; `bash scripts/gate.sh` → GATE: PASS.

Could not commit: sandbox blocked writing the worktree git index (`index.lock: Operation not permitted`). Orchestrator to commit.

Dogfood confirmed: `bash scripts/archi-fresh.sh HEAD` reports stale for `scripts/` — expected; the `/3-review` heal step will add the ARCHI line for `archi-fresh.sh`.
