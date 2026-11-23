The implementer contract precedes this handoff — it is your contract.
Follow its build-discipline section while staying inside the plan footprint.

Work unit: /Users/cboyfly/Documents/repos/agentic-coding/work/integration-branch/plan.md  (read it in full; it is your source of truth)
Branch: wt/integration-branch (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
- `harness/scripts/lib/stack.sh`
- `harness/scripts/worktree.sh`
- `harness/scripts/release.sh`
- `harness/tests/test-scripts.sh`
- `harness/skeleton/config.yaml`
- `harness/profiles/work-slim.md`
- `harness/skills/docs/SKILL.md` (line 16 only)
- `ARCHI.md`

`PLAN.md` is in the plan's footprint but belongs to the orchestrator; do not edit it.

Every edit the plan names is authorized; stop only for an edit outside the footprint.
Nothing is committed while you work, so reads through `HEAD` (`git archive`, `git show HEAD:…`) will not see your changes.

Key constraints:
- `integration_ref` in `lib/stack.sh` has an exact exit contract: 0 prints `origin/<branch>`; 1 means unset or `main` (caller keeps its existing fallback byte-for-byte); 2 is an error with a message on stderr naming the branch and `integration_branch`. Callers run under `set -e`; test the status explicitly (`if ref=$(integration_ref); then … else rc=$?; …`). Read the key from `$STATE_DIR/config.yaml` (a missing file means unset), strip surrounding single/double quotes, validate with `git check-ref-format --branch`.
- `review_base` only changes `mainref`'s value; leave its fork-point logic alone. Stacked `worktree add` still branches from `wt/<parent>`.
- `worktree.sh`: make the missing-config `/dev/null` fallback (line 50) apply in both modes.
- `release.sh`: the integration-branch refusal is the first statement of `release()`, before any `cd` or worktree check, reusing the helper's key reader. Do not touch `codex-review.sh` or `tag_after_merge`.
- Tests: write new cases with the existing helpers. `check_exit` greps stderr only, and `check` discards stdout, so capture stdout in a `bash -c` body when asserting it. Every new guard must be shown to fail when the guard is removed, and that mutation must be confirmed to have landed — see `knowledge/test-helper-contract.md` and `knowledge/silent-no-op-hazards.md` (PLAN.md Decisions 2026-08-27 and 2026-08-28). Set `HARNESS_HOME` to an empty temp dir in each new fixture, so a real `~/.harness` registry can't match. Existing worktree/stack cases must pass unchanged.
- `work-slim.md`: write each acceptance criterion's named strings literally (for example `merge_strategy: merge_commit`, `source.commit.hash`, `close_source_branch: false`, `git rev-list --no-merges`, `git log --first-parent --no-merges`, `git worktree add --detach`, `[reviewed]`, `[unreviewed]`, `git merge-base --is-ancestor origin/main`). Keep the profile terse, matching its current style; it is prose for an agent, not an essay.
- `ARCHI.md`: targeted edits only, at the places the plan lists.
- Run every acceptance-criterion command and `harness demo integration-branch` from the worktree root after your changes, before finishing.

When done:
1. Run harness gate from the repo root — it must pass.
2. Print a final summary: what changed and why, criteria partially met (if any), out-of-scope observations.
