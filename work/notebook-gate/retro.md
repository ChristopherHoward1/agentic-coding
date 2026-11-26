# Retro: notebook-gate (v2026.11.7)

1. **What did the gate miss that a reviewer caught?**
   - **Codex HIGH in round 1: gate continuation.** `gate.sh` keeps running hooks after one fails, so the plan's promise that drift fails before a notebook runs wasn't enforced. Plan review missed it.
   - **Three vacuous tests caught by the code-reviewer's mutations:** the override, `out_dir` and the pyarrow note. This happened even though the handoff cited `knowledge/test-helper-contract.md`.
   - **Routing:** `not worth keeping`. The coordination is now in code (`nb-exec` runs a sibling `data-contract.sh` first) and in ARCHI. Vacuous tests are what mutation review exists to catch, and it caught all three in one round.
2. **What did every check miss?** Nothing known. One MEDIUM, ragged CSV rows, is deferred with its reasoning. → `not worth keeping`.
3. **What got re-derived that a doc would have prevented?**
   - **Different `python3` in the implementer's sandbox.** It lacked pyarrow, so codex reported the pyarrow case as unable to run. The orchestrator re-checked locally.
   - **Routing:** `not worth keeping`. The case reports whether it ran or skipped, so the gate output now shows which environment ran it.
4. **What friction repeated from a prior retro?**
   - **Review latency:** fixed by `TEST_FILTER` (#95). Code-review rounds took about 15 and 9 minutes, against 20–100 before.
   - **ARCHI staleness after a followup:** healed before each round, per the 2026-11-25 decision.
   - **Routing:** `not worth keeping`. Both fixes worked as intended.
