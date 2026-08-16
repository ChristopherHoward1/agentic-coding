# Architecture

_Generated and maintained by `/init` and `/compact` — a snapshot of what the codebase IS, so agents don't re-derive it every session. Regenerate rather than hand-groom._

## Stack

Bash (`set -uo pipefail`, macOS/Linux) and Markdown. No compiled language, no package manager. The "runtime" is Claude Code itself: skills orchestrate, agents review, shell scripts do the deterministic work. The configured implementer is the `codex` CLI. Only external tool the gate needs is `shellcheck`.

## Layout

- `CLAUDE.md` / `ARCHI.md` / `PLAN.md` — the hot context tier (loaded every session, ~300-line budget).
- `config.yaml` — the single knob: profile, per-role models, implementer runtime, gate command, worktree dir.
- `skills/` — the loop stages (`1-plan`, `2-implement`, `3-review`) plus `init` and `compact`. Each is a `SKILL.md`; `1-plan` and `2-implement` carry `prompts/*.tpl` (plan, handoff, followup). Exposed to Claude Code via the `.claude/skills → ../skills` symlink.
- `.claude/agents/` — fresh-subagent definitions (`plan-reviewer.md`, `code-reviewer.md`): read-only tools, separate model, cold context.
- `scripts/` — the deterministic layer: `gate.sh` (stack-detecting check runner), `worktree.sh` (isolated-checkout lifecycle), `agent-exec.sh` (dispatches the implementer into a worktree). `gate.d/*.sh` holds project-specific gate hooks (none yet).
- `profiles/` — `software` (base), `machine-learning`, `database`; selected by `config.yaml`'s `profile:`.
- `tests/test-scripts.sh` — smoke tests for the shell layer.
- `knowledge/` — cold-tier docs, loaded only on citation (empty but for a README).
- `work/<slug>/` — one directory per work unit (`plan.md` etc.).
- `AGENTS.md` — the contract the implementer subagent reads.

## Entry points

- **The loop:** `/1-plan` → `/2-implement` → `/3-review` → Owner merges. Invoked as skills from the orchestrator session.
- **`scripts/gate.sh`** — run from anywhere in the tree; `cd`s to repo root, auto-detects stacks (Node/Python/Shell/Rust/Go), runs applicable checks + `gate.d/*.sh` hooks. Exit 0 = pass.
- **`scripts/worktree.sh add|remove|list <slug>`** — manages worktrees under `../agentic-coding-worktrees`.
- **`scripts/agent-exec.sh <worktree> <handoff>`** — feeds a handoff to the implementer runtime inside a worktree.
- **`tests/test-scripts.sh`** — `bash tests/test-scripts.sh` from repo root.

## Conventions

- **Writer never reviews.** Reviews come only from fresh `.claude/agents/` subagents (read-only, separate model). Never review a diff produced in your own thread.
- **The gate is authoritative.** Never overrule, reinterpret, or declare work done while `gate.sh` fails. It is a script, not a judgment call.
- **Implementation happens in worktrees, never in this checkout.** Use `worktree.sh`.
- **`worktree.sh` only asks git** (`git worktree`, `git rev-parse`) — it never inspects `.git` directly, so it works from inside a worktree where `.git` is a file. Preserve this.
- **YAML parsing is naive awk** in `worktree.sh` and `agent-exec.sh` — no comments mid-line in the keys it reads. Replace with `yq` only if it bites.
- All shell scripts must pass `shellcheck` (enforced by the gate). Use `set -uo pipefail`.
- Vendor/model names live only in `config.yaml`. Reviewer models are additionally in agent frontmatter, which is authoritative; config.yaml documents intent.

## Verification

`bash scripts/gate.sh` — on this repo, runs `shellcheck` over all tracked `*.sh`. `bash tests/test-scripts.sh` — the fuller smoke suite (worktree lifecycle, agent-exec validation, gate run). Both currently pass.
