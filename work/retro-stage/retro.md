# Retro — retro-stage (v2026.8.7)

Covers the retro-stage cycle and folds in codex-reviewer (v2026.8.6), which shipped hours earlier without a retro stage existing yet. First dual-vendor loop in production: plan reviews 4–5 rounds (opus), code reviews 3 rounds each (opus + codex), two genuine cross-vendor catches.

## What did the gate miss that a reviewer caught?

- Opus caught semantic shell bugs a green gate blessed: dead `|| exit 2` guards in a pipeline subshell (APPROVE-of-nothing), `printf '--'` option-parsing failure, approval-looking artifact surviving a failed reviewer. Codex independently caught the unchecked reviewer exit status, then the out-of-footprint README edit the orchestrator itself introduced. **Routing: not worth keeping** — this is the reviewer layer doing exactly its job; no hook can check semantics, and the catches prove the dual-vendor design rather than indicting the gate.

## What did every check miss?

- `check_previous_retro` is bypassable by committing `git rm work/.last-released`, and marker content is unvalidated (empty/multi-line marker → nonsense die message). Also `/5-retro` has no resume path (`worktree.sh add` dies on an existing worktree) and no worktree cleanup step, and `agent-exec.sh` exits 0 when the implementer stream disconnects after work but before commit/summary (happened on the first codex dispatch). **Routing: mechanical → these touch `scripts/` and `skills/`, so per the file boundary they become a `/1-plan` unit, named here: `loop-hardening`** (marker-deletion guard + marker validation, `/5-retro` resume/cleanup, dispatch disconnect detection).

## What got re-derived that a doc would have prevented?

- "Which copy of `release.sh` runs?" was reasoned out twice in one day: the codex-reviewer honesty note (dual-sentinel binds next unit) and again when v2026.8.7's release wrote no marker (primary script predates the marker code — enforcement arms only at the *next* release). **Routing: contextual → `knowledge/release-script-binding.md`.**

## What friction repeated from a prior retro?

- README staleness: `work/bootstrap-retro.md` already flagged docs drifting from mechanism; this cycle README's four-stage loop survived two releases because README belongs to no pipeline (`/compact` owns ARCHI only) and the retro branch may not touch it. **Routing: process → one PLAN.md Decisions line: README loop/skills sections are release-note-owned — checked at `/4-release` step 3, fixed via the small-fix path.** (The five-stage README fix itself ships as a separate small-fix branch, noted here, not applied on this branch.)

Marker status, honestly: `work/.last-released` does not exist yet — v2026.8.7 was released by the pre-retro-stage script. The first marker is written by the next release; enforcement binds the release after that.
