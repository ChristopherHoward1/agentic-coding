# Base the review diff on freshly-fetched origin/main, not local main

**Slug:** review-diff-base-origin-main · **Date:** 2026-09-08 · **Status:** draft

## Goal

`/3-review` and `scripts/codex-review.sh` both compute the review diff as `git diff main...wt/<slug>` against **local** `main`. When local `main` lags `origin/main` (the normal state — the orchestrator rarely pulls mid-loop), the three-dot diff includes every commit that merged to `origin/main` since local `main` last moved, so both reviewers receive a diff polluted with other units' changes. This has bitten two consecutive units (`implementer-ladder`: 9 commits / 148 KB; `archi-fresh-in-review`: 2 commits, `gate.sh`+`PLAN.md`+another retro), each caught only by eye and hand-fixed with a mid-review FF. Done: both review paths base the diff on a freshly-fetched `origin/main`, so a stale local `main` cannot pollute what reviewers see, with a defined fallback when the fetch fails or no `origin/main` ref exists.

## Approach

One best-effort fetch, then base the diff on `origin/main`, mirroring `worktree.sh add`'s existing pattern **exactly**: `git fetch origin --quiet` (all refs, so `refs/remotes/origin/main` reliably updates — not a single-branch `fetch origin main`), then select `origin/main` when `git show-ref --verify --quiet refs/remotes/origin/main` succeeds, else fall back to local `main`.

- **`scripts/codex-review.sh`** — before computing the diff, `git fetch origin --quiet` (best-effort: a failed fetch is not fatal, matching `worktree.sh`; on failure the code proceeds to the fallback). Compute `base`: `origin/main` if `git show-ref --verify --quiet refs/remotes/origin/main`, else `main` (offline/no-remote fallback — preserves today's behavior). Use `$base...$branch` for the diff (line 99) and reflect `$base` in the DIFF header text (line 98).
- **`skills/3-review/SKILL.md` step 1** — change the prose so the orchestrator fetches (`git fetch origin --quiet`) and diffs `origin/main...wt/<slug>` (with the same `':/' ":(exclude,top)work/<slug>"` pathspec), codifying exactly the manual fix applied during `archi-fresh-in-review`.

**Out of scope — the `main:config.yaml` reviewer-command read (codex-review.sh:35, 63) stays on local `main`.** Moving it to `origin/main` would *preserve* the 2026-08-26 main-bound property (a branch still can't choose the reviewer; `origin/main` is strictly more authoritative), but `reviewer.command` drifts far more rarely than the diff base, so the practical hazard is near-zero and it needlessly re-touches the security-relevant read and its assertion (`tests/test-scripts.sh:830`). Split to a near-zero-priority candidate `codex-config-read-origin-main` rather than bundle it here. Basing the diff on `origin/main` and the config on local `main` is a benign, temporary asymmetry, not incoherence — both are still "main," and the config read is unchanged from today.

Alternative considered: have the orchestrator `git pull` local `main` up to date at the top of `/3-review`. Rejected — mutates the primary checkout's branch state as a review side effect, and local `main` being current is not something review should depend on; basing directly on `origin/main` is the narrower, side-effect-free fix (the fetch only updates remote-tracking refs, not the working tree or local `main`).

## Footprint

Files to modify:
- `scripts/codex-review.sh` — best-effort `git fetch origin --quiet`; `base` selection via `show-ref` with local-`main` fallback; diff (line 99) and DIFF header (line 98) use `$base`. Config read (35/63) unchanged.
- `skills/3-review/SKILL.md` — step 1 diff prose: fetch + `origin/main...wt/<slug>`.
- `tests/test-scripts.sh` — (a) update the existing string-assertion at **line 846** that greps `skills/3-review/SKILL.md` for `git diff main...wt/<slug> -- ':/' ...` to the new `origin/main...` string; (b) add the two new hermetic codex-review cases (below). The pollution case needs its **own fixture with a bare remote** (the current `setup_codex_review_fixture` at line 222 builds no `origin`), modeled on the bare-remote pattern at `tests/test-scripts.sh:953–1026` (`BASE_FEATURE`/`STALE_REPO`/`NO_ORIGIN`).

Files NOT to touch:
- `tests/test-scripts.sh:830` — the `git show "main:config.yaml"` assertion stays green (config read is out of scope, see Approach).
- `tests/test-scripts.sh:1574` — the fan-exec `main...wt/demo` diff is a different flow; leave it.
- `scripts/release.sh` — already fetches and guards `origin/main` (`check_origin_main_ancestor`); its base logic is out of scope.

Note: because the current `setup_codex_review_fixture` has no `origin`, every existing codex-review test now exercises the new fallback path (best-effort fetch fails → no `origin/main` ref → local `main`). This is safe: `check_exit` matches stderr by substring, so the fetch's failure noise does not break those assertions.

## Acceptance criteria

- [ ] `scripts/codex-review.sh` fetches all refs best-effort (`git fetch origin --quiet`; a failed fetch does not abort the review) and computes the review diff against `origin/main` when `refs/remotes/origin/main` exists, else local `main`.
- [ ] The `main:config.yaml` reviewer-command read is unchanged (stays on local `main`); `tests/test-scripts.sh:830` still passes.
- [ ] `skills/3-review/SKILL.md` step 1 instructs a fetch and an `origin/main...wt/<slug>` diff; the existing string-assertion at `tests/test-scripts.sh:846` is updated to the new string and passes.
- [ ] Hermetic test: with a bare remote whose `origin/main` is ahead of local `main`, `codex-review.sh` produces a diff scoped to the branch's own changes only (a file changed solely on `origin/main` since local `main` does NOT appear) — and this test would fail against the old `main...` base.
- [ ] Hermetic test: with no `origin/main` ref (no remote), `codex-review.sh` still runs and bases on local `main` (fallback), exit behavior unchanged.
- [ ] `bash scripts/gate.sh` green.

## Release

Release note: `/3-review` and `codex-review.sh` now base the review diff on a freshly-fetched `origin/main`, so a stale local `main` can no longer pollute what reviewers see.

## Verification

- The two hermetic cases above (ahead-of-local-main pollution excluded; no-remote fallback).
- `bash scripts/gate.sh`

## Review

plan-reviewer verdict: REVISE (fresh opus subagent, cold context). Core design confirmed correct (merge-base collapse under a lagging local `main` is exactly the pollution; `origin/main` base fixes it; fetch/fallback mirrors existing scripts). Four findings, all applied:
1. (Blocking) Footprint omitted existing string-assertions the change breaks — added: update `tests/test-scripts.sh:846` (SKILL.md diff string) + criterion; noted `:830` stays green because the config read is now out of scope; noted `:1574` fan-exec is out of scope.
2. Config-read scope decision — **split out** (not bundled). Owner's call recorded: `reviewer.command` drift hazard is near-zero and moving it re-touches the security-relevant read/assertion for no practical gain; named candidate `codex-config-read-origin-main`. Reviewer confirmed the move would *preserve* the 2026-08-26 property, so this is a cost trade, not a correctness one.
3. Fetch pattern — switched from single-branch `fetch origin main` to all-refs `git fetch origin --quiet` + `git show-ref --verify --quiet refs/remotes/origin/main`, mirroring `worktree.sh` exactly so the tracking ref reliably updates.
4. Test fixtures — recorded that the pollution case needs its own bare-remote fixture (current `setup_codex_review_fixture` has no origin) modeled on `:953–1026`, and that existing codex-review tests now exercise the fallback path (tolerated via substring stderr matching).

Plan verdict: REVISE → addressed; ready for Owner approval.
