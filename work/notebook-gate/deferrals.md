# Accepted deferrals: notebook-gate

- **Code review round 2, codex MEDIUM: CSV rows wider than the header pass.** `data-contract.sh` validates each row against the header's columns and ignores any extra fields. So header `id,amount` with the row `1,2.5,unexpected` passes, even under `extra_columns: forbid`.
  - **Why deferred:** a ragged export still fails in the same gate run. pandas `read_csv` raises `Expected N fields`, and that error surfaces once a gated notebook reads the file. Both reviewers approved without the fix, and a third review round wasn't worth it.
  - **Lands in:** a small fix when real use hits it. Compare `len(row)` with the header width, and report `row <n> has <k> fields, header has <h>`.
  - **Closed** 2026-11-27 by small fix `csv-wide-rows`: a wider row fails the contract whatever `extra_columns` says, and only the first such row is reported.
- **Code review round 2, code-reviewer LOWs:**
  - the `halffloat` mapping is untested (local-only, needs pyarrow);
  - the `${TMPDIR%/}` trailing-slash fix is untested (**closed** 2026-11-27: the `nb-exec tmpdir-slash` test pins it, and fails when the fix is reverted);
  - contracts run twice when both hooks are enabled;
  - nb-exec tests depend on the sibling contract hook.

  All of them stay as they are. The behavior is correct, and the demo exercises the macOS `TMPDIR` path.
