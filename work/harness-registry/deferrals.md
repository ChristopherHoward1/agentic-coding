# Accepted deferrals — harness-registry

- **Gitignore metacharacters in `--subdir`.** Raised by codex round 2 (MEDIUM) and the Claude reviewer round 2 (LOW).
  - A subdir name containing `[`, `*` or `?` (e.g. `app[1]`) produces an exclude line that git reads as a pattern. The generated `CLAUDE.local.md` then shows as untracked. The `git ls-files` tracked check has the same glob issue.
  - Deferred because such directory names are unlikely in real work repos, and both reviewers approved without it.
  - Lands as a small fix when real use hits it: escape gitignore metacharacters in the exclude line and use a `:(literal)` pathspec for the tracked check.
