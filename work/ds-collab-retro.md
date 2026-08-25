# DS-collaboration retro — 2026-08-25

Trigger: Owner adapting the framework for a **two-person data-science / computer-vision**
project on the `work` (Bitbucket) profile. Surfaced one shipped work unit
(`notebook-collision-policy`, v2026.8.4) plus guidance on profile composition and
shared-repo topology. Full TRIP autonomy reached the same session (`2fbd6af`).

## What shipped

- **`notebook-collision-policy` (v2026.8.4).** The `machine-learning` profile now carries
  a concrete notebook-collision policy: an opt-in strip-outputs gate hook
  (`scripts/gate.d/examples/nb-clean.sh`, deliberately outside the auto-run `gate.d/*.sh`
  glob), owner-namespaced notebooks, and an exploratory-only default. Plan-reviewer and
  code-reviewer both APPROVE, adversarial detection testing clean, 28/28 gate.
- **Guidance (not code):** compose `machine-learning` (eval-defines-done) with `work`
  (Bitbucket CI, Jira refs, Claude implementer) since `config.yaml` has one `profile:`
  knob; keep the product repo separate from the framework template so each DS drives their
  own Orchestrator against their own worktree; data/weights out of git.

## What went well

- **The loop held under a real, non-framework request.** Plan → reviewer → implement →
  gate → review → release ran end-to-end; the fresh code-reviewer independently re-ran the
  gate and did adversarial testing rather than trusting the implementer's summary.
- **The `gate.d/examples/` design instinct was right and reviewer-confirmed:** shipping the
  hook where the auto-run glob can't see it keeps the base/software profile behavior
  unchanged. This is the reusable pattern for "opt-in hook a project enables at `/init`."
- **The correlated-validator warning is exactly the ML-profile risk that bites CV work** —
  called it out in guidance before it could be mistaken for validation.

## What was friction (the honest part)

1. **Worktree base drift.** `worktree.sh add` cut the branch from the current checkout tip
   (`docs/readme-rewrite`), not `main`, so the review/release diff was polluted with
   unrelated README commits until manually rebased `--onto origin/main`. The loop assumes
   you implement from a clean base; it doesn't enforce it. **Candidate:** have `/2-implement`
   branch from `origin/main` (or warn when the base isn't an ancestor of `main`).
2. **Work-unit artifacts didn't flow to the release branch automatically.** `plan.md` was
   authored in the primary checkout and untracked; `release.sh` refused until it was
   committed onto `wt/<slug>`. Invariant #4 ("artifacts flow between stages") is a
   convention, not plumbing. **Candidate:** `/2-implement` seeds `work/<slug>/plan.md` into
   the worktree at dispatch (fan-exec already seeds; single-agent path doesn't).
3. **ARCHI staleness guard fired mid-release** (correctly) and forced a `/compact` detour.
   Working as designed, but the round-trip is heavy for a 3-file change. No fix proposed —
   the guard is cheap insurance.
4. **Classifier vs. permission rules.** The existing allow rule `Bash(git commit -m ' *)`
   only matches **single-quoted** messages; double-quoted / multi-line commits fall through
   to the auto-mode classifier. And the classifier correctly refused to let the agent commit
   its own `CLAUDE.md` confirmation-gate removal — the Owner ran that commit via `!`. Both
   are the safety model working, not bugs. **Candidate:** broaden the allow rule to
   `Bash(git commit *)` if commit prompts become a nuisance (Owner-only edit).

## Known gaps for the actual DS project (not this repo)

- The five ML declarations (`EVAL_METRIC`, `GROUND_TRUTH_SOURCE`, `EVAL_COMMAND`,
  `DATA_REGIME`, `NOTEBOOK_STRATEGY`) are still unfilled — they land at `/init` on the real
  CV repo, not here.
- Two-Orchestrator topology (shared `worktrees.dir`, branch-name collisions) is guidance
  only; nothing mechanically prevents two DS from colliding on a slug. Slug-prefix-by-initials
  is the current mitigation.

## Next candidates (logged, not scheduled)

1. `/2-implement` clean-base + plan-seed fixes (friction #1, #2) — the highest-value loop
   hardening this session surfaced; both are small and mechanical.
2. Document the `machine-learning` + `work` profile composition explicitly (today it's
   session guidance, not written in `profiles/`).
