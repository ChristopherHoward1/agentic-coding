Code review round 1 of your implementation of /Users/cboyfly/Documents/repos/agentic-coding/work/stacked-units-followups/plan.md approved it but raised two MEDIUMs that are being fixed before release. You are resuming in the same worktree on branch wt/stacked-units-followups.

Failure output (round 1, both reviewers):
```
MEDIUM (code-reviewer + codex): harness/scripts/lib/stack.sh:76 — when wt/c has no worktree, the no-fork-point warning prints `git -C '' rebase -i origin/main`. `git -C ''` keeps the current directory, so pasted from the primary checkout it rebases whatever is checked out there (normally main). Violates the rule that no printed rebase can run against another checkout.
MEDIUM (codex) / LOW (code-reviewer): harness/scripts/lib/stack.sh:104 — restack uses worktree_for_branch, which also returns the primary checkout. If wt/c is checked out in the primary checkout, restack rebases there instead of refusing with `no worktree for` (plan: "checked out in a linked worktree").
LOW (code-reviewer): ARCHI.md:24 — the `harness release` entry-point line still describes only the raw `rebase --onto origin/main <fork>` command; it should mention the `harness worktree restack <slug>` hint too.
```

Fix:
- **No-fork-point warning without a worktree.** When `wt/<slug>` has no worktree, the warning must not print a `git -C` command. Use the existing no-worktree wording, as the rewritten-parent note's no-worktree branch already does: tell the user to recreate the worktree (`harness worktree add <slug>`), then re-run `harness worktree base <slug>`. Audit every other new message in `lib/stack.sh` that interpolates the worktree path, and apply the same rule.
- **Restack in the primary checkout.** `restack` must refuse with `no worktree for` when `wt/<slug>` is checked out only in the primary checkout. A linked worktree is one whose `git rev-parse --git-dir` differs from `--git-common-dir`, or equivalently any `git worktree list` entry that isn't the first.
- **New tests, each `|| return 1`:**
  - no-fork-point plus no child worktree: stderr has no `git -C` and names `harness worktree add c`;
  - `wt/c` checked out in the primary checkout: `restack c` exits 1 with `no worktree for`, and `wt/c`'s SHA is unchanged.
- **`ARCHI.md` line 24:** mention the restack hint.

Read /Users/cboyfly/Documents/repos/agentic-coding/knowledge/test-helper-contract.md before editing tests. Stay inside the plan's footprint. Re-run harness gate until it passes, then print an updated summary. If a failure cannot be fixed within the plan's scope, stop and explain why instead of working around it.
