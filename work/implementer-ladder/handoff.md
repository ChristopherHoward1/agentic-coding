You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract. Note: this unit *edits* AGENTS.md itself, so you are amending your own contract; keep the existing rules and tone intact.

Work unit: work/implementer-ladder/plan.md  (read it in full; it is your source of truth)
Branch: wt/implementer-ladder (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

## What to do

Add a lazy/YAGNI **build-discipline** section to `AGENTS.md`, borrowing the *text* of the "ponytail ladder" (source material below — paraphrase to fit AGENTS.md's terse rule style; do not copy verbatim wholesale). Then add ONE reinforcing line to the handoff template pointing at it. The substance lives only in AGENTS.md — do not duplicate the ladder into the template.

AGENTS.md today enforces *scope* ("Scope is the plan. Nothing more.") but says nothing about how lazily to build *within* scope. This section fills that gap.

## Source material (the ponytail ladder — paraphrase, don't dump)

**The ladder** — stop at the first rung that holds; run it *after* you understand the problem, not instead of it (read the task and the code it touches, trace the real flow end to end, then climb):
1. Does this need to exist at all? Speculative need → skip it, say so in one line. (YAGNI)
2. Already in this codebase? A helper/util/type/pattern that already lives here → reuse it.
3. Stdlib does it? Use it.
4. Native platform feature covers it? Use it.
5. Already-installed dependency solves it? Use it. Never add a new dep for what a few lines do.
6. Can it be one line? One line.
7. Only then: the minimum code that works.

**Bug fix = root cause, not symptom:** a report names a symptom. Grep every caller of the function you touch and fix the shared function once — one guard there is a smaller diff than one per caller, and patching only the path the ticket names leaves sibling callers broken.

**Never lazy about (boundaries — load-bearing, keep these explicit):** understanding the problem; input validation at trust boundaries; error handling that prevents data loss; security; accessibility; anything explicitly requested or named in the plan. Laziness that skips comprehension to ship a small diff is the dangerous kind. The ladder shortens the solution, never the reading.

**`ponytail:` comment marker:** mark a deliberate simplification that cuts a real corner with a known ceiling using a `ponytail:` comment naming the ceiling and upgrade path (e.g. `# ponytail: global lock, per-account locks if throughput matters`).

## Footprint (hard boundary — do not touch anything else)

- `AGENTS.md` — add the build-discipline section (ladder + root-cause + boundaries + marker)
- `.claude/skills/2-implement/prompts/handoff.tpl` — one reinforcing line referencing the build discipline in AGENTS.md

Do NOT touch `.claude/agents/code-reviewer.md` or `scripts/codex-review.sh` — the review-side lens is a separate unit.

## Key constraints

- `AGENTS.md` must stay tight: **≤ 45 lines total** (`wc -l AGENTS.md`). Mechanical rules, not an essay.
- Preserve the existing final line "Honest and brief beats thorough and padded."
- Keep all seven ladder rungs, in priority order, with the "understand first / trace the real flow" guard.
- No duplicated ladder text in the handoff template — just a pointer.

## When done

1. Run scripts/gate.sh from the repo root — it must pass.
2. Commit your work on this branch with a clear message.
3. Print a final summary: what changed and why, any acceptance criteria partially met, out-of-scope observations.
