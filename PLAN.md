# Plan

One screen, always. Reasoning lives in work units — link, don't restate.

## Objective

An end-to-end agentic development framework for a solo developer: skills-driven plan/implement/review loop, mechanically enforced writer≠reviewer, deterministic gate, worktree isolation. Thin by design — framework work stops the moment real use stops demanding it.

## Now

- k=4 Confirm-delta clock: **3/4** (2026.8.1 + 2026.8.2 + 2026.8.3, all delta none) — 1 more clean release promotes to full TRIP.
- Next candidates: `work/bootstrap-retro.md` (incl. the N=1 manual-seeding gap surfaced by `work/fan-implement`).

## Decisions

- 2026-08-15 — No custom runtime; Claude Code is the orchestrator (Overstory's archival was the cautionary tale) — `3b80c19`
- 2026-08-15 — Gate is a shell script with an exit-code contract; agents never overrule it — `3b80c19`
- 2026-08-15 — knowledge/ starts empty; docs earn their way in — `3b80c19`
- 2026-08-16 — Merge autonomy: confirm-then-push (C), auto-promoting to full TRIP (A) after 4 releases where the confirm changed nothing — `work/trip-release`
- 2026-08-16 — CalVer, not SemVer; all release preconditions enforced by `release.sh` exit codes, never skill prose — `work/trip-release`
- 2026-08-16 — Release validates ARCHI freshness but never regenerates it; `/compact` stays the only ARCHI pipeline — `work/trip-release`
- 2026-08-24 — `work` profile for Atlassian/Bitbucket: config-selected release topology (self ff-merges main; platform-team fetch-guards `origin/main` + pushes a branch for PR), one template not a fork — `work/work-profile` *(topology superseded 2026-08-25)*
- 2026-08-25 — One universal PR-merge release topology under protected `main`; `self` direct-push + `review.human_pr_review` knob removed; tagging moves post-merge to `release.sh tag-after-merge` (verify-then-tag, no push) — `work/pr-merge-topology`

## Risks

- Correlated validators: orchestrator and reviewers are both Claude; deterministic checks carry the weight, agent agreement corroborates.
- The PR-merge flow's `tag-after-merge` verify assumes the PR lands as a fast-forward/rebase so `origin/main`'s tip stays the `Release v<version>` commit; a merge-commit or squash strategy would (correctly) fail the guard and block tagging.
