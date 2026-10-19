The implementer contract precedes this handoff — it is your contract.
Follow its build-discipline section while staying inside the plan footprint.

Work unit: /Users/cboyfly/Documents/repos/agentic-coding/work/harness-publish/plan.md  (read it in full, including its ## Review section; it is your source of truth. The denylist mentioned in Review was DROPPED; build none of it.)
Branch: wt/harness-publish (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
Add:
- scripts/publish.sh
- tests/test-publish.sh
- harness/skeleton/config.yaml
Modify:
- harness/skills/init/SKILL.md (frontmatter description + step 0 only)
- harness/skills/4-release/SKILL.md (step 3's README wording and step 5 only)
- scripts/gate.d/test-scripts.sh
- README.md (Getting started + Layout only)
- ARCHI.md (targeted edits per plan Approach step 7)
Move (content unchanged): template/{ARCHI.md,PLAN.md,CHANGELOG.md,VERSION} -> harness/skeleton/
Delete: scripts/export-template.sh, scripts/sync-template.sh, tests/test-export.sh, .gitattributes
NOT to touch: .github/workflows/ci.yml, PLAN.md, VERSION, CHANGELOG.md, anything under harness/scripts/, harness/tests/, harness/bin/

Every edit the plan names is authorized. Do not stop to ask about an edit the plan itself requires; stop only for an edit outside this footprint.

Key constraints:
- Sandbox: you cannot write the git index or commit. Use plain `mv` / `rm` (never `git mv` / `git rm` / `git add`), and leave everything unstaged and uncommitted. The orchestrator stages and commits after you finish, and runs `harness demo` itself. Skip "When done" steps 2 and 3 below.
- Because nothing is staged, `git archive HEAD` in this worktree will not see your new files until the orchestrator commits. Test publish.sh through hermetic fixture repos that commit copies of your working-tree files, as tests/test-export.sh's fixture does; never through the live HEAD.
- The `harness` on PATH points at the primary checkout, not this worktree. Always run this worktree's copy: `bash harness/bin/harness gate` from the worktree root. Before the gate, pre-check with `shellcheck` on every new or changed `*.sh`, then run `bash tests/test-publish.sh` and `bash harness/tests/test-scripts.sh` directly.
- Shellcheck: CI and local both run 0.11.0. Indirectly invoked test functions still disable both SC2317 and SC2329 (ARCHI.md Conventions; tests/test-export.sh's header shows the pattern).
- The sandbox has no network. Tests must be hermetic:
  - `TEMPLATE_REPO` points at a local bare repo created with `--initial-branch=main`.
  - `TMPDIR` lives under the test's tmp dir, and every temp dir publish.sh makes is `mktemp -d "${TMPDIR:-/tmp}/publish.XXXXXX"`.
  - Fixtures export `GIT_AUTHOR_NAME/EMAIL` and `GIT_COMMITTER_NAME/EMAIL`.
- Bash 3.2-safe (macOS), `set -uo pipefail`, matching the style of the scripts being replaced (exit 0/1/2 contract, `error()` helper).
- Test-helper rules: knowledge/test-helper-contract.md.
- Guard pinning: knowledge/silent-no-op-hazards.md (PLAN.md Decisions 2026-08-27 and 2026-08-28). Mutate two guards: the path-limited archive (mutated to a full-HEAD archive) and the tag check. For each one, confirm the mutation landed, confirm the named test fails, then restore. The export-temp-dir removal mutation is run on macOS by the orchestrator, not by you.
- Put one line per guard in your final summary: the mutation, its landing check, the failing test name, and the platform (`uname -s`).
- `harness/skeleton/config.yaml` is root `config.yaml` with `gate.required_tools` emptied and `archi.sources` replaced by a commented example. Everything else stays the same.
- README is published, so it must never name `publish.sh` or any other dogfood-only script.

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
