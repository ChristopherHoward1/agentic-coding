# /5-retro — the learning stage

**Slug:** retro-stage · **Date:** 2026-08-26 · **Status:** approved

## Goal

The framework has no mechanized learning loop: `knowledge/` is still empty after 5 released versions (8 planned units), and the only retros were hand-rolled loose files outside any stage (`work/bootstrap-retro.md`; the pruned ds-collab retro). Add a `/5-retro` stage that closes each released unit by routing lessons to the one place each belongs — and make it non-skippable **by exit code**: `release.sh` refuses to release unit N while unit N−1's retro is missing or empty.

## Approach

**Mechanical spine (the part that makes it real):** `scripts/release.sh` gains
- a marker write: on a successful release, the slug is written to `work/.last-released`, `git add`ed into the release commit, **inside the existing `trap rollback_release ERR` window**. `rollback_release` gains a `git clean -f work/.last-released` (third `release.sh` edit, not creep): `git reset --hard` alone leaves a *previously nonexistent* marker on disk untracked — exactly the first-release case — and the next attempt would die at `check_clean_worktree`;
- a precondition `check_previous_retro`, inserted **between the pre-gate `check_origin_main_ancestor` call and `check_gate`** (so a branch merely cut before the previous retro PR merged fails the ancestor check first, and the retro check never runs behind a full gate pass): if `work/.last-released` exists in the release checkout, `work/<its-content>/retro.md` must exist **and be non-empty** (`[[ -s ]]` — an existence-only check is defeated by `touch`), else `die` with a message containing the literal `has no retro.md` (the stale-branch case keeps its own `is stale` message — the two must stay grep-distinct). Self-bootstrapping — no marker → passes; the **ten** existing `setup_release_fixture` cases pass unmodified because the new fixture parameters (marker slug, retro presence) are **optional**.

Release preconditions are `release.sh` exit codes, never skill prose; retro-after-release ordering is preserved — skipping a retro doesn't block *this* release, it blocks the *next* one.

**The stage:** `skills/5-retro/SKILL.md` only — no `prompts/*.tpl` (templates exist to render dispatches to subagents; `/5-retro` runs in the orchestrator thread). Invoked as `/4-release`'s final step, and standalone for abandoned units. Four questions — what did the gate miss that a reviewer caught? what did every check miss? what got re-derived that a doc would have prevented? what friction repeated from a prior retro? Each answer routes to exactly one of:
- `mechanical` → a `gate.d/` hook or script fix
- `contextual` → a `knowledge/` doc (per its README: the doc that would have prevented this instance, no bigger)
- `process` → one line in `PLAN.md → Decisions`
- `not worth keeping` → said explicitly, with why

**Where it lands (invariant 3, properly this time):** the retro is implementation and happens in a worktree — `bash scripts/worktree.sh add retro-<slug>` (works with no `work/retro-<slug>/plan.md`; the seed step is guarded by an existence check), giving branch `wt/retro-<slug>`. Write `work/<slug>/retro.md` **and apply every routing there**, push, PR to `main`. No hand-rolled branch prose; the primary checkout stays parked on `main` (a live `release.sh` precondition). An unapplied routing means the stage is not done. "Nothing learned" is a valid one-line retro. **The retro branch may only touch `knowledge/`, `PLAN.md`, and `work/<slug>/retro.md`** — any routing that edits `scripts/` or `gate.d/` becomes a `/1-plan` unit named in the retro (mechanical rule, not judgment: a code change merging via the retro PR would skip `/3-review`, violating writer≠reviewer; this also keeps `check_archi_fresh` out of the retro path).
**Why a stage and not four lines in `/4-release`** (round-1 reviewer's simpler version, rejected deliberately): the enforcement check needs a named artifact contract to point at, and `/5-retro` must run standalone for units that never release. Net new surface: one SKILL.md, ~12 lines in `release.sh`, the test cases below, two one-line doc edits.

The loop becomes `/1-plan → /2-implement → /3-review → /4-release → /5-retro`; `CLAUDE.md`'s Loop section gains the stage and one line.

## Footprint

Files to modify:
- `skills/5-retro/SKILL.md` (new)
- `skills/4-release/SKILL.md` (final numbered step invoking `/5-retro`)
- `CLAUDE.md` (Loop section)
- `scripts/release.sh` (marker write + `check_previous_retro`)
- `tests/test-scripts.sh` — honest scope: **new fixture machinery, not a 20-line diff.** `setup_release_fixture` gains *optional* params (marker slug, retro presence) so the nine existing call sites stay untouched; the rollback case needs a forced post-bump failure (a `.git/hooks/pre-commit` exiting 1 in the fixture primary — linked worktrees share the common hooks dir), and there is **no existing rollback test** to copy (ARCHI.md's claim of rollback coverage is stale — retro fodder).
- `PLAN.md` (one Decisions line: fifth stage + retro-enforced release precondition)
- `ARCHI.md` (regenerated via `/compact` pre-release, not hand-edited)

Files NOT to touch:
- `knowledge/README.md` — its earn-your-way-in contract already matches; the retro cites it.
- `scripts/worktree.sh` — the retro worktree path already works, plan-seed guard included.

## Acceptance criteria

- [ ] `skills/5-retro/SKILL.md` has `name: 5-retro` frontmatter with a `description:`; its steps contain the literal routing labels `mechanical`, `contextual`, `process`, `not worth keeping`, the `worktree.sh add retro-<slug>` flow, the rule that an unapplied routing means the stage is not done, and the mechanical restriction that the retro branch touches only `knowledge/`, `PLAN.md`, and `work/<slug>/retro.md` (anything under `scripts/` or `gate.d/` becomes a `/1-plan` unit).
- [ ] A successful `release.sh` run leaves `work/.last-released` containing the slug, included in the release commit; a forced post-bump commit failure (pre-commit hook fixture) rolls the marker back (smoke tests).
- [ ] Refusal matrix (smoke tests, messages asserted by grep): marker naming a unit with no `retro.md` → die message contains `has no retro.md`; marker + **empty** `retro.md` → same message; marker + non-empty retro → proceeds; no marker → proceeds; branch both behind `origin/main` **and** missing the retro → dies with the ancestor-check message (`is stale`), not the retro one (ordering falsifiable).
- [ ] `skills/4-release/SKILL.md` contains a final numbered step with the string `/5-retro`; `CLAUDE.md`'s Loop code block contains `/5-retro`.
- [ ] `bash scripts/gate.sh` green (hygiene; the smoke tests above are the evidence).

## Release

Release note: New `/5-retro` stage — release.sh now refuses to release a unit until the previous unit's retro exists and is non-empty; lessons route into gate hooks, knowledge/ docs, or PLAN.md decisions.

Pre-release step: this unit touches `scripts/`, `skills/`, and `CLAUDE.md` — run `/compact` before `/4-release` (also fixes ARCHI's stale rollback-coverage claim).

Post-release obligation (the dogfood): after the tag, run `/5-retro retro-stage`. No AC — the mechanism itself enforces it: the next release refuses until the retro exists.

## Verification

- The release.sh smoke tests above (marker write + rollback, five-way refusal matrix), run via `tests/test-scripts.sh`.

## Review

Round 1 (plan-reviewer, opus): REVISE — enforcement moved from prose into `release.sh`; footprint corrected; branch flow spelled out; ACs made greppable. Rejected (reasoning in Approach): dropping the stage for four lines in `/4-release`.

Round 2 (plan-reviewer, opus, fresh): REVISE — all seven applied: unfalsifiable dogfood AC → self-enforcing post-release obligation; precondition ordering + dual-remedy die message; `PLAN.md`/`ARCHI.md` in footprint; vacuous verification replaced with marker/rollback tests; greppable AC literals; `prompts/retro.tpl` dropped.

Round 4 (plan-reviewer, opus, fresh): **APPROVE** — four non-blocking findings, all applied: (1) `rollback_release` gains `git clean -f work/.last-released` (reset --hard leaves a first-time marker untracked, bricking the retry at `check_clean_worktree`); (2) die-message literals pinned (`has no retro.md` / `is stale`) so the refusal matrix is greppable; (3) fixture call-site count corrected to ten; (4) retro-branch file restriction made mechanical (`knowledge/` + `PLAN.md` + `retro.md` only; `scripts/`/`gate.d/` routings become `/1-plan` units — preserves writer≠reviewer on the retro PR). Reviewer separately flagged ARCHI.md's stale "Owner confirm" line — `/compact` territory, noted for the retro.

Round 3 (plan-reviewer, opus, fresh): REVISE — all five applied: (1) retro moved into a worktree via `worktree.sh add retro-<slug>` — the main-checkout flow violated invariant 3 and a live release precondition; (2) non-empty check (`[[ -s ]]`) + empty-file refusal case — existence-only was defeated by `touch`; (3) insertion point named exactly (between pre-gate ancestor check and `check_gate`) + ordering-falsifying stale-and-missing-retro test; (4) footprint honest about fixture machinery (optional params, pre-commit-hook rollback forcing, no existing rollback test; ARCHI's stale coverage claim flagged as retro fodder); (5) `/compact`-on-retro-branch rule and its AC dropped — `check_archi_fresh` already forces it by exit code.
Plan verdict: APPROVE
