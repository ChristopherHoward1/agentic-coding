Review round 1 approved your implementation of /Users/cboyfly/Documents/repos/agentic-coding/work/stacked-units/plan.md, with findings worth fixing. You are resuming in the same worktree on branch wt/stacked-units. Your earlier changes are committed; the same sandbox rules apply (plain file edits only, no git index writes in this worktree, the orchestrator commits).

Findings to fix:
```
1. MEDIUM (codex) / LOW (code-reviewer): printed restack commands don't quote the worktree path.
   harness/scripts/lib/stack.sh (the stderr note, `git -C <wt> rebase --onto wt/<parent> <F>`) and
   harness/scripts/release.sh check_stack_landed (`git -C $wt rebase --onto origin/main $fork`)
   interpolate $wt raw. With a WORKTREES_DIR containing a space, the pasted command breaks.
   Fix: shell-escape the path (Bash 3.2 `printf %q`). Add a test whose WORKTREES_DIR contains a space
   and that runs the printed command for both the review note and the release refusal (the existing
   tests already run printed commands; extend one of each rather than adding fixtures).
2. LOW (code-reviewer): harness/scripts/lib/stack.sh, around the rewritten-parent note. When the child's
   worktree was removed but wt/<slug> is kept, $wt is empty and the note prints `git -C  rebase ...`.
   Fix: when no worktree is found, print the command without `-C <wt>` (or with the branch name noted),
   matching release.sh's explicit handling. Don't change the exit status or stdout.
3. LOW (code-reviewer): ARCHI.md test-suite summaries (lines ~21 and ~59) list every other suite but not
   the new stack cases. Add them in the same terse style.
```

Stay inside the plan's footprint. Pin the new quoting guard with a mutation (drop the escaping, confirm it landed, confirm the new test fails, restore) and report it as one line: mutation, landing check, failing test, `uname -s`. Run `bash harness/bin/harness gate` from the worktree root until it passes, then print an updated summary. If a fix can't be made within the plan's scope, stop and explain why.
