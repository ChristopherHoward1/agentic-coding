# Notes — stacked-units-followups

## Implementer summary

Implemented `harness worktree restack`, including landed-parent target selection, conflict aborts, warnings, manual remedies, and the requested hints. Updated the architecture documentation. **`harness gate` passes**: 337 script cases and 6 publish cases.

Acceptance coverage in `stack_followup_case` and `stack_near_case`:

- Untouched, gained, amended, rebase-landed, rewritten-landed, merge-landed, and second-restack scenarios have corresponding named cases.
- Refusals are covered by `unstacked`, `no-worktree`, `dirty`, `missing`, `no-fork`, and `conflict`.
- Registry behavior is covered by `registry-amended`, `registry-merge`, `registry-untouched`, and `registry-release`.
- Hints and the missing-parent remedy are covered by `hint`, `release-hint`, and `missing`.
- Missing-fork warnings are covered by `warning` and `warning-merged`; near-miss and silent header variants have individual cases.
- Existing stack assertions and executable extracted commands pass unchanged.

Two acceptance items remain for the orchestrator or reviewer:

- `harness archi-fresh wt/stacked-units-followups` reports stale because it reads committed branch history. The ARCHI update is uncommitted, as required by the contract; rerun after the orchestrator commits it.
- The plan assigns mutation-pin verification to the reviewer; I did not run those mutations.

No out-of-scope files were changed.

## Gate / demo

GATE PASS (337 / 6); archi-fresh 0; demo 0:
```
base before: 00046ce3477ecccf584bb4960effada2afc88825 note: p was rewritten since c branched; run: harness worktree restack c, or to pick it up: git -C /private/var/folders/y6/cqq_kqw13z58pgr6c9f3fzdm0000gn/T/tmp.jKyN2j42qY/wts/c rebase --onto wt/p 00046ce3477ecccf584bb4960effada2afc88825 
Rebasing (1/2)Rebasing (2/2)Successfully rebased and updated refs/heads/wt/c.
restacked wt/c onto origin/main
origin/main
c1
Record plan for c

```

## Followup 1 (round-1 MEDIUMs: git -C '' warning, primary-checkout restack, ARCHI line 24)

Implemented the review fixes:

- The no-fork-point warning now tells users to recreate the worktree when none exists, without printing a `git -C` command.
- `restack` refuses when the child branch is checked out in the primary checkout.
- Added regression tests for both cases and updated the release entry in [ARCHI.md](/Users/cboyfly/Documents/repos/agentic-coding-worktrees/stacked-units-followups/ARCHI.md).

**Verification:** `harness gate` passed. No requested criteria remain partial; no out-of-scope changes were made.

Gate PASS; demo 0; archi-fresh 0.
