Review findings on your implementation of work/gate-tool-preflight/plan.md. You are resuming in the same worktree on branch wt/gate-tool-preflight.

Both reviewers returned APPROVE, so the design is accepted — do not redesign anything. Three defects were found in the parsing and exit paths. Fix all three, stay inside the plan's existing footprint (`scripts/gate.sh`, `tests/test-scripts.sh`, and ARCHI's check count), and add a regression test for each of the first two.

## Finding 1 (blocking) — a commented-out knob bricks the gate

`scripts/gate.sh:22`. The awk pattern `f&&/required_tools:/` is unanchored, so a commented line matches and `$2` becomes the literal string `required_tools:`. Reproduced by the reviewer:

```
config.yaml containing:  gate:\n  command: scripts/gate.sh\n  # required_tools: shellcheck
output:                  ✗ missing required tool: required_tools     rc=1
```

Commenting out a knob is the obvious way a user disables it, and this turns "no requirement" into "require a tool that can never exist" — the gate is unfixable-red until they find the comment. The same unanchored pattern also mis-parses a quoted value (`required_tools: "shellcheck"` fails on the literal `"shellcheck"`) and will honour a `required_tools:` line under an unrelated later section, because `f` is never reset.

Anchor the pattern — `f&&/^[[:space:]]*required_tools:/` fixes the commented case, which is the likely one. Decide deliberately whether to also reset `f` when a new top-level key begins, and whether to strip surrounding quotes; if you judge either out of scope, say so in your summary rather than silently leaving it.

Tests: a commented-out `required_tools` line must leave the gate green; a `required_tools:` line under a different top-level section must not be honoured.

## Finding 2 (blocking) — `GATE_REQUIRED_TOOLS=` (empty) does not override

`scripts/gate.sh:20-21`. The guard is `-z "$required_tools"`, so an explicitly-empty env var is indistinguishable from an unset one and falls through to the config value. This is exactly the machine in the plan's Goal: on a SageMaker box that lost `shellcheck` after a restart, an operator wanting one diagnostic run without the requirement types `GATE_REQUIRED_TOOLS= bash scripts/gate.sh` and still gets a hard failure, with `GATE_REQUIRED_TOOLS=:` as the only non-obvious escape hatch.

The plan says the env var "overrides" the config value; make an explicitly-set-but-empty value override to "no required tools". Use presence rather than emptiness to decide — `${GATE_REQUIRED_TOOLS+set}` distinguishes the two.

Test: with `required_tools: shellcheck` in config and a `PATH` lacking shellcheck, `GATE_REQUIRED_TOOLS= bash scripts/gate.sh` must not fail on a missing required tool.

## Finding 3 (non-blocking, fix while you are here) — preflight abort prints no `GATE:` line

`scripts/gate.sh:40` exits 1 straight from the loop, while every other exit path prints `GATE: PASS` or `GATE: FAIL — fix everything marked ✗ above.`. Nothing greps for the string today, so this breaks nothing — but the failure text fed back to an implementer is a bare `✗` line with no terminator, in the one output surface this unit exists to make more legible. Emit the standard `GATE: FAIL` line before the preflight's `exit 1`.

## Constraints (unchanged)

- Set `GATE_REQUIRED_TOOLS` **per-command** in tests, never `export` — the suite runs nested inside `scripts/gate.sh` via the `gate.d/test-scripts.sh` hook.
- Mutation requirement still applies: for each new test, break the corresponding behavior, confirm the test goes red, restore. Report what you observed.
- Update ARCHI.md's check count to whatever the suite reports when you are done (currently 102).

## When done

1. `bash scripts/gate.sh` from the repo root — it must pass.
2. Commit on this branch.
3. Print a summary: what changed, what you judged out of scope and why, anything still open.
