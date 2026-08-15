---
name: 3-review
description: Run an independent code review of an implemented work unit via a fresh code-reviewer subagent, then drive the fix loop to a merge-ready state. Use after /2-implement passes the gate.
---

# /3-review — independent review

Input: a work unit whose worktree branch `wt/<slug>` passed the gate.

## Steps

1. **Assemble artifacts, not transcripts:** the diff (`git diff main...wt/<slug>`), the plan path, and nothing else. The reviewer must never see the implementation conversation or your own commentary on the diff.
2. **Spawn the reviewer.** Launch the `code-reviewer` agent (fresh thread) with the diff, the plan path, and the worktree path, instructed to review per its own definition.
3. **Route findings:**
   - Substantive findings → back to the implementer via `/2-implement`'s followup flow (same worktree).
   - Trivial mechanical fixes (typo-grade) → you may fix them directly, but then the re-review in step 4 is mandatory, because you just became a writer.
4. **Re-review after any change:** spawn a *new* fresh code-reviewer thread on the updated diff. Repeat until APPROVE or 3 rounds — after 3, escalate the open findings to the Owner rather than grinding.
5. **Hand to the Owner:** verdict, findings summary (resolved and open), gate status, and the merge command. The Owner merges; you never do.

## Rules

- A reviewer thread is used exactly once. Re-reviews get new threads — a reviewer that already approved a direction is anchored.
- Record the final verdict in `work/<slug>/plan.md → Review` and flip its status.
