# Retro: reviewer-set (v2026.11.4)

1. **What did the gate miss that a reviewer caught?**
   - **Codex round 1 (HIGH).** Letting registry units pass review made the downstream stage rules reachable, and those rules read the repo-side `work/.last-released` and `retro.md`. → `not worth keeping`: the loop worked as designed. The finding is pinned by a regression case and a reviewer mutation.
   - **Code-reviewer round 2 (HIGH).** ARCHI was stale. → item 4.
2. **What did every check miss?** Nothing known. → `not worth keeping`.
3. **What got re-derived that a doc would have prevented?** Nothing. → `not worth keeping`.
4. **What friction repeated from a prior retro?** ARCHI freshness on the branch (Decision 2026-09-01) cost a whole review round here. The followup changed `harness/` after the implementer's ARCHI edit. The round-2 reviewer then failed the `archi-fresh` criterion, which `/3-review` step 7 would have healed without a round. → `process`: one line in `PLAN.md` → Decisions.
