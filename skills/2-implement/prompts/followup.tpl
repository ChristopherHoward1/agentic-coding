The gate failed on your implementation of work/{{SLUG}}/plan.md. You are resuming in the same worktree on branch wt/{{SLUG}}.

Gate output:
```
{{GATE_OUTPUT}}
```

Fix every item marked ✗. Stay inside the plan's footprint. Re-run scripts/gate.sh until it passes, commit the fix, then re-run `scripts/demo.sh {{SLUG}}` on the clean tree and paste its output in an updated summary. If the demo fails, fix, re-gate, commit, and re-run it. If a failure cannot be fixed within the plan's scope, stop and explain why instead of working around it.
