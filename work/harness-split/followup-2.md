Both round-1 reviewers (Claude code-reviewer and codex) raised the same HIGH on your implementation of work/harness-split/plan.md. You are resuming in the same worktree on branch wt/harness-split. Your contract is AGENTS.md in the repo root; the plan is the source of truth.

Sandbox rules from dispatch 2 still apply: do not run any command that writes the git index (`git add`, `git commit`, `git mv`, `git stash`). The orchestrator stages, commits, runs the full gate, and runs the demo.

HIGH — `bash harness <cmd>` fails from the repo root with "harness: is a directory" (exit 126). bash treats `harness` as a script path, finds the `harness/` directory in cwd first, and never consults PATH. Fix every occurrence:
- `harness/skills/4-release/SKILL.md:12` and `:17`, and `harness/skills/5-retro/SKILL.md:12` and `:27`: drop `bash ` → `harness release …`, `harness worktree …` (the form plan Approach 5 specifies).
- `ARCHI.md:53` (Verification): `harness gate`.
- `harness/profiles/work.md:65` (CI instructions): `bash harness/bin/harness gate` — run by path, since CI has no installed dispatcher on PATH (matches this repo's own CI).

Pin it: add a check to `harness/tests/test-scripts.sh` that fails if `grep -rnE 'bash harness( |$)'` matches anything under `harness/skills harness/agents harness/profiles harness/CONSTITUTION.md` or in `ARCHI.md` / `README.md` (use `$ROOT/...` paths). Show it fails with one occurrence reintroduced (verify the mutation landed), restore, and append that mutation to `work/harness-split/mutations.md`.

LOW (fix while here; cheap):
- `harness/tests/test-scripts.sh:2` header comment still says `bash tests/test-scripts.sh` → `bash harness/tests/test-scripts.sh`.
- `harness/agents/code-reviewer.md` (~:21) and `harness/skills/2-implement/prompts/handoff.tpl` say the demo runs "the branch copy"; under the plan's accepted binding shift (Approach 9) `harness demo` runs the installed copy against the branch tree. Reword to that, nothing more.

Stay inside the plan footprint. Pre-check from the worktree root: `shellcheck harness/scripts/*.sh harness/tests/*.sh harness/bin/harness scripts/*.sh scripts/gate.d/*.sh tests/*.sh harness/examples/gate.d/*.sh`, then `bash harness/tests/test-scripts.sh` and `bash tests/test-export.sh` (index-dependent failures: name them, don't work around them). End with an updated summary.
