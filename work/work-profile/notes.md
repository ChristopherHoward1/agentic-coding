Implemented the work-profile changes within the declared footprint.

Changed:
- `config.yaml`: added `review.human_pr_review: self`, added `work` to profile comment, added commented Claude implementer command.
- `scripts/release.sh`: added `self` vs `platform-team` release topology, including the double `origin/main` ancestor guard for platform-team mode.
- `tests/test-scripts.sh`: added platform-team single release, sequential stale-branch collision, and mid-gate `origin/main` move coverage.
- `skills/4-release/SKILL.md` and `skills/init/SKILL.md`: documented mode-specific release handling and `work` profile behavior.
- Added `profiles/work.md` and `bitbucket-pipelines.yml`.
- Included `work/work-profile/plan.md` as requested.

Verification:
- `bash tests/test-scripts.sh` passed.
- `bash scripts/gate.sh` passed.

Partial:
- I could not commit the work because Git’s index for this worktree is outside the writable sandbox:
  `fatal: Unable to create '.../agentic-coding/.git/worktrees/work-profile/index.lock': Operation not permitted`

Out of scope noted:
- `ARCHI.md` was not touched, per plan.
