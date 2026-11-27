# Deferral sweep: release the merged small fixes

**Slug:** deferral-sweep · **Date:** 2026-11-27 · **Status:** approved

## Goal

Three small fixes have merged to `main` since v2026.11.7, and together they close the open MEDIUM deferrals from `notebook-gate` and `pr-release`, plus one notebook-gate LOW. The public template syncs only on a release:

- #98: `data-contract.sh` fails a CSV row that is wider than its header.
- #99: `release.sh` copies the plan's Goal and Acceptance criteria into `pr.md` with fence-aware section extraction.
- #100: `/3-review` re-captures the reviewed SHA every round, and a new test pins `nb-exec`'s `TMPDIR` trailing-slash fix.

The Owner asked for this release. Done = a release whose note names all three, followed by the template sync.

## Approach

A release-only unit; its only behavior change is the round-1 wide-row fix. The branch carries this plan, the orchestrator's `PLAN.md` Now line and a targeted `ARCHI.md` edit. #100 touched `harness/` after #99's ARCHI edit, so ARCHI is stale at `origin/main`. Following the 2026-11-23 decision, the code-reviewer also reads `git diff v2026.11.7..origin/main`, the range being released, because small fixes ship unreviewed.

## Footprint

Files to modify:
- `harness/examples/gate.d/data-contract.sh` and `harness/tests/test-scripts.sh` (round-1 fix, see Review: the wide-row check covers every row, not only the first `DATA_CONTRACT_SCAN_ROWS`, and a second wide row pins "first only")
- `work/pr-release/deferrals.md` (round-1 fix: the `':/'` entry gets its Closed line)
- `ARCHI.md` (targeted freshness edit: the `harness/tests/test-scripts.sh` line names the new `nb-exec`/`data-contract` cases, a `TMPDIR` trailing slash and a CSV row wider than its header)
- `PLAN.md` (orchestrator: this unit's Now line)

## Acceptance criteria

- [ ] The release note names the wide-row contract check, the fence-aware `pr.md` extraction and the `/3-review` reviewed-SHA re-capture, and each matches `git diff v2026.11.7..origin/main`.
- [ ] Each of the four deferral closures (three MEDIUM entries and the notebook-gate `TMPDIR` LOW) in `work/notebook-gate/deferrals.md` and `work/pr-release/deferrals.md` names the change that closed it, and that change is in the released range.
- [ ] A wide CSV row past `DATA_CONTRACT_SCAN_ROWS` fails the contract, and a file with several wide rows reports only the first; each is pinned by a test that fails with the guard removed.
- [ ] `harness archi-fresh wt/deferral-sweep` exits 0.
- [ ] `harness gate` passes.

## Release

Release note: Ships three small fixes that close the open MEDIUM notebook-gate and pr-release deferrals. `data-contract.sh` fails a CSV row with more fields than its header, whatever `extra_columns` says and however far past the `DATA_CONTRACT_SCAN_ROWS` type-check limit it sits; only the first such row is reported. `harness release` builds `pr.md` from the plan's Goal and Acceptance criteria without stopping at a `## ` line inside a fenced block. `/3-review` re-captures the reviewed SHA every round, and a new test pins `nb-exec`'s `TMPDIR` trailing-slash handling.

## Demonstration

None: release-only unit; the released changes already carry their own tests in `harness/tests/test-scripts.sh`, run by the gate.

## Review

Release-only unit, planned at the Owner's request ("accomplish all", after the list proposing to release #98 and #99 as a minimal loop unit); no plan-reviewer round (no design to review), following `work/template-catchup`.
Owner approval (2026-11-27): release the merged small fixes #98–#100 to the template.
Plan verdict: APPROVE

Code review round 1: both APPROVE. Codex MEDIUM: the wide-row check ran only on the first `DATA_CONTRACT_SCAN_ROWS` rows, so the release note overstated it. Fixed, not qualified, because every row is already parsed for the row count, so the check costs nothing. Code-reviewer LOWs: 1, "first wide row only" was unpinned, so it's fixed together with the MEDIUM; 3, the Goal and criterion 2 overstated the closures, so the wording is fixed; 4, the pr-release `':/'` entry had no Closed line, so one is added. LOW 2 is left as it is: an unclosed fence copies the rest of the plan into `pr.md`, the same as `demo.sh`'s rule, and the real `Reviewed-SHA:` is still written last. The fix changes behavior, so a fresh round 2 follows.
