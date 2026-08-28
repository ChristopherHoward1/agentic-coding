Round-5 review findings on work/work-artifact-capture/plan.md. You are resuming in the same worktree on branch wt/work-artifact-capture.

**The Owner has authorized a sixth round.** Three changes, all one-liners, none touching logic. Both reviewers confirmed the shipped *behavior* is correct — these close a test gap, a skill-prose gap, and a doc gap. Do not refactor anything else.

## Finding 1 (blocking) — the `,top` anchor has no test; dropping it leaks artifacts and the suite stays green

`scripts/codex-review.sh:82` is correct as shipped. The problem is that nothing pins it. Mutating `:(exclude,top)work/$slug` → `:(exclude)work/$slug` (leaving `':/'` alone) leaves the suite at **136/136 passing**, and that mutation is a live artifact leak. Verified from `scripts/` on this branch:

    # shipped form  → 0 artifact files in the reviewer's diff
    git diff --name-only main...wt/<slug> -- ':/' ':(exclude,top)work/<slug>'
    # mutated form  → 8 artifact files leak back in
    git diff --name-only main...wt/<slug> -- ':/' ':(exclude)work/<slug>'

Without `,top` the exclude gets the cwd prefix applied (`scripts/work/<slug>`) and stops matching, while `':/'` keeps the whole tree included — so a reviewer invoked from any subdirectory sees every followup and the other vendor's prior review.

The two tests from `0f33143` split the property and cover only half each:
- `tests/test-scripts.sh:263` runs from the primary root only — catches a *missing* exclusion, not a *mis-anchored* one.
- `tests/test-scripts.sh:268` asserts only that `+feature` is present from a subdirectory — it guards `':/'` but says nothing about the exclusion.

**Fix — one clause.** Make the subdirectory check also assert the artifact marker is absent, e.g. add `! grep -Fq 'do-not-leak-review-artifact' "$TMP/codex-excludes-work-artifacts/prompt.txt"` to that check. Note the capture-prompt reviewer does `cat >"$2"`, so the subdirectory run overwrites `prompt.txt` and the root run's absence assertion no longer applies to it — that is precisely why the subdirectory check must carry its own absence assertion.

Then mutation-check it: change `,top` back out, confirm the subdirectory test goes red, restore. **Assert the mutation actually landed before trusting the result** — false greens from unapplied mutations have bitten twice in this unit.

## Finding 2 (blocking) — Fan Mode has no sync call

`skills/2-implement/SKILL.md` Fan Mode section. The sync calls were added to the single-agent dispatch and the followup path, but the `N>1` flow runs its own steps and then "continue[s] to `/3-review` as in step 6", which never syncs.

An earlier round argued fan mode needed no call because `fan-exec.sh adopt` creates the canonical `wt/<slug>` at the same default path, so `/3-review` and `/4-release` would cover it. That reasoning only holds for units that *reach* `/3-review` step 5 or release — a fan-mode unit escalated at the review cap still loses its artifacts, which is the exact case the `/2-implement` call site exists to close. The earlier judgment was wrong; this is the correction.

**Fix — one line of prose:** sync after `fan-exec.sh adopt` has created and populated the canonical worktree, before handing off to `/3-review`. Match the surrounding voice; do not restructure the section.

## Finding 3 (non-blocking, take it) — ARCHI does not mention the diff scoping

`ARCHI.md:10` still describes `codex-review.sh` as piping "plan+diff to the read-only reviewer", with no mention that the diff now excludes `work/<slug>`. `grep -n "exclude" ARCHI.md` returns nothing. The `worktree.sh` line was updated thoroughly; the script whose reviewer-facing behavior actually changed was not. One clause.

## Explicitly declined — do NOT fix

- **Gitignored primary strays are physically copied into the worktree** before `git add` skips them. Invisible to git, clean-worktree criterion holds, fixture already asserts absence from the tree.
- **The artifact commit at `/4-release` lands after both reviewers approved**, so the released tip carries a commit no reviewer saw. By design — and the `:(exclude)work/$slug/plan.md` pathspec keeps sentinels out of it, so `release.sh`'s sentinel checks still read the reviewed plan.

## Constraints (unchanged)

- `set -euo pipefail`; commit gated on `git diff --cached --quiet`, never `|| true`.
- `worktree.sh` only asks git, never inspects `.git` directly.
- Tests set environment per-command, never `export`. See `knowledge/test-helper-contract.md`.
- `scripts/release.sh` stays byte-identical.
- Update ARCHI's check count to whatever the suite reports (currently 136).

## When done

1. `bash scripts/gate.sh` from the repo root — must pass.
2. `git diff main...HEAD -- scripts/release.sh` empty.
3. Confirm that reverting `,top` turns the subdirectory test red, and that restoring it turns it green again.
4. Commit on this branch.
5. Print a summary: what changed, what you observed during mutation checks (including that each mutation landed), anything still open.
