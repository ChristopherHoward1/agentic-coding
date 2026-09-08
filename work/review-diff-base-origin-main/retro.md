# Retro: review-diff-base-origin-main

Shipped v2026.9.4. Bases the `/3-review` + `codex-review.sh` diff on freshly-fetched `origin/main` (local-`main` fallback), killing the stale-`main` pollution that hand-required a mid-review FF in the prior two units. Two review rounds; one real fix, one Owner-overridden false positive.

## What did the gate miss that a reviewer caught?

Codex's **round-1 HIGH was real and the gate could not catch it**: `skills/3-review/SKILL.md` step 1 told the orchestrator to diff `origin/main...` with no fallback when `origin/main` is absent, while the script had the fallback. Prose-behavior asymmetry, invisible to a shell gate — exactly what a reviewer is for. Fixed in `5072d57`. The dual-vendor review earned its keep this unit.

## What did every check miss?

**A reviewer false positive — nothing automated catches a wrong verdict.** Codex's round-2 HIGH claimed a stale `origin/main` on fetch-failure still pollutes; it does not, because the diff is three-dot (`origin/main...branch` = `merge-base..branch`) and the branch is forked from `origin/main`, so the merge-base collapses to the fork point for any `origin/main` at-or-after it — a stale `origin/main` is never worse than local `main`, and codex's proposed fix would regress to a staler base. The Claude reviewer independently rated the identical behavior LOW/intended. No check flags a wrong HIGH; it took orchestrator merge-base analysis + Owner arbitration to reject it. **Signal:** the codex run header showed `reasoning effort: none` — a no-reasoning reviewer is prone to exactly this shallow-analysis false positive, which cost a review round and an escalation. Bumping the codex reviewer's reasoning effort is a cheap lever against both false positives and false negatives. That's a `config.yaml`/`reviewer.command` change (off-limits on a retro branch) → named candidate.

## What got re-derived that a doc would have prevented?

The three-dot merge-base argument (why a stale `origin/main` is still a clean base) was derived live to reject the false positive. Routing it to a `knowledge/` doc is **not worth keeping** as a standalone: the full analysis is durably recorded in `work/review-diff-base-origin-main/plan.md` → Review section, and the new process decision (below) points there. A cold-tier doc that would be cited maybe once a year is over-documentation; PLAN stays thin.

## What friction repeated from a prior retro?

1. **`codex-review-printf-dash` recurred a 3rd time** — `scripts/codex-review.sh` lines ~106–109 again emitted `printf: - : invalid option` (seen in `exec-state`, `archi-fresh-in-review`, now here), silently dropping reviewer-prompt lines. Three strikes on a trivial quoting bug that degrades the reviewer prompt every run → promote from Candidate to **Next** (small-fix). Scripts change, off-limits here.
2. **The wrong-branch primary-checkout friction did NOT recur** — the 2026-09-08 process decision from `archi-fresh-in-review`'s retro (keep the primary checkout on clean `main`) held: this unit started clean on `main`, no stash/checkout dance. The fix worked; noting the positive so it isn't re-litigated.

## Routing

- **process (applied):** one `PLAN.md` Decisions line — how to handle a reviewer CRITICAL/HIGH the orchestrator believes is wrong: analyze on the merits, weigh the *other* reviewer's independent severity, escalate the open HIGH to the Owner, and override only with the analysis recorded in the plan's Review section — never ship a regression to appease a reviewer.
- **`/1-plan`/small-fix (named, not applied) — `codex-review-printf-dash`:** promoted to Next (3rd recurrence); quote the `printf` format args in `codex-review.sh`.
- **mechanical candidate (named, not applied) — `codex-reviewer-reasoning-effort`:** raise the codex `reviewer.command` reasoning effort above `none` to cut shallow false positives/negatives; `config.yaml`/`reviewer.command`, off-limits on a retro branch.
- **not worth keeping:** the merge-base rationale as a standalone `knowledge/` doc (lives in the plan Review section, cited by the process decision) — and the dual-vendor "earned its keep" observation (already an accepted design property, no new artifact).
