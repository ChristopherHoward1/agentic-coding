You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.

Branch: wt/ci-workflow (already checked out in this worktree — verify with `git branch --show-current` before changing anything).

NOTE: the work-unit plan file is not present in this worktree, so the full plan is embedded below. It is your source of truth — read it in full.

================ PLAN (embedded) ================

# CI: run the deterministic layer on PRs

## Goal

There is no CI. The shell layer (`scripts/gate.sh`, `tests/test-scripts.sh`) is the project's only automated correctness check, and today it only runs when someone remembers to run it locally. Add a GitHub Actions workflow that runs both on every pull request (and pushes to `main`), so regressions in the deterministic layer are caught mechanically. Done looks like: a workflow file that, on a Linux runner with `shellcheck` available, runs `tests/test-scripts.sh` and `scripts/gate.sh` and fails the check if either exits non-zero.

## Approach

A single workflow, `.github/workflows/ci.yml`:

- Triggers: `pull_request` and `push` to `main`.
- One job on `ubuntu-latest`.
- Steps, in order:
  1. `actions/checkout@v4`
  2. Ensure `shellcheck` is present. `ubuntu-latest` ships it, but `sudo apt-get update && sudo apt-get install -y shellcheck` guards against image drift. NOTE the `sudo` — the runner user is `runner`, not root; `apt-get` without sudo will fail.
  3. Set a git identity (see hazard #1 below) — MUST come before running the smoke suite.
  4. `bash tests/test-scripts.sh`
  5. `bash scripts/gate.sh`

Use separate `run:` steps (not one folded block) so a failure shows which step broke in the Actions UI.

Two real hazards, both surfaced by reading the scripts:

1. **Git identity.** `tests/test-scripts.sh` does `git init` + `git commit` in a throwaway repo (see `tests/test-scripts.sh` lines ~36-40: `git init -q -b main`, `git commit -q --allow-empty -m init`, `git commit -qm files`). CI runners have no global git identity, so those commits fail and the suite errors out before testing anything. The workflow MUST set `user.name`/`user.email` before the suite runs. Use a `git config --global user.email "ci@example.com" && git config --global user.name "CI"` step — explicit and visible in logs. Do NOT fix this by editing the test script; the fix belongs in the workflow.

2. **Intentional redundancy.** `tests/test-scripts.sh` already invokes `scripts/gate.sh` as its last check. Running `gate.sh` again as its own workflow step is deliberate belt-and-braces — keep both steps.

================ FOOTPRINT (hard boundary) ================

Files to modify:
- `.github/workflows/ci.yml` (new — create it)

Files NOT to touch:
- `scripts/*.sh`, `tests/test-scripts.sh`. The workflow adapts to the scripts, not the reverse. The git-identity fix goes in the workflow, never in the test. If you believe a script genuinely must change, STOP and report it as an out-of-scope observation — do not edit it.

================ ACCEPTANCE CRITERIA ================

- `.github/workflows/ci.yml` exists and is valid YAML.
- Workflow triggers on both `pull_request` and `push` to `main`.
- Job runs, in order: checkout, shellcheck-availability, git-identity, `bash tests/test-scripts.sh`, `bash scripts/gate.sh`.
- A git identity is set before the smoke suite runs.
- `scripts/gate.sh` still passes locally (the new file is YAML, not shell, so it adds no shellcheck surface — confirm the gate stays green).
- `bash tests/test-scripts.sh` still passes locally (8/8).

================ KEY CONSTRAINTS ================

- All shell scripts in this repo must pass `shellcheck` (the gate enforces it). You are adding YAML, not shell, so no new shellcheck surface — but do not break the existing gate.
- Match surrounding style; keep the workflow minimal (no extra jobs, matrices, caches, or actions beyond what the plan calls for).

================ WHEN DONE ================

1. Run `scripts/gate.sh` from the repo root — it must pass (exit 0, `GATE: PASS`).
2. Also run `bash tests/test-scripts.sh` and confirm 8/8 (sanity — this is what CI will run).
3. Commit your work on the `wt/ci-workflow` branch with a clear message.
4. Print a final summary: what changed and why, which acceptance criteria are met, and any out-of-scope observations.
