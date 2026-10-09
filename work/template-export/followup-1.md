Code review (round 1) returned a HIGH finding on your implementation of work/template-export/plan.md. You are resuming in the same worktree on branch wt/template-export.

Finding (HIGH, both reviewers flagged it):
```
scripts/export-template.sh never normalizes to the repo root. `git archive HEAD` and
`git ls-tree -r HEAD -- template/` are cwd-relative, so running from a subdirectory
(e.g. `cd scripts && ./export-template.sh "$d"`) exports only that subtree, silently
skips the template/ overlay, and exits 0 with an incomplete template.
```

Fix:
- Resolve `<dest>` to an absolute path (relative to the caller's cwd) before changing directory, then `cd "$(git rev-parse --show-toplevel)"` (exit 2 if that fails) before the archive/overlay. Keep refusal semantics and exit codes unchanged.
- Add a `tests/test-export.sh` case that runs the export from a subdirectory of the fixture with a relative `<dest>`, and asserts the full template (e.g. CLAUDE.md and VERSION=1970.1.0 present) lands at the dest resolved against the caller's cwd. Show that the case fails with the `cd` removed (confirm the mutation landed, then restore), and record it in work/template-export/mutations.md.

Stay inside the plan's footprint. Your sandbox cannot commit — leave changes uncommitted. Re-run scripts/gate.sh until it passes, then print an updated summary including the mutation you ran.
