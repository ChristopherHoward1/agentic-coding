- **MEDIUM — Restack accepts a primary checkout.** `worktree_for_branch` returns the primary checkout as well as linked worktrees, and `restack` does not exclude it. If `wt/c` is checked out in the primary checkout, the command can rebase it there instead of refusing with `no worktree for`, as the approved precondition requires. See `harness/scripts/lib/stack.sh:104`.

- **MEDIUM — The no-fork warning can print an unusable remedy.** If `wt/c` exists but has no checked-out worktree, the lookup leaves `wt` empty. The warning then suggests `git -C '' rebase -i ...`, which fails. It should instead tell the user to recreate the worktree before giving a command. See `harness/scripts/lib/stack.sh:76`.

The review was based on the supplied diff and branch contents; I did not run the gate or mutation tests.

Codex verdict: APPROVE
