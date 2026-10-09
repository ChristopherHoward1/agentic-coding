1. **MEDIUM — `ARCHI.md`: branch freshness fails.** Running `bash scripts/archi-fresh.sh` on `wt/template-export` exits 1: `ARCHI.md is stale at HEAD; newer source path(s): scripts/`. Refresh ARCHI after the export-script fix to satisfy the explicit acceptance criterion.

No CRITICAL/HIGH findings. The round-1 directory-resolution issue is fixed and covered by a mutation-tested regression case.

ShellCheck passed. I could not independently run the gate or demonstration because the read-only sandbox blocks temporary-file creation; the required successful exported smoke-suite demonstration remains unverified.

Codex verdict: APPROVE
