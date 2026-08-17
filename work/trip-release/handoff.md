You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.

Work unit: work/trip-release/plan.md  (read it in full; it is your source of truth)
Branch: wt/trip-release (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
Create:
- skills/4-release/SKILL.md
- scripts/release.sh
- VERSION
- CHANGELOG.md
Modify:
- CLAUDE.md (merge-authority amendment + promotion rule)
- PLAN.md (only if a decision line is missing; the 2026-08-16 lines already exist)
- skills/1-plan/prompts/plan.tpl (add `Release note:` field and `Verdict:` line in `## Review`)
- skills/3-review/SKILL.md (one line: record final verdict as `Verdict: APPROVE|REVISE`)
Do NOT touch: scripts/gate.sh, scripts/worktree.sh, scripts/agent-exec.sh, any other skill. No promotion-counter machinery anywhere.

Key constraints:
- ALL enforcement lives in scripts/release.sh (exit-code contract like gate.sh). skills/4-release/SKILL.md must contain zero enforcement language — it only invokes the script and reacts to its exit code.
- release.sh preconditions (each exits non-zero with a clear message):
  1. Unit's work/<slug>/plan.md contains a line matching ^Verdict: APPROVE$ (exact sentinel; prose mentions of APPROVE must not match).
  2. scripts/gate.sh exits 0.
  3. ARCHI.md is fresh: last commit touching ARCHI.md is not older than `git log -1 --format=%ct -- scripts/ skills/ profiles/ config.yaml CLAUDE.md`. Stale → fail with "run /compact first".
  4. New version exceeds VERSION numerically, field-by-field (CalVer YYYY.MM.MICRO, MICRO unpadded: 2026.8.10 > 2026.8.9 must hold; never string compare).
- Happy path after preconditions: bump VERSION → prepend CHANGELOG.md entry (Keep-a-Changelog shape, CalVer heading, containing the unit plan's `Release note:` line and a `Confirm-delta:` line) → release commit → tag vYYYY.MM.MICRO → fast-forward merge to local main → STOP before push (the push is Owner-confirmed in-session; release.sh must never push).
- CLAUDE.md amendment: replace "Merge — the Owner's call, always." and any contradictory sentence. State: orchestrator runs /4-release including push after one in-session Owner confirm; each release logs Confirm-delta in CHANGELOG.md; after 4 consecutive `none` entries the Owner drops the confirm (full autonomy) via a one-line edit. `grep -n "Owner's call" CLAUDE.md` must return nothing afterward.
- VERSION starts at 2026.8.0 (this release stage itself will cut the first real version later).
- release.sh must pass shellcheck (the gate runs it automatically on all tracked .sh files).
- Include the acceptance-criteria demonstrations where scriptable: version-comparison edge case (.9 → .10 bumps; .10 → .9 refuses) should be verifiable by running release.sh's compare logic — structure the script so the compare function can be exercised (e.g. a `release.sh check-version <new>` subcommand or similar) without doing a full release.
- Match sibling skill format for skills/4-release/SKILL.md (see skills/3-review/SKILL.md for shape: frontmatter name/description, Steps, Rules).

When done:
1. Run scripts/gate.sh from the repo root — it must pass.
2. Commit your work on this branch with a clear message.
3. Print a final summary: what changed and why, criteria partially met (if any), out-of-scope observations.
