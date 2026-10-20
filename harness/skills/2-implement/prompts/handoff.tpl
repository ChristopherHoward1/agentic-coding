The implementer contract precedes this handoff — it is your contract.
Follow its build-discipline section while staying inside the plan footprint.

Work unit: {{PLAN_PATH}}  (read it in full; it is your source of truth)
Branch: wt/{{SLUG}} (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
{{FILES_TO_MODIFY}}

Every edit the plan names is authorized; stop only for an edit outside the footprint.
Nothing is committed while you work, so reads through `HEAD` (`git archive`, `git show HEAD:…`) will not see your changes.

Key constraints:
{{CONSTRAINTS}}

When done:
1. Run harness gate from the repo root — it must pass.
2. Print a final summary: what changed and why, criteria partially met (if any), out-of-scope observations.
