- **MEDIUM — CSV rows with extra fields pass the contract.** In [data-contract.sh](/Users/cboyfly/Documents/repos/agentic-coding-worktrees/notebook-gate/harness/examples/gate.d/data-contract.sh:75), validation iterates over the header names and ignores any remaining fields in a row. For example, a file with header `id,amount` and row `1,2.5,unexpected` passes a matching contract, even with `extra_columns: forbid`. A malformed export can therefore pass the shape check and reach a notebook. Validate each row’s width against the header and report a mismatch.

Codex verdict: APPROVE
