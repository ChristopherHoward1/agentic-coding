# Retro: codex-worktree-commit (v2026.10.8)

Shipped: `harness agent-exec` commits whatever a successful dispatch leaves, `/2-implement` runs the demo itself, and the gate lints the working tree. That makes the recipe from nine handoffs in a row the default.
- **Plan review:** three rounds, then Owner approval over a round-3 REVISE with no CRITICAL or HIGH findings.
- **Implementation:** one dispatch, zero gate retries.
- **Code review:** both reviewers approved in round 1, with LOW findings only.

1. **What did the gate miss that a reviewer caught?**
   - Plan review caught the one defect that would have cost a dispatch. A naive `add -A` in agent-exec would have swept fan's seeded `work/<slug>/` into every sample commit, which would have broken two fan tests.
   - It also caught one defect no gate could see. A dirtying demo would have been committed by the next followup's auto-commit, and the re-run demo would then have passed.
   - → **not worth keeping:** both are fixed in this unit, the first by the `work/` exclusion and the second by `/2-implement` escalating a dirtying demo.
2. **What did every check miss?**
   - Nothing surfaced after release.
   - Both code reviewers flagged the orchestrator's `PLAN.md` "In progress" line as a footprint LOW. → **not worth keeping:** it cost no round, and the 2026-09-08 Decision already says why it's on the branch.
3. **What got re-derived that a doc would have prevented?**
   - Nothing. → **not worth keeping.**
4. **What friction repeated from a prior retro?**
   - **`codex-worktree-commit` itself, ten units running.** This unit was dispatched with the hand-written recipe one last time, and it worked first try again. → **mechanical, applied by this unit:** the `PLAN.md` candidate is retired.
   - **`demo-fail-fast`.** The plan's demo again needed `|| exit 1` on each check. → **mechanical:** it stays a `PLAN.md` candidate, since a fix would touch `harness/`.
