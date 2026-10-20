# Stacked units: branch a unit from its unmerged parent and review only its own diff

**Slug:** stacked-units · **Date:** 2026-10-19 · **Status:** approved

## Goal

At work, a unit often builds on another whose PR is still waiting for approval, and the two share files (memory `work-environment-constraints`; need confirmed by the Owner 2026-10-19). Today that can't be expressed:

- `harness worktree add` always branches from `origin/main` (`harness/scripts/worktree.sh:59-68`), so unit B can't see unit A's changes.
- Suppose B is branched from `wt/A` by hand. Both reviews diff `origin/main...wt/B` (`harness/skills/3-review/SKILL.md:12`, `harness/scripts/codex-review.sh:104-112`), so B's review includes all of A's diff.
- In repo mode, `release.sh` would release B with A's commits inside. Its only base check is that `origin/main` is an ancestor (`release.sh:161-168`).

Done = a plan can declare `Stacked on: <parent>`. `worktree add` then branches from `wt/<parent>`. Both review paths diff against the parent while it is unmerged, and against `origin/main` once it has landed by merge commit or fast-forward (work's IT-enforced merge commits). Review stays exact even after the parent is amended, squashed or rebased. Repo-mode release refuses a stacked unit that still carries parent commits. Once the parent has landed, the refusal prints the exact rebase command. Trains (several units in one PR) stay in `pr-release`.

## Approach

1. **Plan field.** An optional whole line `Stacked on: <parent-slug>` in the plan's header block, after the title and before the first `## ` heading. `plan.tpl` gets it as an optional line. It is the single source of truth: no CLI flag, so add, review and release all read the same fact.
2. **`harness/scripts/lib/stack.sh`** (sourced; Bash 3.2-safe):
   - `stack_parent <slug>` reads the plan from `wt/<slug>:work/<slug>/plan.md` when that branch exists in repo mode and carries the file. Otherwise, including a branch without the plan file, it reads `$PRIMARY_ROOT/work/<slug>/plan.md` in repo mode (not `$STATE_DIR`, which is the current worktree when this runs from a linked worktree), or `$STATE_DIR/work/<slug>/plan.md` in registry mode, the same lookup `state.sh` uses. Only lines before the first `^## ` heading are scanned. It prints the slug from the first `^Stacked on: [a-z0-9-]+$` line there, or nothing.
   - `stack_fork <slug> <parent>` prints the **fork point** `F` = `git merge-base --fork-point wt/<parent> wt/<slug>`. That is git's built-in: the best common ancestor among `wt/<parent>`'s tip and every reflog entry. It exits 1 with no output when there is none and 128 or more on error.
     - It is not "the newest reflog entry that is an ancestor of the child". `git reset` writes reflog entries that point at older commits, and that rule picks them (plan-review round 5, finding 1).
     - `F` is the exact parent version the child contains, however the parent has been rewritten since: amended, squashed, rebased, or with conflicts resolved.
     - It replaces both the round-2 `git cherry` patch-id check and the round-3 plan-commit guard (plan-review round 4, finding 5).
   - `review_base <slug>` picks the main ref, which is `origin/main` after a best-effort fetch, or `main` when no `refs/remotes/origin/main` exists (the existing fallback). Then:
     - With no parent, it prints the main ref.
     - With a parent, it requires `wt/<parent>` and `wt/<slug>`. If either is missing it returns 2, never a silent fallback that would pollute the diff. For a missing parent, the error names the way out and the plan copy that is actually read: `wt/<parent> missing; if <parent> has landed, delete the Stacked on: line from wt/<slug>:work/<slug>/plan.md and commit that in the worktree`. In registry mode it names the state-dir plan instead.
     - No `F`, or `F` an ancestor of the main ref: it prints the main ref. The child carries no unlanded parent commits.
     - `F` an ancestor of `wt/<parent>`: it prints `wt/<parent>`.
     - Otherwise (the parent was rewritten after the child branched): it prints `F`'s SHA. On stderr it adds `note: <parent> was rewritten since <slug> branched; to pick it up: git -C <wt> rebase --onto wt/<parent> <F>`.
     - In each case, `git diff <base>...wt/<slug>` is exactly the child's own change.
     - `merge-base --is-ancestor` exits 1 for "no" and 128 or more for an error. Any git error returns 2 with git's message; it never aborts through `set -e` with a different status.
     - Limit: the reflog is local and expires, but only when `git gc` runs. Unreachable entries expire after 30 days (`gc.reflogExpireUnreachable`) and reachable ones after 90 (`gc.reflogExpire`). The same loss happens when a stack moves to another clone. Then `F` may be wrong or missing:
       - The review base may be `wt/<parent>` or the main ref.
       - The diff shows old parent commits, where a reviewer can see them.
       - A printed restack command may conflict.
       - Release still refuses while the parent has not landed (step 5), because that check doesn't use the reflog.
       - The ARCHI line states this limit.
     - What that means per parent state:
       - Unmerged, including after it gains commits: `F` is on `wt/<parent>`, so the base is `wt/<parent>`.
       - Merged by merge commit or fast-forward: `F` is on main, so the base is the main ref.
       - Rebase-merged (this repo): `F` is on `wt/<parent>`, off main, so the base is `wt/<parent>`. Release refuses with the restack command (step 5).
       - Restacked onto main after any landing: no reflog entry of `wt/<parent>` is an ancestor of the child, so the base is the main ref.
       - Rewritten while unmerged (amend, squash, rebase): `F` is an old tip, so the base is `F`. The stderr note gives the command that picks up the rewrite, after which the base is `wt/<parent>`.
       - Rewritten, then landed: `F` is off main and off `wt/<parent>`, so the base is `F`. Release refuses with the restack command.
3. **`harness worktree`:**
   - `add <slug>`: if `stack_parent` names a parent, branch from `wt/<parent>` instead of `origin/main`. `wt/<parent>` must exist locally; otherwise exit 1 naming it, and create no branch. The resume path (branch exists) is unchanged.
   - New `base <slug>`: prints `review_base`, exiting with its status.
4. **Review.**
   - `codex-review.sh` takes its base from `review_base` and calls `die2` when it fails. It writes no artifact in that case.
   - `/3-review` step 1 first captures `base=$(harness worktree base <slug>)`. On a non-zero exit it stops and reports. Then it diffs `"$base...wt/<slug>"`. Both keep the `work/<slug>` exclusion.
5. **Release.** `release.sh` adds `check_stack_landed`, called **before** the first `check_origin_main_ancestor`, so a stale-base message can never prompt a plain `git rebase origin/main` that carries the parent along.
   - If `origin/main:work/<parent>/plan.md` is absent (a unit's plan reaches main only with its release), the check dies with `stacked on <parent>, which has not landed on origin/main; release <parent> first`. It does not call `review_base`, so no reflog loss can turn an unlanded parent into a pass (round 5, finding 2).
   - Otherwise it calls `review_base <slug>`:
     - Failure: it dies with that message.
     - `origin/main`: it passes.
     - Anything else: it dies with `stacked on <parent>, which has landed; restack first: git -C <wt> rebase --onto origin/main <F>`, with `<wt>` and `<F>` filled in. Because `F` is the exact fork point, the command replays only the child's commits, whatever happened to the parent.
6. **`fan-exec.sh dispatch`** refuses a stacked plan with exit 2, `fan mode does not support stacked units`. Its sample worktrees are named `<slug>-fan-N`, so `worktree add` would never find the plan's parent. Fan defaults to 1, so this is a guard, not a feature.
7. **ARCHI.md** gets targeted edits for the `worktree` subcommands, `lib/stack.sh`, and the review and release base (Decision 2026-09-01).

Rejected:
- A `--on <parent>` flag on `worktree add`. Review and release would then need the parent again from somewhere; the plan line is that store.
- A `worktree restack` command (plan-review round 1, finding 7). The confirmed need is work's merge-commit path, where no restack is needed. In this repo, the release refusal prints the one command. Add `restack` when repo-mode stacking actually happens here.

`state.sh` is unchanged. A stacked unit moves through the same stages, and the release refusal names the next action.

## Footprint

Files to modify:
- `harness/scripts/lib/stack.sh` (new)
- `harness/scripts/worktree.sh` (`add` base choice; new `base`; usage strings)
- `harness/scripts/codex-review.sh` (base selection only)
- `harness/scripts/release.sh` (`check_stack_landed` and its call)
- `harness/scripts/fan-exec.sh` (stacked-plan refusal in `dispatch`)
- `harness/tests/test-scripts.sh`
- `harness/skills/3-review/SKILL.md` (step 1 only)
- `harness/skills/1-plan/prompts/plan.tpl` (the optional `Stacked on:` line)
- `README.md` (one Layout line for `lib/stack.sh`)
- `ARCHI.md` (targeted edits only)

Files NOT to touch:
- `harness/scripts/state.sh`, `harness/scripts/agent-exec.sh`, `harness/scripts/gate.sh`
- `PLAN.md`, `VERSION`, `CHANGELOG.md`

## Acceptance criteria

Each test is in `test-scripts.sh`, uses a hermetic fixture with a local bare `origin`, and pins its guard with a mutation that is confirmed to have landed (`knowledge/silent-no-op-hazards.md`).

Landings are done in a separate clone of the bare origin, never in the primary checkout. A rebase landing first pushes an unrelated commit to origin `main`, then cherry-picks, and asserts `! git merge-base --is-ancestor wt/p origin/main`, which proves the SHAs were rewritten.

- [ ] **Add.**
  - With `Stacked on: p` in the header of `work/c/plan.md` and an existing `wt/p`, `worktree add c` creates `wt/c` with `wt/p`'s tip as an ancestor.
  - Without the line, the base is `origin/main`, unchanged (existing tests pass).
  - With the line and no `wt/p`, add exits 1, names `wt/p`, and creates no branch.
  - A `Stacked on: p` line that appears only below a `## ` heading is ignored.
- [ ] **Base, parent unmerged.** `worktree base c` prints `wt/p`, and `git diff "$(worktree base c)...wt/c"` contains only the child's file. This still holds after `wt/p` gains a commit.
- [ ] **Base, merge-commit landing.** After `wt/p` lands on origin `main` via `git merge --no-ff`, `worktree base c` prints `origin/main`, and the three-dot diff contains only the child's file. Mutation: drop the "`F` on main means the main ref" branch, and this test fails.
- [ ] **Base, rebase landing.** After the rebase landing described above, `worktree base c` prints `wt/p`, and the diff contains only the child's file. Mutation: drop the "`F` reachable from `wt/<parent>` → `wt/<parent>`" branch, and this test fails.
- [ ] **Base, parent rewritten while unmerged.** Three fixtures:
  - only the tip is amended, so the plan commit is untouched;
  - every parent commit, including `Record plan for p`, is rewritten with changed content (`git reset --soft` to the parent's base, then a new commit);
  - `wt/p` is rebased onto an advanced origin `main`.

  Two more:
  - a partial squash (`git reset --soft HEAD~1`, then recommit);
  - a dropped tip (`git reset --hard HEAD~1`).

  In each, `worktree base c` exits 0 and prints a SHA that is neither `wt/p` nor `origin/main`; the diff contains only the child's file; and stderr carries `rebase --onto wt/p`. Running that printed command makes the base `wt/p`, with a child-only diff and no conflict.

  One extra fixture covers the child after it is restacked onto a rewritten parent, with the parent then rewritten again. Same expectations.

  Mutations:
  - Replace `--fork-point` with the current tip only: the amended-tip fixture fails.
  - Replace `--fork-point` with a "newest reflog entry that is an ancestor" walk: the `reset --soft` fixture fails.
- [ ] **Missing refs and errors.** With `wt/p` deleted, `worktree base c` exits 2. Its message contains `delete the Stacked on: line from wt/c:work/c/plan.md`. With `wt/c` missing, it also exits 2.
- [ ] **Plan fallback.** If `wt/c` exists without `work/c/plan.md`, `stack_parent` reads the primary copy.
- [ ] **Registry mode.** The fixture is registered under a temporary `HARNESS_HOME/projects/<x>/project`, with plans only in the state dir. `worktree add c` branches from `wt/p`, and `worktree base c` prints `wt/p`, then `origin/main` after a `--no-ff` landing.
- [ ] **Release.** Each release fixture's plan carries both `Code-review verdict: APPROVE` and `Codex-review verdict: APPROVE`, because `check_verdict` runs first (`release.sh:233`). "Gets past `check_stack_landed`" means release's stderr has no `stacked on`. `release.sh` exits non-zero before any version change in each of these cases:
  - Stacked, parent unmerged: dies with `has not landed`.
  - The same, with origin `main` advanced by an unrelated commit: still `has not landed`, not `is stale`.
  - Parent rewritten while unmerged: `has not landed`.
  - Parent unmerged with its reflog fully expired (`git reflog expire --expire=now --expire-unreachable=now refs/heads/wt/p`): still `has not landed`.
  - Mutation: invert the `origin/main:work/<parent>/plan.md` presence test, and the unmerged case and the rebase-landed case each get the other's message.
  - Parent rebase-landed: dies with `restack first: git -C` and `F`'s SHA. After running the printed command, `worktree base c` prints `origin/main`, the diff is child-only, and release gets past `check_stack_landed`.
  - Parent amended at the tip, then rebase-landed: the printed restack command applies without conflict, and the base is then `origin/main`.
- [ ] **Codex review.** With a stub reviewer command that captures its stdin, `codex-review.sh` on a stacked unit sends a `--- DIFF (wt/p...wt/c` header and no parent-only file. With `wt/p` deleted, it exits 2 and writes no `codex-review.md`.
- [ ] **Fan.** `fan-exec dispatch` on a stacked plan exits 2 before creating any worktree.
- [ ] **`/3-review` step 1.** It captures `harness worktree base <slug>`, stops on a non-zero exit, and diffs against the captured base. `grep -nE '(origin/)?main\.\.\.wt' harness/skills/3-review/SKILL.md` prints nothing.
- [ ] **Freshness and gate.** `harness archi-fresh wt/stacked-units` exits 0, and `harness gate` passes in the worktree using the worktree's own copy (`bash harness/bin/harness gate`).

## Release

Release note: A plan can declare `Stacked on: <parent>`. `harness worktree add` then branches from the unmerged parent. `harness worktree base` gives both reviews the exact fork point as their diff base until the parent lands, even if the parent was rewritten. Release refuses a unit that still carries its parent's commits and prints the restack command.

## Demonstration

This runs the worktree's own `harness` against a scratch repo with a local bare origin. It walks the work path:
1. Stack `c` on `p`.
2. Show the review base and that the diff holds only the child's file.
3. Amend `p` after review feedback and force-push it. Show that the base becomes the exact fork point and the diff stays child-only.
4. Land the amended `p` with a merge commit from a separate clone. Show that the diff is still child-only.

```sh
H="$PWD/harness/bin/harness"
T=$(mktemp -d) || exit 1
export WORKTREES_DIR="$T/wts" HARNESS_HOME="$T/hh"
export GIT_AUTHOR_NAME=Demo GIT_AUTHOR_EMAIL=demo@example.com GIT_COMMITTER_NAME=Demo GIT_COMMITTER_EMAIL=demo@example.com
git init -q --bare -b main "$T/origin.git" || exit 1
git clone -q "$T/origin.git" "$T/r" 2>/dev/null || exit 1
cd "$T/r" || exit 1
echo base >base.txt && git add -A && git commit -qm init && git push -q origin main || exit 1
mkdir -p work/p work/c
printf '# P\n\n**Slug:** p\n' >work/p/plan.md
printf '# C\n\n**Slug:** c\nStacked on: p\n' >work/c/plan.md
P=$("$H" worktree add p) || exit 1
echo parent >"$P/parent.txt" && git -C "$P" add -A && git -C "$P" commit -qm parent && git -C "$P" push -q origin wt/p || exit 1
C=$("$H" worktree add c) || exit 1
echo child >"$C/child.txt" && git -C "$C" add -A && git -C "$C" commit -qm child || exit 1
b=$("$H" worktree base c) || exit 1
echo "base while p unmerged: $b"
echo "diff files: $(git diff --name-only "$b...wt/c" -- ':(exclude)work/c' | tr '\n' ' ')"
echo parent-v2 >"$P/parent.txt" && git -C "$P" commit -qa --amend --no-edit && git -C "$P" push -qf origin wt/p || exit 1
b=$("$H" worktree base c 2>"$T/note") || exit 1
[[ "$b" != wt/p && "$b" != origin/main ]] && grep -q 'rebase --onto wt/p' "$T/note" && echo "base after p amended: fork-point SHA (note printed)" || exit 1
echo "diff files: $(git diff --name-only "$b...wt/c" -- ':(exclude)work/c' | tr '\n' ' ')"
git clone -q "$T/origin.git" "$T/land" 2>/dev/null || exit 1
git -C "$T/land" merge -q --no-ff -m "Merge wt/p" origin/wt/p && git -C "$T/land" push -q origin main || exit 1
b=$("$H" worktree base c 2>/dev/null) || exit 1
[[ "$b" != wt/p && "$b" != origin/main ]] && echo "base after merge-commit landing of amended p: fork-point SHA" || exit 1
echo "diff files: $(git diff --name-only "$b...wt/c" -- ':(exclude)work/c' | tr '\n' ' ')"
```
Expected: `base while p unmerged: wt/p`, then `diff files: child.txt`, `base after p amended: fork-point SHA (note printed)`, `diff files: child.txt`, `base after merge-commit landing of amended p: fork-point SHA`, and `diff files: child.txt`. On the work path, a parent PR amended after review and then merged leaves the child's review exact.

## Review

**Round 1: REVISE.** All findings applied, with the reviewer's optional simplification taken:
1. **HIGH.** The demo failed (`cherry-pick -q` is invalid, there was an untracked-plan conflict, and same-second cherry-picks give identical SHAs) and never showed the work path. It was rewritten around the merge-commit path, with the landing done in a separate clone.
2. **The rebase-landing fixture had the same SHA hazard.** Origin now advances with an unrelated commit first, and a non-ancestor precondition is asserted.
3. **Registry mode was untested.** A registry-mode criterion was added.
4. **A failed base lookup produced a polluted `HEAD...` diff.** `/3-review` now captures and stops; `codex-review.sh` exits through `die2` with no artifact.
5. **Release check order and message.** `check_stack_landed` runs before the ancestor check, the message branches on whether the parent has landed, and an advanced-origin criterion was added.
6. and 7. **Restack mechanics and the "cut restack" option.** `restack` was cut. In its place, the release refusal prints the exact `rebase --onto` command.
8. **LOW.** The `Stacked on:` match is limited to the header block, with a test.

**Round 2: REVISE.** The reviewer dry-ran the demo's git steps and they matched. All eight round-1 fixes were verified. Applied:
1. **HIGH: parent rebased while unmerged.** The rule fell back to `origin/main` and returned a polluted diff. Fix: a `git cherry` check now refuses with a `rebase --onto wt/<parent>` command. The patch-id limit is stated, and a criterion plus mutation were added.
2. **MEDIUM: stranded child.** When a parent branch has been deleted, the error now names the way out (delete the `Stacked on:` line).
3. **MEDIUM: untested restack command.** The printed restack commands are now executed in tests.
4. **LOW: plan fallback.** `stack_parent` falls back to the primary or state-dir plan when the branch doesn't carry the plan file.
5. **LOW: grep check.** The pattern now also catches the `main...wt` fallback text.
6. **Optional simplification, declined.** The reviewer suggested a single release refusal. The two-message refusal stays: in this repo the parent always lands by rebase, so a stacked unit here always needs the printed command, and the extra branch is a few lines.

**Round 3: REVISE.** The reviewer dry-ran all five parent states. Applied:
1. **HIGH:** the `git cherry` range used `M` and also matched main's own rebased copy of the parent, so a unit whose parent landed by rebase looped between two restack commands. Fixed: the range now starts at `merge-base <mainref> wt/<slug>` (the reviewer confirmed it gives the right answer in all five states). The post-restack state is listed, and a mutation was added.
2. **MEDIUM:** the patch-id limit covers any content rewrite (amend, squash), not just conflict resolution, which broke the Goal's release promise in repo mode. Fixed: a repo-mode `git log origin/main..wt/<slug> -- work/<parent>` guard in `check_stack_landed`, plus an amended-parent criterion. The limit is now stated honestly.
3. **LOW:** README Layout line added to the footprint.
4. **LOW:** caveat about cherry-picked shared fixes added, and git failures in `review_base` now return 2 explicitly.

**Round 4: REVISE.** The reviewer dry-ran nine parent states. The round-3 cherry range and the README line held. Applied:
1. **HIGH.** The amended-parent release criterion couldn't fail: an amended tip leaves the plan commit alone, so the guard never fired.
2. **MEDIUM.** A tip rewrite leaked old parent commits into review and release on the work path.
3. **MEDIUM.** `<X>` was wrong under a partial patch-id match.
4. **LOW.** Change (c) had no test.
5. **The fix for 1–3: root cause, the reviewer's option 5.** Findings 1–3 share one root cause: once the parent is rewritten, the fork point can't be recovered from the refs. `stack_fork` now takes the newest reflog entry of `wt/<parent>` that is an ancestor of the child. The review base is then `wt/<parent>`, the main ref, or that exact fork point, and every printed restack command uses it. This replaced the `git cherry` check and the plan-commit guard. The reflog-expiry limit is stated, and the criteria were rewritten around the three rewrite fixtures plus the rewritten-then-landed restack. Test 4's error case is now a missing `wt/c`.
6. **LOW.** The missing-parent message now names the branch copy of the plan, and says to commit the edit in the worktree.

**Round 5: REVISE.** The reviewer dry-ran 13 parent states using linked worktrees and confirmed that every reflog write the plan relies on happens. Applied:
1. **HIGH.** The "newest ancestor reflog entry" rule picks `reset` entries, so `reset --soft`, a partial squash and a dropped tip all leaked parent commits. Fixed: `F` is now `git merge-base --fork-point`, which was correct in all 13 states. Squash and dropped-tip fixtures plus a newest-walk mutation were added.
2. **MEDIUM.** Release's "has not landed" check depended on the reflog. It now refuses whenever the parent's plan is absent from `origin/main`, without calling `review_base`. An expired-reflog criterion was added.
3. **MEDIUM.** The expiry limit was restated: 30 days for unreachable entries, 90 days for reachable ones, and only when gc runs. The base may then be `wt/<parent>` or the main ref, and a restack may conflict.
4. **LOW.** Mutations were added for the rebase-landing branch and the plan-present test. "Gets past" now has an observable, and the fixtures need the APPROVE lines.
5. **LOW.** The demo now amends and force-pushes `p` after review, then merge-lands it, so it exercises the fork-point rule on the work path.
6. **LOW.** The primary-plan fallback now uses `$PRIMARY_ROOT`.

Owner approval (2026-10-19): approved over the round-5 REVISE. All six round-5 findings were applied, including the reviewer's own `--fork-point` fix for the HIGH; no round 6 was run.
Plan verdict: APPROVE
