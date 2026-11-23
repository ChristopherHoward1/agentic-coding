# Implementer summary

Updated both notebook-writing rules to allow a short descriptive read and reserve an Owner cell for each question. Updated the `ARCHI.md` profile description to match.

`harness gate` passed, and the text, indentation, numbering and count checks passed. **One acceptance criterion remains unverified:** `harness archi-fresh wt/notebook-owner-room` reports the committed branch as stale because it cannot see the uncommitted `ARCHI.md` edit. The orchestrator should rerun it after committing.

Out of scope: the `work` profile does not reference the notebook-writing rule, as noted in the plan.

# Gate

GATE: PASS (orchestrator, in worktree)

# Demo

demo: none — prose-only change to profile guidance; there is no runnable behavior. (exit 0)
