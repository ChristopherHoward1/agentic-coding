The implementer contract precedes this handoff — it is your contract.

Review round 1 on your implementation of work/harness-registry/plan.md found a blocking issue. You are resuming in the same worktree on branch wt/harness-registry. Your earlier work is committed there; verify with `git branch --show-current` and `git log --oneline -3`.

Fix these findings. Stay inside the plan's footprint.

1. **HIGH: normalize `--subdir` in `harness/scripts/register.sh`.**
   - Today, `register --subdir ./app` exits 0 with these results:
     - it names the state dir `repo-.-app`
     - it writes `/./app/CLAUDE.local.md` into `.git/info/exclude`, a pattern git doesn't match
     - `git status --porcelain` then shows `?? app/CLAUDE.local.md`
   - `--subdir .` and `app//` fail the same way.
   - This breaks the plan's goal that `git status` stays empty. Before building the entry, the name and the exclude line:
     - strip any leading `./`
     - collapse repeated `/`
     - strip trailing `/`
     - reject an empty result, `.`, and any `.` or `..` path component (exit 1)
   - Add registry test coverage:
     - `--subdir ./app` and `--subdir app//` both give state dir `repo-app`, exclude line `/app/CLAUDE.local.md`, and an empty `git status --porcelain`.
     - `--subdir .` and `--subdir app/./x` each exit 1 with nothing written.
   - Mutation: remove the normalization. Show that the new case fails, verify the mutation landed, revert, and record it in `work/harness-registry/mutations.md`.

2. **MEDIUM: prove the state-dir gate hook actually runs.**
   - In the registry flow case (`harness/tests/test-scripts.sh`, about lines 2311-2312), the hook only checks `$PWD`. If the hook never runs, the gate still passes.
   - A reviewer confirmed this: reverting `gate.sh`'s registry `hook_dir` to `scripts/gate.d` leaves the case green.
   - Make the hook write a marker file, outside any repo, that records its `$PWD`. Assert that the marker exists and holds the project root.
   - Mutation: the `hook_dir` revert must now fail the case. Record it in `mutations.md`.

3. **LOW, cheap cleanups:**
   - Remove the duplicated `mkdir -p scripts/lib; cp -R …` lines in the release fixture (about lines 113-117) and the fan fixture (about lines 537-545).
   - In `harness/skills/3-review/SKILL.md` step 1, give the deferrals path the same `$(harness project)` wording the other steps use, keeping the pinned literal `work/<slug>/deferrals.md` text that any static grep needs.

The git-index note from your original handoff still applies. If you can't stage or commit, leave the changes unstaged; the orchestrator commits them.

Before finishing, run all of these directly. All must pass:
- `shellcheck harness/scripts/*.sh harness/scripts/lib/*.sh harness/tests/*.sh harness/bin/harness`
- `bash harness/tests/test-scripts.sh`
- `bash tests/test-export.sh`
- `bash harness/bin/harness gate`

Then run the plan's Demonstration block from the worktree root and paste its output in an updated summary. If a fix cannot be made within the plan's scope, stop and explain why instead of working around it.
