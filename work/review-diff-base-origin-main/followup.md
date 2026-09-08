You are resuming the implementer role in the same worktree on branch wt/review-diff-base-origin-main for work/review-diff-base-origin-main/plan.md.

Code review round 1 returned one blocking HIGH finding. Fix exactly this, stay inside the plan footprint, re-run the gate, commit, and print an updated summary.

HIGH — skills/3-review/SKILL.md step 1 lacks the fallback that scripts/codex-review.sh has.
- The script correctly falls back to local `main` when `refs/remotes/origin/main` is absent (offline / fresh clone / no remote). But step 1's prose now instructs the orchestrator to run `git diff origin/main...wt/<slug>` with NO fallback, so in a checkout without an `origin/main` remote-tracking ref the diff command fails and review can't be assembled. The plan goal requires BOTH review paths to have "a defined fallback when the fetch fails or no `origin/main` ref exists."
- Fix: reword step 1 so the orchestrator falls back to local `main` when `origin/main` is unavailable — mirroring the script's `git show-ref --verify --quiet refs/remotes/origin/main` gate. Keep it concise prose; e.g. instruct: fetch (`git fetch origin --quiet`), then diff `origin/main...wt/<slug>` (falling back to `main...wt/<slug>` if `origin/main` is absent) with the same `-- ':/' ":(exclude,top)work/<slug>"` pathspec.
- If you change the exact diff-command string that tests/test-scripts.sh asserts (the "3-review skill keeps codex-review work artifacts out of diff" check greps for `git diff origin/main...wt/<slug> -- ':/' ":(exclude,top)work/<slug>"`), keep that literal substring present in the skill so the assertion still passes — add the fallback as surrounding prose, don't break the asserted string. Update the assertion only if you deliberately change that string, and keep it green.

Do not touch anything else. Re-run scripts/gate.sh until green, commit the fix on this branch, and print what changed.
