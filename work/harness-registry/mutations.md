# Mutation checks

Each mutation was applied individually, verified in the file, run against the named hermetic acceptance case, and restored afterward. Source-tree mutations used a `finally` block; the full preflight mutation used an isolated harness copy. Cases run in a fresh `bash -e` shell with explicit assertion returns for Bash 3.2, so the check helper cannot mask failures.

| Mutation | Failing case | Landing verification |
|---|---|---|
| match any entry regardless of root | `registry_lookup` (exit 1) | Exact replacement asserted once; reread confirmed new text present and old text absent. |
| drop stale-root guard | `registry_lookup` (exit 1) | Exact replacement asserted once; reread confirmed new text present and old text absent. |
| remove registration preflight | `registry_register` (exit 1) | Removed the entire preflight block in an isolated harness copy; reread confirmed the old block absent and mutation marker present. Restored and asserted byte equality afterward. |
| gate cd to git root | `registry_flow` (exit 1) | Exact replacement asserted once; reread confirmed new text present and old text absent. |
| restore registry plan commit | `registry_flow` (exit 1) | Exact replacement asserted once; reread confirmed new text present and old text absent. |
| read checkout demo plan | `registry_flow` (exit 1) | Exact replacement asserted once; reread confirmed new text present and old text absent. |
| drop release guard | `registry_flow` (exit 1) | Exact replacement asserted once; reread confirmed new text present and old text absent. |

## Review round 1 followup

| Mutation | Failing case | Landing verification |
|---|---|---|
| remove subdir normalization (leading `./`, repeated `/`, trailing `/`) | `registry_subdir` (exit 1): `./app` created `repo-.-app`, failing the state-dir assertion | Exact block matched once; reread confirmed replacement marker present and original block absent before running. Restored in `finally`, with byte equality asserted. |
| revert registry `hook_dir` to `scripts/gate.d` | `registry_flow` (exit 1): gate printed `GATE: PASS`, then the missing external marker failed the case | Exact registry hook assignment matched once; reread confirmed replacement present and original absent before running. Restored in `finally`, with byte equality asserted. |

Both unmutated targeted cases passed. Cases were extracted from the test file and run directly in fresh `bash -e` shells with temporary fixture roots.
