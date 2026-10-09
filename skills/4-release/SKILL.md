---
name: 4-release
description: Run the release script for a work unit, then push, PR, and tag autonomously (full TRIP).
---

# /4-release — release

Input: a work unit slug.

## Steps

1. **Run the release script:** from the repo root, run `scripts/worktree.sh sync-artifacts <slug>`, then `bash scripts/release.sh <slug> --confirm-delta "none"` (full TRIP: no in-session confirmation; `Confirm-delta` is logged as `none`).
2. **React to the exit code:**
   - Exit 0 → report the bump commit on the release branch, that no tag exists yet, and that `main` was untouched.
   - Non-zero → report the script output and stop.
3. **Check README drift:** confirm README's loop, skills and Layout sections still match the shipped skills and scripts; fix drift via the small-fix path, never mentioning dogfood-only scripts (README ships in exported templates).
4. **Push the release branch and open the PR** against `main` autonomously; never push `main` directly. `main` stays protected, so a PR + merge is still required. After the PR merges, run `bash scripts/release.sh tag-after-merge <slug>`. If it exits non-zero, report the output and stop. If it succeeds, run `git push origin v<version>`.
5. **Refresh after the release:** check each primary-checkout untracked `work/<slug>/` copy against `origin/main`, delete matching copies, then run `git pull --ff-only`.
   If `scripts/sync-template.sh` exists, confirm `HEAD` carries `v<version>`, then run `bash scripts/sync-template.sh`.
   - `up to date` → nothing to do.
   - A printed branch → work from the printed clone so `gh` resolves the template repo. Push the printed branch with `--force-with-lease` so a retry replaces an earlier failed attempt, then run `gh pr create` against `main`. Use `gh pr list` / `gh pr close` to close any older open `template-sync/*` PR as superseded. Merge once CI is green (full TRIP, as with the release PR).
   - Red template CI → report it and leave the PR open. The release is already done and stays done.
6. **Invoke `/5-retro`** for the released unit.

## Rules

- The release script is the source of truth for the release result.
- Full TRIP: the Orchestrator runs the release, push, PR, and tag without an in-session Owner confirmation. (The harness may still independently gate the PR merge into protected `main`; that is a platform guard, not a framework confirmation.)
