# Architecture

_Generated and maintained by `/init` and `/compact` — a snapshot of what the codebase IS, so agents don't re-derive it every session. Regenerate rather than hand-groom._

## Stack

Bash (`set -uo pipefail`, macOS/Linux) and Markdown. No compiled language, no package manager. The "runtime" is Claude Code itself: skills orchestrate, agents review, shell scripts do the deterministic work. The configured implementer is the `codex` CLI. Only external tool the gate needs is `shellcheck`.

## Layout

- `CLAUDE.md` / `ARCHI.md` / `PLAN.md` — the hot context tier (loaded every session, ~300-line budget).
- `config.yaml` — the single knob: profile, per-role models, implementer runtime, gate command, worktree dir.
- `skills/` — the loop stages (`1-plan`, `2-implement`, `3-review`, `4-release`) plus `init` and `compact`. Each is a `SKILL.md`; `1-plan` and `2-implement` carry `prompts/*.tpl` (plan, handoff, followup). Exposed to Claude Code via the `.claude/skills → ../skills` symlink.
- `.claude/agents/` — fresh-subagent definitions (`plan-reviewer.md`, `code-reviewer.md`): read-only tools, separate model, cold context.
- `scripts/` — the deterministic layer: `gate.sh` (stack-detecting check runner), `worktree.sh` (isolated-checkout lifecycle), `agent-exec.sh` (dispatches the implementer into a worktree), `release.sh` (release preconditions + version/changelog/commit/tag/local ff-merge; never pushes). `gate.d/test-scripts.sh` wires the smoke suite into the gate.
- `VERSION` / `CHANGELOG.md` — CalVer (`YYYY.M.MICRO`, currently 2026.8.0) and Keep-a-Changelog history; both written only by `release.sh`.
- `profiles/` — `software` (base), `machine-learning`, `database`; selected by `config.yaml`'s `profile:`.
- `tests/test-scripts.sh` — smoke tests for the shell layer (17 checks, incl. release refusals, rollback, happy path in a real worktree topology).
- `knowledge/` — cold-tier docs, loaded only on citation (empty but for a README).
- `work/<slug>/` — one directory per work unit (`plan.md` etc.).
- `AGENTS.md` — the contract the implementer subagent reads.

## Entry points

- **The loop:** `/1-plan` → `/2-implement` → `/3-review` → `/4-release`. Invoked as skills from the orchestrator session; release pushes only after one in-session Owner confirm.
- **`scripts/gate.sh`** — run from anywhere in the tree; `cd`s to repo root, auto-detects stacks (Node/Python/Shell/Rust/Go), runs applicable checks + `gate.d/*.sh` hooks. Exit 0 = pass.
- **`scripts/release.sh <slug> [--confirm-delta <text>]`** — the release driver; also `check-version` / `next-version` subcommands for the CalVer logic.
- **`scripts/worktree.sh add|remove|list <slug>`** — manages worktrees under `../agentic-coding-worktrees`.
- **`scripts/agent-exec.sh <worktree> <handoff>`** — feeds a handoff to the implementer runtime inside a worktree.
- **`tests/test-scripts.sh`** — `bash tests/test-scripts.sh` from repo root.

## Conventions

- **Writer never reviews.** Reviews come only from fresh `.claude/agents/` subagents (read-only, separate model). Never review a diff produced in your own thread.
- **The gate and release are scripts, and authoritative.** Never overrule `gate.sh` or `release.sh`; enforcement never lives in skill prose.
- **Implementation happens in worktrees, never in this checkout.** Use `worktree.sh`.
- **Verdict sentinels are distinct by stage:** plan reviews write `Plan verdict:`, code reviews write `Code-review verdict:`; `release.sh` releases only on an exact `Code-review verdict: APPROVE` line in the unit's plan (final verdict overwrites, never appends).
- **Release preconditions:** APPROVE sentinel, gate green, `ARCHI.md` fresher than the last commit touching `scripts/ skills/ profiles/ config.yaml CLAUDE.md` (stale → run `/compact`), version strictly increasing (numeric field-wise). Nothing irreversible before all checks pass; trap-based rollback covers commit/tag/merge failures.
- **`worktree.sh` only asks git** (`git worktree`, `git rev-parse`) — it never inspects `.git` directly, so it works from inside a worktree where `.git` is a file. Preserve this.
- **YAML parsing is naive awk** in `worktree.sh` and `agent-exec.sh` — no comments mid-line in the keys it reads. Replace with `yq` only if it bites.
- All shell scripts must pass `shellcheck` (enforced by the gate). Use `set -uo pipefail`.
- Vendor/model names live only in `config.yaml`. Reviewer models are additionally in agent frontmatter, which is authoritative; config.yaml documents intent.

## Verification

`bash scripts/gate.sh` — shellcheck over all tracked `*.sh` plus the `gate.d/` smoke-suite hook (17 checks). CI runs the gate on push. Both currently pass.
