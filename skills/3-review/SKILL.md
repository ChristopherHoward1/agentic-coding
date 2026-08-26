---
name: 3-review
description: Run an independent code review of an implemented work unit via a fresh code-reviewer subagent, then drive the fix loop to a merge-ready state. Use after /2-implement passes the gate.
---

# /3-review — independent review

Input: a work unit whose worktree branch `wt/<slug>` passed the gate.

## Steps

1. **Assemble artifacts, not transcripts:** the diff (`git diff main...wt/<slug>`), the plan path, and nothing else. Reviewers must never see the implementation conversation or your own commentary on the diff.
2. **Spawn both reviewers.** Launch the `code-reviewer` agent (fresh thread) with the diff, the plan path, and the worktree path, instructed to review per its own definition. From the primary checkout, run `scripts/codex-review.sh <slug>` so Codex reviews the branch plan and diff from cold, read-only context and writes `work/<slug>/codex-review.md`. Its exit-code contract is: 0 = APPROVE, so record the sentinel; 1 = REQUEST CHANGES, so route the artifact's findings to the followup flow; >=2 = tooling error, not a verdict. Never record a sentinel from prose in the artifact after a non-zero exit; fix the tooling and re-run.
3. **Route findings:**
   - Substantive findings from either reviewer → back to the implementer via `/2-implement`'s followup flow (same worktree).
   - Trivial mechanical fixes (typo-grade) → you may fix them directly, but then the re-review in step 4 is mandatory, because you just became a writer.
4. **Re-review after any change:** spawn a *new* fresh code-reviewer thread and re-run `scripts/codex-review.sh <slug>` on the updated diff. Repeat until both approve or 3 rounds total — after 3, escalate the open findings to the Owner rather than grinding.
5. **Record the approved result on the worktree branch:** when both reviewers approve, edit `work/<slug>/plan.md` in the worktree in place to include both `Code-review verdict: APPROVE` and `Codex-review verdict: APPROVE`, flip its status, and sync the current plan body. Commit that plan update in a single commit with `git -C <worktree> add work/<slug>/plan.md` and `git -C <worktree> commit ...`. Do not `cp` over it from the primary checkout, because that can clobber the sentinels.
6. **Hand off to release:** report both verdicts, findings summary (resolved and open), and gate status to the Owner, then proceed through the full `/4-release` TRIP.

## Rules

- A reviewer thread or Codex reviewer run is used exactly once. Re-reviews get new fresh reviews — a reviewer that already approved a direction is anchored.
- Record final verdicts in the worktree plan's Review section as `Code-review verdict: APPROVE|REVISE` and `Codex-review verdict: APPROVE|REQUEST CHANGES`.
