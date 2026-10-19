# Code review round 2 (Claude code-reviewer): APPROVE

Ran:
- gate (228/0, export 12/0)
- demo (matches Expected)
- footprint, dispatcher listing and prose greps
- the gate-cd mutation, in a scratch clone
- edge probes: nested register, missing state config, missing ARCHI, deleted subdir

Findings:
- MEDIUM 1: `archi-fresh wt/harness-registry` is stale after followup commit `2ed1c4e`. → healed by `/3-review` step 7.
- LOW 2: gitignore metacharacters in `--subdir`. → `deferrals.md`.
- LOW 3: the `--name ..` and bad-default-name cases don't assert exit code exactly 1. Recorded, not acted on.
- LOW 4: in repo mode, a deleted primary checkout makes worktree-side commands exit 2. Recorded, not acted on.
