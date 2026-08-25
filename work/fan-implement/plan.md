# fan-implement — best-of-N Claude implementer

**Slug:** fan-implement · **Date:** 2026-08-24 · **Status:** reviewed — merge-ready

## Goal

Give `/2-implement` an opt-in best-of-N mode: render the same handoff into N isolated worktrees, run N Claude implementers (sequentially — dispatch is a simple loop, so N>1 costs N× wall-clock, not just N× tokens; no concurrency footprint), drop the ones that fail the gate, and pick one winner to carry into `/3-review`. **What this does and does not buy:** it reduces per-run implementer *variance/noise* — a single Claude sample can flub a task it usually gets right; N samples + gate-filtering + selection recover the good one. It does **not** close PLAN.md's correlated-validators risk: N Claude samples, a Claude selector, and a Claude `/3-review` reviewer are same-vendor self-consistency, not the cross-vendor diversity codex provided. `/4-release` and PLAN.md bookkeeping must not later imply this unit mitigated that risk. Default N=1 leaves today's single-agent path byte-for-byte unchanged; N>1 is reserved for high-value units because it costs N× implementer tokens. Done = a mechanical fan layer + a selection step that preserve every loop invariant, specced and tested but only activated by config.

## Approach

Keep mechanics in a script, judgment in the skill, downstream stages untouched.

- **`config.yaml`** — add `implementer.fan: 1` (N samples; default 1 = current behavior). The one knob.
- **`scripts/fan-exec.sh`** (new, deterministic) —
  - `dispatch <slug> <handoff> <N>`: for k in 1..N — `worktree.sh add <slug>-fan-k`, **seed the whole `work/<slug>/` dir into the sample worktree** (the branch is cut from main and lacks the still-uncommitted `plan.md` the implementer is told to read; this mechanizes a step that is manual/implicit for N=1 today — see Notes). The handoff stays stdin-only per sample, as today. `agent-exec.sh` the handoff in, run `gate.sh` in it, record pass/fail. Emit a manifest on stdout listing the gate-passing sample branches (empty if none).
  - `adopt <slug> <sample-branch>`: point `wt/<slug>` at the named sample (`git branch -f` + `worktree add`), then remove **every** `<slug>-fan-*` worktree and delete **all** `<slug>-fan-*` branches — the adopted one included, since its commit now also lives on `wt/<slug>`. Leaves only the canonical `wt/<slug>` that `/3-review` and `release.sh` already expect. Works for any sample, winner or fallback (see 0-survivor path).
- **`skills/2-implement/SKILL.md`** — read `implementer.fan`. `N=1` → the existing steps, unchanged. `N>1` → **skip step 1** (`worktree.sh add <slug>`): the canonical `wt/<slug>` must NOT exist yet, because `adopt` creates it via `git branch -f` + `worktree add`, and `git branch -f` errors on a branch already checked out in a worktree. Run `fan-exec dispatch`; then on the manifest: **0 survivors** → `fan-exec adopt <slug>-fan-1` (the gate is binary, so there is no meaningful "least-broken" ranking — adopt the deterministic first sample), then run the **existing** followup loop (`prompts/followup.tpl`, up to `max_retries`) in the now-canonical `wt/<slug>` exactly as single-agent does, escalating after retries; **1 survivor** → `fan-exec adopt` it; **≥2 survivors** → spawn a fresh `fan-selector` to rank, then adopt the winner. All paths converge on a populated `wt/<slug>`; continue to step 6 / `/3-review` as today.
- **`.claude/agents/fan-selector.md`** (new) — read-only (Read/Grep/Glob/Bash), separate model. Receives the N surviving diffs + the plan; returns a ranking and the single winner branch by plan-fit and simplicity; never edits. Distinct from `code-reviewer` (different output contract: rank, not APPROVE/REQUEST CHANGES) and, critically, a **different fresh thread** from the `/3-review` reviewer — selection must not anchor the approver.
- **`tests/test-scripts.sh`** — hermetic fan-exec coverage using a **canned implementer command** (set `implementer.command` to a script that writes a deterministic diff — no real Claude call): dispatch creates N worktrees and the manifest lists only gate-passers; adopt repoints `wt/<slug>` to a named winner and removes the losing worktrees/branches. Keep all existing checks passing.

Alternatives rejected: (a) a new numbered stage — fan is a mode of implement, not a new loop step; (b) "first gate-passer wins" — discards the whole point of *selecting* the best; (c) reusing `code-reviewer` for ranking — wrong output contract and risks anchoring the /3-review approver; (d) orchestrator-driven manual fan-out (no script/agent/config/test) — lighter and matches "thin by design," but can't run unattended and leaves selection to ad hoc judgment; Owner chose the scripted primitive for reusability and testability.

## Footprint

Files to modify:
- `config.yaml` — `implementer.fan: 1` (and, for house-style consistency with the documented `models:` block, a `models.fan_selector` line — agent frontmatter stays authoritative)
- `skills/2-implement/SKILL.md` — the N>1 branch; N=1 text unchanged
- `tests/test-scripts.sh` — hermetic fan-exec cases

Files to add:
- `scripts/fan-exec.sh`
- `.claude/agents/fan-selector.md`

Files NOT to touch:
- `scripts/agent-exec.sh`, `scripts/worktree.sh` — reused as-is (suffixed slugs already produce `wt/<slug>-fan-k`); preserve their git-only / naive-awk conventions.
- `scripts/release.sh`, `skills/3-review/SKILL.md` — downstream consumes the canonical `wt/<slug>` unchanged.
- `ARCHI.md` — regenerated by `/compact`, not here.

## Acceptance criteria

- [ ] `config.yaml` has `implementer.fan: 1`, commented as N (default preserves single-agent).
- [ ] `scripts/fan-exec.sh dispatch <slug> <handoff> <N>` spawns N worktrees via `worktree.sh`, seeds `work/<slug>/` into each, runs `agent-exec.sh` + `gate.sh` per sample, and prints a manifest containing exactly the gate-passing sample branches.
- [ ] `scripts/fan-exec.sh adopt <slug> <sample-branch>` leaves `wt/<slug>` at that sample and removes **all** `<slug>-fan-*` worktrees and branches (the adopted one included, after retargeting). Passes `shellcheck`; uses `set -uo pipefail`.
- [ ] `skills/2-implement/SKILL.md`: the N=1 path is textually unchanged; N>1 documents dispatch → survivor handling → adopt → `/3-review`, with selection by a fresh `fan-selector` explicitly distinct from the `/3-review` reviewer. The **0-survivor** path is spelled out: adopt `<slug>-fan-1`, then the existing followup loop up to `max_retries`, escalate after.
- [ ] `.claude/agents/fan-selector.md` declares read-only tools and a separate model, ranks N diffs against the plan, and outputs one winner branch; it never edits.
- [ ] `tests/test-scripts.sh` proves, hermetically (canned implementer, no real Claude): manifest = gate-passers only, and adopt repoints + cleans up; existing self/platform-team/worktree checks still pass; `bash scripts/gate.sh` exits 0.

## Notes

- **Seeding mechanizes a currently-manual step.** For N=1 today, the work-unit dir reaches the worktree via the orchestrator's own file ops, not any script (git history: `work/work-profile/plan.md` first appears in the same commit as its implementation). `handoff.tpl` tells the implementer to read `work/<slug>/plan.md` from disk, so `dispatch` must copy the whole `work/<slug>/` dir into each sample worktree; the handoff itself stays stdin-only per sample. The N=1 path's reliance on manual seeding is a pre-existing latent gap, out of scope here — candidate follow-up.
- **Cost & diversity caveats** (why it's opt-in): N>1 is N× implementer tokens at Claude rates; the payoff depends on the N samples actually diverging. Identical samples waste the spend. Temperature/prompt-nudge to force divergence is future, not this unit.
- **Test effort is non-trivial.** The hermetic fan-exec fixture is comparable in size to the existing ~150-line release fixture (`tests/test-scripts.sh:60-150`): a throwaway repo with a stubbed `config.yaml` (`implementer.command` → a canned diff-writer), a `gate.sh` the stub can pass or fail on demand, multiple worktrees, and manifest/adopt assertions. Sized deliberately, not a drive-by addition.

## Release

Release note: Add opt-in best-of-N implement mode (`implementer.fan`) — N Claude samples in isolated worktrees, gate-filtered, winner picked by a fresh selector; default N=1 unchanged.

## Verification

- `bash scripts/gate.sh` — green (shellcheck over `fan-exec.sh` + the hermetic smoke cases).
- Fan mode itself is exercised only with the canned implementer; a real N>1 Claude run is validated in live use, not the gate (same residual-risk posture as `bitbucket-pipelines.yml`).
- `/compact` before any `/4-release` (config.yaml + scripts/ + skills/ touched).

## Review

**Round 1 (plan-reviewer, REVISE):**
- *Goal oversold — doesn't close the correlated-validator risk* — agreed; Goal reframed to "reduces per-run variance, does NOT close same-vendor risk," with a note not to let release/PLAN bookkeeping imply otherwise.
- *0-survivor path underspecified* — agreed; `adopt` now takes any sample; 0-survivors adopts `-fan-1` and runs the existing followup loop (gate is binary, so no "least-broken" ranking).
- *Dangling "see Risks"; seeding mechanizes a manual step* — agreed; added a Notes section; the whole `work/<slug>/` dir is seeded, handoff stays stdin-only; the N=1 manual-seeding gap noted as out-of-scope.
- *adopt left the winner's own branch orphaned* — agreed; adopt now deletes all `-fan-*` branches including the adopted one after retargeting.
- *Test effort understated* — agreed; Notes sizes it against the ~150-line release fixture.
- *Simpler orchestrator-driven alternative* — Owner chose the scripted path (reusable/testable/unattended-capable) over the manual version; recorded here as the arbitrated decision.

**Round 2 (plan-reviewer, APPROVE):** two implementation-time notes folded in — (a) N>1 skips step 1 so `wt/<slug>` doesn't exist when `adopt`'s `git branch -f` runs (force-update errors on a checked-out branch); (b) dispatch is intentionally sequential — dropped the "parallel" implication and noted N× wall-clock. Cosmetic `models.fan_selector` doc line added to the config footprint so it isn't treated as creep.

Plan verdict: APPROVE

**Code-review (post-implementation):** 5 rounds, all fresh code-reviewer threads (sonnet, cold, read-only).
- R1 REVISE → empty-array `${passers[@]}` crash on 0-survivor path under bash 3.2 `set -u`; loud seeding; 0-survivor test gap.
- R2 REVISE → adopt lost uncommitted implementer work (`git branch -f` moves to last commit only; dirty `worktree remove` aborts). Fix: dispatch auto-commits samples.
- R3 REVISE → gate ran *before* the auto-commit, so `git ls-files`-based shellcheck missed uncommitted new `.sh`. Fix: commit-before-gate.
- R4 REVISE → adopt `worktree remove` lacked `--force` (gate writes untracked artifacts post-commit) and aborted cleanup on first failure; seeded `work/<slug>/` swept into adopted diff. Owner authorized rounds 4 and 5 past the 3-round ceiling.
- R5 **APPROVE** — 26/26 gate, 6 new hermetic fan-exec cases. Non-blocking: no locked-worktree-failure test; no mid-dispatch partial-failure rollback (both house-convention-consistent).

Code-review verdict: APPROVE
