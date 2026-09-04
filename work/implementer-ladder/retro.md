# Retro: implementer-ladder

Shipped v2026.9.2. Adds ponytail's lazy/YAGNI build-discipline ladder to `AGENTS.md` (+ one `handoff.tpl` line). Both reviewers APPROVE, gate green — the content was clean. Every real lesson this unit produced came from the *loop mechanics around it*, not the diff.

## What did the gate miss that a reviewer caught?

Nothing. Both reviewers found only LOW findings; the diff met all seven criteria. A docs-only nudge has no runtime for the gate to exercise — expected.

## What did every check miss?

**The review base was silently wrong, and no check guards it.** Local `main` was 9 commits behind `origin/main` (v2026.9.1 had shipped remotely and was never pulled), so `/3-review`'s `git diff main...wt/<slug>` produced a **148 KB polluted diff** — someone else's `code-reviewer.md` MEDIUM changes and more — that would have gone to both reviewers had I not noticed the size and traced it. `codex-review.sh` bases on local `main` the same way, so it would have been polluted too. The gate, the plan, and the reviewers all operate faithfully on whatever diff they are handed; nothing validates that the diff's base is current. This is the already-named `review-diff-base-origin-main` candidate — this run is its live proof. → **`/1-plan` unit** (scripts/skills change, off-limits in a retro); candidate promoted to Next in PLAN.

## What got re-derived that a doc would have prevented?

The `.claude/skills` symlink footprint notation — codex flagged the canonical-vs-alias path mismatch as a blocking HIGH, costing a review round. Already routed in the same session by `codex-verdict-medium`'s retro (the 2026-09-04 canonical-tracked-path convention). Not duplicated here; the convention now exists to prevent the next recurrence.

## What friction repeated from a prior retro?

- The symlink footprint (above) — recurred within the same session, which is exactly what promoted it to a written convention.
- The 2026-09-01 ARCHI-freshness-on-branch decision fired again (this unit edited `skills/…/handoff.tpl`, tripping `check_archi_fresh`) and was resolved smoothly by a targeted on-branch ARCHI edit — the decision *worked*, no new lesson.

## Routing

- **`/1-plan` unit (named, not applied here)** — `review-diff-base-origin-main`: base the `/3-review` diff and `codex-review.sh` on a freshly-fetched `origin/main`, not local `main`. Promoted from Candidate to Next in PLAN (a scripts/skills fix, so it cannot be applied on a retro branch).
- **not worth keeping** — (a) the repeated FF-abort friction when syncing local `main`, caused by my own transient "In implementation" edit left uncommitted in the primary checkout; self-inflicted and avoided by not dirtying the primary tree mid-unit, not worth a durable rule. (b) The ARCHI freshness bump and the symlink convention are already documented — no new artifact.
