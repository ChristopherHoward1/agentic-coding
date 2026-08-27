Round-2 review findings on work/gate-tool-preflight/plan.md. You are resuming in the same worktree on branch wt/gate-tool-preflight.

The design is settled — do not redesign. Two blocking defects, both in the test layer, plus two cheap cleanups. This is the final review round before the unit escalates to the Owner, so read finding 2 carefully: it is an acceptance-criterion violation, not a style note.

## Finding 1 (blocking) — an inherited `GATE_REQUIRED_TOOLS` turns a healthy gate red

The plan's hazard note covers only the outbound direction ("never `export` it"), and your tests honour that. The **inbound** direction is unguarded. `scripts/gate.sh:21` reads the variable from the environment, so a prefix assignment on the gate exports it into the process, into the `gate.d/test-scripts.sh` hook, and into every fixture invocation that deliberately leaves it unset. Reproduced on the real gate just now:

```
$ GATE_REQUIRED_TOOLS=shellcheck bash scripts/gate.sh
FAIL: gate reports skipped node when package.json exists and node is missing
FAIL: gate reports skipped lines for every missing guarded tool
FAIL: gate does not report skipped pytest when no tests match
FAIL: gate does not report skipped node when node check runs
FAIL: gate runs without config.yaml or GATE_REQUIRED_TOOLS
FAIL: gate reads required_tools from config.yaml
FAIL: gate ignores commented-out required_tools
FAIL: gate ignores required_tools outside gate section
passed: 97, failed: 8
```

Nothing is genuinely broken — the fixtures' restricted `PATH` lacks `shellcheck`, so the inherited requirement aborts each fixture's gate before it can print skip lines or read its own `config.yaml`. But this is the very knob the unit ships, the plan's own Verification section demonstrates that invocation form, and a green gate that flips red on an unrelated environment variable is exactly the trust erosion this unit exists to fix.

Fix: neutralise the inherited value for the fixture invocations — `env -u GATE_REQUIRED_TOOLS` on the affected checks (`tests/test-scripts.sh:739,758,767,776` and the five skip-visibility checks), or a single `unset GATE_REQUIRED_TOOLS` at the top of the gate test block before line 666. Prefer whichever keeps the block readable.

Add a regression test: the suite must pass when invoked with `GATE_REQUIRED_TOOLS` set in the environment to a tool the fixtures lack.

## Finding 2 (blocking) — a vacuous test; the mutation-testing acceptance criterion is unmet for it

`tests/test-scripts.sh:736`, "preflight aborts before stack checks". The reviewer replaced the preflight's `exit 1` with `fail=1` — so the preflight no longer aborts and every stack check runs — and **all 15 gate checks still passed**.

The cause: the `gate-required-no-run-lines` fixture (`tests/test-scripts.sh:729`) contains only `package.json` plus the copied `scripts/gate.sh`, with a `PATH` holding just bash, git, and awk. No implementation of `gate.sh` can emit a `▶` line there, abort or not, so `! grep -Fq '▶'` can never fail.

The behaviour itself is correct — that is not in question. The problem is that the plan's ACs on abort semantics and on mutation-tested assertions are both unverified, and per the 2026-08-27 decision in `PLAN.md`, an assertion that cannot fail is not a test.

Fix: give the fixture a runnable tool so a non-aborting implementation *would* print a `▶` line — e.g. `write_fake_tool "$GATE_BIN/node"` plus `npm`, as `gate-node-runs` already does, which would emit `▶ npm run --silent lint`. Then confirm by mutation: replace the preflight `exit 1` with `fail=1`, watch this test go red, restore.

Your other new assertions were independently confirmed non-vacuous by the reviewer, so no other test needs this treatment.

## Cheap cleanups (do them while you are here)

- The literal `"GATE: FAIL — fix everything marked ✗ above."` now appears twice in `scripts/gate.sh` (:59 and :134). Extract a one-line helper so the two cannot drift.
- `tests/test-scripts.sh:223` hardcodes `/bin/bash` while adjacent lines resolve `git` and `awk` via `command -v`. Make it consistent.

## Deliberately out of scope — do not fix

Two minor parser boundaries the reviewer raised and judged non-blocking: a `required_tools` nested at any depth inside `gate:` is matched, and duplicate keys take the first where YAML takes the last. Both are contrived shapes. Leave the code alone; instead make ARCHI's naive-awk convention line honest that the parser is section-scoped rather than depth-aware, in one clause.

Also leave alone: a missing/erroring `awk` silently disabling enforcement. Real but low-probability given awk is POSIX-guaranteed, and guarding it cleanly is not a one-liner.

## Constraints (unchanged)

- Tests set `GATE_REQUIRED_TOOLS` per-command, never `export`.
- Mutation requirement applies to both new/changed tests: break the behaviour, confirm red, restore, report what you observed.
- Update ARCHI's check count to whatever the suite reports (currently 105).

## When done

1. `bash scripts/gate.sh` from the repo root — must pass.
2. `GATE_REQUIRED_TOOLS=shellcheck bash scripts/gate.sh` — must also pass, that is finding 1.
3. Commit on this branch.
4. Print a summary: what changed, what you observed during mutation checks, anything still open.
