# Plan

One screen, always. Reasoning lives in work units — link, don't restate.

## Objective

An end-to-end agentic development framework for a solo developer: skills-driven plan/implement/review loop, mechanically enforced writer≠reviewer, deterministic gate, worktree isolation. Thin by design — framework work stops the moment real use stops demanding it.

## Now

- Two dogfood cycles shipped: `work/ci-workflow` (CI green) and `work/trip-release` (/4-release stage + merge-authority amendment, merged 2026-08-17). Loop is now plan → implement → review → release; next release cuts 2026.8.1 and starts the k=4 Confirm-delta promotion clock.

## Decisions

- 2026-08-15 — No custom runtime; Claude Code is the orchestrator (Overstory's archival was the cautionary tale) — `3b80c19`
- 2026-08-15 — Gate is a shell script with an exit-code contract; agents never overrule it — `3b80c19`
- 2026-08-15 — knowledge/ starts empty; docs earn their way in — `3b80c19`
- 2026-08-16 — Merge autonomy: confirm-then-push (C), auto-promoting to full TRIP (A) after 4 releases where the confirm changed nothing — `work/trip-release`
- 2026-08-16 — CalVer, not SemVer; all release preconditions enforced by `release.sh` exit codes, never skill prose — `work/trip-release`
- 2026-08-16 — Release validates ARCHI freshness but never regenerates it; `/compact` stays the only ARCHI pipeline — `work/trip-release`

## Risks

- The agent loop is untested end-to-end — everything above the shell layer is hypothesis until the dogfood cycle runs.
- Correlated validators: orchestrator and reviewers are both Claude; deterministic checks carry the weight, agent agreement corroborates.
