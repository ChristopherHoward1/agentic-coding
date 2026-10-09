Fixed both findings: literal tag matching with near-match rejection, and explicit TMPDIR templates for both directories.
All three mutations landed on macOS: regex matching failed case (c); removing clone cleanup or the export trap failed case (b). Restored and recorded in `work/template-sync/mutations.md`. Gate passes. Demo skipped as requested.
Commit blocked: the sandbox denied creating `index.lock` in the parent repository’s worktree metadata. The three changed files remain uncommitted.
