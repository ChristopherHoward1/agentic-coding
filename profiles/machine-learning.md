# Profile: machine-learning

For projects where model/data quality — not just code correctness — defines done.

## Declarations required at /init (recorded in ARCHI.md → Verification)

- **EVAL_METRIC** — the metric that defines "better", or `NONE` if evaluation is criterion-based.
- **GROUND_TRUTH_SOURCE** — where labels/truth come from, and their known limits.
- **EVAL_COMMAND** — the command that produces the metric. This goes in `scripts/gate.d/eval.sh` when cheap enough to run per-change; otherwise it runs at /3-review.
- **DATA_REGIME** — offline vs. online; what data the system sees in production vs. training.
- **NOTEBOOK_STRATEGY** — notebooks are exploratory-only (default) or first-class; if first-class, name how they're reviewed and executed headlessly.

## Adds to the loop

- **/1-plan:** a plan changing model, features, or data must state its expected effect on EVAL_METRIC and how that will be measured. "Should improve things" is not a criterion.
- **/3-review:** the reviewer receives the eval result (metric before/after, data version) alongside the diff. Code-green with metric-red is REQUEST CHANGES.
- **Correlated-validator warning:** an LLM judging LLM output shares blind spots with it. Where the reviewer and the system-under-test are the same model family, deterministic evals and held-out data carry the weight — agent agreement is corroboration, never validation.

## Gate

Add `scripts/gate.d/eval.sh` when EVAL_COMMAND is cheap; keep expensive evals at review-time and say so in ARCHI.md.
