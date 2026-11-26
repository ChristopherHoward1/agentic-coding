# Retro: pr-release (v2026.11.5)

1. **What did the gate miss that a reviewer caught?**
   - **The trap.** The new tests' mid-function `[[ ]]` assertions were inert under macOS bash 3.2, so dropping the post-gate re-check left the suite 306/306 green. The code-reviewer caught it by mutation in round 1. `knowledge/test-helper-contract.md` already documents this trap, from `stacked-units`. It recurred because the handoff never cited that doc, and cold-tier docs load only on citation (Decision 2026-08-27).
   - **Routing:** `process`, one line in `PLAN.md` → Decisions.
2. **What did every check miss?**
   - **The miss.** Ubuntu CI's git 2.56 also updates the local tracking ref on a push by URL that matches a configured remote. Local git 2.47 doesn't. The no-fetch state case passed locally and in all three review rounds, then failed on the release PR's CI. Diagnosing it took a throwaway traced draft PR, and the release commit had to be dropped and redone.
   - **Routing:** `contextual`, a section in `knowledge/test-helper-contract.md`: advance a fixture's origin from a separate clone.
3. **What got re-derived that a doc would have prevented?**
   - **The cost.** An orchestrator scripted edit replaced the plan body from the first `## Acceptance criteria` match. That match was inside the `pr.md` template, so the edit deleted the Footprint section, and a plan-review round went to finding it.
   - **Routing:** `not worth keeping`. Replacements that assert their match count, which every later edit in this unit used, prevent it. That is editing hygiene, not project knowledge.
4. **What friction repeated from a prior retro?**
   - **ARCHI staleness.** It recurred after every followup that touched `harness/`. The new 2026-11-25 rule healed it before each review round, at no cost in rounds.
   - **A codex false-positive HIGH at the round cap.** Like `review-diff-base-origin-main`, it was handled by the 2026-09-08 escalation rule and an Owner override.
   - **Routing:** `not worth keeping`. Both existing rules worked as written.
