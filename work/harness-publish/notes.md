Implemented the harness-only publisher, skeleton moves/config, `/init` seeding instructions, release flow, docs, and hermetic publish tests. Everything remains unstaged and uncommitted.

Validation:

- ShellCheck 0.11.0: passed.
- Publish tests: 6/6 passed.
- Smoke suite: 231 passed; nested repo gate failed.
- Required worktree gate: **failed** because `git ls-files` still lists the three deleted, unstaged scripts. The orchestrator must stage the changes and rerun the gate; changing its file discovery is outside scope.

Mutation evidence, both restored:

- Full-HEAD archive: verified old command absent/replacement present; `publish_first` failed; platform `Darwin`.
- Tag-check bypass: verified old condition absent/replacement present; `publish_tags` failed; platform `Darwin`.

Remaining: green gate after staging, orchestrator’s cleanup mutation and demo. Evidence is provided here for `notes.md`, which is outside the footprint. No other out-of-scope observations.


## Orchestrator evidence (macOS)

- Export-temp-dir removal: line 20 `trap 'rm -rf "$exp"' EXIT` → `trap ':' EXIT`; landing check: `rm -rf "$exp"` count 0; failed `publish (a)` and `publish (b): up to date leaves TMPDIR empty`; platform Darwin; restored → 6/6 pass.
- Gate after orchestrator commit: PASS. Demo: exit 0, output matches Expected. Grep criterion (plus `green CI`, `export/sync`, `export suites`): no hits.
