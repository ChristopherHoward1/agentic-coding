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
