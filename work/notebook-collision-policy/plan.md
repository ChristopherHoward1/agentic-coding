# Notebook collision policy

**Slug:** notebook-collision-policy · **Date:** 2026-08-25 · **Status:** implemented

## Goal

Two data scientists sharing a CV repo will collide constantly on Jupyter notebooks:
cell outputs, `execution_count`, and metadata re-churn on every run and produce
unmergeable JSON diffs even when the code is compatible. The framework's
`machine-learning` profile names a `NOTEBOOK_STRATEGY` declaration but gives no
concrete collision policy. Done = the profile ships a checkable, copy-in policy
that an adopting multi-author ML/CV project turns on to make notebooks
near-collision-free, without changing behavior for the base/software profile or
this template.

## Approach

Three mechanisms, documented in the profile, one of them enforced by an opt-in gate hook:

1. **Strip outputs.** The dominant collision source is `outputs` / `execution_count`
   blobs. Ship an example gate hook that fails when a tracked `*.ipynb` carries
   non-empty outputs or execution counts; fix is `nbstripout` (git filter) or
   `jupyter nbconvert --clear-output`. Makes notebooks diffable.
2. **Ownership convention.** Notebooks are single-author scratch, namespaced by
   owner (`notebooks/<initials>/…`) so two people never co-edit one file. Shared
   logic is promoted to a `.py` module, which merges cleanly and goes through the loop.
3. **Exploratory-only default.** Reaffirm `NOTEBOOK_STRATEGY`: notebooks don't gate
   correctness and aren't reviewed as product; when logic matters it moves to a module.

Hazard-driven design choice: the hook must **not** live at `scripts/gate.d/*.sh`
(that glob auto-runs on every adopting project and on this template). Ship it as a
non-auto-run example the ML profile tells the project to copy in and rename.
Alternative considered — auto-wire it for all profiles — rejected: a software
project with a stray notebook would suddenly gate, violating "software profile adds
nothing."

## Footprint

Files to modify:
- `profiles/machine-learning.md` — expand `NOTEBOOK_STRATEGY` into the 3-part policy; point at the example hook.
- `tests/test-scripts.sh` — add a hermetic check: the hook flags a notebook-with-outputs fixture, passes a cleaned one.

Files to add:
- `scripts/gate.d/examples/nb-clean.sh` — the example hook (under `examples/`, NOT matched by `gate.d/*.sh`).

Files NOT to touch:
- `scripts/gate.sh` — hook-discovery glob stays `gate.d/*.sh`; the example must stay out of it. No change needed and a live hazard if `examples/` gets pulled in.
- `config.yaml`, `CLAUDE.md`, base profiles — policy is ML-profile-local.

## Acceptance criteria

- [ ] `profiles/machine-learning.md` `NOTEBOOK_STRATEGY` section states all three mechanisms and names the copy-in hook + its fix commands.
- [ ] `scripts/gate.d/examples/nb-clean.sh` exists, is `set -uo pipefail`, shellcheck-clean, and: finds tracked `*.ipynb`, exits non-zero listing any with non-empty `outputs`/`execution_count`, exits 0 when none, prints the fix command on failure.
- [ ] The example does NOT auto-run here: `ls scripts/gate.d/*.sh` does not list it, and `bash scripts/gate.sh` stays green with no notebook behavior on this template.
- [ ] `bash tests/test-scripts.sh` includes a hermetic case that feeds the hook a dirty fixture (fails) and a clean fixture (passes), using a temp dir, no network.
- [ ] `bash scripts/gate.sh` is green.

## Release

Release note: machine-learning profile ships a concrete notebook-collision policy (strip-outputs gate hook + ownership convention) for multi-author ML repos.

## Verification

- `bash scripts/gate.sh`
- `shellcheck scripts/gate.d/examples/nb-clean.sh`
- Manual: run the hook against a hand-made dirty `.ipynb`, confirm non-zero + fix hint.

## Review

plan-reviewer (fresh, read-only): verified all three flagged codebase claims —
(1) `gate.sh:50` hook glob is non-recursive, so `gate.d/examples/` is excluded and
the central hazard-avoidance is real; (2) `test-scripts.sh` `check`/`check_fails` +
single `$TMP` trap pattern fits a new hermetic case; (3) `NOTEBOOK_STRATEGY` is a
single bare bullet in `machine-learning.md` today, gap is real.

Applied: note for implementer — `test-scripts.sh`'s own `shellcheck scripts/*.sh`
line is non-recursive and will NOT cover `gate.d/examples/nb-clean.sh`; rely on
`gate.sh`'s `git ls-files '*.sh'` (recursive) for the shellcheck-clean criterion,
don't assume the test-script line covers it.

Not changed (reviewer agreed non-blocking): AC-1 ("states all three mechanisms") is
diff-checkable but not single-command-checkable — acceptable for a prose deliverable.

Plan verdict: APPROVE

code-reviewer (fresh thread, read-only, scoped to `e39da11...wt/notebook-collision-policy`):
no findings. Independently ran gate (28/28), shellcheck-clean, adversarial detection
testing found no false positives/negatives (comment mentions of the keys, split-empty
arrays, mixed dirty/clean multi-cell notebooks). Footprint = exactly the 3 declared files;
`gate.sh` untouched. Committed as `c151c6f`.
Code-review verdict: APPROVE
