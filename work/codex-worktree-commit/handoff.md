The implementer contract precedes this handoff — it is your contract.
Follow its build-discipline section while staying inside the plan footprint.

Work unit: /Users/cboyfly/Documents/repos/agentic-coding/work/codex-worktree-commit/plan.md  (read it in full, including its ## Review section; it is your source of truth)
Branch: wt/codex-worktree-commit (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
Modify:
- harness/scripts/agent-exec.sh
- harness/scripts/gate.sh (shell file list only)
- harness/tests/test-scripts.sh
- harness/AGENTS.md (rule 2 only)
- harness/skills/2-implement/SKILL.md (steps 3, 5, 6; Fan Mode steps 3 and 5)
- harness/skills/2-implement/prompts/handoff.tpl
- harness/skills/2-implement/prompts/followup.tpl
- harness/skills/docs/prompts/handoff.tpl ("When done" only)
- harness/profiles/machine-learning.md and harness/profiles/work.md (the "before the commit lands" sentence only)
- ARCHI.md (only the lines plan Approach step 5 names)
NOT to touch: harness/scripts/fan-exec.sh, config.yaml, harness/agents/code-reviewer.md, PLAN.md, VERSION, CHANGELOG.md.

Every edit the plan names is authorized. Do not stop to ask about an edit the plan itself requires; stop only for an edit outside this footprint.

Key constraints:
- Sandbox: you cannot write the git index or commit. Use plain `mv` / `rm` (never `git mv` / `git rm` / `git add` / `git commit`), and leave everything unstaged and uncommitted. The orchestrator stages and commits after you finish, and runs `harness demo` itself. Skip "When done" steps 2 and 3 below. (This unit makes that the default; it doesn't apply to your own run yet.)
- Because nothing is committed, tests must never read your changes through `HEAD`. Fixtures copy working-tree files (as the existing `setup_agent_exec_fixture` does with `cp "$ROOT/harness/scripts/agent-exec.sh"`).
- Until the orchestrator commits, the current gate's `git ls-files '*.sh'` will not see new untracked scripts — this unit fixes that, so after your gate.sh change it will.
- The `harness` on PATH points at the primary checkout, not this worktree. Always run this worktree's copy: `bash harness/bin/harness gate` from the worktree root. Before the gate, pre-check with `shellcheck` on every changed `*.sh`, then run `bash harness/tests/test-scripts.sh` directly.
- Shellcheck: CI and local both run 0.11.0. Indirectly invoked test functions disable both SC2317 and SC2329 (ARCHI.md Conventions).
- The sandbox has no network. Tests must be hermetic; fixtures export or configure git author/committer identity.
- Bash 3.2-safe (macOS), matching the surrounding script style.
- Test-helper rules: knowledge/test-helper-contract.md.
- Guard pinning: knowledge/silent-no-op-hazards.md (PLAN.md Decisions 2026-08-27 and 2026-08-28). Mutate each guard the plan's acceptance criteria name: agent-exec's commit, its repo-mode `work/` exclusion, and in gate.sh the `-f` filter, `--others`, and `--exclude-standard`. For each one, confirm the mutation landed, confirm the named test fails, then restore.
- Put one line per guard in your final summary: the mutation, its landing check, the failing test name, and the platform (`uname -s`).
- The fan test "fan dispatch auto-commits non-committing sample work" changes only its subject assertion, to `Implementer changes for wt/demo-fan-2`. No other fan test changes.

When done:
1. Run `bash harness/bin/harness gate` from the worktree root. It must pass.
2. (Skipped: the orchestrator commits.)
3. (Skipped: the orchestrator runs the demo.)
4. Print a final summary covering:
   - what changed and why;
   - the gate result;
   - the mutation-evidence lines;
   - any criteria only partially met;
   - any out-of-scope observations.
