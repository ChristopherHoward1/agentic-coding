# Implementer ladder: lazy/YAGNI build discipline in the contract

**Slug:** implementer-ladder · **Date:** 2026-09-04 · **Status:** implemented

## Goal

Codex's implementer contract (`AGENTS.md`) enforces *scope* ("Scope is the plan. Nothing more.") but says nothing about *how lazily to build within that scope*. So codex can build an over-engineered version of exactly the planned feature — a factory for one product, a hand-rolled stdlib routine, a speculative config knob — and pass both the contract and the plan's acceptance criteria. Nothing downstream catches it either: `/3-review` scores over-engineering as LOW, which never blocks. Done looks like: the contract carries a short, mechanical build-discipline rule (ponytail's "ladder") so codex reaches for the leaner rung by default, with the guardrails that keep laziness from cutting real corners.

## Approach

Borrow the *text* of ponytail's ladder, not its machinery (no hooks, no skills, no multi-platform distribution). One authoritative home: `AGENTS.md`, which the handoff already names as the contract codex reads first. Add:

- **The ladder** — stop at the first rung that holds: needs to exist at all (YAGNI) → already in this codebase → stdlib → native platform feature → already-installed dep → one line → minimum code. Runs *after* understanding the problem, not instead of it.
- **Root cause, not symptom** — grep the callers, fix the shared function once.
- **Boundaries (never lazy about)** — input validation at trust boundaries, error handling that prevents data loss, security, accessibility, and anything explicitly requested or in the plan. This clause is load-bearing: without it a "be lazy" instruction reads as license to strip validation.
- **`ponytail:` comment marker** for a deliberate corner cut with a known ceiling (names the ceiling + upgrade path).

`handoff.tpl` gets a single reinforcing line pointing at the build discipline; the substance lives only in `AGENTS.md` (one source of truth — adding the full ladder to both would be the exact duplication the ladder warns against).

Alternative considered: a warm-tier profile addition instead of `AGENTS.md` — rejected, the ladder is universal build discipline, not profile-specific, and `AGENTS.md` is already the read-first contract.

## Footprint

Files to modify:
- `AGENTS.md` — add the build-discipline section (ladder + root-cause + boundaries + marker)
- `skills/2-implement/prompts/handoff.tpl` — one reinforcing line (`.claude/skills` is a symlink to `skills/`; the canonical tracked path is named here)

Files NOT to touch:
- `.claude/agents/code-reviewer.md` and `scripts/codex-review.sh` — the review-side complexity lens is recommendation #2, a separate unit; keep this diff to the build side.

## Acceptance criteria

- [ ] `AGENTS.md` contains a build-discipline rule listing the ladder rungs in priority order (YAGNI → already-in-codebase → stdlib → native platform → installed dep → one line → minimum code), with the explicit "understand the problem first / trace the real flow" guard.
- [ ] `AGENTS.md` states root-cause-over-symptom (grep callers, fix the shared function once).
- [ ] `AGENTS.md` retains an explicit "never lazy about" boundary naming at least: input validation at trust boundaries, error handling against data loss, security, and anything explicitly requested/in the plan.
- [ ] `AGENTS.md` documents the `ponytail:` comment convention for a deliberately cut corner (ceiling + upgrade path).
- [ ] `handoff.tpl` references the build discipline in `AGENTS.md` (no duplicated ladder text).
- [ ] `AGENTS.md` stays tight (≤ 45 lines total, `wc -l`) — the addition is mechanical rules, not an essay; the existing "Honest and brief beats thorough and padded" line survives.
- [ ] `scripts/gate.sh` passes.

## Release

Release note: Implementer contract now carries a lazy/YAGNI build ladder (borrowed from ponytail) so codex writes the leanest working diff within scope, with explicit boundaries protecting validation/security/error-handling.

## Verification

- `scripts/gate.sh`
- Diff inspection against the acceptance criteria (docs-only change; no runtime behavior to test).

## Review

Plan-reviewer (fresh thread) verified all codebase claims and returned APPROVE with three minor findings:
1. Soft "≤ ~40 lines" ceiling → **applied**: made it a hard `≤ 45 lines (wc -l)`.
2. "seven ladder rungs" pinned an exact count against paraphrased source → **applied**: softened to "the ladder rungs in priority order" with the rungs listed inline.
3. This is a contract *nudge* with zero enforcement — over-engineering stays undetectable downstream, only less likely. No revision needed; the plan does not overclaim (Done = "codex reaches for the leaner rung by default"). Recorded for the Owner's awareness.

Plan verdict: APPROVE

### Implementation review (/3-review)

Round 1: code-reviewer APPROVE (all 7 criteria met; one LOW — the nudge has no downstream enforcement, already noted). Codex REQUEST CHANGES on a single HIGH claiming `handoff.tpl` was outside the footprint — a false positive: `.claude/skills` is a symlink to `skills/` (`-ef` confirms same file), so the file was in-footprint; the plan had merely named the symlink path. Resolved by normalizing the plan footprint to the canonical tracked path (no scope change).

Round 2 (after normalization): both APPROVE. code-reviewer one LOW (rung-1 "say so in one line" phrasing, harmless); codex clean.

Code-review verdict: APPROVE
Codex-review verdict: APPROVE
