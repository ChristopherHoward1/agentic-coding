# Retro: deferral-sweep (v2026.11.8)

1. **What did the gate miss that a reviewer caught?**
   - **Codex MEDIUM in round 1: the wide-row check from #98 stopped at `DATA_CONTRACT_SCAN_ROWS`.** #98 shipped through the small-fix lane with no review. The released-range review that the 2026-11-23 decision requires caught it, as it caught `/docs` in `template-catchup`.
   - **Routing:** `not worth keeping`. The existing decision did its job, the fix shipped in this unit, and two catches don't call for a new rule.
2. **What did every check miss?** Ledger wording. The code-reviewer's round-2 LOWs: the `':/'` closure line gives v2026.11.7 for #91, which shipped in v2026.11.6, and the #98 closure line overstated what it covered until round 1 fixed it. → `not worth keeping`. These are one-off wording slips, and the version number is fixed as a small fix after this retro (outside the retro file boundary).
3. **What got re-derived that a doc would have prevented?** The shape of a release-only unit: no plan-reviewer round, an Owner approval line, an "In progress" Now line, and the released-range review. It came from `work/template-catchup/plan.md` in one read. → `not worth keeping`. The precedent is a good enough doc.
4. **What friction repeated from a prior retro?**
   - **Review latency.** Round 1 took about 9 minutes, in line with notebook-gate's `TEST_FILTER` gain. Round 2 took about 82 minutes, 73 of them in the reviewer's full gate. The release gate then took about 15 minutes, against about 4 for the orchestrator's earlier runs.
   - **Cause:** not identified. Nothing else was running the suite during the release gate, so a slow machine is as likely as contention between the reviewer's parallel mutation runs.
   - **Routing:** `not worth keeping` until it reproduces with a known cause. If it does, it's a `harness/agents/code-reviewer.md` change (run the full gate before mutations, not alongside them), which is a `/1-plan` unit, not a retro edit.
