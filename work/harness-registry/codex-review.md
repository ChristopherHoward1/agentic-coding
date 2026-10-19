- **MEDIUM — Subdirectory names containing glob characters break the exclude rule.** In [register.sh:52](/Users/cboyfly/Documents/repos/agentic-coding-worktrees/harness-registry/harness/scripts/register.sh:52), an existing directory such as `app[1]`, registered with `--name app`, produces `/app[1]/CLAUDE.local.md`. Git interprets the brackets as a pattern, so the generated file remains untracked and `git status` is dirty. Escape gitignore metacharacters when generating the rule, and use a literal pathspec for the tracked-file check.

- **MEDIUM — The required interactive constitution-loading check remains unverified.** [notes.md](/Users/cboyfly/Documents/repos/agentic-coding-worktrees/harness-registry/work/harness-registry/notes.md) explicitly leaves the `/memory`, external-import approval, and `/add-dir` Edit checks to the orchestrator. Generated-file assertions cannot establish that Claude actually loads the constitution or permits state-directory edits. Complete and record this acceptance check before declaring the unit finished.

No CRITICAL or HIGH findings.

Codex verdict: APPROVE
