# Implementer notes — gate-tool-preflight

Runtime: codex (`codex exec --sandbox workspace-write`), fan=1, single dispatch, no followup rounds.
Commit: `a42c8d3 Add gate required-tool preflight` on `wt/gate-tool-preflight`.

## Implementer summary (verbatim)

Changed:
- `scripts/gate.sh` now prints `⊘ skipped: <tool> (not installed)` only when the relevant stack marker is present and the tool is missing.
- Added required-tool preflight from `GATE_REQUIRED_TOOLS` overriding `gate.required_tools`, with missing tools reported before any `▶` check lines.
- Declared `gate.required_tools: shellcheck` in `config.yaml`.
- Added hermetic tests for skip visibility, marker-negative cases, pytest's `tests/*` distinction, required-tool pass/fail, multiple missing tools, config absence, config parsing, and env override.
- Updated `profiles/work.md`, `README.md`, and `ARCHI.md`; ARCHI now records `102` checks.

Verification:
- `bash tests/test-scripts.sh` → `passed: 102, failed: 0`
- `bash scripts/gate.sh` → `GATE: PASS`

Mutation requirement:
- Temporarily broke skip output, stack-marker gating, fake-present required-tool handling, missing-required abort, multi-missing reporting, missing-config guarding, env override precedence, and pytest's `tests/*` guard.
- Each mutation made the corresponding new test go red; restored afterward before final verification.

No acceptance criteria were partially met. No out-of-scope changes made.

## Orchestrator verification (independent of the implementer's claim)

Run from the worktree, not taken on report:

| Check | Result |
|---|---|
| `bash scripts/gate.sh; echo $?` | `0` |
| `GATE_REQUIRED_TOOLS=nope-a:nope-b bash scripts/gate.sh; echo $?` | `1` |
| Both missing tools named | yes — `✗ missing required tool: nope-a` / `nope-b` |
| `▶` lines when preflight fails | `0` — aborts before stack checks, as specced |
| Skip lines on this shell-only repo | none — correct, no `package.json`/`Cargo.toml`/`go.mod` markers |
| Suite count | 102, up from 90 (12 new checks) |
| Footprint | exactly the 6 declared files + `plan.md` recorded by `worktree.sh` |

Not independently re-verified: the mutation testing in the implementer's third bullet. It is self-reported. Each mutation's assertion is present in the suite and its fixture is hermetic, but "I broke it and watched it go red" is not reproducible from the diff alone — flagged for the reviewer.
