# Demo fail-fast: a failing command mid-block fails the demonstration

**Slug:** demo-fail-fast · **Date:** 2026-10-20 · **Status:** implemented

## Goal

`harness demo` runs the Demonstration block as plain `bash <file>` (`harness/scripts/demo.sh:69`), so only the block's last command decides the verdict. A command that fails mid-block is printed and ignored, and the demo exits 0. This hid a failed clone in `template-sync`, and since then plan review has had to add `|| exit 1` to every check, in `harness-publish` and again in `stacked-units` (their `retro.md` files). The Owner is about to use the harness at work, where no second reviewer exists to catch a green demo that actually failed.

Done = the block runs under `bash -e`, so the first failing simple command ends it and `harness demo` exits 1 with that command's code. A plan that shows an expected non-zero exit says so explicitly, and `plan.tpl` shows the two forms that hold up under errexit: one for printing the status and one for capturing output and status together.

Known limit: on Bash 3.2 (macOS `/bin/bash`, which `demo.sh` gets from PATH), a failing `[[ ]]` or `(( ))` that isn't the last command does not end the block (verified; `work/stacked-units/retro.md`). On Linux, which covers CI and SageMaker, it does. So mid-block checks are written as `[ ]` / `test`, or as `[[ ]] || exit 1`, and `plan.tpl` says so.

## Approach

- `demo.sh`: `bash "$block"` → `bash -e "$block"`. Add "under bash -e" to the usage text. Everything else, including the exit contract (0 pass / 1 failure or dirtied tree / 2 plan or tooling error) and the dirty-tree check, stays the same.
- `errexit` doesn't fire for commands in `if`/`while` conditions, `&&`/`||` lists except their last command, or `!`. Those are the ways to show an expected failure. A plain assignment `out=$(cmd)` takes `cmd`'s status, so `out=$(cmd); rc=$?` stops the block. The capture form is `rc=0; out=$(cmd) || rc=$?`. Pipelines are judged by their last command, because `pipefail` is not turned on. On Bash 3.2 a mid-block `[[ ]]` / `(( ))` failure is also exempt (see Goal), and an `ERR` trap doesn't catch it either. There is no mechanical fix within 3.2, so the guidance covers it.
- Alternative considered: `set -euo pipefail`. `-u` would break blocks that read unset variables on purpose, and `pipefail` would fail a `cmd | head` with SIGPIPE. Both go beyond the recorded need (a failing command mid-block), so neither is added.
- Tests: the shared scoping/cwd fixture (heredoc at `harness/tests/test-scripts.sh:827-842`, `false` at line 835) **loses its `false` line**. The `## ` comment line stays. Otherwise "demo runs the full first block in the requested cwd" would break under `-e`. Fail-fast gets its own fixture.
- Older plans under `work/` that use `cmd; echo "exit=$?"` or `out=$(cmd); echo "exit=$?"` are released history and are never re-run. They are not changed.

## Footprint

Files to modify:
- `harness/scripts/demo.sh`
- `harness/tests/test-scripts.sh` (demo section, around lines 823-910)
- `harness/skills/1-plan/prompts/plan.tpl` (Demonstration guidance)
- `ARCHI.md` (the three "plain bash" mentions of `demo.sh`: on lines 18 and 59 they become "bash -e"; line 21's test-case list names the new cases (fail-fast, expected-failure forms) in place of "plain bash")
- `PLAN.md`: the orchestrator removes the `demo-fail-fast` candidate line and adds this unit to Now, committed on the branch

Files NOT to touch:
- `work/*/plan.md` for released units

## Acceptance criteria

- [ ] `demo.sh` runs the extracted block with `bash -e`, and its `--help` text says so.
- [ ] The shared fixture no longer contains `false`, and "demo runs the full first block in the requested cwd" still passes, `## ` comment line included.
- [ ] Fail-fast fixture: a block of `echo before`, `false`, `echo after`. It is covered by two checks and replaces the pinned "demo passes with plain bash despite an intermediate failure" case:
  - a `check_exit` for exit 1, with stderr naming `code 1`
  - a `check ... bash -c` that captures stdout and asserts it contains `before` and not `after` (`check_exit` throws stdout away). `demo.sh` exits 1 here, so the capture must tolerate that, for example `out=$(… ) || true`, not the `out=$(…) &&` chain the other demo checks use.
- [ ] Hermetic test: a block of `[ 1 -eq 2 ]`, then `echo after` → exit 1, and stdout doesn't contain `after`. No test pins `[[ ]]` behaviour, because it differs between local Bash 3.2 and CI.
- [ ] Mutation: with `-e` removed from `demo.sh`, the fail-fast checks fail. The reviewer shows this, and shows that the mutation actually landed.
- [ ] `plan.tpl`'s Demonstration guidance, in three or four lines, says the block runs under `bash -e` and shows both forms: `cmd || echo "exit=$?"`, and `rc=0; out=$(cmd) || rc=$?` for capturing output. It also says to write mid-block checks as `[ ]` / `test`, or to end `[[ ]]` checks with `|| exit 1`, because Bash 3.2 doesn't stop on those.
- [ ] ARCHI lines 18 and 59 say "bash -e", line 21 names the new demo test cases, and no line describes `demo.sh` as plain bash. `grep -c 'plain bash' ARCHI.md` prints `0` on the branch, and `harness archi-fresh wt/demo-fail-fast` exits 0.
- [ ] `harness gate` passes.

## Release

Release note: `harness demo` runs the Demonstration block under `bash -e`, so a command that fails mid-block now fails the demo. On Bash 3.2, mid-block `[[ ]]` checks still need `|| exit 1`.

## Demonstration

Run the branch's real `demo.sh` on throwaway plans in a temp git repo. The block uses only errexit-safe forms, so it behaves the same whether the outer `harness demo` is the old plain-bash runner or the new `bash -e` one. Against the unpatched `demo.sh` it fails at the first check (`fail-fast exit=0`). The orchestrator verified both of these against a scratch copy before review.

```sh
d=$(mktemp -d) && git -C "$d" init -q && mkdir -p "$d/work/x" || exit 1
trap 'rm -rf "$d"' EXIT
f='```'
printf '## Demonstration\n\n%ssh\necho before\nfalse\necho after\n%s\n' "$f" "$f" >"$d/work/x/plan.md"
rc=0; out=$(harness/scripts/demo.sh x "$d" 2>&1) || rc=$?
echo "$out"; echo "fail-fast exit=$rc"
[ "$rc" -eq 1 ] || exit 1
case "$out" in *after*) exit 1 ;; esac
printf '## Demonstration\n\n%ssh\nrc=0; out=$(sh -c "echo hi; exit 3") || rc=$?\necho "rc=$rc out=$out"\nsh -c "exit 4" || echo "exit=$?"\n%s\n' "$f" "$f" >"$d/work/x/plan.md"
out=$(harness/scripts/demo.sh x "$d" 2>&1) || exit 1
echo "$out"
case "$out" in *"rc=3 out=hi"*exit=4*) ;; *) exit 1 ;; esac
harness/scripts/demo.sh --help | grep -q 'bash -e' || exit 1
echo demo-fail-fast-ok
```
Expected: `before`, a message naming code 1, `fail-fast exit=1` and no `after`; then `rc=3 out=hi` and `exit=4`; then `demo-fail-fast-ok`.

## Review

Round 1 (plan-reviewer): REVISE. All four findings applied:
1. The demo's `out=$(…); rc=$?` would itself die under `-e`. Changed to `rc=0; out=$(…) || rc=$?`. The capture form was added to the `plan.tpl` criterion and to a hermetic test.
2. The fail-fast stdout assertion is now a `check ... bash -c`, because `check_exit` discards stdout.
3. The shared fixture's `false` removal is now an explicit step and criterion.
4. The demo cleans up `$d` with a trap.

Round 2 (fresh plan-reviewer): REVISE. All three findings applied:
1. (HIGH) Bash 3.2 doesn't stop on a mid-block `[[ ]]` / `(( ))` failure. The orchestrator confirmed this on `/bin/bash` 3.2.57. The limit is now stated in Goal, Approach, `plan.tpl` guidance and the release note, and a portable `[ ]` fail-fast test was added.
2. (LOW) ARCHI line 21 now names the new test cases instead of saying "bash -e".
3. (LOW) The fixture line range is corrected to 827-842, with `false` at 835.

Round 3 (fresh plan-reviewer): APPROVE, with three LOWs, all applied:
1. Fixed the ARCHI criterion typo and added a `grep -c 'plain bash'` check.
2. The fail-fast stdout check must tolerate `demo.sh`'s exit 1.
3. Dropped the two expected-failure-form tests. They test Bash rather than `demo.sh` and pass with `-e` removed. The Demonstration exercises both forms, and `plan.tpl` documents them.

Plan verdict: APPROVE

Code review round 1: both reviewers APPROVE.
- code-reviewer: all criteria met. The reviewer verified the mutation itself: with `-e` removed, 4 of the new checks fail. It also ran the gate (PASS) and the demo (matches Expected). Two LOWs.
- codex: one LOW, the same as the code-reviewer's first.
- LOW 1 (both reviewers): ARCHI line 21 named "expected-failure forms" tests that plan-review round 3 dropped. The orchestrator corrected the wording after both approvals. It is a description sync of approved code, the same exemption `/3-review` step 7 gives ARCHI heals, so no new round was started.
- LOW 2 (code-reviewer): one long line in `plan.tpl`. Style only, left as is.

Code-review verdict: APPROVE
Codex-review verdict: APPROVE
