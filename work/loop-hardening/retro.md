# Retro — loop-hardening (v2026.8.8)

Closed the enforcement gaps from `work/retro-stage/retro.md`. Four dual-vendor review rounds (Owner authorized round 4 past the 3-round budget); shipped with two known deviations.

## Q1 — What did the gate miss that a reviewer caught?

The 76-check hermetic suite was green at every round, yet reviewers still caught three real correctness holes: the `cmp`-follows-symlink marker bypass (codex R1), the relative-worktree-path breakage in agent-exec's post-dispatch `git -C` (codex R2), and the null-dispatch guard firing on a clean *re*-dispatch (codex R3). Common cause: the implementer's tests matched the plan's spec, and the plan's spec was itself silent on these adversarial edges. The gate tests what was specified; adversarial edges come from a cold adversarial reader. This is dual review working as designed — **not worth keeping** as a new artifact.

## Q2 — What did every check missed?

Two properties nothing mechanical catches, both shipped as documented deviations:
- **codex-review.sh binds to the *local* `main` ref** (`git show main:config.yaml`). A stale primary checkout silently runs an older reviewer binary — the one drift axis of the "branch can't choose the reviewer" property this unit added. → **contextual** (below).
- **The null-dispatch guard hard-fails a legitimate clean-tree no-op re-dispatch** (first dispatch commits, gate fails environmentally, re-dispatched implementer inspects and correctly exits 0 with nothing to change). Loud and orchestrator-recoverable, but it needs a `scripts/agent-exec.sh` edit to soften. → **/1-plan candidate** (below); the retro branch may not touch `scripts/`.

## Q3 — What got re-derived that a doc would have prevented?

The review/release "which copy binds, and when" reasoning came up again — this time for `reviewer.command`. `knowledge/release-script-binding.md` already covers release.sh; the codex-reviewer binding is the same family and belongs there. → **contextual**, applied.

## Q4 — What friction repeated from a prior retro?

**A marginal fix the plan-reviewer flagged for removal consumed most of the review budget.** In planning, the plan-reviewer's round-2 finding 6 recommended dropping fix 3 (null-dispatch detection) as inert on its motivating incident. The Owner kept all four fixes. Fix 3 then drew the REQUEST-CHANGES finding in review rounds 1, 3, and forced the Owner-authorized round 4 — three of four rounds spent on the fix that was flagged as weakest. → **process** (below). Separately, ARCHI.md's hand-maintained check-count went stale mid-review twice and needed on-branch `/compact` touches; inherent to a literal count in prose, `/compact` already owns it — **not worth keeping**.

## Routings

- **contextual** (applied): addendum to `knowledge/release-script-binding.md` — codex-review.sh reads `reviewer.command` from local `main`, so reviewer changes bind at the next review and a stale primary `main` runs an older reviewer.
- **process** (applied): PLAN.md Decisions line — a plan-reviewer's "drop this marginal fix" is a cost signal; keeping such a fix tends to spend its savings back as review-round churn.
- **/1-plan candidate** (named, not applied — needs `scripts/`): `agent-exec-noop-scope` — soften the null-dispatch guard so a clean-tree no-op *re*-dispatch (dirty-before was false, but a prior commit exists / handoff is a followup) does not hard-fail. Small; may go via the small-fix path rather than a full unit.
- **not worth keeping**: adversarial-edge coverage (Q1, dual review already covers it); ARCHI check-count churn (Q4, `/compact` owns it).
