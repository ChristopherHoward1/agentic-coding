The implementer contract precedes this handoff — it is your contract.
Follow its build-discipline section while staying inside the plan footprint.

Work unit: /Users/cboyfly/Documents/repos/agentic-coding/work/stacked-units-followups/plan.md  (read it in full; its Approach is the spec and its Acceptance criteria are the test list — implement every criterion as a test case)
Branch: wt/stacked-units-followups (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
- `harness/scripts/lib/stack.sh`
- `harness/scripts/worktree.sh`
- `harness/scripts/release.sh`: in `check_stack_landed`, the same-line hint; at the registry stacked refusal (line 327), the appended hint. Nothing else.
- `harness/tests/test-scripts.sh`
- `ARCHI.md`

Every edit the plan names is authorized; stop only for an edit outside the footprint.
Nothing is committed while you work, so reads through `HEAD` (`git archive`, `git show HEAD:…`) will not see your changes.

Key constraints:
- **Read the test-suite rules first.** Read `/Users/cboyfly/Documents/repos/agentic-coding/knowledge/test-helper-contract.md` before writing any test (Decision 2026-11-26). macOS `/bin/bash` is 3.2, where a failing mid-function `[[ ]]` does not trip `-e`, so every assertion needs `|| return 1` (or `|| exit 1`). Every exit-code check and grep must be independently fatal. When a fixture needs origin to move while the work repo's tracking ref stays stale, advance origin from a separate clone. Never push from the work repo or its worktrees for that, not even by URL.
- **Keep existing command text unchanged.** The text after `to pick it up: ` and after `restack first: ` must stay byte-identical, because the suite extracts and executes it (`test-scripts.sh:2809`, `2817`, `2841`). Put each new hint on the same line, *before* that prefix, exactly as the plan's Approach shows. Do not change any existing assertion in `test-scripts.sh`.
- **Follow the plan's restack spec exactly.**
  - Order: resolve `mainref` first, then check the preconditions in the listed order.
  - The landed test differs by mode (repo vs. registry).
  - Nothing to do only when the target is an ancestor of `wt/<slug>`.
  - Upstream: use `merge-base(target, wt/<slug>)` when `F` is an ancestor of the target, otherwise `F`.
  - On conflict, abort the rebase.
  - Use the exact substrings and output streams the plan gives.
- **Reuse the existing stack fixtures** (`stack_fixture` and friends) and the registry stack fixture, and register every new function in `export -f` and `check`.
- **Leave these alone:** `codex-review.sh`, `state.sh`, `fan-exec.sh`, the skills, `README.md`, `PLAN.md`, `config.yaml` and `work/`.
- **Shellcheck:** all shell must pass it.

When done:
1. Run harness gate from the repo root — it must pass.
2. Print a final summary: what changed and why, each acceptance criterion with the test case that covers it, criteria partially met (if any), out-of-scope observations.
