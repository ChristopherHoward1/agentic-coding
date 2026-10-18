Relocated the framework under `harness/`, added the dispatcher and bootstrap forwarders, and updated references, tests, CI, and docs.

Validation:
- Shellcheck passes.
- All three mutation pins fail their named cases, then pass after restoration.
- Script suite: **204 passed, 1 failed**—the self-gate reads moved paths from the unchanged index.
- Export suite: **12 failed**—every fixture aborts copying indexed `profiles/database.md`, now moved.

Details are in [mutations.md](work/harness-split/mutations.md).

Per Dispatch 2, work is uncommitted; commit and demo were skipped. The orchestrator must stage, rerun the gate/export tests, and perform agent discovery and demo checks. No out-of-scope files were changed.
Relocated the framework under `harness/`, added the dispatcher and bootstrap forwarders, and updated references, tests, CI, and docs.

Validation:
- Shellcheck passes.
- All three mutation pins fail their named cases, then pass after restoration.
- Script suite: **204 passed, 1 failed**—the self-gate reads moved paths from the unchanged index.
- Export suite: **12 failed**—every fixture aborts copying indexed `profiles/database.md`, now moved.

Details are in [mutations.md](work/harness-split/mutations.md).

## Orchestrator notes

- Dispatch 1 changed nothing: the codex sandbox can't write the worktree's git index, so `git mv` failed (`dispatch-1.log`). Dispatch 2 (`followup-1.md`) used plain `mv`, and the orchestrator staged it with `git add -A`. Rename detection kept the history: `git log --follow` gives `harness/scripts/release.sh` 12 commits, `harness/skills/3-review/SKILL.md` 18, and `harness/agents/code-reviewer.md` 8.
- After staging, `bash harness/bin/harness gate` passes from the worktree root and from `harness/scripts/` (205/0 scripts, 12/0 export). The forwarders work when run directly: `scripts/gate.sh` exits 0, `scripts/demo.sh --help` prints the `harness demo` usage, and `scripts/archi-fresh.sh HEAD` and `harness archi-fresh HEAD` both exit 0. All four files are mode 100755.
- Demo: `harness demo harness-split` exits 0, and its output matches the plan's Expected (`demo.log`).
- Agent discovery, from a fresh `claude -p` run in `$WT`, through the `.claude/agents → ../harness/agents` symlink: it lists `code-reviewer`, `fan-selector` and `plan-reviewer`, so the per-file fallback isn't needed.
