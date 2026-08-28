Round-3 review findings on work/work-artifact-capture/plan.md. You are resuming in the same worktree on branch wt/work-artifact-capture.

**The Owner has authorized a fourth round past the usual 3-round cap, and has authorized expanding the footprint to include `scripts/codex-review.sh`** — which the plan previously listed as do-not-touch. Record that authorization in the plan's Footprint section as part of this round.

Your round-2 fixes were verified good: the reviewer independently mutation-tested all seven guards and found no vacuous tests. Four things to fix.

## Finding 1 (blocking) — synced artifacts land in the review diff and destroy reviewer independence

This is the important one, and it is a design consequence nobody caught at plan time — not a mistake in your code.

Because `/2-implement` now syncs after every dispatch, `handoff.md`, `notes.md`, `followup-*.md`, and `codex-review.md` are committed on `wt/<slug>` **before** `/3-review` runs. Both reviewers read `git diff main...wt/<slug>`. So every reviewer now sees the implementer's self-report, the previous rounds' findings, the orchestrator's arbitration, and — critically — **the other vendor's verdict**. The two "independent" vendors stop being independent from the next unit onward.

This is demonstrable on this very branch: its diff contains `codex-review.md` with a `Codex verdict:` line, and `followup-1.md` naming which findings were "explicitly declined". CLAUDE.md invariant 4 ("Artifacts flow between stages, not transcripts") and `skills/3-review/SKILL.md:12` ("Reviewers must never see the implementation conversation") both say this must not happen.

**Fix: exclude the unit directory from the diff reviewers see, in both places.** They must stay in sync — a reviewer path that misses the exclusion silently reintroduces the leak.

1. `scripts/codex-review.sh:82` — `git diff "main...$branch"` becomes a diff scoped to exclude `work/<slug>`, e.g.
   `git diff "main...$branch" -- . ":(exclude)work/$slug"`.
   Keep the existing `|| die2` error handling. Note the pathspec must be quoted so the shell does not touch it.
2. `skills/3-review/SKILL.md:12` — step 1 currently says the reviewer gets `git diff main...wt/<slug>`. Update it to the excluding form and say *why* in one clause, so the next person does not "simplify" it back.

Add a test: a branch carrying a `work/<slug>/notes.md` must not have that file's content appear in the diff text `codex-review.sh` builds. The hermetic codex-review fixtures with the canned reviewer already exist — extend that suite rather than inventing a new harness.

## Finding 2 (blocking) — `git commit` with no pathspec commits the entire index

`scripts/worktree.sh:85`. Both `git diff --cached --quiet` and `git commit` run without a pathspec, so they consider the whole index, not just `work/$slug`. Reproduced: a staged, unrelated `AGENTS.md` edit in the worktree was swept into a `Record artifacts for <slug>` commit.

This is reachable in normal operation — `/2-implement` runs the sync right after dispatch, **before** step 6's "commit in the worktree if the implementer didn't" — so any work an implementer leaves staged gets committed under a misleading message before the gate runs.

Scope both the guard and the commit to `-- "work/$slug"`. Add a test: with an unrelated staged file present in the worktree, a sync commits only the unit directory and leaves that file staged.

## Finding 3 (blocking) — the primary-checkout guard asks the wrong question

`scripts/worktree.sh:72-73` resolves "where is `main` checked out" rather than "am I in the primary checkout". Two wrong answers:

- **False refusal:** with any non-main branch or a detached HEAD in the primary checkout, `worktree_for_branch main` finds nothing and the command exits 1. CLAUDE.md tells the Owner to do small fixes on a branch in this checkout — leave one checked out and `/4-release` step 1 aborts *before* `release.sh` runs. That is a release refused over bookkeeping, exactly what the plan's "On enforcement" section argued against.
- **False acceptance:** if `main` is checked out in a linked worktree and the primary is on something else, running from that linked worktree passes the guard and syncs from the wrong tree.

The branch-independent test is one line and still only asks git:

    [[ "$(git rev-parse --git-dir)" == "$(git rev-parse --git-common-dir)" ]]

Equal only in the primary checkout. Add a test for the false-refusal case: a primary checkout on a non-main branch must still sync successfully.

## Finding 4 — ARCHI omits the staging scope

`ARCHI.md:15` describes the copy scope but not the surprising half: staging is the whole `work/<slug>` directory, so pre-existing worktree-side files get committed by a command whose name says "sync". That was the decision of the previous round; the hot-tier doc should carry it. One clause.

## Nits — take both

- `scripts/worktree.sh:83` is the repo's first use of `git restore` (git ≥ 2.23); nothing declares a minimum git version and the surrounding code uses older porcelain. `git -C "$wt_root" reset -q -- "work/$slug/plan.md"` is equivalent here and matches the existing vocabulary.
- `skills/2-implement/SKILL.md:21` reads as though `gate.max_retries` applies to the sync. Split it into a sentence.

## Explicitly declined — do NOT fix

- Untracked worktree `plan.md` leaving the tree dirty — only reachable if the worktree was created outside `add`, which seeds the plan.
- The stale-worktree `mkdir -p` case after a directory is deleted without `git worktree prune` — cosmetic.
- Duplication of `worktree_for_branch` with `release.sh` — deliberate, keeps the resolvers identical.

## Constraints (unchanged)

- `set -euo pipefail`; commit gated on `git diff --cached --quiet`, never `|| true`.
- `worktree.sh` only asks git, never inspects `.git` directly. (`git rev-parse --git-dir` is asking git — that is fine.)
- Tests set environment per-command, never `export`. See `knowledge/test-helper-contract.md`.
- Mutation requirement on every new/changed test. **The round-3 reviewer warns that one of its own mutation attempts silently failed to apply and showed a false green — assert your mutation actually landed before trusting a red-or-green result.**
- `scripts/release.sh` stays byte-identical: `git diff main...HEAD -- scripts/release.sh` empty.
- Update ARCHI's check count to whatever the suite reports (currently 126).

## When done

1. `bash scripts/gate.sh` from the repo root — must pass.
2. Confirm `git diff main...HEAD -- scripts/release.sh` is empty.
3. Confirm the diff `scripts/codex-review.sh` builds for this branch contains no `work/work-artifact-capture/` content.
4. Commit on this branch.
5. Print a summary: what changed, what you observed during mutation checks, anything still open.
