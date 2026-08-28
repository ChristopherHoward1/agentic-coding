Review findings on work/work-artifact-capture/plan.md. You are resuming in the same worktree on branch wt/work-artifact-capture.

Both reviewers ran: Claude `code-reviewer` returned REVISE, codex returned REQUEST CHANGES. The design is accepted — do not redesign. Four items to fix, then three explicitly declined so you do not spend effort on them.

Note the branch already carries two housekeeping commits from the orchestrator (`df4eb96` recording artifacts, `772c378` removing a probe file). Leave them alone.

## Finding 1 (blocking) — the directory-staging guard has no test behind it

`tests/test-scripts.sh:408` puts `.DS_Store` in the **worktree** (`$SYNC_WORKTREE/work/demo/.DS_Store`) and `:735` asserts it is absent from `git ls-tree`. That assertion passes under **every** implementation: gitignore excludes it however staging is done, and a `.DS_Store` in the *primary* work dir can never reach the index anyway because the dotfile filter at `scripts/worktree.sh:58` drops it first.

The reviewer proved it: replacing line 61 with per-file staging inside the loop (`git -C "$wt_root" add -- "work/$slug/$(basename "$src")"`, directory add deleted) leaves the suite at **117/117 green**. So the plan's chosen design — stage the directory, not each file — is unverified, and two acceptance criteria are unmet.

This is exactly the "fixture too impoverished to exhibit the behaviour" vacuity shape that `knowledge/test-helper-contract.md` warns about and that the plan's Approach set out to prevent.

What settles it: a **non-dot** gitignored stray in the **primary** work dir. The reviewer verified the shape by hand — with `.gitignore` containing `work/*/scratch.bin` and `work/demo/scratch.bin` present in the primary checkout, the current implementation exits 0 and commits only the real artifacts, while per-file staging aborts under `set -e` because `git add` refuses an explicitly-named ignored path.

The implementation is correct as written. **Only the test changes.** Two lines in the fixture plus one assertion. Then mutation-check it: swap to per-file staging, confirm the new case goes red, restore.

## Finding 2 (blocking) — `[[ -f ]]` follows symlinks, so link targets get materialised

`scripts/worktree.sh:58`. Both reviewers flagged this, and it is not merely latent — it was demonstrated live: a symlink placed in `work/<slug>/` pointing at a file **outside the repo** had its target's contents copied and committed onto the branch.

The plan says "top-level regular non-dot files"; a symlink is not one. Add `! -L "$src"` to the guard (or use a `find -type f` shape), and add a test: a symlink to a file with known content must not appear in `git ls-tree -r`, and its content must not land in the branch.

## Finding 3 (blocking) — followup re-dispatches do not sync

`skills/2-implement/SKILL.md`. The sync call sits only on the initial single-agent dispatch at step 3. Step 5's followup re-dispatch loop does not sync, so a unit escalated at the `gate.max_retries` cap — or one that dies at `/3-review`'s 3-round cap before step 5 ever runs — still loses its `followup-*.md` files and its refreshed `notes.md`. Those are precisely the artifacts the plan's Goal names as most worth keeping.

Put the sync on the followup path too, so every dispatch is followed by one. Keep the prose minimal and in the surrounding voice.

(Fan mode does not need its own call: `fan-exec.sh adopt` creates the canonical worktree at the same default path, so the `/3-review` and `/4-release` call sites cover it. Do not add a fan-mode call.)

## Finding 4 (worth fixing) — the target worktree is resolved by path, not by branch

`scripts/worktree.sh:54`. `git -C "$path" rev-parse --show-toplevel` succeeds for *any* git repo at `$WT_DIR/$slug`; it never confirms `wt/<slug>` is the branch checked out there. A worktree switched to another branch, or a leftover directory inside an enclosing repo, silently receives the artifact commit **on the wrong branch**, exit 0, no warning.

`scripts/release.sh:231` resolves this robustly via `worktree_for_branch` over `git worktree list --porcelain`. Use that shape here. It also preserves the "only ask git, never inspect `.git`" property that ARCHI requires — which the current code does already satisfy, so do not regress it.

Add a test: a worktree at the expected path with a different branch checked out must be refused, not committed to.

## Also fix (one line)

`ARCHI.md`'s `tests/test-scripts.sh` Layout line enumerates every other suite but was not extended with the sync cases, while the Verification line was updated. The two lines now disagree about what the suite contains.

## Explicitly declined — do NOT fix these

Named so you do not spend rounds on them:

- **Partial state after a mid-loop `cp` failure** leaving the worktree dirty. Real, but recoverable by re-running sync, and the resulting `release.sh` "has untracked files" refusal is loud rather than silent.
- **`git add -- work/$slug` staging a worktree-side `plan.md` edit** under the "Record artifacts" message. The plan is never overwritten from primary, which is the criterion; only the commit message is imprecise.
- **`/4-release` step 2's "React to the exit code" prose** not covering a sync failure. Practically unreachable — a missing worktree stops `release.sh` at `:231` regardless.

## Constraints (unchanged)

- `worktree.sh` runs under `set -euo pipefail`; keep the "commit only if staged" guard gated on `git diff --cached --quiet` and never `|| true`.
- Tests set environment per-command, never `export` — the suite runs nested inside `scripts/gate.sh` via the `gate.d/` hook. See `knowledge/test-helper-contract.md`.
- Mutation requirement applies to every new or changed test: break the behaviour, confirm red, restore, and report what you observed.
- `scripts/release.sh` must stay byte-identical: `git diff main...HEAD -- scripts/release.sh` empty.
- Update ARCHI's check count to whatever the suite reports (currently 117).

## When done

1. `bash scripts/gate.sh` from the repo root — must pass.
2. Confirm `git diff main...HEAD -- scripts/release.sh` is empty.
3. Commit on this branch.
4. Print a summary: what changed, what you observed during mutation checks, anything still open.
