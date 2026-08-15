# agentic-coding

An end-to-end agentic development framework for a solo developer. One Claude Code session orchestrates; skills define the stages; fresh subagent threads enforce writer ≠ reviewer; worktrees isolate implementers; a shell-script gate decides pass/fail.

No custom runtime, no ceremony that doesn't catch defects.

## The loop

```
/1-plan  →  /2-implement  →  /3-review  →  you merge
```

| Stage | Who | Isolation |
|---|---|---|
| `/1-plan` | Orchestrator drafts; **plan-reviewer** subagent critiques | fresh thread, read-only, cold context |
| `/2-implement` | Implementer agent (configurable, default Codex) | isolated git worktree, branch `wt/<slug>` |
| gate | `scripts/gate.sh` — a script, not an opinion | exit 0 or feedback loops back to the implementer |
| `/3-review` | **code-reviewer** subagent | new fresh thread, read-only, sees diff + plan only |
| merge | you | always |

Trivial fixes skip the loop. The loop is for work with enough surface to get wrong.

## Design rules

1. **Writer never reviews** — enforced by fresh subagent threads with read-only tools, not by prose.
2. **The gate is deterministic** — agents don't argue with exit codes; failure output *is* the retry prompt.
3. **Artifacts flow, not transcripts** — reviewers see the diff and plan, never the implementation conversation.
4. **Context is tiered** — hot (CLAUDE.md + ARCHI.md + PLAN.md, ~300 lines total), warm (active skill + profile), cold (`knowledge/`, loaded on citation, starts empty).
5. **Vendor names live in `config.yaml` only** — swap Codex for anything by editing one line.

## Layout

```
CLAUDE.md            orchestrator constitution (hot)
ARCHI.md             architecture snapshot, regenerated not groomed (hot)
PLAN.md              one screen: objective, now, decisions, risks (hot)
AGENTS.md            implementer contract
config.yaml          profile, models per role, implementer command, gate settings
skills/              1-plan, 2-implement, 3-review, init, compact (+ prompts/*.tpl)
profiles/            software | machine-learning | database — add slots, never override
scripts/             gate.sh, worktree.sh, agent-exec.sh (+ gate.d/ extensions)
work/<slug>/         one directory per work unit: plan.md, handoff.md, notes.md
knowledge/           cold-tier reference docs — earned, not designed
.claude/agents/      plan-reviewer, code-reviewer (read-only tools, own models)
```

## Getting started

1. Use this repo as a template (or copy it into an existing project).
2. Open in Claude Code and run `/init` — it scans the codebase, generates `ARCHI.md`, sets the profile, and verifies the gate runs.
3. Start work: `/1-plan <what you want>`.

## Requirements

- Claude Code (orchestrator + reviewers)
- An implementer CLI (default: `codex`; set `implementer.command` in `config.yaml`)
- `git`, `bash`, and whatever your project's gate needs (`shellcheck`, `ruff`, `pytest`, ...)
