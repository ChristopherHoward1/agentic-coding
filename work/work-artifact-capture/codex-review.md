Findings:

- `scripts/worktree.sh:76-77`: `sync-artifacts` copies only primary top-level non-dot regular files, but then `git add -- "work/$slug"` stages the entire worktree directory. That can commit worktree-resident files that were never synced and are explicitly out of scope, such as `work/<slug>/sub/x.md`, `work/<slug>/.codex-review.tmpAB`, or a dirty `work/<slug>/plan.md`. The current tests put dotfiles/subdirectories/symlinks in the primary checkout, so they do not catch this. Add a fixture with out-of-scope files already present in the target worktree before sync and prevent them from being staged, or revise the plan if directory staging is intended to capture worktree-side strays.

Open question: the plan intentionally prefers directory staging to avoid ignored-file aborts, but that tradeoff conflicts with the stated “top-level regular non-dot primary artifacts except `plan.md`” scope. The implementation needs a narrower staging strategy or an explicit design decision accepting worktree-side captures.

Codex verdict: REQUEST CHANGES
