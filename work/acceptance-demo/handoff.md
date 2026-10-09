You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.
Follow its build-discipline section while staying inside the plan footprint.

Work unit: work/acceptance-demo/plan.md  (read it in full; it is your source of truth — Approach and Acceptance criteria are the spec)
Branch: wt/acceptance-demo (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
- scripts/demo.sh (new)
- tests/test-scripts.sh (hermetic demo.sh cases)
- skills/1-plan/prompts/plan.tpl (`## Verification` → `## Demonstration`)
- skills/2-implement/prompts/handoff.tpl (order: gate → commit → `scripts/demo.sh <slug>`; on demo failure fix, re-gate, commit, re-run; paste demo output in summary)
- skills/2-implement/prompts/followup.tpl (re-run gate, commit, then re-run `scripts/demo.sh <slug>`)
- .claude/agents/plan-reviewer.md (fifth judgment: is the demonstration real?)
- .claude/agents/code-reviewer.md (run `cd <worktree> && scripts/demo.sh <slug>` yourself; failing or non-demonstrating demo = HIGH)
- ARCHI.md (targeted edit: describe scripts/demo.sh; update the test check count and the tests/test-scripts.sh + Verification descriptions)

Do NOT touch: skills/2-implement/SKILL.md, skills/3-review/SKILL.md, scripts/codex-review.sh, scripts/release.sh, scripts/state.sh, scripts/gate.sh, PLAN.md, README.md. If the footprint is wrong, stop and report it — do not expand scope.

Key constraints:
- demo.sh contract (see plan Approach): `scripts/demo.sh <slug> [<dir>]`, default dir `.`; reads `<dir>/work/<slug>/plan.md`; section = `## Demonstration` up to the next `## ` heading, where `## ` lines count as headings only OUTSIDE a fence; takes the first ```sh or ```bash fenced block in that section and runs it as plain `bash <file>` (no -e) with cwd `<dir>`, streaming stdout/stderr. `None: <reason>` body → print `demo: none — <reason>`, exit 0.
- Exit codes: 0 pass; 1 block exited non-zero (message names the real exit code) OR `git -C <dir> status --porcelain` differs before vs after (message `demo dirtied the worktree`); 2 plan/tooling error (no plan, no section, no block/None: before next heading, `<dir>` not a git work tree). 2 is never a demo verdict.
- Match house style of the other scripts (`set -uo pipefail`, errors to stderr, `--help` usage like scripts/archi-fresh.sh). Must pass shellcheck.
- Tests: hermetic fixtures in temp git repos using the existing check helpers in tests/test-scripts.sh. Cover every case in Acceptance criteria 1–2, including: earlier-section block not run; empty Demonstration followed by a later section with an sh block → exit 2 and that block not run; `## ` line inside the block runs in full; bash fence accepted; untracked file created → 1 with dirtied message; non-git dir → 2. Write tests so that removing the section-start scoping, the section-end scoping, or the dirty-tree check makes at least one test fail (the reviewer will mutation-test these three guards).
- plan.tpl's `## Demonstration` must state: run the real changed behavior on real inputs (not fixtures), write only under `mktemp -d`, include a fenced sh placeholder and a one-line "Expected:" after it; `None: <reason>` only for units with no runnable behavior.

When done:
1. Run scripts/gate.sh from the repo root — it must pass.
2. Commit your work on this branch with a clear message.
3. Run `scripts/demo.sh acceptance-demo` on the now-clean tree (this unit's own demonstration). If it fails, fix, re-run the gate, commit, and re-run.
4. Print a final summary: what changed and why, the demo output, criteria partially met (if any), out-of-scope observations.
