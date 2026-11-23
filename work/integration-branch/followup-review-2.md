Review round 2 requested changes on your implementation of /Users/cboyfly/Documents/repos/agentic-coding/work/integration-branch/plan.md. You are resuming in the same worktree on branch wt/integration-branch.

Findings to fix (all in harness/profiles/work-slim.md unless noted):
```
1. HIGH (codex) — Promote step 3 pushes to `promote/<yyyy-mm-dd>`; a second promote the same day fast-forwards that branch under an open PR, so the PR grows past its recorded SHA and evidence.
   Fix: name the branch after the gated SHA, `promote/<short-sha>` (git push origin <sha>:refs/heads/promote/<short-sha>), and say never to update an existing promote branch — a new gated SHA gets a new branch and PR.

2. HIGH (codex; the code-reviewer raised the same as LOW) — Promote step 4 tags `[reviewed]` from the `wt/*` branch name alone, which proves nothing.
   Fix: Ship step 4 (and Loop, via "as in Ship step 4"): after the reviewer approves and the gate passes on the final head, add a line `Reviewed-SHA: <gated sha>` to the PR description before merging. Promote tags a PR `[reviewed]` only when its description has a `Reviewed-SHA:` line whose SHA starts with the PR's merged `source.commit.hash`; every other PR is `[unreviewed]`. Remove the `wt/*` → `[reviewed]` rule (Explore's "never use a wt/ name" may stay).

3. LOW (code-reviewer, cheap) — the integration_branch declaration's "recommend creating `dev` from `origin/main`" fails when the diverged candidate is `origin/dev` itself.
   Fix: when the diverged candidate is `dev`, recommend a new branch name (for example `integration`) created from `origin/main`, with the Owner's yes.

4. ARCHI.md (code-reviewer MEDIUM) — `harness archi-fresh wt/integration-branch` is stale after the last followup. In the same change, add the integration-branch cases to ARCHI.md's `harness/tests/test-scripts.sh` bullet (one short clause), so ARCHI.md is committed alongside this followup.
```

Stay inside the plan's footprint. Re-run harness gate and `harness demo integration-branch` until both pass, then print an updated summary. If a fix cannot be made within the plan's scope, stop and explain why instead of working around it.
