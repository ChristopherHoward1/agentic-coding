# Work artifact capture — a released unit's artifacts should reach main with it

**Slug:** work-artifact-capture · **Date:** 2026-08-27 · **Status:** approved

## Goal

`worktree.sh add` seeds `work/<slug>/plan.md` onto the branch (`worktree.sh:35-41`), so the plan flows to `main` with the release. Nothing carries the unit's other artifacts. `handoff.md` is written by the orchestrator before dispatch, `notes.md` after it, `followup-*.md` during review rounds, and `codex-review.sh` writes `codex-review.md` into the **primary** checkout (`codex-review.sh:24`). All four land untracked in the primary checkout and never reach the branch.

The result is a manual catch-up commit after every unit — `git log -- work/` shows `b0891f9` and `7d34060`, and the first of those sat unmerged for a full release cycle. Without a fix it recurs every unit, and the loop's own record of how a change was produced — the handoff that specified it, the findings that corrected it — is the thing most at risk of being lost.

Done = every unit that reaches release has its artifacts committed on `wt/<slug>`, with no manual step and no new way for a release to fail.

## Approach

Add `scripts/worktree.sh sync-artifacts <slug>`: copy `work/<slug>/`'s top-level regular non-dot files from the primary checkout into the same path in the unit's worktree, **excluding `plan.md`**, then `git add -- work/<slug>` and commit only if something is staged.

**`plan.md` is excluded outright**, not merely protected. It reaches the branch via `add`, and `/3-review` step 5 writes the verdict sentinels into the *worktree* copy and explicitly warns against `cp`-ing over it from the primary checkout (`skills/3-review/SKILL.md:18`). Excluding it removes the "which copy wins" question from the implementation entirely; every other file is copied unconditionally, so a second sync correctly refreshes a `notes.md` that a followup round rewrote.

**Top-level regular non-dot files only.** Dotfiles must not sync: `codex-review.sh:92` creates `mktemp "$root/work/$slug/.codex-review.XXXXXX"` in that very directory, cleaned by an EXIT trap that a SIGKILL defeats — syncing dotfiles would commit reviewer garbage. Separately, `.DS_Store` is gitignored, and `git add` of an explicitly-named ignored file fails, which under `set -euo pipefail` would abort the subcommand. Staging the **directory** (`git add -- work/<slug>`) rather than each file lets git skip ignored strays silently instead of erroring.

**Why `worktree.sh`.** `fan-exec.sh:38` already does `cp -R "$ROOT/work/$slug" "$wt/work/"`, so the copy idiom belongs to the worktree layer, not the producers. Having each writer commit its own output would spread the same logic across scripts and still leave `notes.md` homeless, since the orchestrator writes it and no script owns it.

**Why not sweep in `release.sh`.** Rejected on inspection: `release()` calls `check_clean_worktree` at `release.sh:242` and `:246` before the release commit, and that guard refuses untracked files (`release.sh:165-166`). A sweep would have to write *before* the guard — adding a write to the only path carrying a rollback trap. Bookkeeping does not belong in the most safety-critical path in the repo.

**Three call sites, because one is not enough.** `/3-review` step 5 fires only on double-APPROVE; step 4 caps at 3 rounds and escalates, so a unit abandoned there would lose its handoff, notes, and every followup — the units whose findings are most worth keeping. The command is idempotent by design, so it is called from three places: end of `/2-implement` (captures `handoff.md` + `notes.md` right after dispatch), `/3-review` step 5, and the start of `/4-release` before `release.sh` runs. The last one covers every unit that actually releases, and since sync leaves the tree clean, `check_clean_worktree` still passes. `/5-retro` does not need it — `retro.md` is written and committed on `wt/retro-<slug>` (`skills/5-retro/SKILL.md:23,25`).

**On enforcement.** This stays an action invoked by skill prose, with no mechanical precondition. A `release.sh` precondition would make releases refusable over bookkeeping — `check_previous_retro` is the cautionary example — and a non-fatal warning is not a better middle: it still touches `release.sh`, which this plan's byte-identical criterion forbids, and would fire on every release for units whose artifacts are legitimately mid-flight. The `/4-release` call site provides the coverage with zero release-path surface.

## Footprint

Files to modify:
- `scripts/worktree.sh` — new `sync-artifacts <slug>` subcommand + usage header
- `skills/2-implement/SKILL.md` — call it after dispatch
- `skills/3-review/SKILL.md` — call it at step 5
- `skills/4-release/SKILL.md` — call it before `release.sh`
- `tests/test-scripts.sh` — hermetic cases
- `ARCHI.md` — `worktree.sh` Layout line, its Entry-points line, Verification check count

Files NOT to touch:
- `scripts/release.sh` — see Approach; no new precondition, no warning, no change to the release commit
- `scripts/codex-review.sh`, `scripts/agent-exec.sh` — producers keep writing where they write today
- `worktree.sh`'s `add` path — the `plan.md` seed and its resume behavior are unchanged
- `skills/5-retro/SKILL.md` — retro artifacts already commit on their own branch

## Acceptance criteria

- [ ] A hermetic fixture with `handoff.md`, `notes.md`, `followup-1.md`, and `codex-review.md` in the primary checkout ends with all four listed by `git ls-tree -r wt/<slug> -- work/<slug>/` after one sync.
- [ ] **`plan.md` is never synced:** a worktree `plan.md` containing `Code-review verdict: APPROVE` is byte-identical after a sync whose primary-checkout copy lacks that line.
- [ ] **A second sync refreshes changed files:** modify `notes.md` in the primary checkout, re-run, and the worktree copy matches the new content.
- [ ] Idempotent: two consecutive syncs with no intervening change produce exactly one commit; the second exits 0 having committed nothing.
- [ ] Dotfiles are not synced: a fixture containing `.codex-review.tmpAB` leaves it absent from `git ls-tree -r wt/<slug> -- work/<slug>/`.
- [ ] Subdirectories are not synced: a fixture containing `work/<slug>/sub/x.md` leaves it absent from the same listing.
- [ ] A gitignored stray (`.DS_Store`) in `work/<slug>/` does not abort the subcommand — it exits 0 and the file is not committed.
- [ ] Refuses with a non-zero exit and a clear message when no worktree exists for `<slug>`.
- [ ] Refuses when the primary checkout has no `work/<slug>/` directory.
- [ ] Leaves the worktree clean — `git status --porcelain` in the worktree is empty afterwards, so `release.sh`'s `check_clean_worktree` still passes.
- [ ] `scripts/release.sh` is byte-identical: `git diff main...HEAD -- scripts/release.sh` is empty.
- [ ] ARCHI's Verification check count matches `tests/test-scripts.sh` output (currently 105).
- [ ] Each new test has been shown to fail with its guard removed (2026-08-27 decision in `PLAN.md`; see `knowledge/test-helper-contract.md` for how vacuity arises here and what each helper actually asserts).
- [ ] `bash scripts/gate.sh` passes.

## Implementation hazards

- The suite runs nested inside `scripts/gate.sh` via the `gate.d/` hook — see `knowledge/test-helper-contract.md`. Fixtures must be hermetic temp repos; set any environment per-command, never `export`.
- `worktree.sh` must only ask git (`git worktree`, `git rev-parse`) and never inspect `.git` directly, because it runs from inside worktrees where `.git` is a file. ARCHI names this as a property to preserve.
- `worktree.sh` uses `set -euo pipefail`; `git commit` with nothing staged exits non-zero and would abort the script. Gate the commit on `git diff --cached --quiet` failing, rather than `|| true`, which would also swallow real failures.

## Release

Release note: `worktree.sh sync-artifacts <slug>` records a unit's handoff, notes, followups, and codex review onto its branch, so a released unit's artifacts reach main with it instead of needing a manual catch-up commit.

## Verification

- `bash scripts/gate.sh`
- On the next unit: `git ls-tree -r wt/<slug> -- work/<slug>/` lists all artifacts, and `git status --porcelain` in the primary checkout shows no stray untracked work files.

## Review

Reviewer: fresh `plan-reviewer` subagent (opus, cold context, read-only). Verdict on the first draft: **REVISE**, six findings. All six accepted; no disagreements to arbitrate. The reviewer independently confirmed the problem is real and recurring (`b0891f9`, `7d34060`), that `add` seeds only `plan.md`, and that the `release.sh` sweep rejection is sound.

Applied:
1. **"Worktree copy wins" was ambiguous and, read generally, made re-runs useless** — under a skip-if-present rule a second sync would silently never refresh `notes.md` after a followup round, while still exiting 0 and satisfying idempotency. Resolved by excluding `plan.md` from the sync entirely and copying everything else unconditionally; the criterion split into two checkable cases.
2. **The subdirectory/dotfile criterion was vacuous** — "state the chosen behavior" is satisfied by any behavior plus a comment. Decided in the plan instead, with the reviewer's concrete rationale: `codex-review.sh:92`'s mktemp dotfile survives a SIGKILL, and `git add` of a gitignored `.DS_Store` aborts under `set -e`. Hence top-level regular non-dot files, staged by directory.
3. **One call site was wrong** — `/3-review` step 5 fires only on double-APPROVE, so an escalated unit lost exactly the artifacts worth keeping. Added `/2-implement` and `/4-release` call sites, and their skill files to the footprint, rather than discovering the creep mid-implementation.
4. **Enforcement trade-off resolved against the warning middle** — a warning still touches `release.sh` (forbidden by this plan's own criterion) and would fire for units legitimately mid-flight. The `/4-release` call site gives the coverage instead.
5. **Mechanical:** `check_clean_worktree` is at `release.sh:242,246` (draft said 241,245), and criterion 1 needed `git ls-tree -r … -- work/<slug>/`, since a bare `ls-tree` lists only the top level. Both verified directly.
6. **Adopted the reviewer's simpler shape:** exclude `plan.md`, `cp` the rest with no per-file comparison, `git add` the directory so git skips ignored strays itself, commit only if `git diff --cached --quiet` fails. ~8 lines, and it deletes the "which copy wins" question from the implementation.

Plan verdict: APPROVE (revised draft; Owner-approved 2026-08-27 after the reviewer's six REVISE findings were applied in full).
