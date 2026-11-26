# Profile: work-slim

For work data-science repos where the harness exists to keep code clean and PRs well defined, not to run a release pipeline. Most work is exploration and runs outside the loop; the loop is reserved for changes big enough to get wrong. The writer ≠ reviewer and gate invariants still hold for anything that reaches a PR.

The `work` profile's **S3 write discipline**, **Snowflake** and **Gate** sections apply unchanged; read them from `$(harness root)/profiles/work.md`. Repos use `harness register` and commit no harness files.

## Declarations required at /init (recorded in ARCHI.md → Verification)

- **Implementer runtime** — `implementer.runtime: claude` with `command: 'claude -p --dangerously-skip-permissions'`, as in `work`, for the rare change that runs `/2-implement`.
- **EVAL_METRIC**, **NOTEBOOK_STRATEGY** and **REPO_HYGIENE** — as defined in `$(harness root)/profiles/machine-learning.md`. Copy `nb-clean.sh` and `ds-hygiene.sh` from `$(harness root)/examples/gate.d/` into the state dir's `scripts/gate.d/`.
- **integration_branch** — check `origin/dev` and `origin/develop`; for a candidate run `git merge-base --is-ancestor origin/main origin/<candidate>` and show the Owner the result before confirmation. If it fails, recommend creating `dev` from `origin/main`, or a new branch such as `integration` if the candidate is `dev`, only with the Owner's yes; if neither exists, offer to create `dev` from `origin/main` only with the Owner's yes. Record the answer in `$(harness project)/config.yaml`. Ask a registered project missing the key before its first Explore, Ship or Promote.
- **Gate tools** — the repo's linter and test runner (for example `gate.required_tools: ruff:pytest`).

## Integration branch

`<integration>` means the configured `integration_branch` value. Units and ad hoc work land on `integration_branch` only through PRs, never direct pushes; `main` changes only through Promote. Open and merge PRs through the Bitbucket REST API, using `merge_strategy: merge_commit` for self-merges so PR numbers remain in merge subjects. The Owner may click merge instead.

## Lanes

Pick the lightest lane that fits. When unsure, say which lane and why in one line before starting.

1. **Explore** — no loop, no review. Query, plot, fit and compare in notebooks under `notebooks/<initials>/`, on a branch from `origin/<integration>`; never use a `wt/` branch name. Merge keepers through a self-merged PR without review. Write findings to `reports/<topic>.md`:
   - **Question**, and the decision it informs.
   - **Data** — source, S3 path and partition, row counts, filters.
   - **Method** — what was fit or computed, and against what baseline.
   - **Result** — numbers with uncertainty (n, interval, held-out vs in-sample).
   - **Read** — left blank for the Owner. Fill it only when asked.

   Notebooks the agent writes or edits carry structure, core findings and a short descriptive read. Reasoning about what the results mean is left to the Owner, more so here than for backing scripts.
   - Markdown cells hold headings and subheadings: one question per heading, followed by the code that answers it.
   - After the code: the core finding (the number, its n and interval, the partition), then at most two or three lines of descriptive analysis: direction, size, and how it compares with the baseline or a prior run.
   - Each question heading's section (not each subheading) ends with a markdown cell holding only `**Owner:**`. Add one to each section the agent writes or edits; leave sections it doesn't touch as they are. The agent never writes in, edits or deletes an Owner cell; an existing Owner cell keeps its text and moves with its heading.
   - No interpretation of what a result means, recommendations, caveat lists or next steps unless the Owner asks. When asked, expand only the section named.

2. **Ship** — code that a person or a later run depends on. Move it out of the notebook into a `.py` module with tests, using `harness worktree add <slug>`.
   1. `harness gate` passes.
   2. Write the PR description (below) first; it stands in for the plan.
   3. Spawn a fresh `code-reviewer` with the diff `git diff "$(harness worktree base <slug>)...wt/<slug>"` and the PR description as the plan. Tell it there is no `harness demo` for this change; the description's **How verified** is the evidence to check. Fix CRITICAL/HIGH findings and re-review with a new reviewer, up to 3 rounds, then escalate to the Owner.
   4. Re-run `harness gate` on the final head after review fixes and record its SHA. Open the PR against the integration branch; after the reviewer approves, add `Reviewed-SHA: <gated sha>` to the PR description. Check immediately before merging that the gated SHA starts with the PR's `source.commit.hash`. The PR is the record: no VERSION, CHANGELOG, tag or retro.
3. **Loop** — `/1-plan` → `/2-implement` → `/3-review`, only when a wrong approach would cost days: a new pipeline, a schema or data-contract change, a refactor across modules. `/4-release` runs `harness release` to gate the reviewed SHA and write `work/<slug>/pr.md`. Open the PR against the integration branch with `pr.md` as its description. Before merging, check that `Reviewed-SHA` starts with the PR’s `source.commit.hash`. Ship step 4’s manual gate and SHA steps do not apply. Skip `/5-retro`.

   Merge Loop PRs by merge commit or fast-forward only; squash and rebase merges rewrite the SHA, so `harness state` cannot report done.

4. **Promote** — only when the Owner asks.
   1. Run `git fetch origin`, then pin the integration tip with `sha=$(git rev-parse origin/<integration>)`.
   2. If `git diff --quiet "$(git merge-base origin/main "$sha")" origin/main` fails, main moved outside Promote: stop and tell the Owner; merge `origin/main` into the integration branch through a self-merged PR, then re-run Promote.
   3. Run `git worktree add --detach <tmp> "$sha"`, run `harness gate` there, note the SHA, then `git worktree remove <tmp>`.
   4. Push the gated SHA to a frozen branch with `git push origin "$sha":refs/heads/promote/<short-sha>` and open its PR to `main`. Never update an existing promote branch; a new gated SHA gets a new branch and PR. Record the gated SHA (the promote branch head) in the description. List each PR since the last promote using numbers from `git log --first-parent --merges origin/main..$sha` merge subjects and titles and source branches from the REST API.
   5. Tag a PR `[reviewed]` only when its description has a `Reviewed-SHA:` line whose SHA starts with the PR's merged `source.commit.hash`; tag every other PR `[unreviewed]`. List merges without PR numbers and every commit from `git log --first-parent --no-merges origin/main..$sha` as `[unreviewed]` with SHA and subject. In How verified claim review only for `[reviewed]` lines, and add the gate result and SHA.
   6. Never merge to `main`; the coworker's approval is the release.

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
