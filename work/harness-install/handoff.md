You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.
Follow its build-discipline section while staying inside the plan footprint.

Work unit: work/harness-install/plan.md  (read it in full; it is your source of truth)
Branch: wt/harness-install (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
- harness/scripts/install.sh (new)
- harness/scripts/agent-exec.sh
- harness/scripts/archi-fresh.sh
- AGENTS.md → harness/AGENTS.md (move + rule 3)
- harness/skills/2-implement/prompts/handoff.tpl
- harness/skills/docs/prompts/handoff.tpl
- harness/skills/init/SKILL.md
- harness/skills/4-release/SKILL.md
- harness/skills/1-plan/SKILL.md
- harness/tests/test-scripts.sh
- harness/CONSTITUTION.md
- harness/profiles/work.md
- config.yaml
- README.md
- ARCHI.md
- knowledge/test-helper-contract.md
- template/ARCHI.md
- deleted: scripts/gate.sh, scripts/demo.sh, scripts/archi-fresh.sh, bitbucket-pipelines.yml, .claude/skills, .claude/agents
- work/harness-install/mutations.md (record of the mutation checks the acceptance criteria require)
- PLAN.md is in the plan's footprint, but the orchestrator has already made its edit. Do not touch it.

Key constraints:
- **Git index access.** In past units the sandbox could not write the git index or commit: `git mv`, `git rm`, `git add` and `git commit` all failed. Do not use them. Move with plain `mv`, delete with plain `rm`, and leave the changes unstaged. The orchestrator stages and commits after you finish. If git writes do work for you, committing is fine, but do not depend on it.
- **Running the gate.** The gate shellchecks only `git ls-files`, so an unstaged new `harness/scripts/install.sh` escapes it. Before finishing, run all of these directly:
  - `shellcheck harness/scripts/*.sh harness/tests/*.sh harness/bin/harness`
  - `bash harness/tests/test-scripts.sh`
  - `bash tests/test-export.sh`
  - `harness gate`
  All four must pass. Report any that you could not run, and why.
- **Mutation pins.** Every mutation the acceptance criteria name must be shown to fail its case, and you must verify that the mutation actually landed. Revert each one afterwards. Record each in `work/harness-install/mutations.md` as: mutation, the failing case name, and how you verified it landed. Read `knowledge/silent-no-op-hazards.md` and `knowledge/test-helper-contract.md` first. They cover hermetic fixtures, the nested-gate environment (keep `GATE_REQUIRED_TOOLS` unset per command), and how to prove that an absence assertion can fail.
- **Test fixtures.** The agent-exec fixture (`harness/tests/test-scripts.sh:406`) and the fan-exec fixture (`:522`) copy `agent-exec.sh` into `<fixture>/scripts/`. Each needs a stub `AGENTS.md` at the fixture root, included in its initial commit. Without it, the existing cases break.
- **Shell style.** Install tests use `HOME=$(mktemp -d)`, with `CLAUDE_CONFIG_DIR` unset per command unless the case sets it. Never touch the real `~/.claude` or `~/.local/bin`. Scripts must be bash 3.2-safe, use `set -uo pipefail` (or `-euo` where the script already does), and pass shellcheck.
- **ARCHI.md.** Make targeted line edits only, at the lines the plan lists. Do not regenerate the file. README must never name the dogfood-only scripts (`export-template.sh`, `sync-template.sh`), because it ships in exported templates.

When done:
1. Run harness gate from the repo root — it must pass.
2. Commit your work on this branch with a clear message.
3. Run `harness demo harness-install` using the installed copy against the now-clean branch tree. If it fails, fix the problem, re-run the gate, commit, and re-run the demo. Exit 2 is a plan or tooling error, never a demo verdict; stop and surface it if it cannot be fixed within scope.
4. Print a final summary: what changed and why, paste the demo output, criteria partially met (if any), out-of-scope observations.

If you cannot commit (see the git index constraint above), skip steps 2–3. Instead, run the plan's Demonstration block yourself from the worktree root and paste its output into your summary. The orchestrator will commit and re-run `harness demo`.
