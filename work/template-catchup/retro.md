# Retro: template-catchup (v2026.11.2)

1. **What did the gate miss that a reviewer caught?** `/docs` (#80, small-fix lane, unreviewed) branched from the integration branch but opened its PR to the default branch, which would have bypassed Promote. The code-reviewer caught it only because it was also given the released range. → `process`: one line in `PLAN.md` → Decisions.
2. **What did every check miss?** Nothing known. → `not worth keeping`.
3. **What got re-derived that a doc would have prevented?** That a release needs a reviewed unit even when every change is already on `main`. The 2026-11-23 decision covers releasing a small fix now; this was the already-merged variant of the same case. → `not worth keeping`: the new decision line covers it.
4. **What friction repeated from a prior retro?** None. → `not worth keeping`.
