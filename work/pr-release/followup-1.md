Your implementation of /Users/cboyfly/Documents/repos/agentic-coding/work/pr-release/plan.md is incomplete: the gate passes, but the plan's acceptance criteria are not met. You are resuming in the same worktree on branch wt/pr-release.

Failure output (your own summary):
```
Acceptance is partial: the new test covers the happy path, moved HEAD and no-fetch state behavior, but the full refusal and mid-gate test matrix was not added, and the reviewer mutation pins were not verified.
```

Add the missing tests in `harness/tests/test-scripts.sh`, following the existing registry helpers. Each case asserts the plan's exact refusal substring, a non-zero exit, and that `pr.md` is absent (or byte-identical when one existed before). The cases come from the plan's Acceptance criteria:

- **Pre-gate refusals.** Each runs with a `$S/scripts/gate.d/` hook that writes a marker file, and asserts the marker is absent afterwards:
  - no plan;
  - no worktree for `wt/<slug>`;
  - missing `Plan verdict: APPROVE`;
  - missing `Code-review verdict: APPROVE`;
  - `Reviewed-SHA:` missing, malformed (`Reviewed-SHA: <sha>`), duplicated (including a copy inside the Goal), or not directly after the code-review verdict;
  - HEAD ≠ `Reviewed-SHA`;
  - a dirty worktree;
  - a base that isn't an ancestor;
  - a `Stacked on:` plan (assert the remedy text too);
  - no `Release note:` line;
  - `integration_branch: dev` with no `origin/dev`;
  - `--confirm-delta`.
- **Post-gate refusals:**
  - a failing gate hook;
  - a stale state-dir `ARCHI.md`;
  - a missing state-dir `ARCHI.md`.
- **Mid-gate refusals:** a gate hook that commits on `wt/<slug>` gets `moved after review`, and a hook that leaves an untracked file in the worktree gets `has untracked files`.
- **Integration branch:** set `integration_branch: dev` and give `origin/dev` a commit that `origin/main` lacks. Then:
  - a `wt/<slug>` based on `origin/main` refuses with `is not based on origin/dev`;
  - a `wt/<slug>` based on `origin/dev` passes, and the printed `release: nothing pushed` line names `dev`.
- **Happy path extras:**
  - `pr.md` has exactly one `^Reviewed-SHA:` line, and its `## What` is the release note;
  - origin's `for-each-ref` output is unchanged;
  - the work repo shows no new commits and an empty `git status --porcelain`;
  - the work repo has no `VERSION`, `CHANGELOG.md` or `work/.last-released`.
- **State:**
  - when `pr.md`'s last `Reviewed-SHA:` differs from the plan's, `next_action: /4-release`;
  - after a fetch, `stage: done`.
- **No tags:** registry `tag-after-merge` exits 1 with `the merged PR is the record`.

If a case shows the implementation doesn't match the plan's Approach, fix the implementation within the footprint. Do not weaken a case to match the code.

Stay inside the plan's footprint. Re-run harness gate until it passes, then print an updated summary listing each case added. If a failure cannot be fixed within the plan's scope, stop and explain why instead of working around it.
