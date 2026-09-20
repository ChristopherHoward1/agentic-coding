# Docs stage — codex/GPT documentation writer

**Slug:** docs-stage · **Date:** 2026-09-20 · **Status:** approved

## Goal

The Owner and coworkers read GPT-style prose more easily than Claude-style prose, so documentation should be authored by codex/GPT rather than by the Claude orchestrator. Add a `/docs` stage that dispatches codex into an isolated worktree to write or rewrite documentation (README, `knowledge/`, per-file docs, etc.). Done means: a `/docs <slug>` invocation renders a docs-specific handoff, dispatches the codex runtime via the existing dispatch point, and leaves the prose on a `wt/<slug>` branch for the Owner to read and ship — with `writer never reviews` intact (codex writes; the orchestrator does not rewrite codex's prose in-thread).

## Approach

Thinnest version: **a skill only.** `implementer.runtime` is already codex and `implementer.command` is already `codex exec --sandbox workspace-write -`, so GPT can author docs today by pointing a `/docs` skill at the existing 2-arg `scripts/agent-exec.sh`. No config knob, no script change, no new tests.

1. **Add `skills/docs/SKILL.md` + `skills/docs/prompts/handoff.tpl`** modeled on `2-implement` but stripped of the gate loop (prose has no exit-code contract) and self-review. Flow: `worktree.sh add <slug>` → render docs handoff → `agent-exec.sh "$WT" work/<slug>/handoff.md` (2 args, reuses `implementer.command`) → `sync-artifacts` → present the diff to the Owner.
2. **Ship lane — one, not two.** Pure-prose docs changes ship via the **small-fix path** (branch + tell the Owner), not `/3-review`→`/4-release`: the dual-vendor code review bases diffs on `origin/main` and gates on code-review sentinels, which reviews prose as code. The SKILL states this explicitly and names the Owner as the reader of prose quality.
3. **`.claude/skills/docs`** resolves through the existing `.claude/skills → ../skills` symlink — no new symlink.

Deferred (reviewer finding #1): a dedicated `docs.command` config knob + a role-key arg on `agent-exec.sh`, to pin a docs model that diverges from the implementer. Not built now because the default would be byte-identical to `implementer.command` today — speculative until the models actually differ. Owner chose the lean path 2026-09-20.

## Footprint

Files to modify:
- `skills/docs/SKILL.md` — new
- `skills/docs/prompts/handoff.tpl` — new
- `ARCHI.md` — targeted branch refresh (new skill in the `skills/` layout line), per the 2026-09-01 decision

Files NOT to touch:
- `config.yaml`, `scripts/agent-exec.sh`, `tests/test-scripts.sh` — the lean path adds no config knob, no dispatch change, no tests

## Acceptance criteria

- [ ] `skills/docs/SKILL.md` exists and describes the worktree → dispatch → present flow, explicitly: no gate, no self-review, small-fix ship lane, Owner reads the prose.
- [ ] `skills/docs/prompts/handoff.tpl` exists, is docs-oriented (write/rewrite named docs for a human audience within a declared footprint, print a summary), and does not instruct a gate run.
- [ ] The skill dispatches via `scripts/agent-exec.sh "$WT" <handoff>` (2 args) — no config or script change (`git diff --name-only` on the branch touches only `skills/docs/*` and `ARCHI.md`).
- [ ] `.claude/skills/docs/SKILL.md` resolves via the existing symlink.
- [ ] `scripts/gate.sh` passes (shellcheck + full smoke suite, unchanged).
- [ ] `ARCHI.md` is fresher than the sources it describes on the branch (`scripts/archi-fresh.sh` exit 0).

## Release

Release note: Add `/docs` stage — codex/GPT authors and rewrites documentation via the existing dispatch point; ships via the small-fix path.

## Verification

- `bash scripts/gate.sh`
- `git diff --name-only origin/main` on the branch shows only `skills/docs/SKILL.md`, `skills/docs/prompts/handoff.tpl`, `ARCHI.md` (+ the unit's `work/docs-stage/` artifacts)

## Review

Plan-reviewer verdict: APPROVE (first draft, 6-file version). Findings folded in:
- #1 (speculative knob): Owner chose the lean skill-only path 2026-09-20 — `docs.command`/role-key arg deferred; footprint dropped from 6 files to 3.
- #4 (ship lane ambiguity): resolved to the single small-fix lane for pure prose.
- #2/#3 (role-key error message, test fixture): moot — no `agent-exec.sh` or test change in the lean path.

Plan verdict: APPROVE
