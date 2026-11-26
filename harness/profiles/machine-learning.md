# Profile: machine-learning

For projects where model/data quality — not just code correctness — defines done.

## Declarations required at /init (recorded in ARCHI.md → Verification)

- **EVAL_METRIC** — the metric that defines "better", or `NONE` if evaluation is criterion-based.
- **GROUND_TRUTH_SOURCE** — where labels/truth come from, and their known limits.
- **EVAL_COMMAND** — the command that produces the metric. This goes in `scripts/gate.d/eval.sh` when cheap enough to run per-change; otherwise it runs at /3-review.
- **DATA_REGIME** — offline vs. online; what data the system sees in production vs. training.
- **NOTEBOOK_STRATEGY** — notebooks are exploratory by default; those listed under NOTEBOOK_EXEC are gated in smoke mode. Shared or correctness-critical logic moves to a `.py` module covered by the normal gate. Notebooks are single-author scratch files under an owner namespace such as `notebooks/<initials>/...`; two people do not co-edit the same notebook. To keep JSON diffs mergeable, copy `$(harness root)/examples/gate.d/nb-clean.sh` to `scripts/gate.d/nb-clean.sh` in ML/CV repos that track notebooks; it fails on tracked `*.ipynb` files with non-empty `outputs` or `execution_count`. Fix notebooks with `nbstripout --install` or `jupyter nbconvert --clear-output --inplace <notebook.ipynb>`.
- **REPO_HYGIENE** — decide whether to copy `$(harness root)/examples/gate.d/ds-hygiene.sh` to `scripts/gate.d/ds-hygiene.sh`. When enabled, it fails on oversized tracked data/model artifacts and hardcoded local paths in tracked Python/notebook files. Decide the hook's local policy knobs: `DS_DATA_MAX_BYTES`, `DS_DATA_ALLOW_DIRS`, and `DS_PATH_SCAN`; `DS_DATA_ALLOW_DIRS` is a colon-separated list of literal path prefixes, so include a separator boundary when needed. `gate.d/` hooks run on every gate regardless of `profile:`. This is a gate-time guard over working-tree size, run after agent-exec commits implementer output on the unit branch and before review; it flags tracked blobs but does not recover repo history and goes quiet after an already-committed blob is removed from the working tree.

- **NOTEBOOK_EXEC** — decide which notebooks to list in `NB_EXEC_NOTEBOOKS` and copy `$(harness root)/examples/gate.d/nb-exec.sh` to `scripts/gate.d/`. Add `papermill` to `gate.required_tools`. Each notebook has a `parameters`-tagged cell declaring `data_dir`, `out_dir` and `smoke`; smoke cuts the work to a quick slice, and side effects go under `out_dir`, never relative to the cwd.
- **DATA_CONTRACTS** — decide which datasets get hand-written JSON contracts and copy `$(harness root)/examples/gate.d/data-contract.sh` to `scripts/gate.d/`.

## Notebook writing

Notebooks the agent writes or edits carry structure, core findings and a short descriptive read. Reasoning about what the results mean is left to the Owner, more so here than for backing scripts.
- Markdown cells hold headings and subheadings: one question per heading, followed by the code that answers it.
- After the code: the core finding (the number, its n and interval, the partition), then at most two or three lines of descriptive analysis: direction, size, and how it compares with the baseline or a prior run.
- Each question heading's section (not each subheading) ends with a markdown cell holding only `**Owner:**`. Add one to each section the agent writes or edits; leave sections it doesn't touch as they are. The agent never writes in, edits or deletes an Owner cell; an existing Owner cell keeps its text and moves with its heading.
- No interpretation of what a result means, recommendations, caveat lists or next steps unless the Owner asks. When asked, expand only the section named.

## Adds to the loop

- **/1-plan:** a plan changing model, features, or data must state its expected effect on EVAL_METRIC and how that will be measured. "Should improve things" is not a criterion.
- **/3-review:** the reviewer receives the eval result (metric before/after, data version) alongside the diff. Code-green with metric-red is REQUEST CHANGES.
- **Correlated-validator warning:** an LLM judging LLM output shares blind spots with it. Where the reviewer and the system-under-test are the same model family, deterministic evals and held-out data carry the weight — agent agreement is corroboration, never validation.

## Gate

Add `scripts/gate.d/eval.sh` when EVAL_COMMAND is cheap; keep expensive evals at review-time and say so in ARCHI.md.
