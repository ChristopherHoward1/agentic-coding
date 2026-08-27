Review findings on your implementation of work/loop-hardening/plan.md require changes. You are resuming in the same worktree on branch wt/loop-hardening.

Findings to fix (stay inside the plan's footprint — scripts/release.sh, scripts/agent-exec.sh, tests/test-scripts.sh):

1. **Symlink bypass of the marker guard** (codex review): in `check_previous_retro`, `[[ -f "$marker" ]]` and `cmp -s - "$marker"` both dereference a symlink, so replacing `work/.last-released` with a symlink pointing at a file with the right bytes passes the byte-identity guard, and the release then writes through the symlink. Fix: before the comparison, die if the marker path is a symlink (`[[ -L "$marker" ]]`), with a distinct message containing `marker is a symlink`. Add a hermetic test over the release fixture: replace the committed marker with a symlink to a file containing origin/main's exact marker bytes → die, stderr contains `marker is a symlink`.

2. **agent-exec post-dispatch git calls lose the worktree** (Claude review): `HEAD_BEFORE` uses `git -C "$WORKTREE" rev-parse HEAD`, but the post-dispatch `HEAD_AFTER` and `git status --porcelain` rely on the `cd "$WORKTREE"` surviving `eval "$CMD"` — an implementer.command containing `cd` relocates them, producing either a bare git failure or a spurious `no new commit` against the wrong repo. Fix: use `git -C "$WORKTREE"` for both post-dispatch calls. If a hermetic test is cheap (canned implementer whose command cd's elsewhere but commits in the worktree → exit 0), add it; otherwise the mechanical fix alone is acceptable.

Not to change (recorded disagreements/deferrals — do not act on these):
- ARCHI.md staleness (codex finding 2): the plan explicitly defers ARCHI.md to /compact pre-release. Leave it untouched.
- Retro-content branch-editability and whitespace-only markers (Claude findings 3–4): explicitly out of the plan's scope; they route to /5-retro.

When done:
1. Run scripts/gate.sh from the repo root — it must pass.
2. Commit on this branch with a clear message.
3. Print an updated summary.
