# Retro — exec-state (v2026.9.0)

The mechanism itself shipped cleanly: plan-reviewer cut the footprint ~60% (dropped a redundant persisted snapshot + skill wiring), both code reviewers approved in round 1 with only LOW findings, gate green 170/170, and the dogfood run reported its own unit as `stage: release / next_action: /4-release`. All friction this unit was in the **release-stage environment**, not the code.

## Q1 — What did the gate miss that a reviewer caught?

Nothing. Round-1 dual approval, only LOW findings; the gate and reviewers agreed.

## Q2 — What did every check miss?

The `main...wt/<slug>` diff base silently depends on **local `main` being current with `origin/main`**. This session's primary checkout started on a feature branch (`fix/deferral-injection`) with a stale local `main` (behind `origin/main`), so `/3-review`'s diff — and `codex-review.sh`'s, which use the same `main...$branch` base — pulled in unrelated commits until I hand-fast-forwarded `main`. No gate check, reviewer, or skill step catches a stale local `main`; the reviewers would simply have reviewed a polluted diff.

→ **mechanical**, but touches `scripts/` (`codex-review.sh`) + the `3-review` skill, so per rule 6 it becomes a `/1-plan` candidate, not applied here: **`review-diff-base-origin-main`** — base the review/release diff on a freshly-fetched `origin/main` rather than local `main`, removing the stale-local-main trap. Named as a candidate in `PLAN.md → Now`.

## Q3 — What got re-derived that a doc would have prevented?

Adding a new script (`scripts/state.sh`) made `ARCHI.md` stale, and `release.sh` correctly refused. But the file existed only on the branch, so the documented remedy ("run `/compact`") could not describe it — `/compact` from a `main` checkout can't see branch-only code. I re-derived that ARCHI must be refreshed **on the release branch** with a targeted edit. This ordering is a workflow rule, not domain knowledge, so it lands as one Decision line, not a `knowledge/` doc.

→ **process** — one line in `PLAN.md → Decisions`.

## Q4 — What friction repeated from a prior retro?

No clear repeat. The stale-`main` and branch-only-ARCHI frictions are both first occurrences here (they surface only when the primary checkout is off an up-to-date `main`, which prior units did not hit).

## Also observed (not from the four questions)

`scripts/codex-review.sh` emitted `printf: - : invalid option` four times (≈ lines 106–109) during the round-1 run — a latent bug where a `printf` format begins with `-`, silently dropping those instruction lines from the reviewer prompt. It did not change the verdict this time, but it degrades the reviewer prompt. Mechanical, touches `scripts/`.

→ **mechanical** `/1-plan` (or small-fix) candidate: **`codex-review-printf-dash`** — quote the `printf` format args (`printf -- '%s' …` / `printf '%s'`). Named in `PLAN.md → Now`.

## Routings applied on this branch

- `PLAN.md → Decisions`: ARCHI-freshness-on-branch ordering line.
- `PLAN.md → Now`: `review-diff-base-origin-main` and `codex-review-printf-dash` candidates; exec-state moved to Shipped.
- No `knowledge/` doc (both durable lessons are workflow/mechanical, not domain hazards) — consistent with "process is not the product."
