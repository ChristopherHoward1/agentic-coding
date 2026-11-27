The gate or demonstration failed on your implementation of /Users/cboyfly/Documents/repos/agentic-coding/work/deferral-sweep/plan.md. You are resuming in the same worktree on branch wt/deferral-sweep.

Failure output:
```
Code review round 1 finding (codex MEDIUM, accepted): harness/examples/gate.d/data-contract.sh skips the wide-row check once a file has more than DATA_CONTRACT_SCAN_ROWS nonblank rows, because the `if count > scan: continue` line sits above it. A wider row at position scan+1 passes. Every row is already parsed to count rows, so the check costs nothing extra.
Code review round 1 finding (code-reviewer LOW, accepted with it): no test pins "only the first wide row is reported". Removing `and not wide` still passes every data-contract case.
```

Fix both, inside the plan's footprint (only `harness/examples/gate.d/data-contract.sh` and `harness/tests/test-scripts.sh`):
1. In `data-contract.sh`, run the wide-row check for every nonblank row, including rows past the scan limit. Type checks still stop at the limit. Update the header comment if it needs to say so.
2. In `harness/tests/test-scripts.sh`, extend the `contract_case` scenarios. Add one case where the only wide row comes after `DATA_CONTRACT_SCAN_ROWS` (see the existing `cap` scenario for how it sets the limit), and make it fail the contract with the `row <n> has <k> fields, header has <h>` message. Add one case with two wide rows, and assert that exactly one such error line is printed. Register both with the existing `check_exit`/`check` loops.
3. Prove each new test pins its guard: temporarily move the check back below `count > scan`, then remove `and not wide`, and confirm the matching new test fails each time (use `TEST_FILTER`). Restore the code after each mutation.

Read /Users/cboyfly/Documents/repos/agentic-coding/knowledge/test-helper-contract.md before editing the tests (bash 3.2: every assertion inside a case function needs `|| return 1`).

Re-run harness gate until it passes, then print an updated summary that includes the mutation results. If a failure cannot be fixed within the plan's scope, stop and explain why instead of working around it.
