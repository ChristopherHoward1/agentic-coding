# Retro: stacked-units-followups (v2026.11.6)

1. **What did the gate miss that a reviewer caught?**
   - **Unsafe printed remedy.** When the child had no worktree, the new no-fork-point warning printed `git -C '' rebase -i …`. ARCHI's rule against printed rebases that can run in another checkout already covered this, but the plan didn't apply it to the new message. Both reviewers flagged it in round 1. Restack also accepted a primary-checkout `wt/<slug>`.
   - **Routing:** `not worth keeping`. Both are fixed and pinned by mutation, and the ARCHI rule already exists.
2. **What did every check miss?** Nothing known. → `not worth keeping`.
3. **What got re-derived that a doc would have prevented?**
   - **None.** The handoff cited `knowledge/test-helper-contract.md`, per the 2026-11-26 decision, and the unit had no bash 3.2 or fixture-portability findings. That shows the citation rule works.
   - **Routing:** `not worth keeping`.
4. **What friction repeated from a prior retro?**
   - **Review latency.** The code-reviewer reruns the full ~340-case suite for every mutation, so a round takes 20–100 minutes. Round 1 here took about 58 minutes. Round 2 was scoped to the new guards and took about 18. The Owner noticed the stalls.
   - **Routing:** `mechanical`. This becomes the Owner-approved `TEST_FILTER` small fix right after this release. It adds a case filter to the suite's `check` helpers and tells the reviewer to run each mutation against the matching cases, then one full suite at the end. It touches `harness/`, so it isn't applied on this retro branch.
