Review round 3 requested a change on your implementation of /Users/cboyfly/Documents/repos/agentic-coding/work/integration-branch/plan.md. You are resuming in the same worktree on branch wt/integration-branch.

Findings to fix (harness/profiles/work-slim.md, Promote lane):
```
1. HIGH (codex) — Promote reads origin/main and origin/<integration> without fetching, so stale remote-tracking refs can make it gate and open a PR for an old tip, and make the main-moved check and the PR list wrong.
   Fix: make Promote's first action `git fetch origin`, then pin `sha=$(git rev-parse origin/<integration>)` and use that SHA (not `origin/<integration>`) in the main-moved check, the detached-worktree gate, the promote branch push and the PR list. Keep the existing steps otherwise; renumber if needed.

2. LOW (code-reviewer, cheap) — `origin/<integration>` is used without definition.
   Fix: in the Integration branch section, say `<integration>` means the configured `integration_branch` value.
```

Do not change anything else (the round-3 merge-commit finding was overridden by the Owner; see the plan's Review section). Stay inside the plan's footprint. If your edit leaves `harness archi-fresh wt/integration-branch` stale, make no ARCHI change unless its description is now wrong. Re-run harness gate and `harness demo integration-branch` until both pass, then print an updated summary.
