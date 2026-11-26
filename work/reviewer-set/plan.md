# Reviewer set by mode

**Slug:** reviewer-set · **Date:** 2026-11-25 · **Status:** implemented

## Goal

Decision 2026-10-18 set reviewer sets per environment, with one fresh Claude reviewer at work, where there is no second vendor. `/3-review` already runs only the code-reviewer in registry mode. But `harness state` still requires both verdicts (`state.sh:50`, guarded by `PROJECT_MODE == repo`), so an approved registry unit never leaves `stage: review`.

Two more leftovers:
- While a registry unit sits in review, `next_action` always reads `run harness gate`, because it keys off `codex-review.md`, which registry never writes.
- `codex-review.sh`, `/3-review` and `ARCHI.md` still describe codex as pending a `reviewer-set` unit.

Done = the mode decides the required set. Registry needs `Code-review verdict: APPROVE`; repo needs it plus `Codex-review verdict: APPROVE`, unchanged. `harness state` follows that, and no `reviewer-set` placeholder is left in `harness/`, `README.md` or `ARCHI.md`.

The need, restated per Decision 2026-10-19: the Owner chose this unit on 2026-11-25 to clear frozen roadmap items, and chose this slim scope over a configurable `reviewer.set` key. It comes before `pr-release` despite the roadmap order because it is independent: `pr-release` will consume the registry `review: approve → stage: release` transition this unit adds.

## Approach

- **`state.sh`:** in registry mode, `review` is `approve` when `Code-review verdict: APPROVE` is present. In repo mode it still needs both lines. An approved registry unit then reaches `stage: release` / `next_action: /4-release`; `/4-release` step 1 already tells the Owner to open the PR by hand there. The release and done rules stay as they are; registry done-state stays with `pr-release`. The `ponytail` comment says registry units stop at `stage: release` even after a hand-merged PR, until `pr-release` defines done.
- **`state.sh` review `next_action`:** `/3-review` when `codex-review.md` **or** `review-round` exists in the unit dir, otherwise `run harness gate`. `/3-review` step 2 creates `review-round` in both modes, so registry reviews in progress now point at `/3-review`.
- **`codex-review.sh`:** the registry refusal stays (exit 2, canned reviewer never invoked). Its message drops the placeholder: `codex-review: registry mode has no codex reviewer; /3-review uses the code-reviewer only`.
- **`/3-review` step 3:** the registry sentence no longer says "until `reviewer-set` lands" / "`harness state` keeps the unit in `review`". It says registry needs only the code-reviewer's verdict, and `harness state` then moves the unit to `release`. Steps 5 and 6 are unchanged.
- **`ARCHI.md`:** the Registry-mode paragraph says state reaches release after the code-review verdict, and that codex-review refuses (no codex at work) while release and fan-exec wait on `pr-release`. The `state.sh` description in the scripts bullet gains the registry rule and the `review-round` `next_action`.

`release.sh` is untouched: its registry guard (`pr-release`) refuses before `check_verdict` runs. `README.md` line 43 ("in registry mode review uses only the code-reviewer, and the loop stops after review") stays accurate and is untouched.

Rejected: a `reviewer.set` config key, main-bound, with a `harness reviewers` command and `/init` codex detection. Only a repo-mode template user without codex would use it (Owner call, 2026-11-25).

## Footprint

Files to modify:
- `harness/scripts/state.sh`
- `harness/scripts/codex-review.sh` (registry message only)
- `harness/skills/3-review/SKILL.md` (step 3's registry sentence)
- `harness/skills/4-release/SKILL.md` (step 1: "In registry mode, stop after review:" becomes "In registry mode, stop here:")
- `harness/tests/test-scripts.sh`:
  - the registry `state new` assertions at `registry_flow` (now `stage: release` after the code-review line, plus a `review-round` `next_action` case);
  - the `grep -q reviewer-set` assertion, now matching the new message;
  - new repo-mode cases where needed.
- `ARCHI.md`
- `PLAN.md` (orchestrator: this unit's Now line; the roadmap arrow marks `reviewer-set` done)

Files NOT to touch:
- `harness/scripts/release.sh`, `harness/scripts/fan-exec.sh`: their registry refusals belong to `pr-release`.
- `README.md`: line 43 stays accurate.

## Acceptance criteria

- [ ] Registry: a unit with `Plan verdict: APPROVE`, a `handoff.md` and `Code-review verdict: APPROVE` reports `review: approve`, `stage: release`, `next_action: /4-release`.
- [ ] Registry: the same unit without the code-review line reports `stage: review` and `next_action: run harness gate`. After `review-round` is written to its unit dir it reports `next_action: /3-review`.
- [ ] Repo: a branch plan with only `Code-review verdict: APPROVE` still reports `review: pending` / `stage: review` (the existing `review-single-sentinel` case passes unchanged).
- [ ] Repo: in review, a unit dir with `review-round` but no `codex-review.md` reports `next_action: /3-review`.
- [ ] Every existing repo-mode state, release and codex-review case passes unchanged.
- [ ] Registry `codex-review` exits 2 with `registry mode has no codex reviewer`, and the canned reviewer is never invoked.
- [ ] Mutation pins, each shown by the reviewer to fail the suite after the mutation is confirmed to have landed:
  - the registry rule also requires the codex line;
  - the repo rule drops the codex line;
  - the `review-round` check is removed from `next_action`.
- [ ] `grep -rn 'reviewer-set' harness/ README.md ARCHI.md` prints nothing.
- [ ] `grep -F 'then moves an approved unit to `release`' harness/skills/3-review/SKILL.md` matches step 3. The new sentence there is: "**Registry mode:** launch only the code-reviewer and record only `Code-review verdict:`; `harness state` then moves an approved unit to `release`." `grep -F 'keeps the unit in' harness/skills/3-review/SKILL.md` prints nothing.
- [ ] `harness archi-fresh wt/reviewer-set` exits 0.
- [ ] `harness gate` passes.

## Release

Release note: in registry mode, `harness state` takes the code-reviewer's verdict as the whole review, as Decision 2026-10-18 intended. An approved registry unit now reaches `stage: release` instead of sitting in `review`, and a review in progress points at `/3-review`. The `reviewer-set` placeholder is gone from `codex-review`, `/3-review` and `ARCHI.md`.

## Demonstration

Runs the branch's dispatcher on a scratch repo registered in a scratch `HARNESS_HOME`, so the installed harness and real state are untouched.

```sh
H="$PWD/harness/bin/harness"
d=$(mktemp -d)
trap 'rm -rf "$d"' EXIT
export HARNESS_HOME="$d/hh"
git -C "$d" init -qb main repo
cd "$d/repo"
echo x >README
git add -A
git -c user.name=t -c user.email=t@t commit -qm init
S=$(bash "$H" register 2>/dev/null)
mkdir -p "$S/work/demo"
printf '# Demo\n\nPlan verdict: APPROVE\n' >"$S/work/demo/plan.md"
echo h >"$S/work/demo/handoff.md"
bash "$H" state demo | grep -E '^(stage|next_action):'
echo 1 >"$S/work/demo/review-round"
bash "$H" state demo | grep -E '^next_action:'
echo 'Code-review verdict: APPROVE' >>"$S/work/demo/plan.md"
bash "$H" state demo | grep -E '^(review|stage|next_action):'
bash "$H" codex-review demo || echo "codex-review exit=$?"
```
Expected, in order:
1. `stage: review`, then `next_action: run harness gate`.
2. `next_action: /3-review`.
3. `stage: release`, `review: approve`, `next_action: /4-release` (in `state.sh`'s print order).
4. The `registry mode has no codex reviewer` message on stderr, then `codex-review exit=2`.

## Review

Plan review round 1: REVISE. The reviewer's first finding was scope: most of the drafted `reviewer.set` config served only a repo-mode template user without codex. The Owner chose the slim, mode-decided version (2026-11-25), and the plan was rewritten around it. How the other findings were handled:
- **Applied:** `next_action` keyed off `codex-review.md` (finding 2); the contradictory "existing state cases" criterion and the unnamed registry assertion (3); the demo's missing registry pass and git identity (4); the uncheckable grep criterion (5).
- **No longer apply:** invalid-set behavior, main-binding mutation, `/init` and the README paragraph (findings 6–9). They concerned the config key, which was dropped.

Plan review round 2: APPROVE, with three LOWs:
1. `/4-release` step 1's "stop after review" wording: applied, file added to the footprint.
2. The `ponytail` comment must say registry units stay at `release` even after a hand-merged PR: applied.
3. The ARCHI dual-vendor line is already scoped by "Repo mode retains…": no change.
Plan verdict: APPROVE

Code review round 1:
- **Codex: REQUEST CHANGES**, one HIGH. Registry `state.sh` still read the repo-side `work/.last-released` and `retro.md`, so a repo that had once used repo mode could jump a registry unit to `/5-retro` or `done`. That path only became reachable with this unit. It was sent back as followup 1: the marker is now read in repo mode only, with a regression case.
- **Code-reviewer: APPROVE**, with two LOWs:
  1. `review-round` persists through followups.
  2. No canned-reviewer marker in the registry codex-review test.

Code review round 2:
- **Codex: APPROVE.**
- **Code-reviewer: REQUEST CHANGES**, one HIGH. The followup touched `harness/` after the last ARCHI edit, so `archi-fresh` failed. The orchestrator made a targeted ARCHI edit on the branch: registry state ignores the repo-side marker. Its four mutations, including one for the followup's guard, all failed the suite.

Code review round 3: both APPROVE.
- **Codex MEDIUM:** the `PLAN.md` roadmap and Now line. This is orchestrator work, done on the branch at release.
- **Code-reviewer LOWs:** the same `PLAN.md` note, `review-round` precision, and the ARCHI test-summary breadth. Left as is.

Code-review verdict: APPROVE
Codex-review verdict: APPROVE
