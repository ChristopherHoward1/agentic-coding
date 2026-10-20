# The orchestrator owns implementer commits and the demo

**Slug:** codex-worktree-commit · **Date:** 2026-10-19 · **Status:** approved

## Goal

The codex sandbox can't write the worktree's git metadata, because the worktree's git dir sits under the primary checkout's `.git/worktrees/`. So `git add`, `git mv` and `git commit` fail, and the sandbox has no network. Nine units in a row (`acceptance-demo` → `harness-publish`) worked around this the same way: a hand-written recipe in each handoff says use plain `mv`/`rm`, stage nothing, and leave the commit and the demo to the orchestrator. The recipe has worked with zero gate retries for four units. Three costs remain:
- Each handoff has to restate the recipe, while the templates still tell the implementer to commit and run the demo.
- In `harness-registry`, a dispatch stopped without changes because nothing authorized an edit the plan itself required.
- In `harness-publish`, unstaged deletions stayed in `gate.sh`'s `git ls-files '*.sh'` list, so shellcheck failed on files that no longer existed.

Done means the recipe is the default. The implementer never touches git. `harness agent-exec` commits whatever a successful dispatch leaves behind. `/2-implement` runs the demo from the orchestrator. The gate lints the working tree as it actually is.

## Approach

1. **`agent-exec.sh` commits leftovers.** After a zero-exit dispatch, and after the existing null-dispatch check, it commits if `git -C "$WORKTREE" status --porcelain` is non-empty.
   - **Staging.** In repo mode it runs `git -C "$WORKTREE" add -A -- ':/' ':(exclude,top)work'`. `worktree sync-artifacts` owns `work/` there, and `fan-exec` seeds uncommitted `work/<slug>/` copies that must stay out of sample commits (`seed_work_dir`, `commit_sample_changes`). In registry mode it stages with `add -A` and no exclusion: `work/` in a work repo can be real project code, and unit artifacts live in the state dir.
   - **Commit.** Guarded by `git diff --cached --quiet`, so a dispatch that only touched `work/` commits nothing and still exits 0. The commit is `git commit -qm "Implementer changes for <branch>"`, where `<branch>` comes from `git branch --show-current`.
   - **Runs outside the sandbox.** This happens in the orchestrator's shell, so it works under any runtime.
   - **Failure cases.** A failing commit, for example one a pre-commit hook rejects, makes agent-exec exit non-zero with git's message. A non-zero dispatch still exits early without committing, as it does today.
   - **Implementer commits.** An implementer that commits on its own still works, because nothing is left to commit.
   - **Scope of `work/`.** In repo mode, an implementer edit under `work/` (outside the unit's own artifacts, which `sync-artifacts` carries) is never committed. So repo-mode plans must not name `work/` files in their footprint.
   - **Gate byproducts.** The implementer's in-sandbox gate run can leave files behind, and any that aren't gitignored land in the commit. The reviewer sees them in the diff. Projects should gitignore their gate caches. This repo's gate leaves none, because its tests write under `mktemp`.
   - **Tracked-file hooks.** Hooks that only scan tracked files (`examples/gate.d/nb-clean.sh`, `ds-hygiene.sh`) now see implementer output in the orchestrator's gate, after agent-exec committed it to `wt/<slug>`. Today the gate runs before anything is committed and never sees it. Commit-then-gate is accepted. The commit is on the unit branch only, and a failing hook sends the followup back before review. The two profile sentences that say the hook runs "before the commit lands" are reworded to match.
2. **`gate.sh` lints the working tree.** The shell file list becomes `git ls-files --cached --others --exclude-standard '*.sh'`, keeping only entries that exist as regular files (`[[ -f ]]`). Deleted-but-tracked files drop out, and new untracked, non-ignored scripts are checked before anything commits them.
3. **Contract and templates state the recipe once.**
   - `harness/AGENTS.md` rule 2 adds: do not stage, commit or otherwise write git metadata; use plain `mv`/`rm`; the orchestrator commits.
   - `handoff.tpl`: "When done" becomes: run the gate, then print the summary. The commit and demo steps go, and so does "paste the demo output" from the summary. Add a line after the footprint: every edit the plan names is authorized; stop only for an edit outside the footprint. Add one line: nothing is committed while you work, so anything that reads `HEAD` (`git archive`, `git show HEAD:…`) won't see your changes.
   - `followup.tpl`: drop "commit the fix" and the demo re-run. Its output block covers a failing gate or demo: `{{GATE_OUTPUT}}` becomes `{{FAILURE_OUTPUT}}`, with a heading to match.
   - `docs/prompts/handoff.tpl`: drop "Commit your work"; agent-exec commits.
4. **`/2-implement`.**
   - Step 3 notes that agent-exec commits the dispatch's changes. If agent-exec exits non-zero, for example because a pre-commit hook rejected the commit, stop and escalate to the Owner with its output. Don't gate a branch that is missing the implementer's work.
   - Step 6 changes from "commit if the implementer didn't" to: run `cd "$WT" && harness demo <slug>`, append its output to `work/<slug>/notes.md` in the primary checkout, then run `harness worktree sync-artifacts <slug>` from the repo root so the branch records it.
   - Demo exit 0 continues to `/3-review`. Exit 2 is a plan or tooling error: stop and escalate to the Owner.
   - A demo that exits 1 with `demo dirtied the worktree` is also escalated to the Owner, not sent to followup. The next agent-exec would commit the leftovers, and the re-run demo would then pass.
   - Demo exit 1 feeds step 5's loop. One iteration is: render `followup.tpl` with the failing output (gate or demo), dispatch with `--allow-noop`, run `sync-artifacts`, run the gate, and run the demo only once the gate is green.
   - Each followup dispatch counts once toward `gate.max_retries`, whether the gate or the demo triggered it. After that, escalate to the Owner.
   - Fan Mode: step 5 runs step 6, including the demo, on the adopted `wt/<slug>` before `/3-review`. The 0-survivor path uses the same gate-or-demo followup loop.
5. **ARCHI.md** gets targeted edits on the branch (Decision 2026-09-01) to every line describing who commits implementer work, when the demo runs, or the shellcheck file list:
   - the `agent-exec.sh` and `fan-exec.sh` descriptions in the `harness/scripts/` bullet (fan's own commit now matters only after a failed dispatch);
   - the `harness demo` entry point ("after the implementer gates and commits");
   - Verification's "shellcheck over all tracked `*.sh`";
   - the case lists in the `test-scripts.sh` bullet and in Verification, which get the new auto-commit, `work/` exclusion, registry, fan-subject and working-tree-lint cases appended.

Alternative rejected: adding the worktree git dir as a writable sandbox root in `implementer.command`. It is codex-specific, it widens the sandbox to the primary checkout's `.git`, and it does nothing for demos that need the network.

`fan-exec.sh` keeps its code. Its own `commit_sample_changes` also commits after a *failed* dispatch, which the 0-survivor adopt path relies on. After a successful dispatch, `agent-exec` has already committed the sample's work under the `Implementer changes for …` subject, minus the seeded `work/`, so `commit_sample_changes` finds nothing to stage. The fan test that asserts the `Fan sample implementation for …` subject on a successful non-committing sample changes to the new subject. Its `work/demo` exclusion assertions stay as they are and now pin agent-exec's exclusion.

## Footprint

Files to modify:
- `harness/scripts/agent-exec.sh`
- `harness/scripts/gate.sh` (shell file list only)
- `harness/tests/test-scripts.sh`
- `harness/AGENTS.md` (rule 2 only)
- `harness/skills/2-implement/SKILL.md` (steps 3, 5, 6; Fan Mode steps 3 and 5)
- `harness/profiles/machine-learning.md` and `harness/profiles/work.md` (the "before the commit lands" sentence only)
- `harness/skills/2-implement/prompts/handoff.tpl`
- `harness/skills/2-implement/prompts/followup.tpl`
- `harness/skills/docs/prompts/handoff.tpl` ("When done" only)
- `ARCHI.md` (the lines Approach step 5 names, and only those)

Files NOT to touch:
- `harness/scripts/fan-exec.sh`: its failed-dispatch commit is load-bearing (see Approach).
- `config.yaml`: no sandbox widening.
- `harness/agents/code-reviewer.md`: the reviewer still re-runs the demo cold.
- `PLAN.md`, `VERSION`, `CHANGELOG.md`.

## Acceptance criteria

- [ ] A zero-exit dispatch that modifies, adds and deletes files without committing leaves the worktree with HEAD advanced by exactly one commit, subject `Implementer changes for wt/<slug>`, and an empty `git status --porcelain`. `git show --no-renames --name-status` shows the commit contains the deletion and the new file. This is a new test in `test-scripts.sh` (the existing `dirty` fixture extended or a new mode), pinned by mutation: with the commit removed from agent-exec, the mutation is confirmed landed and the test fails.
- [ ] In repo mode, a dispatch that leaves both an untracked `work/<x>/` file and a code change commits only the code change; `work/<x>/` stays untracked. A dispatch that only touched `work/` exits 0 with no new commit. In registry mode, a changed file under the project's own `work/` *is* committed. These are new tests; the exclusion is pinned by a mutation that is confirmed landed (exclusion removed, so the repo-mode test fails).
- [ ] Unchanged behavior: an implementer that commits gets no extra commit. This is a new assertion on the `commit` case: `git rev-list --count` on the worktree HEAD goes up by exactly 1. The existing tests still pass: `nothing` exits 1 with `no new commit`, and `--allow-noop` makes no commit.
- [ ] New test, which needs a new failing mode in `setup_agent_exec_fixture`'s stub implementer: a dispatch that leaves changes and exits non-zero makes agent-exec exit with that status and commit nothing.
- [ ] Fan: "fan dispatch auto-commits non-committing sample work" passes with its subject assertion changed to `Implementer changes for wt/demo-fan-2`. It still asserts the sample branch has no `work/demo` entries. "fan adopt preserves auto-committed sample work…" passes unchanged, with `work/demo/plan.md` as the only `work/demo/` path. No other fan test changes.
- [ ] With a tracked `*.sh` deleted but unstaged, the gate's shellcheck step passes. With an untracked, non-ignored `*.sh` that fails shellcheck, the gate fails and names it. A gitignored failing `*.sh` is not checked. These are new gate tests, each guard pinned by a mutation that is confirmed landed: `-f` filter removed, `--others` removed, `--exclude-standard` removed.
- [ ] `grep -nE 'Commit your work|commit the fix|harness demo|demo output' harness/skills/2-implement/prompts/*.tpl harness/skills/docs/prompts/handoff.tpl` prints nothing.
- [ ] `handoff.tpl` contains the plan-named-edits authorization line and the `HEAD`-doesn't-see-your-changes line. `AGENTS.md` rule 2 forbids staging and committing and names plain `mv`/`rm`.
- [ ] `/2-implement` step 6 runs `harness demo` from the orchestrator, appends its output to `notes.md`, and runs `sync-artifacts` afterward. Exit 1 goes into the followup loop (followup, `sync-artifacts`, gate, then demo on a green gate; each dispatch counts once toward `gate.max_retries`). Exit 2, a dirtying demo (`demo dirtied the worktree`), and a non-zero agent-exec each go to the Owner. No step tells the orchestrator to commit implementer work by hand.
- [ ] `harness archi-fresh wt/codex-worktree-commit` exits 0. A diff inspection of `ARCHI.md` shows that the `agent-exec.sh` and `fan-exec.sh` descriptions, the `harness demo` entry point, and Verification's shellcheck line all describe the new behavior.
- [ ] `harness gate` passes in the worktree, run as the worktree's own copy (`bash harness/bin/harness gate`).

## Release

Release note: `harness agent-exec` commits whatever a successful dispatch leaves uncommitted, and `/2-implement` runs the demo itself. Implementers never touch git, the gate lints the working tree (untracked scripts in, deleted ones out), and the handoff authorizes every edit the plan names.

## Demonstration

Runs this worktree's own `harness` against a scratch repo. A stub implementer deletes a tracked script and adds a new one without committing. The gate then runs over an unstaged deletion and over an untracked failing script.

```sh
H="$PWD/harness/bin/harness"
T=$(mktemp -d) || exit 1
git init -q -b main "$T/r" || exit 1
cd "$T/r" || exit 1
git config user.email demo@example.com; git config user.name Demo
printf '#!/usr/bin/env bash\necho keep\n' >keep.sh
printf '#!/usr/bin/env bash\necho old\n' >old.sh
cat >config.yaml <<'EOF'
implementer:
  command: 'cat >/dev/null; rm old.sh; printf "#!/usr/bin/env bash\necho new\n" >new.sh'
EOF
git add -A && git commit -qm init || exit 1
echo handoff >"$T/handoff.md"
"$H" agent-exec "$PWD" "$T/handoff.md" || exit 1
echo "subject: $(git log -1 --format=%s)"
echo "status: [$(git status --porcelain)]"
[[ $(git log -1 --format=%s) == "Implementer changes for main" && -z $(git status --porcelain) ]] || exit 1
git show --no-renames --name-status --format= HEAD
rm keep.sh
"$H" gate >/dev/null 2>&1 && echo "gate with unstaged deletion: pass" || exit 1
printf '#!/usr/bin/env bash\nrm $1\n' >bad.sh
if "$H" gate >"$T/gate.out" 2>&1; then echo "gate missed untracked bad.sh"; exit 1; fi
grep -q 'bad.sh' "$T/gate.out" && echo "gate with untracked bad.sh: fail (names bad.sh)" || exit 1
```
Expected: `subject: Implementer changes for main`, `status: []`, `A new.sh` and `D old.sh`, then `gate with unstaged deletion: pass` and `gate with untracked bad.sh: fail (names bad.sh)`.

## Review

**Round 1 — REVISE.** All five findings applied:
1. **HIGH:** agent-exec's `add -A` would have swept fan's seeded `work/<slug>/` into sample commits and broken two fan tests. Fixed: repo mode excludes `work/`, registry mode doesn't, a `diff --cached` guard was added, the fan subject-assertion change is stated, and the exclusion is pinned.
2. **MEDIUM:** the demo/followup sequence and the `notes.md` sync were spelled out.
3. **MEDIUM:** the ARCHI footprint was widened to the demo entry point, the fan description and Verification.
4. **LOW:** the `--exclude-standard` mutation was added.
5. **LOW:** committing gate byproducts was accepted in one line.

**Round 2: REVISE.** The reviewer patched a scratch clone and ran the suite: 230 pass. The 2 failures were the fan subject assertion this plan already names, plus the gate test that runs it. All round-1 fixes were verified. Applied:
1. **MEDIUM:** rename detection made the demo print `R068`. Fixed with `--no-renames` in the demo and the criterion, and the demo now fails on a missing commit.
2. **LOW:** Fan Mode now runs step 6 (demo included) and the gate-or-demo followup loop.
3. **LOW:** the ARCHI test-case lists may be appended to.
4. **LOW:** commit-then-gate for tracked-file hooks is accepted, and the two profile sentences are in the footprint.
5. **LOW:** the gitignore claim is corrected.
6. **LOW:** the non-zero-dispatch assertion is labeled as a new fixture mode.

**Round 3: REVISE.** The reviewer patched a scratch clone. The demo printed exactly the Expected lines, and it fails when either script is unpatched. With the fan assertion updated, all 232 tests pass. Applied:
1. **MEDIUM:** a dirtying demo would have been laundered into a pass by the next auto-commit. Fix: it now escalates to the Owner.
2. **LOW:** the HEAD-count assertion on the `commit` case is now stated as new.
3. **LOW:** "paste the demo output" is dropped, and the grep catches it.
4. **LOW:** a non-zero agent-exec escalates to the Owner.
5. **LOW:** the `work/`-edits limit is noted.

Owner approval (2026-10-19): approved over the round-3 REVISE. No CRITICAL or HIGH findings were open, and all round-3 findings were applied.
Plan verdict: APPROVE
