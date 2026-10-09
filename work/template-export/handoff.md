You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.
Follow its build-discipline section while staying inside the plan footprint.

Work unit: work/template-export/plan.md  (read it in full; it is your source of truth)
Branch: wt/template-export (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
- scripts/export-template.sh — new
- .gitattributes — new (export-ignore list)
- template/ARCHI.md, template/PLAN.md, template/CHANGELOG.md, template/VERSION — new
- tests/test-export.sh — new
- tests/test-scripts.sh — the one worktree-dir fallback case only
- scripts/gate.d/test-scripts.sh — also run tests/test-export.sh, after the TEST_SCRIPTS_RUNNING guard
- CLAUDE.md — TRIP paragraph made history-free
- config.yaml — worktrees: block removed entirely (no commented `dir:` line — the awk readers would parse it)
- skills/1-plan/SKILL.md, skills/2-implement/SKILL.md, skills/3-review/SKILL.md, skills/4-release/SKILL.md, .claude/agents/code-reviewer.md — the plan's step-7 rule lines
- ARCHI.md — targeted refresh (new script, template/, .gitattributes, tests/test-export.sh, worktrees.dir basename default, how to export)
- work/template-export/ — your notes only

Files NOT to touch: scripts/release.sh, scripts/worktree.sh, scripts/fan-exec.sh, README.md, .github/workflows/ci.yml, bitbucket-pipelines.yml, PLAN.md, knowledge/*. If one of them must change for the criteria to hold, stop and report — do not change it.

Key constraints:
- template/ARCHI.md and template/PLAN.md are the skeletons at commit 3b80c19 (`git show 3b80c19:ARCHI.md`, `git show 3b80c19:PLAN.md`), byte-for-byte.
- template/VERSION is exactly `1970.1.0`. template/CHANGELOG.md is only the header lines of the current CHANGELOG.md above the first `## ` heading.
- The export must reflect HEAD, never the working tree: `git archive HEAD` for the base, and overlay template/ files via `git ls-tree -r --name-only HEAD -- template/` + `git show HEAD:<path>` (template/ is export-ignored, so `git archive HEAD template` yields nothing).
- Exit codes: 0 success, 1 refusal (bad arg count with usage; existing non-empty dest, writing nothing), 2 tooling error.
- tests/test-export.sh builds every fixture by copying the current working tree's tracked + new (untracked, non-ignored) files into `mktemp -d`, `git init`, commit — never export from the live repo's HEAD and never edit the live checkout. Against the export it runs only the exported scripts/gate.sh and scripts/archi-fresh.sh (not the exported smoke suite — too slow for every gate). Match the style/helpers conventions of tests/test-scripts.sh (see knowledge/test-helper-contract.md and knowledge/silent-no-op-hazards.md).
- Every refusal and the HEAD-vs-working-tree case must be shown to fail with its guard removed (mutation-check each guard, confirm the mutation landed, then restore). Report which mutations you ran in your summary.
- Bash with `set -uo pipefail`; must pass shellcheck. Keep it lean per AGENTS.md's ladder.

When done:
1. Run scripts/gate.sh from the repo root — it must pass.
2. Commit your work on this branch with a clear message.
3. Run `scripts/demo.sh template-export` on the now-clean tree. If it fails, fix the problem, re-run the gate, commit, and re-run the demo. Exit 2 is a plan or tooling error, never a demo verdict; stop and surface it if it cannot be fixed within scope.
4. Print a final summary: what changed and why, paste the demo output, criteria partially met (if any), mutations run, out-of-scope observations.
