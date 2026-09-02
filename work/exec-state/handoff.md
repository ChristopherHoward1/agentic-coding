You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.

Work unit: work/exec-state/plan.md  (read it in full; it is your source of truth)
Branch: wt/exec-state (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

## What to build

A new deterministic script `scripts/state.sh` — a **pure, read-only deriver** of one work unit's execution state. Given a slug, it observes repo facts and prints a flat `key: value` block. It writes nothing, mutates nothing, and runs no side-effecting commands. A cold session runs `scripts/state.sh <slug>` and learns the unit's stage and next legal action without any prior conversation.

Study the existing scripts for house style before writing: `scripts/codex-review.sh` (how it reads the branch plan via `git show wt/<slug>:...`, `git rev-parse --show-toplevel`, `die` helpers, naive-awk parsing), `scripts/release.sh` (`check_verdict` greps exact sentinel lines), `scripts/worktree.sh`. Match `set -uo pipefail`, error-to-stderr, and the exit-code discipline. All shell must pass `shellcheck` (the gate enforces it).

## Footprint (hard boundary)

Files to modify:
- `scripts/state.sh` (new — the deriver)
- `tests/test-scripts.sh` (add hermetic cases)

Do NOT touch: `scripts/gate.sh`, `scripts/release.sh`, `scripts/codex-review.sh`, `scripts/worktree.sh`, any `.claude/skills/*`, `ARCHI.md`, `PLAN.md`. If you believe the footprint is wrong, stop and report it — do not expand scope.

## Behavior spec

`scripts/state.sh <slug>` (single subcommand; `<slug>` required, else usage error non-zero).

`cd` to repo root (`git rev-parse --show-toplevel`) like the other scripts. Then derive, from these deterministic inputs only:

- Artifact presence under `work/<slug>/`: `plan.md`, `handoff.md`, `codex-review.md`, `retro.md`.
- Verdict sentinels — the EXACT lines (whole-line match, like `release.sh`'s `grep -qx`):
  - `Plan verdict: APPROVE`
  - `Code-review verdict: APPROVE`
  - `Codex-review verdict: APPROVE`
  Read these from the **branch** plan when the branch exists: if `git rev-parse --verify --quiet wt/<slug>` succeeds, read via `git show wt/<slug>:work/<slug>/plan.md`; otherwise read the primary-checkout file `work/<slug>/plan.md`. (This differs deliberately from the other scripts — do not try to reuse their exact read path.)
- `git rev-parse --verify --quiet wt/<slug>` — does the branch exist.
- The `work/.last-released` marker: a single line; it "names this slug" iff its trimmed content equals `<slug>`.

Output — flat lines, exactly these keys, grep/awk-readable (no JSON, no `jq`):
```
slug: <slug>
stage: <plan|implement|review|release|done>
review: <pending|approve>
next_action: <string>
```

`review` = `approve` iff BOTH `Code-review verdict: APPROVE` and `Codex-review verdict: APPROVE` are present in the resolved plan; else `pending`. (This two-sentinel AND is the guard to mutation-pin — see tests.)

Stage derivation, FIRST MATCH WINS:
1. `work/<slug>/plan.md` does not exist (in the primary checkout) → print nothing to stdout, write `state: not a work unit: <slug>` (or similar) to stderr, exit non-zero.
2. `Plan verdict: APPROVE` absent → `stage: plan`, `next_action: finish /1-plan`.
3. no `handoff.md` AND no `wt/<slug>` branch → `stage: implement`, `next_action: /2-implement`.
4. otherwise, if `review != approve` → `stage: review`, `next_action: /3-review` — but if `codex-review.md` is absent, `next_action: run scripts/gate.sh`.
5. `review == approve` AND `.last-released` does not name this slug → `stage: release`, `next_action: /4-release`.
6. `.last-released` names this slug AND `retro.md` missing or empty → `stage: release`, `next_action: /5-retro`.
7. `.last-released` names this slug AND `retro.md` non-empty → `stage: done`, `next_action: none`.

Note rule 1 checks the primary-checkout `work/<slug>/plan.md` for existence; rules 2+ read the sentinel from the branch-or-local resolved plan as described above.

Gate result is intentionally NOT derived or persisted — never run `scripts/gate.sh` from `state.sh`, never record a gate outcome.

## Tests (tests/test-scripts.sh)

Add a hermetic block using the existing `check` / `check_fails` / `check_exit` helpers. Build fixtures in a temp dir with their own throwaway git repo + `work/<slug>/` tree so no case depends on this repo's live state. Cover:

- One fixture per stage rule (7 total) asserting the derived `stage:` and `next_action:` lines (e.g. pipe stdout to `grep -qx 'stage: implement'`).
- Branch-vs-local sentinel read: a fixture where the `wt/<slug>` branch plan has both APPROVE sentinels but the primary-checkout plan does NOT → derives `review: approve`. This proves the `git show` path is used.
- Read-only: after running `state.sh` over a fixture, `git status --porcelain` is empty and no new files appeared.
- Missing `plan.md` → non-zero exit with the expected stderr substring (`check_exit`).
- **Mutation-pin (required, per `knowledge/silent-no-op-hazards.md`):** structure the two-sentinel `review == approve` test so that if the AND were an OR (single sentinel counted as approve), a fixture with only ONE sentinel would wrongly derive `approve` and the test would FAIL. Before you finish, temporarily apply that mutation, run the suite, confirm the new test goes red, then revert — and say in your summary that you did this and it landed.

## When done

1. Run `scripts/gate.sh` from the repo root — it must pass (shellcheck + full suite green).
2. Commit your work on `wt/exec-state` with a clear message.
3. Print a final summary: what changed, which acceptance criteria are met, the mutation-pin result (mutation applied → test went red → reverted), and any out-of-scope observations.
