# Stacked units follow-ups

**Slug:** stacked-units-followups · **Date:** 2026-11-26 · **Status:** approved

## Goal

`stacked-units` (v2026.10.9) shipped stacking without a restack command and deferred two MEDIUMs (`work/stacked-units/deferrals.md`). Its retro filed the rest as the `stacked-units-followups` candidate in `PLAN.md`. The Owner asked for this unit on 2026-11-26. Four problems remain:

1. **No single restack command.** The user has to know which printed command applies.
   - `review_base`'s note for a rewritten parent says `git -C <wt> rebase --onto wt/<parent> <F>`.
   - Release's landed-parent refusal says `rebase --onto origin/main <F>`.
   - Once a rewritten parent has *landed*, the note's command points at the wrong target. Only release's command is right, and it shows up only at release time.
2. **No fork point is silent** (round-3 MEDIUM). When `git merge-base --fork-point` exits 1 while `wt/<parent>` is unmerged, `review_base` prints the main ref with no note, and the review diff carries the parent's commits.
3. **A near-miss `Stacked on:` line is silent.** `stack_parent` matches only `^Stacked on: [a-z0-9-]+$` in the header block. `stacked on: p`, `Stacked on p`, `**Stacked on:** p` and `Stacked on: P` all leave the unit silently unstacked.
4. **A deleted parent after a rebase landing** (round-1 MEDIUM). `review_base` says to delete the `Stacked on:` line. Its fork history is gone by then, so a plain `git rebase origin/main` can carry the old parent commits along or conflict on them.

Done means four things:
- `harness worktree restack <slug>` moves the child onto whatever its parent's state needs, in one command.
- The existing rewritten-parent note and the release refusals name it.
- A missing fork point and a near-miss header line warn on stderr.
- The deleted-parent message names the hand remedy.

## Approach

### `harness worktree restack <slug>`

The command lives in `worktree.sh`, with its logic in `lib/stack.sh`.

**Main ref, resolved first.** `mainref` is resolved as in `review_base`: `integration_ref`, otherwise `origin/main` after a fetch, otherwise `main`.

**Preconditions, in order.** Each failure exits 1 with the substring shown:
1. The plan declares a parent through `stack_parent` (`not stacked`).
2. `wt/<slug>` is checked out in a linked worktree (`no worktree for`).
3. `wt/<parent>` exists. Otherwise: `wt/<parent> is gone, so the fork point is lost; drop the parent's commits by hand: git -C <wt> rebase -i <mainref>`.
4. That worktree is clean (`has uncommitted changes`).

**Target.** The target is `mainref` when the parent has landed, otherwise `wt/<parent>`. "Landed" means:
- **Repo mode:** `<mainref>:work/<parent>/plan.md` exists. This is the test `check_stack_landed` applies to `origin/main`.
- **Registry mode:** `wt/<parent>`'s tip is an ancestor of `mainref`. Work merges with merge commits (`work-slim`), and this test is false after a squash or rebase merge. The plan and ARCHI state that limit. In that case restack targets `wt/<parent>`, and the hand remedy is the same `rebase -i <mainref>`.

**Fork.** `F=$(stack_fork <slug> <parent>)`. An exit above 1 is a git error and returns 2, as in `review_base`. If it exits 1, restack refuses: `no fork point for wt/<slug> on wt/<parent>; rebase by hand: git -C <wt> rebase -i <target>`.

**Nothing to do.** It is nothing to do only when `git merge-base --is-ancestor <target> wt/<slug>` succeeds, meaning the child already contains the target. That is the untouched-parent case. It prints `wt/<slug> is already on <target>` and exits 0. In registry mode, when the target is `wt/<parent>`, it also prints `if <parent> was squash- or rebase-merged, drop its commits by hand: git -C <wt> rebase -i <mainref>`, because the landed test can't see those merges. Every other case rebases:
- the parent was rewritten;
- the parent gained commits;
- the parent landed by rebase, by merge commit, or by fast-forward after a rewrite.

**Rebase.** The upstream `U` depends on where `F` sits:
- if `F` is an ancestor of the target, `U=$(git merge-base <target> wt/<slug>)`, which is a plain rebase onto the target;
- otherwise `U=F`.

It runs `git -C <wt> rebase --onto <target> <U>`, which replays only the child's own commits. A second restack after a rebase landing hits the first case. There, `wt/<slug>` holds none of `wt/<parent>`'s commits, so `--fork-point` falls back to the parent's creation point on main, and `F` as the upstream would replay main's own history.
- On failure, it runs `git -C <wt> rebase --abort`, then exits 1 with `restack conflicted; aborted. By hand: git -C <wt> rebase --onto <target> <U>`. Restack never leaves a rebase in progress.
- On success, it prints `restacked wt/<slug> onto <target>` and then the new `review_base` on its own line.

Output streams: the `already on` and `restacked` lines and the new base go to stdout. Refusals, the conflict message and the registry remedy go to stderr.

**Registry mode.** Release still refuses a stacked plan, whatever restack did (`release.sh:327`). The `Stacked on:` line still has to be deleted after the parent lands, followed by a fresh `/3-review`.

### Hints in the existing messages

Each hint goes on the **same line**, before the existing extraction prefix. The suite's `sed` extractors (`test-scripts.sh:2809`, `2817`, `2841`) take everything after `to pick it up: ` or `restack first: `, so they return the same bytes and the existing tests stay unchanged.

- **The `review_base` rewritten-parent note, with-worktree branch only:**
  `note: <parent> was rewritten since <slug> branched; run: harness worktree restack <slug>, or to pick it up: git -C <wt> rebase --onto wt/<parent> <F>`.
  The no-worktree branch is unchanged, because restack refuses without a worktree.
- **The `check_stack_landed` landed refusal:**
  `stacked on <parent>, which has landed; run: harness worktree restack <slug>, or restack first: git -C <wt> rebase --onto origin/main <F>`.
- **The registry release refusal** (`release.sh:327`) gets ` (harness worktree restack <slug> does the rebase)` appended at the end of the line. The test at line 2668 matches an earlier substring with `grep -Fq`, so it stays unchanged.

### Warnings

**No fork point.** In `review_base`, whenever a parent is declared and `stack_fork` exits 1, it still prints `mainref` and exits 0, so the contract is unchanged. It also writes `warning: no fork point for wt/<slug> on wt/<parent>; the review diff may include the parent's commits` to stderr. This applies whether the parent is merged or not: plan review found no state where the parent was merged, the fork point was missing and the child was still clean. Restack refuses in this state too, so the warning names the `rebase -i` remedy, not restack.

**Near-miss header.** In `stack_parent`, when no header-block line matches exactly, some line may still match after cleanup. The cleanup strips `*`, `_` and leading spaces, then lowercases the line with awk `tolower()`, because macOS awk has no `IGNORECASE`. A line matching `^stacked[[:space:]]*on([^a-z]|$)` writes `warning: ignoring near-miss stack line "<line>"; expected: Stacked on: <slug>` to stderr. The function still prints nothing and exits 0. A line like `Stacked onboarding flow` doesn't match. Release calls `stack_parent` twice, directly and through `review_base`, so the warning can appear twice there; that is accepted.

### Missing parent

`review_base`'s `wt/<parent> missing` refusal keeps its text and exit 2. When the child has a worktree, it adds `; its fork point is gone, so drop the parent's commits by hand first: git -C <wt> rebase -i <mainref>`. That means moving the `wt` lookup above the parent check. It doesn't point at restack, which refuses in this state.

### Prose

- **`ARCHI.md`:**
  - the `lib/stack.sh` and `worktree.sh` entries, including the registry landed-test limit;
  - the `harness worktree` entry-point line;
  - the release entry's restack-command description;
  - the test-scripts and gate summaries (their "hermetic stack cases" lists).
- **`worktree.sh`:** its usage strings.

### Rejected

- **Leaving a conflicted rebase in progress.** Aborting keeps the worktree in a known state, and the printed command reproduces the rebase.
- **Silencing the no-fork-point warning when the parent is merged.** An amended-then-merged parent with an expired reflog still leaves parent commits in the diff.
- **Making "no fork point" exit 2.** The deferral noted this changes `review_base`'s contract, which `/3-review` and `codex-review` both rely on.
- **"Nothing to do" when `F` is an ancestor of the target.** That is a review-base condition. It would strand a merge-landed child, which release then refuses with `is stale`.

## Footprint

Files to modify:
- `harness/scripts/lib/stack.sh`: restack logic, both warnings, the hint on the note, and the missing-parent remedy.
- `harness/scripts/worktree.sh`: the `restack` subcommand and the usage strings.
- `harness/scripts/release.sh`: the same-line hint in `check_stack_landed`, and the hint appended to the registry stacked refusal at line 327, only.
- `harness/tests/test-scripts.sh`: new stack cases. Existing assertions stay unchanged.
- `ARCHI.md`
- `PLAN.md` (orchestrator: this unit's Now line, and the candidate line removed)

Files NOT to touch:
- **The text after `to pick it up: ` and `restack first: ` in `lib/stack.sh` and `release.sh`.** It must stay byte-identical, because the suite extracts it and executes it.
- **`harness/scripts/codex-review.sh`, `state.sh` and `fan-exec.sh`, the skills, and `README.md`.** `README.md` doesn't list `worktree` subcommands.

## Acceptance criteria

The cases reuse the existing hermetic stack fixtures: a non-bare clone plus a local bare origin, with `wt/p` and `wt/c`. Every assertion uses `|| return 1`, as `knowledge/test-helper-contract.md` requires. After each rebasing restack, a case checks that `git log --format=%s <target>..wt/c` lists only the child's commits, and that `"$(worktree base c)...wt/c"` is child-only.

- [ ] **Untouched parent.** `restack c` prints `already on wt/p`, exits 0, and `wt/c`'s SHA is unchanged.
- [ ] **Parent gained a commit.** `restack c` rebases onto `wt/p`, and `wt/c` then contains `wt/p`.
- [ ] **Parent amended at its tip (unmerged).** `restack c` rebases onto `wt/p`, and the base is then `wt/p`.
- [ ] **Parent rebase-landed.** `restack c` rebases onto `origin/main`. Release then gets past `check_stack_landed` (no `stacked on`) and past `is stale`.
- [ ] **Parent rewritten, then landed.** A single `restack c` rebases onto `origin/main`, with the same release checks.
- [ ] **Parent merge-landed** (`--no-ff`, from a separate clone). `restack c` rebases onto `origin/main`. Release then gets past `check_stack_landed` and `is stale`.
- [ ] **Second restack after a rebase landing.** Restack a rebase-landed parent's child once. Then add a commit to main that edits a file the first landing added after the fork point, such as the parent's file, and restack again. Editing a file from `init` instead lets the "always use `F`" mutation pass vacuously. The second restack succeeds, and the child stays child-only (`git log origin/main..wt/c` lists only the child's commits).
- [ ] **Refusals.** Each exits 1 with its substring and leaves `wt/c`'s SHA unchanged:
  - `not stacked`;
  - `no worktree for`;
  - `has uncommitted changes`;
  - `wt/p is gone` together with `rebase -i`;
  - `no fork point` (an unmerged, amended parent with its reflog fully expired);
  - `restack conflicted; aborted`. The child edits the line the parent's rewrite changes, and afterwards `git -C <wt> status` shows no rebase in progress.
- [ ] **Registry mode.** Using the existing registry stack fixture:
  - an amended unmerged parent: restack onto `wt/p`;
  - a `--no-ff`-landed parent: restack onto `origin/main`;
  - an untouched parent: `already on wt/p`, with the `rebase -i` remedy on stderr;
  - release still refuses with the stacked message, which now ends with `harness worktree restack c does the rebase`.
- [ ] **Hints.** The rewritten-parent note (with-worktree branch) and the repo landed refusal each include `run: harness worktree restack c` on the same line as the existing command. Every existing stack assertion, including the extracted-and-executed commands, passes unchanged.
- [ ] **Missing-parent remedy.** With `wt/p` deleted and a `wt/c` worktree, `worktree base c` exits 2. Its stderr includes `delete the Stacked on: line` (unchanged) and `rebase -i`.
- [ ] **No-fork-point warning.**
  - **Unmerged parent:** amend it after the child branches, then expire its reflog. `worktree base c` exits 0, prints the main ref, and stderr has `warning: no fork point`.
  - **Merged parent:** amend it after the child branches, merge the amended tip `--no-ff`, then expire the reflog. The fixture first asserts that `git merge-base --fork-point wt/p wt/c` exits 1. The warning appears here too.
- [ ] **Near-miss warning.**
  - **Warned:** `stacked on: p`, `Stacked on p`, `**Stacked on:** p` and `Stacked on: P` each produce `warning: ignoring near-miss stack line`. `worktree add` on that unit then branches from the main ref.
  - **Silent:**
    - an exact `Stacked on: p`;
    - no such line;
    - `Stacked on: p` or `stacked on: p` below `## Approach`;
    - a `Stacked onboarding flow` line in the header block, without `#`.
- [ ] **Mutation pins.** The reviewer shows each one fails the suite, after confirming the mutation landed:
  - restack always targets `wt/<parent>`;
  - restack always targets `mainref`;
  - drop the `rebase --abort`;
  - replace the nothing-to-do test with "`F` is an ancestor of the target";
  - always use `F` as the upstream;
  - drop the no-fork-point warning;
  - drop the near-miss check;
  - drop the near-miss `^` anchor;
  - drop the near-miss `([^a-z]|$)` boundary;
  - scan the whole plan instead of the header block.
- [ ] `harness archi-fresh wt/stacked-units-followups` exits 0.
- [ ] `harness gate` passes.

## Release

Release note: `harness worktree restack <slug>` moves a stacked unit onto its parent in one command, whatever the parent's state: rewritten, grown, or landed by rebase or merge commit. It never leaves a rebase in progress, and the existing printed commands now name it. `harness worktree base` warns when an unmerged parent has no fork point, and a near-miss `Stacked on:` line warns instead of being ignored.

## Demonstration

This runs the worktree's own `harness` on a scratch repo with a local bare origin. The parent is amended after the child branches, then lands on `main` with its recorded plan. One `restack` fixes the child.

```sh
H="$PWD/harness/bin/harness"
d=$(mktemp -d)
trap 'rm -rf "$d"' EXIT
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
git init -q --bare "$d/origin.git"
git clone -q "$d/origin.git" "$d/repo" 2>/dev/null
cd "$d/repo"
printf 'worktrees:\n  dir: %s/wts\n' "$d" >config.yaml
echo base >README
git add -A
git commit -qm init
git push -q origin HEAD:main
git fetch -q origin
mkdir -p work/p work/c
printf '# P\n' >work/p/plan.md
printf '# C\nStacked on: p\n' >work/c/plan.md
P=$(bash "$H" worktree add p 2>/dev/null)
echo p1 >"$P/p.txt"
git -C "$P" add p.txt
git -C "$P" commit -qm p1
C=$(bash "$H" worktree add c 2>/dev/null)
echo c1 >"$C/c.txt"
git -C "$C" add c.txt
git -C "$C" commit -qm c1
echo p2 >"$P/p.txt"
git -C "$P" commit -qa --amend -m p1-amended
git -C "$P" push -q origin HEAD:main
git fetch -q origin
echo "base before: $(bash "$H" worktree base c 2>&1 | tr '\n' ' ')"
bash "$H" worktree restack c
git log --format=%s origin/main..wt/c
```

Expected:
1. `base before:` followed by a fork-point SHA and the note naming `harness worktree restack c`.
2. `restacked wt/c onto origin/main`, then `origin/main`.
3. Only `c1` and `Record plan for c`.

## Review

Plan review round 1: REVISE, ten findings, all applied:
1. Each hint now goes on the same line, before the extraction prefix, so the existing `sed` extractors are unaffected.
2. "Nothing to do" now requires the target to be an ancestor of the child, so merge-landed parents and parents that gained commits rebase. Criteria and a mutation were added.
3. The merged-parent no-fork-point fixture now really reaches exit 1 and asserts that it does.
4. The registry release refusal names restack, and registry still needs the line deleted plus a re-review.
5. The missing-parent refusal gets only the `rebase -i` remedy, not the circular restack hint.
6. The registry landed test's limit for squash and rebase merges is stated.
7. The near-miss match is anchored and uses `tolower`; double warnings during release are accepted.
8. The demo shows the base before restack and the commit list after, and uses exported git identity.
9. README is out of the footprint, and Goal item 1 is reworded.
10. Restack checks that `wt/<parent>` exists before working out the target.

Plan review round 2: REVISE, all applied:
1. **Second restack (MEDIUM-HIGH).** It replayed main's history after a rebase landing. The upstream is now the merge-base when `F` is inside the target, with a criterion and a mutation.
2. **Warning carve-out (MEDIUM).** The merged-parent exception hid the bad state. The no-fork-point warning is now unconditional and names the `rebase -i` remedy.
3. **Vacuous near-miss pin (MEDIUM).** The silent fixture is now `Stacked onboarding flow` without `#`, and the mutations are split.
4. **Header scoping.** A near-miss line below `## Approach` was added as a silent case.
5. **Registry squash or rebase merges.** `already on wt/<parent>` now prints the `rebase -i` remedy.
6. **Rebase already in progress:** accepted. The worktree shows as detached, so restack refuses with `no worktree for`. That is safe, though the wording is imprecise.
7. **ARCHI scope.** Every line that describes stacking was added to the Prose list.

Plan review round 3: APPROVE, with five LOWs:
- **Applied:** the second-restack fixture edits a file added after the fork point; `stack_fork` exit >1 returns 2; output streams are named; `mainref` is resolved before the preconditions.
- **Skipped:** the optional near-miss addition to the demo. The criteria cover it.
Plan verdict: APPROVE

Code review round 1: both reviewers APPROVE.
- **Code-reviewer:** all 16 criteria met. Each of the 10 required mutation pins failed the suite, under bash 3.2 as well.
- **Two MEDIUMs, sent back as followup 1:**
  - The no-fork-point warning printed `git -C ''` when the child had no worktree. Both reviewers raised it.
  - Restack accepted `wt/<slug>` checked out in the primary checkout (codex MEDIUM; code-reviewer LOW).
- **Also in followup 1:** the ARCHI line-24 LOW.
- **LOWs left as they are:** the fork-point refusal ordering after reflog expiry, and the indirect `base is wt/p` check.
