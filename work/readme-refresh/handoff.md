The implementer contract precedes this handoff — it is your contract. Its gate rule does not apply to docs units: do not run the gate.
Author or rewrite documentation for a human audience: the Owner and coworkers. Use clear, plain, GPT-style prose.

Work unit: /Users/cboyfly/Documents/repos/agentic-coding/work/readme-refresh/plan.md  (read it in full; it is your source of truth)
Branch: wt/readme-refresh (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
- `README.md`

Key constraints:
- Files NOT to touch: everything except `README.md` (no `harness/`, `ARCHI.md` or `PLAN.md` edits).
- The README is published in the public template: name no dogfood-only scripts (e.g. `scripts/publish.sh`) and nothing about the Owner's employer or work environment. The shared-repo section stays generic.
- Do not invent features: every claim must match the shipped skills, scripts and profiles under `harness/`. Check claims against `harness/CONSTITUTION.md`, `harness/skills/*/SKILL.md`, `harness/profiles/work-slim.md` and `harness/scripts/` when in doubt.
- Keep both mermaid diagrams valid mermaid and keep the existing `classDef` styling.
- "Why the agents grill each other": at most ~12 lines, plain direct sentences; drop the rhetorical framing, the blockquote and bold lead-ins, as the plan's change 4 describes.
- New "Using it in a shared repo" section: at most ~20 lines, after "Best-of-N implement", as the plan's change 3 describes.
- Total README length grows by no more than ~15 lines. Plain prose, no filler, no emoji, no marketing tone.
- Leave Design rules, Layout, Getting started and Requirements unchanged unless something there is now wrong.
