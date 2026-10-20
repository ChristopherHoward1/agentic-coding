The implementer contract precedes this handoff — it is your contract.
Follow its build-discipline section while staying inside the plan footprint.

Work unit: /Users/cboyfly/Documents/repos/agentic-coding/work/demo-fail-fast/plan.md  (read it in full; it is your source of truth)
Branch: wt/demo-fail-fast (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
- harness/scripts/demo.sh
- harness/tests/test-scripts.sh (demo section, around lines 823-910)
- harness/skills/1-plan/prompts/plan.tpl (Demonstration guidance)
- ARCHI.md (lines 18, 21, 59: the "plain bash" mentions of demo.sh)
(PLAN.md is the orchestrator's; do not touch it.)

Every edit the plan names is authorized; stop only for an edit outside the footprint.
Nothing is committed while you work, so reads through `HEAD` (`git archive`, `git show HEAD:…`) will not see your changes.

Key constraints:
- Change only the runner line `(cd "$dir" && bash "$block")` to `bash -e`; keep the exit contract (0/1/2) and the dirty-tree check untouched. Do not add -u or pipefail.
- Tests must follow knowledge/test-helper-contract.md and knowledge/silent-no-op-hazards.md (read both). In particular: on macOS Bash 3.2 a failing `[[ ]]` that is not the last command does not trip errexit, so assertions inside `bash -c` checks must be the final command or chained with `&&` / `|| exit 1`. Show each new fail-fast check fails with `-e` removed from demo.sh (then restore it).
- Remove `false` from the shared fixture heredoc (test-scripts.sh:827-842, `false` at 835); keep the `## ` comment line. Replace the "demo passes with plain bash despite an intermediate failure" check (line 843) with the fail-fast checks from the plan.
- `check_exit` (test-scripts.sh:31) discards stdout; the stdout assertion must be a separate `check ... bash -c` that tolerates demo.sh exiting 1.
- plan.tpl guidance: three or four lines, as the acceptance criterion states.
- Bash 3.2 compatible; shellcheck clean.

When done:
1. Run harness gate from the repo root — it must pass.
2. Print a final summary: what changed and why, criteria partially met (if any), out-of-scope observations.
