---
name: 2-implement
description: Dispatch the implementer agent into an isolated worktree for an approved work unit, then drive the gate loop until green. Use after /1-plan approval.
---

# /2-implement — dispatch and gate

Input: an approved work unit `$(harness project)/work/<slug>/plan.md`.

Read `implementer.fan` from `config.yaml`.

- `N=1`: use the existing single-agent steps below, textually as written.
- `N>1`: use fan mode instead of step 1. Do not create `wt/<slug>` before adoption; `harness fan-exec adopt` creates the canonical worktree after retargeting `wt/<slug>`.

## Steps

1. **Create the worktree:** `WT=$(harness worktree add <slug>)`.
2. **Render the handoff** from `prompts/handoff.tpl` into `$(harness project)/work/<slug>/handoff.md`. Fill `{{PLAN_PATH}}` with the absolute `$(harness project)/work/<slug>/plan.md` path. It must be self-contained — the implementer starts cold.
3. **Dispatch:** `harness agent-exec "$WT" "$(harness project)/work/<slug>/handoff.md"`. agent-exec commits changes left by a successful dispatch. If it exits non-zero (including a rejected commit hook), stop and escalate to the Owner with its output; do not gate a branch missing the implementer's work. Capture the implementer's final summary into `$(harness project)/work/<slug>/notes.md`, then from the repo root run `harness worktree sync-artifacts <slug>`.
4. **Run the gate in the worktree:** `cd "$WT" && harness gate`. Trust the exit code, not the implementer's claim.
5. **On gate or demo failure:** render `prompts/followup.tpl` with `{{FAILURE_OUTPUT}}` set to the failing output and re-dispatch with `harness agent-exec "$WT" <followup> --allow-noop`. A non-zero agent-exec goes to the Owner as in step 3. From the repo root run `harness worktree sync-artifacts <slug>`, run the gate, then run step 6 only once the gate is green. Each followup dispatch counts once toward `gate.max_retries` from `config.yaml`, whether gate or demo triggered it. After that, stop and escalate to the Owner with the failing output; do not fix it yourself or lower the bar.
6. **On gate pass:** run `cd "$WT" && harness demo <slug>` from the orchestrator. Append its output to `work/<slug>/notes.md` in the primary checkout, then from the repo root run `harness worktree sync-artifacts <slug>` so the branch records it. Exit 0 proceeds to `/3-review`. Exit 2 is a plan or tooling error: stop and escalate to the Owner. Exit 1 containing `demo dirtied the worktree` also goes to the Owner: a followup auto-commit would hide that failure. Other exit-1 failures enter step 5's shared retry loop.

## Rules

- `wt/<slug>` reaches `main` only through its `/4-release` PR; the primary checkout stays on a clean `main`.
- A handoff citing a `PLAN.md` decision also names the `knowledge/` doc that explains how to satisfy it.

- You orchestrate; the implementer implements. If you catch yourself editing code in the worktree, you've collapsed the roles — stop.
- Footprint violations reported by the implementer go back to `/1-plan`, not into ad-hoc scope expansion.

## Fan Mode (`N>1`)

1. Render the same handoff from `prompts/handoff.tpl` into `$(harness project)/work/<slug>/handoff.md`.
2. Run `harness fan-exec dispatch <slug> "$(harness project)/work/<slug>/handoff.md" <N>`. Dispatch is sequential and prints a manifest containing only gate-passing sample branches.
3. Handle the manifest:
   - 0 survivors: run `harness fan-exec adopt <slug> <slug>-fan-1`, then run the main Steps section's step 5 gate-or-demo followup loop in `wt/<slug>` using `prompts/followup.tpl`, up to `gate.max_retries`; after that, stop and escalate to the Owner with the failing output.
   - 1 survivor: run `harness fan-exec adopt <slug> <survivor>`.
   - 2+ survivors: spawn a fresh `fan-selector` thread to rank the surviving diffs against the plan, then run `harness fan-exec adopt <slug> <winner>`.
4. The `fan-selector` is only a selector: it is distinct from `/3-review`'s `code-reviewer`, has a different output contract, and must not anchor or replace the later approver.
5. After adoption, all paths converge on populated `wt/<slug>`; from the repo root run `harness worktree sync-artifacts <slug>`, then run step 6, including the demo, on the adopted `wt/<slug>` before `/3-review`; failures use the main Steps section's step 5.
