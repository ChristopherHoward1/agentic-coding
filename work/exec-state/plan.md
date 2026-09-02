# Explicit Per-Work-Unit Execution State

**Slug:** exec-state · **Date:** 2026-09-01 · **Status:** implemented

## Goal

A fresh Claude Code session, given only the repo and a slug, can answer *"what stage is this work unit at, and what is the next legal action?"* without the prior implementation conversation. Today that answer is implicit — scattered across artifact presence, verdict sentinels in the branch plan, git refs, and the `.last-released` marker — and can only be reconstructed by a session that already knows the loop. Done means one command, `scripts/state.sh <slug>`, derives the execution state from observable repo facts and prints it.

This is **execution state**, distinct from ARCHI.md (system state), PLAN.md (strategic state), and `work/<slug>/plan.md` (the spec). It reads those as inputs and stores nothing they own.

## Approach

`scripts/state.sh <slug>` is a **pure, read-only function of observable repo state** — it asserts no fact it cannot derive and writes nothing. A cold session runs it and learns stage + next action. Because it is pure, there is no state to persist and no copy that can drift or lie: the command *is* the explicit-state mechanism.

**No persisted `state.md`, no skill wiring.** (Reviewer finding 1, accepted.) A persisted snapshot was in the first draft justified as "flows to review/release as an artifact" — but the review diff explicitly excludes `work/<slug>` (`codex-review.sh:99`, `3-review/SKILL.md:12`) so no reviewer sees it, and `release.sh` reads only sentinels/marker/plan, never a state file. Nothing downstream consumes a snapshot; a derived copy could only ever go stale. So v1 ships the deriver alone. Discovery for a cold session comes from a one-line pointer in the release note / ARCHI (added at `/4-release`, not now).

Derivation inputs (all deterministic):
- artifact presence under `work/<slug>/` (`plan.md`, `handoff.md`, `codex-review.md`, `retro.md`)
- the exact verdict sentinel lines — `Plan verdict: APPROVE`, `Code-review verdict: APPROVE`, `Codex-review verdict: APPROVE` — read from the **branch** plan via `git show wt/<slug>:work/<slug>/plan.md` when `wt/<slug>` exists, else the primary-checkout `work/<slug>/plan.md`. (`state.sh` makes its own reading choice; note this differs from how the other scripts work — `codex-review.sh` derives its verdict from the reviewer *exit code*, and `release.sh` greps the release-checkout working-tree plan with `grep -qx`. `state.sh` needs the primary-checkout view, hence `git show`.)
- git refs: does `wt/<slug>` exist
- the `work/.last-released` marker (does its single line name this slug)

Derived fields (the whole record, flat `key: value` lines — grep/awk-readable, no `jq`):
- `stage:` `plan` | `implement` | `review` | `release` | `done`
- `review:` `pending` | `approve` — `approve` iff **both** `Code-review verdict: APPROVE` and `Codex-review verdict: APPROVE` are present; else `pending`. (Reviewer finding 2, accepted: `request-changes`/`blocked_on` are cut from v1 — a mid-review state carries no sentinel and is indistinguishable from not-yet-reviewed, and the two vendors' negative words differ; not worth faking a state that can't be cleanly derived or fixtured.)
- `next_action:` the next legal command

Stage derivation rules (first match wins):
1. no `plan.md` → exit non-zero, "not a work unit: <slug>"
2. `Plan verdict: APPROVE` absent → `stage: plan` / `next_action: finish /1-plan`
3. no `handoff.md` and no `wt/<slug>` branch → `stage: implement` / `next_action: /2-implement`
4. `handoff.md` present (or branch exists), `review != approve` → `stage: review` / `next_action: /3-review` (or `run scripts/gate.sh` when `codex-review.md` is absent)
5. `review == approve`, slug not in `.last-released` → `stage: release` / `next_action: /4-release`
6. slug in `.last-released`, `retro.md` missing or empty → `stage: release` / `next_action: /5-retro`
7. slug in `.last-released`, `retro.md` non-empty → `stage: done` / `next_action: none`

**Gate result stays out of scope for v1** (reviewer confirmed this is the right call). A gate result is tree-sha-bound and ephemeral; persisting it would invite a stale-lie. In `implement`/`review`, `next_action` names `run scripts/gate.sh` — deterministic, drift-free, and keeps `gate.sh` the live authority.

## Footprint

Files to modify:
- `scripts/state.sh` (new — the deriver)
- `tests/test-scripts.sh` (hermetic per-rule derivation + read-only + mutation-pin cases)

Files NOT to touch:
- `scripts/gate.sh` — gate stays the live authority; `state.sh` never records its result
- `scripts/release.sh`, `codex-review.sh`, `worktree.sh` — sentinel/marker contracts are read-only inputs, unchanged
- `.claude/skills/*` — no wiring in v1
- `ARCHI.md`, `PLAN.md`, and the release-note pointer — updated at `/4-release`/`/5-retro`, not now

## Acceptance criteria

- [ ] `scripts/state.sh exec-state` prints a flat `key: value` block with `slug`, `stage`, `review`, `next_action`.
- [ ] Each of the 7 stage rules has a hermetic fixture (artifacts/sentinels/refs/marker) yielding the expected `stage` + `next_action`. Verified in `tests/test-scripts.sh`.
- [ ] Sentinels are read from `wt/<slug>` when the branch exists, else the primary plan — a fixture with a branch-only both-APPROVE that is absent from the primary-checkout plan derives `review: approve`.
- [ ] `state.sh` writes nothing anywhere (read-only) — verified (e.g. clean `git status` + no new files after a run over a fixture).
- [ ] A missing `plan.md` exits non-zero with a "not a work unit" message.
- [ ] At least one stage-derivation guard is mutation-pinned: e.g. mutating the two-sentinel AND into an OR flips a `review: pending` fixture to `approve` and makes a test fail; the mutation is shown to have landed. (Per `knowledge/silent-no-op-hazards.md`.)
- [ ] `scripts/gate.sh` passes (shellcheck clean; full suite green).

## Release

Release note: `scripts/state.sh <slug>` derives per-work-unit execution state (stage, review, next legal action) from observable repo facts — a cold session can learn where a unit stands and what comes next without the prior conversation.

## Verification

- `bash scripts/gate.sh`
- `scripts/state.sh exec-state` and eyeball the derived block against the unit's actual stage (dogfood: this unit is the first real run of the mechanism)

## Review

Reviewer: fresh `plan-reviewer` subagent (opus, cold, read-only), 2026-09-01. Verdict on first draft: **REVISE**. All four findings accepted and applied:

1. **Dropped the persisted `state.md`, the `refresh`/`updated` machinery, and all five skill edits.** The review diff excludes `work/<slug>` and `release.sh` never reads a state file, so nothing downstream consumes a snapshot; a pure deriver makes persistence redundant. v1 = `scripts/state.sh` + tests only. Footprint cut ~60%.
2. **Cut `review: request-changes` and `blocked_on`.** Mid-review carries no sentinel (indistinguishable from `pending`), and the negative sentinel words differ across vendors (`REVISE` vs `REQUEST CHANGES`); not cleanly derivable or fixturable. `review` is now `pending | approve` only.
3. Moot after 2 (`blocked_on` pointed at a non-existent `followup-N.md`; real round truth is `work/<slug>/review-round`).
4. **Corrected the provenance claims.** State the exact sentinel strings (incl. `Plan verdict:`) and no longer claim `state.sh`'s `git show` reading "matches" the other scripts — it deliberately differs (they use exit code / working-tree grep from the release checkout).

No disagreements — the reviewer's cuts are right and shrink the unit to its core.

Plan verdict: APPROVE

Code review (round 1, 2026-09-01): both reviewers APPROVE. Claude `code-reviewer` (opus) verified the mutation-pin by hand and confirmed all 7 acceptance criteria; Codex reviewer exit 0. Only LOW findings, none blocking: read-only test uses a branchless fixture (the `git show` path's read-only-ness is covered implicitly by `branch-approve`); bad-arg exits 2 while other errors exit 1 (both non-zero, per spec); `review: approve` can co-print with `stage: implement` pre-handoff (per-contract, `review` is a pure sentinel projection).
Code-review verdict: APPROVE
Codex-review verdict: APPROVE
