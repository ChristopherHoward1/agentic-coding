Round-2 code review returned REQUEST CHANGES on work/codex-reviewer/plan.md. You are resuming in the same worktree on branch wt/codex-reviewer. The gate is green (51/51); these are review findings. Both independent reviewers converged on finding 1.

Findings to fix, most severe first:

```
1. scripts/codex-review.sh:81-85 — a failing reviewer leaves an approving audit
   artifact on disk. Reviewer stdout is redirected straight into
   work/<slug>/codex-review.md; if the command then exits non-zero (rate limit,
   teardown error, network drop after streaming "Codex verdict: APPROVE"), the script
   exits 2 but the artifact looks like a clean approval — and a truncated run silently
   clobbers the previous round's artifact. This file is the audit trail backing a
   hand-written sentinel, so it must not lie. Fix: capture reviewer stdout to a temp
   file; on reviewer exit 0, mv it into place; on non-zero, leave the previous
   artifact untouched (or write an explicit failure record) and exit 2. Update the
   existing approve-then-fail test to assert the ARTIFACT CONTENTS (previous artifact
   preserved / failure record present), not just the exit code.

2. skills/3-review/SKILL.md — the exit-code contract is never stated. Step 2 must
   name the contract explicitly: 0 = APPROVE (record the sentinel), 1 = REQUEST
   CHANGES (route the artifact's findings to the followup flow), >=2 = tooling error —
   NOT a verdict; never record a sentinel from prose in the artifact after a non-zero
   exit; fix the tooling and re-run.

3. scripts/codex-review.sh:66-77 — the verdict-format instruction is emitted at the
   head of the prompt; the plan specifies the prompt ENDS with it (after the diff).
   Move it to the tail (or repeat it there).

Non-blocking nits, fix cheaply while in the files:
   - codex-review.sh: refuse to run when $(git rev-parse --show-toplevel) is itself
     the wt/<slug> checkout (honest error instead of dirtying the release checkout);
   - check_exit: use grep -F for the stderr substring;
   - skills/3-review/SKILL.md: rephrase "sync the current plan body" vs "never copy
     the whole plan file" as "edit in place; do not cp over it" so the two sentences
     don't read as contradictory.
```

Stay inside the plan's footprint. Re-run scripts/gate.sh until it passes, commit the fix, and print an updated summary.
