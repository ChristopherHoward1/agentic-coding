# Bootstrap retro — 2026-08-15

Framework designed and built in one session, from a critique of `agentic-coding-template` plus convergent evidence from TRIP, ADHD, Overstory, Orkestra, and the Codified Context paper. Initial commit: `3b80c19`.

## What went well

- **The deterministic layer is real and verified.** 8/8 smoke tests pass; the suite caught two genuine defects (SC2164 in gate.sh, a malformed compound check in the tests) on its first run. The old repo's `.git`-as-file worktree bug is fixed by construction — `worktree.sh` only asks git, never inspects `.git`.
- **Hot tier is 81 lines** (CLAUDE.md + ARCHI.md + PLAN.md) against a 300-line budget. The old system's equivalent was ~1,400.
- Salvage worked: AGENTS.md contract, named profile slots, and checkable-acceptance-criteria carried over; the ceremony didn't.

## What is untested (the honest part)

The **entire agent loop has never run.** Skills never invoked, reviewer subagents never spawned, `agent-exec.sh` has never dispatched a real Codex run, the handoff/followup templates are unproven prose. Only the shell layer is validated. Treat everything else as a hypothesis until the first dogfood cycle.

## Known gaps and judgment calls

1. **Skill discovery via symlink** (`.claude/skills → ../skills`) is assumed, not verified.
2. **YAML parsing is naive awk** in `worktree.sh` and `agent-exec.sh` — fine until config.yaml gets a comment in the wrong place. Acceptable for now; replace with `yq` only if it actually bites.
3. **gate.sh** is only exercised on the shell stack; Node/Python/Rust/Go branches are untested.
4. **Model config duplication:** reviewer models appear in both `config.yaml` and the agent frontmatter. Frontmatter is what's authoritative; config.yaml documents intent. Unify if it causes a real mismatch.
5. No CI. Deliberate — add it as the first dogfooded work unit rather than hand-rolling it outside the loop.

## Next tasks (for a fresh session in this repo)

1. **Shakedown `/init`** — run it on this repo itself; it should fill ARCHI.md with no placeholders and confirm the gate + codex CLI. First test of skill discovery; if the symlink isn't picked up, fix discovery before anything else.
2. **Dogfood the full loop on a real first task: add CI** (GitHub Actions running `tests/test-scripts.sh` + `scripts/gate.sh` on PRs). Small, real, and exercises every stage: `/1-plan` → plan-reviewer subagent → `/2-implement` → worktree + Codex dispatch + gate → `/3-review` → code-reviewer subagent → merge.
3. **Fix what the dogfood run breaks.** Expected suspects: handoff template gaps (Codex missing context it needs), followup re-dispatch ergonomics, reviewer subagents needing sharper input framing.
4. **Then stop and use it on a real project** — `/init` against an actual codebase (the ML profile is the interesting stress test). No further framework work until real use demands it.
