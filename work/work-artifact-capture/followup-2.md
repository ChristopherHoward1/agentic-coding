Round-2 review findings on work/work-artifact-capture/plan.md. You are resuming in the same worktree on branch wt/work-artifact-capture.

Both reviewers ran again: Claude `code-reviewer` REVISE, codex REQUEST CHANGES. Your round-1 fixes were all verified good — the reviewer mutation-tested every new guard independently and found no vacuous tests. Two defects remain, both about *where* the command runs and *what* it stages.

This is the final review round before the unit escalates to the Owner. Do not redesign; make these two fixes, take the two nits, and stop.

The branch carries several orchestrator housekeeping commits (`df4eb96`, `772c378`, `d9784de` and a probe cleanup). Leave them alone.

## Finding 1 (blocking) — the command silently does nothing when run from inside the worktree

`scripts/worktree.sh:10` sets `ROOT=$(git rev-parse --show-toplevel)`, which resolves to the *current* checkout, not the primary one. Nothing guards against being invoked from inside the worktree — and that is exactly where the round-1 call site puts it: `/2-implement` step 4 is `cd "$WT" && scripts/gate.sh`, and the orchestrator's shell cwd persists across commands, so step 5's sync runs with `ROOT` = the worktree.

The reviewer reproduced both variants on a live fixture:

- **First followup round** (no artifacts in the worktree yet): `$ROOT/work/<slug>` *is* the worktree's own copy, the branch check resolves to that same worktree, the loop copies nothing, nothing stages — **exit 0, the primary checkout's `handoff.md` never captured, and no signal to the orchestrator that anything was skipped.** That is precisely the escalated-unit artifact loss the plan's "Three call sites" section exists to prevent.
- **Second round** (artifacts already present): `cp: .../work/demo/handoff.md and .../work/demo/handoff.md are identical (not copied).` → **exit 1** under `set -e`, with a message naming no cause.

`scripts/release.sh:229` sets the precedent for the missing assertion:

    worktree_for_branch main >/dev/null || die "main must be checked out in the primary worktree"

Add the equivalent refusal to `sync-artifacts` — it must run from the primary checkout — with a clear message. Add a test: invoking from inside the worktree is refused non-zero, not silently no-op'd.

Also make the prose match: `skills/2-implement/SKILL.md` and `skills/3-review/SKILL.md` should say the sync runs from the repo root, the way `skills/4-release/SKILL.md:12` already does.

## Finding 2 (blocking) — directory staging captures worktree-side files, including `plan.md` edits

Raised by both reviewers. `scripts/worktree.sh:76`'s `git add -- "work/$slug"` stages everything under that directory in the worktree, while the copy loop deliberately syncs a much narrower set. Verified live: a `work/<slug>/sub/x.md` created worktree-side is committed under `Record artifacts for <slug>`, even though the copy loop would never have synced it.

The genuinely harmful case is `plan.md`. The copy loop correctly excludes it, but staging does not — so if `/3-review` step 5 edits the worktree plan in place and a sync runs before that edit is committed, the review sentinels land inside a `Record artifacts` commit instead of the intended single plan-update commit.

**Resolve it this way, and record the decision in the plan's Approach section:**

- **Keep directory staging.** Per-file `git add` is not an option — that is what breaks on gitignored strays under `set -e`, which round 1 established with a test.
- **Unstage `plan.md` explicitly after the directory add**, e.g. `git restore --staged -- "work/$slug/plan.md"` (or the `git reset --` equivalent), so the plan can never be folded into an artifact commit regardless of ordering. Guard it so it does not fail when `plan.md` is not staged.
- **Accept other worktree-side files under `work/<slug>/` as in scope.** Everything in that directory belongs on the branch; capturing a stray there is correct, not a leak. Add one test pinning that accepted behavior so it is deliberate rather than accidental, and state it in the plan: the *copy* scope is narrow, the *staging* scope is the whole unit directory minus `plan.md`.

Add a test for the `plan.md` case: with an uncommitted sentinel edit in the worktree `plan.md`, a sync must not commit it, and the worktree must still show that edit pending afterwards.

## Nits — take both, they are one line each

- `ARCHI.md:15` says "top-level regular non-dot"; symlinks-to-files satisfy `-f`, so "regular" only reads as covering them if you already know `! -L` is there. Make it explicit.
- `tests/test-scripts.sh:733` — the check named `stages directory so ignored primary strays do not abort` asserts only that `scratch.bin` is absent, which holds under per-file staging too; the actual discrimination lives in the preceding `copies primary artifacts` `check_exit ... 0`. Rename it to say what it proves.

## Explicitly declined — do NOT fix

- **Partial state after a mid-loop `cp` failure.** Recoverable and loud; fixing finding 1 removes the reachable path to it.
- **Duplication of `worktree_for_branch` between `worktree.sh` and `release.sh:140-157`.** Matches surrounding style and keeps the two resolvers semantically identical. The reviewer explicitly said leave it.
- **A test distinguishing the commit guard from `commit || true`.** The reviewer confirmed no criterion can separate them and is not asking for one.

## Constraints (unchanged)

- `set -euo pipefail`; keep the commit gated on `git diff --cached --quiet`, never `|| true`.
- `worktree.sh` only asks git, never inspects `.git` directly.
- Tests set environment per-command, never `export`. See `knowledge/test-helper-contract.md`.
- Mutation requirement on every new/changed test: break it, confirm red, restore, report.
- `scripts/release.sh` byte-identical: `git diff main...HEAD -- scripts/release.sh` empty.
- Update ARCHI's check count to whatever the suite reports (currently 121).

## When done

1. `bash scripts/gate.sh` from the repo root — must pass.
2. Confirm `git diff main...HEAD -- scripts/release.sh` is empty.
3. Commit on this branch.
4. Print a summary: what changed, what you observed during mutation checks, anything still open.
