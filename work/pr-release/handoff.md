The implementer contract precedes this handoff — it is your contract.
Follow its build-discipline section while staying inside the plan footprint.

Work unit: /Users/cboyfly/Documents/repos/agentic-coding/work/pr-release/plan.md  (read it in full; it is your source of truth — its Approach is the spec, and its Acceptance criteria are the test list)
Branch: wt/pr-release (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
- `harness/scripts/release.sh`: the registry branch only. Add a `registry_release` function, change the registry `tag-after-merge` message, and add the `--confirm-delta` rejection. Do not change `release`, `tag_after_merge` or any `check_*` function. You may call `check_clean_worktree`, `worktree_for_branch` and `extract_release_note`.
- `harness/scripts/state.sh`: registry release and done rules after `review: approve`; remove the `ponytail` comment.
- `harness/skills/3-review/SKILL.md`: the registry sentences in steps 1 and 6.
- `harness/skills/4-release/SKILL.md`: the registry sentence in step 1.
- `harness/profiles/work-slim.md`: the Loop lane item, plus the merge-strategy line.
- `harness/tests/test-scripts.sh`
- `README.md` (line 43)
- `ARCHI.md`: line 40, the `release.sh` and `state.sh` descriptions, and the line-51 verdict-sentinel convention.

Every edit the plan names is authorized; stop only for an edit outside the footprint.
Nothing is committed while you work, so reads through `HEAD` (`git archive`, `git show HEAD:…`) will not see your changes.

Key constraints:
- **Do not touch** `harness/scripts/lib/stack.sh`, `fan-exec.sh`, `codex-review.sh`, `PLAN.md`, `config.yaml` or anything under `work/`.
- **`registry_release`:**
  - Use `"$HERE/gate.sh"` run from inside the worktree (`(cd "$wt" && bash "$HERE/gate.sh")`), and `"$HERE/archi-fresh.sh" "wt/$slug"`.
  - Resolve the base with `integration_ref` from `lib/stack.sh`, or `origin/main` when it returns 1. Propagate a status of 2 as a refusal.
  - Fetch the base before the ancestor check.
  - Write `pr.md` via a temp file in `$STATE_DIR/work/<slug>/` and `mv`.
  - Use the exact refusal substrings from the plan's Approach. Every pre-gate check runs before the gate.
- **`state.sh`:**
  - Never fetch.
  - Use `integration_branch` only (not `integration_ref` or `review_base`), and check `refs/remotes/origin/<branch>` (or `origin/main`) locally.
  - Read `pr.md`'s last `^Reviewed-SHA:` line.
- **Tests:** follow the existing registry helpers (`registry_fixture`, `registry_run`) and the shellcheck-disable header convention, and register every new function in `export -f` and `check`.
  - Give the fixture a bare origin.
  - Pre-gate refusal cases use a marker-writing `$S/scripts/gate.d/` hook and assert the marker is absent.
  - The no-fetch state case pushes by URL, never by the remote name `origin`.
  - Rewrite the `grep -q pr-release` assertion in `registry_flow`; leave its other assertions as they are.
- **Afterwards:** `grep -rn 'pr-release' harness/ README.md ARCHI.md` must print nothing.
- **Shellcheck:** all shell must pass it. Keep `set -euo pipefail` semantics as in `release.sh`.

When done:
1. Run harness gate from the repo root — it must pass.
2. Print a final summary: what changed and why, criteria partially met (if any), out-of-scope observations.
