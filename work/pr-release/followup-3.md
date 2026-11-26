Release PR CI (Ubuntu, git 2.56.1) failed on your implementation of /Users/cboyfly/Documents/repos/agentic-coding/work/pr-release/plan.md. You are resuming in the same worktree on branch wt/pr-release. The release commit has been dropped; do not touch VERSION or CHANGELOG.md.

Failure output (CI trace of `registry_release_flow`):
```
+ git -C .../wts/demo push -q .../origin.git HEAD:main
+ registry_run state demo
+ grep -qx 'next_action: merge the PR (work/demo/pr.md)'
+ return 1
FAIL: registry release and state flow
```

Cause: newer git (2.56 on CI; local is 2.47) also updates the local `refs/remotes/origin/main` on a push by URL when the URL matches the configured `origin` remote. So the "pushed but not fetched" step already sees the merge and reports `done`. `state.sh` is correct; the test's way of advancing origin without updating the tracking ref is not portable.

Fix, in `harness/tests/test-scripts.sh` only:
- In `registry_release_flow`, advance origin from a **separate clone**, which the plan allows ("by URL or from a separate clone"). For example:
  - `git clone -q "$REG/origin.git" "$REG/other"`;
  - `git -C "$REG/other" fetch -q "$WT" HEAD`, or push from `$WT` into the clone;
  - `git -C "$REG/other" push -q origin <sha>:main`.

  The work repo's tracking ref must stay stale until its explicit `git fetch`. Do not push from `$WT` or `$REG/repo` to origin in any form before that fetch.
- Keep every assertion `|| return 1`.
- Do not change `state.sh`, `release.sh` or any other file.

Stay inside the plan's footprint. Re-run harness gate until it passes, then print an updated summary. If a failure cannot be fixed within the plan's scope, stop and explain why instead of working around it.
