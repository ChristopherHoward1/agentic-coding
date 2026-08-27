You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.

Work unit: work/gate-tool-preflight/plan.md  (read it in full; it is your source of truth)
Branch: wt/gate-tool-preflight (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
- scripts/gate.sh — skip lines on each `command -v` guard; required-tools preflight
- config.yaml — add `required_tools: shellcheck` under the existing `gate:` block
- tests/test-scripts.sh — hermetic cases for both behaviors
- profiles/work.md — document the knob
- README.md — one clause in the Requirements section (~line 134) listing gate tool prerequisites
- ARCHI.md — Stack line, Layout `config.yaml` line, Conventions YAML-parsing line (add `gate.sh` to the naive-awk list), Verification check count

Do NOT touch: scripts/gate.d/examples/*, scripts/release.sh, scripts/agent-exec.sh.

Key constraints:

1. TWO behaviors, both in scripts/gate.sh.

   (a) VISIBILITY, always on, no configuration. Every `command -v` guard that
       declines to run a check prints one line:
           ⊘ skipped: <tool> (not installed)
       Exit codes are unchanged by this half. Critically, the skip line must fire
       only when the STACK IS PRESENT AND THE TOOL IS MISSING. A shell-only repo
       must NOT report skipping cargo/go/node. This means restructuring the
       combined guards at gate.sh:21 (`[[ -f package.json ]] && command -v node`),
       :46 (`[[ -f Cargo.toml ]] && command -v cargo`), and :47 (`go.mod` / `go`)
       so the stack-marker test and the tool test are separable. Note pytest is
       additionally conditioned on `compgen -G "tests/*"` — a repo with no tests/
       directory is not "skipping pytest", so keep that distinction.

   (b) ENFORCEMENT via a declared list. Source order:
           GATE_REQUIRED_TOOLS (env var)  overrides  gate.required_tools (config.yaml)
       Format is a colon-separated scalar, e.g. `shellcheck:ruff` — the same shape
       as the existing DS_DATA_ALLOW_DIRS in scripts/gate.d/examples/ds-hygiene.sh.
       Parse config.yaml with the naive awk idiom already used in scripts/worktree.sh:13.
       This exact command is verified to work:
           awk '/^gate:/{f=1;next} f&&/required_tools:/{print $2; exit}' config.yaml
       Absent config.yaml, or an absent key, must parse to EMPTY so gate.sh still
       runs standalone in a repo that has no config.yaml. Do not let a missing
       config.yaml produce an awk error on stderr.

2. PREFLIGHT SEMANTICS: a missing required tool ABORTS BEFORE any stack check runs.
   Print every missing tool (not just the first), exit non-zero, and emit NO `▶`
   lines at all. "No `▶` lines in the output" is the tested observable.

3. Declare it in this repo: add `required_tools: shellcheck` under `gate:` in
   config.yaml. The gate must still pass here.

4. TEST HAZARD — read carefully. tests/test-scripts.sh runs `bash scripts/gate.sh`
   on this repo, and the suite itself runs as the scripts/gate.d/test-scripts.sh
   hook (recursion-guarded by TEST_SCRIPTS_RUNNING). Any new test that EXPORTS
   GATE_REQUIRED_TOOLS will leak into that nested invocation and poison the rest
   of the suite. Set it PER-COMMAND only (`GATE_REQUIRED_TOOLS=x bash ...`), never
   `export`. Build hermetic fixture repos in a temp dir, as the existing nb-clean
   and ds-hygiene cases do (see tests/test-scripts.sh around lines 660-760 for the
   established pattern).

5. MUTATION REQUIREMENT (PLAN.md decision, 2026-08-27): a test asserting a guard
   exists is not done until you have SHOWN IT FAILS with that guard removed. For
   each new case, temporarily break the corresponding gate.sh behavior, confirm
   the new test goes red, then restore. State in your summary that you did this
   and what you observed. A green suite cannot distinguish a real case from a
   vacuous one.

6. ARCHI.md's Verification line currently claims 90 checks. `bash tests/test-scripts.sh`
   currently prints `passed: 90, failed: 0`. Update that number to whatever the
   suite actually reports when you are done — release.sh checks ARCHI freshness,
   and the count is a release-checked artifact.

7. All shell must pass shellcheck with `set -uo pipefail` (gate.sh's existing
   style — note gate.sh deliberately does NOT use `set -e`, since it accumulates
   failures in `fail`). Match the surrounding style; the `run()` helper and the
   ▶ / ✗ output vocabulary already exist — reuse them rather than inventing new ones.

Acceptance criteria are listed in full in the plan. Every one must be checkable by
a command; the plan's list is the definition of done.

When done:
1. Run scripts/gate.sh from the repo root — it must pass.
2. Commit your work on this branch with a clear message.
3. Print a final summary: what changed and why, criteria partially met (if any), out-of-scope observations.
