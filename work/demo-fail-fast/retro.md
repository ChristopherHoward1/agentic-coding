# Retro: demo-fail-fast (v2026.10.10)

Shipped: `harness demo` runs the Demonstration block under `bash -e`, and `plan.tpl` shows the errexit-safe forms plus the Bash 3.2 `[[ ]]` limit.
- **Plan review:** three rounds (REVISE, REVISE, APPROVE).
- **Implementation:** one codex dispatch, zero gate retries.
- **Code review:** round 1, both reviewers approved. The code-reviewer verified the mutation (4 new checks fail without `-e`).

1. **What did the gate miss that a reviewer caught?**
   - **The plan's own demo would have died under the change.** It used `out=$(cmd); rc=$?`, which errexit kills, and `plan.tpl` was only going to teach `cmd || echo`. Plan-review round 1 caught it. → **not worth keeping:** `plan.tpl` now teaches `rc=0; out=$(cmd) || rc=$?`, which is the durable fix.
   - **ARCHI claimed tests that round 3 dropped.** The criterion's wording outlived the tests, and both code reviewers flagged it (LOW). → **not worth keeping:** a one-off; both reviewers caught it in one round.
2. **What did every check miss?**
   - Nothing surfaced. → **not worth keeping.**
3. **What got re-derived that a doc would have prevented?**
   - **The Bash 3.2 `[[ ]]` errexit exemption.** `knowledge/test-helper-contract.md` already had it, but the orchestrator's draft didn't cite it, so plan-review round 2 re-derived it as a HIGH. → **not worth keeping:** `plan.tpl` now states it for demo blocks, which is where plan authors look.
4. **What friction repeated from a prior retro?**
   - **`footprint-plan-md` didn't recur.** This plan listed the orchestrator's `PLAN.md` edit under Files to modify, and neither reviewer flagged it. → **mechanical:** the `PLAN.md` candidate is narrowed to that fix (a default `PLAN.md` line in `plan.tpl`'s Files to modify).
   - **A post-approval LOW doc fix.** Both reviewers raised the same ARCHI wording LOW. The orchestrator fixed it after both approvals without a new round, treating it like `/3-review` step 7's ARCHI-heal exemption. → **process:** one `PLAN.md` Decisions line, so the call is explicit rather than improvised.
