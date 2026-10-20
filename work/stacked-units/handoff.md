The implementer contract precedes this handoff — it is your contract.
Follow its build-discipline section while staying inside the plan footprint.

Work unit: /Users/cboyfly/Documents/repos/agentic-coding/work/stacked-units/plan.md  (read it in full, including its ## Review section; it is your source of truth)
Branch: wt/stacked-units (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
Modify:
- harness/scripts/lib/stack.sh (new)
- harness/scripts/worktree.sh (`add` base choice; new `base`; usage strings)
- harness/scripts/codex-review.sh (base selection only)
- harness/scripts/release.sh (`check_stack_landed` and its call)
- harness/scripts/fan-exec.sh (stacked-plan refusal in `dispatch`)
- harness/tests/test-scripts.sh
- harness/skills/3-review/SKILL.md (step 1 only)
- harness/skills/1-plan/prompts/plan.tpl (the optional `Stacked on:` line)
- README.md (one Layout line for `lib/stack.sh`)
- ARCHI.md (targeted edits only)
NOT to touch: harness/scripts/state.sh, harness/scripts/agent-exec.sh, harness/scripts/gate.sh, PLAN.md, VERSION, CHANGELOG.md.

Every edit the plan names is authorized; stop only for an edit outside the footprint.
Nothing is committed while you work, so reads through `HEAD` (`git archive`, `git show HEAD:…`) will not see your changes.

Key constraints:
- Sandbox: you cannot write this worktree's git index or commit. Use plain `mv` / `rm` (never `git mv` / `git rm` / `git add` / `git commit` in this worktree) and leave everything unstaged. The orchestrator commits after you finish and runs `harness demo`. Git writes inside your own temporary test fixtures are fine.
- Tests must never read your changes through `HEAD`. Fixtures copy working-tree files, as the existing fixtures do with `cp "$ROOT/harness/scripts/..."`. `lib/stack.sh` must be copied alongside `lib/project.sh` wherever a fixture copies `worktree.sh`, `codex-review.sh`, `release.sh` or `fan-exec.sh`.
- `lib/stack.sh` is sourced the same way `lib/project.sh` is (`# shellcheck source=/dev/null` then `source "$HERE/lib/stack.sh"`), after `resolve_project` has set `PRIMARY_ROOT`, `STATE_DIR` and `PROJECT_MODE`.
- Reflog: `git merge-base --fork-point` reads the reflog of `refs/heads/wt/<parent>`. Fixture repos must be non-bare clones (reflogs on by default), and linked worktrees share the common dir's reflog. If a fixture needs it, set `core.logAllRefUpdates=true` explicitly rather than relying on a global default.
- The `harness` on PATH points at the primary checkout, not this worktree. Always run this worktree's copy: `bash harness/bin/harness gate` from the worktree root. Before the gate, pre-check with `shellcheck` on every changed `*.sh`, then run `bash harness/tests/test-scripts.sh` directly.
- Shellcheck: CI and local both run 0.11.0. Indirectly invoked test functions disable both SC2317 and SC2329 (ARCHI.md Conventions).
- The sandbox has no network. Tests must be hermetic (local bare `origin`); fixtures export or configure git author/committer identity. `review_base`'s fetch is best-effort and must not fail a hermetic test.
- Bash 3.2-safe (macOS), matching the surrounding script style.
- Test-helper rules: knowledge/test-helper-contract.md.
- Guard pinning: knowledge/silent-no-op-hazards.md (PLAN.md Decisions 2026-08-27 and 2026-08-28). Run every mutation the plan's acceptance criteria name: the "F on main → main ref" branch, the "F reachable from wt/<parent> → wt/<parent>" branch, `--fork-point` → current tip only, `--fork-point` → newest-ancestor reflog walk, and the inverted `origin/main:work/<parent>/plan.md` presence test. For each: confirm the mutation landed, confirm the named test fails, then restore.
- Put one line per mutation in your final summary: the mutation, its landing check, the failing test name, and the platform (`uname -s`).
- ARCHI.md: targeted edits only, and it must state the reflog-expiry limit (plan Approach step 2).

When done:
1. Run `bash harness/bin/harness gate` from the worktree root. It must pass.
2. Print a final summary covering: what changed and why; the gate result; the mutation-evidence lines; any criteria only partially met; any out-of-scope observations.
