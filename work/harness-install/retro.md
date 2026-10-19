# Retro — harness-install (v2026.10.5)

1. **What did the gate miss that a reviewer caught?**
   - Neither code reviewer raised a blocking finding: both approved in round 1, with three LOWs. The catches came in plan review, which took 3 rounds and 19 findings. Two would have broken the gate anyway: the fan-exec fixture needing a stub `AGENTS.md`, and `test-scripts.sh:885` running through a deleted forwarder. One the gate could never have seen: the plan committed the roadmap edit on local `main`, which would have broken `/4-release`'s `--ff-only` pull and left the repo with no skills after the `.claude/` symlinks were deleted. → **process**: the 2026-09-08 clean-`main` Decision in `PLAN.md` now also covers local commits on `main`.
2. **What did every check miss?**
   - The orchestrator's discovery check used `timeout`, which macOS doesn't have; it failed once with exit 127. → **not worth keeping**: a one-off typo-grade slip, fixed on the spot, and the check passed on the re-run.
3. **What got re-derived that a doc would have prevented?**
   - Nothing. The `codex-worktree-commit` recovery recipe was copied straight from its `PLAN.md` candidate into the handoff, and it worked the first time. → **not worth keeping** as a separate lesson; see 4.
4. **What friction repeated from a prior retro?**
   - The codex sandbox couldn't write git metadata, for the seventh unit in a row. This time, stating the recipe in the handoff up front cost no extra dispatches: one dispatch, zero gate retries, and the orchestrator staged, committed and ran the demo. → **process**: the `codex-worktree-commit` candidate in `PLAN.md` now records that the recipe works and names the fix: `handoff.tpl` states it by default and `/2-implement` owns staging and the commit. That's a `harness/` change, so it becomes a `/1-plan` unit (`codex-worktree-commit`), not a change in this retro.
