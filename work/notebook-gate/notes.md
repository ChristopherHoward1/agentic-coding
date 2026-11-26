# Notes — notebook-gate

## Implementer summary

Implemented the two opt-in hooks and updated the profiles and [ARCHI.md](/Users/cboyfly/Documents/repos/agentic-coding-worktrees/notebook-gate/ARCHI.md). Notebook execution uses the primary checkout’s data and temporary outputs; data contracts check CSV and Parquet schemas and row counts.

**Verification:** `harness gate` passed, with 365 script tests and 6 publish tests. The focused hook suite passed 26 cases.

Acceptance coverage in [test-scripts.sh](/Users/cboyfly/Documents/repos/agentic-coding-worktrees/notebook-gate/harness/tests/test-scripts.sh):

- **Notebook execution:** `idle`, `no parameters`, `missing papermill`, `missing notebook`, `success`, `override`, `failure`, and `missing primary subfolder` cover skipping, refusals, invocation, root selection, continuation, and clean-tree behavior.
- **Data contracts:** `pass`, `override`, `cap`, `allow`, `idle`, the named failure cases, `reports both contracts`, and `no-arrow` cover CSV validation, root selection, aggregation, and the missing-PyArrow refusal.
- **Profiles:** the requested declarations appear in all three profiles.
- **Mutation checks:** targeted mutations were caught for root resolution, parameters, smoke mode, output location, continuation, dtype and row checks, extra columns, reporting, and notebook cwd.

The work is **partially complete** in these respects:

- The PyArrow success case and `int64` mapping mutation could not run: the local `python3 -I` cannot import PyArrow. The forced no-PyArrow case passed.
- Mutation checks were run through targeted fixture functions; the complete plan-specified mutation suite, including removal of the PyArrow import guard, was not demonstrated.
- `harness archi-fresh wt/notebook-gate` reports stale because it reads committed branch history. The ARCHI update is uncommitted, and the contract prohibits writing Git metadata. The orchestrator needs to rerun freshness after committing.

No out-of-scope files were changed.

Orchestrator: the pyarrow-present case runs in the orchestrator's environment (/opt/miniconda3 python3 imports pyarrow); the implementer sandbox's python3 did not.

## Gate / demo

GATE PASS (365 / 6); archi-fresh 0; demo 0 (real papermill in a temp venv):
```
contract exit=0
nb-exec: ok nb/check.ipynb
nb-exec exit=0
nb-exec: ok nb/check.ipynb
nb-exec: FAILED nb/bad.ipynb
           ^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/var/folders/y6/cqq_kqw13z58pgr6c9f3fzdm0000gn/T/tmp.nC8EPsvK3u/venv/lib/python3.12/site-packages/click/decorators.py", line 34, in new_func
    return f(get_current_context(), *args, **kwargs)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/var/folders/y6/cqq_kqw13z58pgr6c9f3fzdm0000gn/T/tmp.nC8EPsvK3u/venv/lib/python3.12/site-packages/papermill/cli.py", line 235, in papermill
    execute_notebook(
  File "/var/folders/y6/cqq_kqw13z58pgr6c9f3fzdm0000gn/T/tmp.nC8EPsvK3u/venv/lib/python3.12/site-packages/papermill/execute.py", line 131, in execute_notebook
    raise_for_execution_errors(nb, output_path)
  File "/var/folders/y6/cqq_kqw13z58pgr6c9f3fzdm0000gn/T/tmp.nC8EPsvK3u/venv/lib/python3.12/site-packages/papermill/execute.py", line 251, in raise_for_execution_errors
    raise error
papermill.exceptions.PapermillExecutionError: 
---------------------------------------------------------------------------
Exception encountered at "In [3]":
---------------------------------------------------------------------------
ValueError                                Traceback (most recent call last)
Cell In[3], line 1
----> 1 raise ValueError('boom')

ValueError: boom

nb-exec: kept output /var/folders/y6/cqq_kqw13z58pgr6c9f3fzdm0000gn/T//nb-exec.RuUNK4
nb-exec both exit=1
status=[]
data-contract: contracts/sales.json: column amount expected int, got '2.5'
drift exit=1

```
