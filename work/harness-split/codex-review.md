1. **HIGH — `bash harness …` breaks release, retro, and generated Bitbucket gate commands.** [4-release/SKILL.md:12](/Users/cboyfly/Documents/repos/agentic-coding-worktrees/harness-split/harness/skills/4-release/SKILL.md:12) invokes `bash harness release …`. Bash treats `harness` as a script filename; from this repo’s root it encounters the `harness/` directory and exits 126. Reproduced with `bash harness release next-version`: `harness: harness: is a directory`. The same error affects release tagging, retro creation/removal, and the work profile’s CI instructions. Replace these invocations with `harness <command>`; correct the matching ARCHI verification command too.

Dispatcher shellcheck passes. Full gate and demo were not run because this review environment permits only filesystem reads, while their fixtures require writes.

Codex verdict: REQUEST CHANGES
