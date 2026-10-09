Review round 1 on your implementation of work/docs-stage/plan.md requested changes. You are resuming in the same worktree on branch wt/docs-stage.

Fix these findings. Stay inside the plan's footprint (`skills/docs/SKILL.md`, `skills/docs/prompts/handoff.tpl`, `ARCHI.md` only).

1. HIGH — `skills/docs/SKILL.md` step 2 says to render `prompts/handoff.tpl` but never says how to fill `{{SLUG}}`, `{{FILES_TO_MODIFY}}` and `{{CONSTRAINTS}}`. Without that the docs writer can be dispatched with unresolved placeholders and no footprint boundary. State in step 2 that they come from the plan: the slug, the plan's "Files to modify" list, and the plan's constraints (including "Files NOT to touch"). No unresolved `{{...}}` may remain in the rendered handoff.

2. MEDIUM — `skills/docs/prompts/handoff.tpl` line 1 tells the writer to read AGENTS.md as "your contract". AGENTS.md is the implementer contract and its rule 3 requires running `scripts/gate.sh` and not reporting done while it fails, which contradicts the skill's "No gate loop". Keep the pointer to AGENTS.md for scope and stop-and-surface rules, but say explicitly that its gate rule does not apply to docs units: do not run the gate.

3. LOW — `skills/docs/SKILL.md` step 3 says "Capture the writer's final summary" without a destination. Name `work/<slug>/notes.md`, matching `/2-implement`.

Then run `scripts/gate.sh` once to confirm shellcheck and the smoke suite still pass (these files are Markdown, so they should), commit the fix on this branch, and print an updated summary. If a finding cannot be fixed within the footprint, stop and explain why instead of working around it.
