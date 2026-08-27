# tests/test-scripts.sh — helper contract

Cited when writing or reviewing cases in `tests/test-scripts.sh`. Not hot context.

Written after `ds-hygiene-hook` (v2026.8.9) re-derived this three times — once while
planning, twice under code review — at roughly a review round each.

## What each helper actually asserts

| Helper | Exit code | stdout | stderr |
|---|---|---|---|
| `check` | must be 0 | discarded | discarded |
| `check_fails` | must be non-zero | discarded | discarded |
| `check_exit <desc> <code> <substr>` | must equal `<code>` | discarded | grepped for `<substr>` |

Three consequences that have each cost a round:

1. **A script under test must write diagnostics to stderr** if a case wants to assert the
   message. `check_exit` greps stderr only. `gate.sh` captures both streams, so writing to
   stderr costs nothing in implementer feedback.
2. **There is no absence assertion.** `check_exit` proves a substring is present, never that
   one is missing. Asserting "X is not flagged" needs an inline `bash -c`:

       check "desc" bash -c 'out=$(bash hook 2>&1); ! grep -q needle <<<"$out"'

3. **There is no emptiness assertion, and `$(...)` discards exit status.** This shape is a
   trap — it passes for a command that exits 1 silently:

       check "desc" bash -c '[ -z "$(cmd 2>&1 >/dev/null)" ]'          # status ignored

   Capture both when the criterion names both:

       check "desc" bash -c 'err=$(cmd 2>&1 >/dev/null); s=$?; [[ $s -eq 0 && -z "$err" ]]'

## A green suite is not a real suite

Every vacuous test found in this repo has passed the gate. The gate cannot distinguish a
test that proves something from one that cannot fail.

Before trusting a case that asserts a guard exists, delete the guard and re-run. If the
suite stays green, the case is decoration. Three cases in `ds-hygiene-hook` failed this and
were caught only by reviewers doing it by hand.

Common vacuity: a fixture that violates two checks at once, asserted with a single non-zero
exit. The assertion cannot tell which check fired, so it survives the deletion of either.
Give each guard a fixture that violates **only** the thing that guard controls.

A second vacuity shape, from `gate-tool-preflight` (v2026.8.10): a fixture too impoverished to
exhibit the behaviour at all. The case asserted the gate's preflight aborts *before* running
checks, by grepping for absence of the `▶` run marker — but the fixture had no runnable tool,
so no implementation could ever print one. Deleting the abort left the suite green. When
asserting that something does **not** appear, first confirm the fixture can produce it.

## The suite runs *inside* the gate, so environment hermeticity is bidirectional

`scripts/gate.d/test-scripts.sh` runs this suite as a gate hook, so `bash scripts/gate.sh`
executes the suite, which executes fixture gates. Any variable `gate.sh` reads therefore
flows in both directions, and both cost a review round in `gate-tool-preflight`:

- **Outbound:** a case that `export`s such a variable leaks it into the nested gate run and
  into every later case. Set it per-command instead — `VAR=x bash -c '…'`.
- **Inbound:** a value already in the environment reaches the hook and then every fixture.
  `GATE_REQUIRED_TOOLS=shellcheck bash scripts/gate.sh` failed 8 of 15 new cases this way —
  nothing was broken; the inherited requirement aborted each fixture gate before it could
  run, because fixtures deliberately use a restricted `PATH`.

Neutralise the inbound direction once, structurally, next to the suite's `cd "$ROOT"` rather
than immediately above the affected block — a guard that works only because of where it sits
is silently lost by the next case added above it:

    unset GATE_REQUIRED_TOOLS   # the suite runs nested inside gate.sh; see above

Check both directions when adding a variable `gate.sh` reads: `grep -n export tests/test-scripts.sh`
for outbound, and one full-suite run with the variable set for inbound.

## Proving cross-platform behaviour on one platform

The gate runs on whichever platform invoked it, so a portability bug can sit behind a fully
green suite. `ds-hygiene-hook` shipped a `stat` probe to review that worked on macOS and
silently disabled its check on every Linux box.

Where behaviour branches on a tool's platform variant, stub the other variant on `PATH` and
run against it, rather than reasoning about the flags:

    # GNU-shaped stat: -c succeeds, -f fails
    printf '#!/bin/sh\ncase "$1" in -c) echo 21;; *) exit 1;; esac\n' >"$stub/stat"
    chmod +x "$stub/stat"
    PATH="$stub:$PATH" bash scripts/gate.d/the-hook.sh

Note the failure that made this necessary: GNU `stat -f %z` does **not** fail. `-f` is
`--file-system` there, an unrecognised directive prints `?` and exits 0. Probes of the form
"try the BSD flag, fall back if it fails" are therefore inverted; order the GNU form first
and fall back to the BSD one, which does exit non-zero on an unknown flag.
