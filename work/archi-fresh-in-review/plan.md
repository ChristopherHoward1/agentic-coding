# Catch ARCHI staleness in /3-review, not first at /4-release

**Slug:** archi-fresh-in-review · **Date:** 2026-09-08 · **Status:** implemented

## Goal

`ARCHI.md` freshness is validated only inside `release.sh` (`check_archi_fresh`, release.sh:118). A work unit that touches `scripts/ skills/ profiles/ config.yaml CLAUDE.md` leaves ARCHI stale; the `/2-implement` gate stays green (it never checks freshness) and the drift is invisible until `/4-release` dies with "ARCHI.md is stale" — the worst moment, after review has passed. Done: freshness is checked at the end of `/3-review`, so a stale ARCHI is caught and healed on the release branch before the unit is declared merge-ready; `release.sh` keeps the identical check as a backstop, now sharing one implementation.

## Approach

Extract the timestamp comparison into `scripts/archi-fresh.sh`, ref-aware so both callers use it against the release branch:

- `scripts/archi-fresh.sh [<ref>]` — compares last-commit epoch of `ARCHI.md` vs `scripts/ skills/ profiles/ config.yaml CLAUDE.md` at `<ref>` (default `HEAD`), via `git log -1 --format=%ct <ref> -- <paths>`. Preserves today's **strict** `archi_epoch < source_epoch` semantics: equal epochs pass (a single commit touching both ARCHI and source is fresh, not stale). Exit 0 = fresh; exit 1 = stale (message names the offending newer paths and says to refresh ARCHI on the branch); exit 2 = missing git history for either side. A `--help`/`-h` flag prints usage (the ref arg) and exits 0; a bare run defaults to `HEAD` and runs the check (it does not print help).
- `release.sh` drops its inline `check_archi_fresh` body; the `check_archi_fresh` wrapper stays and calls `scripts/archi-fresh.sh || die "ARCHI.md is stale; refresh it on the branch"` so the `release:`-prefixed message and `set -e` semantics are preserved (it already `cd`s into the worktree at release.sh:237, so `HEAD` = the branch). Backstop behavior unchanged; the existing stale-ARCHI refusal test still guards it.
- `/3-review` SKILL.md: a new step **between step 6 (record verdicts) and step 7 (hand off)** — after both APPROVE sentinels are recorded, run `scripts/archi-fresh.sh wt/<slug>` from the primary checkout. If stale, the **orchestrator** makes a targeted `ARCHI.md` edit on the `wt/<slug>` worktree describing the added/renamed/removed surface, commits it on the branch (then `scripts/worktree.sh sync-artifacts <slug>`), and re-runs the check until fresh — *then* declares merge-ready. This ARCHI-freshness heal is **exempt from step-19's "you just became a writer → re-review is mandatory" rule**: it is a mechanical description-sync of already-approved code, not a behavior change, so it does not spawn a fresh review round (state this exemption explicitly in the skill, or a cold orchestrator will loop).

**Heal mechanism is a targeted branch edit, NOT `/compact`** — per PLAN.md decision 2026-09-01: `/compact` runs from a `main` checkout and cannot describe branch-only code, so it is not the remedy for branch-local ARCHI drift. This corrects the originating request, which said "regenerate via /compact." The 2026-08-16 decision ("release never regenerates ARCHI; /compact is the only ARCHI pipeline") is not violated: the regenerator here is the orchestrator in a skill, editing the branch by hand — not a script, and not `/compact`.

Alternative considered: put the check in `gate.sh`/`gate.d`. Rejected — the gate runs mid-implementation in the worktree, where an implementer that just committed a `scripts/` change makes source newer than ARCHI by construction; that would fail every implement loop touching a hot-tier path and force ARCHI regen into the implementer's job (wrong altitude).

Alternative considered (plan-reviewer's "simpler version"): ship `archi-fresh.sh` + the `/3-review` step only, leave `release.sh:118–130` untouched with its duplicated comparison. Rejected — two independent definitions of "stale" is precisely the drift this unit exists to prevent; the release-path edit is small (delegate one wrapper body) and guarded by the existing stale-ARCHI refusal test. Keeping one source of truth is worth the load-bearing edit; acknowledged as the unit's main risk.

**This unit dogfoods its own feature.** Adding `scripts/archi-fresh.sh` and editing `scripts/release.sh`/`skills/` makes `scripts/` newer than `ARCHI.md`, so this unit's own `/3-review` freshness step will (correctly) fire and require an ARCHI heal describing `archi-fresh.sh`. That is expected, not a footprint violation — the orchestrator performs it during `/3-review`.

## Footprint

Files to modify:
- `scripts/release.sh` — replace `check_archi_fresh` body (lines ~118–130) with a call to `scripts/archi-fresh.sh`; keep the call site at release.sh:247.
- `skills/3-review/SKILL.md` — add the post-APPROVE freshness step + targeted-heal loop.
- `tests/test-scripts.sh` — hermetic cases for `archi-fresh.sh` (fresh, stale, ref-selects-branch, missing-history exit 2) and that release still refuses on stale ARCHI via the shared script.

Files to create:
- `scripts/archi-fresh.sh` — the extracted, ref-aware check (`set -uo pipefail`, shellcheck-clean).

ARCHI.md note (not off-limits — the opposite): the implementer must NOT touch `ARCHI.md`; but the **orchestrator** must add a Layout-section line for `scripts/archi-fresh.sh` during `/3-review`'s heal step (the implementer doesn't run `/3-review`). Keep the freshness path set defined once — in `archi-fresh.sh` — not duplicated into ARCHI prose.

## Acceptance criteria

- [ ] `scripts/archi-fresh.sh` exists, `set -uo pipefail`, passes `shellcheck`; `bash scripts/archi-fresh.sh --help` prints usage documenting the ref arg and exits 0.
- [ ] `scripts/archi-fresh.sh <ref>` exits 0 when ARCHI's epoch is `>=` every source path's at `<ref>` (equal epochs pass — strict `<` for stale), exit 1 (naming the newer paths) when stale, exit 2 when either side has no history at `<ref>`.
- [ ] `release.sh` no longer contains the inline epoch comparison; `check_archi_fresh` (or its call site) delegates to `scripts/archi-fresh.sh`; the release stale-ARCHI refusal test still passes.
- [ ] `skills/3-review/SKILL.md` gains a step between record-verdicts and hand-off: run `scripts/archi-fresh.sh wt/<slug>`; on stale, targeted-edit ARCHI on the branch (explicitly NOT `/compact`) + commit + `sync-artifacts` + re-check before merge-ready; and states the heal is exempt from the writer-triggers-re-review rule.
- [ ] `bash scripts/gate.sh` green (shellcheck + full smoke suite incl. the new archi-fresh cases).

## Release

Release note: `/3-review` now validates ARCHI.md freshness and heals it on the branch, so `/4-release` no longer surprises with a stale-ARCHI block; freshness check extracted to `scripts/archi-fresh.sh`.

## Verification

- `bash scripts/archi-fresh.sh HEAD` (fresh on a clean tree) and a constructed stale-ref case in the smoke suite.
- `bash scripts/gate.sh`

## Review

plan-reviewer verdict: REVISE (fresh opus subagent, cold context). Core design confirmed sound and consistent with PLAN.md decisions 2026-09-01 and 2026-08-16; ref-awareness confirmed sufficient for `/3-review` to check `wt/<slug>` from the primary checkout. Four findings, all applied:
1. Self-referential footprint — "NOT to touch ARCHI.md" was false; this unit dogfoods and its own ARCHI heal (line for `archi-fresh.sh`) is expected, done by the orchestrator in `/3-review`. Reworded footprint + Approach.
2. `--help` vs bare-run contradiction — resolved: explicit `--help` prints usage & exits 0; bare run defaults to `HEAD` and runs the check.
3. Behavior preservation — pinned the strict `<` boundary (equal epochs pass) as a criterion; kept a `|| die` wrapper at the call site so the `release:` message and `set -e` semantics survive.
4. Re-review loop hazard — added an explicit exemption: the ARCHI-freshness heal does not trigger step-19's mandatory re-review.

Disagreement (Owner arbitrates): reviewer offered a "simpler version" dropping the `release.sh` refactor to avoid touching the release path. Declined and recorded in Approach — two definitions of "stale" is the drift this unit prevents; the edit is a one-wrapper delegation guarded by the existing refusal test. Kept as the unit's acknowledged main risk.

Plan verdict: REVISE → addressed; ready for Owner approval.

### Code review (round 1)

Both reviewers APPROVE on the clean `origin/main`-based diff (local `main` was stale; FF'd before review). All findings LOW, none blocking:
- Claude code-reviewer: (a) release.sh wrapper collapses exit 1/2 into the "stale" die message (plan-accepted); (b) a nonexistent `<ref>` reports as "no git history" rather than ref-not-found (fails closed); (c) the missing-*source* exit-2 branch is untested (symmetric to the tested missing-archi side).
- Codex reviewer: step-7 text cites "step 4 / step-19" for the re-review exemption; the mandatory-re-review rule is actually step 5. Cosmetic; intent clear.

None routed to a fix round (all LOW). (a)–(c) and the step-ref wording noted for /5-retro.

Code-review verdict: APPROVE
Codex-review verdict: APPROVE
