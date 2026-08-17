The independent code review of your implementation of work/trip-release/plan.md returned REVISE. You are resuming in the same worktree on branch wt/trip-release.

Reviewer findings (fix all three; stay inside the plan's footprint):

```
1. BROKEN HAPPY PATH (reproduced): scripts/release.sh release() does `git switch main`
   then `git merge --ff-only "$branch"`. In this repo's mandated topology, main is
   checked out in the PRIMARY checkout while wt/<slug> lives in a separate worktree.
   `git switch main` from the worktree fails with
   `fatal: 'main' is already used by worktree at '.../repo'` (exit 128) — AFTER the
   release commit and tag were already created, stranding a half-finished release with
   no rollback. Run from the primary checkout instead, `$branch` resolves to main and
   the merge is a self-merge no-op. Both invocation locations are broken.

   Required fix shape: never `git switch`. Locate the primary worktree that has main
   checked out (`git worktree list --porcelain`), verify it is clean, and run
   `git -C <main-checkout> merge --ff-only wt/<slug>`. Order operations so nothing
   irreversible (commit, tag) happens until every precondition INCLUDING
   merge-ability (main clean, ff possible) has been verified — or roll back
   cleanly on failure.

2. NO TESTS: the plan requires the four refusals and the happy path be demonstrated,
   not described. Add release.sh coverage to tests/test-scripts.sh (sandbox git repo
   fixture that reproduces the real topology: primary checkout with main + a linked
   worktree with wt/<slug>): all four refusals, the .9→.10 / .10→.9 version cases,
   and the happy path including the ff-merge landing on main in the primary checkout
   and stopping before any push. The gate must run these.

3. SENTINEL AMBIGUITY: plan.tpl's `Verdict:` line sits in the same `## Review`
   section the /1-plan-stage reviewer fills, so a clean plan-stage approval would
   write `Verdict: APPROVE` and satisfy release.sh before any code review ran.
   Disambiguate the two producers: plan-stage verdict gets a distinct label
   (e.g. `Plan verdict:`), the code-review stage writes `Code-review verdict: APPROVE`,
   and release.sh greps exactly for the code-review sentinel. Update plan.tpl,
   skills/3-review/SKILL.md, and release.sh consistently.
```

Also non-blocking: add a one-line comment on extract_release_note's single-line assumption.

Re-run scripts/gate.sh until it passes (it must now include your new release.sh tests), commit the fix, and print an updated summary. If a fix cannot be done within the plan's footprint, stop and explain why instead of working around it.
