Review round 2 found one blocking issue in your implementation of /Users/cboyfly/Documents/repos/agentic-coding/work/stacked-units/plan.md, plus one test-strength issue. You are resuming in the same worktree on branch wt/stacked-units. Your earlier changes are committed; the same sandbox rules apply (plain file edits only, no git index writes in this worktree, the orchestrator commits).

Findings to fix:
```
1. HIGH (codex): harness/scripts/lib/stack.sh:54-55. When the child has no worktree, the rewritten-parent note
   prints `git rebase --onto wt/<parent> <F>` with no branch argument. Run from the primary checkout, that
   rebases the currently checked-out branch (usually main) onto the unmerged parent. (The round-1 followup asked
   for `-C` to be omitted; that advice was wrong.)
   Fix: when no child worktree is found, do not print an executable rebase. Print instead
   `note: <parent> was rewritten since <slug> branched; to pick it up, recreate the worktree (harness worktree add <slug>) and re-run harness worktree base <slug>`.
   Stdout and exit status stay unchanged. Update the existing missing-worktree test to assert that the note
   contains no `rebase` and names `harness worktree add <slug>`; then actually run `harness worktree add c`
   and `worktree base c` again, and assert the printed note now carries `rebase --onto wt/p` with a quoted -C path,
   and that running it leaves the fixture's main ref unchanged (compare `git rev-parse main` before/after).

2. MEDIUM (code-reviewer): harness/tests/test-scripts.sh, the stack cases (around lines 2582, 2588, 2589, 2607,
   2685, 2690-2693). They run under `bash -e -c`, but in macOS /bin/bash 3.2.57 a failing `[[ ]]` does not trigger
   errexit, so bare `[[ ... ]]` checks followed by more commands never fail locally. Append `|| return 1`
   (inside functions) or `|| exit 1` (top level of the -c body) to every bare `[[ ]]` / `[ ]` / `test` check in
   the stack cases that isn't the last command. The reviewer confirmed three mutations then each fail
   exactly one case; re-run those on Darwin and report them:
   - `review_base`: replace `[[ "$status" -eq 1 ]] || return 2` with `:` -> `stack edge errors` fails
   - always add `-C <wt>` to the note -> the missing-worktree case fails
   - make `review_base` ignore the parent in registry mode -> `stack edge registry` fails
```

Stay inside the plan's footprint. For each mutation, confirm it landed, confirm the named test fails, restore, and report one line: mutation, landing check, failing test, `uname -s`. Run `bash harness/bin/harness gate` from the worktree root until it passes, then print an updated summary. If a fix can't be made within the plan's scope, stop and explain why.
