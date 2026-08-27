Round-3 review found one remaining issue in your implementation of work/loop-hardening/plan.md. You are resuming in the same worktree on branch wt/loop-hardening. Owner authorized this round.

Finding to fix (footprint: scripts/agent-exec.sh, tests/test-scripts.sh only):

**The null-dispatch guard must only fire when the tree was clean BEFORE dispatch.** Currently the guard checks only post-dispatch state, so a dirty re-dispatch where the implementer resolves the dirty state by reverting/cleaning without committing (HEAD unchanged, tree ends clean) false-fails as `no new commit`. Capture pre-dispatch cleanliness and gate on it:

```bash
STATUS_BEFORE=$(git -C "$WORKTREE" status --porcelain)
...
if [[ -z "$STATUS_BEFORE" && "$HEAD_AFTER" == "$HEAD_BEFORE" && -z "$(git -C "$WORKTREE" status --porcelain)" ]]; then
```

Add a hermetic test: dirty tree before dispatch, canned implementer that cleans/reverts it (clean after, HEAD unchanged) → exit 0. Existing agent-exec cases must keep passing.

Touch nothing else.

When done:
1. Run scripts/gate.sh from the repo root — it must pass.
2. Commit on this branch with a clear message.
3. Print an updated summary.
