The implementer contract precedes this handoff — it is your contract.
Follow its build-discipline section while staying inside the plan footprint.

Work unit: work/harness-registry/plan.md  (read it in full; it is your source of truth)
Branch: wt/harness-registry (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
- harness/scripts/lib/project.sh (new)
- harness/scripts/project.sh (new)
- harness/scripts/register.sh (new)
- harness/scripts/{gate,worktree,agent-exec,demo,state,codex-review,archi-fresh,release,fan-exec}.sh
- harness/tests/test-scripts.sh
- tests/test-export.sh: one `HARNESS_HOME` export line only
- harness/CONSTITUTION.md, harness/AGENTS.md, harness/agents/code-reviewer.md, harness/agents/fan-selector.md
- harness/skills/{1-plan,2-implement,3-review,4-release,5-retro,init,docs}/SKILL.md
- harness/skills/2-implement/prompts/handoff.tpl, harness/skills/2-implement/prompts/followup.tpl, harness/skills/docs/prompts/handoff.tpl
- harness/profiles/work.md, README.md, ARCHI.md
- work/harness-registry/mutations.md (record of the mutation checks the acceptance criteria require)
- PLAN.md is in the plan's footprint, but the orchestrator has already made its edit. Do not touch it.

Do NOT touch: harness/bin/harness, harness/scripts/install.sh, root CLAUDE.md, config.yaml, scripts/, template/, .github/, harness/examples/, harness/profiles/{software,machine-learning,database}.md.

Key constraints:
- **Repo mode is byte-for-byte unchanged.** This repo has no registry entry, so every existing case in `harness/tests/test-scripts.sh` and `tests/test-export.sh` must pass. The only allowed edits to existing cases are copying `harness/scripts/lib/` into fixtures (before each fixture's first commit) and the `HARNESS_HOME` exports. Adding `"$HARNESS_HOME"` to the existing cleanup `trap` (about line 770) is part of the export change and is authorized, as is any edit the plan itself names. Don't stop to ask about those. If an existing case seems to need any other change, stop and report it; that's a plan problem, not something to work around.
- **Plan specifics that are easy to miss** (all in the plan's §1 and §4):
  - The lib uses only bash builtins, `git` and `awk`. The gate fixtures run with a stripped `PATH`.
  - `gate.sh` computes `HERE` without `dirname`, including when the path has no slash.
  - Use `# shellcheck source=/dev/null` on every `source` line, and `# shellcheck shell=bash` plus `# shellcheck disable=SC2034` at the top of the lib.
  - `resolve_project [<dir>]` is never called in a subshell, and only runs after argument, `--help` and git-checkout handling.
  - The one exception is `codex-review.sh`. Its registry guard goes right after `root=`.
  - Stale or malformed registry entries are skipped under `set -e`.
  - A missing state `config.yaml` reads as empty.
- **Hermetic tests.** Never read or write the real `~/.harness`, `~/.claude` or `~/.local/bin`.
  - `test-scripts.sh` exports a temp `HARNESS_HOME` near `unset GATE_REQUIRED_TOOLS`, and the existing trap removes it.
  - `tests/test-export.sh` exports its own.
  - Keep `GATE_REQUIRED_TOOLS` unset per command (`knowledge/test-helper-contract.md`).
- **Git index access.** In past units the sandbox could not write the git index or commit: `git mv`, `git rm`, `git add` and `git commit` all failed. Do not use them. Create files normally and leave every change unstaged. The orchestrator stages and commits after you finish. If git writes do work for you, committing is fine, but do not depend on it. Test fixtures under `mktemp -d` may run git freely.
- **Running the checks.** The gate shellchecks only `git ls-files`, so unstaged new files escape it. Before finishing, run all of these directly:
  - `shellcheck harness/scripts/*.sh harness/scripts/lib/*.sh harness/tests/*.sh harness/bin/harness`
  - `bash harness/tests/test-scripts.sh`
  - `bash tests/test-export.sh`
  - `bash harness/bin/harness gate`

  All four must pass. Report any that you could not run, and why.
- **Mutation pins.** Every mutation the acceptance criteria name must be shown to fail its case, and you must verify that the mutation actually landed. Revert each one afterwards. Record each in `work/harness-registry/mutations.md` as: mutation, the failing case name, and how you verified it landed. Read `knowledge/silent-no-op-hazards.md` and `knowledge/test-helper-contract.md` first.
- **Shell style.** Scripts must be bash 3.2-safe (macOS `/bin/bash`), use `set -uo pipefail` (or `-euo` where the script already does), and pass shellcheck. Match the surrounding style. Keep new code minimal.
- **Prose.**
  - The `test-scripts.sh` static greps pin literal strings in skills and agents. Keep them: `work/<slug>/review-round` in 3-review, the `":(exclude,top)work/<slug>"` pathspec in 3-review, `work/<slug>/deferrals.md` in code-reviewer.md, and `git show "$branch:$plan_path"` and `git show "main:config.yaml"` in codex-review.sh.
  - ARCHI.md gets targeted line edits only. Do not regenerate it.
  - README must never name `export-template.sh` or `sync-template.sh`.
- **Not yours:** the plan's manual `/memory` acceptance check is run by the orchestrator. Skip it.

When done:
1. Run harness gate from the repo root — it must pass.
2. Commit your work on this branch with a clear message.
3. Run `harness demo harness-registry` using the installed copy against the now-clean branch tree. If it fails, fix the problem, re-run the gate, commit, and re-run the demo. Exit 2 is a plan or tooling error, never a demo verdict; stop and surface it if it cannot be fixed within scope.
4. Print a final summary: what changed and why, paste the demo output, criteria partially met (if any), out-of-scope observations.

If you cannot commit (see the git index constraint above), skip steps 2–3. Instead, run the plan's Demonstration block yourself from the worktree root and paste its output into your summary. The orchestrator will commit and re-run `harness demo`.
