# PR release (forge: none)

**Slug:** pr-release · **Date:** 2026-11-25 · **Status:** implemented

## Goal

At work (registry mode) the PR is the release record (Decision 2026-10-18). Today `harness release` refuses in registry mode (`release.sh:322`), so a Loop-lane unit's release runs by hand from `work-slim` prose:
- gate the final head and note its SHA;
- add `Reviewed-SHA:` to the PR;
- write the What/Why/How verified/Out of scope description;
- check the SHA against the PR's source commit before merging.

Nothing binds the review verdict to a SHA, so a commit added after review can reach the PR unnoticed. `harness state` also can't tell when a registry unit is done.

Done = in registry mode, `harness release <slug>` does the following and pushes nothing:
- checks the plan and code-review verdicts;
- checks that `wt/<slug>` is clean, sits on the integration branch, and is still exactly the reviewed SHA;
- gates that SHA;
- writes `$STATE_DIR/work/<slug>/pr.md`, with the gated and reviewed SHA as `Reviewed-SHA:`.

`harness state` then reports done once that SHA is merged into the integration branch. The Owner confirmed this need and the `forge: none` scope on 2026-11-25: no forge API calls; the Owner or the profile opens the PR.

## Approach

**Review binds a SHA.** In registry mode, `/3-review` step 1 captures `reviewed=$(git rev-parse wt/<slug>)` and builds the reviewer's diff from `"$base...$reviewed"`. Step 6 then records `Reviewed-SHA: <reviewed>` (full 40-hex) on the line after `Code-review verdict: APPROVE`. Each approving round replaces it. Any commit after `reviewed` is not reviewed in registry mode:
- a MEDIUM fix applied directly, or a post-APPROVE LOW wording fix on the branch, needs a new round before release;
- release refuses otherwise.

The `/3-review` prose says this. Repo mode is unchanged.

**`release.sh`, registry branch.** `registry_release_guard` keeps refusing `tag-after-merge`, with `registry mode has no tags; the merged PR is the record`. `release <slug>` dispatches to a new `registry_release`. It writes nothing until every check passes, and each refusal exits 1 with the substring shown:
1. The plan `$STATE_DIR/work/<slug>/plan.md` exists (`missing work unit plan`) and has the exact lines `Plan verdict: APPROVE` (`Plan verdict: APPROVE`) and `Code-review verdict: APPROVE` (`Code-review verdict: APPROVE`).
2. The plan has exactly one line matching `^Reviewed-SHA:`. That line matches `^Reviewed-SHA: [0-9a-f]{40}$` and comes directly after `Code-review verdict: APPROVE`, where `/3-review` step 6 writes it (`exactly one Reviewed-SHA line after the code-review verdict`). Because there is only one such line, the copied Goal and Acceptance-criteria bodies can't hold another.
3. The plan declares no `Stacked on:`, i.e. `stack_parent` is empty (`stacked on`; message below).
4. `wt/<slug>` is checked out in a linked worktree (`must be checked out`) and is clean (`check_clean_worktree`: `has unstaged changes` / `has staged changes` / `has untracked files`).
5. HEAD equals `Reviewed-SHA` (`moved after review; re-run /3-review`).
6. The base is fetched and is an ancestor of `wt/<slug>`. The base is `integration_ref`, or `origin/main` when `integration_branch` is unset or `main`. Message: `is not based on <base>; rebase onto <base>, then re-run /3-review`. A rebase gives a new SHA, so it always needs a new review.
7. The gate runs in the worktree, `(cd "$wt" && bash "$HERE/gate.sh")` (`harness gate failed`).
8. After the gate, the worktree is still clean and HEAD is still `Reviewed-SHA`, with the same messages as 4 and 5. The base is not re-fetched after the gate: a coworker's push between the two checks is caught at the PR, and no test could pin a re-fetch here.
9. `harness archi-fresh wt/<slug>` passes (`ARCHI.md is stale`). Checks 1–6 and the refusals below run before the gate (a missing state-dir `ARCHI.md` is caught by check 9, after it), so a pre-gate refusal never runs it. Tests pin this with a marker-writing gate hook.

It then writes `pr.md` through a temp file and `mv`:

```text
## What
<the plan's one-line Release note>

## Why
<the plan's ## Goal body>

## How verified
- harness gate: PASS at <sha>
- Code review: APPROVE by a fresh code-reviewer at <sha>

Acceptance criteria the reviewer checked against at <sha>:
<the plan's ## Acceptance criteria body>

## Out of scope
_Fill in before opening the PR._

Reviewed-SHA: <sha>
```

`plan.tpl` has no Out of scope section, so `pr.md` leaves an explicit placeholder rather than inventing one. `## What` is the release note, which `extract_release_note` already limits to one line. The script prints the `pr.md` path, then `release: nothing pushed; push wt/<slug> and open a PR to <integration branch> with this description`. It writes no VERSION, CHANGELOG, tag or marker, and makes no commit. A re-run overwrites `pr.md`.

**Further refusals.** Each exits non-zero before anything is written:
- **No release note:** `extract_release_note`'s `missing a Release note: line`.
- **Bad integration branch:** `integration_ref` exit 2 (invalid `integration_branch`, or no `origin/<branch>`) propagates its message.
- **`--confirm-delta`:** in registry mode it is rejected with `--confirm-delta is repo-mode only`.
- **Stacked plans** get a message naming the remedy: `stacked on <parent>; land <parent>, rebase onto <base>, delete the Stacked on: line, then re-run /3-review`.

**`state.sh`, registry after `review: approve`.** `state.sh` sources `lib/stack.sh` only for `integration_branch`, never `integration_ref` or `review_base`, both of which fetch. An empty or `main` branch means `refs/remotes/origin/main`; otherwise it uses `refs/remotes/origin/<branch>`. It checks that local ref with no fetch, and a missing ref counts as not merged.
- `stage: release`, `next_action: /4-release` when there is no `pr.md`, or `pr.md`'s last `^Reviewed-SHA:` line (the template's closing line) differs from the plan's;
- `stage: release`, `next_action: merge the PR (work/<slug>/pr.md)` when the plan's `Reviewed-SHA` is not an ancestor of that ref;
- `stage: done`, `next_action: none` otherwise.

Done means the reviewed SHA is in the integration branch. With `forge: none`, the only guard against extra commits in the merged PR is the source-commit check before merging. Done appears after the next fetch. The `ponytail` comment goes.

**Prose:**
- **`/3-review` steps 1 and 6:** capture the reviewed SHA and record it, as above.
- **`/4-release` step 1, registry mode:**
  1. Run `harness release <slug>`.
  2. Before the PR opens, fill in Out of scope and any `EVAL_METRIC` line the profile needs for model or data changes. A re-run overwrites `pr.md`.
  3. Push and open the PR, either by the Owner or following the profile.
  4. Before merging, check that `Reviewed-SHA` starts with the PR's source commit hash; forges may return a short hash.
  5. On a base refusal, rebase and re-run `/3-review`; never re-stamp.
  6. Step 2 (react to the exit code) applies to both modes; steps 3–6 (README drift, tag, publish, retro) are repo-only. The "stop here" wording goes.
- **`work-slim`:**
  - The Loop lane runs `/4-release`, whose `harness release` gates the reviewed SHA and writes `work/<slug>/pr.md`. Then open the PR against the integration branch with `pr.md` as its description. Before merging, check that `Reviewed-SHA` starts with the PR's `source.commit.hash`. This replaces "`/4-release` stops after review in registry mode". The manual gate and `Reviewed-SHA` steps of Ship step 4 don't apply.
  - One line: merge Loop PRs by merge commit or fast-forward only. Squash and rebase merges rewrite the SHA, so `harness state` would never report done.
- **`README.md` line 43** says registry release writes `pr.md` and stops before the PR.
- **`ARCHI.md`**: the Registry-mode paragraph and the `release.sh`/`state.sh` descriptions.

**Not covered:**
- **The `work-slim` Ship lane.** It has no plan or verdict file, so it keeps its prose. Routing it through a minimal plan would be a separate unit.
- **Bitbucket or GitHub forge calls.** Out of scope by the Owner's call.

## Footprint

Files to modify:
- `harness/scripts/release.sh`: the registry branch, `registry_release`, and the `tag-after-merge` message.
- `harness/scripts/state.sh`: registry release/done rules; the `ponytail` comment removed.
- `harness/skills/3-review/SKILL.md`: steps 1 and 6, registry sentences.
- `harness/skills/4-release/SKILL.md`: step 1, registry sentence.
- `harness/profiles/work-slim.md`: the Loop lane item and the squash-merge line.
- `harness/tests/test-scripts.sh`:
  - new registry release and state cases;
  - `registry_flow`'s `release demo` refusal (`grep -q pr-release`, line 2545) rewritten to the verdict refusal;
  - its `state new` `stage: release` assertions, which stay true (no `pr.md`).
- `README.md` (line 43)
- `ARCHI.md`: line 40, the `release.sh`/`state.sh` descriptions, and line 51's verdict-sentinel convention, which becomes repo-mode only.
- `PLAN.md` (orchestrator: this unit's Now line and roadmap)

Files NOT to touch:
- **Repo-mode release logic in `release.sh`:** `release`, `tag_after_merge`, and every `check_*` they call. New code may call `check_clean_worktree`, `worktree_for_branch` and `extract_release_note` but may not change them.
- **`harness/scripts/lib/stack.sh`, `fan-exec.sh` and `codex-review.sh`.**

## Acceptance criteria

- [ ] **Happy path.** The hermetic registry fixture has a bare `origin` and a registered project. It runs `harness worktree add`, makes one commit on `wt/<slug>`, and adds `handoff.md`, a plan containing `Plan verdict: APPROVE`, `Code-review verdict: APPROVE` and `Reviewed-SHA: <head>`, and a state-dir `ARCHI.md` touched after the commit. `harness release <slug>` exits 0 and writes `pr.md`:
  - The last line is `Reviewed-SHA: <head>`, and it is the only line starting with `Reviewed-SHA:`.
  - `## What` is the release note, and `## Why` holds the plan's Goal text.
  - How verified includes `harness gate: PASS at <head>`.

  Afterwards origin's `for-each-ref` output is identical to before, and the work repo has no new commits and an empty `git status --porcelain`. No `VERSION`, `CHANGELOG.md` or `work/.last-released` exists there.
- [ ] **Refusals.** Each exits non-zero and prints the Approach's substring for that check. An existing `pr.md` stays byte-identical; otherwise none is written.
  - **Pre-gate cases.** Each runs with a `$S/scripts/gate.d/` hook that writes a marker file, and asserts the marker is absent:
    - no plan (`missing work unit plan`);
    - no worktree for `wt/<slug>` (`must be checked out`);
    - missing `Plan verdict: APPROVE`, or missing `Code-review verdict: APPROVE`;
    - a `Reviewed-SHA:` line that is missing, malformed (`Reviewed-SHA: <sha>`), duplicated (including one inside the Goal), or not directly after the code-review verdict;
    - HEAD ≠ `Reviewed-SHA`, or a dirty worktree;
    - a base that isn't an ancestor;
    - a `Stacked on:` plan, with the message naming the remedy;
    - no `Release note:` line;
    - `integration_branch: dev` with no `origin/dev`;
    - `--confirm-delta`.
  - **Post-gate cases:**
    - a failing gate hook;
    - a stale state-dir `ARCHI.md` (`ARCHI.md is stale`);
    - a missing state-dir `ARCHI.md`.
- [ ] **Mid-gate refusals.** A `$S/scripts/gate.d/` hook that commits on `wt/<slug>` gets `moved after review`. A hook that leaves an untracked file gets `has untracked files`. In both cases the gate itself passes.
- [ ] **Integration branch.** With `integration_branch: dev` and an `origin/dev` that has a commit `origin/main` lacks:
  - a `wt/<slug>` based on `origin/main` refuses with `is not based on origin/dev`;
  - a `wt/<slug>` based on `origin/dev` passes, and the printed `release: nothing pushed` line names `dev`.
- [ ] **No tags.** Registry `tag-after-merge` exits 1 with `the merged PR is the record`.
- [ ] **Registry state.** For an approved fixture with `handoff.md`, it reports, in turn:
  - with no `pr.md`: `stage: release` / `next_action: /4-release`;
  - with `pr.md`: `next_action: merge the PR (work/<slug>/pr.md)`;
  - when `pr.md`'s `Reviewed-SHA` differs from the plan's: `next_action: /4-release`;
  - after `Reviewed-SHA` is pushed to origin **by URL or from a separate clone**, never by the remote name `origin` (that would update the local tracking ref), but before any fetch: still `merge the PR`, which pins no-fetch;
  - after the fetch: `stage: done` / `next_action: none`.
- [ ] **Repo mode unchanged.** Every existing repo-mode release, `tag-after-merge` and state case passes unchanged.
- [ ] **Mutation pins.** The reviewer shows each mutation fails the suite, after confirming it landed:
  - drop the pre-gate HEAD = `Reviewed-SHA` check;
  - drop the post-gate HEAD/clean re-check;
  - skip the gate;
  - drop the base-ancestor check;
  - make `state.sh` report done without the ancestor check;
  - drop the stale-`pr.md` comparison;
  - add a `git fetch` to `state.sh`.
- [ ] **Placeholder.** `grep -rn 'pr-release' harness/ README.md ARCHI.md` prints nothing.
- [ ] **Prose, positive.** `grep -F 'pr.md'` matches in each of `harness/skills/4-release/SKILL.md`, `harness/profiles/work-slim.md` and `README.md`. `grep -F 'reviewed=$(git rev-parse wt/<slug>)' harness/skills/3-review/SKILL.md` matches, and `grep -i 'squash' harness/profiles/work-slim.md` matches the new line.
- [ ] **Prose, negative.** `grep -F 'stops after review in registry mode' harness/profiles/work-slim.md` and `grep -F 'stop here' harness/skills/4-release/SKILL.md` both print nothing.
- [ ] `harness archi-fresh wt/pr-release` exits 0.
- [ ] `harness gate` passes.

## Release

Release note: In registry mode `harness release <slug>` now prepares the PR instead of refusing. It checks the verdicts and the `Reviewed-SHA:` that `/3-review` now records, and refuses if `wt/<slug>` moved after review or isn't based on the integration branch. It then gates that SHA and writes `work/<slug>/pr.md`. Nothing is pushed and no forge is called. `harness state` reports a registry unit done once its reviewed SHA is in the integration branch.


## Demonstration

Runs the branch's dispatcher on a scratch registered repo with a local bare origin.

```sh
H="$PWD/harness/bin/harness"
d=$(mktemp -d)
trap 'rm -rf "$d"' EXIT
export HARNESS_HOME="$d/hh"
g() { git -c user.name=t -c user.email=t@t "$@"; }
git init -q --bare "$d/origin.git"
git -C "$d" init -qb main repo
cd "$d/repo"
echo x >README
git add -A
g commit -qm init
git remote add origin "$d/origin.git"
git push -q origin main
S=$(bash "$H" register 2>/dev/null)
printf 'worktrees:\n  dir: %s/wts\n' "$d" >"$S/config.yaml"
mkdir -p "$S/work/demo"
printf '# Demo\n\n## Goal\n\nShow pr-release.\n\n## Acceptance criteria\n\n- [ ] it works\n\n## Release\n\nRelease note: demo change.\n\nPlan verdict: APPROVE\n' >"$S/work/demo/plan.md"
WT=$(bash "$H" worktree add demo 2>/dev/null)
echo change >"$WT/change.txt"
g -C "$WT" add change.txt
g -C "$WT" commit -qm change
touch "$S/ARCHI.md" "$S/work/demo/handoff.md"
printf 'Code-review verdict: APPROVE\nReviewed-SHA: %s\n' "$(git -C "$WT" rev-parse HEAD)" >>"$S/work/demo/plan.md"
before=$(git -C "$d/origin.git" for-each-ref)
bash "$H" release demo
cat "$S/work/demo/pr.md"
[ "$before" = "$(git -C "$d/origin.git" for-each-ref)" ] && echo "origin unchanged"
bash "$H" state demo | grep -E '^(stage|next_action):'
git -C "$WT" push -q "$d/origin.git" HEAD:main
bash "$H" state demo | grep -E '^next_action:'
git fetch -q origin
bash "$H" state demo | grep -E '^(stage|next_action):'
echo more >>"$WT/change.txt"
g -C "$WT" commit -qam more
bash "$H" release demo || echo "release exit=$?"
```
Expected, in order:
1. The `pr.md` path and the `release: nothing pushed … main` line.
2. The whole `pr.md`: What `demo change.`, Why `Show pr-release.`, How verified with `harness gate: PASS at <sha>` and the criterion, the Out of scope placeholder, and a closing `Reviewed-SHA: <sha>`.
3. `origin unchanged`.
4. `stage: release`, then `next_action: merge the PR (work/demo/pr.md)`.
5. After the push but before the fetch: `next_action: merge the PR (work/demo/pr.md)`.
6. After the fetch: `stage: done` and `next_action: none`.
7. A `moved after review` refusal, then `release exit=1`.

## Review

Plan review round 1: REVISE, nine findings, all applied.
1. The reviewed SHA is captured at step 1, the diff is built from it, and post-review commits need a new round.
2. The demo now has `handoff.md`, shows `done` after a merge, and cats the whole `pr.md`.
3. Mid-gate hook refusal cases were added, and the unpinned post-gate base re-fetch was dropped.
4. The criteria block is retitled as what the reviewer checked against, and the EVAL_METRIC and overwrite prose were added.
5. An exact `Reviewed-SHA` parse rule, plus a refusal for copied bodies.
6. `state.sh` checks the local remote ref without fetching.
7. The base refusal names rebase plus `/3-review`.
8. Exact refusal substrings, and the `dev` criterion now targets the printed line.
9. Stale-`pr.md` comparison, a squash-merge line, and the extra-commits guard stated.

Plan review round 2: REVISE. The plan body was truncated by a scripted edit; it has been restored in full, and the Review section re-checked against disk. Findings applied:
1. The Footprint names every forced file, with lines.
2. The prose criteria use only text that exists after the change, plus negative greps.
3. The release note is one line, and `## What` is that line.
4. `state.sh` resolves the ref without `integration_ref`; a pushed-but-unfetched case and a fetch mutation pin it.
5. Refusals for a missing release note, a missing `origin/dev`, a missing ARCHI and `--confirm-delta`.
6. The stacked message names the remedy.
7. Out of scope is an explicit placeholder, filled before the PR opens. That removes one input from check 10.

Plan review round 3: REVISE, seven findings, all applied.
1. The demo and the no-fetch criterion push by URL, so the tracking ref stays stale until the fetch.
2. Pre-gate refusals assert that a marker-writing gate hook never ran, so the pre-gate HEAD and clean checks are pinned separately from the post-gate ones.
3. The `Reviewed-SHA` line must come directly after the code-review verdict. Check 10 and its case were dropped.
4. The integration-branch criterion adds a refusal for a branch based on `origin/main`.
5. The merge line covers rebase merges as well as squash merges.
6. Refusal cases were added for the missing plan, the missing worktree, and a stale or missing ARCHI, and the happy-path fixture touches ARCHI.
7. ARCHI line 51 was added to the Footprint.

Plan review round 4: APPROVE, with five LOWs, all applied:
1. A missing ARCHI is a post-gate refusal.
2. The Loop prose opens the PR with `pr.md` and drops Ship step 4's manual steps.
3. "Starts with" the PR's source hash.
4. `/4-release` step 2 applies to both modes.
5. `state.sh` reads `pr.md`'s last `Reviewed-SHA:` line.
Plan verdict: APPROVE

Implementation: dispatch 1 built the feature but skipped most of the test matrix. Followup 1 added it (306 tests). The orchestrator then made a targeted ARCHI edit on the branch before review, per the 2026-11-25 decision.

Code review round 1: both reviewers REQUEST CHANGES.
- **Codex HIGH:** `/4-release` step 1 listed push and open-PR before the exit-code check.
- **Code-reviewer HIGH (codex MEDIUM, same issue):** on bash 3.2, mid-function `[[ ]]` assertions don't fail under `-e`, so the post-gate re-check mutation survived 306/306.
- **Fix:** followup 2 made every assertion `|| return 1`, proved the mid-gate cases fail with the re-check removed, reordered the prose, and fixed three LOWs (registry exit-0 report, work-slim list indentation, a scoped `## Why` check). ARCHI was then edited again on the branch.

Code review round 2: both reviewers APPROVE.
- **Code-reviewer:** all seven required mutation pins, plus five extra mutations, fail the suite. LOWs left as they are: `pr.md` mode 0600, the migration message for older registry plans without `Reviewed-SHA`, no temp-file cleanup trap, the primary-checkout path comparison, and the dense step-1 paragraph.
- **Codex:** two MEDIUMs deferred to `deferrals.md` (fence-aware section extraction; re-capturing the SHA on each round). Both fail safe or visibly.

Code-review verdict: APPROVE
Codex-review verdict: APPROVE
