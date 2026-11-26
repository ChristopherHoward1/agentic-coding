Code review round 1 of your implementation of /Users/cboyfly/Documents/repos/agentic-coding/work/notebook-gate/plan.md raised findings to fix. You are resuming in the same worktree on branch wt/notebook-gate.

Failure output (round 1):
```
HIGH (codex): a failed data contract does not stop notebook execution. gate.sh runs every hook even after one fails, so with both hooks enabled nb-exec still runs notebooks against data that just failed validation — breaks "schema drift fails before a notebook runs" and can trigger an expensive GPU run.
MEDIUM (codex): the contract format (fields, dtypes, rows, extra_columns) is documented nowhere a user enabling the hook will read it.
MEDIUM (code-reviewer): test-scripts.sh:3161 — the data-contract `override` case cannot fail: it copies the CSV to the override dir but leaves the primary copy, so ignoring NB_DATA_ROOT still passes.
MEDIUM (code-reviewer): test-scripts.sh:3147 — `-p out_dir` outside the repo is not pinned: changing it to "$(dirname "$nb")/out" keeps the suite green (the grep matches the output-notebook arg; the stub never writes out_dir).
MEDIUM (code-reviewer): test-scripts.sh:3174/3184 — the pyarrow case's "ran"/"skipped" note goes to /dev/null inside `check`, so CI's skip is invisible.
LOW: blank CSV lines count as data rows (data-contract.sh:66-69).
LOW: dead `printf 'RAISE\n' >>nb/a.ipynb` line with a misleading comment (test-scripts.sh:3148).
LOW: `${TMPDIR:-/tmp}/nb-exec.XXXXXX` gives a double slash when TMPDIR ends in /.
LOW: no test that the skip line comes before data-root resolution (idle hook in a subfolder missing from the primary checkout must still skip).
LOW: Parquet `halffloat` (float16) is not mapped to float.
```

Fix:
- **Contract failure stops notebooks.** When a `data-contract.sh` sits next to `nb-exec.sh`, in the same hook directory (`"$(dirname "$0")"`), `nb-exec.sh` runs it first. If it fails, `nb-exec.sh` writes `nb-exec: skipped; data contracts failed` to stderr and exits 1 without calling papermill. With no sibling, behavior is unchanged. Test:
  - both hooks are in one directory and the contract fails: `nb-exec` exits 1 with that message, and the stub log is empty;
  - the contract passes: the notebooks run.
- **Document the contract format.** Add it to `data-contract.sh`'s header comment and to `machine-learning.md`'s `DATA_CONTRACTS` declaration:
  - one JSON example, plus the fields `path`, `columns`, `rows` and `extra_columns`;
  - the dtypes `int`, `float`, `str`, `bool` and `any`, and that the header is excluded from `rows`;
  - in `NOTEBOOK_EXEC`, that `nb-exec` runs the contracts first when both are enabled.
- **Override test.** Make the `data-contract` override case fail when `NB_DATA_ROOT` is ignored: remove or alter the primary copy.
- **`out_dir` test.** Make the stub write a file into its `out_dir` argument, and assert that the file lands under `$TMPDIR` and that `git status --porcelain` is empty.
- **Pyarrow note.** Print the pyarrow ran/skipped note outside `check`, so it shows in gate output. For example, probe with `python3 -I -c 'import pyarrow'` before the loop and `echo` the result.
- **LOWs:**
  - skip blank CSV lines when counting and scanning rows;
  - remove the dead line;
  - build the temp path without a double slash (`${TMPDIR%/}`);
  - add an idle-skip case run from a subfolder missing in the primary checkout, for both hooks;
  - map `halffloat` to `float`.

Read `/Users/cboyfly/Documents/repos/agentic-coding/knowledge/test-helper-contract.md` before editing tests. Every assertion uses `|| return 1`, and new test descriptions start with `nb-exec` or `data-contract`.

Stay inside the plan's footprint. Re-run harness gate until it passes, then print an updated summary. If a failure cannot be fixed within the plan's scope, stop and explain why instead of working around it.
