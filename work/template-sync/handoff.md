You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.
Follow its build-discipline section while staying inside the plan footprint.

Work unit: work/template-sync/plan.md  (read it in full; it is your source of truth)
Branch: wt/template-sync (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
- scripts/sync-template.sh — new
- .gitattributes — one line: `scripts/sync-template.sh export-ignore`
- tests/test-export.sh — sync cases (a)–(d) per plan Approach step 4
- skills/4-release/SKILL.md — new step 5 (unconditional cleanup + `git pull --ff-only`; conditional sync part), renumber /5-retro to step 6, remove the Rules pull line it replaces
- ARCHI.md — targeted refresh: sync-template.sh on the scripts/ line and in Key flows
- work/template-sync/ — your notes and mutations.md only

Files NOT to touch: scripts/export-template.sh, scripts/release.sh, scripts/worktree.sh, README.md, PLAN.md, config.yaml, CLAUDE.md, .github/workflows/ci.yml, knowledge/*. If one must change for the criteria to hold, stop and report — do not change it.

Key constraints:
- sync-template.sh takes NO arguments (any arg → exit 1). Exit 0 success/up-to-date, 1 refusal, 2 tooling error. Never pushes.
- Tag check: `git tag --points-at HEAD | grep -qx "v$(cat VERSION)"` — not `git describe`.
- `TEMPLATE_REPO` defaults to https://github.com/ChristopherHoward1/agentic-coding-template.git and is overridable by env. That repo name must appear nowhere in skills/, config.yaml, or CLAUDE.md.
- Use bare `mktemp -d` (no template path) for both the clone dir and the export dir so tests can redirect them with TMPDIR. The export dir is always deleted (trap); the clone dir is kept and printed on success-with-commit, and deleted on the `up to date` path.
- In the clone: `git switch -c template-sync/v<version>`, `git rm -rq --ignore-unmatch .`, `cp -R "$exp/." "$clone/"`, `git add -Af`. No staged diff → print `up to date`. Otherwise commit `Sync from agentic-coding v<version> (<short-sha>)` and print clone path then branch name on two lines.
- Tests are hermetic: the existing `fixture` helper repo (tag it `v$(cat VERSION)` lightweight), a local bare "template" repo seeded with stale `conventions/x` and an old README.md, `TEMPLATE_REPO` pointing at it, and every case runs the fixture's own copy (`cd "$repo" && bash scripts/sync-template.sh`). Case (a) compares `HEAD^{tree}` against a scratch repo committing a fresh export, checks `HEAD~1` == the bare repo's original main, the clone path survives, and the bare repo's `git for-each-ref` output is unchanged. Case (b) per the plan uses an empty TMPDIR and asserts it stays empty. Case (c) includes the positive two-tag variant. Match the conventions in tests/test-export.sh and knowledge/test-helper-contract.md and knowledge/silent-no-op-hazards.md.
- Mutation-check every guard listed in the plan's acceptance criteria (confirm each mutation landed, see the named case fail, restore) and record them in work/template-sync/mutations.md.
- Bash with `set -uo pipefail`; must pass shellcheck. Keep it lean per AGENTS.md's ladder.
- The Demonstration needs network access to github.com. If your sandbox has none, say so in your summary rather than faking output.
- Your sandbox may be unable to write .git metadata for this linked worktree (git commit fails on index.lock). If so, leave the changes uncommitted, do NOT continue into the demo on the uncommitted tree, and report it — the orchestrator will commit and run the demo.

When done:
1. Run scripts/gate.sh from the repo root — it must pass.
2. Commit your work on this branch with a clear message.
3. Run `scripts/demo.sh template-sync` on the now-clean tree. If it fails, fix the problem, re-run the gate, commit, and re-run the demo. Exit 2 is a plan or tooling error, never a demo verdict; stop and surface it if it cannot be fixed within scope.
4. Print a final summary: what changed and why, paste the demo output, criteria partially met (if any), out-of-scope observations.
