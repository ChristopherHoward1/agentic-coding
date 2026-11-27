The implementer contract precedes this handoff — it is your contract.
Follow its build-discipline section while staying inside the plan footprint.

Work unit: /Users/cboyfly/Documents/repos/agentic-coding/work/deferral-sweep/plan.md  (read it in full; it is your source of truth)
Branch: wt/deferral-sweep (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
- `ARCHI.md`: one targeted edit to the `harness/tests/test-scripts.sh` bullet. Where it says "`nb-exec.sh` and `data-contract.sh` example-hook cases", name the two new cases: a `TMPDIR` with a trailing slash (nb-exec) and a CSV row wider than its header (data-contract). Also, where it describes the hermetic registry release cases, mention that `pr.md` sections are extracted ignoring `## ` lines inside fences.

Every edit the plan names is authorized; stop only for an edit outside the footprint.
Nothing is committed while you work, so reads through `HEAD` (`git archive`, `git show HEAD:…`) will not see your changes.

Key constraints:
- Edit only `ARCHI.md`. No code, test or skill changes; this is a release-only unit.
- Keep the edit minimal and match the bullet's existing style (one long line, backticked identifiers).
- Verify each claim against `harness/tests/test-scripts.sh` (search for `tmpdir-slash`, `wide)` and `Fenced goal`).

When done:
1. Run harness gate from the repo root — it must pass.
2. Print a final summary: what changed and why, criteria partially met (if any), out-of-scope observations.
