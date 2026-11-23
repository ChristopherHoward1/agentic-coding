# Integration branch: work units land on `dev`, and `main` is the release

**Slug:** integration-branch · **Date:** 2026-11-23 · **Status:** implemented

## Goal

At work, every merge into protected `main` waits on a coworker's approval. So the Owner's PRs grow until nobody can review them (around 3000 changed lines), and ad hoc work costs approvals too. The Owner controls a `dev` branch in their work repos and can merge to it themselves, through self-merged Bitbucket PRs. The repos are shared on paper, but in practice the Owner works alone. The harness hardcodes `main` as the base for new worktrees and review diffs (`harness/scripts/worktree.sh:71-72`, `harness/scripts/lib/stack.sh:22`).

Done means:
- A project can set `integration_branch: dev` in its `config.yaml`. New unit worktrees then branch from `origin/dev`, and review diffs are taken against `origin/dev`.
- `work-slim` declares the integration branch at `/init` and routes the Explore, Ship and Loop lanes to it through self-merged PRs.
- A new Promote lane opens the one `dev` → `main` PR the coworker approves. Its description lists the unit PRs instead of asking anyone to read the whole diff.

## Approach

- **Config.** Add `integration_branch:`, defaulting to `main`, read from `$STATE_DIR/config.yaml` with the same naive `awk` read as `worktrees.dir`. Surrounding single or double quotes are stripped. A missing config file means `main` in either mode: the helper checks for the file itself rather than relying on `worktree.sh`'s registry-only `/dev/null` fallback, because `release.sh` and `codex-review.sh` also reach it through `review_base`. The skeleton config gets a commented `# integration_branch: main` line with a short comment.
- **One helper in `lib/stack.sh`.** `integration_ref` prints the ref to base on. It reads the key, rejects an invalid name (`git check-ref-format --branch`), and prints `origin/<branch>` when that remote ref exists.
  - Contract: exit 0 prints the ref; exit 1 means unset or `main`; exit 2 is an error with a message on stderr. Both callers run under `set -e`, so they test the status explicitly (`if ref=$(integration_ref); then … else rc=$?; …`).
  - Unset or `main` (exit 1): the current fallback stays byte-for-byte, so local `main` in `review_base`, and HEAD in `worktree add`. The helper signals this case, and each caller keeps its own fallback.
  - Explicitly set to anything other than `main`, with no `origin/<branch>` after the best-effort fetch: exit 2 with a message naming the branch and `integration_branch`. Silently branching from HEAD would put a unit on the wrong base.
- **`worktree.sh`:** the `/dev/null` fallback for a missing config (line 50) applies in both modes, so `worktrees.dir`'s read no longer fails in a repo-mode checkout with no `config.yaml`.
- **`worktree.sh add`** (non-stacked path) and **`review_base`** (`mainref`) call the helper. Stacked units keep branching from `wt/<parent>`. `review_base`'s fork-point logic is unchanged; only `mainref`'s value changes. `review_base` feeds `harness worktree base`, `/3-review`, `codex-review.sh` and `release.sh`, so all of them follow the key.
- **`release.sh`** refuses when `integration_branch` is set to anything other than `main`. Its guards (`origin/main` ancestry, tag-after-merge) assume `main`, and in registry mode it already refuses. The `die` is the first statement of `release()`, before any `cd` or worktree check, and it reuses the helper's key reader (`$STATE_DIR/config.yaml`), not a second `awk`.
- **`codex-review.sh`** is not edited. It still reads `reviewer.command` from `main:config.yaml`. Its review base now comes from `review_base`, which reads the working-tree config. That is harmless, because `release.sh` refuses unless the key is `main`, and it refuses in registry mode, where work runs. `ARCHI.md` says this.
- **`work-slim.md`**:
  - **New declaration under "Declarations required at /init":** `integration_branch`. Check `origin/dev` and `origin/develop`. If one exists, check `git merge-base --is-ancestor origin/main origin/<candidate>` and show the Owner the result before confirming. If `main` is not an ancestor, recommend creating `dev` from `origin/main` instead. If neither exists, offer to create `dev` from `origin/main`, only with the Owner's yes, since it's a shared branch. Record the answer in `$(harness project)/config.yaml`. A registered project with no `integration_branch` is asked before its first Explore, Ship or Promote. `/init` step 2 already asks for every declaration the chosen profile requires, so `init/SKILL.md` needs no edit.
  - **A short "Integration branch" section:** units and ad hoc work land on `integration_branch` only through PRs (no direct pushes), and `main` changes only through Promote. PRs are opened and merged through the Bitbucket REST API, as they are at work today, and self-merges pass `merge_strategy: merge_commit` so every PR leaves a merge subject with its number. The Owner may click merge instead.
  - **Explore:** branch from `origin/<integration>`, never under a `wt/` name, which is reserved for reviewed units. Keepers (notebooks, reports) merge back through a self-merged PR, with no review.
  - **Ship:** create the worktree with `harness worktree add <slug>`. Step 3 diffs with `git diff "$(harness worktree base <slug>)...wt/<slug>"` (three dots, as `/3-review` does). Step 4 re-runs `harness gate` on the final head after any review fixes, opens the PR against the integration branch, and, after the reviewer approves, checks right before the merge call that the gated SHA starts with the PR's (short) `source.commit.hash`. The PR stays the record.
  - **Loop:** unchanged, except that the PR targets the integration branch, as in Ship step 4.
  - **New Promote lane, run only when the Owner asks:**
    0. `git fetch origin`, then pin `sha=$(git rev-parse origin/<integration>)` and use it in every later step.
    1. If `git diff --quiet "$(git merge-base origin/main "$sha")" origin/main` fails, `main` moved outside Promote: stop and tell the Owner. The remedy is to merge `origin/main` into the integration branch through a self-merged PR, then re-run Promote.
    2. Gate the integration tip in a throwaway detached worktree: `git worktree add --detach <tmp> "$sha"`, run `harness gate` inside it, note the SHA, then `git worktree remove <tmp>`.
    3. Push the gated SHA to a frozen `promote/<short-sha>` branch (never updated once pushed) and open its PR to `main`, so later merges to the integration branch can't ride along. Its description has one line per PR merged since the last promote: PR number from the merge subjects in `git log --first-parent --merges origin/main..origin/<integration>`, title and source branch from the REST API.
    4. Tag a PR `[reviewed]` only when its description has a `Reviewed-SHA:` line (written by Ship step 4 after approval and the final gate) whose SHA starts with the PR's merged `source.commit.hash`; anything else is `[unreviewed]`. A merge without a PR number, and every commit from `git log --first-parent --no-merges origin/main..<sha>`, is also listed as `[unreviewed]` with its SHA and subject. How verified makes the review claim only for `[reviewed]` lines, and adds the gate result with its SHA.
    5. Never merge to `main`; the coworker's approval is the release.
- **`docs/SKILL.md`** line 16: "bases diffs on `origin/main`" becomes "bases diffs on the review base".
- **`ARCHI.md`:** targeted edits so every place that says new worktrees or review bases are `origin/main` names `integration_branch` instead: the `worktree.sh` entry in the `harness/scripts/` Layout bullet, the `harness worktree add|base…` Entry points line, and the `config.yaml` Layout key list. Also the `lib/stack.sh` bullet (landings use the integration ref, not "the main ref"), the `release.sh` (refuses a non-`main` key), `codex-review.sh` (review base follows the key) and `work-slim` descriptions.
- **`PLAN.md`:** this unit's Now line, and this unit inserted into the roadmap ahead of `pr-release`, which stays unchanged.

Alternatives considered:
- A per-person `dev-<initials>` branch. Not needed, because the Owner works alone in these repos. The config key allows it later at no cost.
- A `harness promote` script. The list comes from one `git log` command plus a PR lookup, so profile prose is enough until real use asks for more.
- Back-merging `main` into `dev` before each promote. Dropped: with merge commits, every promote leaves a merge commit on `main` that isn't on `dev`, so the back-merge would fire every time, and `main` changes only through Promote anyway.

## Footprint

Files to modify:
- `harness/scripts/lib/stack.sh`
- `harness/scripts/worktree.sh`
- `harness/scripts/release.sh`
- `harness/tests/test-scripts.sh`
- `harness/skeleton/config.yaml`
- `harness/profiles/work-slim.md`
- `harness/skills/docs/SKILL.md` (line 16 only)
- `ARCHI.md`
- `PLAN.md` (orchestrator: Now line and roadmap entry, committed on the branch)

Files NOT to touch:
- `harness/scripts/codex-review.sh` (see Approach)
- `harness/skills/init/SKILL.md`, `harness/skills/4-release/SKILL.md`
- `config.yaml` (this repo stays on `main`)

## Acceptance criteria

- [ ] Hermetic tests in `test-scripts.sh`, each in a throwaway repo with a bare `origin` that has a `main` and a `dev` carrying a dev-only commit, and with `HARNESS_HOME` pointed at an empty temp dir:
  - With `integration_branch: dev`, `worktree.sh add x` creates `wt/x` whose HEAD is the dev-only commit.
  - With `integration_branch: dev`, `worktree.sh base x` prints `origin/dev`.
  - With `integration_branch: "dev"` (quoted), `add` also bases on the dev-only commit.
  - With the key unset, `add` bases on `origin/main` and `base` prints `origin/main`. The existing worktree and stack cases still pass unchanged.
  - With `integration_branch: main`, `base` prints `origin/main`.
  - With no `config.yaml` at all in repo mode, `add` bases on `origin/main` and `base` prints `origin/main`.
  - In registry mode with the state-dir config set to `integration_branch: dev`, `base x` prints `origin/dev`.
  - With `integration_branch: nope` (no such remote branch), `add` exits non-zero, names `nope` on stderr, and creates no `wt/x` branch; `base x` (on an existing `wt/x`) exits non-zero and names `nope`.
  - With `integration_branch: 'bad..name'`, `add` exits non-zero.
  - With `integration_branch: dev`, `release.sh <slug>` exits non-zero, naming `integration_branch` on stderr, even with no primary-on-`main` or `wt/<slug>` worktree set up.
  - In registry mode (a `$HARNESS_HOME/projects/<name>/project` entry whose state-dir `config.yaml` sets `integration_branch: dev`), `add` bases on the dev-only commit.
- [ ] Mutation: replace the helper's lookup with a hardcoded `origin/main`. The dev-base `add` and `base` checks fail. The reviewer shows this, and shows that the mutation actually landed.
- [ ] `harness/skeleton/config.yaml` contains a commented `integration_branch` line.
- [ ] `grep -c 'origin/main' harness/skills/docs/SKILL.md` reports 0.
- [ ] `work-slim.md`:
  - The /init declarations list `integration_branch`, naming `origin/dev` and `origin/develop`, naming the `git merge-base --is-ancestor origin/main` check, saying a missing branch is created only with the Owner's yes, and saying a registered project without the key is asked before its first Explore, Ship or Promote.
  - The Integration branch section says the branch changes only through PRs and names `merge_strategy: merge_commit`.
  - Explore names `origin/<integration>` and says never to use a `wt/` branch name.
  - Ship contains `harness worktree add` and the three-dot `harness worktree base <slug>)...wt/<slug>` diff, and step 4 re-runs `harness gate` on the final head writes `Reviewed-SHA:` into the PR description, and checks `source.commit.hash` against the gated SHA before merging into the integration branch.
  - Loop says its PR targets the integration branch.
  - A lane headed `**Promote**` starts with `git fetch origin` and a pinned `sha=$(git rev-parse origin/<integration>)`, contains the `git diff --quiet "$(git merge-base origin/main "$sha")" origin/main` stop check, the `git log --first-parent --no-merges` unreviewed listing, `refs/heads/promote/`, `git worktree add --detach`, the `[reviewed]` and `[unreviewed]` tags with the `Reviewed-SHA:` rule, `refs/heads/promote/<short-sha>` with never-update wording, and says never merge to `main`.
  - Outside Promote, `origin/main` appears only in the declaration's create-from step: `awk '/\*\*Promote\*\*/{p=1} /^## /{p=0} !p' harness/profiles/work-slim.md | grep -c 'origin/main'` reports at most 1.
- [ ] `grep -c pr-release PLAN.md` is unchanged from `main`, and the roadmap line names `integration-branch` before `pr-release`.
- [ ] `harness archi-fresh wt/integration-branch` exits 0. The `harness worktree add|base` Entry points line and the `config.yaml` Layout line each contain `integration_branch` (`grep '^- \*\*`harness worktree add' ARCHI.md | grep -c integration_branch` and `grep '^- `config.yaml`' ARCHI.md | grep -c integration_branch` each report 1), and the `harness/scripts/` bullet's `worktree.sh` entry names `integration_branch`.
- [ ] `harness gate` passes.

## Release

Release note: Projects can set `integration_branch` (for example `dev`), so unit worktrees and review diffs base on it. `work-slim` declares it at `/init` and lands units and ad hoc work there through self-merged PRs, and a Promote lane opens the single PR to `main`.

## Demonstration

Runs the branch's real `worktree.sh` against a throwaway repo with a bare origin, first in repo mode, then in registry mode.

```sh
S=$PWD/harness/scripts
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
export HARNESS_HOME="$t/home"; mkdir -p "$HARNESS_HOME"
git init -q --bare "$t/origin.git"
git clone -q "$t/origin.git" "$t/repo" 2>/dev/null
cd "$t/repo"
git config user.email demo@example.com; git config user.name demo
git checkout -q -b main
git commit -q --allow-empty -m root; git push -q origin main
git checkout -q -b dev; git commit -q --allow-empty -m "dev only"; git push -q origin dev; git checkout -q main
printf 'integration_branch: dev\nworktrees:\n  dir: %s/wts\n' "$t" >"$t/cfg"
cp "$t/cfg" config.yaml
wt=$("$S/worktree.sh" add demo)
git -C "$wt" log -1 --format=%s
[ "$(git -C "$wt" log -1 --format=%s)" = "dev only" ] || exit 1
"$S/worktree.sh" base demo
[ "$("$S/worktree.sh" base demo)" = origin/dev ] || exit 1
printf 'integration_branch: nope\nworktrees:\n  dir: %s/wts\n' "$t" >config.yaml
rc=0; out=$("$S/worktree.sh" add demo2 2>&1) || rc=$?
echo "missing-branch exit=$rc: $out"
[ "$rc" -ne 0 ] || exit 1
if git show-ref --verify --quiet refs/heads/wt/demo2; then exit 1; fi
rm config.yaml
mkdir -p "$HARNESS_HOME/projects/demo/work"
printf 'root=%s\nsubdir=\n' "$(cd -P "$t/repo" && pwd)" >"$HARNESS_HOME/projects/demo/project"
cp "$t/cfg" "$HARNESS_HOME/projects/demo/config.yaml"
wt=$("$S/worktree.sh" add reg)
git -C "$wt" log -1 --format=%s
[ "$(git -C "$wt" log -1 --format=%s)" = "dev only" ] || exit 1
[ "$("$S/worktree.sh" base reg)" = origin/dev ] || exit 1
echo integration-branch-ok
```
Expected: `dev only`, `origin/dev`, a non-zero `missing-branch exit=` line naming `nope`, `dev only` again (registry mode), then `integration-branch-ok`.

## Review

Round 1 (plan-reviewer): REVISE. All ten findings applied:
1. The `origin/main` grep criterion contradicted the Promote text. It is now scoped outside Promote, alongside concrete Ship/Promote checks.
2. The Promote back-merge step is dropped, since merge commits would make it fire on every promote (see Alternatives).
3. Promote lines are tagged by lane, and the review claim covers only `[ship]`/`[loop]`.
4. PRs are opened and merged through the Bitbucket REST API (or the Owner clicks merge). The Promote list comes from merge-subject PR numbers plus a REST title lookup.
5. `pr-release` stays on the roadmap, and this unit is inserted ahead of it. `4-release/SKILL.md` is not touched: `work-slim`'s Loop lane already overrides its registry-mode step.
6. Ship uses `harness worktree add`, and Explore branches from `origin/<integration>`.
7. The `init/SKILL.md` edit is dropped. `integration_branch` becomes a `work-slim` /init declaration, which `/init` step 2 already asks for, plus an ask-once rule for older registrations.
8. The demo adds a registry-mode run.
9. Quotes are stripped from the value, with a quoted-value test.
10. `codex-review.sh`'s review base now follows the key. The plan and `ARCHI.md` say so.

Round 2 (fresh plan-reviewer): REVISE. Seven findings applied, one declined:
1. Promote's lane tags had no source. They now come from the PR's source branch: `wt/*` → `[reviewed]`, else `[unreviewed]`. Explore never uses `wt/` names.
2. The tip gate runs in a throwaway detached worktree at `origin/<integration>`, with its SHA recorded.
3. The ARCHI edit names the three `origin/main` places, and the criterion checks each one.
4. A missing config means `main` in either mode, with a repo-mode no-config test.
5. Tests added for `base` on a missing branch and for an explicit `main`.
6. Promote stops if `main` gained non-merge commits outside Promote.
7. Criteria added for Explore, Ship step 4 and Loop.
8. Declined, optional "drop the `release.sh` guard": it costs one `die` and saves a misleading restack message for a repo-mode project on `dev`.

Round 3 (fresh plan-reviewer): REVISE. All seven findings applied:
1. Promote also lists direct and PR-less commits on the integration branch as `[unreviewed]`, and the branch changes only through PRs.
2. Ship re-runs the gate on the final head before self-merging.
3. A criterion checks the ask-before-first-use rule for older registrations.
4. Ship's diff is the three-dot form.
5. The Promote PR keeps its source branch (`close_source_branch: false`).
6. The helper's exit contract (0 ref / 1 fallback / 2 error) and the explicit status checks under `set -e` are stated.
7. A registry-mode `base` test, and the same check in the demo.

Round 4 (fresh plan-reviewer): REVISE. All five findings applied:
1. The no-config test couldn't pass, because `worktree.sh`'s `worktrees.dir` read failed first. The `/dev/null` fallback now applies in both modes.
2. The `/init` declaration checks that `origin/main` is an ancestor of the candidate branch (relevant for work's long-lived `develop`). Promote's stop now says how to fix it.
3. Self-merges pin `merge_strategy: merge_commit`, and Ship checks `source.commit.hash` against the gated SHA before merging.
4. The `release.sh` guard is the first statement of `release()` and reuses the helper's key reader.
5. The stale `origin/main` wording in `docs/SKILL.md` and the ARCHI `lib/stack.sh` bullet is reworded (`docs/SKILL.md` added to the footprint).

Owner approval (2026-11-23): approved over the round-4 REVISE after all five findings were applied; the code review still checks the result.
Plan verdict: APPROVE

Code review round 1: code-reviewer APPROVE (one MEDIUM, four LOWs). Codex REQUEST CHANGES with two HIGHs, both accepted on the merits and sent back:
1. The Promote PR tracked the live integration branch. It now comes from a frozen `promote/<date>` branch at the gated SHA, and `close_source_branch: false` is dropped as moot.
2. `rev-list --no-merges` missed content that exists only in a merge commit. It is replaced by a tree comparison against the merge base.
Also sent back: the MEDIUM (the no-config test never exercised the `worktree.sh` fix) and one LOW (Bitbucket's short `source.commit.hash` is now matched as a prefix). LOWs left as-is: an extra fetch in `integration_ref`, the `registry-base` case duplicating `registry`, and a `key:value` line with no space reading as unset.

Code review round 2: code-reviewer APPROVE (it ran both mutations itself, including the pinned round-1 no-config fix). Its MEDIUM was a stale ARCHI after the followup. Codex REQUEST CHANGES with two HIGHs, both accepted and sent back:
1. A same-day second promote would fast-forward `promote/<date>` under an open PR. Promote branches are now `promote/<short-sha>`, never updated.
2. `wt/*` alone proved no review (the code-reviewer raised the same as a LOW). Ship now writes `Reviewed-SHA:` into the PR description, and Promote tags `[reviewed]` only when that line matches the merged source hash.
Also sent back: a diverged `dev` candidate gets a new branch name suggested, and the ARCHI test bullet refreshed. LOWs left as-is: squash merges of the promote PR (work enforces merge commits), test temp dirs not removed (matching the existing cases), and a triple helper call in the release guard.

Code review round 3: code-reviewer APPROVE (four LOWs). Codex REQUEST CHANGES with two HIGHs, which left the review at its 3-round cap and went to the Owner:
1. Override, with the analysis recorded: "A self-merged PR's merge commit can carry unreviewed conflict-resolution code that `[reviewed]` hides." Bitbucket's UI and REST merge refuse a PR with conflicts, so conflicts are resolved on the source branch, where the gate and the `Reviewed-SHA:` check see them. The only other route to such a merge commit is a direct push to the integration branch, and the profile forbids that. The Claude reviewer raised nothing on this behavior in three rounds.
2. Accepted: Promote fetches `origin` before its checks and pins the fetched integration SHA for every later step.
Owner approval (2026-11-23): fix #2 and run a fourth review round, past the 3-round cap; override #1 as analyzed above.

Code review round 4 (Owner-authorized): code-reviewer APPROVE. It ran the gate, the demo and the helper mutation itself. Its LOWs were ARCHI freshness (healed below, per /3-review step 7), pinning `origin/main` as well (not acted on: a late `main` change only shows up as extra PR diff), and plan wording (`$sha` in the detached worktree, synced). Codex APPROVE, no findings.

Code-review verdict: APPROVE
Codex-review verdict: APPROVE
