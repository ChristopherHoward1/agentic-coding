You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.
Follow its build-discipline section while staying inside the plan footprint.

Work unit: work/{{SLUG}}/plan.md  (read it in full; it is your source of truth)
Branch: wt/{{SLUG}} (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
{{FILES_TO_MODIFY}}

Key constraints:
{{CONSTRAINTS}}

When done:
1. Run scripts/gate.sh from the repo root — it must pass.
2. Commit your work on this branch with a clear message.
3. Run `scripts/demo.sh {{SLUG}}` on the now-clean tree. If it fails, fix the problem, re-run the gate, commit, and re-run the demo. Exit 2 is a plan or tooling error, never a demo verdict; stop and surface it if it cannot be fixed within scope.
4. Print a final summary: what changed and why, paste the demo output, criteria partially met (if any), out-of-scope observations.
