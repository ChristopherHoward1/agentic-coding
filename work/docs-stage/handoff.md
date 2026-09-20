You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract. Follow its build-discipline ladder (reuse → minimum code) while staying strictly inside the plan footprint.

Work unit: work/docs-stage/plan.md  (read it in full; it is your source of truth)
Branch: wt/docs-stage (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

## What this is

Add a new loop stage `/docs`: a skill that dispatches codex/GPT to WRITE or REWRITE documentation prose, because the Owner and coworkers read GPT-style prose more easily than Claude-style prose. This is the LEAN version: a skill only. Do NOT add a config knob, do NOT modify agent-exec.sh, do NOT add tests. The existing 2-arg `scripts/agent-exec.sh <worktree> <handoff>` already dispatches codex via `implementer.command` — reuse it exactly.

## Footprint (hard boundary — touch nothing else)

- `skills/docs/SKILL.md` — new
- `skills/docs/prompts/handoff.tpl` — new
- `ARCHI.md` — targeted edit only (see below)

Do NOT touch: `config.yaml`, `scripts/agent-exec.sh`, `tests/test-scripts.sh`, or any other file. Note: `skills/` is the canonical tracked path; `.claude/skills` is a symlink to it — edit the canonical `skills/docs/...` paths.

## skills/docs/SKILL.md — requirements

Model it on `skills/2-implement/SKILL.md` in structure and tone (read that file first). It must specify this flow and these facts explicitly:

1. Input: a slug for a docs work unit, with a `work/<slug>/plan.md` naming which docs to write/rewrite and the footprint.
2. Create an isolated worktree: `WT=$(scripts/worktree.sh add <slug>)`. Implementation happens in worktrees, never the primary checkout.
3. Render the docs handoff from `skills/docs/prompts/handoff.tpl` into `work/<slug>/handoff.md` — self-contained, since the docs writer starts cold.
4. Dispatch codex with the existing TWO-argument form: `scripts/agent-exec.sh "$WT" work/<slug>/handoff.md` (this reuses `implementer.command`, which is codex/GPT — that is the point: GPT authors the prose). Then capture the writer's summary and run `scripts/worktree.sh sync-artifacts <slug>` from the repo root.
5. Present the resulting diff to the Owner — the Owner and coworkers are the readers of prose quality; there is no automated prose-quality judge.

It must state these rules explicitly:
- **No gate loop.** Prose has no exit-code contract. (If a docs change also edits code/scripts, that is out of scope for `/docs` — `/docs` is for documentation prose.)
- **No self-review, writer never reviews.** codex writes the prose; the orchestrator does not rewrite codex's prose in-thread. This preserves the framework's writer≠reviewer invariant.
- **Ship lane: the small-fix path** (branch + tell the Owner), NOT `/3-review`→`/4-release`. Reason: the dual-vendor `/3-review` bases diffs on origin/main and gates on code-review sentinels, i.e. it reviews prose as code — a mismatch for pure documentation. State this reasoning in one line.

## skills/docs/prompts/handoff.tpl — requirements

A cold-start prompt template for the codex docs writer, modeled on `skills/2-implement/prompts/handoff.tpl` but for documentation. Use `{{SLUG}}`, `{{FILES_TO_MODIFY}}`, `{{CONSTRAINTS}}` placeholders in the same style. It must:
- Tell the writer it is authoring/rewriting documentation for a human audience (the Owner and coworkers) — clear, plain, GPT-style prose.
- Point it at `work/{{SLUG}}/plan.md` as the source of truth and `wt/{{SLUG}}` as its branch.
- Give the footprint as the hard boundary via `{{FILES_TO_MODIFY}}` and constraints via `{{CONSTRAINTS}}`.
- Ask it to commit on the branch and print a summary of what it wrote and why.
- Must NOT instruct a `scripts/gate.sh` run (that is the code-implementer's step, not the docs writer's).

## ARCHI.md — targeted edit

In the `skills/` bullet under `## Layout`, add that `skills/docs` is a documentation-writing stage (`/docs`) that dispatches codex/GPT via the 2-arg `agent-exec.sh` to author/rewrite prose, ships via the small-fix path, and runs no gate/no self-review. Keep it a targeted edit consistent with the surrounding prose density — do NOT regenerate or restructure ARCHI.md. This edit is required so `scripts/archi-fresh.sh` stays green after adding a `skills/` file (per the 2026-09-01 project decision).

## When done

1. Run `scripts/gate.sh` from the repo root — it must pass (shellcheck + smoke suite; you changed no scripts, so this should stay green).
2. Run `scripts/archi-fresh.sh` — it must exit 0 (ARCHI fresher than the sources it describes; committing ARCHI.md in the same commit as the skill files keeps epochs equal, which passes the strict `<` check).
3. Commit your work on this branch with a clear message.
4. Print a final summary: what changed and why, any criteria partially met, any out-of-scope observations.
