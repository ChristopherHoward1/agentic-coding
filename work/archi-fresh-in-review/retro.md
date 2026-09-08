# Retro: archi-fresh-in-review

Shipped v2026.9.3. Extracts `check_archi_fresh` into ref-aware `scripts/archi-fresh.sh`, wires a freshness/heal step into `/3-review`, keeps `release.sh` as backstop. Both reviewers APPROVE (all LOW). The unit dogfooded cleanly — its own `/3-review` step caught the stale ARCHI it created and healed it with a targeted branch edit.

## What did the gate miss that a reviewer caught?

Nothing blocking. Both reviewers returned only LOW findings; the new hermetic archi-fresh cases covered the behavior the gate could exercise. LOW polish surfaced (below) but none met the CRITICAL/HIGH bar. Expected for a script-extraction + docs unit.

## What did every check miss?

**The review-diff base was silently stale again.** Local `main` was 2 commits behind `origin/main` (v2026.9.2 `implementer-ladder` + the gate tsc-fallback had merged remotely and were never pulled), so `/3-review`'s `git diff main...wt/<slug>` produced a polluted diff — `gate.sh`, `PLAN.md`, and `work/implementer-ladder/retro.md` on top of the real 4 files — and `codex-review.sh` bases on local `main` the same way. Caught by eye (diffstat had files I didn't write), then fixed by fetching and FF-ing local `main` to `origin/main` before spawning reviewers. This is the already-named `review-diff-base-origin-main` candidate — its **second consecutive live occurrence** (implementer-ladder was the first). Nothing in the loop guards the diff base; the reviewers, gate, and plan all operate faithfully on whatever diff they are handed.

## What got re-derived that a doc would have prevented?

The two review LOWs are cosmetic and the `/3-review` step-reference wording was written awkwardly by me:
- `skills/3-review/SKILL.md` step 7 cites "step 4's rule … also known as step-19's rule" for the re-review exemption; the mandatory-re-review rule is actually step 5, and "step 19" is a plan line number that means nothing in the skill.
- `release.sh check_archi_fresh` collapses archi-fresh exit 1 (stale) and exit 2 (no history) into one "stale" die message; a bad `<ref>` reports as "no git history"; the missing-*source* exit-2 branch is untested (only missing-archi is).

These live in `skills/` and `tests/` — **off-limits on a retro branch**, so they are named here as a single tiny **small-fix** (`archi-fresh-polish`), not applied: correct the step-5 reference, and add the missing-source exit-2 test case. Not worth a full `/1-plan` unit.

## What friction repeated from a prior retro?

1. **Review-diff base pollution (2nd occurrence)** — see above. `implementer-ladder`'s retro named it; it recurred immediately. Two live hits in two units promotes it from "Next" to the top of the queue.
2. **Primary checkout left on a stale feature branch with a transient `PLAN.md` edit (2nd occurrence)** — the session started on `gate-tsc-fallback` (2 commits behind `origin/main`) carrying an uncommitted "Approved" note in `PLAN.md`. That blocked the `main` checkout `release.sh` requires ("main must be checked out in the primary worktree") and forced a stash + checkout mid-release. `implementer-ladder`'s retro filed the same self-inflicted friction as "not worth keeping." A friction that recurs is no longer noise — it earns a durable rule. → **process**.

## Routing

- **`/1-plan` unit (named, already queued) — `review-diff-base-origin-main`:** base the `/3-review` diff and `codex-review.sh` on a freshly-fetched `origin/main`, not local `main`. Scripts/skills change, so it cannot be applied on a retro branch. Reinforced in PLAN Now (now bitten twice; top of queue).
- **process (applied here):** one `PLAN.md` Decisions line — the orchestrator keeps the primary checkout on clean `main`; transient status notes never live in the primary tree, because `/4-release` and branch switches both require a clean `main` there.
- **small-fix (named, not applied) — `archi-fresh-polish`:** fix the `/3-review` step-5 reference and add the missing-source exit-2 test. Trivial; skip the loop.
- **not worth keeping:** the gate/reviewer split (Q1) — a docs+extraction unit with full test coverage is exactly the shape where the gate suffices and reviewers only polish; no durable artifact.
