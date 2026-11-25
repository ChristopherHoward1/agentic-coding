The implementer contract precedes this handoff — it is your contract.
Follow its build-discipline section while staying inside the plan footprint.

Work unit: /Users/cboyfly/Documents/repos/agentic-coding/work/registry-subdir-literal/plan.md  (read it in full; it is your source of truth)
Branch: wt/registry-subdir-literal (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
- `harness/scripts/register.sh`
- `harness/tests/test-scripts.sh` (one new case in the registry section, next to `registry_register` / `registry_subdir`)
- `ARCHI.md` (targeted edit to the `register.sh` clause in the `harness/scripts/lib/project.sh` bullet only)

Every edit the plan names is authorized; stop only for an edit outside the footprint.
Nothing is committed while you work, so reads through `HEAD` (`git archive`, `git show HEAD:…`) will not see your changes.

Key constraints:
- Two changes in `register.sh`, nothing more. (1) Build the exclude line with `[ ] * ? \` backslash-escaped, for example `sed 's/[][\\*?]/\\&/g'`. The existing `grep -qxF` idempotency check must compare against the escaped line. (2) Run the tracked check as `git ls-files -- ":(literal)${subdir:+$subdir/}CLAUDE.local.md"`.
- The new test case follows the existing registry cases:
  - use `registry_fixture` / `registry_run`, or the same pattern with a distinct fixture name per subdir;
  - use the shellcheck disable header line;
  - add it to `export -f` and register it with `check`.
  - Use `--name` because metacharacter subdirs fail the default name.
- Cover every acceptance criterion:
  - the `app[1]` missing-file case (exact escaped exclude line plus empty porcelain);
  - the `a*b`/`q?`/`a\b` over-match cases via `git check-ignore -q` (registered path ignored, sibling path not);
  - tracked check: register succeeds with a tracked `app1/…` and with a tracked `axb/…`, and still refuses with a tracked `app[1]/…`;
  - an idempotent re-run leaves exactly one matching line.
- The case must fail if only the `*` escape is dropped, so assert the `a*b` sibling explicitly.
- Do not modify the existing registry cases. Do not touch `config.yaml`, `harness/skeleton/`, `PLAN.md`, or anything under `work/`.
- All shell must pass shellcheck; keep `set -euo pipefail` style as in `register.sh`.

When done:
1. Run harness gate from the repo root — it must pass.
2. Print a final summary: what changed and why, criteria partially met (if any), out-of-scope observations.
