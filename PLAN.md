# Plan

One screen, always. Reasoning lives in work units — link, don't restate.

## Objective

An end-to-end agentic development framework for a solo developer: skills-driven plan/implement/review loop, mechanically enforced writer≠reviewer, deterministic gate, worktree isolation. Thin by design — framework work stops the moment real use stops demanding it.

## Now

- `/init` shakedown done (skill discovery, gate, codex all verified). Now dogfooding the full loop on the first real task: **`work/ci-workflow`** (add GitHub Actions CI) — approved, in `/2-implement`. See `work/bootstrap-retro.md` for the remaining task list, known gaps, and logged candidate improvements.

## Decisions

- 2026-08-15 — No custom runtime; Claude Code is the orchestrator (Overstory's archival was the cautionary tale) — `3b80c19`
- 2026-08-15 — Gate is a shell script with an exit-code contract; agents never overrule it — `3b80c19`
- 2026-08-15 — knowledge/ starts empty; docs earn their way in — `3b80c19`

## Risks

- The agent loop is untested end-to-end — everything above the shell layer is hypothesis until the dogfood cycle runs.
- Correlated validators: orchestrator and reviewers are both Claude; deterministic checks carry the weight, agent agreement corroborates.
