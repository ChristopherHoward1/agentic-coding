# CI: run the deterministic layer on PRs

**Slug:** ci-workflow · **Date:** 2026-08-15 · **Status:** reviewed — APPROVE, merge-ready (gate PASS, commit 2b5964c)

## Goal

There is no CI. The shell layer (`scripts/gate.sh`, `tests/test-scripts.sh`) is the project's only automated correctness check, and today it only runs when someone remembers to run it locally. Add a GitHub Actions workflow that runs both on every pull request (and pushes to `main`), so regressions in the deterministic layer are caught mechanically. Done looks like: a workflow file that, on a Linux runner with `shellcheck` available, runs `tests/test-scripts.sh` and `scripts/gate.sh` and fails the check if either exits non-zero.

This is also the first dogfood of the full agent loop (see `work/bootstrap-retro.md` §2); the workflow itself is deliberately small so the loop, not the task, is what's under test.

## Approach

A single workflow, `.github/workflows/ci.yml`:

- Triggers: `pull_request` and `push` to `main`.
- One job on `ubuntu-latest`.
- Steps: `actions/checkout@v4`; ensure `shellcheck` is present (`ubuntu-latest` ships it, but `sudo apt-get install -y shellcheck` guards against image drift — cheap insurance; note the `sudo`, the runner user is not root); run `bash tests/test-scripts.sh`; run `bash scripts/gate.sh`.

Two real hazards the implementer must handle, both surfaced by reading the scripts:

1. **Git identity.** `tests/test-scripts.sh` does `git init` + `git commit` in a throwaway repo. CI runners have no global git identity, so the commit fails and the suite errors out before testing anything. The workflow must set `user.name`/`user.email` (via `git config --global` in a step, or `GIT_AUTHOR_*`/`GIT_COMMITTER_*` env). Prefer the `git config --global` step — explicit and visible in logs.
2. **`gate.sh` runs `tests/test-scripts.sh`'s work twice-ish but that's fine.** Running the smoke suite *and* the gate is intentional redundancy (belt+braces, matching the suite's own comment); keep both.

Order: run `test-scripts.sh` first (broader), then `gate.sh`. Don't `set -e` around them in a way that hides which failed — each `run:` step failing is enough for GitHub to mark the job red and show which step.

Alternative considered: fold everything into one `run:` block. Rejected — separate steps give clearer failure attribution in the Actions UI.

Note: the repo currently has **no git remote**, so this workflow will not actually execute until a GitHub remote is added and a PR opened. The file is still a complete, reviewable artifact; the plan does not include creating a remote (Owner's call).

## Footprint

Files to modify:
- `.github/workflows/ci.yml` (new)

Files NOT to touch:
- `scripts/*.sh`, `tests/test-scripts.sh` — the workflow adapts to the scripts, not the reverse. If a script genuinely needs a CI-friendliness change (e.g. git identity), that is a separate work unit; the git-identity fix belongs in the workflow, not the test.

## Acceptance criteria

- [ ] `.github/workflows/ci.yml` exists and is valid YAML (`bash -c 'python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" .github/workflows/ci.yml'` or equivalent parses without error).
- [ ] Workflow triggers on both `pull_request` and `push` to `main` (verifiable by diff inspection of the `on:` block).
- [ ] Job runs, in order: checkout, shellcheck-availability, `bash tests/test-scripts.sh`, `bash scripts/gate.sh` (verifiable by diff inspection).
- [ ] The workflow sets a git identity before the smoke suite runs (verifiable by diff inspection — a `git config --global user.email/user.name` step or equivalent env).
- [ ] `scripts/gate.sh` still passes locally after the change (shellcheck over tracked `*.sh`; the new file is YAML, not shell, so no new shellcheck surface — confirm gate stays green).
- [ ] `bash tests/test-scripts.sh` still passes locally (8/8).

## Verification

- `bash scripts/gate.sh` → `GATE: PASS`
- `bash tests/test-scripts.sh` → `passed: 8, failed: 0`
- YAML parse of the workflow file (command above).
- Optional, if the Owner wants live confirmation: `act` (nektos/act) to run the workflow locally — not required for merge, and not assumed installed.

## Review

**Verdict: APPROVE** (plan-reviewer, fresh subagent, 2026-08-15). All codebase claims verified against the scripts: git-identity hazard confirmed real (`tests/test-scripts.sh:36-40`), gate adds no new shellcheck surface for a `.yml` file (`gate.sh:39-42`), gate.sh-run redundancy is intentional, all six acceptance criteria checkable. No plan revisions required.

Non-blocking findings carried to the implementer handoff:
1. `apt-get install -y shellcheck` on `ubuntu-latest` needs `sudo` (default user is `runner`, not root). One-line note so it isn't a wasted review round.
2. The YAML `safe_load` check proves syntax only, not GitHub Actions schema validity — accepted, disclosed limitation (workflow can't execute pre-remote anyway).
3. Nothing meaningful left to cut; already the minimal version.

### Code review (/3-review)

**Verdict: APPROVE** (code-reviewer, fresh subagent, cold context, read-only). All six acceptance criteria met and independently confirmed: valid YAML, both triggers present, correct step order, git-identity set before the smoke suite, gate stays `PASS`, smoke suite 8/8. Footprint honest — one file, no script changes. CI-correctness checks passed: `sudo apt-get` correct for the `runner` user, shallow checkout sufficient (`git rev-parse`/`git ls-files` don't need history), default read-only permissions fine, git-identity fix placed correctly before `git commit` in the sandbox. No blocking findings. Only open caveat is the disclosed, accepted one: the workflow can't actually execute until the repo has a GitHub remote.
