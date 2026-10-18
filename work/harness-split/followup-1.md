You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.
Follow its build-discipline section while staying inside the plan footprint.

Work unit: work/harness-split/plan.md  (read it in full; it is your source of truth)
Branch: wt/harness-split (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
- `harness/**` — every file moved per Approach 1 (use `git mv`), new `harness/bin/harness`, and the reference rewrites inside them
- `scripts/gate.sh`, `scripts/archi-fresh.sh`, `scripts/demo.sh` — recreated at the old paths as two-line bootstrap forwarders (mode 100755)
- `scripts/gate.d/test-scripts.sh`, `tests/test-export.sh`
- `CLAUDE.md` (single line `@harness/CONSTITUTION.md`), `config.yaml` (`gate.command: harness gate`)
- `.claude/skills`, `.claude/agents` (symlinks into `harness/`)
- `.github/workflows/ci.yml`, `bitbucket-pipelines.yml`
- `README.md`, `ARCHI.md`, `knowledge/release-script-binding.md`
- `work/harness-split/mutations.md` (new: your mutation record)

Key constraints:
- Files NOT to touch: `scripts/export-template.sh`, `scripts/sync-template.sh`, `template/`, root `AGENTS.md`, other `knowledge/**` files, `work/**` outside `work/harness-split/`, `.claude/settings.local.json`. If the export breaks under the new layout beyond expected-path updates in `tests/test-export.sh`, stop and report instead of editing those files.
- Behavior-preserving relocation. No script behavior changes beyond: `HERE`-relative sibling lookup (computed before any `cd`), the new `SOURCE_PATHS` list in archi-fresh, usage strings / `state.sh` next_action wording, and the new dispatcher.
- Approach 6 lists exact test-file line changes, including the bare cwd-relative paths at `:942-959`, `:1459`, `:1738-1739` — a `check_fails` against a missing file passes vacuously (exit 127), so those must point at real files.
- Every new guard must be pinned by a mutation that you verified actually landed (grep the mutated file) and that fails a named case; record each in `work/harness-split/mutations.md`. Why and how: `knowledge/silent-no-op-hazards.md` and `knowledge/test-helper-contract.md`.
- Gate command for this unit: `bash harness/bin/harness gate` (the `scripts/gate.sh` forwarder must also work). Neither `harness` on PATH nor network is available to you — don't rely on them.
- The orchestrator (not you) performs the fresh-`claude -p` agent-discovery check and the post-merge steps from Approach 8; leave those to it.
- If your sandbox can't create commits, leave the finished work uncommitted and say so in your summary — the orchestrator will commit.

When done:
1. Run `bash harness/bin/harness gate` from the repo root — it must pass.
2. Commit your work on this branch with a clear message.
3. Run `bash harness/bin/harness demo harness-split` on the now-clean tree. If it fails, fix the problem, re-run the gate, commit, and re-run the demo. Exit 2 is a plan or tooling error, never a demo verdict; stop and surface it if it cannot be fixed within scope.
4. Print a final summary: what changed and why, paste the demo output, criteria partially met (if any), out-of-scope observations.

---
DISPATCH 2 — sandbox correction (read this before starting; it overrides the git-related instructions above):

Your first attempt stopped because the sandbox cannot write this worktree's git metadata (`index.lock` is outside your writable roots). Nothing was changed. The orchestrator stages and commits for you. So:
- Do NOT use `git mv`, `git add`, `git commit`, or any command that writes the git index. Do plain filesystem moves (`mkdir -p` + `mv`) and edits. The orchestrator will `git add -A`; rename detection preserves `git log --follow` history because moved files keep nearly identical content — so keep moved files' content changes minimal (path rewrites only).
- `.claude/agents` is a real directory holding the three agent files: `mv` the files to `harness/agents/` first, then `rmdir .claude/agents`, then create the symlink.
- `git ls-files` (used by `gate.sh`'s shellcheck step) reads the index, which you can't update, so the full gate will mis-list moved files until the orchestrator stages. Your pre-check instead is, from the worktree root:
  1. `shellcheck harness/scripts/*.sh harness/tests/*.sh harness/bin/harness scripts/*.sh scripts/gate.d/*.sh tests/*.sh harness/examples/gate.d/*.sh`
  2. `bash harness/tests/test-scripts.sh` and `bash tests/test-export.sh` — both must pass (these build their own temp repos and work in the sandbox; if a case fails only because it reads this worktree's index, name it in your summary rather than working around it).
- Do the mutation pins as specified (mutate, verify landed, confirm the named case fails, restore), recorded in `work/harness-split/mutations.md`.
- Skip the commit and the demo steps; the orchestrator commits, runs the real gate and the demo. End with the summary.
