---
name: 2-implement
description: Dispatch the implementer agent into an isolated worktree for an approved work unit, then drive the gate loop until green. Use after /1-plan approval.
---

# /2-implement — dispatch and gate

Input: an approved work unit `work/<slug>/plan.md`.

## Steps

1. **Create the worktree:** `WT=$(scripts/worktree.sh add <slug>)`.
2. **Render the handoff** from `prompts/handoff.tpl` into `work/<slug>/handoff.md`. It must be self-contained — the implementer starts cold.
3. **Dispatch:** `scripts/agent-exec.sh "$WT" work/<slug>/handoff.md`. Capture the implementer's final summary into `work/<slug>/notes.md`.
4. **Run the gate in the worktree:** `cd "$WT" && scripts/gate.sh`. Trust the exit code, not the implementer's claim.
5. **On failure:** render `prompts/followup.tpl` with the gate output and re-dispatch, up to `gate.max_retries` from `config.yaml`. After that, stop and escalate to the Owner with the failing output — do not fix it yourself in this stage, and do not lower the bar.
6. **On pass:** commit in the worktree if the implementer didn't, then proceed to `/3-review`.

## Rules

- You orchestrate; the implementer implements. If you catch yourself editing code in the worktree, you've collapsed the roles — stop.
- Footprint violations reported by the implementer go back to `/1-plan`, not into ad-hoc scope expansion.
