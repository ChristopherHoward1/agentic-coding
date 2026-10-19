- **HIGH — Normalize `--subdir` before generating the exclude pattern** (`harness/scripts/register.sh:24–25,46`). `--subdir ./app` passes validation but writes `/./app/CLAUDE.local.md` to `.git/info/exclude`. Git does not match that pattern against `app/CLAUDE.local.md`, leaving the generated harness file untracked and vulnerable to accidental commit. `--subdir .` has the same problem. I verified the pattern mismatch with `git check-ignore`. Normalize these paths before constructing the registry entry and exclude line, and test that porcelain remains empty.

- **MEDIUM — The required constitution-loading check remains unverified** (`work/harness-registry/notes.md`). The notes explicitly leave the interactive `/memory` and state-directory Edit checks outstanding. The automated assertions verify generated import text, but cannot establish that Claude loads the constitution or permits state writes as required. Complete the manual acceptance check and record its results.

The read-only environment prevented running the fixture suites; review used source inspection and a read-only Git pattern check.

Codex verdict: REQUEST CHANGES
