# Changelog

All notable changes to this project are documented in this file.
## [2026.8.8] - 2026-08-27

- Enforcement hardening — retro marker must match origin/main byte-for-
- Confirm-delta: none

## [2026.8.7] - 2026-08-26

- New `/5-retro` stage — release.sh now refuses to release a unit until the previous unit's retro exists and is non-empty; lessons route into gate hooks, knowledge/ docs, or PLAN.md decisions.
- Confirm-delta: none

## [2026.8.6] - 2026-08-26

- Release now requires a second, read-only codex review — cross-vendor approval enforced by `release.sh`, not prose. (Binds from the next unit onward.)
- Confirm-delta: none

## [2026.8.5] - 2026-08-25

- /2-implement starts implementation branches from origin/main and seeds the plan onto the single-agent worktree — no manual rebase or plan-commit before release.
- Confirm-delta: none

## [2026.8.4] - 2026-08-25

- machine-learning profile ships a concrete notebook-collision policy (strip-outputs gate hook + ownership convention) for multi-author ML repos.
- Confirm-delta: none

## [2026.8.3] - 2026-08-25

- Add opt-in best-of-N implement mode (`implementer.fan`) — N Claude samples in isolated worktrees, gate-filtered, winner picked by a fresh selector; default N=1 unchanged.
- Confirm-delta: none

## [2026.8.2] - 2026-08-25

- Collapse to a single PR-merge release topology under protected `main` — `release.sh` never touches `main`, `/4-release` pushes the branch for a PR and tags after it merges; the `self` direct-push mode and `review.human_pr_review` knob are removed.
- Confirm-delta: none

## [2026.8.1] - 2026-08-24

- Add `work` profile with a config-selected release topology (self vs platform-team), Bitbucket Pipelines CI, and a Claude implementer runtime for Atlassian workplaces.
- Confirm-delta: none

