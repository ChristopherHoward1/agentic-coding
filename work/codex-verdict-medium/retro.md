# Retro: codex-verdict-medium

Retro written cold from the unit's shipped artifacts (`plan.md`, `notes.md`, `codex-review.md`) — the unit released as v2026.9.1 in a prior session without a retro; this closes that gap.

## What did the gate miss that a reviewer caught?

Nothing blocking — both reviewers returned APPROVE in round 1 with only LOW findings. Worth stating: the gate *structurally cannot* verify this unit's actual behavioral change. The change is prompt-text semantics (MEDIUM no longer gates the verdict), and the hermetic codex-review smoke tests use a canned reviewer that ignores prompt text. So the gate stayed green regardless of whether the edit was correct; only future real review runs confirm it. Inherent to prompt-only changes, already acknowledged in the plan — not a new lesson.

## What did every check miss?

The codex reviewer's first run exited 2 (tooling non-verdict): it emitted the plan's `Codex-review verdict:` sentinel form instead of the required `Codex verdict:` line, plausibly contaminated by the fact that this unit's *subject matter is verdict sentinels*. Recovered by re-run with a fresh reviewer. The exit-2/re-run machinery handled it exactly as designed and no sentinel was recorded from the exit-2 prose — so the guard worked. A one-off tied to this unit's subject; not durable.

## What got re-derived that a doc would have prevented?

**The `.claude/skills` → `skills/` symlink footprint notation.** This unit's own codex review noted it benignly ("satisfies the `.claude/skills/...` footprint because `.claude/skills` is a symlink to `../skills`"). One unit later, `implementer-ladder`'s round-1 codex review escalated the *same* notation to a blocking **HIGH** ("outside the declared footprint"), costing a full review round to resolve by normalizing the plan path. The confusion recurred and got more expensive because plans name footprints by the `.claude/` symlink alias while diffs touch the canonical tracked path (`skills/`, `agents/`) — a cold reviewer sees two different strings and can't be relied on to check `-ef`. A footprint-naming convention prevents it at the source. → **process** (see PLAN decision).

## What friction repeated from a prior retro?

None that wasn't already caught. The 2026-09-01 ARCHI-freshness-on-branch decision (from `exec-state`) *worked*: this unit's plan explicitly footprint-noted the branch ARCHI freshness bump and handled it, so that friction did not repeat.

## Routing

- **process** — footprint paths name the canonical tracked path, not the `.claude/` symlink alias. Applied as a one-line PLAN decision.
- **not worth keeping** — the exit-2 verdict-sentinel contamination (self-recovered, subject-specific, already covered by the exit-code contract); the gate's inability to test prompt semantics (inherent, already known).

Candidate considered, not applied here (crosses the mechanical file boundary → would be a `/1-plan` unit): teach the codex-review prompt that `.claude/skills` and `.claude/agents` are symlinks to tracked dirs so a same-file path is not a footprint violation. Not worth a unit — the naming convention prevents it regardless of reviewer, and `code-reviewer` already resolves it correctly via `-ef`.
