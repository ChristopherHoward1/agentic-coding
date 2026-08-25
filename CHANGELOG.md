# Changelog

All notable changes to this project are documented in this file.
## [2026.8.2] - 2026-08-25

- Collapse to a single PR-merge release topology under protected `main` — `release.sh` never touches `main`, `/4-release` pushes the branch for a PR and tags after it merges; the `self` direct-push mode and `review.human_pr_review` knob are removed.
- Confirm-delta: none

## [2026.8.1] - 2026-08-24

- Add `work` profile with a config-selected release topology (self vs platform-team), Bitbucket Pipelines CI, and a Claude implementer runtime for Atlassian workplaces.
- Confirm-delta: none

