# Plan

One screen, always. Reasoning lives in work units — link, don't restate.

## Objective

An end-to-end agentic development framework for a solo developer: skills-driven plan/implement/review loop, mechanically enforced writer≠reviewer, deterministic gate, worktree isolation. Thin by design — framework work stops the moment real use stops demanding it.

## Now

- `work/work-profile` released as 2026.8.1 (k=4 Confirm-delta clock: 1/4, delta none).
- `work/fan-implement` (approved, plan-reviewer APPROVE round 2) — opt-in best-of-N implement mode (`implementer.fan`); reduces per-run variance, does **not** close the correlated-validator risk. Next: `/2-implement`. After it: candidates from `work/bootstrap-retro.md`.

## Decisions

- 2026-08-15 — No custom runtime; Claude Code is the orchestrator (Overstory's archival was the cautionary tale) — `3b80c19`
- 2026-08-15 — Gate is a shell script with an exit-code contract; agents never overrule it — `3b80c19`
- 2026-08-15 — knowledge/ starts empty; docs earn their way in — `3b80c19`
- 2026-08-16 — Merge autonomy: confirm-then-push (C), auto-promoting to full TRIP (A) after 4 releases where the confirm changed nothing — `work/trip-release`
- 2026-08-16 — CalVer, not SemVer; all release preconditions enforced by `release.sh` exit codes, never skill prose — `work/trip-release`
- 2026-08-16 — Release validates ARCHI freshness but never regenerates it; `/compact` stays the only ARCHI pipeline — `work/trip-release`
- 2026-08-24 — `work` profile for Atlassian/Bitbucket: config-selected release topology (self ff-merges main; platform-team fetch-guards `origin/main` + pushes a branch for PR), one template not a fork — `work/work-profile`

## Risks

- Correlated validators: orchestrator and reviewers are both Claude; deterministic checks carry the weight, agent agreement corroborates.
- `/4-release` has never run for real — its tests pass, but the first live release (2026.8.1) is the actual validation.
