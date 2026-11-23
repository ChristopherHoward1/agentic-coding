---
name: docs
description: Write or rewrite documentation prose (README, guides, profile text) directly, on a branch through the small-fix lane. Use when the change is prose only.
---

# /docs — write documentation

Input: what to write or rewrite, from the Owner's request.

## Steps

1. **Branch:** `WT=$(harness worktree add <slug>)`, and write in that worktree, never the primary checkout.
2. **Write the prose yourself.** Check every claim against the shipped code, skills and profiles. Name nothing that doesn't exist, and don't describe planned work as done.
3. **Show the Owner the diff.** The Owner is the reader and the reviewer of prose quality; there is no automated judge.
4. **Ship by the small-fix lane:** commit, push the branch, open a PR to the default branch, and merge it once the Owner is happy and CI passes. Then remove the worktree and branch. Prose never goes through `/3-review` → `/4-release`, which would review it as code.

## Rules

- **Prose only.** If the change needs a code, script or test edit, that part goes through `/1-plan`.
- **No gate loop.** Prose has no exit-code contract.
- **Plain and short.** No filler, marketing tone or private shorthand. Explain each term a cold reader wouldn't know, or cut it.
- **Published files stay generic.** A file that ships in a public template names no dogfood-only scripts and nothing from the Owner's work environment.
