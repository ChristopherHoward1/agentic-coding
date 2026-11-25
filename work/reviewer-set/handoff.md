The implementer contract precedes this handoff — it is your contract.
Follow its build-discipline section while staying inside the plan footprint.

Work unit: /Users/cboyfly/Documents/repos/agentic-coding/work/reviewer-set/plan.md  (read it in full; it is your source of truth)
Branch: wt/reviewer-set (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
- `harness/scripts/state.sh`
- `harness/scripts/codex-review.sh` (registry refusal message only)
- `harness/skills/3-review/SKILL.md` (step 3's registry sentence only)
- `harness/skills/4-release/SKILL.md` (step 1: "In registry mode, stop after review:" → "In registry mode, stop here:")
- `harness/tests/test-scripts.sh`
- `ARCHI.md`

Every edit the plan names is authorized; stop only for an edit outside the footprint.
Nothing is committed while you work, so reads through `HEAD` (`git archive`, `git show HEAD:…`) will not see your changes.

Key constraints:
- **`state.sh`:**
  - Registry mode sets `review=approve` on `Code-review verdict: APPROVE` alone; repo mode still requires both sentinel lines.
  - The review-stage `next_action` is `/3-review` when `$unit_dir/codex-review.md` or `$unit_dir/review-round` exists, otherwise `run harness gate`.
  - Update the `ponytail` comment: registry units stop at `stage: release`, even after a hand-merged PR, until `pr-release` defines done.
  - Change nothing else in the stage rules.
- **`codex-review.sh`:** keep the registry guard where it is, at exit 2. Only the message changes, to exactly: `registry mode has no codex reviewer; /3-review uses the code-reviewer only` (die2 adds the `codex-review: ` prefix).
- **`/3-review` step 3:** replace the leading registry sentences ("**Registry mode:** launch only the code-reviewer; record only `Code-review verdict:` until `reviewer-set` lands. `harness state` keeps the unit in `review`.") with exactly: "**Registry mode:** launch only the code-reviewer and record only `Code-review verdict:`; `harness state` then moves an approved unit to `release`." Leave the rest of the step untouched.
- **Tests:**
  - In `registry_flow`, the `state new` assertions after the code-review line become `stage: release` and `next_action: /4-release`.
  - Add a registry case: in review without the code-review line, `run harness gate`; after writing `review-round`, `/3-review`.
  - Update `grep -q reviewer-set` to match the new message.
  - Add a repo-mode `setup_state_fixture` mode (or inline case) for review with `review-round` but no `codex-review.md`, expecting `next_action: /3-review`.
  - Do not change existing repo-mode assertions.
- **`ARCHI.md`:** a targeted edit of the Registry-mode paragraph and the `state.sh` description, as the plan's Approach says. Afterwards `grep -rn 'reviewer-set' harness/ README.md ARCHI.md` must print nothing.
- Do not touch `release.sh`, `fan-exec.sh`, `README.md`, `PLAN.md`, `config.yaml` or anything under `work/`.
- All shell must pass shellcheck.

When done:
1. Run harness gate from the repo root — it must pass.
2. Print a final summary: what changed and why, criteria partially met (if any), out-of-scope observations.
