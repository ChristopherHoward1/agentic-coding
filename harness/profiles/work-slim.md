# Profile: work-slim

For work data-science repos where the harness exists to keep code clean and PRs well defined, not to run a release pipeline. Most work is exploration and runs outside the loop; the loop is reserved for changes big enough to get wrong. The writer ≠ reviewer and gate invariants still hold for anything that reaches a PR.

The `work` profile's **S3 write discipline**, **Snowflake** and **Gate** sections apply unchanged; read them from `$(harness root)/profiles/work.md`. Repos use `harness register` and commit no harness files.

## Declarations required at /init (recorded in ARCHI.md → Verification)

- **Implementer runtime** — `implementer.runtime: claude` with `command: 'claude -p --dangerously-skip-permissions'`, as in `work`, for the rare change that runs `/2-implement`.
- **EVAL_METRIC**, **NOTEBOOK_STRATEGY** and **REPO_HYGIENE** — as defined in `$(harness root)/profiles/machine-learning.md`. Copy `nb-clean.sh` and `ds-hygiene.sh` from `$(harness root)/examples/gate.d/` into the state dir's `scripts/gate.d/`.
- **Gate tools** — the repo's linter and test runner (for example `gate.required_tools: ruff:pytest`).

## Lanes

Pick the lightest lane that fits. When unsure, say which lane and why in one line before starting.

1. **Explore** — no loop, no review. Query, plot, fit and compare in notebooks under `notebooks/<initials>/`, on a branch. Write findings to `reports/<topic>.md`:
   - **Question**, and the decision it informs.
   - **Data** — source, S3 path and partition, row counts, filters.
   - **Method** — what was fit or computed, and against what baseline.
   - **Result** — numbers with uncertainty (n, interval, held-out vs in-sample).
   - **Read** — what the result supports, kept separate from what it does not; caveats; next step.
2. **Ship** — code that a person or a later run depends on. Move it out of the notebook into a `.py` module with tests, in a worktree on its own branch.
   1. `harness gate` passes.
   2. Write the PR description (below) first; it stands in for the plan.
   3. Spawn a fresh `code-reviewer` with the branch diff against `origin/main` and the PR description as the plan. Tell it there is no `harness demo` for this change; the description's **How verified** is the evidence to check. Fix CRITICAL/HIGH findings and re-review with a new reviewer, up to 3 rounds, then escalate to the Owner.
   4. Open the PR. The PR is the record: no VERSION, CHANGELOG, tag or retro.
3. **Loop** — `/1-plan` → `/2-implement` → `/3-review`, only when a wrong approach would cost days: a new pipeline, a schema or data-contract change, a refactor across modules. `/4-release` stops after review in registry mode; open the PR as in Ship step 4. Skip `/5-retro`.

## PR description

```
## What      one purpose; the files that matter
## Why       the problem or question it answers
## How verified
            gate result; for model/data changes, EVAL_METRIC before → after and the data partition
## Out of scope
```

Keep notebooks and reports out of code PRs unless the PR is the report.

## Lessons

No retro stage. When the same thing goes wrong twice, add one line to `PLAN.md → Decisions`.
