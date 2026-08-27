Round-2 review findings on work/loop-hardening/plan.md require two small fixes. You are resuming in the same worktree on branch wt/loop-hardening.

Findings to fix (footprint: scripts/agent-exec.sh, scripts/release.sh, tests/test-scripts.sh):

1. **Relative worktree path breaks the post-dispatch checks** (codex): after `cd "$WORKTREE"`, the post-dispatch `git -C "$WORKTREE"` calls resolve a *relative* worktree path against the new cwd, so a previously valid relative-path invocation can fail or check the wrong repo. Fix: normalize `WORKTREE` to an absolute physical path once, right after the `[[ -d "$WORKTREE" ]]` validation (e.g. `WORKTREE=$(cd "$WORKTREE" && pwd -P)`), so every later use is absolute. Add a hermetic test invoking agent-exec.sh with a relative worktree path (canned implementer that commits → exit 0).

2. **Bootstrap branch of the marker guard misses the symlink check** (Claude review): the non-bootstrap branch dies on `[[ -L "$marker" ]]`, but when origin/main has no marker, a symlinked local marker is still followed. Add the same one-line symlink refusal (same `marker is a symlink` message) to the bootstrap path. Hermetic test: bootstrap fixture (no marker on origin/main) with a symlinked local marker → die, stderr contains `marker is a symlink`.

Do NOT touch ARCHI.md (handled by /compact pre-release, outside your scope) and do not act on the other recorded deferrals.

When done:
1. Run scripts/gate.sh from the repo root — it must pass.
2. Commit on this branch with a clear message.
3. Print an updated summary.
