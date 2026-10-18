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
