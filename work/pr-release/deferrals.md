# Accepted deferrals: pr-release

- **Code review round 2, codex MEDIUM: section extraction is not fence-aware.** `registry_release` ends the copied Goal or Acceptance-criteria section at any line starting `## `, including one inside a fenced block. A plan with such an example in those sections gets a truncated `pr.md`.
  - **Why deferred:** Goal and Acceptance-criteria bodies rarely hold fenced headings. The truncation is visible in `pr.md`, which the Owner edits before opening the PR. Both reviewers approved without it.
  - **Lands in:** a small fix when real use hits it. Reuse `demo.sh`'s fence tracking.
- **Code review round 2, codex MEDIUM: `/3-review` does not say to re-capture the reviewed SHA on each round.** An orchestrator that reuses the round-1 `reviewed` value after a fix commit would review the old diff and record the old SHA.
  - **Why deferred:** it fails safe. `harness release` refuses with `moved after review`, because HEAD ≠ `Reviewed-SHA`. The fix is one sentence of prose, but under `/3-review` step 4 the orchestrator making it would force another review round.
  - **Lands in:** the next unit that touches `/3-review`. Step 5 says to repeat step 1, including the SHA capture, for each round.
