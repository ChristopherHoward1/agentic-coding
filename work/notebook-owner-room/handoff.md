The implementer contract precedes this handoff — it is your contract.
Follow its build-discipline section while staying inside the plan footprint.

Work unit: /Users/cboyfly/Documents/repos/agentic-coding/work/notebook-owner-room/plan.md  (read it in full; it is your source of truth)
Branch: wt/notebook-owner-room (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
- `harness/profiles/work-slim.md` (Explore lane's notebook bullets)
- `harness/profiles/machine-learning.md` (`## Notebook writing`)
- `ARCHI.md` (`harness/profiles/` bullet only)

`PLAN.md` is in the plan's footprint but belongs to the orchestrator; do not edit it.

Every edit the plan names is authorized; stop only for an edit outside the footprint.
Nothing is committed while you work, so reads through `HEAD` (`git archive`, `git show HEAD:…`) will not see your changes.

Key constraints:
- Replace the existing notebook-writing paragraph and its three bullets (added in commit `7f7c87b`) in both profiles with the exact rule text from the plan's Approach blockquote, minus the leading `> `. The two copies must be byte-identical apart from indentation.
- In `work-slim.md` the paragraph and bullets stay indented three spaces under list item `1. **Explore**`, exactly as the current text is; do not dedent or renumber the lanes. Keep the blank line before `2. **Ship**`.
- In `machine-learning.md` the text stays under `## Notebook writing`, unindented.
- Leave `work-slim.md`'s report bullets (Question/Data/Method/Result/Read) unchanged.
- `ARCHI.md`: a targeted edit to the `harness/profiles/` bullet only. In the `machine-learning` parenthetical add `notebook writing (headings, core findings, a short descriptive read, an empty Owner cell per question)`; in the `work-slim` parenthetical add `the same notebook-writing rule`. Each of those strings must appear exactly once in ARCHI.md. Change nothing else in ARCHI.md.
- Do not touch `harness/profiles/work.md`.
- Every acceptance criterion in the plan is a shell command; run each one from the worktree root and confirm it passes. Criterion 2 reads `work/notebook-owner-room/plan.md` from the worktree (it is committed on the branch).

When done:
1. Run harness gate from the repo root — it must pass.
2. Print a final summary: what changed and why, criteria partially met (if any), out-of-scope observations.
