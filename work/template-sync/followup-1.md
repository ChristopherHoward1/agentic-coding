Review round 1 on your implementation of work/template-sync/plan.md raised two MEDIUM findings to fix. You are resuming in the same worktree on branch wt/template-sync.

Findings:
```
✗ MEDIUM scripts/sync-template.sh:15 — the release-tag guard treats VERSION as a regex: `grep -qx "v$version"` lets a HEAD tagged only `v2026x10x2` pass for VERSION 2026.10.2. Use `grep -Fqx`. Add a near-match rejection case to sync case (c) (HEAD carries only a tag like v<VERSION with dots replaced by x> → exit 1), and mutation-check it (revert to grep -qx → case (c) fails; record in work/template-sync/mutations.md).

✗ MEDIUM scripts/sync-template.sh:58-59, tests/test-export.sh (case (b) empty-TMPDIR checks) — on macOS, bare `mktemp -d` ignores TMPDIR, so the clone and export dirs never land in the test's TMPDIR. Removing the no-op `rm -rf "$clone"` or the export trap still passes the suite on macOS, and every local gate run leaks template clones into the real temp dir. Use an explicit template for both dirs: `mktemp -d "${TMPDIR:-/tmp}/sync.XXXXXX"` (or similar). Then on THIS machine (macOS) re-run the two mutations (remove no-op clone cleanup; remove export trap), confirm each landed and that case (b) fails, restore, and update mutations.md with what you observed here.
```

Stay inside the plan's footprint. Re-run scripts/gate.sh until it passes and commit the fix. The demo needs network to github.com which your sandbox lacks — do not run it; the orchestrator will. If a finding cannot be fixed within the plan's scope, stop and explain why instead of working around it. End with a short summary of the changes and the mutation results.
