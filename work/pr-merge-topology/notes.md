Dispatching implementer in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
  codex exec --sandbox workspace-write - < /Users/cboyfly/Documents/repos/agentic-coding/work/pr-merge-topology/handoff.md
OpenAI Codex v0.139.0
--------
workdir: /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
model: gpt-5.5
provider: openai
approval: never
sandbox: workspace-write [workdir, /tmp, $TMPDIR]
reasoning effort: none
reasoning summaries: none
session id: 01a038af-155a-79d2-b0c1-944f6a8474c6
--------
user
You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.

Work unit: work/pr-merge-topology/plan.md  (read it in full; it is your source of truth)
Branch: wt/pr-merge-topology (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

## What this change does

Collapse the two release topologies (`self` direct-push-to-`main` and `platform-team` PR-merge) into ONE universal PR-merge topology, and remove the `review.human_pr_review` config knob entirely. `scripts/release.sh` must never touch `main` and never tag. Automatic tagging survives via a NEW `scripts/release.sh tag-after-merge <slug>` subcommand that `/4-release` runs after the PR merges. The plan is authoritative — follow its Approach and Acceptance criteria exactly.

Footprint (the hard boundary — do not modify files outside this list):
- `scripts/release.sh` — remove the `self` path, `human_pr_review_mode()`, `check_ff_possible()`, the `git tag`/tag-exists check, the `git -C "$main_checkout" merge --ff-only`; drop the two `check_clean_worktree "$main_checkout"` calls (keep the `worktree_for_branch main` existence lookup); simplify `rollback_release` to just reset the branch HEAD (no tag deletion); rewrite `usage()` so no "self-review"/"platform-team" prose survives. ADD a `tag-after-merge <slug>` subcommand (see constraints).
- `config.yaml` — remove the `review:` block entirely.
- `.claude/skills/4-release/SKILL.md` — single Owner-confirmed push of the release BRANCH (never `main`); add a post-merge tag phase that runs `bash scripts/release.sh tag-after-merge <slug>` then, Owner-confirmed, `git push origin v<version>`.
- `profiles/work.md` — delete the "Review topology" declaration, both topology sections, the platform-team sync subtlety, and the manual-tag section. Keep only: the Claude implementer runtime/command, the Bitbucket Pipelines CI swap, and the Jira reference-only stance. Release topology is now base behavior — a one-line pointer to the base flow is enough.
- `CLAUDE.md` — invariant #5 wording only: `release.sh` no longer creates a tag or fast-forward-merges `main`. New sense: it owns preconditions, versioning, changelog assembly, and the release commit on the branch; it never pushes and never touches `main`; tagging happens in `/4-release` after the PR merges (via `tag-after-merge`).
- `tests/test-scripts.sh` — see constraints.

Do NOT touch: `ARCHI.md` (regenerated later by `/compact`), `.claude/skills/init/SKILL.md`, `scripts/agent-exec.sh`, `scripts/worktree.sh`, `scripts/gate.sh`, `bitbucket-pipelines.yml`, `work/**` other than this unit.

## Key constraints

1. **`release()` single flow** — after removing the `self` branch, `release()` runs the shared preconditions and calls `check_origin_main_ancestor` BOTH before and after `check_gate` (this is the existing collision guard — leave its double-call intact), commits the `VERSION`+`CHANGELOG.md` bump on `wt/<slug>`, creates NO tag, and never merges/touches `main`. Print the branch-push/PR guidance message. Keep `next_version` read once off the branch `VERSION`.

2. **`tag-after-merge <slug>` subcommand** — must:
   - `git fetch origin main`.
   - Read the release branch's `VERSION` → `<version>`.
   - VERIFY `origin/main`'s tip is actually this release: the tip commit's tree has `VERSION` == `<version>` AND the tip commit's subject is exactly `Release v<version>`. If not, `die` with a clear message (this prevents tagging the wrong commit when another PR merged to `origin/main` between the merge and the fetch).
   - Refuse if tag `v<version>` already exists.
   - Create the tag `v<version>` on the `origin/main` tip, LOCALLY. Do NOT push — there must be NO `git push` anywhere in `release.sh`. The push is the orchestrator's job in `/4-release`.
   - Read `origin/main`'s VERSION content via `git show origin/main:VERSION` (or equivalent); read its subject via `git log -1 --format=%s origin/main`.

3. **`invariant #5 / never pushes`** — `release.sh` must contain no `git push`. Verify with grep before finishing.

4. **Tests** (`tests/test-scripts.sh`):
   - Drop `setup_release_fixture`'s `review_mode` parameter (currently `local review_mode="${6:-self}"`) and stop writing the `review:`/`human_pr_review:` block into the fixture `config.yaml`.
   - DELETE the self-only tests: `release-happy` (asserts ff-merge into main + tag), `release-tag-race-rolls-back`, and remove the tag expectation from `release-happy-primary`.
   - PROMOTE the three `release-platform-*` tests to be THE canonical release tests (rename their descriptions off "platform-team"; drop the trailing `platform-team` fixture arg): happy = bump-commit-on-branch + `main` unchanged + `origin/main` unchanged + no `v<version>` tag; keep the sequential-collision test (stale branch refused with the `rebase/sync` message, then next micro after sync) and the mid-gate test (competing push to `origin` during the gate caught by the post-gate re-check).
   - Keep the mode-agnostic refusal tests (no-verdict, gate-fails, archi-stale, version-regresses) and a "runnable from primary checkout" variant (without the tag assertion).
   - ADD `tag-after-merge` coverage: (a) HAPPY — after the bump commit is pushed to `origin/main` (simulating the merged PR), `tag-after-merge` creates `v<version>` locally on the `origin/main` tip and pushes nothing; (b) WRONG-COMMIT REFUSAL — `origin/main` has advanced one commit past this release's bump (subject/VERSION no longer match), so `tag-after-merge` dies without creating the tag.

## When done
1. Run `scripts/gate.sh` from the repo root — it must pass (shellcheck + the smoke suite including your new tests).
2. Commit your work on this branch with a clear message.
3. Print a final summary: what changed and why, any acceptance criteria only partially met, and any out-of-scope observations. If you believe the footprint must expand, STOP and report it rather than editing outside the list.

codex
I’ll read the repo contract and the work-unit plan first, then verify the branch before touching anything. After that I’ll inspect only the declared footprint and make the scoped changes.
exec
/bin/zsh -lc "sed -n '1,220p' AGENTS.md" in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
 succeeded in 0ms:
# Implementer Contract

You are the implementer. Your source of truth is the handoff you received; it names the work unit (`work/<slug>/plan.md`), the branch, and the file footprint.

## Rules

1. **Scope is the plan. Nothing more.** No refactoring adjacent code, no speculative features. If the work seems to require a file outside the declared footprint, stop and say so instead of expanding it yourself.
2. **You are in a worktree on a pre-created branch.** Verify the branch matches the handoff before changing anything. Do not switch, merge, rebase, or reset.
3. **Run the gate before finishing:** `scripts/gate.sh` from the repo root. Do not report done while it fails.
4. **Finish with a summary**: what changed and why, any acceptance criteria only partially met (and why), anything you noticed but left out of scope.
5. **Stop and surface** rather than guess when: acceptance criteria conflict, the plan seems wrong against the actual code, or a decision belongs to the Orchestrator or Owner.

Honest and brief beats thorough and padded.

exec
/bin/zsh -lc "sed -n '1,260p' work/pr-merge-topology/plan.md" in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
 succeeded in 0ms:
# PR-merge as the only release topology

**Slug:** pr-merge-topology · **Date:** 2026-08-25 · **Status:** approved

## Goal

Every Bitbucket repo at work protects `main` on creation, and the Owner wants branch protection everywhere (personal included): CI must gate a PR *before* it lands, never check `main` after the fact. The current `self` topology pushes directly to `main` (`release.sh` ff-merges + tags, `/4-release` pushes `main`+tag) — a direct push protected `main` rejects by policy, so `self` is unusable in any protected repo. Collapse the two topologies into **one universal PR-merge flow**: `release.sh` stages the version bump on the release branch and never touches `main`; `/4-release` pushes the branch for a PR, and — after the PR merges — creates and pushes the version tag. Done = the `self` code path, the `review.human_pr_review` knob, and their tests are gone; the single flow works and is proven by the existing collision/mid-gate tests; tags are still created automatically, just after the merge instead of before.

This reverses the 2026-08-24 config-selected-topology decision (`work/work-profile`) on purpose — that design kept a direct-push mode the Owner has since rejected. Owner decisions locked at plan time: **delete `self` entirely** (not keep as an escape hatch), and **`/4-release` auto-tags** post-merge (not manual tagging).

## Approach

One topology, no knob. `release.sh` becomes what `platform-team` already was; `/4-release` gains a post-merge tag phase so automatic tagging survives the loss of the local ff-merge.

- **`scripts/release.sh`** — delete `human_pr_review_mode()`, `check_ff_possible()`, both `if [[ "$review_mode" == self ]]` branches, the `git tag`/tag-exists check, and the `git -C "$main_checkout" merge --ff-only`. `release()` keeps the shared preconditions and runs `check_origin_main_ancestor` **before and after `check_gate`** (unchanged — closes the cross-release version collision), commits the bump on `wt/<slug>`, and prints the branch-push/PR message. Keep the `main_checkout` **existence lookup** (`worktree_for_branch main` — worktrees are cut from the primary, so it must exist), but **drop the two `check_clean_worktree "$main_checkout"` calls**: post-collapse `release()` never mutates `main`, so the primary's cleanliness has no bearing on release safety (F3). Rollback: the only mutation left is one commit on the branch, so simplify `rollback_release` to reset the branch HEAD to `pre_release_head` and drop the tag deletion. Rewrite `usage()` for the single flow — no "self-review"/"platform-team" prose survives. `next_version` is read once off the branch's `VERSION` (post-rebase = newest merged release), as today.
  - Alternative rejected: keep `self` as an escape hatch for remote-less repos — Owner chose full deletion; a mode nobody should use is exactly the process cruft to avoid.
- **`scripts/release.sh tag-after-merge <slug>` (new subcommand)** — keeps tagging a *script* mutation with an exit-code contract and test coverage, instead of raw orchestrator git (F1). It: `git fetch origin main`; reads the release branch's `VERSION`; **verifies `origin/main`'s tip is this release** — its tree's `VERSION` equals `<version>` **and** its subject is `Release v<version>` — dying otherwise so a `main` that moved to another PR between merge and fetch cannot be mistagged; then creates `v<version>` **on the `origin/main` tip locally**. It does **not** push — the tag push stays `/4-release`'s Owner-confirmed step, so invariant #5 ("release.sh never pushes") holds. Refuses if `v<version>` already exists.
- **`config.yaml`** — remove the `review:` block entirely.
- **`.claude/skills/4-release/SKILL.md`** — rewrite steps 3–4 to the single path and add a tag phase:
  1. (unchanged) confirm intent, capture `Confirm-delta`.
  2. (unchanged) run `release.sh <slug> --confirm-delta …`.
  3. Exit 0 → report the bump commit on the release branch, that no tag exists **yet**, and that `main` is untouched. Non-zero → report output, stop.
  4. **Push (Owner-confirmed):** push the release branch, print the "open a PR, get it merged" instruction, never push `main`. This push stays the single TRIP/`Confirm-delta` clock event.
  5. **Tag after merge:** once the Owner confirms the PR has merged (a factual checkpoint, not a second risk-gate), run `bash scripts/release.sh tag-after-merge <slug>` (fetches + verifies + creates the local tag, or dies if `origin/main` isn't this release's commit), then — Owner-confirmed — `git push origin v<version>`. The verify-then-tag lives in the script; only the push is the Orchestrator's.
- **`profiles/work.md`** — drop the "Review topology" declaration, both topology sections, the platform-team sync subtlety, and the manual-tag section (tagging is now automatic + universal). Keep only what's genuinely Bitbucket/work-specific: the Claude implementer runtime, the Bitbucket Pipelines CI swap, and the Jira reference-only stance. Release topology is now base behavior, so work.md stops describing it (a one-line pointer to the base flow is enough).
- **`CLAUDE.md`** — invariant #5 wording: `release.sh` no longer tags or ff-merges. New: it owns preconditions, versioning, changelog assembly, and the release commit on the branch; it never pushes and never touches `main`; tagging happens in `/4-release` after the PR merges.
- **`tests/test-scripts.sh`** — drop `setup_release_fixture`'s `review_mode` param and stop writing a `review:` block to the fixture `config.yaml`. Delete the self-only tests: `release-happy` (ff+tag assertions), `release-tag-race-rolls-back` (no tag to fail), and the tag expectation in `release-happy-primary`. Promote the three `release-platform-*` tests to the canonical release tests (rename off "platform-team"): happy = bump-on-branch + `main` untouched + `origin/main` untouched + no tag; keep the sequential collision test (stale branch refused, then next micro after sync) and the mid-gate test (competing push to `origin` during the gate caught by the post-gate re-check). Keep the mode-agnostic refusal tests (no-verdict, gate-fails, archi-stale, version-regresses) and a "runnable from the primary checkout" variant. **Add `tag-after-merge` coverage** (replaces the deleted tag-race test): (a) happy — after the bump commit is pushed to `origin/main`, `tag-after-merge` creates `v<version>` locally on the `origin/main` tip and pushes nothing; (b) **wrong-commit refusal** — `origin/main` advanced past this release (another commit on top), so the verify step dies without tagging. `bash scripts/gate.sh` must exit 0.
- **`PLAN.md`** — add a decision line (collapse to single PR-merge topology; supersedes 2026-08-24); refresh `Now`.

## Footprint

Files to modify:
- `scripts/release.sh` — remove `self` path, knob parser, tag/ff-merge; single PR-merge flow; add `tag-after-merge <slug>` subcommand (verify + local tag, no push)
- `config.yaml` — remove the `review:` block
- `.claude/skills/4-release/SKILL.md` — single push path + post-merge tag phase
- `profiles/work.md` — drop the two topologies + manual-tag; keep Claude/Bitbucket-CI/Jira
- `CLAUDE.md` — invariant #5 wording (no tag / no ff-merge in release.sh)
- `tests/test-scripts.sh` — drop self-only tests + `review_mode`; promote the universal ones
- `PLAN.md` — decision + Now

Files NOT to touch:
- `ARCHI.md` — regenerated by `/compact`; touching `scripts/ skills/ profiles/ config.yaml CLAUDE.md` makes it stale, so `/compact` runs before `/4-release` (expected).
- `.claude/skills/init/SKILL.md` — the `work` enum entry stays valid; the only review-topology declaration lived in `profiles/work.md`, which this removes.
- `scripts/agent-exec.sh`, `scripts/worktree.sh`, `scripts/gate.sh`, `bitbucket-pipelines.yml` — unaffected.

## Acceptance criteria

- [ ] `grep -E 'human_pr_review|platform-team|self-review|check_ff_possible|merge --ff-only' scripts/release.sh` returns nothing, and `usage()` no longer names either mode; `release()` calls `check_origin_main_ancestor` twice (before and after `check_gate`), commits the bump on `wt/<slug>`, creates no tag, never runs a `main` merge, and no longer calls `check_clean_worktree` on `main_checkout` (its existence lookup stays).
- [ ] `scripts/release.sh tag-after-merge <slug>` exists: it fetches `origin/main`, dies unless the tip's `VERSION` equals `<version>` and its subject is `Release v<version>`, then creates the local tag `v<version>` and pushes nothing (no `git push` anywhere in `release.sh`).
- [ ] `grep -n 'review:' config.yaml` returns nothing.
- [ ] `tests/test-scripts.sh` contains no `review_mode`, `human_pr_review`, or `platform-team`; the happy-path test asserts bump-commit-on-branch + `main` unchanged + `origin/main` unchanged + no `v<version>` tag; the sequential-collision and mid-gate tests are retained; the tag-race rollback test is removed; a `tag-after-merge` happy test and a wrong-commit-refusal test are added.
- [ ] `.claude/skills/4-release/SKILL.md` has a single Owner-confirmed push of the release branch (never `main`) and a post-merge phase that runs `release.sh tag-after-merge <slug>` then, Owner-confirmed, pushes the tag.
- [ ] `profiles/work.md` has no `self`/`platform-team` topology text, no manual-tag section, and no review-topology declaration; it still documents the Claude implementer command, the Bitbucket Pipelines CI swap, and Jira reference-only.
- [ ] `CLAUDE.md` invariant #5 no longer claims `release.sh` creates a tag or fast-forward-merges `main`.
- [ ] `bash scripts/gate.sh` exits 0.

## Release

Release note: Collapse to a single PR-merge release topology under protected `main` — `release.sh` never touches `main`, `/4-release` pushes the branch for a PR and tags after it merges; the `self` direct-push mode and `review.human_pr_review` knob are removed.

## Verification

- `bash scripts/gate.sh` — green (shellcheck over `release.sh`/`tests`, smoke suite with the promoted universal tests).
- Run `/compact` before `/4-release` to refresh `ARCHI.md` (scripts/skills/profiles/config.yaml/CLAUDE.md all touched → staleness gate refuses release otherwise).

## Review

**Round 1 (plan-reviewer, REVISE):** three findings, all applied.
- *F1 — post-merge tagging was untested raw orchestrator git with a wrong-commit race* (if `origin/main` moves between the merge and the fetch, the tag lands on another PR's commit). Applied: tagging becomes a `scripts/release.sh tag-after-merge <slug>` subcommand that fetches and **verifies** `origin/main`'s tip carries this release's `VERSION` + `Release v<version>` subject before creating the local tag; it pushes nothing (the tag push stays `/4-release`'s Owner-confirmed step, so invariant #5 holds). A wrong-commit-refusal test replaces the deleted tag-race test.
- *F2 — acceptance grep missed stale "self-review" prose in `usage()`.* Applied: added `self-review` to criterion 1's grep and required `usage()` rewritten.
- *F3 — `main_checkout` clean-check rationale doesn't hold post-collapse* (`main` is never mutated). Applied: dropped the two `check_clean_worktree "$main_checkout"` calls; kept only the existence lookup.

Reviewer confirmed the rest of the footprint complete (init needs no change; `rollback_release` simplification correct; collision guard correctly preserved; the `release-platform-*` tests already assert what the plan promotes).

Plan verdict: APPROVE (all REVISE findings incorporated)

exec
/bin/zsh -lc 'pwd && git branch --show-current' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
 succeeded in 0ms:
/Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
wt/pr-merge-topology

codex
Branch and contract are verified. I noticed the plan mentions `PLAN.md`, but your hard footprint list omits it; I’m treating the hard boundary in the handoff as controlling and will not edit `PLAN.md`.
exec
/bin/zsh -lc "sed -n '1,280p' scripts/release.sh" in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
 succeeded in 0ms:
#!/usr/bin/env bash
# Release driver. Exit 0 = release staged locally. Non-zero = stop and report.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

usage() {
  cat <<'EOF'
Usage:
  scripts/release.sh <slug> [--confirm-delta <text>]
  scripts/release.sh check-version <new-version> [current-version]
  scripts/release.sh next-version [current-version]

The full release path never pushes. In self-review mode it commits, tags,
fast-forward merges to local main, then stops for the Owner-confirmed push step.
In platform-team mode it commits the bump on the release branch for PR review.
EOF
}

die() {
  echo "release: $*" >&2
  exit 1
}

valid_version() {
  [[ "$1" =~ ^([1-9][0-9]{3})\.([1-9]|1[0-2])\.(0|[1-9][0-9]*)$ ]]
}

version_gt() {
  local new="$1"
  local old="$2"
  local new_year new_month new_micro old_year old_month old_micro

  valid_version "$new" || die "invalid new version '$new' (expected YYYY.M.MICRO)"
  valid_version "$old" || die "invalid current version '$old' (expected YYYY.M.MICRO)"

  IFS=. read -r new_year new_month new_micro <<<"$new"
  IFS=. read -r old_year old_month old_micro <<<"$old"

  if (( new_year > old_year )); then return 0; fi
  if (( new_year < old_year )); then return 1; fi
  if (( new_month > old_month )); then return 0; fi
  if (( new_month < old_month )); then return 1; fi
  (( new_micro > old_micro ))
}

next_version() {
  local current="$1"
  local today year month current_year current_month current_micro

  valid_version "$current" || die "invalid current version '$current' (expected YYYY.M.MICRO)"
  today=$(date +%Y.%-m)
  IFS=. read -r year month <<<"$today"
  IFS=. read -r current_year current_month current_micro <<<"$current"

  if (( year == current_year && month == current_month )); then
    printf '%s.%s.%s\n' "$current_year" "$current_month" "$((current_micro + 1))"
  else
    printf '%s.%s.0\n' "$year" "$month"
  fi
}

extract_release_note() {
  local plan_path="$1"
  local note

  # Release notes are intentionally one line so changelog assembly stays deterministic.
  note=$(
    sed -n -E 's/^\**Release note:\**[[:space:]]*//p' "$plan_path" | head -n 1
  )
  [[ -n "$note" ]] || die "$plan_path is missing a Release note: line"
  printf '%s\n' "$note"
}

prepend_changelog() {
  local version="$1"
  local release_note="$2"
  local confirm_delta="$3"
  local date_stamp
  local tmp

  date_stamp=$(date +%F)
  tmp=$(mktemp)

  {
    if [[ -f CHANGELOG.md ]]; then
      sed -n '1,/^## /{ /^## /q; p; }' CHANGELOG.md
    else
      printf '# Changelog\n\n'
      printf 'All notable changes to this project are documented in this file.\n\n'
    fi
    printf '## [%s] - %s\n\n' "$version" "$date_stamp"
    printf '%s\n' "- $release_note"
    printf '%s\n\n' "- Confirm-delta: $confirm_delta"
    if [[ -f CHANGELOG.md ]]; then
      sed -n '/^## /,$p' CHANGELOG.md
    fi
  } >"$tmp"

  mv "$tmp" CHANGELOG.md
}

check_verdict() {
  local plan_path="$1"
  grep -qx 'Code-review verdict: APPROVE' "$plan_path" \
    || die "$plan_path must contain exact line: Code-review verdict: APPROVE"
}

check_gate() {
  bash scripts/gate.sh || die "scripts/gate.sh failed"
}

check_archi_fresh() {
  local archi_epoch source_epoch

  archi_epoch=$(git log -1 --format=%ct -- ARCHI.md)
  source_epoch=$(git log -1 --format=%ct -- scripts/ skills/ profiles/ config.yaml CLAUDE.md)

  [[ -n "$archi_epoch" ]] || die "ARCHI.md has no git history"
  [[ -n "$source_epoch" ]] || die "source paths have no git history"

  if (( archi_epoch < source_epoch )); then
    die "ARCHI.md is stale; run /compact first"
  fi
}

check_version_exceeds() {
  local new_version="$1"
  local current_version="$2"

  version_gt "$new_version" "$current_version" \
    || die "new version $new_version must exceed VERSION $current_version"
}

worktree_for_branch() {
  local branch="$1"

  git worktree list --porcelain | awk -v branch="refs/heads/$branch" '
    $1 == "worktree" {
      path = substr($0, 10)
      next
    }
    $1 == "branch" && $2 == branch {
      print path
      found = 1
      exit
    }
    END {
      if (!found) exit 1
    }
  '
}

check_clean_worktree() {
  local checkout="$1"
  local label="$2"

  git -C "$checkout" diff --quiet || die "$label has unstaged changes"
  git -C "$checkout" diff --cached --quiet || die "$label has staged changes"
  [[ -z "$(git -C "$checkout" ls-files --others --exclude-standard)" ]] \
    || die "$label has untracked files"
}

check_ff_possible() {
  local main_checkout="$1"
  local release_branch="$2"

  git -C "$main_checkout" rev-parse --verify --quiet "$release_branch" >/dev/null \
    || die "missing release branch: $release_branch"
  git -C "$main_checkout" merge-base --is-ancestor main "$release_branch" \
    || die "main cannot fast-forward to $release_branch"
}

human_pr_review_mode() {
  local mode

  mode=$(awk '/^review:/{f=1;next} f&&/human_pr_review:/{print $2; exit}' config.yaml)
  mode=${mode:-self}
  case "$mode" in
    self|platform-team) printf '%s\n' "$mode" ;;
    *) die "invalid review.human_pr_review '$mode' (expected self or platform-team)" ;;
  esac
}

check_origin_main_ancestor() {
  local release_branch="$1"

  git fetch origin main
  git rev-parse --verify --quiet origin/main >/dev/null \
    || die "missing origin/main after fetch"
  git merge-base --is-ancestor origin/main "$release_branch" \
    || die "$release_branch is stale; rebase/sync your branch onto origin/main"
}

rollback_release() {
  local status=$?
  local pre_release_head="$1"
  local new_version="$2"

  trap - ERR
  set +e
  git tag -d "v$new_version" >/dev/null 2>&1
  git reset --hard "$pre_release_head" >/dev/null 2>&1
  echo "release: irreversible step failed; release commit and tag changes were rolled back" >&2
  exit "$status"
}

release() {
  local slug="$1"
  local confirm_delta="$2"
  local plan_path="work/$slug/plan.md"
  local release_branch="wt/$slug"
  local main_checkout
  local release_checkout
  local current_version
  local new_version
  local release_note
  local pre_release_head
  local review_mode

  main_checkout=$(worktree_for_branch main) \
    || die "main must be checked out in the primary worktree"
  release_checkout=$(worktree_for_branch "$release_branch") \
    || die "$release_branch must be checked out in a linked worktree"

  [[ -f "$release_checkout/$plan_path" ]] || die "missing work unit plan: $plan_path"
  [[ -f "$release_checkout/VERSION" ]] || die "missing VERSION"

  cd "$release_checkout"
  current_version=$(<VERSION)
  new_version=$(next_version "$current_version")
  review_mode=$(human_pr_review_mode)

  check_verdict "$plan_path"
  check_clean_worktree "$release_checkout" "$release_branch"
  check_clean_worktree "$main_checkout" "main checkout"
  if [[ "$review_mode" == self ]]; then
    check_ff_possible "$main_checkout" "$release_branch"
    git rev-parse --verify --quiet "refs/tags/v$new_version" >/dev/null \
      && die "tag v$new_version already exists"
  else
    check_origin_main_ancestor "$release_branch"
  fi
  check_gate
  check_clean_worktree "$release_checkout" "$release_branch"
  check_archi_fresh
  check_version_exceeds "$new_version" "$current_version"
  check_clean_worktree "$main_checkout" "main checkout"
  if [[ "$review_mode" == self ]]; then
    check_ff_possible "$main_checkout" "$release_branch"
  else
    check_origin_main_ancestor "$release_branch"
  fi

  release_note=$(extract_release_note "$plan_path")
  pre_release_head=$(git rev-parse HEAD)
  trap 'rollback_release "$pre_release_head" "$new_version"' ERR

  printf '%s\n' "$new_version" >VERSION
  prepend_changelog "$new_version" "$release_note" "$confirm_delta"

  git add VERSION CHANGELOG.md
  git commit -m "Release v$new_version"
  if [[ "$review_mode" == self ]]; then
    git tag "v$new_version"
    git -C "$main_checkout" merge --ff-only "$release_branch"
  fi
  trap - ERR

  if [[ "$review_mode" == self ]]; then
    cat <<EOF
release: prepared v$new_version on local main
release: stopped before push; push requires Owner confirmation in-session
EOF
  else
    cat <<EOF
release: prepared v$new_version on $release_branch
release: no tag created; local main untouched
release: push $release_branch, open a Bitbucket PR, and have a platform engineer merge it
EOF

exec
/bin/zsh -lc "sed -n '1,220p' config.yaml" in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
 succeeded in 0ms:
# The one knob. Everything vendor- or project-specific lives here.

profile: software            # software | machine-learning | database | work

models:
  orchestrator: inherit      # the main Claude Code session
  plan_reviewer: sonnet      # fresh subagent, .claude/agents/plan-reviewer.md
  code_reviewer: sonnet      # fresh subagent, .claude/agents/code-reviewer.md

implementer:
  runtime: codex             # codex | claude | custom
  # Command receives the handoff on stdin, runs inside the worktree.
  command: 'codex exec --sandbox workspace-write -'
  # Claude Code implementer alternative:
  # command: 'claude -p --dangerously-skip-permissions'

review:
  human_pr_review: self      # self | platform-team

gate:
  command: scripts/gate.sh
  max_retries: 2             # failed-gate feedback loops before escalating to the Owner

worktrees:
  dir: ../agentic-coding-worktrees

exec
/bin/zsh -lc "sed -n '1,260p' profiles/work.md" in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
exec
/bin/zsh -lc "sed -n '1,260p' .claude/skills/4-release/SKILL.md" in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
 succeeded in 0ms:
# Profile: work

For workplace repositories that use Atlassian/Bitbucket review and CI conventions while keeping this template as the single source.

## Declarations required at /init

- **Review topology** — set `review.human_pr_review` to `self` or `platform-team`.
- **Implementer runtime** — when the workplace uses Claude Code for implementation, set `implementer.runtime: claude` and use:

```yaml
implementer:
  runtime: claude
  command: 'claude -p --dangerously-skip-permissions'
```

## Adds to the loop

- **Jira:** Jira keys may be recorded as read-only references in `work/<slug>/plan.md`. The loop never creates or mutates Jira issues.
- **Self review topology:** `scripts/release.sh` keeps the base release shape: it bumps `VERSION` and `CHANGELOG.md`, creates `vX.Y.Z`, fast-forwards local `main`, and stops before push. `/4-release` pushes `main` and the tag only after Owner confirmation.
- **Platform-team review topology:** `scripts/release.sh` fetches `origin/main`, refuses when the release branch does not contain it, bumps `VERSION` and `CHANGELOG.md` on the release branch, creates no tag, and leaves local `main` untouched. `/4-release` pushes the release branch and prints the Bitbucket PR instruction; a platform engineer merges the PR.

## Gate

Replace GitHub Actions with Bitbucket Pipelines during /init:

- Add `bitbucket-pipelines.yml`.
- Delete `.github/workflows/ci.yml`.
- Keep the deterministic commands equivalent: install `shellcheck`, set a git identity, run `bash tests/test-scripts.sh`, then run `bash scripts/gate.sh`.

## Platform-team release sync

The platform-team release path treats remote `origin/main` as the current source of truth. `scripts/release.sh` fetches it before and after the gate, then refuses with a rebase/sync message if the release branch is stale.

Keep the local `main` worktree pulled from the PR-merged remote before cutting new work. The required `main` worktree check only proves the linked worktree exists; it does not prove local `main` is current, because the release guard checks `origin/main`.

Tagging is permanently manual in platform-team mode. If a tag is wanted after the Bitbucket PR merges, run:

```sh
git tag vX.Y.Z <merge-commit> && git push origin vX.Y.Z
```

 succeeded in 0ms:
---
name: 4-release
description: Run the release script for a work unit, then handle the separate Owner-confirmed push.
---

# /4-release — release

Input: a work unit slug.

## Steps

1. **Confirm intent:** ask the Owner for the in-session release confirmation and capture the `Confirm-delta:` value.
2. **Run the release script:** from the repo root, run `bash scripts/release.sh <slug> --confirm-delta "<value>"`.
3. **React to the exit code based on `review.human_pr_review`:**
   - Exit 0 with `self` → report the prepared version, tag, and local `main` state.
   - Exit 0 with `platform-team` → report the bump commit on the release branch, that no tag was created, and that local `main` was untouched.
   - Non-zero → report the script output and stop.
4. **Push separately based on `review.human_pr_review`:**
   - `self` → after the Owner confirms the push, push `main` and the new tag.
   - `platform-team` → after the Owner confirms the push, push the release branch, print instructions to open a Bitbucket PR, and never push `main`.

## Rules

- The release script is the source of truth for the release result.
- The push is a separate Owner-confirmed action.

exec
/bin/zsh -lc "sed -n '1,220p' CLAUDE.md" in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
 succeeded in 0ms:
# Constitution

You are the **Orchestrator** for this project. The human is the **Owner**. You plan, dispatch, and drive the loop; you do not silently make product decisions and you do not review your own work.

## The Loop

```
/1-plan  →  /2-implement  →  /3-review  →  /4-release
```

- **/1-plan** — draft a work unit in `work/<slug>/plan.md`; a fresh reviewer subagent critiques it before it's real.
- **/2-implement** — dispatch the implementer agent into an isolated worktree; run the gate; feed failures back until green or retries exhausted.
- **/3-review** — a fresh reviewer subagent (different model, cold context, read-only) reviews the diff against the plan.
- **/4-release** — the Orchestrator runs the release, including the push, after one in-session Owner confirmation.

Each release logs `Confirm-delta:` in `CHANGELOG.md` as `none` or the change caused by confirmation. After 4 consecutive `none` entries, the Owner promotes to full autonomy by deleting the confirmation requirement with a one-line edit here.

Small fixes (typos, one-liners, config tweaks) skip the loop: just do them on a branch and tell the Owner. The loop is for work with enough surface to get wrong.

## Invariants (mechanical, not aspirational)

1. **Writer never reviews.** Reviews come from fresh subagents defined in `.claude/agents/` — read-only tools, separate model. Never review a diff produced in your own thread.
2. **The gate is a script.** `scripts/gate.sh` exits 0 or it doesn't. You do not overrule it, reinterpret it, or declare work done while it fails.
3. **Implementation happens in worktrees**, never in this checkout. `scripts/worktree.sh` manages them.
4. **Artifacts flow between stages, not transcripts.** The reviewer gets the diff + plan, never the implementation conversation.
5. **Release is a script.** `scripts/release.sh` owns release preconditions, versioning, changelog assembly, the release commit, tag, and local fast-forward merge. It never pushes.

## Context tiers

- **Hot** (always loaded): this file, `ARCHI.md`, `PLAN.md`. Combined budget ~300 lines — if it grows past that, run `/compact`.
- **Warm** (on invocation): the active skill and the active profile (`config.yaml` → `profiles/`).
- **Cold** (on citation): `knowledge/` docs. Load one only when a task names it.

## Config

`config.yaml` declares the profile, models per role, implementer runtime, and gate settings. Read it at session start. It is the only place vendor/model names live.

## Judgment defaults

- Prefer simple and reversible. Delete dead code. Match surrounding style.
- State assumptions instead of silently making them; ask only when the answer changes what you'd build.
- Record decisions worth keeping as one line in `PLAN.md` — link to the work unit for the reasoning. No essays.

exec
/bin/zsh -lc "sed -n '1,360p' tests/test-scripts.sh" in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
 succeeded in 0ms:
#!/usr/bin/env bash
# Smoke tests for the deterministic layer. Run from repo root: bash tests/test-scripts.sh
set -uo pipefail

pass=0; fail=0
check() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "ok: $desc"; pass=$((pass+1))
  else
    echo "FAIL: $desc"; fail=$((fail+1))
  fi
}
check_fails() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "FAIL: $desc (expected non-zero exit)"; fail=$((fail+1))
  else
    echo "ok: $desc"; pass=$((pass+1))
  fi
}

ROOT=$(git rev-parse --show-toplevel)
cd "$ROOT" || exit 1

commit_fixture() {
  local repo="$1"
  local stamp="$2"
  local msg="$3"

  (
    cd "$repo" || exit 1
    git add -A
    GIT_AUTHOR_DATE="$stamp" GIT_COMMITTER_DATE="$stamp" git commit -qm "$msg"
  )
}

write_release_fixture_date() {
  local bin_dir="$1"
  local ym="$2"
  local ymd="$3"

  mkdir -p "$bin_dir"
  cat >"$bin_dir/date" <<EOF
#!/usr/bin/env bash
case "\${1:-}" in
  +%Y.%-m) printf '%s\n' "$ym" ;;
  +%F) printf '%s\n' "$ymd" ;;
  *) /bin/date "\$@" ;;
esac
EOF
  chmod +x "$bin_dir/date"
}

setup_release_fixture() {
  local name="$1"
  local version="$2"
  local verdict_line="$3"
  local gate_mode="$4"
  local archi_mode="$5"
  local review_mode="${6:-self}"
  local tmp_root="$TMP/$name"

  REL_PRIMARY="$tmp_root/primary"
  REL_WORKTREE="$tmp_root/demo-wt"
  REL_REMOTE="$tmp_root/remote.git"
  REL_FAKEBIN="$tmp_root/bin"

  mkdir -p "$tmp_root"
  git init -q -b main "$REL_PRIMARY"
  git init -q --bare "$REL_REMOTE"
  (
    cd "$REL_PRIMARY" || exit 1
    git config user.email tester@example.com
    git config user.name Tester
    git remote add origin "$REL_REMOTE"

    mkdir -p scripts skills/3-review skills/1-plan/prompts work/demo
    cp "$ROOT/scripts/release.sh" scripts/release.sh
    cat >scripts/gate.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
if [[ -f GATE_FAIL ]]; then
  echo "GATE: FAIL"
  exit 1
fi
if compgen -G "scripts/gate.d/*.sh" >/dev/null; then
  for hook in scripts/gate.d/*.sh; do
    bash "$hook"
  done
fi
echo "GATE: PASS"
EOF
    chmod +x scripts/release.sh scripts/gate.sh
    {
      printf 'name: fixture\n'
      printf 'review:\n'
      printf '  human_pr_review: %s\n' "$review_mode"
    } >config.yaml
    printf 'merge rules\n' >CLAUDE.md
    printf '%s\n' "$version" >VERSION
    printf '# Changelog\n\nAll notable changes to this project are documented in this file.\n\n' >CHANGELOG.md
    {
      printf '# Demo\n\n'
      printf '## Release\n\n'
      printf 'Release note: Demo release note.\n\n'
      printf '## Review\n\n'
      printf '%s\n' "$verdict_line"
    } >work/demo/plan.md
    [[ "$gate_mode" == fail ]] && printf 'fail\n' >GATE_FAIL
  )
  commit_fixture "$REL_PRIMARY" "2026-08-16T10:00:00Z" source
  printf 'architecture\n' >"$REL_PRIMARY/ARCHI.md"
  commit_fixture "$REL_PRIMARY" "2026-08-16T10:01:00Z" archi
  if [[ "$archi_mode" == stale ]]; then
    printf 'merge rules updated\n' >>"$REL_PRIMARY/CLAUDE.md"
    commit_fixture "$REL_PRIMARY" "2026-08-16T10:02:00Z" stale-source
  fi
  (
    cd "$REL_PRIMARY" || exit 1
    git push -q -u origin main
    git branch wt/demo
    git worktree add -q "$REL_WORKTREE" wt/demo
    git -C "$REL_WORKTREE" config user.email tester@example.com
    git -C "$REL_WORKTREE" config user.name Tester
  )
  write_release_fixture_date "$REL_FAKEBIN" "2026.8" "2026-08-16"
}

# --- shellcheck the scripts themselves (gate.sh covers this too; belt+braces)
if command -v shellcheck >/dev/null; then
  check "shellcheck scripts" shellcheck scripts/*.sh tests/*.sh
fi

# --- worktree.sh lifecycle in a throwaway repo
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
(
  cd "$TMP"
  git init -q -b main sandbox && cd sandbox
  git commit -q --allow-empty -m init
  cp "$ROOT/scripts/worktree.sh" wt.sh
  printf 'worktrees:\n  dir: ../wts\n' > config.yaml
  git add -A && git commit -qm files
) || { echo "FAIL: sandbox setup"; exit 1; }

SB="$TMP/sandbox"
WT_PATH=$(cd "$SB" && bash wt.sh add demo 2>/dev/null)
check "worktree add creates directory" test -d "$WT_PATH"
check "worktree branch checked out" bash -c "cd '$WT_PATH' && [ \"\$(git branch --show-current)\" = wt/demo ]"
check "worktree.sh works FROM INSIDE a worktree (.git-as-file)" bash -c "cd '$WT_PATH' && bash wt.sh list"
check "worktree remove" bash -c "cd '$SB' && bash wt.sh remove demo"
check_fails "worktree add without slug fails" bash -c "cd '$SB' && bash wt.sh add"

# --- agent-exec.sh argument validation
check_fails "agent-exec rejects missing handoff" bash scripts/agent-exec.sh /tmp nonexistent-handoff.md

# --- release.sh version comparison
check "release version compare accepts .10 over .9" bash scripts/release.sh check-version 2026.8.10 2026.8.9
check_fails "release version compare rejects .9 after .10" bash scripts/release.sh check-version 2026.8.9 2026.8.10

# --- release.sh refusals and happy path in the mandated worktree topology
setup_release_fixture release-no-verdict 2026.8.9 "Plan verdict: APPROVE" pass fresh
check_fails "release refuses without code-review approval" bash -c "cd '$REL_WORKTREE' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo"

setup_release_fixture release-gate-fails 2026.8.9 "Code-review verdict: APPROVE" fail fresh
check_fails "release refuses when gate fails" bash -c "cd '$REL_WORKTREE' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo"

setup_release_fixture release-archi-stale 2026.8.9 "Code-review verdict: APPROVE" pass stale
check_fails "release refuses when ARCHI.md is stale" bash -c "cd '$REL_WORKTREE' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo"

setup_release_fixture release-version-regresses 2026.9.0 "Code-review verdict: APPROVE" pass fresh
check_fails "release refuses when computed version does not exceed VERSION" bash -c "cd '$REL_WORKTREE' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo"

setup_release_fixture release-happy 2026.8.9 "Code-review verdict: APPROVE" pass fresh
origin_before=$(git -C "$REL_PRIMARY" rev-parse origin/main)
check "release happy path lands fast-forward on primary main and stops before push" bash -c "
  cd '$REL_WORKTREE' &&
  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
  [ \"\$(git -C '$REL_PRIMARY' branch --show-current)\" = main ] &&
  [ \"\$(cat '$REL_PRIMARY/VERSION')\" = 2026.8.10 ] &&
  git -C '$REL_PRIMARY' merge-base --is-ancestor wt/demo main &&
  git -C '$REL_PRIMARY' rev-parse --verify --quiet refs/tags/v2026.8.10 &&
  [ \"\$(git -C '$REL_PRIMARY' rev-parse origin/main)\" = '$origin_before' ]
"

setup_release_fixture release-tag-race-rolls-back 2026.8.9 "Code-review verdict: APPROVE" pass fresh
release_head_before=$(git -C "$REL_WORKTREE" rev-parse HEAD)
real_git=$(command -v git)
tag_fail_bin="$TMP/tag-fail-bin"
mkdir -p "$tag_fail_bin"
cat >"$tag_fail_bin/git" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == tag && "\${2:-}" == v2026.8.10 ]]; then
  "$real_git" tag v2026.8.10 HEAD~1
fi
"$real_git" "\$@"
EOF
chmod +x "$tag_fail_bin/git"
check "release rolls back cleanly when tag creation fails after prechecks" bash -c "
  cd '$REL_WORKTREE' &&
  PATH='$tag_fail_bin:$REL_FAKEBIN':\$PATH bash scripts/release.sh demo >/dev/null 2>&1 &&
  exit 1
  status=\$?
  [ \"\$status\" -ne 0 ] &&
  [ \"\$(git rev-parse HEAD)\" = '$release_head_before' ] &&
  [ \"\$(cat VERSION)\" = 2026.8.9 ] &&
  git diff --quiet &&
  git diff --cached --quiet &&
  [ -z \"\$(git ls-files --others --exclude-standard)\" ] &&
  ! git rev-parse --verify --quiet refs/tags/v2026.8.10
"

setup_release_fixture release-happy-primary 2026.8.9 "Code-review verdict: APPROVE" pass fresh
check "release can be invoked from primary checkout" bash -c "cd '$REL_PRIMARY' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo && [ \"\$(cat VERSION)\" = 2026.8.10 ]"

setup_release_fixture release-platform-single 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
origin_before=$(git -C "$REL_PRIMARY" rev-parse origin/main)
main_before=$(git -C "$REL_PRIMARY" rev-parse main)
check "platform-team release commits bump on branch without touching main or tagging" bash -c "
  cd '$REL_WORKTREE' &&
  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
  [ \"\$(git -C '$REL_PRIMARY' rev-parse main)\" = '$main_before' ] &&
  [ \"\$(git -C '$REL_PRIMARY' rev-parse origin/main)\" = '$origin_before' ] &&
  [ \"\$(cat VERSION)\" = 2026.8.10 ] &&
  [ \"\$(git log -1 --format=%s)\" = 'Release v2026.8.10' ] &&
  ! git rev-parse --verify --quiet refs/tags/v2026.8.10
"

setup_release_fixture release-platform-sequential 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
check "platform-team release refuses stale branch, then computes next micro after sync" bash -c "
  set -e
  cd '$REL_WORKTREE'
  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo
  git push -q origin wt/demo:main
  rel_b='$TMP/release-platform-sequential/b-wt'
  git -C '$REL_PRIMARY' branch wt/b main
  git -C '$REL_PRIMARY' worktree add -q \"\$rel_b\" wt/b
  git -C \"\$rel_b\" config user.email tester@example.com
  git -C \"\$rel_b\" config user.name Tester
  mkdir -p \"\$rel_b/work/b\"
  sed 's/# Demo/# B/' '$REL_WORKTREE/work/demo/plan.md' > \"\$rel_b/work/b/plan.md\"
  git -C \"\$rel_b\" add work/b/plan.md
  GIT_AUTHOR_DATE='2026-08-16T10:00:30Z' GIT_COMMITTER_DATE='2026-08-16T10:00:30Z' git -C \"\$rel_b\" commit -qm 'add b plan'
  stale_out='$TMP/platform-stale.out'
  if PATH='$REL_FAKEBIN':\$PATH bash \"\$rel_b/scripts/release.sh\" b >\"\$stale_out\" 2>&1; then
    exit 1
  fi
  grep -q 'rebase/sync your branch onto origin/main' \"\$stale_out\"
  git -C \"\$rel_b\" fetch -q origin main
  git -C \"\$rel_b\" rebase -q origin/main
  cd \"\$rel_b\"
  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh b
  [ \"\$(cat VERSION)\" = 2026.8.11 ] &&
  [ \"\$(git log -1 --format=%s)\" = 'Release v2026.8.11' ] &&
  ! git rev-parse --verify --quiet refs/tags/v2026.8.11
"

setup_release_fixture release-platform-mid-gate 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
mkdir -p "$REL_WORKTREE/scripts/gate.d"
cat >"$REL_WORKTREE/scripts/gate.d/move-origin-main.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
repo='$REL_PRIMARY'
printf 'platform merge during gate\n' >> "\$repo/platform.txt"
git -C "\$repo" add platform.txt
GIT_AUTHOR_DATE='2026-08-16T10:02:00Z' GIT_COMMITTER_DATE='2026-08-16T10:02:00Z' git -C "\$repo" commit -qm 'platform merge during gate'
git -C "\$repo" push -q origin main
EOF
chmod +x "$REL_WORKTREE/scripts/gate.d/move-origin-main.sh"
(
  cd "$REL_WORKTREE" || exit 1
  git add scripts/gate.d/move-origin-main.sh
  GIT_AUTHOR_DATE="2026-08-16T10:00:30Z" GIT_COMMITTER_DATE="2026-08-16T10:00:30Z" git commit -qm "add mid-gate hook"
)
check "platform-team release catches origin/main moving during gate" bash -c "
  cd '$REL_WORKTREE'
  mid_gate_out='$TMP/platform-mid-gate.out'
  if PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo >\"\$mid_gate_out\" 2>&1; then
    exit 1
  fi
  grep -q 'rebase/sync your branch onto origin/main' \"\$mid_gate_out\"
"

# --- gate.sh runs and exits cleanly on this repo
check "gate.sh runs on this repo" bash scripts/gate.sh

echo
echo "passed: $pass, failed: $fail"
exit "$((fail > 0 ? 1 : 0))"

exec
/bin/zsh -lc "sed -n '281,520p' scripts/release.sh" in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
exec
/bin/zsh -lc "sed -n '361,760p' tests/test-scripts.sh" in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
 succeeded in 0ms:
 succeeded in 0ms:
  fi
}

if [[ $# -eq 0 ]]; then
  usage
  exit 2
fi

case "$1" in
  check-version)
    [[ $# -eq 2 || $# -eq 3 ]] || { usage; exit 2; }
    current=${3:-$(<VERSION)}
    check_version_exceeds "$2" "$current"
    ;;
  next-version)
    [[ $# -le 2 ]] || { usage; exit 2; }
    next_version "${2:-$(<VERSION)}"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    slug="$1"
    confirm_delta="none"
    shift
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --confirm-delta)
          [[ $# -ge 2 ]] || die "--confirm-delta requires a value"
          confirm_delta="$2"
          shift 2
          ;;
        *)
          usage
          exit 2
          ;;
      esac
    done
    release "$slug" "$confirm_delta"
    ;;
esac

exec
/bin/zsh -lc 'rg -n "human_pr_review|platform-team|self-review|check_ff_possible|merge --ff-only|git push|review_mode|release-platform|release-happy|tag-race" scripts/release.sh tests/test-scripts.sh config.yaml .claude/skills/4-release/SKILL.md profiles/work.md CLAUDE.md' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
 succeeded in 0ms:
.claude/skills/4-release/SKILL.md:14:3. **React to the exit code based on `review.human_pr_review`:**
.claude/skills/4-release/SKILL.md:16:   - Exit 0 with `platform-team` → report the bump commit on the release branch, that no tag was created, and that local `main` was untouched.
.claude/skills/4-release/SKILL.md:18:4. **Push separately based on `review.human_pr_review`:**
.claude/skills/4-release/SKILL.md:20:   - `platform-team` → after the Owner confirms the push, push the release branch, print instructions to open a Bitbucket PR, and never push `main`.
scripts/release.sh:14:The full release path never pushes. In self-review mode it commits, tags,
scripts/release.sh:16:In platform-team mode it commits the bump on the release branch for PR review.
scripts/release.sh:164:check_ff_possible() {
scripts/release.sh:174:human_pr_review_mode() {
scripts/release.sh:177:  mode=$(awk '/^review:/{f=1;next} f&&/human_pr_review:/{print $2; exit}' config.yaml)
scripts/release.sh:180:    self|platform-team) printf '%s\n' "$mode" ;;
scripts/release.sh:181:    *) die "invalid review.human_pr_review '$mode' (expected self or platform-team)" ;;
scripts/release.sh:219:  local review_mode
scripts/release.sh:232:  review_mode=$(human_pr_review_mode)
scripts/release.sh:237:  if [[ "$review_mode" == self ]]; then
scripts/release.sh:238:    check_ff_possible "$main_checkout" "$release_branch"
scripts/release.sh:249:  if [[ "$review_mode" == self ]]; then
scripts/release.sh:250:    check_ff_possible "$main_checkout" "$release_branch"
scripts/release.sh:264:  if [[ "$review_mode" == self ]]; then
scripts/release.sh:266:    git -C "$main_checkout" merge --ff-only "$release_branch"
scripts/release.sh:270:  if [[ "$review_mode" == self ]]; then
tests/test-scripts.sh:61:  local review_mode="${6:-self}"
tests/test-scripts.sh:99:      printf '  human_pr_review: %s\n' "$review_mode"
tests/test-scripts.sh:122:    git push -q -u origin main
tests/test-scripts.sh:176:setup_release_fixture release-happy 2026.8.9 "Code-review verdict: APPROVE" pass fresh
tests/test-scripts.sh:188:setup_release_fixture release-tag-race-rolls-back 2026.8.9 "Code-review verdict: APPROVE" pass fresh
tests/test-scripts.sh:215:setup_release_fixture release-happy-primary 2026.8.9 "Code-review verdict: APPROVE" pass fresh
tests/test-scripts.sh:218:setup_release_fixture release-platform-single 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
tests/test-scripts.sh:221:check "platform-team release commits bump on branch without touching main or tagging" bash -c "
tests/test-scripts.sh:231:setup_release_fixture release-platform-sequential 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
tests/test-scripts.sh:232:check "platform-team release refuses stale branch, then computes next micro after sync" bash -c "
tests/test-scripts.sh:236:  git push -q origin wt/demo:main
tests/test-scripts.sh:237:  rel_b='$TMP/release-platform-sequential/b-wt'
tests/test-scripts.sh:260:setup_release_fixture release-platform-mid-gate 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
tests/test-scripts.sh:277:check "platform-team release catches origin/main moving during gate" bash -c "
profiles/work.md:7:- **Review topology** — set `review.human_pr_review` to `self` or `platform-team`.
profiles/work.md:32:The platform-team release path treats remote `origin/main` as the current source of truth. `scripts/release.sh` fetches it before and after the gate, then refuses with a rebase/sync message if the release branch is stale.
profiles/work.md:36:Tagging is permanently manual in platform-team mode. If a tag is wanted after the Bitbucket PR merges, run:
profiles/work.md:39:git tag vX.Y.Z <merge-commit> && git push origin vX.Y.Z
config.yaml:18:  human_pr_review: self      # self | platform-team

codex
I’ve got the existing shape: `release.sh` still branches on the removed review mode and the tests mostly already have the PR-flow cases but under the old platform-team name. I’m going to patch the script first, then update the docs/config, then tighten the smoke tests around the new single flow and post-merge tag command.
apply patch
patch: completed
/Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology/scripts/release.sh
diff --git a/scripts/release.sh b/scripts/release.sh
index ce19d803956becc2b39b89e57262cb47e44dd359..4e421de6d2c68f9095c6e73232b7e5e4c1e01670
--- a/scripts/release.sh
+++ b/scripts/release.sh
@@ -8,12 +8,15 @@
   cat <<'EOF'
 Usage:
   scripts/release.sh <slug> [--confirm-delta <text>]
+  scripts/release.sh tag-after-merge <slug>
   scripts/release.sh check-version <new-version> [current-version]
   scripts/release.sh next-version [current-version]
 
-The full release path never pushes. In self-review mode it commits, tags,
-fast-forward merges to local main, then stops for the Owner-confirmed push step.
-In platform-team mode it commits the bump on the release branch for PR review.
+The release path never pushes, never tags, and never touches main. It commits
+the version bump on the release branch for PR review.
+
+After the PR merges, tag-after-merge verifies origin/main is the release commit
+and creates the local version tag. The tag push is a separate confirmed step.
 EOF
 }
 
@@ -159,27 +162,6 @@
   git -C "$checkout" diff --cached --quiet || die "$label has staged changes"
   [[ -z "$(git -C "$checkout" ls-files --others --exclude-standard)" ]] \
     || die "$label has untracked files"
-}
-
-check_ff_possible() {
-  local main_checkout="$1"
-  local release_branch="$2"
-
-  git -C "$main_checkout" rev-parse --verify --quiet "$release_branch" >/dev/null \
-    || die "missing release branch: $release_branch"
-  git -C "$main_checkout" merge-base --is-ancestor main "$release_branch" \
-    || die "main cannot fast-forward to $release_branch"
-}
-
-human_pr_review_mode() {
-  local mode
-
-  mode=$(awk '/^review:/{f=1;next} f&&/human_pr_review:/{print $2; exit}' config.yaml)
-  mode=${mode:-self}
-  case "$mode" in
-    self|platform-team) printf '%s\n' "$mode" ;;
-    *) die "invalid review.human_pr_review '$mode' (expected self or platform-team)" ;;
-  esac
 }
 
 check_origin_main_ancestor() {
@@ -195,13 +177,11 @@
 rollback_release() {
   local status=$?
   local pre_release_head="$1"
-  local new_version="$2"
 
   trap - ERR
   set +e
-  git tag -d "v$new_version" >/dev/null 2>&1
   git reset --hard "$pre_release_head" >/dev/null 2>&1
-  echo "release: irreversible step failed; release commit and tag changes were rolled back" >&2
+  echo "release: irreversible step failed; release commit was rolled back" >&2
   exit "$status"
 }
 
@@ -210,15 +190,13 @@
   local confirm_delta="$2"
   local plan_path="work/$slug/plan.md"
   local release_branch="wt/$slug"
-  local main_checkout
   local release_checkout
   local current_version
   local new_version
   local release_note
   local pre_release_head
-  local review_mode
 
-  main_checkout=$(worktree_for_branch main) \
+  worktree_for_branch main >/dev/null \
     || die "main must be checked out in the primary worktree"
   release_checkout=$(worktree_for_branch "$release_branch") \
     || die "$release_branch must be checked out in a linked worktree"
@@ -229,64 +207,75 @@
   cd "$release_checkout"
   current_version=$(<VERSION)
   new_version=$(next_version "$current_version")
-  review_mode=$(human_pr_review_mode)
 
   check_verdict "$plan_path"
   check_clean_worktree "$release_checkout" "$release_branch"
-  check_clean_worktree "$main_checkout" "main checkout"
-  if [[ "$review_mode" == self ]]; then
-    check_ff_possible "$main_checkout" "$release_branch"
-    git rev-parse --verify --quiet "refs/tags/v$new_version" >/dev/null \
-      && die "tag v$new_version already exists"
-  else
-    check_origin_main_ancestor "$release_branch"
-  fi
+  check_origin_main_ancestor "$release_branch"
   check_gate
   check_clean_worktree "$release_checkout" "$release_branch"
   check_archi_fresh
   check_version_exceeds "$new_version" "$current_version"
-  check_clean_worktree "$main_checkout" "main checkout"
-  if [[ "$review_mode" == self ]]; then
-    check_ff_possible "$main_checkout" "$release_branch"
-  else
-    check_origin_main_ancestor "$release_branch"
-  fi
+  check_origin_main_ancestor "$release_branch"
 
   release_note=$(extract_release_note "$plan_path")
   pre_release_head=$(git rev-parse HEAD)
-  trap 'rollback_release "$pre_release_head" "$new_version"' ERR
+  trap 'rollback_release "$pre_release_head"' ERR
 
   printf '%s\n' "$new_version" >VERSION
   prepend_changelog "$new_version" "$release_note" "$confirm_delta"
 
   git add VERSION CHANGELOG.md
   git commit -m "Release v$new_version"
-  if [[ "$review_mode" == self ]]; then
-    git tag "v$new_version"
-    git -C "$main_checkout" merge --ff-only "$release_branch"
-  fi
   trap - ERR
 
-  if [[ "$review_mode" == self ]]; then
-    cat <<EOF
-release: prepared v$new_version on local main
-release: stopped before push; push requires Owner confirmation in-session
-EOF
-  else
-    cat <<EOF
+  cat <<EOF
 release: prepared v$new_version on $release_branch
 release: no tag created; local main untouched
-release: push $release_branch, open a Bitbucket PR, and have a platform engineer merge it
+release: push $release_branch, open a PR, and merge it after review
 EOF
-  fi
 }
 
+tag_after_merge() {
+  local slug="$1"
+  local release_branch="wt/$slug"
+  local release_checkout
+  local version
+  local origin_version
+  local origin_subject
+
+  release_checkout=$(worktree_for_branch "$release_branch") \
+    || die "$release_branch must be checked out in a linked worktree"
+  [[ -f "$release_checkout/VERSION" ]] || die "missing VERSION in $release_branch"
+
+  git fetch origin main
+  git rev-parse --verify --quiet origin/main >/dev/null \
+    || die "missing origin/main after fetch"
+
+  version=$(<"$release_checkout/VERSION")
+  origin_version=$(git show origin/main:VERSION) \
+    || die "origin/main does not contain VERSION"
+  origin_subject=$(git log -1 --format=%s origin/main)
+
+  [[ "$origin_version" == "$version" && "$origin_subject" == "Release v$version" ]] \
+    || die "origin/main is not Release v$version (VERSION is $origin_version; subject is '$origin_subject')"
+
+  git rev-parse --verify --quiet "refs/tags/v$version" >/dev/null \
+    && die "tag v$version already exists"
+
+  git tag "v$version" origin/main
+  printf 'release: created local tag v%s on origin/main\n' "$version"
+}
+
 if [[ $# -eq 0 ]]; then
   usage
   exit 2
 fi
 
 case "$1" in
+  tag-after-merge)
+    [[ $# -eq 2 ]] || { usage; exit 2; }
+    tag_after_merge "$2"
+    ;;
   check-version)
     [[ $# -eq 2 || $# -eq 3 ]] || { usage; exit 2; }
     current=${3:-$(<VERSION)}

diff --git a/scripts/release.sh b/scripts/release.sh
index ce19d803956becc2b39b89e57262cb47e44dd359..4e421de6d2c68f9095c6e73232b7e5e4c1e01670
--- a/scripts/release.sh
+++ b/scripts/release.sh
@@ -8,12 +8,15 @@
   cat <<'EOF'
 Usage:
   scripts/release.sh <slug> [--confirm-delta <text>]
+  scripts/release.sh tag-after-merge <slug>
   scripts/release.sh check-version <new-version> [current-version]
   scripts/release.sh next-version [current-version]
 
-The full release path never pushes. In self-review mode it commits, tags,
-fast-forward merges to local main, then stops for the Owner-confirmed push step.
-In platform-team mode it commits the bump on the release branch for PR review.
+The release path never pushes, never tags, and never touches main. It commits
+the version bump on the release branch for PR review.
+
+After the PR merges, tag-after-merge verifies origin/main is the release commit
+and creates the local version tag. The tag push is a separate confirmed step.
 EOF
 }
 
@@ -159,27 +162,6 @@
   git -C "$checkout" diff --cached --quiet || die "$label has staged changes"
   [[ -z "$(git -C "$checkout" ls-files --others --exclude-standard)" ]] \
     || die "$label has untracked files"
-}
-
-check_ff_possible() {
-  local main_checkout="$1"
-  local release_branch="$2"
-
-  git -C "$main_checkout" rev-parse --verify --quiet "$release_branch" >/dev/null \
-    || die "missing release branch: $release_branch"
-  git -C "$main_checkout" merge-base --is-ancestor main "$release_branch" \
-    || die "main cannot fast-forward to $release_branch"
-}
-
-human_pr_review_mode() {
-  local mode
-
-  mode=$(awk '/^review:/{f=1;next} f&&/human_pr_review:/{print $2; exit}' config.yaml)
-  mode=${mode:-self}
-  case "$mode" in
-    self|platform-team) printf '%s\n' "$mode" ;;
-    *) die "invalid review.human_pr_review '$mode' (expected self or platform-team)" ;;
-  esac
 }
 
 check_origin_main_ancestor() {
@@ -195,13 +177,11 @@
 rollback_release() {
   local status=$?
   local pre_release_head="$1"
-  local new_version="$2"
 
   trap - ERR
   set +e
-  git tag -d "v$new_version" >/dev/null 2>&1
   git reset --hard "$pre_release_head" >/dev/null 2>&1
-  echo "release: irreversible step failed; release commit and tag changes were rolled back" >&2
+  echo "release: irreversible step failed; release commit was rolled back" >&2
   exit "$status"
 }
 
@@ -210,15 +190,13 @@
   local confirm_delta="$2"
   local plan_path="work/$slug/plan.md"
   local release_branch="wt/$slug"
-  local main_checkout
   local release_checkout
   local current_version
   local new_version
   local release_note
   local pre_release_head
-  local review_mode
 
-  main_checkout=$(worktree_for_branch main) \
+  worktree_for_branch main >/dev/null \
     || die "main must be checked out in the primary worktree"
   release_checkout=$(worktree_for_branch "$release_branch") \
     || die "$release_branch must be checked out in a linked worktree"
@@ -229,64 +207,75 @@
   cd "$release_checkout"
   current_version=$(<VERSION)
   new_version=$(next_version "$current_version")
-  review_mode=$(human_pr_review_mode)
 
   check_verdict "$plan_path"
   check_clean_worktree "$release_checkout" "$release_branch"
-  check_clean_worktree "$main_checkout" "main checkout"
-  if [[ "$review_mode" == self ]]; then
-    check_ff_possible "$main_checkout" "$release_branch"
-    git rev-parse --verify --quiet "refs/tags/v$new_version" >/dev/null \
-      && die "tag v$new_version already exists"
-  else
-    check_origin_main_ancestor "$release_branch"
-  fi
+  check_origin_main_ancestor "$release_branch"
   check_gate
   check_clean_worktree "$release_checkout" "$release_branch"
   check_archi_fresh
   check_version_exceeds "$new_version" "$current_version"
-  check_clean_worktree "$main_checkout" "main checkout"
-  if [[ "$review_mode" == self ]]; then
-    check_ff_possible "$main_checkout" "$release_branch"
-  else
-    check_origin_main_ancestor "$release_branch"
-  fi
+  check_origin_main_ancestor "$release_branch"
 
   release_note=$(extract_release_note "$plan_path")
   pre_release_head=$(git rev-parse HEAD)
-  trap 'rollback_release "$pre_release_head" "$new_version"' ERR
+  trap 'rollback_release "$pre_release_head"' ERR
 
   printf '%s\n' "$new_version" >VERSION
   prepend_changelog "$new_version" "$release_note" "$confirm_delta"
 
   git add VERSION CHANGELOG.md
   git commit -m "Release v$new_version"
-  if [[ "$review_mode" == self ]]; then
-    git tag "v$new_version"
-    git -C "$main_checkout" merge --ff-only "$release_branch"
-  fi
   trap - ERR
 
-  if [[ "$review_mode" == self ]]; then
-    cat <<EOF
-release: prepared v$new_version on local main
-release: stopped before push; push requires Owner confirmation in-session
-EOF
-  else
-    cat <<EOF
+  cat <<EOF
 release: prepared v$new_version on $release_branch
 release: no tag created; local main untouched
-release: push $release_branch, open a Bitbucket PR, and have a platform engineer merge it
+release: push $release_branch, open a PR, and merge it after review
 EOF
-  fi
 }
 
+tag_after_merge() {
+  local slug="$1"
+  local release_branch="wt/$slug"
+  local release_checkout
+  local version
+  local origin_version
+  local origin_subject
+
+  release_checkout=$(worktree_for_branch "$release_branch") \
+    || die "$release_branch must be checked out in a linked worktree"
+  [[ -f "$release_checkout/VERSION" ]] || die "missing VERSION in $release_branch"
+
+  git fetch origin main
+  git rev-parse --verify --quiet origin/main >/dev/null \
+    || die "missing origin/main after fetch"
+
+  version=$(<"$release_checkout/VERSION")
+  origin_version=$(git show origin/main:VERSION) \
+    || die "origin/main does not contain VERSION"
+  origin_subject=$(git log -1 --format=%s origin/main)
+
+  [[ "$origin_version" == "$version" && "$origin_subject" == "Release v$version" ]] \
+    || die "origin/main is not Release v$version (VERSION is $origin_version; subject is '$origin_subject')"
+
+  git rev-parse --verify --quiet "refs/tags/v$version" >/dev/null \
+    && die "tag v$version already exists"
+
+  git tag "v$version" origin/main
+  printf 'release: created local tag v%s on origin/main\n' "$version"
+}
+
 if [[ $# -eq 0 ]]; then
   usage
   exit 2
 fi
 
 case "$1" in
+  tag-after-merge)
+    [[ $# -eq 2 ]] || { usage; exit 2; }
+    tag_after_merge "$2"
+    ;;
   check-version)
     [[ $# -eq 2 || $# -eq 3 ]] || { usage; exit 2; }
     current=${3:-$(<VERSION)}

codex
`release.sh` is now structurally single-flow, with `tag-after-merge` separated from the release commit path. Next I’m removing the deleted knob from configuration and rewriting the small release/profile docs to match the new behavior.
apply patch
patch: completed
/Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology/.claude/skills/4-release/SKILL.md
/Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology/CLAUDE.md
/Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology/config.yaml
/Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology/profiles/work.md
diff --git a/.claude/skills/4-release/SKILL.md b/.claude/skills/4-release/SKILL.md
index 923d42b3ecf0574b4e04bc3d1d7d6b9fb9d647fe..e292a1fec26467e14eeab6dd25f32644bd12717f
--- a/.claude/skills/4-release/SKILL.md
+++ b/.claude/skills/4-release/SKILL.md
@@ -11,13 +11,11 @@
 
 1. **Confirm intent:** ask the Owner for the in-session release confirmation and capture the `Confirm-delta:` value.
 2. **Run the release script:** from the repo root, run `bash scripts/release.sh <slug> --confirm-delta "<value>"`.
-3. **React to the exit code based on `review.human_pr_review`:**
-   - Exit 0 with `self` → report the prepared version, tag, and local `main` state.
-   - Exit 0 with `platform-team` → report the bump commit on the release branch, that no tag was created, and that local `main` was untouched.
+3. **React to the exit code:**
+   - Exit 0 → report the bump commit on the release branch, that no tag exists yet, and that `main` was untouched.
    - Non-zero → report the script output and stop.
-4. **Push separately based on `review.human_pr_review`:**
-   - `self` → after the Owner confirms the push, push `main` and the new tag.
-   - `platform-team` → after the Owner confirms the push, push the release branch, print instructions to open a Bitbucket PR, and never push `main`.
+4. **Push the release branch:** after the Owner confirms the push, push the release branch, print instructions to open a PR and get it merged, and never push `main`.
+5. **Tag after merge:** once the Owner confirms the PR has merged, run `bash scripts/release.sh tag-after-merge <slug>`. If it exits non-zero, report the output and stop. If it succeeds, ask the Owner to confirm pushing the new tag, then run `git push origin v<version>`.
 
 ## Rules
 
diff --git a/CLAUDE.md b/CLAUDE.md
index bf72a9b97511c2563b248078c46726b47a5c62a8..6ec3b7c56d404abd1d28a52eb982227c2e51b4ea
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -23,7 +23,7 @@
 2. **The gate is a script.** `scripts/gate.sh` exits 0 or it doesn't. You do not overrule it, reinterpret it, or declare work done while it fails.
 3. **Implementation happens in worktrees**, never in this checkout. `scripts/worktree.sh` manages them.
 4. **Artifacts flow between stages, not transcripts.** The reviewer gets the diff + plan, never the implementation conversation.
-5. **Release is a script.** `scripts/release.sh` owns release preconditions, versioning, changelog assembly, the release commit, tag, and local fast-forward merge. It never pushes.
+5. **Release is a script.** `scripts/release.sh` owns release preconditions, versioning, changelog assembly, and the release commit on the branch. It never pushes and never touches `main`; tagging happens in `/4-release` after the PR merges via `tag-after-merge`.
 
 ## Context tiers
 
diff --git a/config.yaml b/config.yaml
index 906edc83166366a7556ac002dd81216301f98e3a..0c6fe53d7df35ed60c70d2a88dea2a1da99ab640
--- a/config.yaml
+++ b/config.yaml
@@ -14,9 +14,6 @@
   # Claude Code implementer alternative:
   # command: 'claude -p --dangerously-skip-permissions'
 
-review:
-  human_pr_review: self      # self | platform-team
-
 gate:
   command: scripts/gate.sh
   max_retries: 2             # failed-gate feedback loops before escalating to the Owner
diff --git a/profiles/work.md b/profiles/work.md
index 047b6efdfa81e3d8ed0e0fa246144863ee6762b4..4496e556b94f00ebe837b804420788283ba70e90
--- a/profiles/work.md
+++ b/profiles/work.md
@@ -4,7 +4,6 @@
 
 ## Declarations required at /init
 
-- **Review topology** — set `review.human_pr_review` to `self` or `platform-team`.
 - **Implementer runtime** — when the workplace uses Claude Code for implementation, set `implementer.runtime: claude` and use:
 
 ```yaml
@@ -16,8 +15,7 @@
 ## Adds to the loop
 
 - **Jira:** Jira keys may be recorded as read-only references in `work/<slug>/plan.md`. The loop never creates or mutates Jira issues.
-- **Self review topology:** `scripts/release.sh` keeps the base release shape: it bumps `VERSION` and `CHANGELOG.md`, creates `vX.Y.Z`, fast-forwards local `main`, and stops before push. `/4-release` pushes `main` and the tag only after Owner confirmation.
-- **Platform-team review topology:** `scripts/release.sh` fetches `origin/main`, refuses when the release branch does not contain it, bumps `VERSION` and `CHANGELOG.md` on the release branch, creates no tag, and leaves local `main` untouched. `/4-release` pushes the release branch and prints the Bitbucket PR instruction; a platform engineer merges the PR.
+- **Release:** use the base PR-merge release flow.
 
 ## Gate
 
@@ -26,15 +24,3 @@
 - Add `bitbucket-pipelines.yml`.
 - Delete `.github/workflows/ci.yml`.
 - Keep the deterministic commands equivalent: install `shellcheck`, set a git identity, run `bash tests/test-scripts.sh`, then run `bash scripts/gate.sh`.
-
-## Platform-team release sync
-
-The platform-team release path treats remote `origin/main` as the current source of truth. `scripts/release.sh` fetches it before and after the gate, then refuses with a rebase/sync message if the release branch is stale.
-
-Keep the local `main` worktree pulled from the PR-merged remote before cutting new work. The required `main` worktree check only proves the linked worktree exists; it does not prove local `main` is current, because the release guard checks `origin/main`.
-
-Tagging is permanently manual in platform-team mode. If a tag is wanted after the Bitbucket PR merges, run:
-
-```sh
-git tag vX.Y.Z <merge-commit> && git push origin vX.Y.Z
-```
diff --git a/scripts/release.sh b/scripts/release.sh
index ce19d803956becc2b39b89e57262cb47e44dd359..4e421de6d2c68f9095c6e73232b7e5e4c1e01670
--- a/scripts/release.sh
+++ b/scripts/release.sh
@@ -8,12 +8,15 @@
   cat <<'EOF'
 Usage:
   scripts/release.sh <slug> [--confirm-delta <text>]
+  scripts/release.sh tag-after-merge <slug>
   scripts/release.sh check-version <new-version> [current-version]
   scripts/release.sh next-version [current-version]
 
-The full release path never pushes. In self-review mode it commits, tags,
-fast-forward merges to local main, then stops for the Owner-confirmed push step.
-In platform-team mode it commits the bump on the release branch for PR review.
+The release path never pushes, never tags, and never touches main. It commits
+the version bump on the release branch for PR review.
+
+After the PR merges, tag-after-merge verifies origin/main is the release commit
+and creates the local version tag. The tag push is a separate confirmed step.
 EOF
 }
 
@@ -159,27 +162,6 @@
   git -C "$checkout" diff --cached --quiet || die "$label has staged changes"
   [[ -z "$(git -C "$checkout" ls-files --others --exclude-standard)" ]] \
     || die "$label has untracked files"
-}
-
-check_ff_possible() {
-  local main_checkout="$1"
-  local release_branch="$2"
-
-  git -C "$main_checkout" rev-parse --verify --quiet "$release_branch" >/dev/null \
-    || die "missing release branch: $release_branch"
-  git -C "$main_checkout" merge-base --is-ancestor main "$release_branch" \
-    || die "main cannot fast-forward to $release_branch"
-}
-
-human_pr_review_mode() {
-  local mode
-
-  mode=$(awk '/^review:/{f=1;next} f&&/human_pr_review:/{print $2; exit}' config.yaml)
-  mode=${mode:-self}
-  case "$mode" in
-    self|platform-team) printf '%s\n' "$mode" ;;
-    *) die "invalid review.human_pr_review '$mode' (expected self or platform-team)" ;;
-  esac
 }
 
 check_origin_main_ancestor() {
@@ -195,13 +177,11 @@
 rollback_release() {
   local status=$?
   local pre_release_head="$1"
-  local new_version="$2"
 
   trap - ERR
   set +e
-  git tag -d "v$new_version" >/dev/null 2>&1
   git reset --hard "$pre_release_head" >/dev/null 2>&1
-  echo "release: irreversible step failed; release commit and tag changes were rolled back" >&2
+  echo "release: irreversible step failed; release commit was rolled back" >&2
   exit "$status"
 }
 
@@ -210,15 +190,13 @@
   local confirm_delta="$2"
   local plan_path="work/$slug/plan.md"
   local release_branch="wt/$slug"
-  local main_checkout
   local release_checkout
   local current_version
   local new_version
   local release_note
   local pre_release_head
-  local review_mode
 
-  main_checkout=$(worktree_for_branch main) \
+  worktree_for_branch main >/dev/null \
     || die "main must be checked out in the primary worktree"
   release_checkout=$(worktree_for_branch "$release_branch") \
     || die "$release_branch must be checked out in a linked worktree"
@@ -229,64 +207,75 @@
   cd "$release_checkout"
   current_version=$(<VERSION)
   new_version=$(next_version "$current_version")
-  review_mode=$(human_pr_review_mode)
 
   check_verdict "$plan_path"
   check_clean_worktree "$release_checkout" "$release_branch"
-  check_clean_worktree "$main_checkout" "main checkout"
-  if [[ "$review_mode" == self ]]; then
-    check_ff_possible "$main_checkout" "$release_branch"
-    git rev-parse --verify --quiet "refs/tags/v$new_version" >/dev/null \
-      && die "tag v$new_version already exists"
-  else
-    check_origin_main_ancestor "$release_branch"
-  fi
+  check_origin_main_ancestor "$release_branch"
   check_gate
   check_clean_worktree "$release_checkout" "$release_branch"
   check_archi_fresh
   check_version_exceeds "$new_version" "$current_version"
-  check_clean_worktree "$main_checkout" "main checkout"
-  if [[ "$review_mode" == self ]]; then
-    check_ff_possible "$main_checkout" "$release_branch"
-  else
-    check_origin_main_ancestor "$release_branch"
-  fi
+  check_origin_main_ancestor "$release_branch"
 
   release_note=$(extract_release_note "$plan_path")
   pre_release_head=$(git rev-parse HEAD)
-  trap 'rollback_release "$pre_release_head" "$new_version"' ERR
+  trap 'rollback_release "$pre_release_head"' ERR
 
   printf '%s\n' "$new_version" >VERSION
   prepend_changelog "$new_version" "$release_note" "$confirm_delta"
 
   git add VERSION CHANGELOG.md
   git commit -m "Release v$new_version"
-  if [[ "$review_mode" == self ]]; then
-    git tag "v$new_version"
-    git -C "$main_checkout" merge --ff-only "$release_branch"
-  fi
   trap - ERR
 
-  if [[ "$review_mode" == self ]]; then
-    cat <<EOF
-release: prepared v$new_version on local main
-release: stopped before push; push requires Owner confirmation in-session
-EOF
-  else
-    cat <<EOF
+  cat <<EOF
 release: prepared v$new_version on $release_branch
 release: no tag created; local main untouched
-release: push $release_branch, open a Bitbucket PR, and have a platform engineer merge it
+release: push $release_branch, open a PR, and merge it after review
 EOF
-  fi
 }
 
+tag_after_merge() {
+  local slug="$1"
+  local release_branch="wt/$slug"
+  local release_checkout
+  local version
+  local origin_version
+  local origin_subject
+
+  release_checkout=$(worktree_for_branch "$release_branch") \
+    || die "$release_branch must be checked out in a linked worktree"
+  [[ -f "$release_checkout/VERSION" ]] || die "missing VERSION in $release_branch"
+
+  git fetch origin main
+  git rev-parse --verify --quiet origin/main >/dev/null \
+    || die "missing origin/main after fetch"
+
+  version=$(<"$release_checkout/VERSION")
+  origin_version=$(git show origin/main:VERSION) \
+    || die "origin/main does not contain VERSION"
+  origin_subject=$(git log -1 --format=%s origin/main)
+
+  [[ "$origin_version" == "$version" && "$origin_subject" == "Release v$version" ]] \
+    || die "origin/main is not Release v$version (VERSION is $origin_version; subject is '$origin_subject')"
+
+  git rev-parse --verify --quiet "refs/tags/v$version" >/dev/null \
+    && die "tag v$version already exists"
+
+  git tag "v$version" origin/main
+  printf 'release: created local tag v%s on origin/main\n' "$version"
+}
+
 if [[ $# -eq 0 ]]; then
   usage
   exit 2
 fi
 
 case "$1" in
+  tag-after-merge)
+    [[ $# -eq 2 ]] || { usage; exit 2; }
+    tag_after_merge "$2"
+    ;;
   check-version)
     [[ $# -eq 2 || $# -eq 3 ]] || { usage; exit 2; }
     current=${3:-$(<VERSION)}

diff --git a/.claude/skills/4-release/SKILL.md b/.claude/skills/4-release/SKILL.md
index 923d42b3ecf0574b4e04bc3d1d7d6b9fb9d647fe..e292a1fec26467e14eeab6dd25f32644bd12717f
--- a/.claude/skills/4-release/SKILL.md
+++ b/.claude/skills/4-release/SKILL.md
@@ -11,13 +11,11 @@
 
 1. **Confirm intent:** ask the Owner for the in-session release confirmation and capture the `Confirm-delta:` value.
 2. **Run the release script:** from the repo root, run `bash scripts/release.sh <slug> --confirm-delta "<value>"`.
-3. **React to the exit code based on `review.human_pr_review`:**
-   - Exit 0 with `self` → report the prepared version, tag, and local `main` state.
-   - Exit 0 with `platform-team` → report the bump commit on the release branch, that no tag was created, and that local `main` was untouched.
+3. **React to the exit code:**
+   - Exit 0 → report the bump commit on the release branch, that no tag exists yet, and that `main` was untouched.
    - Non-zero → report the script output and stop.
-4. **Push separately based on `review.human_pr_review`:**
-   - `self` → after the Owner confirms the push, push `main` and the new tag.
-   - `platform-team` → after the Owner confirms the push, push the release branch, print instructions to open a Bitbucket PR, and never push `main`.
+4. **Push the release branch:** after the Owner confirms the push, push the release branch, print instructions to open a PR and get it merged, and never push `main`.
+5. **Tag after merge:** once the Owner confirms the PR has merged, run `bash scripts/release.sh tag-after-merge <slug>`. If it exits non-zero, report the output and stop. If it succeeds, ask the Owner to confirm pushing the new tag, then run `git push origin v<version>`.
 
 ## Rules
 
diff --git a/CLAUDE.md b/CLAUDE.md
index bf72a9b97511c2563b248078c46726b47a5c62a8..6ec3b7c56d404abd1d28a52eb982227c2e51b4ea
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -23,7 +23,7 @@
 2. **The gate is a script.** `scripts/gate.sh` exits 0 or it doesn't. You do not overrule it, reinterpret it, or declare work done while it fails.
 3. **Implementation happens in worktrees**, never in this checkout. `scripts/worktree.sh` manages them.
 4. **Artifacts flow between stages, not transcripts.** The reviewer gets the diff + plan, never the implementation conversation.
-5. **Release is a script.** `scripts/release.sh` owns release preconditions, versioning, changelog assembly, the release commit, tag, and local fast-forward merge. It never pushes.
+5. **Release is a script.** `scripts/release.sh` owns release preconditions, versioning, changelog assembly, and the release commit on the branch. It never pushes and never touches `main`; tagging happens in `/4-release` after the PR merges via `tag-after-merge`.
 
 ## Context tiers
 
diff --git a/config.yaml b/config.yaml
index 906edc83166366a7556ac002dd81216301f98e3a..0c6fe53d7df35ed60c70d2a88dea2a1da99ab640
--- a/config.yaml
+++ b/config.yaml
@@ -14,9 +14,6 @@
   # Claude Code implementer alternative:
   # command: 'claude -p --dangerously-skip-permissions'
 
-review:
-  human_pr_review: self      # self | platform-team
-
 gate:
   command: scripts/gate.sh
   max_retries: 2             # failed-gate feedback loops before escalating to the Owner
diff --git a/profiles/work.md b/profiles/work.md
index 047b6efdfa81e3d8ed0e0fa246144863ee6762b4..4496e556b94f00ebe837b804420788283ba70e90
--- a/profiles/work.md
+++ b/profiles/work.md
@@ -4,7 +4,6 @@
 
 ## Declarations required at /init
 
-- **Review topology** — set `review.human_pr_review` to `self` or `platform-team`.
 - **Implementer runtime** — when the workplace uses Claude Code for implementation, set `implementer.runtime: claude` and use:
 
 ```yaml
@@ -16,8 +15,7 @@
 ## Adds to the loop
 
 - **Jira:** Jira keys may be recorded as read-only references in `work/<slug>/plan.md`. The loop never creates or mutates Jira issues.
-- **Self review topology:** `scripts/release.sh` keeps the base release shape: it bumps `VERSION` and `CHANGELOG.md`, creates `vX.Y.Z`, fast-forwards local `main`, and stops before push. `/4-release` pushes `main` and the tag only after Owner confirmation.
-- **Platform-team review topology:** `scripts/release.sh` fetches `origin/main`, refuses when the release branch does not contain it, bumps `VERSION` and `CHANGELOG.md` on the release branch, creates no tag, and leaves local `main` untouched. `/4-release` pushes the release branch and prints the Bitbucket PR instruction; a platform engineer merges the PR.
+- **Release:** use the base PR-merge release flow.
 
 ## Gate
 
@@ -26,15 +24,3 @@
 - Add `bitbucket-pipelines.yml`.
 - Delete `.github/workflows/ci.yml`.
 - Keep the deterministic commands equivalent: install `shellcheck`, set a git identity, run `bash tests/test-scripts.sh`, then run `bash scripts/gate.sh`.
-
-## Platform-team release sync
-
-The platform-team release path treats remote `origin/main` as the current source of truth. `scripts/release.sh` fetches it before and after the gate, then refuses with a rebase/sync message if the release branch is stale.
-
-Keep the local `main` worktree pulled from the PR-merged remote before cutting new work. The required `main` worktree check only proves the linked worktree exists; it does not prove local `main` is current, because the release guard checks `origin/main`.
-
-Tagging is permanently manual in platform-team mode. If a tag is wanted after the Bitbucket PR merges, run:
-
-```sh
-git tag vX.Y.Z <merge-commit> && git push origin vX.Y.Z
-```
diff --git a/scripts/release.sh b/scripts/release.sh
index ce19d803956becc2b39b89e57262cb47e44dd359..4e421de6d2c68f9095c6e73232b7e5e4c1e01670
--- a/scripts/release.sh
+++ b/scripts/release.sh
@@ -8,12 +8,15 @@
   cat <<'EOF'
 Usage:
   scripts/release.sh <slug> [--confirm-delta <text>]
+  scripts/release.sh tag-after-merge <slug>
   scripts/release.sh check-version <new-version> [current-version]
   scripts/release.sh next-version [current-version]
 
-The full release path never pushes. In self-review mode it commits, tags,
-fast-forward merges to local main, then stops for the Owner-confirmed push step.
-In platform-team mode it commits the bump on the release branch for PR review.
+The release path never pushes, never tags, and never touches main. It commits
+the version bump on the release branch for PR review.
+
+After the PR merges, tag-after-merge verifies origin/main is the release commit
+and creates the local version tag. The tag push is a separate confirmed step.
 EOF
 }
 
@@ -159,27 +162,6 @@
   git -C "$checkout" diff --cached --quiet || die "$label has staged changes"
   [[ -z "$(git -C "$checkout" ls-files --others --exclude-standard)" ]] \
     || die "$label has untracked files"
-}
-
-check_ff_possible() {
-  local main_checkout="$1"
-  local release_branch="$2"
-
-  git -C "$main_checkout" rev-parse --verify --quiet "$release_branch" >/dev/null \
-    || die "missing release branch: $release_branch"
-  git -C "$main_checkout" merge-base --is-ancestor main "$release_branch" \
-    || die "main cannot fast-forward to $release_branch"
-}
-
-human_pr_review_mode() {
-  local mode
-
-  mode=$(awk '/^review:/{f=1;next} f&&/human_pr_review:/{print $2; exit}' config.yaml)
-  mode=${mode:-self}
-  case "$mode" in
-    self|platform-team) printf '%s\n' "$mode" ;;
-    *) die "invalid review.human_pr_review '$mode' (expected self or platform-team)" ;;
-  esac
 }
 
 check_origin_main_ancestor() {
@@ -195,13 +177,11 @@
 rollback_release() {
   local status=$?
   local pre_release_head="$1"
-  local new_version="$2"
 
   trap - ERR
   set +e
-  git tag -d "v$new_version" >/dev/null 2>&1
   git reset --hard "$pre_release_head" >/dev/null 2>&1
-  echo "release: irreversible step failed; release commit and tag changes were rolled back" >&2
+  echo "release: irreversible step failed; release commit was rolled back" >&2
   exit "$status"
 }
 
@@ -210,15 +190,13 @@
   local confirm_delta="$2"
   local plan_path="work/$slug/plan.md"
   local release_branch="wt/$slug"
-  local main_checkout
   local release_checkout
   local current_version
   local new_version
   local release_note
   local pre_release_head
-  local review_mode
 
-  main_checkout=$(worktree_for_branch main) \
+  worktree_for_branch main >/dev/null \
     || die "main must be checked out in the primary worktree"
   release_checkout=$(worktree_for_branch "$release_branch") \
     || die "$release_branch must be checked out in a linked worktree"
@@ -229,64 +207,75 @@
   cd "$release_checkout"
   current_version=$(<VERSION)
   new_version=$(next_version "$current_version")
-  review_mode=$(human_pr_review_mode)
 
   check_verdict "$plan_path"
   check_clean_worktree "$release_checkout" "$release_branch"
-  check_clean_worktree "$main_checkout" "main checkout"
-  if [[ "$review_mode" == self ]]; then
-    check_ff_possible "$main_checkout" "$release_branch"
-    git rev-parse --verify --quiet "refs/tags/v$new_version" >/dev/null \
-      && die "tag v$new_version already exists"
-  else
-    check_origin_main_ancestor "$release_branch"
-  fi
+  check_origin_main_ancestor "$release_branch"
   check_gate
   check_clean_worktree "$release_checkout" "$release_branch"
   check_archi_fresh
   check_version_exceeds "$new_version" "$current_version"
-  check_clean_worktree "$main_checkout" "main checkout"
-  if [[ "$review_mode" == self ]]; then
-    check_ff_possible "$main_checkout" "$release_branch"
-  else
-    check_origin_main_ancestor "$release_branch"
-  fi
+  check_origin_main_ancestor "$release_branch"
 
   release_note=$(extract_release_note "$plan_path")
   pre_release_head=$(git rev-parse HEAD)
-  trap 'rollback_release "$pre_release_head" "$new_version"' ERR
+  trap 'rollback_release "$pre_release_head"' ERR
 
   printf '%s\n' "$new_version" >VERSION
   prepend_changelog "$new_version" "$release_note" "$confirm_delta"
 
   git add VERSION CHANGELOG.md
   git commit -m "Release v$new_version"
-  if [[ "$review_mode" == self ]]; then
-    git tag "v$new_version"
-    git -C "$main_checkout" merge --ff-only "$release_branch"
-  fi
   trap - ERR
 
-  if [[ "$review_mode" == self ]]; then
-    cat <<EOF
-release: prepared v$new_version on local main
-release: stopped before push; push requires Owner confirmation in-session
-EOF
-  else
-    cat <<EOF
+  cat <<EOF
 release: prepared v$new_version on $release_branch
 release: no tag created; local main untouched
-release: push $release_branch, open a Bitbucket PR, and have a platform engineer merge it
+release: push $release_branch, open a PR, and merge it after review
 EOF
-  fi
 }
 
+tag_after_merge() {
+  local slug="$1"
+  local release_branch="wt/$slug"
+  local release_checkout
+  local version
+  local origin_version
+  local origin_subject
+
+  release_checkout=$(worktree_for_branch "$release_branch") \
+    || die "$release_branch must be checked out in a linked worktree"
+  [[ -f "$release_checkout/VERSION" ]] || die "missing VERSION in $release_branch"
+
+  git fetch origin main
+  git rev-parse --verify --quiet origin/main >/dev/null \
+    || die "missing origin/main after fetch"
+
+  version=$(<"$release_checkout/VERSION")
+  origin_version=$(git show origin/main:VERSION) \
+    || die "origin/main does not contain VERSION"
+  origin_subject=$(git log -1 --format=%s origin/main)
+
+  [[ "$origin_version" == "$version" && "$origin_subject" == "Release v$version" ]] \
+    || die "origin/main is not Release v$version (VERSION is $origin_version; subject is '$origin_subject')"
+
+  git rev-parse --verify --quiet "refs/tags/v$version" >/dev/null \
+    && die "tag v$version already exists"
+
+  git tag "v$version" origin/main
+  printf 'release: created local tag v%s on origin/main\n' "$version"
+}
+
 if [[ $# -eq 0 ]]; then
   usage
   exit 2
 fi
 
 case "$1" in
+  tag-after-merge)
+    [[ $# -eq 2 ]] || { usage; exit 2; }
+    tag_after_merge "$2"
+    ;;
   check-version)
     [[ $# -eq 2 || $# -eq 3 ]] || { usage; exit 2; }
     current=${3:-$(<VERSION)}

codex
The docs/config are now aligned with the collapsed topology. I’m editing the smoke suite next: removing the old direct-push cases, making the branch-only release tests canonical, and adding the two post-merge tagging checks.
apply patch
patch: completed
/Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology/tests/test-scripts.sh
diff --git a/.claude/skills/4-release/SKILL.md b/.claude/skills/4-release/SKILL.md
index 923d42b3ecf0574b4e04bc3d1d7d6b9fb9d647fe..e292a1fec26467e14eeab6dd25f32644bd12717f
--- a/.claude/skills/4-release/SKILL.md
+++ b/.claude/skills/4-release/SKILL.md
@@ -11,13 +11,11 @@
 
 1. **Confirm intent:** ask the Owner for the in-session release confirmation and capture the `Confirm-delta:` value.
 2. **Run the release script:** from the repo root, run `bash scripts/release.sh <slug> --confirm-delta "<value>"`.
-3. **React to the exit code based on `review.human_pr_review`:**
-   - Exit 0 with `self` → report the prepared version, tag, and local `main` state.
-   - Exit 0 with `platform-team` → report the bump commit on the release branch, that no tag was created, and that local `main` was untouched.
+3. **React to the exit code:**
+   - Exit 0 → report the bump commit on the release branch, that no tag exists yet, and that `main` was untouched.
    - Non-zero → report the script output and stop.
-4. **Push separately based on `review.human_pr_review`:**
-   - `self` → after the Owner confirms the push, push `main` and the new tag.
-   - `platform-team` → after the Owner confirms the push, push the release branch, print instructions to open a Bitbucket PR, and never push `main`.
+4. **Push the release branch:** after the Owner confirms the push, push the release branch, print instructions to open a PR and get it merged, and never push `main`.
+5. **Tag after merge:** once the Owner confirms the PR has merged, run `bash scripts/release.sh tag-after-merge <slug>`. If it exits non-zero, report the output and stop. If it succeeds, ask the Owner to confirm pushing the new tag, then run `git push origin v<version>`.
 
 ## Rules
 
diff --git a/CLAUDE.md b/CLAUDE.md
index bf72a9b97511c2563b248078c46726b47a5c62a8..6ec3b7c56d404abd1d28a52eb982227c2e51b4ea
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -23,7 +23,7 @@
 2. **The gate is a script.** `scripts/gate.sh` exits 0 or it doesn't. You do not overrule it, reinterpret it, or declare work done while it fails.
 3. **Implementation happens in worktrees**, never in this checkout. `scripts/worktree.sh` manages them.
 4. **Artifacts flow between stages, not transcripts.** The reviewer gets the diff + plan, never the implementation conversation.
-5. **Release is a script.** `scripts/release.sh` owns release preconditions, versioning, changelog assembly, the release commit, tag, and local fast-forward merge. It never pushes.
+5. **Release is a script.** `scripts/release.sh` owns release preconditions, versioning, changelog assembly, and the release commit on the branch. It never pushes and never touches `main`; tagging happens in `/4-release` after the PR merges via `tag-after-merge`.
 
 ## Context tiers
 
diff --git a/config.yaml b/config.yaml
index 906edc83166366a7556ac002dd81216301f98e3a..0c6fe53d7df35ed60c70d2a88dea2a1da99ab640
--- a/config.yaml
+++ b/config.yaml
@@ -14,9 +14,6 @@
   # Claude Code implementer alternative:
   # command: 'claude -p --dangerously-skip-permissions'
 
-review:
-  human_pr_review: self      # self | platform-team
-
 gate:
   command: scripts/gate.sh
   max_retries: 2             # failed-gate feedback loops before escalating to the Owner
diff --git a/profiles/work.md b/profiles/work.md
index 047b6efdfa81e3d8ed0e0fa246144863ee6762b4..4496e556b94f00ebe837b804420788283ba70e90
--- a/profiles/work.md
+++ b/profiles/work.md
@@ -4,7 +4,6 @@
 
 ## Declarations required at /init
 
-- **Review topology** — set `review.human_pr_review` to `self` or `platform-team`.
 - **Implementer runtime** — when the workplace uses Claude Code for implementation, set `implementer.runtime: claude` and use:
 
 ```yaml
@@ -16,8 +15,7 @@
 ## Adds to the loop
 
 - **Jira:** Jira keys may be recorded as read-only references in `work/<slug>/plan.md`. The loop never creates or mutates Jira issues.
-- **Self review topology:** `scripts/release.sh` keeps the base release shape: it bumps `VERSION` and `CHANGELOG.md`, creates `vX.Y.Z`, fast-forwards local `main`, and stops before push. `/4-release` pushes `main` and the tag only after Owner confirmation.
-- **Platform-team review topology:** `scripts/release.sh` fetches `origin/main`, refuses when the release branch does not contain it, bumps `VERSION` and `CHANGELOG.md` on the release branch, creates no tag, and leaves local `main` untouched. `/4-release` pushes the release branch and prints the Bitbucket PR instruction; a platform engineer merges the PR.
+- **Release:** use the base PR-merge release flow.
 
 ## Gate
 
@@ -26,15 +24,3 @@
 - Add `bitbucket-pipelines.yml`.
 - Delete `.github/workflows/ci.yml`.
 - Keep the deterministic commands equivalent: install `shellcheck`, set a git identity, run `bash tests/test-scripts.sh`, then run `bash scripts/gate.sh`.
-
-## Platform-team release sync
-
-The platform-team release path treats remote `origin/main` as the current source of truth. `scripts/release.sh` fetches it before and after the gate, then refuses with a rebase/sync message if the release branch is stale.
-
-Keep the local `main` worktree pulled from the PR-merged remote before cutting new work. The required `main` worktree check only proves the linked worktree exists; it does not prove local `main` is current, because the release guard checks `origin/main`.
-
-Tagging is permanently manual in platform-team mode. If a tag is wanted after the Bitbucket PR merges, run:
-
-```sh
-git tag vX.Y.Z <merge-commit> && git push origin vX.Y.Z
-```
diff --git a/scripts/release.sh b/scripts/release.sh
index ce19d803956becc2b39b89e57262cb47e44dd359..4e421de6d2c68f9095c6e73232b7e5e4c1e01670
--- a/scripts/release.sh
+++ b/scripts/release.sh
@@ -8,12 +8,15 @@
   cat <<'EOF'
 Usage:
   scripts/release.sh <slug> [--confirm-delta <text>]
+  scripts/release.sh tag-after-merge <slug>
   scripts/release.sh check-version <new-version> [current-version]
   scripts/release.sh next-version [current-version]
 
-The full release path never pushes. In self-review mode it commits, tags,
-fast-forward merges to local main, then stops for the Owner-confirmed push step.
-In platform-team mode it commits the bump on the release branch for PR review.
+The release path never pushes, never tags, and never touches main. It commits
+the version bump on the release branch for PR review.
+
+After the PR merges, tag-after-merge verifies origin/main is the release commit
+and creates the local version tag. The tag push is a separate confirmed step.
 EOF
 }
 
@@ -159,27 +162,6 @@
   git -C "$checkout" diff --cached --quiet || die "$label has staged changes"
   [[ -z "$(git -C "$checkout" ls-files --others --exclude-standard)" ]] \
     || die "$label has untracked files"
-}
-
-check_ff_possible() {
-  local main_checkout="$1"
-  local release_branch="$2"
-
-  git -C "$main_checkout" rev-parse --verify --quiet "$release_branch" >/dev/null \
-    || die "missing release branch: $release_branch"
-  git -C "$main_checkout" merge-base --is-ancestor main "$release_branch" \
-    || die "main cannot fast-forward to $release_branch"
-}
-
-human_pr_review_mode() {
-  local mode
-
-  mode=$(awk '/^review:/{f=1;next} f&&/human_pr_review:/{print $2; exit}' config.yaml)
-  mode=${mode:-self}
-  case "$mode" in
-    self|platform-team) printf '%s\n' "$mode" ;;
-    *) die "invalid review.human_pr_review '$mode' (expected self or platform-team)" ;;
-  esac
 }
 
 check_origin_main_ancestor() {
@@ -195,13 +177,11 @@
 rollback_release() {
   local status=$?
   local pre_release_head="$1"
-  local new_version="$2"
 
   trap - ERR
   set +e
-  git tag -d "v$new_version" >/dev/null 2>&1
   git reset --hard "$pre_release_head" >/dev/null 2>&1
-  echo "release: irreversible step failed; release commit and tag changes were rolled back" >&2
+  echo "release: irreversible step failed; release commit was rolled back" >&2
   exit "$status"
 }
 
@@ -210,15 +190,13 @@
   local confirm_delta="$2"
   local plan_path="work/$slug/plan.md"
   local release_branch="wt/$slug"
-  local main_checkout
   local release_checkout
   local current_version
   local new_version
   local release_note
   local pre_release_head
-  local review_mode
 
-  main_checkout=$(worktree_for_branch main) \
+  worktree_for_branch main >/dev/null \
     || die "main must be checked out in the primary worktree"
   release_checkout=$(worktree_for_branch "$release_branch") \
     || die "$release_branch must be checked out in a linked worktree"
@@ -229,64 +207,75 @@
   cd "$release_checkout"
   current_version=$(<VERSION)
   new_version=$(next_version "$current_version")
-  review_mode=$(human_pr_review_mode)
 
   check_verdict "$plan_path"
   check_clean_worktree "$release_checkout" "$release_branch"
-  check_clean_worktree "$main_checkout" "main checkout"
-  if [[ "$review_mode" == self ]]; then
-    check_ff_possible "$main_checkout" "$release_branch"
-    git rev-parse --verify --quiet "refs/tags/v$new_version" >/dev/null \
-      && die "tag v$new_version already exists"
-  else
-    check_origin_main_ancestor "$release_branch"
-  fi
+  check_origin_main_ancestor "$release_branch"
   check_gate
   check_clean_worktree "$release_checkout" "$release_branch"
   check_archi_fresh
   check_version_exceeds "$new_version" "$current_version"
-  check_clean_worktree "$main_checkout" "main checkout"
-  if [[ "$review_mode" == self ]]; then
-    check_ff_possible "$main_checkout" "$release_branch"
-  else
-    check_origin_main_ancestor "$release_branch"
-  fi
+  check_origin_main_ancestor "$release_branch"
 
   release_note=$(extract_release_note "$plan_path")
   pre_release_head=$(git rev-parse HEAD)
-  trap 'rollback_release "$pre_release_head" "$new_version"' ERR
+  trap 'rollback_release "$pre_release_head"' ERR
 
   printf '%s\n' "$new_version" >VERSION
   prepend_changelog "$new_version" "$release_note" "$confirm_delta"
 
   git add VERSION CHANGELOG.md
   git commit -m "Release v$new_version"
-  if [[ "$review_mode" == self ]]; then
-    git tag "v$new_version"
-    git -C "$main_checkout" merge --ff-only "$release_branch"
-  fi
   trap - ERR
 
-  if [[ "$review_mode" == self ]]; then
-    cat <<EOF
-release: prepared v$new_version on local main
-release: stopped before push; push requires Owner confirmation in-session
-EOF
-  else
-    cat <<EOF
+  cat <<EOF
 release: prepared v$new_version on $release_branch
 release: no tag created; local main untouched
-release: push $release_branch, open a Bitbucket PR, and have a platform engineer merge it
+release: push $release_branch, open a PR, and merge it after review
 EOF
-  fi
 }
 
+tag_after_merge() {
+  local slug="$1"
+  local release_branch="wt/$slug"
+  local release_checkout
+  local version
+  local origin_version
+  local origin_subject
+
+  release_checkout=$(worktree_for_branch "$release_branch") \
+    || die "$release_branch must be checked out in a linked worktree"
+  [[ -f "$release_checkout/VERSION" ]] || die "missing VERSION in $release_branch"
+
+  git fetch origin main
+  git rev-parse --verify --quiet origin/main >/dev/null \
+    || die "missing origin/main after fetch"
+
+  version=$(<"$release_checkout/VERSION")
+  origin_version=$(git show origin/main:VERSION) \
+    || die "origin/main does not contain VERSION"
+  origin_subject=$(git log -1 --format=%s origin/main)
+
+  [[ "$origin_version" == "$version" && "$origin_subject" == "Release v$version" ]] \
+    || die "origin/main is not Release v$version (VERSION is $origin_version; subject is '$origin_subject')"
+
+  git rev-parse --verify --quiet "refs/tags/v$version" >/dev/null \
+    && die "tag v$version already exists"
+
+  git tag "v$version" origin/main
+  printf 'release: created local tag v%s on origin/main\n' "$version"
+}
+
 if [[ $# -eq 0 ]]; then
   usage
   exit 2
 fi
 
 case "$1" in
+  tag-after-merge)
+    [[ $# -eq 2 ]] || { usage; exit 2; }
+    tag_after_merge "$2"
+    ;;
   check-version)
     [[ $# -eq 2 || $# -eq 3 ]] || { usage; exit 2; }
     current=${3:-$(<VERSION)}
diff --git a/tests/test-scripts.sh b/tests/test-scripts.sh
index 77e929164770e68220eefdedb0591fc9e25e1f0b..473311694d7e6564bdac487d41e2a595aa54d116
--- a/tests/test-scripts.sh
+++ b/tests/test-scripts.sh
@@ -58,7 +58,6 @@
   local verdict_line="$3"
   local gate_mode="$4"
   local archi_mode="$5"
-  local review_mode="${6:-self}"
   local tmp_root="$TMP/$name"
 
   REL_PRIMARY="$tmp_root/primary"
@@ -93,11 +92,7 @@
 echo "GATE: PASS"
 EOF
     chmod +x scripts/release.sh scripts/gate.sh
-    {
-      printf 'name: fixture\n'
-      printf 'review:\n'
-      printf '  human_pr_review: %s\n' "$review_mode"
-    } >config.yaml
+    printf 'name: fixture\n' >config.yaml
     printf 'merge rules\n' >CLAUDE.md
     printf '%s\n' "$version" >VERSION
     printf '# Changelog\n\nAll notable changes to this project are documented in this file.\n\n' >CHANGELOG.md
@@ -173,52 +168,21 @@
 setup_release_fixture release-version-regresses 2026.9.0 "Code-review verdict: APPROVE" pass fresh
 check_fails "release refuses when computed version does not exceed VERSION" bash -c "cd '$REL_WORKTREE' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo"
 
-setup_release_fixture release-happy 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-origin_before=$(git -C "$REL_PRIMARY" rev-parse origin/main)
-check "release happy path lands fast-forward on primary main and stops before push" bash -c "
-  cd '$REL_WORKTREE' &&
+setup_release_fixture release-happy-primary 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+main_before=$(git -C "$REL_PRIMARY" rev-parse main)
+check "release can be invoked from primary checkout" bash -c "
+  cd '$REL_PRIMARY' &&
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
-  [ \"\$(git -C '$REL_PRIMARY' branch --show-current)\" = main ] &&
-  [ \"\$(cat '$REL_PRIMARY/VERSION')\" = 2026.8.10 ] &&
-  git -C '$REL_PRIMARY' merge-base --is-ancestor wt/demo main &&
-  git -C '$REL_PRIMARY' rev-parse --verify --quiet refs/tags/v2026.8.10 &&
-  [ \"\$(git -C '$REL_PRIMARY' rev-parse origin/main)\" = '$origin_before' ]
-"
-
-setup_release_fixture release-tag-race-rolls-back 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-release_head_before=$(git -C "$REL_WORKTREE" rev-parse HEAD)
-real_git=$(command -v git)
-tag_fail_bin="$TMP/tag-fail-bin"
-mkdir -p "$tag_fail_bin"
-cat >"$tag_fail_bin/git" <<EOF
-#!/usr/bin/env bash
-if [[ "\$1" == tag && "\${2:-}" == v2026.8.10 ]]; then
-  "$real_git" tag v2026.8.10 HEAD~1
-fi
-"$real_git" "\$@"
-EOF
-chmod +x "$tag_fail_bin/git"
-check "release rolls back cleanly when tag creation fails after prechecks" bash -c "
-  cd '$REL_WORKTREE' &&
-  PATH='$tag_fail_bin:$REL_FAKEBIN':\$PATH bash scripts/release.sh demo >/dev/null 2>&1 &&
-  exit 1
-  status=\$?
-  [ \"\$status\" -ne 0 ] &&
-  [ \"\$(git rev-parse HEAD)\" = '$release_head_before' ] &&
-  [ \"\$(cat VERSION)\" = 2026.8.9 ] &&
-  git diff --quiet &&
-  git diff --cached --quiet &&
-  [ -z \"\$(git ls-files --others --exclude-standard)\" ] &&
-  ! git rev-parse --verify --quiet refs/tags/v2026.8.10
+  [ \"\$(git -C '$REL_PRIMARY' rev-parse main)\" = '$main_before' ] &&
+  [ \"\$(cat '$REL_PRIMARY/VERSION')\" = 2026.8.9 ] &&
+  [ \"\$(cat '$REL_WORKTREE/VERSION')\" = 2026.8.10 ] &&
+  ! git -C '$REL_WORKTREE' rev-parse --verify --quiet refs/tags/v2026.8.10
 "
-
-setup_release_fixture release-happy-primary 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-check "release can be invoked from primary checkout" bash -c "cd '$REL_PRIMARY' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo && [ \"\$(cat VERSION)\" = 2026.8.10 ]"
 
-setup_release_fixture release-platform-single 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
+setup_release_fixture release-single 2026.8.9 "Code-review verdict: APPROVE" pass fresh
 origin_before=$(git -C "$REL_PRIMARY" rev-parse origin/main)
 main_before=$(git -C "$REL_PRIMARY" rev-parse main)
-check "platform-team release commits bump on branch without touching main or tagging" bash -c "
+check "release commits bump on branch without touching main, origin/main, or tagging" bash -c "
   cd '$REL_WORKTREE' &&
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
   [ \"\$(git -C '$REL_PRIMARY' rev-parse main)\" = '$main_before' ] &&
@@ -228,13 +192,13 @@
   ! git rev-parse --verify --quiet refs/tags/v2026.8.10
 "
 
-setup_release_fixture release-platform-sequential 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
-check "platform-team release refuses stale branch, then computes next micro after sync" bash -c "
+setup_release_fixture release-sequential 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+check "release refuses stale branch, then computes next micro after sync" bash -c "
   set -e
   cd '$REL_WORKTREE'
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo
   git push -q origin wt/demo:main
-  rel_b='$TMP/release-platform-sequential/b-wt'
+  rel_b='$TMP/release-sequential/b-wt'
   git -C '$REL_PRIMARY' branch wt/b main
   git -C '$REL_PRIMARY' worktree add -q \"\$rel_b\" wt/b
   git -C \"\$rel_b\" config user.email tester@example.com
@@ -243,7 +207,7 @@
   sed 's/# Demo/# B/' '$REL_WORKTREE/work/demo/plan.md' > \"\$rel_b/work/b/plan.md\"
   git -C \"\$rel_b\" add work/b/plan.md
   GIT_AUTHOR_DATE='2026-08-16T10:00:30Z' GIT_COMMITTER_DATE='2026-08-16T10:00:30Z' git -C \"\$rel_b\" commit -qm 'add b plan'
-  stale_out='$TMP/platform-stale.out'
+  stale_out='$TMP/release-stale.out'
   if PATH='$REL_FAKEBIN':\$PATH bash \"\$rel_b/scripts/release.sh\" b >\"\$stale_out\" 2>&1; then
     exit 1
   fi
@@ -257,15 +221,15 @@
   ! git rev-parse --verify --quiet refs/tags/v2026.8.11
 "
 
-setup_release_fixture release-platform-mid-gate 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
+setup_release_fixture release-mid-gate 2026.8.9 "Code-review verdict: APPROVE" pass fresh
 mkdir -p "$REL_WORKTREE/scripts/gate.d"
 cat >"$REL_WORKTREE/scripts/gate.d/move-origin-main.sh" <<EOF
 #!/usr/bin/env bash
 set -euo pipefail
 repo='$REL_PRIMARY'
-printf 'platform merge during gate\n' >> "\$repo/platform.txt"
-git -C "\$repo" add platform.txt
-GIT_AUTHOR_DATE='2026-08-16T10:02:00Z' GIT_COMMITTER_DATE='2026-08-16T10:02:00Z' git -C "\$repo" commit -qm 'platform merge during gate'
+printf 'merge during gate\n' >> "\$repo/remote-change.txt"
+git -C "\$repo" add remote-change.txt
+GIT_AUTHOR_DATE='2026-08-16T10:02:00Z' GIT_COMMITTER_DATE='2026-08-16T10:02:00Z' git -C "\$repo" commit -qm 'merge during gate'
 git -C "\$repo" push -q origin main
 EOF
 chmod +x "$REL_WORKTREE/scripts/gate.d/move-origin-main.sh"
@@ -274,15 +238,58 @@
   git add scripts/gate.d/move-origin-main.sh
   GIT_AUTHOR_DATE="2026-08-16T10:00:30Z" GIT_COMMITTER_DATE="2026-08-16T10:00:30Z" git commit -qm "add mid-gate hook"
 )
-check "platform-team release catches origin/main moving during gate" bash -c "
+check "release catches origin/main moving during gate" bash -c "
   cd '$REL_WORKTREE'
-  mid_gate_out='$TMP/platform-mid-gate.out'
+  mid_gate_out='$TMP/release-mid-gate.out'
   if PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo >\"\$mid_gate_out\" 2>&1; then
     exit 1
   fi
   grep -q 'rebase/sync your branch onto origin/main' \"\$mid_gate_out\"
 "
 
+setup_release_fixture release-tag-after-merge-happy 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+real_git=$(command -v git)
+push_log="$TMP/tag-after-merge-push.log"
+tag_guard_bin="$TMP/tag-after-merge-bin"
+mkdir -p "$tag_guard_bin"
+cat >"$tag_guard_bin/git" <<EOF
+#!/usr/bin/env bash
+if [[ "\$1" == push ]]; then
+  printf 'unexpected push\n' >> "$push_log"
+  exit 99
+fi
+"$real_git" "\$@"
+EOF
+chmod +x "$tag_guard_bin/git"
+check "tag-after-merge creates local tag on origin/main and pushes nothing" bash -c "
+  cd '$REL_WORKTREE' &&
+  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
+  git push -q origin wt/demo:main &&
+  PATH='$tag_guard_bin:$REL_FAKEBIN':\$PATH bash scripts/release.sh tag-after-merge demo &&
+  [ \"\$(git rev-parse refs/tags/v2026.8.10)\" = \"\$(git rev-parse origin/main)\" ] &&
+  [ ! -s '$push_log' ]
+"
+
+setup_release_fixture release-tag-after-merge-wrong-commit 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+check "tag-after-merge refuses when origin/main advanced past the release" bash -c "
+  set -e
+  cd '$REL_WORKTREE'
+  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo
+  git push -q origin wt/demo:main
+  git -C '$REL_PRIMARY' fetch -q origin main
+  git -C '$REL_PRIMARY' reset -q --hard origin/main
+  printf 'next change\n' > '$REL_PRIMARY/after-release.txt'
+  git -C '$REL_PRIMARY' add after-release.txt
+  GIT_AUTHOR_DATE='2026-08-16T10:03:00Z' GIT_COMMITTER_DATE='2026-08-16T10:03:00Z' git -C '$REL_PRIMARY' commit -qm 'Next change'
+  git -C '$REL_PRIMARY' push -q origin main
+  wrong_out='$TMP/tag-after-merge-wrong.out'
+  if PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh tag-after-merge demo >\"\$wrong_out\" 2>&1; then
+    exit 1
+  fi
+  grep -q 'origin/main is not Release v2026.8.10' \"\$wrong_out\" &&
+  ! git rev-parse --verify --quiet refs/tags/v2026.8.10
+"
+
 # --- gate.sh runs and exits cleanly on this repo
 check "gate.sh runs on this repo" bash scripts/gate.sh
 

diff --git a/.claude/skills/4-release/SKILL.md b/.claude/skills/4-release/SKILL.md
index 923d42b3ecf0574b4e04bc3d1d7d6b9fb9d647fe..e292a1fec26467e14eeab6dd25f32644bd12717f
--- a/.claude/skills/4-release/SKILL.md
+++ b/.claude/skills/4-release/SKILL.md
@@ -11,13 +11,11 @@
 
 1. **Confirm intent:** ask the Owner for the in-session release confirmation and capture the `Confirm-delta:` value.
 2. **Run the release script:** from the repo root, run `bash scripts/release.sh <slug> --confirm-delta "<value>"`.
-3. **React to the exit code based on `review.human_pr_review`:**
-   - Exit 0 with `self` → report the prepared version, tag, and local `main` state.
-   - Exit 0 with `platform-team` → report the bump commit on the release branch, that no tag was created, and that local `main` was untouched.
+3. **React to the exit code:**
+   - Exit 0 → report the bump commit on the release branch, that no tag exists yet, and that `main` was untouched.
    - Non-zero → report the script output and stop.
-4. **Push separately based on `review.human_pr_review`:**
-   - `self` → after the Owner confirms the push, push `main` and the new tag.
-   - `platform-team` → after the Owner confirms the push, push the release branch, print instructions to open a Bitbucket PR, and never push `main`.
+4. **Push the release branch:** after the Owner confirms the push, push the release branch, print instructions to open a PR and get it merged, and never push `main`.
+5. **Tag after merge:** once the Owner confirms the PR has merged, run `bash scripts/release.sh tag-after-merge <slug>`. If it exits non-zero, report the output and stop. If it succeeds, ask the Owner to confirm pushing the new tag, then run `git push origin v<version>`.
 
 ## Rules
 
diff --git a/CLAUDE.md b/CLAUDE.md
index bf72a9b97511c2563b248078c46726b47a5c62a8..6ec3b7c56d404abd1d28a52eb982227c2e51b4ea
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -23,7 +23,7 @@
 2. **The gate is a script.** `scripts/gate.sh` exits 0 or it doesn't. You do not overrule it, reinterpret it, or declare work done while it fails.
 3. **Implementation happens in worktrees**, never in this checkout. `scripts/worktree.sh` manages them.
 4. **Artifacts flow between stages, not transcripts.** The reviewer gets the diff + plan, never the implementation conversation.
-5. **Release is a script.** `scripts/release.sh` owns release preconditions, versioning, changelog assembly, the release commit, tag, and local fast-forward merge. It never pushes.
+5. **Release is a script.** `scripts/release.sh` owns release preconditions, versioning, changelog assembly, and the release commit on the branch. It never pushes and never touches `main`; tagging happens in `/4-release` after the PR merges via `tag-after-merge`.
 
 ## Context tiers
 
diff --git a/config.yaml b/config.yaml
index 906edc83166366a7556ac002dd81216301f98e3a..0c6fe53d7df35ed60c70d2a88dea2a1da99ab640
--- a/config.yaml
+++ b/config.yaml
@@ -14,9 +14,6 @@
   # Claude Code implementer alternative:
   # command: 'claude -p --dangerously-skip-permissions'
 
-review:
-  human_pr_review: self      # self | platform-team
-
 gate:
   command: scripts/gate.sh
   max_retries: 2             # failed-gate feedback loops before escalating to the Owner
diff --git a/profiles/work.md b/profiles/work.md
index 047b6efdfa81e3d8ed0e0fa246144863ee6762b4..4496e556b94f00ebe837b804420788283ba70e90
--- a/profiles/work.md
+++ b/profiles/work.md
@@ -4,7 +4,6 @@
 
 ## Declarations required at /init
 
-- **Review topology** — set `review.human_pr_review` to `self` or `platform-team`.
 - **Implementer runtime** — when the workplace uses Claude Code for implementation, set `implementer.runtime: claude` and use:
 
 ```yaml
@@ -16,8 +15,7 @@
 ## Adds to the loop
 
 - **Jira:** Jira keys may be recorded as read-only references in `work/<slug>/plan.md`. The loop never creates or mutates Jira issues.
-- **Self review topology:** `scripts/release.sh` keeps the base release shape: it bumps `VERSION` and `CHANGELOG.md`, creates `vX.Y.Z`, fast-forwards local `main`, and stops before push. `/4-release` pushes `main` and the tag only after Owner confirmation.
-- **Platform-team review topology:** `scripts/release.sh` fetches `origin/main`, refuses when the release branch does not contain it, bumps `VERSION` and `CHANGELOG.md` on the release branch, creates no tag, and leaves local `main` untouched. `/4-release` pushes the release branch and prints the Bitbucket PR instruction; a platform engineer merges the PR.
+- **Release:** use the base PR-merge release flow.
 
 ## Gate
 
@@ -26,15 +24,3 @@
 - Add `bitbucket-pipelines.yml`.
 - Delete `.github/workflows/ci.yml`.
 - Keep the deterministic commands equivalent: install `shellcheck`, set a git identity, run `bash tests/test-scripts.sh`, then run `bash scripts/gate.sh`.
-
-## Platform-team release sync
-
-The platform-team release path treats remote `origin/main` as the current source of truth. `scripts/release.sh` fetches it before and after the gate, then refuses with a rebase/sync message if the release branch is stale.
-
-Keep the local `main` worktree pulled from the PR-merged remote before cutting new work. The required `main` worktree check only proves the linked worktree exists; it does not prove local `main` is current, because the release guard checks `origin/main`.
-
-Tagging is permanently manual in platform-team mode. If a tag is wanted after the Bitbucket PR merges, run:
-
-```sh
-git tag vX.Y.Z <merge-commit> && git push origin vX.Y.Z
-```
diff --git a/scripts/release.sh b/scripts/release.sh
index ce19d803956becc2b39b89e57262cb47e44dd359..4e421de6d2c68f9095c6e73232b7e5e4c1e01670
--- a/scripts/release.sh
+++ b/scripts/release.sh
@@ -8,12 +8,15 @@
   cat <<'EOF'
 Usage:
   scripts/release.sh <slug> [--confirm-delta <text>]
+  scripts/release.sh tag-after-merge <slug>
   scripts/release.sh check-version <new-version> [current-version]
   scripts/release.sh next-version [current-version]
 
-The full release path never pushes. In self-review mode it commits, tags,
-fast-forward merges to local main, then stops for the Owner-confirmed push step.
-In platform-team mode it commits the bump on the release branch for PR review.
+The release path never pushes, never tags, and never touches main. It commits
+the version bump on the release branch for PR review.
+
+After the PR merges, tag-after-merge verifies origin/main is the release commit
+and creates the local version tag. The tag push is a separate confirmed step.
 EOF
 }
 
@@ -159,27 +162,6 @@
   git -C "$checkout" diff --cached --quiet || die "$label has staged changes"
   [[ -z "$(git -C "$checkout" ls-files --others --exclude-standard)" ]] \
     || die "$label has untracked files"
-}
-
-check_ff_possible() {
-  local main_checkout="$1"
-  local release_branch="$2"
-
-  git -C "$main_checkout" rev-parse --verify --quiet "$release_branch" >/dev/null \
-    || die "missing release branch: $release_branch"
-  git -C "$main_checkout" merge-base --is-ancestor main "$release_branch" \
-    || die "main cannot fast-forward to $release_branch"
-}
-
-human_pr_review_mode() {
-  local mode
-
-  mode=$(awk '/^review:/{f=1;next} f&&/human_pr_review:/{print $2; exit}' config.yaml)
-  mode=${mode:-self}
-  case "$mode" in
-    self|platform-team) printf '%s\n' "$mode" ;;
-    *) die "invalid review.human_pr_review '$mode' (expected self or platform-team)" ;;
-  esac
 }
 
 check_origin_main_ancestor() {
@@ -195,13 +177,11 @@
 rollback_release() {
   local status=$?
   local pre_release_head="$1"
-  local new_version="$2"
 
   trap - ERR
   set +e
-  git tag -d "v$new_version" >/dev/null 2>&1
   git reset --hard "$pre_release_head" >/dev/null 2>&1
-  echo "release: irreversible step failed; release commit and tag changes were rolled back" >&2
+  echo "release: irreversible step failed; release commit was rolled back" >&2
   exit "$status"
 }
 
@@ -210,15 +190,13 @@
   local confirm_delta="$2"
   local plan_path="work/$slug/plan.md"
   local release_branch="wt/$slug"
-  local main_checkout
   local release_checkout
   local current_version
   local new_version
   local release_note
   local pre_release_head
-  local review_mode
 
-  main_checkout=$(worktree_for_branch main) \
+  worktree_for_branch main >/dev/null \
     || die "main must be checked out in the primary worktree"
   release_checkout=$(worktree_for_branch "$release_branch") \
     || die "$release_branch must be checked out in a linked worktree"
@@ -229,64 +207,75 @@
   cd "$release_checkout"
   current_version=$(<VERSION)
   new_version=$(next_version "$current_version")
-  review_mode=$(human_pr_review_mode)
 
   check_verdict "$plan_path"
   check_clean_worktree "$release_checkout" "$release_branch"
-  check_clean_worktree "$main_checkout" "main checkout"
-  if [[ "$review_mode" == self ]]; then
-    check_ff_possible "$main_checkout" "$release_branch"
-    git rev-parse --verify --quiet "refs/tags/v$new_version" >/dev/null \
-      && die "tag v$new_version already exists"
-  else
-    check_origin_main_ancestor "$release_branch"
-  fi
+  check_origin_main_ancestor "$release_branch"
   check_gate
   check_clean_worktree "$release_checkout" "$release_branch"
   check_archi_fresh
   check_version_exceeds "$new_version" "$current_version"
-  check_clean_worktree "$main_checkout" "main checkout"
-  if [[ "$review_mode" == self ]]; then
-    check_ff_possible "$main_checkout" "$release_branch"
-  else
-    check_origin_main_ancestor "$release_branch"
-  fi
+  check_origin_main_ancestor "$release_branch"
 
   release_note=$(extract_release_note "$plan_path")
   pre_release_head=$(git rev-parse HEAD)
-  trap 'rollback_release "$pre_release_head" "$new_version"' ERR
+  trap 'rollback_release "$pre_release_head"' ERR
 
   printf '%s\n' "$new_version" >VERSION
   prepend_changelog "$new_version" "$release_note" "$confirm_delta"
 
   git add VERSION CHANGELOG.md
   git commit -m "Release v$new_version"
-  if [[ "$review_mode" == self ]]; then
-    git tag "v$new_version"
-    git -C "$main_checkout" merge --ff-only "$release_branch"
-  fi
   trap - ERR
 
-  if [[ "$review_mode" == self ]]; then
-    cat <<EOF
-release: prepared v$new_version on local main
-release: stopped before push; push requires Owner confirmation in-session
-EOF
-  else
-    cat <<EOF
+  cat <<EOF
 release: prepared v$new_version on $release_branch
 release: no tag created; local main untouched
-release: push $release_branch, open a Bitbucket PR, and have a platform engineer merge it
+release: push $release_branch, open a PR, and merge it after review
 EOF
-  fi
 }
 
+tag_after_merge() {
+  local slug="$1"
+  local release_branch="wt/$slug"
+  local release_checkout
+  local version
+  local origin_version
+  local origin_subject
+
+  release_checkout=$(worktree_for_branch "$release_branch") \
+    || die "$release_branch must be checked out in a linked worktree"
+  [[ -f "$release_checkout/VERSION" ]] || die "missing VERSION in $release_branch"
+
+  git fetch origin main
+  git rev-parse --verify --quiet origin/main >/dev/null \
+    || die "missing origin/main after fetch"
+
+  version=$(<"$release_checkout/VERSION")
+  origin_version=$(git show origin/main:VERSION) \
+    || die "origin/main does not contain VERSION"
+  origin_subject=$(git log -1 --format=%s origin/main)
+
+  [[ "$origin_version" == "$version" && "$origin_subject" == "Release v$version" ]] \
+    || die "origin/main is not Release v$version (VERSION is $origin_version; subject is '$origin_subject')"
+
+  git rev-parse --verify --quiet "refs/tags/v$version" >/dev/null \
+    && die "tag v$version already exists"
+
+  git tag "v$version" origin/main
+  printf 'release: created local tag v%s on origin/main\n' "$version"
+}
+
 if [[ $# -eq 0 ]]; then
   usage
   exit 2
 fi
 
 case "$1" in
+  tag-after-merge)
+    [[ $# -eq 2 ]] || { usage; exit 2; }
+    tag_after_merge "$2"
+    ;;
   check-version)
     [[ $# -eq 2 || $# -eq 3 ]] || { usage; exit 2; }
     current=${3:-$(<VERSION)}
diff --git a/tests/test-scripts.sh b/tests/test-scripts.sh
index 77e929164770e68220eefdedb0591fc9e25e1f0b..473311694d7e6564bdac487d41e2a595aa54d116
--- a/tests/test-scripts.sh
+++ b/tests/test-scripts.sh
@@ -58,7 +58,6 @@
   local verdict_line="$3"
   local gate_mode="$4"
   local archi_mode="$5"
-  local review_mode="${6:-self}"
   local tmp_root="$TMP/$name"
 
   REL_PRIMARY="$tmp_root/primary"
@@ -93,11 +92,7 @@
 echo "GATE: PASS"
 EOF
     chmod +x scripts/release.sh scripts/gate.sh
-    {
-      printf 'name: fixture\n'
-      printf 'review:\n'
-      printf '  human_pr_review: %s\n' "$review_mode"
-    } >config.yaml
+    printf 'name: fixture\n' >config.yaml
     printf 'merge rules\n' >CLAUDE.md
     printf '%s\n' "$version" >VERSION
     printf '# Changelog\n\nAll notable changes to this project are documented in this file.\n\n' >CHANGELOG.md
@@ -173,52 +168,21 @@
 setup_release_fixture release-version-regresses 2026.9.0 "Code-review verdict: APPROVE" pass fresh
 check_fails "release refuses when computed version does not exceed VERSION" bash -c "cd '$REL_WORKTREE' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo"
 
-setup_release_fixture release-happy 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-origin_before=$(git -C "$REL_PRIMARY" rev-parse origin/main)
-check "release happy path lands fast-forward on primary main and stops before push" bash -c "
-  cd '$REL_WORKTREE' &&
+setup_release_fixture release-happy-primary 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+main_before=$(git -C "$REL_PRIMARY" rev-parse main)
+check "release can be invoked from primary checkout" bash -c "
+  cd '$REL_PRIMARY' &&
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
-  [ \"\$(git -C '$REL_PRIMARY' branch --show-current)\" = main ] &&
-  [ \"\$(cat '$REL_PRIMARY/VERSION')\" = 2026.8.10 ] &&
-  git -C '$REL_PRIMARY' merge-base --is-ancestor wt/demo main &&
-  git -C '$REL_PRIMARY' rev-parse --verify --quiet refs/tags/v2026.8.10 &&
-  [ \"\$(git -C '$REL_PRIMARY' rev-parse origin/main)\" = '$origin_before' ]
-"
-
-setup_release_fixture release-tag-race-rolls-back 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-release_head_before=$(git -C "$REL_WORKTREE" rev-parse HEAD)
-real_git=$(command -v git)
-tag_fail_bin="$TMP/tag-fail-bin"
-mkdir -p "$tag_fail_bin"
-cat >"$tag_fail_bin/git" <<EOF
-#!/usr/bin/env bash
-if [[ "\$1" == tag && "\${2:-}" == v2026.8.10 ]]; then
-  "$real_git" tag v2026.8.10 HEAD~1
-fi
-"$real_git" "\$@"
-EOF
-chmod +x "$tag_fail_bin/git"
-check "release rolls back cleanly when tag creation fails after prechecks" bash -c "
-  cd '$REL_WORKTREE' &&
-  PATH='$tag_fail_bin:$REL_FAKEBIN':\$PATH bash scripts/release.sh demo >/dev/null 2>&1 &&
-  exit 1
-  status=\$?
-  [ \"\$status\" -ne 0 ] &&
-  [ \"\$(git rev-parse HEAD)\" = '$release_head_before' ] &&
-  [ \"\$(cat VERSION)\" = 2026.8.9 ] &&
-  git diff --quiet &&
-  git diff --cached --quiet &&
-  [ -z \"\$(git ls-files --others --exclude-standard)\" ] &&
-  ! git rev-parse --verify --quiet refs/tags/v2026.8.10
+  [ \"\$(git -C '$REL_PRIMARY' rev-parse main)\" = '$main_before' ] &&
+  [ \"\$(cat '$REL_PRIMARY/VERSION')\" = 2026.8.9 ] &&
+  [ \"\$(cat '$REL_WORKTREE/VERSION')\" = 2026.8.10 ] &&
+  ! git -C '$REL_WORKTREE' rev-parse --verify --quiet refs/tags/v2026.8.10
 "
-
-setup_release_fixture release-happy-primary 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-check "release can be invoked from primary checkout" bash -c "cd '$REL_PRIMARY' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo && [ \"\$(cat VERSION)\" = 2026.8.10 ]"
 
-setup_release_fixture release-platform-single 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
+setup_release_fixture release-single 2026.8.9 "Code-review verdict: APPROVE" pass fresh
 origin_before=$(git -C "$REL_PRIMARY" rev-parse origin/main)
 main_before=$(git -C "$REL_PRIMARY" rev-parse main)
-check "platform-team release commits bump on branch without touching main or tagging" bash -c "
+check "release commits bump on branch without touching main, origin/main, or tagging" bash -c "
   cd '$REL_WORKTREE' &&
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
   [ \"\$(git -C '$REL_PRIMARY' rev-parse main)\" = '$main_before' ] &&
@@ -228,13 +192,13 @@
   ! git rev-parse --verify --quiet refs/tags/v2026.8.10
 "
 
-setup_release_fixture release-platform-sequential 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
-check "platform-team release refuses stale branch, then computes next micro after sync" bash -c "
+setup_release_fixture release-sequential 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+check "release refuses stale branch, then computes next micro after sync" bash -c "
   set -e
   cd '$REL_WORKTREE'
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo
   git push -q origin wt/demo:main
-  rel_b='$TMP/release-platform-sequential/b-wt'
+  rel_b='$TMP/release-sequential/b-wt'
   git -C '$REL_PRIMARY' branch wt/b main
   git -C '$REL_PRIMARY' worktree add -q \"\$rel_b\" wt/b
   git -C \"\$rel_b\" config user.email tester@example.com
@@ -243,7 +207,7 @@
   sed 's/# Demo/# B/' '$REL_WORKTREE/work/demo/plan.md' > \"\$rel_b/work/b/plan.md\"
   git -C \"\$rel_b\" add work/b/plan.md
   GIT_AUTHOR_DATE='2026-08-16T10:00:30Z' GIT_COMMITTER_DATE='2026-08-16T10:00:30Z' git -C \"\$rel_b\" commit -qm 'add b plan'
-  stale_out='$TMP/platform-stale.out'
+  stale_out='$TMP/release-stale.out'
   if PATH='$REL_FAKEBIN':\$PATH bash \"\$rel_b/scripts/release.sh\" b >\"\$stale_out\" 2>&1; then
     exit 1
   fi
@@ -257,15 +221,15 @@
   ! git rev-parse --verify --quiet refs/tags/v2026.8.11
 "
 
-setup_release_fixture release-platform-mid-gate 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
+setup_release_fixture release-mid-gate 2026.8.9 "Code-review verdict: APPROVE" pass fresh
 mkdir -p "$REL_WORKTREE/scripts/gate.d"
 cat >"$REL_WORKTREE/scripts/gate.d/move-origin-main.sh" <<EOF
 #!/usr/bin/env bash
 set -euo pipefail
 repo='$REL_PRIMARY'
-printf 'platform merge during gate\n' >> "\$repo/platform.txt"
-git -C "\$repo" add platform.txt
-GIT_AUTHOR_DATE='2026-08-16T10:02:00Z' GIT_COMMITTER_DATE='2026-08-16T10:02:00Z' git -C "\$repo" commit -qm 'platform merge during gate'
+printf 'merge during gate\n' >> "\$repo/remote-change.txt"
+git -C "\$repo" add remote-change.txt
+GIT_AUTHOR_DATE='2026-08-16T10:02:00Z' GIT_COMMITTER_DATE='2026-08-16T10:02:00Z' git -C "\$repo" commit -qm 'merge during gate'
 git -C "\$repo" push -q origin main
 EOF
 chmod +x "$REL_WORKTREE/scripts/gate.d/move-origin-main.sh"
@@ -274,15 +238,58 @@
   git add scripts/gate.d/move-origin-main.sh
   GIT_AUTHOR_DATE="2026-08-16T10:00:30Z" GIT_COMMITTER_DATE="2026-08-16T10:00:30Z" git commit -qm "add mid-gate hook"
 )
-check "platform-team release catches origin/main moving during gate" bash -c "
+check "release catches origin/main moving during gate" bash -c "
   cd '$REL_WORKTREE'
-  mid_gate_out='$TMP/platform-mid-gate.out'
+  mid_gate_out='$TMP/release-mid-gate.out'
   if PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo >\"\$mid_gate_out\" 2>&1; then
     exit 1
   fi
   grep -q 'rebase/sync your branch onto origin/main' \"\$mid_gate_out\"
 "
 
+setup_release_fixture release-tag-after-merge-happy 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+real_git=$(command -v git)
+push_log="$TMP/tag-after-merge-push.log"
+tag_guard_bin="$TMP/tag-after-merge-bin"
+mkdir -p "$tag_guard_bin"
+cat >"$tag_guard_bin/git" <<EOF
+#!/usr/bin/env bash
+if [[ "\$1" == push ]]; then
+  printf 'unexpected push\n' >> "$push_log"
+  exit 99
+fi
+"$real_git" "\$@"
+EOF
+chmod +x "$tag_guard_bin/git"
+check "tag-after-merge creates local tag on origin/main and pushes nothing" bash -c "
+  cd '$REL_WORKTREE' &&
+  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
+  git push -q origin wt/demo:main &&
+  PATH='$tag_guard_bin:$REL_FAKEBIN':\$PATH bash scripts/release.sh tag-after-merge demo &&
+  [ \"\$(git rev-parse refs/tags/v2026.8.10)\" = \"\$(git rev-parse origin/main)\" ] &&
+  [ ! -s '$push_log' ]
+"
+
+setup_release_fixture release-tag-after-merge-wrong-commit 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+check "tag-after-merge refuses when origin/main advanced past the release" bash -c "
+  set -e
+  cd '$REL_WORKTREE'
+  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo
+  git push -q origin wt/demo:main
+  git -C '$REL_PRIMARY' fetch -q origin main
+  git -C '$REL_PRIMARY' reset -q --hard origin/main
+  printf 'next change\n' > '$REL_PRIMARY/after-release.txt'
+  git -C '$REL_PRIMARY' add after-release.txt
+  GIT_AUTHOR_DATE='2026-08-16T10:03:00Z' GIT_COMMITTER_DATE='2026-08-16T10:03:00Z' git -C '$REL_PRIMARY' commit -qm 'Next change'
+  git -C '$REL_PRIMARY' push -q origin main
+  wrong_out='$TMP/tag-after-merge-wrong.out'
+  if PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh tag-after-merge demo >\"\$wrong_out\" 2>&1; then
+    exit 1
+  fi
+  grep -q 'origin/main is not Release v2026.8.10' \"\$wrong_out\" &&
+  ! git rev-parse --verify --quiet refs/tags/v2026.8.10
+"
+
 # --- gate.sh runs and exits cleanly on this repo
 check "gate.sh runs on this repo" bash scripts/gate.sh
 

codex
The test suite patch is in place. I’m running the targeted greps now before executing the full gate, so any leftover old topology terms or forbidden release-script operations are caught cheaply.
exec
/bin/zsh -lc 'rg -n "human_pr_review|platform-team|self-review|check_ff_possible|merge --ff-only|git push" scripts/release.sh || true' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
exec
/bin/zsh -lc 'rg -n "review_mode|human_pr_review|platform-team" tests/test-scripts.sh || true' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
 succeeded in 0ms:
 succeeded in 0ms:
exec
/bin/zsh -lc 'rg -n "review:|human_pr_review|platform-team|self-review|manual-tag|manual tag|fast-forward|ff-merge" config.yaml .claude/skills/4-release/SKILL.md profiles/work.md CLAUDE.md || true' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
 succeeded in 0ms:
exec
/bin/zsh -lc 'git diff -- scripts/release.sh config.yaml .claude/skills/4-release/SKILL.md profiles/work.md CLAUDE.md tests/test-scripts.sh' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
 succeeded in 0ms:
diff --git a/CLAUDE.md b/CLAUDE.md
index bf72a9b..6ec3b7c 100644
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -23,7 +23,7 @@ Small fixes (typos, one-liners, config tweaks) skip the loop: just do them on a
 2. **The gate is a script.** `scripts/gate.sh` exits 0 or it doesn't. You do not overrule it, reinterpret it, or declare work done while it fails.
 3. **Implementation happens in worktrees**, never in this checkout. `scripts/worktree.sh` manages them.
 4. **Artifacts flow between stages, not transcripts.** The reviewer gets the diff + plan, never the implementation conversation.
-5. **Release is a script.** `scripts/release.sh` owns release preconditions, versioning, changelog assembly, the release commit, tag, and local fast-forward merge. It never pushes.
+5. **Release is a script.** `scripts/release.sh` owns release preconditions, versioning, changelog assembly, and the release commit on the branch. It never pushes and never touches `main`; tagging happens in `/4-release` after the PR merges via `tag-after-merge`.
 
 ## Context tiers
 
diff --git a/config.yaml b/config.yaml
index 906edc8..0c6fe53 100644
--- a/config.yaml
+++ b/config.yaml
@@ -14,9 +14,6 @@ implementer:
   # Claude Code implementer alternative:
   # command: 'claude -p --dangerously-skip-permissions'
 
-review:
-  human_pr_review: self      # self | platform-team
-
 gate:
   command: scripts/gate.sh
   max_retries: 2             # failed-gate feedback loops before escalating to the Owner
diff --git a/profiles/work.md b/profiles/work.md
index 047b6ef..4496e55 100644
--- a/profiles/work.md
+++ b/profiles/work.md
@@ -4,7 +4,6 @@ For workplace repositories that use Atlassian/Bitbucket review and CI convention
 
 ## Declarations required at /init
 
-- **Review topology** — set `review.human_pr_review` to `self` or `platform-team`.
 - **Implementer runtime** — when the workplace uses Claude Code for implementation, set `implementer.runtime: claude` and use:
 
 ```yaml
@@ -16,8 +15,7 @@ implementer:
 ## Adds to the loop
 
 - **Jira:** Jira keys may be recorded as read-only references in `work/<slug>/plan.md`. The loop never creates or mutates Jira issues.
-- **Self review topology:** `scripts/release.sh` keeps the base release shape: it bumps `VERSION` and `CHANGELOG.md`, creates `vX.Y.Z`, fast-forwards local `main`, and stops before push. `/4-release` pushes `main` and the tag only after Owner confirmation.
-- **Platform-team review topology:** `scripts/release.sh` fetches `origin/main`, refuses when the release branch does not contain it, bumps `VERSION` and `CHANGELOG.md` on the release branch, creates no tag, and leaves local `main` untouched. `/4-release` pushes the release branch and prints the Bitbucket PR instruction; a platform engineer merges the PR.
+- **Release:** use the base PR-merge release flow.
 
 ## Gate
 
@@ -26,15 +24,3 @@ Replace GitHub Actions with Bitbucket Pipelines during /init:
 - Add `bitbucket-pipelines.yml`.
 - Delete `.github/workflows/ci.yml`.
 - Keep the deterministic commands equivalent: install `shellcheck`, set a git identity, run `bash tests/test-scripts.sh`, then run `bash scripts/gate.sh`.
-
-## Platform-team release sync
-
-The platform-team release path treats remote `origin/main` as the current source of truth. `scripts/release.sh` fetches it before and after the gate, then refuses with a rebase/sync message if the release branch is stale.
-
-Keep the local `main` worktree pulled from the PR-merged remote before cutting new work. The required `main` worktree check only proves the linked worktree exists; it does not prove local `main` is current, because the release guard checks `origin/main`.
-
-Tagging is permanently manual in platform-team mode. If a tag is wanted after the Bitbucket PR merges, run:
-
-```sh
-git tag vX.Y.Z <merge-commit> && git push origin vX.Y.Z
-```
diff --git a/scripts/release.sh b/scripts/release.sh
index ce19d80..4e421de 100755
--- a/scripts/release.sh
+++ b/scripts/release.sh
@@ -8,12 +8,15 @@ usage() {
   cat <<'EOF'
 Usage:
   scripts/release.sh <slug> [--confirm-delta <text>]
+  scripts/release.sh tag-after-merge <slug>
   scripts/release.sh check-version <new-version> [current-version]
   scripts/release.sh next-version [current-version]
 
-The full release path never pushes. In self-review mode it commits, tags,
-fast-forward merges to local main, then stops for the Owner-confirmed push step.
-In platform-team mode it commits the bump on the release branch for PR review.
+The release path never pushes, never tags, and never touches main. It commits
+the version bump on the release branch for PR review.
+
+After the PR merges, tag-after-merge verifies origin/main is the release commit
+and creates the local version tag. The tag push is a separate confirmed step.
 EOF
 }
 
@@ -161,27 +164,6 @@ check_clean_worktree() {
     || die "$label has untracked files"
 }
 
-check_ff_possible() {
-  local main_checkout="$1"
-  local release_branch="$2"
-
-  git -C "$main_checkout" rev-parse --verify --quiet "$release_branch" >/dev/null \
-    || die "missing release branch: $release_branch"
-  git -C "$main_checkout" merge-base --is-ancestor main "$release_branch" \
-    || die "main cannot fast-forward to $release_branch"
-}
-
-human_pr_review_mode() {
-  local mode
-
-  mode=$(awk '/^review:/{f=1;next} f&&/human_pr_review:/{print $2; exit}' config.yaml)
-  mode=${mode:-self}
-  case "$mode" in
-    self|platform-team) printf '%s\n' "$mode" ;;
-    *) die "invalid review.human_pr_review '$mode' (expected self or platform-team)" ;;
-  esac
-}
-
 check_origin_main_ancestor() {
   local release_branch="$1"
 
@@ -195,13 +177,11 @@ check_origin_main_ancestor() {
 rollback_release() {
   local status=$?
   local pre_release_head="$1"
-  local new_version="$2"
 
   trap - ERR
   set +e
-  git tag -d "v$new_version" >/dev/null 2>&1
   git reset --hard "$pre_release_head" >/dev/null 2>&1
-  echo "release: irreversible step failed; release commit and tag changes were rolled back" >&2
+  echo "release: irreversible step failed; release commit was rolled back" >&2
   exit "$status"
 }
 
@@ -210,15 +190,13 @@ release() {
   local confirm_delta="$2"
   local plan_path="work/$slug/plan.md"
   local release_branch="wt/$slug"
-  local main_checkout
   local release_checkout
   local current_version
   local new_version
   local release_note
   local pre_release_head
-  local review_mode
 
-  main_checkout=$(worktree_for_branch main) \
+  worktree_for_branch main >/dev/null \
     || die "main must be checked out in the primary worktree"
   release_checkout=$(worktree_for_branch "$release_branch") \
     || die "$release_branch must be checked out in a linked worktree"
@@ -229,56 +207,63 @@ release() {
   cd "$release_checkout"
   current_version=$(<VERSION)
   new_version=$(next_version "$current_version")
-  review_mode=$(human_pr_review_mode)
 
   check_verdict "$plan_path"
   check_clean_worktree "$release_checkout" "$release_branch"
-  check_clean_worktree "$main_checkout" "main checkout"
-  if [[ "$review_mode" == self ]]; then
-    check_ff_possible "$main_checkout" "$release_branch"
-    git rev-parse --verify --quiet "refs/tags/v$new_version" >/dev/null \
-      && die "tag v$new_version already exists"
-  else
-    check_origin_main_ancestor "$release_branch"
-  fi
+  check_origin_main_ancestor "$release_branch"
   check_gate
   check_clean_worktree "$release_checkout" "$release_branch"
   check_archi_fresh
   check_version_exceeds "$new_version" "$current_version"
-  check_clean_worktree "$main_checkout" "main checkout"
-  if [[ "$review_mode" == self ]]; then
-    check_ff_possible "$main_checkout" "$release_branch"
-  else
-    check_origin_main_ancestor "$release_branch"
-  fi
+  check_origin_main_ancestor "$release_branch"
 
   release_note=$(extract_release_note "$plan_path")
   pre_release_head=$(git rev-parse HEAD)
-  trap 'rollback_release "$pre_release_head" "$new_version"' ERR
+  trap 'rollback_release "$pre_release_head"' ERR
 
   printf '%s\n' "$new_version" >VERSION
   prepend_changelog "$new_version" "$release_note" "$confirm_delta"
 
   git add VERSION CHANGELOG.md
   git commit -m "Release v$new_version"
-  if [[ "$review_mode" == self ]]; then
-    git tag "v$new_version"
-    git -C "$main_checkout" merge --ff-only "$release_branch"
-  fi
   trap - ERR
 
-  if [[ "$review_mode" == self ]]; then
-    cat <<EOF
-release: prepared v$new_version on local main
-release: stopped before push; push requires Owner confirmation in-session
-EOF
-  else
-    cat <<EOF
+  cat <<EOF
 release: prepared v$new_version on $release_branch
 release: no tag created; local main untouched
-release: push $release_branch, open a Bitbucket PR, and have a platform engineer merge it
+release: push $release_branch, open a PR, and merge it after review
 EOF
-  fi
+}
+
+tag_after_merge() {
+  local slug="$1"
+  local release_branch="wt/$slug"
+  local release_checkout
+  local version
+  local origin_version
+  local origin_subject
+
+  release_checkout=$(worktree_for_branch "$release_branch") \
+    || die "$release_branch must be checked out in a linked worktree"
+  [[ -f "$release_checkout/VERSION" ]] || die "missing VERSION in $release_branch"
+
+  git fetch origin main
+  git rev-parse --verify --quiet origin/main >/dev/null \
+    || die "missing origin/main after fetch"
+
+  version=$(<"$release_checkout/VERSION")
+  origin_version=$(git show origin/main:VERSION) \
+    || die "origin/main does not contain VERSION"
+  origin_subject=$(git log -1 --format=%s origin/main)
+
+  [[ "$origin_version" == "$version" && "$origin_subject" == "Release v$version" ]] \
+    || die "origin/main is not Release v$version (VERSION is $origin_version; subject is '$origin_subject')"
+
+  git rev-parse --verify --quiet "refs/tags/v$version" >/dev/null \
+    && die "tag v$version already exists"
+
+  git tag "v$version" origin/main
+  printf 'release: created local tag v%s on origin/main\n' "$version"
 }
 
 if [[ $# -eq 0 ]]; then
@@ -287,6 +272,10 @@ if [[ $# -eq 0 ]]; then
 fi
 
 case "$1" in
+  tag-after-merge)
+    [[ $# -eq 2 ]] || { usage; exit 2; }
+    tag_after_merge "$2"
+    ;;
   check-version)
     [[ $# -eq 2 || $# -eq 3 ]] || { usage; exit 2; }
     current=${3:-$(<VERSION)}
diff --git a/tests/test-scripts.sh b/tests/test-scripts.sh
index 77e9291..4733116 100755
--- a/tests/test-scripts.sh
+++ b/tests/test-scripts.sh
@@ -58,7 +58,6 @@ setup_release_fixture() {
   local verdict_line="$3"
   local gate_mode="$4"
   local archi_mode="$5"
-  local review_mode="${6:-self}"
   local tmp_root="$TMP/$name"
 
   REL_PRIMARY="$tmp_root/primary"
@@ -93,11 +92,7 @@ fi
 echo "GATE: PASS"
 EOF
     chmod +x scripts/release.sh scripts/gate.sh
-    {
-      printf 'name: fixture\n'
-      printf 'review:\n'
-      printf '  human_pr_review: %s\n' "$review_mode"
-    } >config.yaml
+    printf 'name: fixture\n' >config.yaml
     printf 'merge rules\n' >CLAUDE.md
     printf '%s\n' "$version" >VERSION
     printf '# Changelog\n\nAll notable changes to this project are documented in this file.\n\n' >CHANGELOG.md
@@ -173,52 +168,21 @@ check_fails "release refuses when ARCHI.md is stale" bash -c "cd '$REL_WORKTREE'
 setup_release_fixture release-version-regresses 2026.9.0 "Code-review verdict: APPROVE" pass fresh
 check_fails "release refuses when computed version does not exceed VERSION" bash -c "cd '$REL_WORKTREE' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo"
 
-setup_release_fixture release-happy 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-origin_before=$(git -C "$REL_PRIMARY" rev-parse origin/main)
-check "release happy path lands fast-forward on primary main and stops before push" bash -c "
-  cd '$REL_WORKTREE' &&
+setup_release_fixture release-happy-primary 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+main_before=$(git -C "$REL_PRIMARY" rev-parse main)
+check "release can be invoked from primary checkout" bash -c "
+  cd '$REL_PRIMARY' &&
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
-  [ \"\$(git -C '$REL_PRIMARY' branch --show-current)\" = main ] &&
-  [ \"\$(cat '$REL_PRIMARY/VERSION')\" = 2026.8.10 ] &&
-  git -C '$REL_PRIMARY' merge-base --is-ancestor wt/demo main &&
-  git -C '$REL_PRIMARY' rev-parse --verify --quiet refs/tags/v2026.8.10 &&
-  [ \"\$(git -C '$REL_PRIMARY' rev-parse origin/main)\" = '$origin_before' ]
-"
-
-setup_release_fixture release-tag-race-rolls-back 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-release_head_before=$(git -C "$REL_WORKTREE" rev-parse HEAD)
-real_git=$(command -v git)
-tag_fail_bin="$TMP/tag-fail-bin"
-mkdir -p "$tag_fail_bin"
-cat >"$tag_fail_bin/git" <<EOF
-#!/usr/bin/env bash
-if [[ "\$1" == tag && "\${2:-}" == v2026.8.10 ]]; then
-  "$real_git" tag v2026.8.10 HEAD~1
-fi
-"$real_git" "\$@"
-EOF
-chmod +x "$tag_fail_bin/git"
-check "release rolls back cleanly when tag creation fails after prechecks" bash -c "
-  cd '$REL_WORKTREE' &&
-  PATH='$tag_fail_bin:$REL_FAKEBIN':\$PATH bash scripts/release.sh demo >/dev/null 2>&1 &&
-  exit 1
-  status=\$?
-  [ \"\$status\" -ne 0 ] &&
-  [ \"\$(git rev-parse HEAD)\" = '$release_head_before' ] &&
-  [ \"\$(cat VERSION)\" = 2026.8.9 ] &&
-  git diff --quiet &&
-  git diff --cached --quiet &&
-  [ -z \"\$(git ls-files --others --exclude-standard)\" ] &&
-  ! git rev-parse --verify --quiet refs/tags/v2026.8.10
+  [ \"\$(git -C '$REL_PRIMARY' rev-parse main)\" = '$main_before' ] &&
+  [ \"\$(cat '$REL_PRIMARY/VERSION')\" = 2026.8.9 ] &&
+  [ \"\$(cat '$REL_WORKTREE/VERSION')\" = 2026.8.10 ] &&
+  ! git -C '$REL_WORKTREE' rev-parse --verify --quiet refs/tags/v2026.8.10
 "
 
-setup_release_fixture release-happy-primary 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-check "release can be invoked from primary checkout" bash -c "cd '$REL_PRIMARY' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo && [ \"\$(cat VERSION)\" = 2026.8.10 ]"
-
-setup_release_fixture release-platform-single 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
+setup_release_fixture release-single 2026.8.9 "Code-review verdict: APPROVE" pass fresh
 origin_before=$(git -C "$REL_PRIMARY" rev-parse origin/main)
 main_before=$(git -C "$REL_PRIMARY" rev-parse main)
-check "platform-team release commits bump on branch without touching main or tagging" bash -c "
+check "release commits bump on branch without touching main, origin/main, or tagging" bash -c "
   cd '$REL_WORKTREE' &&
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
   [ \"\$(git -C '$REL_PRIMARY' rev-parse main)\" = '$main_before' ] &&
@@ -228,13 +192,13 @@ check "platform-team release commits bump on branch without touching main or tag
   ! git rev-parse --verify --quiet refs/tags/v2026.8.10
 "
 
-setup_release_fixture release-platform-sequential 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
-check "platform-team release refuses stale branch, then computes next micro after sync" bash -c "
+setup_release_fixture release-sequential 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+check "release refuses stale branch, then computes next micro after sync" bash -c "
   set -e
   cd '$REL_WORKTREE'
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo
   git push -q origin wt/demo:main
-  rel_b='$TMP/release-platform-sequential/b-wt'
+  rel_b='$TMP/release-sequential/b-wt'
   git -C '$REL_PRIMARY' branch wt/b main
   git -C '$REL_PRIMARY' worktree add -q \"\$rel_b\" wt/b
   git -C \"\$rel_b\" config user.email tester@example.com
@@ -243,7 +207,7 @@ check "platform-team release refuses stale branch, then computes next micro afte
   sed 's/# Demo/# B/' '$REL_WORKTREE/work/demo/plan.md' > \"\$rel_b/work/b/plan.md\"
   git -C \"\$rel_b\" add work/b/plan.md
   GIT_AUTHOR_DATE='2026-08-16T10:00:30Z' GIT_COMMITTER_DATE='2026-08-16T10:00:30Z' git -C \"\$rel_b\" commit -qm 'add b plan'
-  stale_out='$TMP/platform-stale.out'
+  stale_out='$TMP/release-stale.out'
   if PATH='$REL_FAKEBIN':\$PATH bash \"\$rel_b/scripts/release.sh\" b >\"\$stale_out\" 2>&1; then
     exit 1
   fi
@@ -257,15 +221,15 @@ check "platform-team release refuses stale branch, then computes next micro afte
   ! git rev-parse --verify --quiet refs/tags/v2026.8.11
 "
 
-setup_release_fixture release-platform-mid-gate 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
+setup_release_fixture release-mid-gate 2026.8.9 "Code-review verdict: APPROVE" pass fresh
 mkdir -p "$REL_WORKTREE/scripts/gate.d"
 cat >"$REL_WORKTREE/scripts/gate.d/move-origin-main.sh" <<EOF
 #!/usr/bin/env bash
 set -euo pipefail
 repo='$REL_PRIMARY'
-printf 'platform merge during gate\n' >> "\$repo/platform.txt"
-git -C "\$repo" add platform.txt
-GIT_AUTHOR_DATE='2026-08-16T10:02:00Z' GIT_COMMITTER_DATE='2026-08-16T10:02:00Z' git -C "\$repo" commit -qm 'platform merge during gate'
+printf 'merge during gate\n' >> "\$repo/remote-change.txt"
+git -C "\$repo" add remote-change.txt
+GIT_AUTHOR_DATE='2026-08-16T10:02:00Z' GIT_COMMITTER_DATE='2026-08-16T10:02:00Z' git -C "\$repo" commit -qm 'merge during gate'
 git -C "\$repo" push -q origin main
 EOF
 chmod +x "$REL_WORKTREE/scripts/gate.d/move-origin-main.sh"
@@ -274,15 +238,58 @@ chmod +x "$REL_WORKTREE/scripts/gate.d/move-origin-main.sh"
   git add scripts/gate.d/move-origin-main.sh
   GIT_AUTHOR_DATE="2026-08-16T10:00:30Z" GIT_COMMITTER_DATE="2026-08-16T10:00:30Z" git commit -qm "add mid-gate hook"
 )
-check "platform-team release catches origin/main moving during gate" bash -c "
+check "release catches origin/main moving during gate" bash -c "
   cd '$REL_WORKTREE'
-  mid_gate_out='$TMP/platform-mid-gate.out'
+  mid_gate_out='$TMP/release-mid-gate.out'
   if PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo >\"\$mid_gate_out\" 2>&1; then
     exit 1
   fi
   grep -q 'rebase/sync your branch onto origin/main' \"\$mid_gate_out\"
 "
 
+setup_release_fixture release-tag-after-merge-happy 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+real_git=$(command -v git)
+push_log="$TMP/tag-after-merge-push.log"
+tag_guard_bin="$TMP/tag-after-merge-bin"
+mkdir -p "$tag_guard_bin"
+cat >"$tag_guard_bin/git" <<EOF
+#!/usr/bin/env bash
+if [[ "\$1" == push ]]; then
+  printf 'unexpected push\n' >> "$push_log"
+  exit 99
+fi
+"$real_git" "\$@"
+EOF
+chmod +x "$tag_guard_bin/git"
+check "tag-after-merge creates local tag on origin/main and pushes nothing" bash -c "
+  cd '$REL_WORKTREE' &&
+  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
+  git push -q origin wt/demo:main &&
+  PATH='$tag_guard_bin:$REL_FAKEBIN':\$PATH bash scripts/release.sh tag-after-merge demo &&
+  [ \"\$(git rev-parse refs/tags/v2026.8.10)\" = \"\$(git rev-parse origin/main)\" ] &&
+  [ ! -s '$push_log' ]
+"
+
+setup_release_fixture release-tag-after-merge-wrong-commit 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+check "tag-after-merge refuses when origin/main advanced past the release" bash -c "
+  set -e
+  cd '$REL_WORKTREE'
+  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo
+  git push -q origin wt/demo:main
+  git -C '$REL_PRIMARY' fetch -q origin main
+  git -C '$REL_PRIMARY' reset -q --hard origin/main
+  printf 'next change\n' > '$REL_PRIMARY/after-release.txt'
+  git -C '$REL_PRIMARY' add after-release.txt
+  GIT_AUTHOR_DATE='2026-08-16T10:03:00Z' GIT_COMMITTER_DATE='2026-08-16T10:03:00Z' git -C '$REL_PRIMARY' commit -qm 'Next change'
+  git -C '$REL_PRIMARY' push -q origin main
+  wrong_out='$TMP/tag-after-merge-wrong.out'
+  if PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh tag-after-merge demo >\"\$wrong_out\" 2>&1; then
+    exit 1
+  fi
+  grep -q 'origin/main is not Release v2026.8.10' \"\$wrong_out\" &&
+  ! git rev-parse --verify --quiet refs/tags/v2026.8.10
+"
+
 # --- gate.sh runs and exits cleanly on this repo
 check "gate.sh runs on this repo" bash scripts/gate.sh
 

diff --git a/.claude/skills/4-release/SKILL.md b/.claude/skills/4-release/SKILL.md
index 923d42b3ecf0574b4e04bc3d1d7d6b9fb9d647fe..e292a1fec26467e14eeab6dd25f32644bd12717f
--- a/.claude/skills/4-release/SKILL.md
+++ b/.claude/skills/4-release/SKILL.md
@@ -11,13 +11,11 @@
 
 1. **Confirm intent:** ask the Owner for the in-session release confirmation and capture the `Confirm-delta:` value.
 2. **Run the release script:** from the repo root, run `bash scripts/release.sh <slug> --confirm-delta "<value>"`.
-3. **React to the exit code based on `review.human_pr_review`:**
-   - Exit 0 with `self` → report the prepared version, tag, and local `main` state.
-   - Exit 0 with `platform-team` → report the bump commit on the release branch, that no tag was created, and that local `main` was untouched.
+3. **React to the exit code:**
+   - Exit 0 → report the bump commit on the release branch, that no tag exists yet, and that `main` was untouched.
    - Non-zero → report the script output and stop.
-4. **Push separately based on `review.human_pr_review`:**
-   - `self` → after the Owner confirms the push, push `main` and the new tag.
-   - `platform-team` → after the Owner confirms the push, push the release branch, print instructions to open a Bitbucket PR, and never push `main`.
+4. **Push the release branch:** after the Owner confirms the push, push the release branch, print instructions to open a PR and get it merged, and never push `main`.
+5. **Tag after merge:** once the Owner confirms the PR has merged, run `bash scripts/release.sh tag-after-merge <slug>`. If it exits non-zero, report the output and stop. If it succeeds, ask the Owner to confirm pushing the new tag, then run `git push origin v<version>`.
 
 ## Rules
 
diff --git a/CLAUDE.md b/CLAUDE.md
index bf72a9b97511c2563b248078c46726b47a5c62a8..6ec3b7c56d404abd1d28a52eb982227c2e51b4ea
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -23,7 +23,7 @@
 2. **The gate is a script.** `scripts/gate.sh` exits 0 or it doesn't. You do not overrule it, reinterpret it, or declare work done while it fails.
 3. **Implementation happens in worktrees**, never in this checkout. `scripts/worktree.sh` manages them.
 4. **Artifacts flow between stages, not transcripts.** The reviewer gets the diff + plan, never the implementation conversation.
-5. **Release is a script.** `scripts/release.sh` owns release preconditions, versioning, changelog assembly, the release commit, tag, and local fast-forward merge. It never pushes.
+5. **Release is a script.** `scripts/release.sh` owns release preconditions, versioning, changelog assembly, and the release commit on the branch. It never pushes and never touches `main`; tagging happens in `/4-release` after the PR merges via `tag-after-merge`.
 
 ## Context tiers
 
diff --git a/config.yaml b/config.yaml
index 906edc83166366a7556ac002dd81216301f98e3a..0c6fe53d7df35ed60c70d2a88dea2a1da99ab640
--- a/config.yaml
+++ b/config.yaml
@@ -14,9 +14,6 @@
   # Claude Code implementer alternative:
   # command: 'claude -p --dangerously-skip-permissions'
 
-review:
-  human_pr_review: self      # self | platform-team
-
 gate:
   command: scripts/gate.sh
   max_retries: 2             # failed-gate feedback loops before escalating to the Owner
diff --git a/profiles/work.md b/profiles/work.md
index 047b6efdfa81e3d8ed0e0fa246144863ee6762b4..4496e556b94f00ebe837b804420788283ba70e90
--- a/profiles/work.md
+++ b/profiles/work.md
@@ -4,7 +4,6 @@
 
 ## Declarations required at /init
 
-- **Review topology** — set `review.human_pr_review` to `self` or `platform-team`.
 - **Implementer runtime** — when the workplace uses Claude Code for implementation, set `implementer.runtime: claude` and use:
 
 ```yaml
@@ -16,8 +15,7 @@
 ## Adds to the loop
 
 - **Jira:** Jira keys may be recorded as read-only references in `work/<slug>/plan.md`. The loop never creates or mutates Jira issues.
-- **Self review topology:** `scripts/release.sh` keeps the base release shape: it bumps `VERSION` and `CHANGELOG.md`, creates `vX.Y.Z`, fast-forwards local `main`, and stops before push. `/4-release` pushes `main` and the tag only after Owner confirmation.
-- **Platform-team review topology:** `scripts/release.sh` fetches `origin/main`, refuses when the release branch does not contain it, bumps `VERSION` and `CHANGELOG.md` on the release branch, creates no tag, and leaves local `main` untouched. `/4-release` pushes the release branch and prints the Bitbucket PR instruction; a platform engineer merges the PR.
+- **Release:** use the base PR-merge release flow.
 
 ## Gate
 
@@ -26,15 +24,3 @@
 - Add `bitbucket-pipelines.yml`.
 - Delete `.github/workflows/ci.yml`.
 - Keep the deterministic commands equivalent: install `shellcheck`, set a git identity, run `bash tests/test-scripts.sh`, then run `bash scripts/gate.sh`.
-
-## Platform-team release sync
-
-The platform-team release path treats remote `origin/main` as the current source of truth. `scripts/release.sh` fetches it before and after the gate, then refuses with a rebase/sync message if the release branch is stale.
-
-Keep the local `main` worktree pulled from the PR-merged remote before cutting new work. The required `main` worktree check only proves the linked worktree exists; it does not prove local `main` is current, because the release guard checks `origin/main`.
-
-Tagging is permanently manual in platform-team mode. If a tag is wanted after the Bitbucket PR merges, run:
-
-```sh
-git tag vX.Y.Z <merge-commit> && git push origin vX.Y.Z
-```
diff --git a/scripts/release.sh b/scripts/release.sh
index ce19d803956becc2b39b89e57262cb47e44dd359..4e421de6d2c68f9095c6e73232b7e5e4c1e01670
--- a/scripts/release.sh
+++ b/scripts/release.sh
@@ -8,12 +8,15 @@
   cat <<'EOF'
 Usage:
   scripts/release.sh <slug> [--confirm-delta <text>]
+  scripts/release.sh tag-after-merge <slug>
   scripts/release.sh check-version <new-version> [current-version]
   scripts/release.sh next-version [current-version]
 
-The full release path never pushes. In self-review mode it commits, tags,
-fast-forward merges to local main, then stops for the Owner-confirmed push step.
-In platform-team mode it commits the bump on the release branch for PR review.
+The release path never pushes, never tags, and never touches main. It commits
+the version bump on the release branch for PR review.
+
+After the PR merges, tag-after-merge verifies origin/main is the release commit
+and creates the local version tag. The tag push is a separate confirmed step.
 EOF
 }
 
@@ -159,27 +162,6 @@
   git -C "$checkout" diff --cached --quiet || die "$label has staged changes"
   [[ -z "$(git -C "$checkout" ls-files --others --exclude-standard)" ]] \
     || die "$label has untracked files"
-}
-
-check_ff_possible() {
-  local main_checkout="$1"
-  local release_branch="$2"
-
-  git -C "$main_checkout" rev-parse --verify --quiet "$release_branch" >/dev/null \
-    || die "missing release branch: $release_branch"
-  git -C "$main_checkout" merge-base --is-ancestor main "$release_branch" \
-    || die "main cannot fast-forward to $release_branch"
-}
-
-human_pr_review_mode() {
-  local mode
-
-  mode=$(awk '/^review:/{f=1;next} f&&/human_pr_review:/{print $2; exit}' config.yaml)
-  mode=${mode:-self}
-  case "$mode" in
-    self|platform-team) printf '%s\n' "$mode" ;;
-    *) die "invalid review.human_pr_review '$mode' (expected self or platform-team)" ;;
-  esac
 }
 
 check_origin_main_ancestor() {
@@ -195,13 +177,11 @@
 rollback_release() {
   local status=$?
   local pre_release_head="$1"
-  local new_version="$2"
 
   trap - ERR
   set +e
-  git tag -d "v$new_version" >/dev/null 2>&1
   git reset --hard "$pre_release_head" >/dev/null 2>&1
-  echo "release: irreversible step failed; release commit and tag changes were rolled back" >&2
+  echo "release: irreversible step failed; release commit was rolled back" >&2
   exit "$status"
 }
 
@@ -210,15 +190,13 @@
   local confirm_delta="$2"
   local plan_path="work/$slug/plan.md"
   local release_branch="wt/$slug"
-  local main_checkout
   local release_checkout
   local current_version
   local new_version
   local release_note
   local pre_release_head
-  local review_mode
 
-  main_checkout=$(worktree_for_branch main) \
+  worktree_for_branch main >/dev/null \
     || die "main must be checked out in the primary worktree"
   release_checkout=$(worktree_for_branch "$release_branch") \
     || die "$release_branch must be checked out in a linked worktree"
@@ -229,64 +207,75 @@
   cd "$release_checkout"
   current_version=$(<VERSION)
   new_version=$(next_version "$current_version")
-  review_mode=$(human_pr_review_mode)
 
   check_verdict "$plan_path"
   check_clean_worktree "$release_checkout" "$release_branch"
-  check_clean_worktree "$main_checkout" "main checkout"
-  if [[ "$review_mode" == self ]]; then
-    check_ff_possible "$main_checkout" "$release_branch"
-    git rev-parse --verify --quiet "refs/tags/v$new_version" >/dev/null \
-      && die "tag v$new_version already exists"
-  else
-    check_origin_main_ancestor "$release_branch"
-  fi
+  check_origin_main_ancestor "$release_branch"
   check_gate
   check_clean_worktree "$release_checkout" "$release_branch"
   check_archi_fresh
   check_version_exceeds "$new_version" "$current_version"
-  check_clean_worktree "$main_checkout" "main checkout"
-  if [[ "$review_mode" == self ]]; then
-    check_ff_possible "$main_checkout" "$release_branch"
-  else
-    check_origin_main_ancestor "$release_branch"
-  fi
+  check_origin_main_ancestor "$release_branch"
 
   release_note=$(extract_release_note "$plan_path")
   pre_release_head=$(git rev-parse HEAD)
-  trap 'rollback_release "$pre_release_head" "$new_version"' ERR
+  trap 'rollback_release "$pre_release_head"' ERR
 
   printf '%s\n' "$new_version" >VERSION
   prepend_changelog "$new_version" "$release_note" "$confirm_delta"
 
   git add VERSION CHANGELOG.md
   git commit -m "Release v$new_version"
-  if [[ "$review_mode" == self ]]; then
-    git tag "v$new_version"
-    git -C "$main_checkout" merge --ff-only "$release_branch"
-  fi
   trap - ERR
 
-  if [[ "$review_mode" == self ]]; then
-    cat <<EOF
-release: prepared v$new_version on local main
-release: stopped before push; push requires Owner confirmation in-session
-EOF
-  else
-    cat <<EOF
+  cat <<EOF
 release: prepared v$new_version on $release_branch
 release: no tag created; local main untouched
-release: push $release_branch, open a Bitbucket PR, and have a platform engineer merge it
+release: push $release_branch, open a PR, and merge it after review
 EOF
-  fi
 }
 
+tag_after_merge() {
+  local slug="$1"
+  local release_branch="wt/$slug"
+  local release_checkout
+  local version
+  local origin_version
+  local origin_subject
+
+  release_checkout=$(worktree_for_branch "$release_branch") \
+    || die "$release_branch must be checked out in a linked worktree"
+  [[ -f "$release_checkout/VERSION" ]] || die "missing VERSION in $release_branch"
+
+  git fetch origin main
+  git rev-parse --verify --quiet origin/main >/dev/null \
+    || die "missing origin/main after fetch"
+
+  version=$(<"$release_checkout/VERSION")
+  origin_version=$(git show origin/main:VERSION) \
+    || die "origin/main does not contain VERSION"
+  origin_subject=$(git log -1 --format=%s origin/main)
+
+  [[ "$origin_version" == "$version" && "$origin_subject" == "Release v$version" ]] \
+    || die "origin/main is not Release v$version (VERSION is $origin_version; subject is '$origin_subject')"
+
+  git rev-parse --verify --quiet "refs/tags/v$version" >/dev/null \
+    && die "tag v$version already exists"
+
+  git tag "v$version" origin/main
+  printf 'release: created local tag v%s on origin/main\n' "$version"
+}
+
 if [[ $# -eq 0 ]]; then
   usage
   exit 2
 fi
 
 case "$1" in
+  tag-after-merge)
+    [[ $# -eq 2 ]] || { usage; exit 2; }
+    tag_after_merge "$2"
+    ;;
   check-version)
     [[ $# -eq 2 || $# -eq 3 ]] || { usage; exit 2; }
     current=${3:-$(<VERSION)}
diff --git a/tests/test-scripts.sh b/tests/test-scripts.sh
index 77e929164770e68220eefdedb0591fc9e25e1f0b..473311694d7e6564bdac487d41e2a595aa54d116
--- a/tests/test-scripts.sh
+++ b/tests/test-scripts.sh
@@ -58,7 +58,6 @@
   local verdict_line="$3"
   local gate_mode="$4"
   local archi_mode="$5"
-  local review_mode="${6:-self}"
   local tmp_root="$TMP/$name"
 
   REL_PRIMARY="$tmp_root/primary"
@@ -93,11 +92,7 @@
 echo "GATE: PASS"
 EOF
     chmod +x scripts/release.sh scripts/gate.sh
-    {
-      printf 'name: fixture\n'
-      printf 'review:\n'
-      printf '  human_pr_review: %s\n' "$review_mode"
-    } >config.yaml
+    printf 'name: fixture\n' >config.yaml
     printf 'merge rules\n' >CLAUDE.md
     printf '%s\n' "$version" >VERSION
     printf '# Changelog\n\nAll notable changes to this project are documented in this file.\n\n' >CHANGELOG.md
@@ -173,52 +168,21 @@
 setup_release_fixture release-version-regresses 2026.9.0 "Code-review verdict: APPROVE" pass fresh
 check_fails "release refuses when computed version does not exceed VERSION" bash -c "cd '$REL_WORKTREE' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo"
 
-setup_release_fixture release-happy 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-origin_before=$(git -C "$REL_PRIMARY" rev-parse origin/main)
-check "release happy path lands fast-forward on primary main and stops before push" bash -c "
-  cd '$REL_WORKTREE' &&
+setup_release_fixture release-happy-primary 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+main_before=$(git -C "$REL_PRIMARY" rev-parse main)
+check "release can be invoked from primary checkout" bash -c "
+  cd '$REL_PRIMARY' &&
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
-  [ \"\$(git -C '$REL_PRIMARY' branch --show-current)\" = main ] &&
-  [ \"\$(cat '$REL_PRIMARY/VERSION')\" = 2026.8.10 ] &&
-  git -C '$REL_PRIMARY' merge-base --is-ancestor wt/demo main &&
-  git -C '$REL_PRIMARY' rev-parse --verify --quiet refs/tags/v2026.8.10 &&
-  [ \"\$(git -C '$REL_PRIMARY' rev-parse origin/main)\" = '$origin_before' ]
-"
-
-setup_release_fixture release-tag-race-rolls-back 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-release_head_before=$(git -C "$REL_WORKTREE" rev-parse HEAD)
-real_git=$(command -v git)
-tag_fail_bin="$TMP/tag-fail-bin"
-mkdir -p "$tag_fail_bin"
-cat >"$tag_fail_bin/git" <<EOF
-#!/usr/bin/env bash
-if [[ "\$1" == tag && "\${2:-}" == v2026.8.10 ]]; then
-  "$real_git" tag v2026.8.10 HEAD~1
-fi
-"$real_git" "\$@"
-EOF
-chmod +x "$tag_fail_bin/git"
-check "release rolls back cleanly when tag creation fails after prechecks" bash -c "
-  cd '$REL_WORKTREE' &&
-  PATH='$tag_fail_bin:$REL_FAKEBIN':\$PATH bash scripts/release.sh demo >/dev/null 2>&1 &&
-  exit 1
-  status=\$?
-  [ \"\$status\" -ne 0 ] &&
-  [ \"\$(git rev-parse HEAD)\" = '$release_head_before' ] &&
-  [ \"\$(cat VERSION)\" = 2026.8.9 ] &&
-  git diff --quiet &&
-  git diff --cached --quiet &&
-  [ -z \"\$(git ls-files --others --exclude-standard)\" ] &&
-  ! git rev-parse --verify --quiet refs/tags/v2026.8.10
+  [ \"\$(git -C '$REL_PRIMARY' rev-parse main)\" = '$main_before' ] &&
+  [ \"\$(cat '$REL_PRIMARY/VERSION')\" = 2026.8.9 ] &&
+  [ \"\$(cat '$REL_WORKTREE/VERSION')\" = 2026.8.10 ] &&
+  ! git -C '$REL_WORKTREE' rev-parse --verify --quiet refs/tags/v2026.8.10
 "
-
-setup_release_fixture release-happy-primary 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-check "release can be invoked from primary checkout" bash -c "cd '$REL_PRIMARY' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo && [ \"\$(cat VERSION)\" = 2026.8.10 ]"
 
-setup_release_fixture release-platform-single 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
+setup_release_fixture release-single 2026.8.9 "Code-review verdict: APPROVE" pass fresh
 origin_before=$(git -C "$REL_PRIMARY" rev-parse origin/main)
 main_before=$(git -C "$REL_PRIMARY" rev-parse main)
-check "platform-team release commits bump on branch without touching main or tagging" bash -c "
+check "release commits bump on branch without touching main, origin/main, or tagging" bash -c "
   cd '$REL_WORKTREE' &&
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
   [ \"\$(git -C '$REL_PRIMARY' rev-parse main)\" = '$main_before' ] &&
@@ -228,13 +192,13 @@
   ! git rev-parse --verify --quiet refs/tags/v2026.8.10
 "
 
-setup_release_fixture release-platform-sequential 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
-check "platform-team release refuses stale branch, then computes next micro after sync" bash -c "
+setup_release_fixture release-sequential 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+check "release refuses stale branch, then computes next micro after sync" bash -c "
   set -e
   cd '$REL_WORKTREE'
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo
   git push -q origin wt/demo:main
-  rel_b='$TMP/release-platform-sequential/b-wt'
+  rel_b='$TMP/release-sequential/b-wt'
   git -C '$REL_PRIMARY' branch wt/b main
   git -C '$REL_PRIMARY' worktree add -q \"\$rel_b\" wt/b
   git -C \"\$rel_b\" config user.email tester@example.com
@@ -243,7 +207,7 @@
   sed 's/# Demo/# B/' '$REL_WORKTREE/work/demo/plan.md' > \"\$rel_b/work/b/plan.md\"
   git -C \"\$rel_b\" add work/b/plan.md
   GIT_AUTHOR_DATE='2026-08-16T10:00:30Z' GIT_COMMITTER_DATE='2026-08-16T10:00:30Z' git -C \"\$rel_b\" commit -qm 'add b plan'
-  stale_out='$TMP/platform-stale.out'
+  stale_out='$TMP/release-stale.out'
   if PATH='$REL_FAKEBIN':\$PATH bash \"\$rel_b/scripts/release.sh\" b >\"\$stale_out\" 2>&1; then
     exit 1
   fi
@@ -257,15 +221,15 @@
   ! git rev-parse --verify --quiet refs/tags/v2026.8.11
 "
 
-setup_release_fixture release-platform-mid-gate 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
+setup_release_fixture release-mid-gate 2026.8.9 "Code-review verdict: APPROVE" pass fresh
 mkdir -p "$REL_WORKTREE/scripts/gate.d"
 cat >"$REL_WORKTREE/scripts/gate.d/move-origin-main.sh" <<EOF
 #!/usr/bin/env bash
 set -euo pipefail
 repo='$REL_PRIMARY'
-printf 'platform merge during gate\n' >> "\$repo/platform.txt"
-git -C "\$repo" add platform.txt
-GIT_AUTHOR_DATE='2026-08-16T10:02:00Z' GIT_COMMITTER_DATE='2026-08-16T10:02:00Z' git -C "\$repo" commit -qm 'platform merge during gate'
+printf 'merge during gate\n' >> "\$repo/remote-change.txt"
+git -C "\$repo" add remote-change.txt
+GIT_AUTHOR_DATE='2026-08-16T10:02:00Z' GIT_COMMITTER_DATE='2026-08-16T10:02:00Z' git -C "\$repo" commit -qm 'merge during gate'
 git -C "\$repo" push -q origin main
 EOF
 chmod +x "$REL_WORKTREE/scripts/gate.d/move-origin-main.sh"
@@ -274,15 +238,58 @@
   git add scripts/gate.d/move-origin-main.sh
   GIT_AUTHOR_DATE="2026-08-16T10:00:30Z" GIT_COMMITTER_DATE="2026-08-16T10:00:30Z" git commit -qm "add mid-gate hook"
 )
-check "platform-team release catches origin/main moving during gate" bash -c "
+check "release catches origin/main moving during gate" bash -c "
   cd '$REL_WORKTREE'
-  mid_gate_out='$TMP/platform-mid-gate.out'
+  mid_gate_out='$TMP/release-mid-gate.out'
   if PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo >\"\$mid_gate_out\" 2>&1; then
     exit 1
   fi
   grep -q 'rebase/sync your branch onto origin/main' \"\$mid_gate_out\"
 "
 
+setup_release_fixture release-tag-after-merge-happy 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+real_git=$(command -v git)
+push_log="$TMP/tag-after-merge-push.log"
+tag_guard_bin="$TMP/tag-after-merge-bin"
+mkdir -p "$tag_guard_bin"
+cat >"$tag_guard_bin/git" <<EOF
+#!/usr/bin/env bash
+if [[ "\$1" == push ]]; then
+  printf 'unexpected push\n' >> "$push_log"
+  exit 99
+fi
+"$real_git" "\$@"
+EOF
+chmod +x "$tag_guard_bin/git"
+check "tag-after-merge creates local tag on origin/main and pushes nothing" bash -c "
+  cd '$REL_WORKTREE' &&
+  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
+  git push -q origin wt/demo:main &&
+  PATH='$tag_guard_bin:$REL_FAKEBIN':\$PATH bash scripts/release.sh tag-after-merge demo &&
+  [ \"\$(git rev-parse refs/tags/v2026.8.10)\" = \"\$(git rev-parse origin/main)\" ] &&
+  [ ! -s '$push_log' ]
+"
+
+setup_release_fixture release-tag-after-merge-wrong-commit 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+check "tag-after-merge refuses when origin/main advanced past the release" bash -c "
+  set -e
+  cd '$REL_WORKTREE'
+  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo
+  git push -q origin wt/demo:main
+  git -C '$REL_PRIMARY' fetch -q origin main
+  git -C '$REL_PRIMARY' reset -q --hard origin/main
+  printf 'next change\n' > '$REL_PRIMARY/after-release.txt'
+  git -C '$REL_PRIMARY' add after-release.txt
+  GIT_AUTHOR_DATE='2026-08-16T10:03:00Z' GIT_COMMITTER_DATE='2026-08-16T10:03:00Z' git -C '$REL_PRIMARY' commit -qm 'Next change'
+  git -C '$REL_PRIMARY' push -q origin main
+  wrong_out='$TMP/tag-after-merge-wrong.out'
+  if PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh tag-after-merge demo >\"\$wrong_out\" 2>&1; then
+    exit 1
+  fi
+  grep -q 'origin/main is not Release v2026.8.10' \"\$wrong_out\" &&
+  ! git rev-parse --verify --quiet refs/tags/v2026.8.10
+"
+
 # --- gate.sh runs and exits cleanly on this repo
 check "gate.sh runs on this repo" bash scripts/gate.sh
 

codex
The cheap greps are clean: no removed topology terms in `release.sh`, no `git push` there, and the tests no longer reference the deleted review mode. I’m running the full gate now; this may take a bit because it runs the smoke suite fixtures.
exec
/bin/zsh -lc 'bash scripts/gate.sh' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
diff --git a/.claude/skills/4-release/SKILL.md b/.claude/skills/4-release/SKILL.md
index 923d42b3ecf0574b4e04bc3d1d7d6b9fb9d647fe..e292a1fec26467e14eeab6dd25f32644bd12717f
--- a/.claude/skills/4-release/SKILL.md
+++ b/.claude/skills/4-release/SKILL.md
@@ -11,13 +11,11 @@
 
 1. **Confirm intent:** ask the Owner for the in-session release confirmation and capture the `Confirm-delta:` value.
 2. **Run the release script:** from the repo root, run `bash scripts/release.sh <slug> --confirm-delta "<value>"`.
-3. **React to the exit code based on `review.human_pr_review`:**
-   - Exit 0 with `self` → report the prepared version, tag, and local `main` state.
-   - Exit 0 with `platform-team` → report the bump commit on the release branch, that no tag was created, and that local `main` was untouched.
+3. **React to the exit code:**
+   - Exit 0 → report the bump commit on the release branch, that no tag exists yet, and that `main` was untouched.
    - Non-zero → report the script output and stop.
-4. **Push separately based on `review.human_pr_review`:**
-   - `self` → after the Owner confirms the push, push `main` and the new tag.
-   - `platform-team` → after the Owner confirms the push, push the release branch, print instructions to open a Bitbucket PR, and never push `main`.
+4. **Push the release branch:** after the Owner confirms the push, push the release branch, print instructions to open a PR and get it merged, and never push `main`.
+5. **Tag after merge:** once the Owner confirms the PR has merged, run `bash scripts/release.sh tag-after-merge <slug>`. If it exits non-zero, report the output and stop. If it succeeds, ask the Owner to confirm pushing the new tag, then run `git push origin v<version>`.
 
 ## Rules
 
diff --git a/CLAUDE.md b/CLAUDE.md
index bf72a9b97511c2563b248078c46726b47a5c62a8..6ec3b7c56d404abd1d28a52eb982227c2e51b4ea
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -23,7 +23,7 @@
 2. **The gate is a script.** `scripts/gate.sh` exits 0 or it doesn't. You do not overrule it, reinterpret it, or declare work done while it fails.
 3. **Implementation happens in worktrees**, never in this checkout. `scripts/worktree.sh` manages them.
 4. **Artifacts flow between stages, not transcripts.** The reviewer gets the diff + plan, never the implementation conversation.
-5. **Release is a script.** `scripts/release.sh` owns release preconditions, versioning, changelog assembly, the release commit, tag, and local fast-forward merge. It never pushes.
+5. **Release is a script.** `scripts/release.sh` owns release preconditions, versioning, changelog assembly, and the release commit on the branch. It never pushes and never touches `main`; tagging happens in `/4-release` after the PR merges via `tag-after-merge`.
 
 ## Context tiers
 
diff --git a/config.yaml b/config.yaml
index 906edc83166366a7556ac002dd81216301f98e3a..0c6fe53d7df35ed60c70d2a88dea2a1da99ab640
--- a/config.yaml
+++ b/config.yaml
@@ -14,9 +14,6 @@
   # Claude Code implementer alternative:
   # command: 'claude -p --dangerously-skip-permissions'
 
-review:
-  human_pr_review: self      # self | platform-team
-
 gate:
   command: scripts/gate.sh
   max_retries: 2             # failed-gate feedback loops before escalating to the Owner
diff --git a/profiles/work.md b/profiles/work.md
index 047b6efdfa81e3d8ed0e0fa246144863ee6762b4..4496e556b94f00ebe837b804420788283ba70e90
--- a/profiles/work.md
+++ b/profiles/work.md
@@ -4,7 +4,6 @@
 
 ## Declarations required at /init
 
-- **Review topology** — set `review.human_pr_review` to `self` or `platform-team`.
 - **Implementer runtime** — when the workplace uses Claude Code for implementation, set `implementer.runtime: claude` and use:
 
 ```yaml
@@ -16,8 +15,7 @@
 ## Adds to the loop
 
 - **Jira:** Jira keys may be recorded as read-only references in `work/<slug>/plan.md`. The loop never creates or mutates Jira issues.
-- **Self review topology:** `scripts/release.sh` keeps the base release shape: it bumps `VERSION` and `CHANGELOG.md`, creates `vX.Y.Z`, fast-forwards local `main`, and stops before push. `/4-release` pushes `main` and the tag only after Owner confirmation.
-- **Platform-team review topology:** `scripts/release.sh` fetches `origin/main`, refuses when the release branch does not contain it, bumps `VERSION` and `CHANGELOG.md` on the release branch, creates no tag, and leaves local `main` untouched. `/4-release` pushes the release branch and prints the Bitbucket PR instruction; a platform engineer merges the PR.
+- **Release:** use the base PR-merge release flow.
 
 ## Gate
 
@@ -26,15 +24,3 @@
 - Add `bitbucket-pipelines.yml`.
 - Delete `.github/workflows/ci.yml`.
 - Keep the deterministic commands equivalent: install `shellcheck`, set a git identity, run `bash tests/test-scripts.sh`, then run `bash scripts/gate.sh`.
-
-## Platform-team release sync
-
-The platform-team release path treats remote `origin/main` as the current source of truth. `scripts/release.sh` fetches it before and after the gate, then refuses with a rebase/sync message if the release branch is stale.
-
-Keep the local `main` worktree pulled from the PR-merged remote before cutting new work. The required `main` worktree check only proves the linked worktree exists; it does not prove local `main` is current, because the release guard checks `origin/main`.
-
-Tagging is permanently manual in platform-team mode. If a tag is wanted after the Bitbucket PR merges, run:
-
-```sh
-git tag vX.Y.Z <merge-commit> && git push origin vX.Y.Z
-```
diff --git a/scripts/release.sh b/scripts/release.sh
index ce19d803956becc2b39b89e57262cb47e44dd359..4e421de6d2c68f9095c6e73232b7e5e4c1e01670
--- a/scripts/release.sh
+++ b/scripts/release.sh
@@ -8,12 +8,15 @@
   cat <<'EOF'
 Usage:
   scripts/release.sh <slug> [--confirm-delta <text>]
+  scripts/release.sh tag-after-merge <slug>
   scripts/release.sh check-version <new-version> [current-version]
   scripts/release.sh next-version [current-version]
 
-The full release path never pushes. In self-review mode it commits, tags,
-fast-forward merges to local main, then stops for the Owner-confirmed push step.
-In platform-team mode it commits the bump on the release branch for PR review.
+The release path never pushes, never tags, and never touches main. It commits
+the version bump on the release branch for PR review.
+
+After the PR merges, tag-after-merge verifies origin/main is the release commit
+and creates the local version tag. The tag push is a separate confirmed step.
 EOF
 }
 
@@ -159,27 +162,6 @@
   git -C "$checkout" diff --cached --quiet || die "$label has staged changes"
   [[ -z "$(git -C "$checkout" ls-files --others --exclude-standard)" ]] \
     || die "$label has untracked files"
-}
-
-check_ff_possible() {
-  local main_checkout="$1"
-  local release_branch="$2"
-
-  git -C "$main_checkout" rev-parse --verify --quiet "$release_branch" >/dev/null \
-    || die "missing release branch: $release_branch"
-  git -C "$main_checkout" merge-base --is-ancestor main "$release_branch" \
-    || die "main cannot fast-forward to $release_branch"
-}
-
-human_pr_review_mode() {
-  local mode
-
-  mode=$(awk '/^review:/{f=1;next} f&&/human_pr_review:/{print $2; exit}' config.yaml)
-  mode=${mode:-self}
-  case "$mode" in
-    self|platform-team) printf '%s\n' "$mode" ;;
-    *) die "invalid review.human_pr_review '$mode' (expected self or platform-team)" ;;
-  esac
 }
 
 check_origin_main_ancestor() {
@@ -195,13 +177,11 @@
 rollback_release() {
   local status=$?
   local pre_release_head="$1"
-  local new_version="$2"
 
   trap - ERR
   set +e
-  git tag -d "v$new_version" >/dev/null 2>&1
   git reset --hard "$pre_release_head" >/dev/null 2>&1
-  echo "release: irreversible step failed; release commit and tag changes were rolled back" >&2
+  echo "release: irreversible step failed; release commit was rolled back" >&2
   exit "$status"
 }
 
@@ -210,15 +190,13 @@
   local confirm_delta="$2"
   local plan_path="work/$slug/plan.md"
   local release_branch="wt/$slug"
-  local main_checkout
   local release_checkout
   local current_version
   local new_version
   local release_note
   local pre_release_head
-  local review_mode
 
-  main_checkout=$(worktree_for_branch main) \
+  worktree_for_branch main >/dev/null \
     || die "main must be checked out in the primary worktree"
   release_checkout=$(worktree_for_branch "$release_branch") \
     || die "$release_branch must be checked out in a linked worktree"
@@ -229,64 +207,75 @@
   cd "$release_checkout"
   current_version=$(<VERSION)
   new_version=$(next_version "$current_version")
-  review_mode=$(human_pr_review_mode)
 
   check_verdict "$plan_path"
   check_clean_worktree "$release_checkout" "$release_branch"
-  check_clean_worktree "$main_checkout" "main checkout"
-  if [[ "$review_mode" == self ]]; then
-    check_ff_possible "$main_checkout" "$release_branch"
-    git rev-parse --verify --quiet "refs/tags/v$new_version" >/dev/null \
-      && die "tag v$new_version already exists"
-  else
-    check_origin_main_ancestor "$release_branch"
-  fi
+  check_origin_main_ancestor "$release_branch"
   check_gate
   check_clean_worktree "$release_checkout" "$release_branch"
   check_archi_fresh
   check_version_exceeds "$new_version" "$current_version"
-  check_clean_worktree "$main_checkout" "main checkout"
-  if [[ "$review_mode" == self ]]; then
-    check_ff_possible "$main_checkout" "$release_branch"
-  else
-    check_origin_main_ancestor "$release_branch"
-  fi
+  check_origin_main_ancestor "$release_branch"
 
   release_note=$(extract_release_note "$plan_path")
   pre_release_head=$(git rev-parse HEAD)
-  trap 'rollback_release "$pre_release_head" "$new_version"' ERR
+  trap 'rollback_release "$pre_release_head"' ERR
 
   printf '%s\n' "$new_version" >VERSION
   prepend_changelog "$new_version" "$release_note" "$confirm_delta"
 
   git add VERSION CHANGELOG.md
   git commit -m "Release v$new_version"
-  if [[ "$review_mode" == self ]]; then
-    git tag "v$new_version"
-    git -C "$main_checkout" merge --ff-only "$release_branch"
-  fi
   trap - ERR
 
-  if [[ "$review_mode" == self ]]; then
-    cat <<EOF
-release: prepared v$new_version on local main
-release: stopped before push; push requires Owner confirmation in-session
-EOF
-  else
-    cat <<EOF
+  cat <<EOF
 release: prepared v$new_version on $release_branch
 release: no tag created; local main untouched
-release: push $release_branch, open a Bitbucket PR, and have a platform engineer merge it
+release: push $release_branch, open a PR, and merge it after review
 EOF
-  fi
 }
 
+tag_after_merge() {
+  local slug="$1"
+  local release_branch="wt/$slug"
+  local release_checkout
+  local version
+  local origin_version
+  local origin_subject
+
+  release_checkout=$(worktree_for_branch "$release_branch") \
+    || die "$release_branch must be checked out in a linked worktree"
+  [[ -f "$release_checkout/VERSION" ]] || die "missing VERSION in $release_branch"
+
+  git fetch origin main
+  git rev-parse --verify --quiet origin/main >/dev/null \
+    || die "missing origin/main after fetch"
+
+  version=$(<"$release_checkout/VERSION")
+  origin_version=$(git show origin/main:VERSION) \
+    || die "origin/main does not contain VERSION"
+  origin_subject=$(git log -1 --format=%s origin/main)
+
+  [[ "$origin_version" == "$version" && "$origin_subject" == "Release v$version" ]] \
+    || die "origin/main is not Release v$version (VERSION is $origin_version; subject is '$origin_subject')"
+
+  git rev-parse --verify --quiet "refs/tags/v$version" >/dev/null \
+    && die "tag v$version already exists"
+
+  git tag "v$version" origin/main
+  printf 'release: created local tag v%s on origin/main\n' "$version"
+}
+
 if [[ $# -eq 0 ]]; then
   usage
   exit 2
 fi
 
 case "$1" in
+  tag-after-merge)
+    [[ $# -eq 2 ]] || { usage; exit 2; }
+    tag_after_merge "$2"
+    ;;
   check-version)
     [[ $# -eq 2 || $# -eq 3 ]] || { usage; exit 2; }
     current=${3:-$(<VERSION)}
diff --git a/tests/test-scripts.sh b/tests/test-scripts.sh
index 77e929164770e68220eefdedb0591fc9e25e1f0b..473311694d7e6564bdac487d41e2a595aa54d116
--- a/tests/test-scripts.sh
+++ b/tests/test-scripts.sh
@@ -58,7 +58,6 @@
   local verdict_line="$3"
   local gate_mode="$4"
   local archi_mode="$5"
-  local review_mode="${6:-self}"
   local tmp_root="$TMP/$name"
 
   REL_PRIMARY="$tmp_root/primary"
@@ -93,11 +92,7 @@
 echo "GATE: PASS"
 EOF
     chmod +x scripts/release.sh scripts/gate.sh
-    {
-      printf 'name: fixture\n'
-      printf 'review:\n'
-      printf '  human_pr_review: %s\n' "$review_mode"
-    } >config.yaml
+    printf 'name: fixture\n' >config.yaml
     printf 'merge rules\n' >CLAUDE.md
     printf '%s\n' "$version" >VERSION
     printf '# Changelog\n\nAll notable changes to this project are documented in this file.\n\n' >CHANGELOG.md
@@ -173,52 +168,21 @@
 setup_release_fixture release-version-regresses 2026.9.0 "Code-review verdict: APPROVE" pass fresh
 check_fails "release refuses when computed version does not exceed VERSION" bash -c "cd '$REL_WORKTREE' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo"
 
-setup_release_fixture release-happy 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-origin_before=$(git -C "$REL_PRIMARY" rev-parse origin/main)
-check "release happy path lands fast-forward on primary main and stops before push" bash -c "
-  cd '$REL_WORKTREE' &&
+setup_release_fixture release-happy-primary 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+main_before=$(git -C "$REL_PRIMARY" rev-parse main)
+check "release can be invoked from primary checkout" bash -c "
+  cd '$REL_PRIMARY' &&
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
-  [ \"\$(git -C '$REL_PRIMARY' branch --show-current)\" = main ] &&
-  [ \"\$(cat '$REL_PRIMARY/VERSION')\" = 2026.8.10 ] &&
-  git -C '$REL_PRIMARY' merge-base --is-ancestor wt/demo main &&
-  git -C '$REL_PRIMARY' rev-parse --verify --quiet refs/tags/v2026.8.10 &&
-  [ \"\$(git -C '$REL_PRIMARY' rev-parse origin/main)\" = '$origin_before' ]
-"
-
-setup_release_fixture release-tag-race-rolls-back 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-release_head_before=$(git -C "$REL_WORKTREE" rev-parse HEAD)
-real_git=$(command -v git)
-tag_fail_bin="$TMP/tag-fail-bin"
-mkdir -p "$tag_fail_bin"
-cat >"$tag_fail_bin/git" <<EOF
-#!/usr/bin/env bash
-if [[ "\$1" == tag && "\${2:-}" == v2026.8.10 ]]; then
-  "$real_git" tag v2026.8.10 HEAD~1
-fi
-"$real_git" "\$@"
-EOF
-chmod +x "$tag_fail_bin/git"
-check "release rolls back cleanly when tag creation fails after prechecks" bash -c "
-  cd '$REL_WORKTREE' &&
-  PATH='$tag_fail_bin:$REL_FAKEBIN':\$PATH bash scripts/release.sh demo >/dev/null 2>&1 &&
-  exit 1
-  status=\$?
-  [ \"\$status\" -ne 0 ] &&
-  [ \"\$(git rev-parse HEAD)\" = '$release_head_before' ] &&
-  [ \"\$(cat VERSION)\" = 2026.8.9 ] &&
-  git diff --quiet &&
-  git diff --cached --quiet &&
-  [ -z \"\$(git ls-files --others --exclude-standard)\" ] &&
-  ! git rev-parse --verify --quiet refs/tags/v2026.8.10
+  [ \"\$(git -C '$REL_PRIMARY' rev-parse main)\" = '$main_before' ] &&
+  [ \"\$(cat '$REL_PRIMARY/VERSION')\" = 2026.8.9 ] &&
+  [ \"\$(cat '$REL_WORKTREE/VERSION')\" = 2026.8.10 ] &&
+  ! git -C '$REL_WORKTREE' rev-parse --verify --quiet refs/tags/v2026.8.10
 "
-
-setup_release_fixture release-happy-primary 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-check "release can be invoked from primary checkout" bash -c "cd '$REL_PRIMARY' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo && [ \"\$(cat VERSION)\" = 2026.8.10 ]"
 
-setup_release_fixture release-platform-single 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
+setup_release_fixture release-single 2026.8.9 "Code-review verdict: APPROVE" pass fresh
 origin_before=$(git -C "$REL_PRIMARY" rev-parse origin/main)
 main_before=$(git -C "$REL_PRIMARY" rev-parse main)
-check "platform-team release commits bump on branch without touching main or tagging" bash -c "
+check "release commits bump on branch without touching main, origin/main, or tagging" bash -c "
   cd '$REL_WORKTREE' &&
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
   [ \"\$(git -C '$REL_PRIMARY' rev-parse main)\" = '$main_before' ] &&
@@ -228,13 +192,13 @@
   ! git rev-parse --verify --quiet refs/tags/v2026.8.10
 "
 
-setup_release_fixture release-platform-sequential 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
-check "platform-team release refuses stale branch, then computes next micro after sync" bash -c "
+setup_release_fixture release-sequential 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+check "release refuses stale branch, then computes next micro after sync" bash -c "
   set -e
   cd '$REL_WORKTREE'
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo
   git push -q origin wt/demo:main
-  rel_b='$TMP/release-platform-sequential/b-wt'
+  rel_b='$TMP/release-sequential/b-wt'
   git -C '$REL_PRIMARY' branch wt/b main
   git -C '$REL_PRIMARY' worktree add -q \"\$rel_b\" wt/b
   git -C \"\$rel_b\" config user.email tester@example.com
@@ -243,7 +207,7 @@
   sed 's/# Demo/# B/' '$REL_WORKTREE/work/demo/plan.md' > \"\$rel_b/work/b/plan.md\"
   git -C \"\$rel_b\" add work/b/plan.md
   GIT_AUTHOR_DATE='2026-08-16T10:00:30Z' GIT_COMMITTER_DATE='2026-08-16T10:00:30Z' git -C \"\$rel_b\" commit -qm 'add b plan'
-  stale_out='$TMP/platform-stale.out'
+  stale_out='$TMP/release-stale.out'
   if PATH='$REL_FAKEBIN':\$PATH bash \"\$rel_b/scripts/release.sh\" b >\"\$stale_out\" 2>&1; then
     exit 1
   fi
@@ -257,15 +221,15 @@
   ! git rev-parse --verify --quiet refs/tags/v2026.8.11
 "
 
-setup_release_fixture release-platform-mid-gate 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
+setup_release_fixture release-mid-gate 2026.8.9 "Code-review verdict: APPROVE" pass fresh
 mkdir -p "$REL_WORKTREE/scripts/gate.d"
 cat >"$REL_WORKTREE/scripts/gate.d/move-origin-main.sh" <<EOF
 #!/usr/bin/env bash
 set -euo pipefail
 repo='$REL_PRIMARY'
-printf 'platform merge during gate\n' >> "\$repo/platform.txt"
-git -C "\$repo" add platform.txt
-GIT_AUTHOR_DATE='2026-08-16T10:02:00Z' GIT_COMMITTER_DATE='2026-08-16T10:02:00Z' git -C "\$repo" commit -qm 'platform merge during gate'
+printf 'merge during gate\n' >> "\$repo/remote-change.txt"
+git -C "\$repo" add remote-change.txt
+GIT_AUTHOR_DATE='2026-08-16T10:02:00Z' GIT_COMMITTER_DATE='2026-08-16T10:02:00Z' git -C "\$repo" commit -qm 'merge during gate'
 git -C "\$repo" push -q origin main
 EOF
 chmod +x "$REL_WORKTREE/scripts/gate.d/move-origin-main.sh"
@@ -274,15 +238,58 @@
   git add scripts/gate.d/move-origin-main.sh
   GIT_AUTHOR_DATE="2026-08-16T10:00:30Z" GIT_COMMITTER_DATE="2026-08-16T10:00:30Z" git commit -qm "add mid-gate hook"
 )
-check "platform-team release catches origin/main moving during gate" bash -c "
+check "release catches origin/main moving during gate" bash -c "
   cd '$REL_WORKTREE'
-  mid_gate_out='$TMP/platform-mid-gate.out'
+  mid_gate_out='$TMP/release-mid-gate.out'
   if PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo >\"\$mid_gate_out\" 2>&1; then
     exit 1
   fi
   grep -q 'rebase/sync your branch onto origin/main' \"\$mid_gate_out\"
 "
 
+setup_release_fixture release-tag-after-merge-happy 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+real_git=$(command -v git)
+push_log="$TMP/tag-after-merge-push.log"
+tag_guard_bin="$TMP/tag-after-merge-bin"
+mkdir -p "$tag_guard_bin"
+cat >"$tag_guard_bin/git" <<EOF
+#!/usr/bin/env bash
+if [[ "\$1" == push ]]; then
+  printf 'unexpected push\n' >> "$push_log"
+  exit 99
+fi
+"$real_git" "\$@"
+EOF
+chmod +x "$tag_guard_bin/git"
+check "tag-after-merge creates local tag on origin/main and pushes nothing" bash -c "
+  cd '$REL_WORKTREE' &&
+  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
+  git push -q origin wt/demo:main &&
+  PATH='$tag_guard_bin:$REL_FAKEBIN':\$PATH bash scripts/release.sh tag-after-merge demo &&
+  [ \"\$(git rev-parse refs/tags/v2026.8.10)\" = \"\$(git rev-parse origin/main)\" ] &&
+  [ ! -s '$push_log' ]
+"
+
+setup_release_fixture release-tag-after-merge-wrong-commit 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+check "tag-after-merge refuses when origin/main advanced past the release" bash -c "
+  set -e
+  cd '$REL_WORKTREE'
+  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo
+  git push -q origin wt/demo:main
+  git -C '$REL_PRIMARY' fetch -q origin main
+  git -C '$REL_PRIMARY' reset -q --hard origin/main
+  printf 'next change\n' > '$REL_PRIMARY/after-release.txt'
+  git -C '$REL_PRIMARY' add after-release.txt
+  GIT_AUTHOR_DATE='2026-08-16T10:03:00Z' GIT_COMMITTER_DATE='2026-08-16T10:03:00Z' git -C '$REL_PRIMARY' commit -qm 'Next change'
+  git -C '$REL_PRIMARY' push -q origin main
+  wrong_out='$TMP/tag-after-merge-wrong.out'
+  if PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh tag-after-merge demo >\"\$wrong_out\" 2>&1; then
+    exit 1
+  fi
+  grep -q 'origin/main is not Release v2026.8.10' \"\$wrong_out\" &&
+  ! git rev-parse --verify --quiet refs/tags/v2026.8.10
+"
+
 # --- gate.sh runs and exits cleanly on this repo
 check "gate.sh runs on this repo" bash scripts/gate.sh
 

 succeeded in 5445ms:
▶ bash scripts/gate.d/test-scripts.sh
ok: shellcheck scripts
ok: worktree add creates directory
ok: worktree branch checked out
ok: worktree.sh works FROM INSIDE a worktree (.git-as-file)
ok: worktree remove
ok: worktree add without slug fails
ok: agent-exec rejects missing handoff
ok: release version compare accepts .10 over .9
ok: release version compare rejects .9 after .10
ok: release refuses without code-review approval
ok: release refuses when gate fails
ok: release refuses when ARCHI.md is stale
ok: release refuses when computed version does not exceed VERSION
ok: release can be invoked from primary checkout
ok: release commits bump on branch without touching main, origin/main, or tagging
ok: release refuses stale branch, then computes next micro after sync
ok: release catches origin/main moving during gate
ok: tag-after-merge creates local tag on origin/main and pushes nothing
ok: tag-after-merge refuses when origin/main advanced past the release
ok: gate.sh runs on this repo

passed: 20, failed: 0
GATE: PASS

codex
The required gate passes. I’m doing a final scoped status/diff check now, then I’ll commit only the allowed files with a release-topology message.
exec
/bin/zsh -lc "grep -n 'review:' config.yaml || true" in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
exec
/bin/zsh -lc "grep -E 'human_pr_review|platform-team|self-review|check_ff_possible|merge --ff-only|git push' scripts/release.sh || true" in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
 succeeded in 0ms:
 succeeded in 0ms:
exec
/bin/zsh -lc 'rg -n "check_origin_main_ancestor" scripts/release.sh' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
 succeeded in 0ms:
167:check_origin_main_ancestor() {
213:  check_origin_main_ancestor "$release_branch"
218:  check_origin_main_ancestor "$release_branch"

exec
/bin/zsh -lc 'rg -n "review_mode|human_pr_review|platform-team" tests/test-scripts.sh || true' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
 succeeded in 0ms:
exec
/bin/zsh -lc 'git status --short' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
 succeeded in 0ms:
 M CLAUDE.md
 M config.yaml
 M profiles/work.md
 M scripts/release.sh
 M skills/4-release/SKILL.md
 M tests/test-scripts.sh
?? work/pr-merge-topology/

diff --git a/.claude/skills/4-release/SKILL.md b/.claude/skills/4-release/SKILL.md
index 923d42b3ecf0574b4e04bc3d1d7d6b9fb9d647fe..e292a1fec26467e14eeab6dd25f32644bd12717f
--- a/.claude/skills/4-release/SKILL.md
+++ b/.claude/skills/4-release/SKILL.md
@@ -11,13 +11,11 @@
 
 1. **Confirm intent:** ask the Owner for the in-session release confirmation and capture the `Confirm-delta:` value.
 2. **Run the release script:** from the repo root, run `bash scripts/release.sh <slug> --confirm-delta "<value>"`.
-3. **React to the exit code based on `review.human_pr_review`:**
-   - Exit 0 with `self` → report the prepared version, tag, and local `main` state.
-   - Exit 0 with `platform-team` → report the bump commit on the release branch, that no tag was created, and that local `main` was untouched.
+3. **React to the exit code:**
+   - Exit 0 → report the bump commit on the release branch, that no tag exists yet, and that `main` was untouched.
    - Non-zero → report the script output and stop.
-4. **Push separately based on `review.human_pr_review`:**
-   - `self` → after the Owner confirms the push, push `main` and the new tag.
-   - `platform-team` → after the Owner confirms the push, push the release branch, print instructions to open a Bitbucket PR, and never push `main`.
+4. **Push the release branch:** after the Owner confirms the push, push the release branch, print instructions to open a PR and get it merged, and never push `main`.
+5. **Tag after merge:** once the Owner confirms the PR has merged, run `bash scripts/release.sh tag-after-merge <slug>`. If it exits non-zero, report the output and stop. If it succeeds, ask the Owner to confirm pushing the new tag, then run `git push origin v<version>`.
 
 ## Rules
 
diff --git a/CLAUDE.md b/CLAUDE.md
index bf72a9b97511c2563b248078c46726b47a5c62a8..6ec3b7c56d404abd1d28a52eb982227c2e51b4ea
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -23,7 +23,7 @@
 2. **The gate is a script.** `scripts/gate.sh` exits 0 or it doesn't. You do not overrule it, reinterpret it, or declare work done while it fails.
 3. **Implementation happens in worktrees**, never in this checkout. `scripts/worktree.sh` manages them.
 4. **Artifacts flow between stages, not transcripts.** The reviewer gets the diff + plan, never the implementation conversation.
-5. **Release is a script.** `scripts/release.sh` owns release preconditions, versioning, changelog assembly, the release commit, tag, and local fast-forward merge. It never pushes.
+5. **Release is a script.** `scripts/release.sh` owns release preconditions, versioning, changelog assembly, and the release commit on the branch. It never pushes and never touches `main`; tagging happens in `/4-release` after the PR merges via `tag-after-merge`.
 
 ## Context tiers
 
diff --git a/config.yaml b/config.yaml
index 906edc83166366a7556ac002dd81216301f98e3a..0c6fe53d7df35ed60c70d2a88dea2a1da99ab640
--- a/config.yaml
+++ b/config.yaml
@@ -14,9 +14,6 @@
   # Claude Code implementer alternative:
   # command: 'claude -p --dangerously-skip-permissions'
 
-review:
-  human_pr_review: self      # self | platform-team
-
 gate:
   command: scripts/gate.sh
   max_retries: 2             # failed-gate feedback loops before escalating to the Owner
diff --git a/profiles/work.md b/profiles/work.md
index 047b6efdfa81e3d8ed0e0fa246144863ee6762b4..4496e556b94f00ebe837b804420788283ba70e90
--- a/profiles/work.md
+++ b/profiles/work.md
@@ -4,7 +4,6 @@
 
 ## Declarations required at /init
 
-- **Review topology** — set `review.human_pr_review` to `self` or `platform-team`.
 - **Implementer runtime** — when the workplace uses Claude Code for implementation, set `implementer.runtime: claude` and use:
 
 ```yaml
@@ -16,8 +15,7 @@
 ## Adds to the loop
 
 - **Jira:** Jira keys may be recorded as read-only references in `work/<slug>/plan.md`. The loop never creates or mutates Jira issues.
-- **Self review topology:** `scripts/release.sh` keeps the base release shape: it bumps `VERSION` and `CHANGELOG.md`, creates `vX.Y.Z`, fast-forwards local `main`, and stops before push. `/4-release` pushes `main` and the tag only after Owner confirmation.
-- **Platform-team review topology:** `scripts/release.sh` fetches `origin/main`, refuses when the release branch does not contain it, bumps `VERSION` and `CHANGELOG.md` on the release branch, creates no tag, and leaves local `main` untouched. `/4-release` pushes the release branch and prints the Bitbucket PR instruction; a platform engineer merges the PR.
+- **Release:** use the base PR-merge release flow.
 
 ## Gate
 
@@ -26,15 +24,3 @@
 - Add `bitbucket-pipelines.yml`.
 - Delete `.github/workflows/ci.yml`.
 - Keep the deterministic commands equivalent: install `shellcheck`, set a git identity, run `bash tests/test-scripts.sh`, then run `bash scripts/gate.sh`.
-
-## Platform-team release sync
-
-The platform-team release path treats remote `origin/main` as the current source of truth. `scripts/release.sh` fetches it before and after the gate, then refuses with a rebase/sync message if the release branch is stale.
-
-Keep the local `main` worktree pulled from the PR-merged remote before cutting new work. The required `main` worktree check only proves the linked worktree exists; it does not prove local `main` is current, because the release guard checks `origin/main`.
-
-Tagging is permanently manual in platform-team mode. If a tag is wanted after the Bitbucket PR merges, run:
-
-```sh
-git tag vX.Y.Z <merge-commit> && git push origin vX.Y.Z
-```
diff --git a/scripts/release.sh b/scripts/release.sh
index ce19d803956becc2b39b89e57262cb47e44dd359..4e421de6d2c68f9095c6e73232b7e5e4c1e01670
--- a/scripts/release.sh
+++ b/scripts/release.sh
@@ -8,12 +8,15 @@
   cat <<'EOF'
 Usage:
   scripts/release.sh <slug> [--confirm-delta <text>]
+  scripts/release.sh tag-after-merge <slug>
   scripts/release.sh check-version <new-version> [current-version]
   scripts/release.sh next-version [current-version]
 
-The full release path never pushes. In self-review mode it commits, tags,
-fast-forward merges to local main, then stops for the Owner-confirmed push step.
-In platform-team mode it commits the bump on the release branch for PR review.
+The release path never pushes, never tags, and never touches main. It commits
+the version bump on the release branch for PR review.
+
+After the PR merges, tag-after-merge verifies origin/main is the release commit
+and creates the local version tag. The tag push is a separate confirmed step.
 EOF
 }
 
@@ -159,27 +162,6 @@
   git -C "$checkout" diff --cached --quiet || die "$label has staged changes"
   [[ -z "$(git -C "$checkout" ls-files --others --exclude-standard)" ]] \
     || die "$label has untracked files"
-}
-
-check_ff_possible() {
-  local main_checkout="$1"
-  local release_branch="$2"
-
-  git -C "$main_checkout" rev-parse --verify --quiet "$release_branch" >/dev/null \
-    || die "missing release branch: $release_branch"
-  git -C "$main_checkout" merge-base --is-ancestor main "$release_branch" \
-    || die "main cannot fast-forward to $release_branch"
-}
-
-human_pr_review_mode() {
-  local mode
-
-  mode=$(awk '/^review:/{f=1;next} f&&/human_pr_review:/{print $2; exit}' config.yaml)
-  mode=${mode:-self}
-  case "$mode" in
-    self|platform-team) printf '%s\n' "$mode" ;;
-    *) die "invalid review.human_pr_review '$mode' (expected self or platform-team)" ;;
-  esac
 }
 
 check_origin_main_ancestor() {
@@ -195,13 +177,11 @@
 rollback_release() {
   local status=$?
   local pre_release_head="$1"
-  local new_version="$2"
 
   trap - ERR
   set +e
-  git tag -d "v$new_version" >/dev/null 2>&1
   git reset --hard "$pre_release_head" >/dev/null 2>&1
-  echo "release: irreversible step failed; release commit and tag changes were rolled back" >&2
+  echo "release: irreversible step failed; release commit was rolled back" >&2
   exit "$status"
 }
 
@@ -210,15 +190,13 @@
   local confirm_delta="$2"
   local plan_path="work/$slug/plan.md"
   local release_branch="wt/$slug"
-  local main_checkout
   local release_checkout
   local current_version
   local new_version
   local release_note
   local pre_release_head
-  local review_mode
 
-  main_checkout=$(worktree_for_branch main) \
+  worktree_for_branch main >/dev/null \
     || die "main must be checked out in the primary worktree"
   release_checkout=$(worktree_for_branch "$release_branch") \
     || die "$release_branch must be checked out in a linked worktree"
@@ -229,64 +207,75 @@
   cd "$release_checkout"
   current_version=$(<VERSION)
   new_version=$(next_version "$current_version")
-  review_mode=$(human_pr_review_mode)
 
   check_verdict "$plan_path"
   check_clean_worktree "$release_checkout" "$release_branch"
-  check_clean_worktree "$main_checkout" "main checkout"
-  if [[ "$review_mode" == self ]]; then
-    check_ff_possible "$main_checkout" "$release_branch"
-    git rev-parse --verify --quiet "refs/tags/v$new_version" >/dev/null \
-      && die "tag v$new_version already exists"
-  else
-    check_origin_main_ancestor "$release_branch"
-  fi
+  check_origin_main_ancestor "$release_branch"
   check_gate
   check_clean_worktree "$release_checkout" "$release_branch"
   check_archi_fresh
   check_version_exceeds "$new_version" "$current_version"
-  check_clean_worktree "$main_checkout" "main checkout"
-  if [[ "$review_mode" == self ]]; then
-    check_ff_possible "$main_checkout" "$release_branch"
-  else
-    check_origin_main_ancestor "$release_branch"
-  fi
+  check_origin_main_ancestor "$release_branch"
 
   release_note=$(extract_release_note "$plan_path")
   pre_release_head=$(git rev-parse HEAD)
-  trap 'rollback_release "$pre_release_head" "$new_version"' ERR
+  trap 'rollback_release "$pre_release_head"' ERR
 
   printf '%s\n' "$new_version" >VERSION
   prepend_changelog "$new_version" "$release_note" "$confirm_delta"
 
   git add VERSION CHANGELOG.md
   git commit -m "Release v$new_version"
-  if [[ "$review_mode" == self ]]; then
-    git tag "v$new_version"
-    git -C "$main_checkout" merge --ff-only "$release_branch"
-  fi
   trap - ERR
 
-  if [[ "$review_mode" == self ]]; then
-    cat <<EOF
-release: prepared v$new_version on local main
-release: stopped before push; push requires Owner confirmation in-session
-EOF
-  else
-    cat <<EOF
+  cat <<EOF
 release: prepared v$new_version on $release_branch
 release: no tag created; local main untouched
-release: push $release_branch, open a Bitbucket PR, and have a platform engineer merge it
+release: push $release_branch, open a PR, and merge it after review
 EOF
-  fi
 }
 
+tag_after_merge() {
+  local slug="$1"
+  local release_branch="wt/$slug"
+  local release_checkout
+  local version
+  local origin_version
+  local origin_subject
+
+  release_checkout=$(worktree_for_branch "$release_branch") \
+    || die "$release_branch must be checked out in a linked worktree"
+  [[ -f "$release_checkout/VERSION" ]] || die "missing VERSION in $release_branch"
+
+  git fetch origin main
+  git rev-parse --verify --quiet origin/main >/dev/null \
+    || die "missing origin/main after fetch"
+
+  version=$(<"$release_checkout/VERSION")
+  origin_version=$(git show origin/main:VERSION) \
+    || die "origin/main does not contain VERSION"
+  origin_subject=$(git log -1 --format=%s origin/main)
+
+  [[ "$origin_version" == "$version" && "$origin_subject" == "Release v$version" ]] \
+    || die "origin/main is not Release v$version (VERSION is $origin_version; subject is '$origin_subject')"
+
+  git rev-parse --verify --quiet "refs/tags/v$version" >/dev/null \
+    && die "tag v$version already exists"
+
+  git tag "v$version" origin/main
+  printf 'release: created local tag v%s on origin/main\n' "$version"
+}
+
 if [[ $# -eq 0 ]]; then
   usage
   exit 2
 fi
 
 case "$1" in
+  tag-after-merge)
+    [[ $# -eq 2 ]] || { usage; exit 2; }
+    tag_after_merge "$2"
+    ;;
   check-version)
     [[ $# -eq 2 || $# -eq 3 ]] || { usage; exit 2; }
     current=${3:-$(<VERSION)}
diff --git a/tests/test-scripts.sh b/tests/test-scripts.sh
index 77e929164770e68220eefdedb0591fc9e25e1f0b..473311694d7e6564bdac487d41e2a595aa54d116
--- a/tests/test-scripts.sh
+++ b/tests/test-scripts.sh
@@ -58,7 +58,6 @@
   local verdict_line="$3"
   local gate_mode="$4"
   local archi_mode="$5"
-  local review_mode="${6:-self}"
   local tmp_root="$TMP/$name"
 
   REL_PRIMARY="$tmp_root/primary"
@@ -93,11 +92,7 @@
 echo "GATE: PASS"
 EOF
     chmod +x scripts/release.sh scripts/gate.sh
-    {
-      printf 'name: fixture\n'
-      printf 'review:\n'
-      printf '  human_pr_review: %s\n' "$review_mode"
-    } >config.yaml
+    printf 'name: fixture\n' >config.yaml
     printf 'merge rules\n' >CLAUDE.md
     printf '%s\n' "$version" >VERSION
     printf '# Changelog\n\nAll notable changes to this project are documented in this file.\n\n' >CHANGELOG.md
@@ -173,52 +168,21 @@
 setup_release_fixture release-version-regresses 2026.9.0 "Code-review verdict: APPROVE" pass fresh
 check_fails "release refuses when computed version does not exceed VERSION" bash -c "cd '$REL_WORKTREE' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo"
 
-setup_release_fixture release-happy 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-origin_before=$(git -C "$REL_PRIMARY" rev-parse origin/main)
-check "release happy path lands fast-forward on primary main and stops before push" bash -c "
-  cd '$REL_WORKTREE' &&
+setup_release_fixture release-happy-primary 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+main_before=$(git -C "$REL_PRIMARY" rev-parse main)
+check "release can be invoked from primary checkout" bash -c "
+  cd '$REL_PRIMARY' &&
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
-  [ \"\$(git -C '$REL_PRIMARY' branch --show-current)\" = main ] &&
-  [ \"\$(cat '$REL_PRIMARY/VERSION')\" = 2026.8.10 ] &&
-  git -C '$REL_PRIMARY' merge-base --is-ancestor wt/demo main &&
-  git -C '$REL_PRIMARY' rev-parse --verify --quiet refs/tags/v2026.8.10 &&
-  [ \"\$(git -C '$REL_PRIMARY' rev-parse origin/main)\" = '$origin_before' ]
-"
-
-setup_release_fixture release-tag-race-rolls-back 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-release_head_before=$(git -C "$REL_WORKTREE" rev-parse HEAD)
-real_git=$(command -v git)
-tag_fail_bin="$TMP/tag-fail-bin"
-mkdir -p "$tag_fail_bin"
-cat >"$tag_fail_bin/git" <<EOF
-#!/usr/bin/env bash
-if [[ "\$1" == tag && "\${2:-}" == v2026.8.10 ]]; then
-  "$real_git" tag v2026.8.10 HEAD~1
-fi
-"$real_git" "\$@"
-EOF
-chmod +x "$tag_fail_bin/git"
-check "release rolls back cleanly when tag creation fails after prechecks" bash -c "
-  cd '$REL_WORKTREE' &&
-  PATH='$tag_fail_bin:$REL_FAKEBIN':\$PATH bash scripts/release.sh demo >/dev/null 2>&1 &&
-  exit 1
-  status=\$?
-  [ \"\$status\" -ne 0 ] &&
-  [ \"\$(git rev-parse HEAD)\" = '$release_head_before' ] &&
-  [ \"\$(cat VERSION)\" = 2026.8.9 ] &&
-  git diff --quiet &&
-  git diff --cached --quiet &&
-  [ -z \"\$(git ls-files --others --exclude-standard)\" ] &&
-  ! git rev-parse --verify --quiet refs/tags/v2026.8.10
+  [ \"\$(git -C '$REL_PRIMARY' rev-parse main)\" = '$main_before' ] &&
+  [ \"\$(cat '$REL_PRIMARY/VERSION')\" = 2026.8.9 ] &&
+  [ \"\$(cat '$REL_WORKTREE/VERSION')\" = 2026.8.10 ] &&
+  ! git -C '$REL_WORKTREE' rev-parse --verify --quiet refs/tags/v2026.8.10
 "
-
-setup_release_fixture release-happy-primary 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-check "release can be invoked from primary checkout" bash -c "cd '$REL_PRIMARY' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo && [ \"\$(cat VERSION)\" = 2026.8.10 ]"
 
-setup_release_fixture release-platform-single 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
+setup_release_fixture release-single 2026.8.9 "Code-review verdict: APPROVE" pass fresh
 origin_before=$(git -C "$REL_PRIMARY" rev-parse origin/main)
 main_before=$(git -C "$REL_PRIMARY" rev-parse main)
-check "platform-team release commits bump on branch without touching main or tagging" bash -c "
+check "release commits bump on branch without touching main, origin/main, or tagging" bash -c "
   cd '$REL_WORKTREE' &&
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
   [ \"\$(git -C '$REL_PRIMARY' rev-parse main)\" = '$main_before' ] &&
@@ -228,13 +192,13 @@
   ! git rev-parse --verify --quiet refs/tags/v2026.8.10
 "
 
-setup_release_fixture release-platform-sequential 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
-check "platform-team release refuses stale branch, then computes next micro after sync" bash -c "
+setup_release_fixture release-sequential 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+check "release refuses stale branch, then computes next micro after sync" bash -c "
   set -e
   cd '$REL_WORKTREE'
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo
   git push -q origin wt/demo:main
-  rel_b='$TMP/release-platform-sequential/b-wt'
+  rel_b='$TMP/release-sequential/b-wt'
   git -C '$REL_PRIMARY' branch wt/b main
   git -C '$REL_PRIMARY' worktree add -q \"\$rel_b\" wt/b
   git -C \"\$rel_b\" config user.email tester@example.com
@@ -243,7 +207,7 @@
   sed 's/# Demo/# B/' '$REL_WORKTREE/work/demo/plan.md' > \"\$rel_b/work/b/plan.md\"
   git -C \"\$rel_b\" add work/b/plan.md
   GIT_AUTHOR_DATE='2026-08-16T10:00:30Z' GIT_COMMITTER_DATE='2026-08-16T10:00:30Z' git -C \"\$rel_b\" commit -qm 'add b plan'
-  stale_out='$TMP/platform-stale.out'
+  stale_out='$TMP/release-stale.out'
   if PATH='$REL_FAKEBIN':\$PATH bash \"\$rel_b/scripts/release.sh\" b >\"\$stale_out\" 2>&1; then
     exit 1
   fi
@@ -257,15 +221,15 @@
   ! git rev-parse --verify --quiet refs/tags/v2026.8.11
 "
 
-setup_release_fixture release-platform-mid-gate 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
+setup_release_fixture release-mid-gate 2026.8.9 "Code-review verdict: APPROVE" pass fresh
 mkdir -p "$REL_WORKTREE/scripts/gate.d"
 cat >"$REL_WORKTREE/scripts/gate.d/move-origin-main.sh" <<EOF
 #!/usr/bin/env bash
 set -euo pipefail
 repo='$REL_PRIMARY'
-printf 'platform merge during gate\n' >> "\$repo/platform.txt"
-git -C "\$repo" add platform.txt
-GIT_AUTHOR_DATE='2026-08-16T10:02:00Z' GIT_COMMITTER_DATE='2026-08-16T10:02:00Z' git -C "\$repo" commit -qm 'platform merge during gate'
+printf 'merge during gate\n' >> "\$repo/remote-change.txt"
+git -C "\$repo" add remote-change.txt
+GIT_AUTHOR_DATE='2026-08-16T10:02:00Z' GIT_COMMITTER_DATE='2026-08-16T10:02:00Z' git -C "\$repo" commit -qm 'merge during gate'
 git -C "\$repo" push -q origin main
 EOF
 chmod +x "$REL_WORKTREE/scripts/gate.d/move-origin-main.sh"
@@ -274,15 +238,58 @@
   git add scripts/gate.d/move-origin-main.sh
   GIT_AUTHOR_DATE="2026-08-16T10:00:30Z" GIT_COMMITTER_DATE="2026-08-16T10:00:30Z" git commit -qm "add mid-gate hook"
 )
-check "platform-team release catches origin/main moving during gate" bash -c "
+check "release catches origin/main moving during gate" bash -c "
   cd '$REL_WORKTREE'
-  mid_gate_out='$TMP/platform-mid-gate.out'
+  mid_gate_out='$TMP/release-mid-gate.out'
   if PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo >\"\$mid_gate_out\" 2>&1; then
     exit 1
   fi
   grep -q 'rebase/sync your branch onto origin/main' \"\$mid_gate_out\"
 "
 
+setup_release_fixture release-tag-after-merge-happy 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+real_git=$(command -v git)
+push_log="$TMP/tag-after-merge-push.log"
+tag_guard_bin="$TMP/tag-after-merge-bin"
+mkdir -p "$tag_guard_bin"
+cat >"$tag_guard_bin/git" <<EOF
+#!/usr/bin/env bash
+if [[ "\$1" == push ]]; then
+  printf 'unexpected push\n' >> "$push_log"
+  exit 99
+fi
+"$real_git" "\$@"
+EOF
+chmod +x "$tag_guard_bin/git"
+check "tag-after-merge creates local tag on origin/main and pushes nothing" bash -c "
+  cd '$REL_WORKTREE' &&
+  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
+  git push -q origin wt/demo:main &&
+  PATH='$tag_guard_bin:$REL_FAKEBIN':\$PATH bash scripts/release.sh tag-after-merge demo &&
+  [ \"\$(git rev-parse refs/tags/v2026.8.10)\" = \"\$(git rev-parse origin/main)\" ] &&
+  [ ! -s '$push_log' ]
+"
+
+setup_release_fixture release-tag-after-merge-wrong-commit 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+check "tag-after-merge refuses when origin/main advanced past the release" bash -c "
+  set -e
+  cd '$REL_WORKTREE'
+  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo
+  git push -q origin wt/demo:main
+  git -C '$REL_PRIMARY' fetch -q origin main
+  git -C '$REL_PRIMARY' reset -q --hard origin/main
+  printf 'next change\n' > '$REL_PRIMARY/after-release.txt'
+  git -C '$REL_PRIMARY' add after-release.txt
+  GIT_AUTHOR_DATE='2026-08-16T10:03:00Z' GIT_COMMITTER_DATE='2026-08-16T10:03:00Z' git -C '$REL_PRIMARY' commit -qm 'Next change'
+  git -C '$REL_PRIMARY' push -q origin main
+  wrong_out='$TMP/tag-after-merge-wrong.out'
+  if PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh tag-after-merge demo >\"\$wrong_out\" 2>&1; then
+    exit 1
+  fi
+  grep -q 'origin/main is not Release v2026.8.10' \"\$wrong_out\" &&
+  ! git rev-parse --verify --quiet refs/tags/v2026.8.10
+"
+
 # --- gate.sh runs and exits cleanly on this repo
 check "gate.sh runs on this repo" bash scripts/gate.sh
 

codex
One status detail needs care: Git reports the release skill under `skills/4-release/SKILL.md`, while the path I edited was `.claude/skills/4-release/SKILL.md`. I’m checking whether that’s a symlinked path representation before staging, so I don’t accidentally step outside the declared footprint.
exec
/bin/zsh -lc 'ls -ld .claude .claude/skills .claude/skills/4-release .claude/skills/4-release/SKILL.md skills skills/4-release skills/4-release/SKILL.md' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
 succeeded in 0ms:
drwxr-xr-x  4 cboyfly  staff   128 Aug 25 07:29 .claude
lrwxr-xr-x  1 cboyfly  staff     9 Aug 25 07:29 .claude/skills -> ../skills
drwxr-xr-x  3 cboyfly  staff    96 Aug 25 07:29 .claude/skills/4-release
-rw-r--r--  1 cboyfly  staff  1186 Aug 25 07:31 .claude/skills/4-release/SKILL.md
drwxr-xr-x  8 cboyfly  staff   256 Aug 25 07:29 skills
drwxr-xr-x  3 cboyfly  staff    96 Aug 25 07:29 skills/4-release
-rw-r--r--  1 cboyfly  staff  1186 Aug 25 07:31 skills/4-release/SKILL.md

exec
/bin/zsh -lc 'git ls-files .claude/skills/4-release/SKILL.md skills/4-release/SKILL.md work/pr-merge-topology/plan.md' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
 succeeded in 0ms:
skills/4-release/SKILL.md

exec
/bin/zsh -lc 'git diff --name-only' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
 succeeded in 0ms:
CLAUDE.md
config.yaml
profiles/work.md
scripts/release.sh
skills/4-release/SKILL.md
tests/test-scripts.sh

diff --git a/.claude/skills/4-release/SKILL.md b/.claude/skills/4-release/SKILL.md
index 923d42b3ecf0574b4e04bc3d1d7d6b9fb9d647fe..e292a1fec26467e14eeab6dd25f32644bd12717f
--- a/.claude/skills/4-release/SKILL.md
+++ b/.claude/skills/4-release/SKILL.md
@@ -11,13 +11,11 @@
 
 1. **Confirm intent:** ask the Owner for the in-session release confirmation and capture the `Confirm-delta:` value.
 2. **Run the release script:** from the repo root, run `bash scripts/release.sh <slug> --confirm-delta "<value>"`.
-3. **React to the exit code based on `review.human_pr_review`:**
-   - Exit 0 with `self` → report the prepared version, tag, and local `main` state.
-   - Exit 0 with `platform-team` → report the bump commit on the release branch, that no tag was created, and that local `main` was untouched.
+3. **React to the exit code:**
+   - Exit 0 → report the bump commit on the release branch, that no tag exists yet, and that `main` was untouched.
    - Non-zero → report the script output and stop.
-4. **Push separately based on `review.human_pr_review`:**
-   - `self` → after the Owner confirms the push, push `main` and the new tag.
-   - `platform-team` → after the Owner confirms the push, push the release branch, print instructions to open a Bitbucket PR, and never push `main`.
+4. **Push the release branch:** after the Owner confirms the push, push the release branch, print instructions to open a PR and get it merged, and never push `main`.
+5. **Tag after merge:** once the Owner confirms the PR has merged, run `bash scripts/release.sh tag-after-merge <slug>`. If it exits non-zero, report the output and stop. If it succeeds, ask the Owner to confirm pushing the new tag, then run `git push origin v<version>`.
 
 ## Rules
 
diff --git a/CLAUDE.md b/CLAUDE.md
index bf72a9b97511c2563b248078c46726b47a5c62a8..6ec3b7c56d404abd1d28a52eb982227c2e51b4ea
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -23,7 +23,7 @@
 2. **The gate is a script.** `scripts/gate.sh` exits 0 or it doesn't. You do not overrule it, reinterpret it, or declare work done while it fails.
 3. **Implementation happens in worktrees**, never in this checkout. `scripts/worktree.sh` manages them.
 4. **Artifacts flow between stages, not transcripts.** The reviewer gets the diff + plan, never the implementation conversation.
-5. **Release is a script.** `scripts/release.sh` owns release preconditions, versioning, changelog assembly, the release commit, tag, and local fast-forward merge. It never pushes.
+5. **Release is a script.** `scripts/release.sh` owns release preconditions, versioning, changelog assembly, and the release commit on the branch. It never pushes and never touches `main`; tagging happens in `/4-release` after the PR merges via `tag-after-merge`.
 
 ## Context tiers
 
diff --git a/config.yaml b/config.yaml
index 906edc83166366a7556ac002dd81216301f98e3a..0c6fe53d7df35ed60c70d2a88dea2a1da99ab640
--- a/config.yaml
+++ b/config.yaml
@@ -14,9 +14,6 @@
   # Claude Code implementer alternative:
   # command: 'claude -p --dangerously-skip-permissions'
 
-review:
-  human_pr_review: self      # self | platform-team
-
 gate:
   command: scripts/gate.sh
   max_retries: 2             # failed-gate feedback loops before escalating to the Owner
diff --git a/profiles/work.md b/profiles/work.md
index 047b6efdfa81e3d8ed0e0fa246144863ee6762b4..4496e556b94f00ebe837b804420788283ba70e90
--- a/profiles/work.md
+++ b/profiles/work.md
@@ -4,7 +4,6 @@
 
 ## Declarations required at /init
 
-- **Review topology** — set `review.human_pr_review` to `self` or `platform-team`.
 - **Implementer runtime** — when the workplace uses Claude Code for implementation, set `implementer.runtime: claude` and use:
 
 ```yaml
@@ -16,8 +15,7 @@
 ## Adds to the loop
 
 - **Jira:** Jira keys may be recorded as read-only references in `work/<slug>/plan.md`. The loop never creates or mutates Jira issues.
-- **Self review topology:** `scripts/release.sh` keeps the base release shape: it bumps `VERSION` and `CHANGELOG.md`, creates `vX.Y.Z`, fast-forwards local `main`, and stops before push. `/4-release` pushes `main` and the tag only after Owner confirmation.
-- **Platform-team review topology:** `scripts/release.sh` fetches `origin/main`, refuses when the release branch does not contain it, bumps `VERSION` and `CHANGELOG.md` on the release branch, creates no tag, and leaves local `main` untouched. `/4-release` pushes the release branch and prints the Bitbucket PR instruction; a platform engineer merges the PR.
+- **Release:** use the base PR-merge release flow.
 
 ## Gate
 
@@ -26,15 +24,3 @@
 - Add `bitbucket-pipelines.yml`.
 - Delete `.github/workflows/ci.yml`.
 - Keep the deterministic commands equivalent: install `shellcheck`, set a git identity, run `bash tests/test-scripts.sh`, then run `bash scripts/gate.sh`.
-
-## Platform-team release sync
-
-The platform-team release path treats remote `origin/main` as the current source of truth. `scripts/release.sh` fetches it before and after the gate, then refuses with a rebase/sync message if the release branch is stale.
-
-Keep the local `main` worktree pulled from the PR-merged remote before cutting new work. The required `main` worktree check only proves the linked worktree exists; it does not prove local `main` is current, because the release guard checks `origin/main`.
-
-Tagging is permanently manual in platform-team mode. If a tag is wanted after the Bitbucket PR merges, run:
-
-```sh
-git tag vX.Y.Z <merge-commit> && git push origin vX.Y.Z
-```
diff --git a/scripts/release.sh b/scripts/release.sh
index ce19d803956becc2b39b89e57262cb47e44dd359..4e421de6d2c68f9095c6e73232b7e5e4c1e01670
--- a/scripts/release.sh
+++ b/scripts/release.sh
@@ -8,12 +8,15 @@
   cat <<'EOF'
 Usage:
   scripts/release.sh <slug> [--confirm-delta <text>]
+  scripts/release.sh tag-after-merge <slug>
   scripts/release.sh check-version <new-version> [current-version]
   scripts/release.sh next-version [current-version]
 
-The full release path never pushes. In self-review mode it commits, tags,
-fast-forward merges to local main, then stops for the Owner-confirmed push step.
-In platform-team mode it commits the bump on the release branch for PR review.
+The release path never pushes, never tags, and never touches main. It commits
+the version bump on the release branch for PR review.
+
+After the PR merges, tag-after-merge verifies origin/main is the release commit
+and creates the local version tag. The tag push is a separate confirmed step.
 EOF
 }
 
@@ -159,27 +162,6 @@
   git -C "$checkout" diff --cached --quiet || die "$label has staged changes"
   [[ -z "$(git -C "$checkout" ls-files --others --exclude-standard)" ]] \
     || die "$label has untracked files"
-}
-
-check_ff_possible() {
-  local main_checkout="$1"
-  local release_branch="$2"
-
-  git -C "$main_checkout" rev-parse --verify --quiet "$release_branch" >/dev/null \
-    || die "missing release branch: $release_branch"
-  git -C "$main_checkout" merge-base --is-ancestor main "$release_branch" \
-    || die "main cannot fast-forward to $release_branch"
-}
-
-human_pr_review_mode() {
-  local mode
-
-  mode=$(awk '/^review:/{f=1;next} f&&/human_pr_review:/{print $2; exit}' config.yaml)
-  mode=${mode:-self}
-  case "$mode" in
-    self|platform-team) printf '%s\n' "$mode" ;;
-    *) die "invalid review.human_pr_review '$mode' (expected self or platform-team)" ;;
-  esac
 }
 
 check_origin_main_ancestor() {
@@ -195,13 +177,11 @@
 rollback_release() {
   local status=$?
   local pre_release_head="$1"
-  local new_version="$2"
 
   trap - ERR
   set +e
-  git tag -d "v$new_version" >/dev/null 2>&1
   git reset --hard "$pre_release_head" >/dev/null 2>&1
-  echo "release: irreversible step failed; release commit and tag changes were rolled back" >&2
+  echo "release: irreversible step failed; release commit was rolled back" >&2
   exit "$status"
 }
 
@@ -210,15 +190,13 @@
   local confirm_delta="$2"
   local plan_path="work/$slug/plan.md"
   local release_branch="wt/$slug"
-  local main_checkout
   local release_checkout
   local current_version
   local new_version
   local release_note
   local pre_release_head
-  local review_mode
 
-  main_checkout=$(worktree_for_branch main) \
+  worktree_for_branch main >/dev/null \
     || die "main must be checked out in the primary worktree"
   release_checkout=$(worktree_for_branch "$release_branch") \
     || die "$release_branch must be checked out in a linked worktree"
@@ -229,64 +207,75 @@
   cd "$release_checkout"
   current_version=$(<VERSION)
   new_version=$(next_version "$current_version")
-  review_mode=$(human_pr_review_mode)
 
   check_verdict "$plan_path"
   check_clean_worktree "$release_checkout" "$release_branch"
-  check_clean_worktree "$main_checkout" "main checkout"
-  if [[ "$review_mode" == self ]]; then
-    check_ff_possible "$main_checkout" "$release_branch"
-    git rev-parse --verify --quiet "refs/tags/v$new_version" >/dev/null \
-      && die "tag v$new_version already exists"
-  else
-    check_origin_main_ancestor "$release_branch"
-  fi
+  check_origin_main_ancestor "$release_branch"
   check_gate
   check_clean_worktree "$release_checkout" "$release_branch"
   check_archi_fresh
   check_version_exceeds "$new_version" "$current_version"
-  check_clean_worktree "$main_checkout" "main checkout"
-  if [[ "$review_mode" == self ]]; then
-    check_ff_possible "$main_checkout" "$release_branch"
-  else
-    check_origin_main_ancestor "$release_branch"
-  fi
+  check_origin_main_ancestor "$release_branch"
 
   release_note=$(extract_release_note "$plan_path")
   pre_release_head=$(git rev-parse HEAD)
-  trap 'rollback_release "$pre_release_head" "$new_version"' ERR
+  trap 'rollback_release "$pre_release_head"' ERR
 
   printf '%s\n' "$new_version" >VERSION
   prepend_changelog "$new_version" "$release_note" "$confirm_delta"
 
   git add VERSION CHANGELOG.md
   git commit -m "Release v$new_version"
-  if [[ "$review_mode" == self ]]; then
-    git tag "v$new_version"
-    git -C "$main_checkout" merge --ff-only "$release_branch"
-  fi
   trap - ERR
 
-  if [[ "$review_mode" == self ]]; then
-    cat <<EOF
-release: prepared v$new_version on local main
-release: stopped before push; push requires Owner confirmation in-session
-EOF
-  else
-    cat <<EOF
+  cat <<EOF
 release: prepared v$new_version on $release_branch
 release: no tag created; local main untouched
-release: push $release_branch, open a Bitbucket PR, and have a platform engineer merge it
+release: push $release_branch, open a PR, and merge it after review
 EOF
-  fi
 }
 
+tag_after_merge() {
+  local slug="$1"
+  local release_branch="wt/$slug"
+  local release_checkout
+  local version
+  local origin_version
+  local origin_subject
+
+  release_checkout=$(worktree_for_branch "$release_branch") \
+    || die "$release_branch must be checked out in a linked worktree"
+  [[ -f "$release_checkout/VERSION" ]] || die "missing VERSION in $release_branch"
+
+  git fetch origin main
+  git rev-parse --verify --quiet origin/main >/dev/null \
+    || die "missing origin/main after fetch"
+
+  version=$(<"$release_checkout/VERSION")
+  origin_version=$(git show origin/main:VERSION) \
+    || die "origin/main does not contain VERSION"
+  origin_subject=$(git log -1 --format=%s origin/main)
+
+  [[ "$origin_version" == "$version" && "$origin_subject" == "Release v$version" ]] \
+    || die "origin/main is not Release v$version (VERSION is $origin_version; subject is '$origin_subject')"
+
+  git rev-parse --verify --quiet "refs/tags/v$version" >/dev/null \
+    && die "tag v$version already exists"
+
+  git tag "v$version" origin/main
+  printf 'release: created local tag v%s on origin/main\n' "$version"
+}
+
 if [[ $# -eq 0 ]]; then
   usage
   exit 2
 fi
 
 case "$1" in
+  tag-after-merge)
+    [[ $# -eq 2 ]] || { usage; exit 2; }
+    tag_after_merge "$2"
+    ;;
   check-version)
     [[ $# -eq 2 || $# -eq 3 ]] || { usage; exit 2; }
     current=${3:-$(<VERSION)}
diff --git a/tests/test-scripts.sh b/tests/test-scripts.sh
index 77e929164770e68220eefdedb0591fc9e25e1f0b..473311694d7e6564bdac487d41e2a595aa54d116
--- a/tests/test-scripts.sh
+++ b/tests/test-scripts.sh
@@ -58,7 +58,6 @@
   local verdict_line="$3"
   local gate_mode="$4"
   local archi_mode="$5"
-  local review_mode="${6:-self}"
   local tmp_root="$TMP/$name"
 
   REL_PRIMARY="$tmp_root/primary"
@@ -93,11 +92,7 @@
 echo "GATE: PASS"
 EOF
     chmod +x scripts/release.sh scripts/gate.sh
-    {
-      printf 'name: fixture\n'
-      printf 'review:\n'
-      printf '  human_pr_review: %s\n' "$review_mode"
-    } >config.yaml
+    printf 'name: fixture\n' >config.yaml
     printf 'merge rules\n' >CLAUDE.md
     printf '%s\n' "$version" >VERSION
     printf '# Changelog\n\nAll notable changes to this project are documented in this file.\n\n' >CHANGELOG.md
@@ -173,52 +168,21 @@
 setup_release_fixture release-version-regresses 2026.9.0 "Code-review verdict: APPROVE" pass fresh
 check_fails "release refuses when computed version does not exceed VERSION" bash -c "cd '$REL_WORKTREE' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo"
 
-setup_release_fixture release-happy 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-origin_before=$(git -C "$REL_PRIMARY" rev-parse origin/main)
-check "release happy path lands fast-forward on primary main and stops before push" bash -c "
-  cd '$REL_WORKTREE' &&
+setup_release_fixture release-happy-primary 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+main_before=$(git -C "$REL_PRIMARY" rev-parse main)
+check "release can be invoked from primary checkout" bash -c "
+  cd '$REL_PRIMARY' &&
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
-  [ \"\$(git -C '$REL_PRIMARY' branch --show-current)\" = main ] &&
-  [ \"\$(cat '$REL_PRIMARY/VERSION')\" = 2026.8.10 ] &&
-  git -C '$REL_PRIMARY' merge-base --is-ancestor wt/demo main &&
-  git -C '$REL_PRIMARY' rev-parse --verify --quiet refs/tags/v2026.8.10 &&
-  [ \"\$(git -C '$REL_PRIMARY' rev-parse origin/main)\" = '$origin_before' ]
-"
-
-setup_release_fixture release-tag-race-rolls-back 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-release_head_before=$(git -C "$REL_WORKTREE" rev-parse HEAD)
-real_git=$(command -v git)
-tag_fail_bin="$TMP/tag-fail-bin"
-mkdir -p "$tag_fail_bin"
-cat >"$tag_fail_bin/git" <<EOF
-#!/usr/bin/env bash
-if [[ "\$1" == tag && "\${2:-}" == v2026.8.10 ]]; then
-  "$real_git" tag v2026.8.10 HEAD~1
-fi
-"$real_git" "\$@"
-EOF
-chmod +x "$tag_fail_bin/git"
-check "release rolls back cleanly when tag creation fails after prechecks" bash -c "
-  cd '$REL_WORKTREE' &&
-  PATH='$tag_fail_bin:$REL_FAKEBIN':\$PATH bash scripts/release.sh demo >/dev/null 2>&1 &&
-  exit 1
-  status=\$?
-  [ \"\$status\" -ne 0 ] &&
-  [ \"\$(git rev-parse HEAD)\" = '$release_head_before' ] &&
-  [ \"\$(cat VERSION)\" = 2026.8.9 ] &&
-  git diff --quiet &&
-  git diff --cached --quiet &&
-  [ -z \"\$(git ls-files --others --exclude-standard)\" ] &&
-  ! git rev-parse --verify --quiet refs/tags/v2026.8.10
+  [ \"\$(git -C '$REL_PRIMARY' rev-parse main)\" = '$main_before' ] &&
+  [ \"\$(cat '$REL_PRIMARY/VERSION')\" = 2026.8.9 ] &&
+  [ \"\$(cat '$REL_WORKTREE/VERSION')\" = 2026.8.10 ] &&
+  ! git -C '$REL_WORKTREE' rev-parse --verify --quiet refs/tags/v2026.8.10
 "
-
-setup_release_fixture release-happy-primary 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-check "release can be invoked from primary checkout" bash -c "cd '$REL_PRIMARY' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo && [ \"\$(cat VERSION)\" = 2026.8.10 ]"
 
-setup_release_fixture release-platform-single 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
+setup_release_fixture release-single 2026.8.9 "Code-review verdict: APPROVE" pass fresh
 origin_before=$(git -C "$REL_PRIMARY" rev-parse origin/main)
 main_before=$(git -C "$REL_PRIMARY" rev-parse main)
-check "platform-team release commits bump on branch without touching main or tagging" bash -c "
+check "release commits bump on branch without touching main, origin/main, or tagging" bash -c "
   cd '$REL_WORKTREE' &&
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
   [ \"\$(git -C '$REL_PRIMARY' rev-parse main)\" = '$main_before' ] &&
@@ -228,13 +192,13 @@
   ! git rev-parse --verify --quiet refs/tags/v2026.8.10
 "
 
-setup_release_fixture release-platform-sequential 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
-check "platform-team release refuses stale branch, then computes next micro after sync" bash -c "
+setup_release_fixture release-sequential 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+check "release refuses stale branch, then computes next micro after sync" bash -c "
   set -e
   cd '$REL_WORKTREE'
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo
   git push -q origin wt/demo:main
-  rel_b='$TMP/release-platform-sequential/b-wt'
+  rel_b='$TMP/release-sequential/b-wt'
   git -C '$REL_PRIMARY' branch wt/b main
   git -C '$REL_PRIMARY' worktree add -q \"\$rel_b\" wt/b
   git -C \"\$rel_b\" config user.email tester@example.com
@@ -243,7 +207,7 @@
   sed 's/# Demo/# B/' '$REL_WORKTREE/work/demo/plan.md' > \"\$rel_b/work/b/plan.md\"
   git -C \"\$rel_b\" add work/b/plan.md
   GIT_AUTHOR_DATE='2026-08-16T10:00:30Z' GIT_COMMITTER_DATE='2026-08-16T10:00:30Z' git -C \"\$rel_b\" commit -qm 'add b plan'
-  stale_out='$TMP/platform-stale.out'
+  stale_out='$TMP/release-stale.out'
   if PATH='$REL_FAKEBIN':\$PATH bash \"\$rel_b/scripts/release.sh\" b >\"\$stale_out\" 2>&1; then
     exit 1
   fi
@@ -257,15 +221,15 @@
   ! git rev-parse --verify --quiet refs/tags/v2026.8.11
 "
 
-setup_release_fixture release-platform-mid-gate 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
+setup_release_fixture release-mid-gate 2026.8.9 "Code-review verdict: APPROVE" pass fresh
 mkdir -p "$REL_WORKTREE/scripts/gate.d"
 cat >"$REL_WORKTREE/scripts/gate.d/move-origin-main.sh" <<EOF
 #!/usr/bin/env bash
 set -euo pipefail
 repo='$REL_PRIMARY'
-printf 'platform merge during gate\n' >> "\$repo/platform.txt"
-git -C "\$repo" add platform.txt
-GIT_AUTHOR_DATE='2026-08-16T10:02:00Z' GIT_COMMITTER_DATE='2026-08-16T10:02:00Z' git -C "\$repo" commit -qm 'platform merge during gate'
+printf 'merge during gate\n' >> "\$repo/remote-change.txt"
+git -C "\$repo" add remote-change.txt
+GIT_AUTHOR_DATE='2026-08-16T10:02:00Z' GIT_COMMITTER_DATE='2026-08-16T10:02:00Z' git -C "\$repo" commit -qm 'merge during gate'
 git -C "\$repo" push -q origin main
 EOF
 chmod +x "$REL_WORKTREE/scripts/gate.d/move-origin-main.sh"
@@ -274,15 +238,58 @@
   git add scripts/gate.d/move-origin-main.sh
   GIT_AUTHOR_DATE="2026-08-16T10:00:30Z" GIT_COMMITTER_DATE="2026-08-16T10:00:30Z" git commit -qm "add mid-gate hook"
 )
-check "platform-team release catches origin/main moving during gate" bash -c "
+check "release catches origin/main moving during gate" bash -c "
   cd '$REL_WORKTREE'
-  mid_gate_out='$TMP/platform-mid-gate.out'
+  mid_gate_out='$TMP/release-mid-gate.out'
   if PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo >\"\$mid_gate_out\" 2>&1; then
     exit 1
   fi
   grep -q 'rebase/sync your branch onto origin/main' \"\$mid_gate_out\"
 "
 
+setup_release_fixture release-tag-after-merge-happy 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+real_git=$(command -v git)
+push_log="$TMP/tag-after-merge-push.log"
+tag_guard_bin="$TMP/tag-after-merge-bin"
+mkdir -p "$tag_guard_bin"
+cat >"$tag_guard_bin/git" <<EOF
+#!/usr/bin/env bash
+if [[ "\$1" == push ]]; then
+  printf 'unexpected push\n' >> "$push_log"
+  exit 99
+fi
+"$real_git" "\$@"
+EOF
+chmod +x "$tag_guard_bin/git"
+check "tag-after-merge creates local tag on origin/main and pushes nothing" bash -c "
+  cd '$REL_WORKTREE' &&
+  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
+  git push -q origin wt/demo:main &&
+  PATH='$tag_guard_bin:$REL_FAKEBIN':\$PATH bash scripts/release.sh tag-after-merge demo &&
+  [ \"\$(git rev-parse refs/tags/v2026.8.10)\" = \"\$(git rev-parse origin/main)\" ] &&
+  [ ! -s '$push_log' ]
+"
+
+setup_release_fixture release-tag-after-merge-wrong-commit 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+check "tag-after-merge refuses when origin/main advanced past the release" bash -c "
+  set -e
+  cd '$REL_WORKTREE'
+  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo
+  git push -q origin wt/demo:main
+  git -C '$REL_PRIMARY' fetch -q origin main
+  git -C '$REL_PRIMARY' reset -q --hard origin/main
+  printf 'next change\n' > '$REL_PRIMARY/after-release.txt'
+  git -C '$REL_PRIMARY' add after-release.txt
+  GIT_AUTHOR_DATE='2026-08-16T10:03:00Z' GIT_COMMITTER_DATE='2026-08-16T10:03:00Z' git -C '$REL_PRIMARY' commit -qm 'Next change'
+  git -C '$REL_PRIMARY' push -q origin main
+  wrong_out='$TMP/tag-after-merge-wrong.out'
+  if PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh tag-after-merge demo >\"\$wrong_out\" 2>&1; then
+    exit 1
+  fi
+  grep -q 'origin/main is not Release v2026.8.10' \"\$wrong_out\" &&
+  ! git rev-parse --verify --quiet refs/tags/v2026.8.10
+"
+
 # --- gate.sh runs and exits cleanly on this repo
 check "gate.sh runs on this repo" bash scripts/gate.sh
 

codex
`.claude/skills` is a symlink to the tracked `skills/` directory, so the reported path is the same file. The untracked work-unit directory was present as source material; I’m leaving it unstaged and committing only the scoped implementation files.
exec
/bin/zsh -lc 'git diff --stat -- CLAUDE.md config.yaml profiles/work.md scripts/release.sh skills/4-release/SKILL.md tests/test-scripts.sh' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
 succeeded in 0ms:
 CLAUDE.md                 |   2 +-
 config.yaml               |   3 --
 profiles/work.md          |  16 +-----
 scripts/release.sh        | 107 ++++++++++++++++++----------------------
 skills/4-release/SKILL.md |  10 ++--
 tests/test-scripts.sh     | 121 ++++++++++++++++++++++++----------------------
 6 files changed, 118 insertions(+), 141 deletions(-)

exec
/bin/zsh -lc 'git diff --check' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
 succeeded in 0ms:
diff --git a/.claude/skills/4-release/SKILL.md b/.claude/skills/4-release/SKILL.md
index 923d42b3ecf0574b4e04bc3d1d7d6b9fb9d647fe..e292a1fec26467e14eeab6dd25f32644bd12717f
--- a/.claude/skills/4-release/SKILL.md
+++ b/.claude/skills/4-release/SKILL.md
@@ -11,13 +11,11 @@
 
 1. **Confirm intent:** ask the Owner for the in-session release confirmation and capture the `Confirm-delta:` value.
 2. **Run the release script:** from the repo root, run `bash scripts/release.sh <slug> --confirm-delta "<value>"`.
-3. **React to the exit code based on `review.human_pr_review`:**
-   - Exit 0 with `self` → report the prepared version, tag, and local `main` state.
-   - Exit 0 with `platform-team` → report the bump commit on the release branch, that no tag was created, and that local `main` was untouched.
+3. **React to the exit code:**
+   - Exit 0 → report the bump commit on the release branch, that no tag exists yet, and that `main` was untouched.
    - Non-zero → report the script output and stop.
-4. **Push separately based on `review.human_pr_review`:**
-   - `self` → after the Owner confirms the push, push `main` and the new tag.
-   - `platform-team` → after the Owner confirms the push, push the release branch, print instructions to open a Bitbucket PR, and never push `main`.
+4. **Push the release branch:** after the Owner confirms the push, push the release branch, print instructions to open a PR and get it merged, and never push `main`.
+5. **Tag after merge:** once the Owner confirms the PR has merged, run `bash scripts/release.sh tag-after-merge <slug>`. If it exits non-zero, report the output and stop. If it succeeds, ask the Owner to confirm pushing the new tag, then run `git push origin v<version>`.
 
 ## Rules
 
diff --git a/CLAUDE.md b/CLAUDE.md
index bf72a9b97511c2563b248078c46726b47a5c62a8..6ec3b7c56d404abd1d28a52eb982227c2e51b4ea
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -23,7 +23,7 @@
 2. **The gate is a script.** `scripts/gate.sh` exits 0 or it doesn't. You do not overrule it, reinterpret it, or declare work done while it fails.
 3. **Implementation happens in worktrees**, never in this checkout. `scripts/worktree.sh` manages them.
 4. **Artifacts flow between stages, not transcripts.** The reviewer gets the diff + plan, never the implementation conversation.
-5. **Release is a script.** `scripts/release.sh` owns release preconditions, versioning, changelog assembly, the release commit, tag, and local fast-forward merge. It never pushes.
+5. **Release is a script.** `scripts/release.sh` owns release preconditions, versioning, changelog assembly, and the release commit on the branch. It never pushes and never touches `main`; tagging happens in `/4-release` after the PR merges via `tag-after-merge`.
 
 ## Context tiers
 
diff --git a/config.yaml b/config.yaml
index 906edc83166366a7556ac002dd81216301f98e3a..0c6fe53d7df35ed60c70d2a88dea2a1da99ab640
--- a/config.yaml
+++ b/config.yaml
@@ -14,9 +14,6 @@
   # Claude Code implementer alternative:
   # command: 'claude -p --dangerously-skip-permissions'
 
-review:
-  human_pr_review: self      # self | platform-team
-
 gate:
   command: scripts/gate.sh
   max_retries: 2             # failed-gate feedback loops before escalating to the Owner
diff --git a/profiles/work.md b/profiles/work.md
index 047b6efdfa81e3d8ed0e0fa246144863ee6762b4..4496e556b94f00ebe837b804420788283ba70e90
--- a/profiles/work.md
+++ b/profiles/work.md
@@ -4,7 +4,6 @@
 
 ## Declarations required at /init
 
-- **Review topology** — set `review.human_pr_review` to `self` or `platform-team`.
 - **Implementer runtime** — when the workplace uses Claude Code for implementation, set `implementer.runtime: claude` and use:
 
 ```yaml
@@ -16,8 +15,7 @@
 ## Adds to the loop
 
 - **Jira:** Jira keys may be recorded as read-only references in `work/<slug>/plan.md`. The loop never creates or mutates Jira issues.
-- **Self review topology:** `scripts/release.sh` keeps the base release shape: it bumps `VERSION` and `CHANGELOG.md`, creates `vX.Y.Z`, fast-forwards local `main`, and stops before push. `/4-release` pushes `main` and the tag only after Owner confirmation.
-- **Platform-team review topology:** `scripts/release.sh` fetches `origin/main`, refuses when the release branch does not contain it, bumps `VERSION` and `CHANGELOG.md` on the release branch, creates no tag, and leaves local `main` untouched. `/4-release` pushes the release branch and prints the Bitbucket PR instruction; a platform engineer merges the PR.
+- **Release:** use the base PR-merge release flow.
 
 ## Gate
 
@@ -26,15 +24,3 @@
 - Add `bitbucket-pipelines.yml`.
 - Delete `.github/workflows/ci.yml`.
 - Keep the deterministic commands equivalent: install `shellcheck`, set a git identity, run `bash tests/test-scripts.sh`, then run `bash scripts/gate.sh`.
-
-## Platform-team release sync
-
-The platform-team release path treats remote `origin/main` as the current source of truth. `scripts/release.sh` fetches it before and after the gate, then refuses with a rebase/sync message if the release branch is stale.
-
-Keep the local `main` worktree pulled from the PR-merged remote before cutting new work. The required `main` worktree check only proves the linked worktree exists; it does not prove local `main` is current, because the release guard checks `origin/main`.
-
-Tagging is permanently manual in platform-team mode. If a tag is wanted after the Bitbucket PR merges, run:
-
-```sh
-git tag vX.Y.Z <merge-commit> && git push origin vX.Y.Z
-```
diff --git a/scripts/release.sh b/scripts/release.sh
index ce19d803956becc2b39b89e57262cb47e44dd359..4e421de6d2c68f9095c6e73232b7e5e4c1e01670
--- a/scripts/release.sh
+++ b/scripts/release.sh
@@ -8,12 +8,15 @@
   cat <<'EOF'
 Usage:
   scripts/release.sh <slug> [--confirm-delta <text>]
+  scripts/release.sh tag-after-merge <slug>
   scripts/release.sh check-version <new-version> [current-version]
   scripts/release.sh next-version [current-version]
 
-The full release path never pushes. In self-review mode it commits, tags,
-fast-forward merges to local main, then stops for the Owner-confirmed push step.
-In platform-team mode it commits the bump on the release branch for PR review.
+The release path never pushes, never tags, and never touches main. It commits
+the version bump on the release branch for PR review.
+
+After the PR merges, tag-after-merge verifies origin/main is the release commit
+and creates the local version tag. The tag push is a separate confirmed step.
 EOF
 }
 
@@ -159,27 +162,6 @@
   git -C "$checkout" diff --cached --quiet || die "$label has staged changes"
   [[ -z "$(git -C "$checkout" ls-files --others --exclude-standard)" ]] \
     || die "$label has untracked files"
-}
-
-check_ff_possible() {
-  local main_checkout="$1"
-  local release_branch="$2"
-
-  git -C "$main_checkout" rev-parse --verify --quiet "$release_branch" >/dev/null \
-    || die "missing release branch: $release_branch"
-  git -C "$main_checkout" merge-base --is-ancestor main "$release_branch" \
-    || die "main cannot fast-forward to $release_branch"
-}
-
-human_pr_review_mode() {
-  local mode
-
-  mode=$(awk '/^review:/{f=1;next} f&&/human_pr_review:/{print $2; exit}' config.yaml)
-  mode=${mode:-self}
-  case "$mode" in
-    self|platform-team) printf '%s\n' "$mode" ;;
-    *) die "invalid review.human_pr_review '$mode' (expected self or platform-team)" ;;
-  esac
 }
 
 check_origin_main_ancestor() {
@@ -195,13 +177,11 @@
 rollback_release() {
   local status=$?
   local pre_release_head="$1"
-  local new_version="$2"
 
   trap - ERR
   set +e
-  git tag -d "v$new_version" >/dev/null 2>&1
   git reset --hard "$pre_release_head" >/dev/null 2>&1
-  echo "release: irreversible step failed; release commit and tag changes were rolled back" >&2
+  echo "release: irreversible step failed; release commit was rolled back" >&2
   exit "$status"
 }
 
@@ -210,15 +190,13 @@
   local confirm_delta="$2"
   local plan_path="work/$slug/plan.md"
   local release_branch="wt/$slug"
-  local main_checkout
   local release_checkout
   local current_version
   local new_version
   local release_note
   local pre_release_head
-  local review_mode
 
-  main_checkout=$(worktree_for_branch main) \
+  worktree_for_branch main >/dev/null \
     || die "main must be checked out in the primary worktree"
   release_checkout=$(worktree_for_branch "$release_branch") \
     || die "$release_branch must be checked out in a linked worktree"
@@ -229,64 +207,75 @@
   cd "$release_checkout"
   current_version=$(<VERSION)
   new_version=$(next_version "$current_version")
-  review_mode=$(human_pr_review_mode)
 
   check_verdict "$plan_path"
   check_clean_worktree "$release_checkout" "$release_branch"
-  check_clean_worktree "$main_checkout" "main checkout"
-  if [[ "$review_mode" == self ]]; then
-    check_ff_possible "$main_checkout" "$release_branch"
-    git rev-parse --verify --quiet "refs/tags/v$new_version" >/dev/null \
-      && die "tag v$new_version already exists"
-  else
-    check_origin_main_ancestor "$release_branch"
-  fi
+  check_origin_main_ancestor "$release_branch"
   check_gate
   check_clean_worktree "$release_checkout" "$release_branch"
   check_archi_fresh
   check_version_exceeds "$new_version" "$current_version"
-  check_clean_worktree "$main_checkout" "main checkout"
-  if [[ "$review_mode" == self ]]; then
-    check_ff_possible "$main_checkout" "$release_branch"
-  else
-    check_origin_main_ancestor "$release_branch"
-  fi
+  check_origin_main_ancestor "$release_branch"
 
   release_note=$(extract_release_note "$plan_path")
   pre_release_head=$(git rev-parse HEAD)
-  trap 'rollback_release "$pre_release_head" "$new_version"' ERR
+  trap 'rollback_release "$pre_release_head"' ERR
 
   printf '%s\n' "$new_version" >VERSION
   prepend_changelog "$new_version" "$release_note" "$confirm_delta"
 
   git add VERSION CHANGELOG.md
   git commit -m "Release v$new_version"
-  if [[ "$review_mode" == self ]]; then
-    git tag "v$new_version"
-    git -C "$main_checkout" merge --ff-only "$release_branch"
-  fi
   trap - ERR
 
-  if [[ "$review_mode" == self ]]; then
-    cat <<EOF
-release: prepared v$new_version on local main
-release: stopped before push; push requires Owner confirmation in-session
-EOF
-  else
-    cat <<EOF
+  cat <<EOF
 release: prepared v$new_version on $release_branch
 release: no tag created; local main untouched
-release: push $release_branch, open a Bitbucket PR, and have a platform engineer merge it
+release: push $release_branch, open a PR, and merge it after review
 EOF
-  fi
 }
 
+tag_after_merge() {
+  local slug="$1"
+  local release_branch="wt/$slug"
+  local release_checkout
+  local version
+  local origin_version
+  local origin_subject
+
+  release_checkout=$(worktree_for_branch "$release_branch") \
+    || die "$release_branch must be checked out in a linked worktree"
+  [[ -f "$release_checkout/VERSION" ]] || die "missing VERSION in $release_branch"
+
+  git fetch origin main
+  git rev-parse --verify --quiet origin/main >/dev/null \
+    || die "missing origin/main after fetch"
+
+  version=$(<"$release_checkout/VERSION")
+  origin_version=$(git show origin/main:VERSION) \
+    || die "origin/main does not contain VERSION"
+  origin_subject=$(git log -1 --format=%s origin/main)
+
+  [[ "$origin_version" == "$version" && "$origin_subject" == "Release v$version" ]] \
+    || die "origin/main is not Release v$version (VERSION is $origin_version; subject is '$origin_subject')"
+
+  git rev-parse --verify --quiet "refs/tags/v$version" >/dev/null \
+    && die "tag v$version already exists"
+
+  git tag "v$version" origin/main
+  printf 'release: created local tag v%s on origin/main\n' "$version"
+}
+
 if [[ $# -eq 0 ]]; then
   usage
   exit 2
 fi
 
 case "$1" in
+  tag-after-merge)
+    [[ $# -eq 2 ]] || { usage; exit 2; }
+    tag_after_merge "$2"
+    ;;
   check-version)
     [[ $# -eq 2 || $# -eq 3 ]] || { usage; exit 2; }
     current=${3:-$(<VERSION)}
diff --git a/tests/test-scripts.sh b/tests/test-scripts.sh
index 77e929164770e68220eefdedb0591fc9e25e1f0b..473311694d7e6564bdac487d41e2a595aa54d116
--- a/tests/test-scripts.sh
+++ b/tests/test-scripts.sh
@@ -58,7 +58,6 @@
   local verdict_line="$3"
   local gate_mode="$4"
   local archi_mode="$5"
-  local review_mode="${6:-self}"
   local tmp_root="$TMP/$name"
 
   REL_PRIMARY="$tmp_root/primary"
@@ -93,11 +92,7 @@
 echo "GATE: PASS"
 EOF
     chmod +x scripts/release.sh scripts/gate.sh
-    {
-      printf 'name: fixture\n'
-      printf 'review:\n'
-      printf '  human_pr_review: %s\n' "$review_mode"
-    } >config.yaml
+    printf 'name: fixture\n' >config.yaml
     printf 'merge rules\n' >CLAUDE.md
     printf '%s\n' "$version" >VERSION
     printf '# Changelog\n\nAll notable changes to this project are documented in this file.\n\n' >CHANGELOG.md
@@ -173,52 +168,21 @@
 setup_release_fixture release-version-regresses 2026.9.0 "Code-review verdict: APPROVE" pass fresh
 check_fails "release refuses when computed version does not exceed VERSION" bash -c "cd '$REL_WORKTREE' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo"
 
-setup_release_fixture release-happy 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-origin_before=$(git -C "$REL_PRIMARY" rev-parse origin/main)
-check "release happy path lands fast-forward on primary main and stops before push" bash -c "
-  cd '$REL_WORKTREE' &&
+setup_release_fixture release-happy-primary 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+main_before=$(git -C "$REL_PRIMARY" rev-parse main)
+check "release can be invoked from primary checkout" bash -c "
+  cd '$REL_PRIMARY' &&
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
-  [ \"\$(git -C '$REL_PRIMARY' branch --show-current)\" = main ] &&
-  [ \"\$(cat '$REL_PRIMARY/VERSION')\" = 2026.8.10 ] &&
-  git -C '$REL_PRIMARY' merge-base --is-ancestor wt/demo main &&
-  git -C '$REL_PRIMARY' rev-parse --verify --quiet refs/tags/v2026.8.10 &&
-  [ \"\$(git -C '$REL_PRIMARY' rev-parse origin/main)\" = '$origin_before' ]
-"
-
-setup_release_fixture release-tag-race-rolls-back 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-release_head_before=$(git -C "$REL_WORKTREE" rev-parse HEAD)
-real_git=$(command -v git)
-tag_fail_bin="$TMP/tag-fail-bin"
-mkdir -p "$tag_fail_bin"
-cat >"$tag_fail_bin/git" <<EOF
-#!/usr/bin/env bash
-if [[ "\$1" == tag && "\${2:-}" == v2026.8.10 ]]; then
-  "$real_git" tag v2026.8.10 HEAD~1
-fi
-"$real_git" "\$@"
-EOF
-chmod +x "$tag_fail_bin/git"
-check "release rolls back cleanly when tag creation fails after prechecks" bash -c "
-  cd '$REL_WORKTREE' &&
-  PATH='$tag_fail_bin:$REL_FAKEBIN':\$PATH bash scripts/release.sh demo >/dev/null 2>&1 &&
-  exit 1
-  status=\$?
-  [ \"\$status\" -ne 0 ] &&
-  [ \"\$(git rev-parse HEAD)\" = '$release_head_before' ] &&
-  [ \"\$(cat VERSION)\" = 2026.8.9 ] &&
-  git diff --quiet &&
-  git diff --cached --quiet &&
-  [ -z \"\$(git ls-files --others --exclude-standard)\" ] &&
-  ! git rev-parse --verify --quiet refs/tags/v2026.8.10
+  [ \"\$(git -C '$REL_PRIMARY' rev-parse main)\" = '$main_before' ] &&
+  [ \"\$(cat '$REL_PRIMARY/VERSION')\" = 2026.8.9 ] &&
+  [ \"\$(cat '$REL_WORKTREE/VERSION')\" = 2026.8.10 ] &&
+  ! git -C '$REL_WORKTREE' rev-parse --verify --quiet refs/tags/v2026.8.10
 "
-
-setup_release_fixture release-happy-primary 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-check "release can be invoked from primary checkout" bash -c "cd '$REL_PRIMARY' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo && [ \"\$(cat VERSION)\" = 2026.8.10 ]"
 
-setup_release_fixture release-platform-single 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
+setup_release_fixture release-single 2026.8.9 "Code-review verdict: APPROVE" pass fresh
 origin_before=$(git -C "$REL_PRIMARY" rev-parse origin/main)
 main_before=$(git -C "$REL_PRIMARY" rev-parse main)
-check "platform-team release commits bump on branch without touching main or tagging" bash -c "
+check "release commits bump on branch without touching main, origin/main, or tagging" bash -c "
   cd '$REL_WORKTREE' &&
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
   [ \"\$(git -C '$REL_PRIMARY' rev-parse main)\" = '$main_before' ] &&
@@ -228,13 +192,13 @@
   ! git rev-parse --verify --quiet refs/tags/v2026.8.10
 "
 
-setup_release_fixture release-platform-sequential 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
-check "platform-team release refuses stale branch, then computes next micro after sync" bash -c "
+setup_release_fixture release-sequential 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+check "release refuses stale branch, then computes next micro after sync" bash -c "
   set -e
   cd '$REL_WORKTREE'
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo
   git push -q origin wt/demo:main
-  rel_b='$TMP/release-platform-sequential/b-wt'
+  rel_b='$TMP/release-sequential/b-wt'
   git -C '$REL_PRIMARY' branch wt/b main
   git -C '$REL_PRIMARY' worktree add -q \"\$rel_b\" wt/b
   git -C \"\$rel_b\" config user.email tester@example.com
@@ -243,7 +207,7 @@
   sed 's/# Demo/# B/' '$REL_WORKTREE/work/demo/plan.md' > \"\$rel_b/work/b/plan.md\"
   git -C \"\$rel_b\" add work/b/plan.md
   GIT_AUTHOR_DATE='2026-08-16T10:00:30Z' GIT_COMMITTER_DATE='2026-08-16T10:00:30Z' git -C \"\$rel_b\" commit -qm 'add b plan'
-  stale_out='$TMP/platform-stale.out'
+  stale_out='$TMP/release-stale.out'
   if PATH='$REL_FAKEBIN':\$PATH bash \"\$rel_b/scripts/release.sh\" b >\"\$stale_out\" 2>&1; then
     exit 1
   fi
@@ -257,15 +221,15 @@
   ! git rev-parse --verify --quiet refs/tags/v2026.8.11
 "
 
-setup_release_fixture release-platform-mid-gate 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
+setup_release_fixture release-mid-gate 2026.8.9 "Code-review verdict: APPROVE" pass fresh
 mkdir -p "$REL_WORKTREE/scripts/gate.d"
 cat >"$REL_WORKTREE/scripts/gate.d/move-origin-main.sh" <<EOF
 #!/usr/bin/env bash
 set -euo pipefail
 repo='$REL_PRIMARY'
-printf 'platform merge during gate\n' >> "\$repo/platform.txt"
-git -C "\$repo" add platform.txt
-GIT_AUTHOR_DATE='2026-08-16T10:02:00Z' GIT_COMMITTER_DATE='2026-08-16T10:02:00Z' git -C "\$repo" commit -qm 'platform merge during gate'
+printf 'merge during gate\n' >> "\$repo/remote-change.txt"
+git -C "\$repo" add remote-change.txt
+GIT_AUTHOR_DATE='2026-08-16T10:02:00Z' GIT_COMMITTER_DATE='2026-08-16T10:02:00Z' git -C "\$repo" commit -qm 'merge during gate'
 git -C "\$repo" push -q origin main
 EOF
 chmod +x "$REL_WORKTREE/scripts/gate.d/move-origin-main.sh"
@@ -274,15 +238,58 @@
   git add scripts/gate.d/move-origin-main.sh
   GIT_AUTHOR_DATE="2026-08-16T10:00:30Z" GIT_COMMITTER_DATE="2026-08-16T10:00:30Z" git commit -qm "add mid-gate hook"
 )
-check "platform-team release catches origin/main moving during gate" bash -c "
+check "release catches origin/main moving during gate" bash -c "
   cd '$REL_WORKTREE'
-  mid_gate_out='$TMP/platform-mid-gate.out'
+  mid_gate_out='$TMP/release-mid-gate.out'
   if PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo >\"\$mid_gate_out\" 2>&1; then
     exit 1
   fi
   grep -q 'rebase/sync your branch onto origin/main' \"\$mid_gate_out\"
 "
 
+setup_release_fixture release-tag-after-merge-happy 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+real_git=$(command -v git)
+push_log="$TMP/tag-after-merge-push.log"
+tag_guard_bin="$TMP/tag-after-merge-bin"
+mkdir -p "$tag_guard_bin"
+cat >"$tag_guard_bin/git" <<EOF
+#!/usr/bin/env bash
+if [[ "\$1" == push ]]; then
+  printf 'unexpected push\n' >> "$push_log"
+  exit 99
+fi
+"$real_git" "\$@"
+EOF
+chmod +x "$tag_guard_bin/git"
+check "tag-after-merge creates local tag on origin/main and pushes nothing" bash -c "
+  cd '$REL_WORKTREE' &&
+  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
+  git push -q origin wt/demo:main &&
+  PATH='$tag_guard_bin:$REL_FAKEBIN':\$PATH bash scripts/release.sh tag-after-merge demo &&
+  [ \"\$(git rev-parse refs/tags/v2026.8.10)\" = \"\$(git rev-parse origin/main)\" ] &&
+  [ ! -s '$push_log' ]
+"
+
+setup_release_fixture release-tag-after-merge-wrong-commit 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+check "tag-after-merge refuses when origin/main advanced past the release" bash -c "
+  set -e
+  cd '$REL_WORKTREE'
+  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo
+  git push -q origin wt/demo:main
+  git -C '$REL_PRIMARY' fetch -q origin main
+  git -C '$REL_PRIMARY' reset -q --hard origin/main
+  printf 'next change\n' > '$REL_PRIMARY/after-release.txt'
+  git -C '$REL_PRIMARY' add after-release.txt
+  GIT_AUTHOR_DATE='2026-08-16T10:03:00Z' GIT_COMMITTER_DATE='2026-08-16T10:03:00Z' git -C '$REL_PRIMARY' commit -qm 'Next change'
+  git -C '$REL_PRIMARY' push -q origin main
+  wrong_out='$TMP/tag-after-merge-wrong.out'
+  if PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh tag-after-merge demo >\"\$wrong_out\" 2>&1; then
+    exit 1
+  fi
+  grep -q 'origin/main is not Release v2026.8.10' \"\$wrong_out\" &&
+  ! git rev-parse --verify --quiet refs/tags/v2026.8.10
+"
+
 # --- gate.sh runs and exits cleanly on this repo
 check "gate.sh runs on this repo" bash scripts/gate.sh
 

codex
Whitespace checks are clean, and the final diff is limited to the intended tracked files. I’m staging and committing those files now.
exec
/bin/zsh -lc 'git add CLAUDE.md config.yaml profiles/work.md scripts/release.sh skills/4-release/SKILL.md tests/test-scripts.sh && git commit -m "Collapse release flow to PR merge topology"' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
 succeeded in 0ms:
[wt/pr-merge-topology 6ff6c42] Collapse release flow to PR merge topology
 6 files changed, 118 insertions(+), 141 deletions(-)

diff --git a/.claude/skills/4-release/SKILL.md b/.claude/skills/4-release/SKILL.md
index 923d42b3ecf0574b4e04bc3d1d7d6b9fb9d647fe..e292a1fec26467e14eeab6dd25f32644bd12717f
--- a/.claude/skills/4-release/SKILL.md
+++ b/.claude/skills/4-release/SKILL.md
@@ -11,13 +11,11 @@
 
 1. **Confirm intent:** ask the Owner for the in-session release confirmation and capture the `Confirm-delta:` value.
 2. **Run the release script:** from the repo root, run `bash scripts/release.sh <slug> --confirm-delta "<value>"`.
-3. **React to the exit code based on `review.human_pr_review`:**
-   - Exit 0 with `self` → report the prepared version, tag, and local `main` state.
-   - Exit 0 with `platform-team` → report the bump commit on the release branch, that no tag was created, and that local `main` was untouched.
+3. **React to the exit code:**
+   - Exit 0 → report the bump commit on the release branch, that no tag exists yet, and that `main` was untouched.
    - Non-zero → report the script output and stop.
-4. **Push separately based on `review.human_pr_review`:**
-   - `self` → after the Owner confirms the push, push `main` and the new tag.
-   - `platform-team` → after the Owner confirms the push, push the release branch, print instructions to open a Bitbucket PR, and never push `main`.
+4. **Push the release branch:** after the Owner confirms the push, push the release branch, print instructions to open a PR and get it merged, and never push `main`.
+5. **Tag after merge:** once the Owner confirms the PR has merged, run `bash scripts/release.sh tag-after-merge <slug>`. If it exits non-zero, report the output and stop. If it succeeds, ask the Owner to confirm pushing the new tag, then run `git push origin v<version>`.
 
 ## Rules
 
diff --git a/CLAUDE.md b/CLAUDE.md
index bf72a9b97511c2563b248078c46726b47a5c62a8..6ec3b7c56d404abd1d28a52eb982227c2e51b4ea
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -23,7 +23,7 @@
 2. **The gate is a script.** `scripts/gate.sh` exits 0 or it doesn't. You do not overrule it, reinterpret it, or declare work done while it fails.
 3. **Implementation happens in worktrees**, never in this checkout. `scripts/worktree.sh` manages them.
 4. **Artifacts flow between stages, not transcripts.** The reviewer gets the diff + plan, never the implementation conversation.
-5. **Release is a script.** `scripts/release.sh` owns release preconditions, versioning, changelog assembly, the release commit, tag, and local fast-forward merge. It never pushes.
+5. **Release is a script.** `scripts/release.sh` owns release preconditions, versioning, changelog assembly, and the release commit on the branch. It never pushes and never touches `main`; tagging happens in `/4-release` after the PR merges via `tag-after-merge`.
 
 ## Context tiers
 
diff --git a/config.yaml b/config.yaml
index 906edc83166366a7556ac002dd81216301f98e3a..0c6fe53d7df35ed60c70d2a88dea2a1da99ab640
--- a/config.yaml
+++ b/config.yaml
@@ -14,9 +14,6 @@
   # Claude Code implementer alternative:
   # command: 'claude -p --dangerously-skip-permissions'
 
-review:
-  human_pr_review: self      # self | platform-team
-
 gate:
   command: scripts/gate.sh
   max_retries: 2             # failed-gate feedback loops before escalating to the Owner
diff --git a/profiles/work.md b/profiles/work.md
index 047b6efdfa81e3d8ed0e0fa246144863ee6762b4..4496e556b94f00ebe837b804420788283ba70e90
--- a/profiles/work.md
+++ b/profiles/work.md
@@ -4,7 +4,6 @@
 
 ## Declarations required at /init
 
-- **Review topology** — set `review.human_pr_review` to `self` or `platform-team`.
 - **Implementer runtime** — when the workplace uses Claude Code for implementation, set `implementer.runtime: claude` and use:
 
 ```yaml
@@ -16,8 +15,7 @@
 ## Adds to the loop
 
 - **Jira:** Jira keys may be recorded as read-only references in `work/<slug>/plan.md`. The loop never creates or mutates Jira issues.
-- **Self review topology:** `scripts/release.sh` keeps the base release shape: it bumps `VERSION` and `CHANGELOG.md`, creates `vX.Y.Z`, fast-forwards local `main`, and stops before push. `/4-release` pushes `main` and the tag only after Owner confirmation.
-- **Platform-team review topology:** `scripts/release.sh` fetches `origin/main`, refuses when the release branch does not contain it, bumps `VERSION` and `CHANGELOG.md` on the release branch, creates no tag, and leaves local `main` untouched. `/4-release` pushes the release branch and prints the Bitbucket PR instruction; a platform engineer merges the PR.
+- **Release:** use the base PR-merge release flow.
 
 ## Gate
 
@@ -26,15 +24,3 @@
 - Add `bitbucket-pipelines.yml`.
 - Delete `.github/workflows/ci.yml`.
 - Keep the deterministic commands equivalent: install `shellcheck`, set a git identity, run `bash tests/test-scripts.sh`, then run `bash scripts/gate.sh`.
-
-## Platform-team release sync
-
-The platform-team release path treats remote `origin/main` as the current source of truth. `scripts/release.sh` fetches it before and after the gate, then refuses with a rebase/sync message if the release branch is stale.
-
-Keep the local `main` worktree pulled from the PR-merged remote before cutting new work. The required `main` worktree check only proves the linked worktree exists; it does not prove local `main` is current, because the release guard checks `origin/main`.
-
-Tagging is permanently manual in platform-team mode. If a tag is wanted after the Bitbucket PR merges, run:
-
-```sh
-git tag vX.Y.Z <merge-commit> && git push origin vX.Y.Z
-```
diff --git a/scripts/release.sh b/scripts/release.sh
index ce19d803956becc2b39b89e57262cb47e44dd359..4e421de6d2c68f9095c6e73232b7e5e4c1e01670
--- a/scripts/release.sh
+++ b/scripts/release.sh
@@ -8,12 +8,15 @@
   cat <<'EOF'
 Usage:
   scripts/release.sh <slug> [--confirm-delta <text>]
+  scripts/release.sh tag-after-merge <slug>
   scripts/release.sh check-version <new-version> [current-version]
   scripts/release.sh next-version [current-version]
 
-The full release path never pushes. In self-review mode it commits, tags,
-fast-forward merges to local main, then stops for the Owner-confirmed push step.
-In platform-team mode it commits the bump on the release branch for PR review.
+The release path never pushes, never tags, and never touches main. It commits
+the version bump on the release branch for PR review.
+
+After the PR merges, tag-after-merge verifies origin/main is the release commit
+and creates the local version tag. The tag push is a separate confirmed step.
 EOF
 }
 
@@ -159,27 +162,6 @@
   git -C "$checkout" diff --cached --quiet || die "$label has staged changes"
   [[ -z "$(git -C "$checkout" ls-files --others --exclude-standard)" ]] \
     || die "$label has untracked files"
-}
-
-check_ff_possible() {
-  local main_checkout="$1"
-  local release_branch="$2"
-
-  git -C "$main_checkout" rev-parse --verify --quiet "$release_branch" >/dev/null \
-    || die "missing release branch: $release_branch"
-  git -C "$main_checkout" merge-base --is-ancestor main "$release_branch" \
-    || die "main cannot fast-forward to $release_branch"
-}
-
-human_pr_review_mode() {
-  local mode
-
-  mode=$(awk '/^review:/{f=1;next} f&&/human_pr_review:/{print $2; exit}' config.yaml)
-  mode=${mode:-self}
-  case "$mode" in
-    self|platform-team) printf '%s\n' "$mode" ;;
-    *) die "invalid review.human_pr_review '$mode' (expected self or platform-team)" ;;
-  esac
 }
 
 check_origin_main_ancestor() {
@@ -195,13 +177,11 @@
 rollback_release() {
   local status=$?
   local pre_release_head="$1"
-  local new_version="$2"
 
   trap - ERR
   set +e
-  git tag -d "v$new_version" >/dev/null 2>&1
   git reset --hard "$pre_release_head" >/dev/null 2>&1
-  echo "release: irreversible step failed; release commit and tag changes were rolled back" >&2
+  echo "release: irreversible step failed; release commit was rolled back" >&2
   exit "$status"
 }
 
@@ -210,15 +190,13 @@
   local confirm_delta="$2"
   local plan_path="work/$slug/plan.md"
   local release_branch="wt/$slug"
-  local main_checkout
   local release_checkout
   local current_version
   local new_version
   local release_note
   local pre_release_head
-  local review_mode
 
-  main_checkout=$(worktree_for_branch main) \
+  worktree_for_branch main >/dev/null \
     || die "main must be checked out in the primary worktree"
   release_checkout=$(worktree_for_branch "$release_branch") \
     || die "$release_branch must be checked out in a linked worktree"
@@ -229,64 +207,75 @@
   cd "$release_checkout"
   current_version=$(<VERSION)
   new_version=$(next_version "$current_version")
-  review_mode=$(human_pr_review_mode)
 
   check_verdict "$plan_path"
   check_clean_worktree "$release_checkout" "$release_branch"
-  check_clean_worktree "$main_checkout" "main checkout"
-  if [[ "$review_mode" == self ]]; then
-    check_ff_possible "$main_checkout" "$release_branch"
-    git rev-parse --verify --quiet "refs/tags/v$new_version" >/dev/null \
-      && die "tag v$new_version already exists"
-  else
-    check_origin_main_ancestor "$release_branch"
-  fi
+  check_origin_main_ancestor "$release_branch"
   check_gate
   check_clean_worktree "$release_checkout" "$release_branch"
   check_archi_fresh
   check_version_exceeds "$new_version" "$current_version"
-  check_clean_worktree "$main_checkout" "main checkout"
-  if [[ "$review_mode" == self ]]; then
-    check_ff_possible "$main_checkout" "$release_branch"
-  else
-    check_origin_main_ancestor "$release_branch"
-  fi
+  check_origin_main_ancestor "$release_branch"
 
   release_note=$(extract_release_note "$plan_path")
   pre_release_head=$(git rev-parse HEAD)
-  trap 'rollback_release "$pre_release_head" "$new_version"' ERR
+  trap 'rollback_release "$pre_release_head"' ERR
 
   printf '%s\n' "$new_version" >VERSION
   prepend_changelog "$new_version" "$release_note" "$confirm_delta"
 
   git add VERSION CHANGELOG.md
   git commit -m "Release v$new_version"
-  if [[ "$review_mode" == self ]]; then
-    git tag "v$new_version"
-    git -C "$main_checkout" merge --ff-only "$release_branch"
-  fi
   trap - ERR
 
-  if [[ "$review_mode" == self ]]; then
-    cat <<EOF
-release: prepared v$new_version on local main
-release: stopped before push; push requires Owner confirmation in-session
-EOF
-  else
-    cat <<EOF
+  cat <<EOF
 release: prepared v$new_version on $release_branch
 release: no tag created; local main untouched
-release: push $release_branch, open a Bitbucket PR, and have a platform engineer merge it
+release: push $release_branch, open a PR, and merge it after review
 EOF
-  fi
 }
 
+tag_after_merge() {
+  local slug="$1"
+  local release_branch="wt/$slug"
+  local release_checkout
+  local version
+  local origin_version
+  local origin_subject
+
+  release_checkout=$(worktree_for_branch "$release_branch") \
+    || die "$release_branch must be checked out in a linked worktree"
+  [[ -f "$release_checkout/VERSION" ]] || die "missing VERSION in $release_branch"
+
+  git fetch origin main
+  git rev-parse --verify --quiet origin/main >/dev/null \
+    || die "missing origin/main after fetch"
+
+  version=$(<"$release_checkout/VERSION")
+  origin_version=$(git show origin/main:VERSION) \
+    || die "origin/main does not contain VERSION"
+  origin_subject=$(git log -1 --format=%s origin/main)
+
+  [[ "$origin_version" == "$version" && "$origin_subject" == "Release v$version" ]] \
+    || die "origin/main is not Release v$version (VERSION is $origin_version; subject is '$origin_subject')"
+
+  git rev-parse --verify --quiet "refs/tags/v$version" >/dev/null \
+    && die "tag v$version already exists"
+
+  git tag "v$version" origin/main
+  printf 'release: created local tag v%s on origin/main\n' "$version"
+}
+
 if [[ $# -eq 0 ]]; then
   usage
   exit 2
 fi
 
 case "$1" in
+  tag-after-merge)
+    [[ $# -eq 2 ]] || { usage; exit 2; }
+    tag_after_merge "$2"
+    ;;
   check-version)
     [[ $# -eq 2 || $# -eq 3 ]] || { usage; exit 2; }
     current=${3:-$(<VERSION)}
diff --git a/tests/test-scripts.sh b/tests/test-scripts.sh
index 77e929164770e68220eefdedb0591fc9e25e1f0b..473311694d7e6564bdac487d41e2a595aa54d116
--- a/tests/test-scripts.sh
+++ b/tests/test-scripts.sh
@@ -58,7 +58,6 @@
   local verdict_line="$3"
   local gate_mode="$4"
   local archi_mode="$5"
-  local review_mode="${6:-self}"
   local tmp_root="$TMP/$name"
 
   REL_PRIMARY="$tmp_root/primary"
@@ -93,11 +92,7 @@
 echo "GATE: PASS"
 EOF
     chmod +x scripts/release.sh scripts/gate.sh
-    {
-      printf 'name: fixture\n'
-      printf 'review:\n'
-      printf '  human_pr_review: %s\n' "$review_mode"
-    } >config.yaml
+    printf 'name: fixture\n' >config.yaml
     printf 'merge rules\n' >CLAUDE.md
     printf '%s\n' "$version" >VERSION
     printf '# Changelog\n\nAll notable changes to this project are documented in this file.\n\n' >CHANGELOG.md
@@ -173,52 +168,21 @@
 setup_release_fixture release-version-regresses 2026.9.0 "Code-review verdict: APPROVE" pass fresh
 check_fails "release refuses when computed version does not exceed VERSION" bash -c "cd '$REL_WORKTREE' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo"
 
-setup_release_fixture release-happy 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-origin_before=$(git -C "$REL_PRIMARY" rev-parse origin/main)
-check "release happy path lands fast-forward on primary main and stops before push" bash -c "
-  cd '$REL_WORKTREE' &&
+setup_release_fixture release-happy-primary 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+main_before=$(git -C "$REL_PRIMARY" rev-parse main)
+check "release can be invoked from primary checkout" bash -c "
+  cd '$REL_PRIMARY' &&
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
-  [ \"\$(git -C '$REL_PRIMARY' branch --show-current)\" = main ] &&
-  [ \"\$(cat '$REL_PRIMARY/VERSION')\" = 2026.8.10 ] &&
-  git -C '$REL_PRIMARY' merge-base --is-ancestor wt/demo main &&
-  git -C '$REL_PRIMARY' rev-parse --verify --quiet refs/tags/v2026.8.10 &&
-  [ \"\$(git -C '$REL_PRIMARY' rev-parse origin/main)\" = '$origin_before' ]
-"
-
-setup_release_fixture release-tag-race-rolls-back 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-release_head_before=$(git -C "$REL_WORKTREE" rev-parse HEAD)
-real_git=$(command -v git)
-tag_fail_bin="$TMP/tag-fail-bin"
-mkdir -p "$tag_fail_bin"
-cat >"$tag_fail_bin/git" <<EOF
-#!/usr/bin/env bash
-if [[ "\$1" == tag && "\${2:-}" == v2026.8.10 ]]; then
-  "$real_git" tag v2026.8.10 HEAD~1
-fi
-"$real_git" "\$@"
-EOF
-chmod +x "$tag_fail_bin/git"
-check "release rolls back cleanly when tag creation fails after prechecks" bash -c "
-  cd '$REL_WORKTREE' &&
-  PATH='$tag_fail_bin:$REL_FAKEBIN':\$PATH bash scripts/release.sh demo >/dev/null 2>&1 &&
-  exit 1
-  status=\$?
-  [ \"\$status\" -ne 0 ] &&
-  [ \"\$(git rev-parse HEAD)\" = '$release_head_before' ] &&
-  [ \"\$(cat VERSION)\" = 2026.8.9 ] &&
-  git diff --quiet &&
-  git diff --cached --quiet &&
-  [ -z \"\$(git ls-files --others --exclude-standard)\" ] &&
-  ! git rev-parse --verify --quiet refs/tags/v2026.8.10
+  [ \"\$(git -C '$REL_PRIMARY' rev-parse main)\" = '$main_before' ] &&
+  [ \"\$(cat '$REL_PRIMARY/VERSION')\" = 2026.8.9 ] &&
+  [ \"\$(cat '$REL_WORKTREE/VERSION')\" = 2026.8.10 ] &&
+  ! git -C '$REL_WORKTREE' rev-parse --verify --quiet refs/tags/v2026.8.10
 "
-
-setup_release_fixture release-happy-primary 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-check "release can be invoked from primary checkout" bash -c "cd '$REL_PRIMARY' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo && [ \"\$(cat VERSION)\" = 2026.8.10 ]"
 
-setup_release_fixture release-platform-single 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
+setup_release_fixture release-single 2026.8.9 "Code-review verdict: APPROVE" pass fresh
 origin_before=$(git -C "$REL_PRIMARY" rev-parse origin/main)
 main_before=$(git -C "$REL_PRIMARY" rev-parse main)
-check "platform-team release commits bump on branch without touching main or tagging" bash -c "
+check "release commits bump on branch without touching main, origin/main, or tagging" bash -c "
   cd '$REL_WORKTREE' &&
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
   [ \"\$(git -C '$REL_PRIMARY' rev-parse main)\" = '$main_before' ] &&
@@ -228,13 +192,13 @@
   ! git rev-parse --verify --quiet refs/tags/v2026.8.10
 "
 
-setup_release_fixture release-platform-sequential 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
-check "platform-team release refuses stale branch, then computes next micro after sync" bash -c "
+setup_release_fixture release-sequential 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+check "release refuses stale branch, then computes next micro after sync" bash -c "
   set -e
   cd '$REL_WORKTREE'
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo
   git push -q origin wt/demo:main
-  rel_b='$TMP/release-platform-sequential/b-wt'
+  rel_b='$TMP/release-sequential/b-wt'
   git -C '$REL_PRIMARY' branch wt/b main
   git -C '$REL_PRIMARY' worktree add -q \"\$rel_b\" wt/b
   git -C \"\$rel_b\" config user.email tester@example.com
@@ -243,7 +207,7 @@
   sed 's/# Demo/# B/' '$REL_WORKTREE/work/demo/plan.md' > \"\$rel_b/work/b/plan.md\"
   git -C \"\$rel_b\" add work/b/plan.md
   GIT_AUTHOR_DATE='2026-08-16T10:00:30Z' GIT_COMMITTER_DATE='2026-08-16T10:00:30Z' git -C \"\$rel_b\" commit -qm 'add b plan'
-  stale_out='$TMP/platform-stale.out'
+  stale_out='$TMP/release-stale.out'
   if PATH='$REL_FAKEBIN':\$PATH bash \"\$rel_b/scripts/release.sh\" b >\"\$stale_out\" 2>&1; then
     exit 1
   fi
@@ -257,15 +221,15 @@
   ! git rev-parse --verify --quiet refs/tags/v2026.8.11
 "
 
-setup_release_fixture release-platform-mid-gate 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
+setup_release_fixture release-mid-gate 2026.8.9 "Code-review verdict: APPROVE" pass fresh
 mkdir -p "$REL_WORKTREE/scripts/gate.d"
 cat >"$REL_WORKTREE/scripts/gate.d/move-origin-main.sh" <<EOF
 #!/usr/bin/env bash
 set -euo pipefail
 repo='$REL_PRIMARY'
-printf 'platform merge during gate\n' >> "\$repo/platform.txt"
-git -C "\$repo" add platform.txt
-GIT_AUTHOR_DATE='2026-08-16T10:02:00Z' GIT_COMMITTER_DATE='2026-08-16T10:02:00Z' git -C "\$repo" commit -qm 'platform merge during gate'
+printf 'merge during gate\n' >> "\$repo/remote-change.txt"
+git -C "\$repo" add remote-change.txt
+GIT_AUTHOR_DATE='2026-08-16T10:02:00Z' GIT_COMMITTER_DATE='2026-08-16T10:02:00Z' git -C "\$repo" commit -qm 'merge during gate'
 git -C "\$repo" push -q origin main
 EOF
 chmod +x "$REL_WORKTREE/scripts/gate.d/move-origin-main.sh"
@@ -274,15 +238,58 @@
   git add scripts/gate.d/move-origin-main.sh
   GIT_AUTHOR_DATE="2026-08-16T10:00:30Z" GIT_COMMITTER_DATE="2026-08-16T10:00:30Z" git commit -qm "add mid-gate hook"
 )
-check "platform-team release catches origin/main moving during gate" bash -c "
+check "release catches origin/main moving during gate" bash -c "
   cd '$REL_WORKTREE'
-  mid_gate_out='$TMP/platform-mid-gate.out'
+  mid_gate_out='$TMP/release-mid-gate.out'
   if PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo >\"\$mid_gate_out\" 2>&1; then
     exit 1
   fi
   grep -q 'rebase/sync your branch onto origin/main' \"\$mid_gate_out\"
 "
 
+setup_release_fixture release-tag-after-merge-happy 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+real_git=$(command -v git)
+push_log="$TMP/tag-after-merge-push.log"
+tag_guard_bin="$TMP/tag-after-merge-bin"
+mkdir -p "$tag_guard_bin"
+cat >"$tag_guard_bin/git" <<EOF
+#!/usr/bin/env bash
+if [[ "\$1" == push ]]; then
+  printf 'unexpected push\n' >> "$push_log"
+  exit 99
+fi
+"$real_git" "\$@"
+EOF
+chmod +x "$tag_guard_bin/git"
+check "tag-after-merge creates local tag on origin/main and pushes nothing" bash -c "
+  cd '$REL_WORKTREE' &&
+  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
+  git push -q origin wt/demo:main &&
+  PATH='$tag_guard_bin:$REL_FAKEBIN':\$PATH bash scripts/release.sh tag-after-merge demo &&
+  [ \"\$(git rev-parse refs/tags/v2026.8.10)\" = \"\$(git rev-parse origin/main)\" ] &&
+  [ ! -s '$push_log' ]
+"
+
+setup_release_fixture release-tag-after-merge-wrong-commit 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+check "tag-after-merge refuses when origin/main advanced past the release" bash -c "
+  set -e
+  cd '$REL_WORKTREE'
+  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo
+  git push -q origin wt/demo:main
+  git -C '$REL_PRIMARY' fetch -q origin main
+  git -C '$REL_PRIMARY' reset -q --hard origin/main
+  printf 'next change\n' > '$REL_PRIMARY/after-release.txt'
+  git -C '$REL_PRIMARY' add after-release.txt
+  GIT_AUTHOR_DATE='2026-08-16T10:03:00Z' GIT_COMMITTER_DATE='2026-08-16T10:03:00Z' git -C '$REL_PRIMARY' commit -qm 'Next change'
+  git -C '$REL_PRIMARY' push -q origin main
+  wrong_out='$TMP/tag-after-merge-wrong.out'
+  if PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh tag-after-merge demo >\"\$wrong_out\" 2>&1; then
+    exit 1
+  fi
+  grep -q 'origin/main is not Release v2026.8.10' \"\$wrong_out\" &&
+  ! git rev-parse --verify --quiet refs/tags/v2026.8.10
+"
+
 # --- gate.sh runs and exits cleanly on this repo
 check "gate.sh runs on this repo" bash scripts/gate.sh
 

codex
The commit succeeded. I’m checking the post-commit status so the final summary can distinguish committed work from the pre-existing untracked work-unit files.
exec
/bin/zsh -lc 'git log -1 --oneline' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
 succeeded in 0ms:
6ff6c42 Collapse release flow to PR merge topology

exec
/bin/zsh -lc 'git show --stat --oneline --name-only HEAD' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
exec
/bin/zsh -lc 'git status --short' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-merge-topology
 succeeded in 0ms:
?? work/pr-merge-topology/

 succeeded in 0ms:
6ff6c42 Collapse release flow to PR merge topology
CLAUDE.md
config.yaml
profiles/work.md
scripts/release.sh
skills/4-release/SKILL.md
tests/test-scripts.sh

diff --git a/.claude/skills/4-release/SKILL.md b/.claude/skills/4-release/SKILL.md
index 923d42b3ecf0574b4e04bc3d1d7d6b9fb9d647fe..e292a1fec26467e14eeab6dd25f32644bd12717f
--- a/.claude/skills/4-release/SKILL.md
+++ b/.claude/skills/4-release/SKILL.md
@@ -11,13 +11,11 @@
 
 1. **Confirm intent:** ask the Owner for the in-session release confirmation and capture the `Confirm-delta:` value.
 2. **Run the release script:** from the repo root, run `bash scripts/release.sh <slug> --confirm-delta "<value>"`.
-3. **React to the exit code based on `review.human_pr_review`:**
-   - Exit 0 with `self` → report the prepared version, tag, and local `main` state.
-   - Exit 0 with `platform-team` → report the bump commit on the release branch, that no tag was created, and that local `main` was untouched.
+3. **React to the exit code:**
+   - Exit 0 → report the bump commit on the release branch, that no tag exists yet, and that `main` was untouched.
    - Non-zero → report the script output and stop.
-4. **Push separately based on `review.human_pr_review`:**
-   - `self` → after the Owner confirms the push, push `main` and the new tag.
-   - `platform-team` → after the Owner confirms the push, push the release branch, print instructions to open a Bitbucket PR, and never push `main`.
+4. **Push the release branch:** after the Owner confirms the push, push the release branch, print instructions to open a PR and get it merged, and never push `main`.
+5. **Tag after merge:** once the Owner confirms the PR has merged, run `bash scripts/release.sh tag-after-merge <slug>`. If it exits non-zero, report the output and stop. If it succeeds, ask the Owner to confirm pushing the new tag, then run `git push origin v<version>`.
 
 ## Rules
 
diff --git a/CLAUDE.md b/CLAUDE.md
index bf72a9b97511c2563b248078c46726b47a5c62a8..6ec3b7c56d404abd1d28a52eb982227c2e51b4ea
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -23,7 +23,7 @@
 2. **The gate is a script.** `scripts/gate.sh` exits 0 or it doesn't. You do not overrule it, reinterpret it, or declare work done while it fails.
 3. **Implementation happens in worktrees**, never in this checkout. `scripts/worktree.sh` manages them.
 4. **Artifacts flow between stages, not transcripts.** The reviewer gets the diff + plan, never the implementation conversation.
-5. **Release is a script.** `scripts/release.sh` owns release preconditions, versioning, changelog assembly, the release commit, tag, and local fast-forward merge. It never pushes.
+5. **Release is a script.** `scripts/release.sh` owns release preconditions, versioning, changelog assembly, and the release commit on the branch. It never pushes and never touches `main`; tagging happens in `/4-release` after the PR merges via `tag-after-merge`.
 
 ## Context tiers
 
diff --git a/config.yaml b/config.yaml
index 906edc83166366a7556ac002dd81216301f98e3a..0c6fe53d7df35ed60c70d2a88dea2a1da99ab640
--- a/config.yaml
+++ b/config.yaml
@@ -14,9 +14,6 @@
   # Claude Code implementer alternative:
   # command: 'claude -p --dangerously-skip-permissions'
 
-review:
-  human_pr_review: self      # self | platform-team
-
 gate:
   command: scripts/gate.sh
   max_retries: 2             # failed-gate feedback loops before escalating to the Owner
diff --git a/profiles/work.md b/profiles/work.md
index 047b6efdfa81e3d8ed0e0fa246144863ee6762b4..4496e556b94f00ebe837b804420788283ba70e90
--- a/profiles/work.md
+++ b/profiles/work.md
@@ -4,7 +4,6 @@
 
 ## Declarations required at /init
 
-- **Review topology** — set `review.human_pr_review` to `self` or `platform-team`.
 - **Implementer runtime** — when the workplace uses Claude Code for implementation, set `implementer.runtime: claude` and use:
 
 ```yaml
@@ -16,8 +15,7 @@
 ## Adds to the loop
 
 - **Jira:** Jira keys may be recorded as read-only references in `work/<slug>/plan.md`. The loop never creates or mutates Jira issues.
-- **Self review topology:** `scripts/release.sh` keeps the base release shape: it bumps `VERSION` and `CHANGELOG.md`, creates `vX.Y.Z`, fast-forwards local `main`, and stops before push. `/4-release` pushes `main` and the tag only after Owner confirmation.
-- **Platform-team review topology:** `scripts/release.sh` fetches `origin/main`, refuses when the release branch does not contain it, bumps `VERSION` and `CHANGELOG.md` on the release branch, creates no tag, and leaves local `main` untouched. `/4-release` pushes the release branch and prints the Bitbucket PR instruction; a platform engineer merges the PR.
+- **Release:** use the base PR-merge release flow.
 
 ## Gate
 
@@ -26,15 +24,3 @@
 - Add `bitbucket-pipelines.yml`.
 - Delete `.github/workflows/ci.yml`.
 - Keep the deterministic commands equivalent: install `shellcheck`, set a git identity, run `bash tests/test-scripts.sh`, then run `bash scripts/gate.sh`.
-
-## Platform-team release sync
-
-The platform-team release path treats remote `origin/main` as the current source of truth. `scripts/release.sh` fetches it before and after the gate, then refuses with a rebase/sync message if the release branch is stale.
-
-Keep the local `main` worktree pulled from the PR-merged remote before cutting new work. The required `main` worktree check only proves the linked worktree exists; it does not prove local `main` is current, because the release guard checks `origin/main`.
-
-Tagging is permanently manual in platform-team mode. If a tag is wanted after the Bitbucket PR merges, run:
-
-```sh
-git tag vX.Y.Z <merge-commit> && git push origin vX.Y.Z
-```
diff --git a/scripts/release.sh b/scripts/release.sh
index ce19d803956becc2b39b89e57262cb47e44dd359..4e421de6d2c68f9095c6e73232b7e5e4c1e01670
--- a/scripts/release.sh
+++ b/scripts/release.sh
@@ -8,12 +8,15 @@
   cat <<'EOF'
 Usage:
   scripts/release.sh <slug> [--confirm-delta <text>]
+  scripts/release.sh tag-after-merge <slug>
   scripts/release.sh check-version <new-version> [current-version]
   scripts/release.sh next-version [current-version]
 
-The full release path never pushes. In self-review mode it commits, tags,
-fast-forward merges to local main, then stops for the Owner-confirmed push step.
-In platform-team mode it commits the bump on the release branch for PR review.
+The release path never pushes, never tags, and never touches main. It commits
+the version bump on the release branch for PR review.
+
+After the PR merges, tag-after-merge verifies origin/main is the release commit
+and creates the local version tag. The tag push is a separate confirmed step.
 EOF
 }
 
@@ -159,27 +162,6 @@
   git -C "$checkout" diff --cached --quiet || die "$label has staged changes"
   [[ -z "$(git -C "$checkout" ls-files --others --exclude-standard)" ]] \
     || die "$label has untracked files"
-}
-
-check_ff_possible() {
-  local main_checkout="$1"
-  local release_branch="$2"
-
-  git -C "$main_checkout" rev-parse --verify --quiet "$release_branch" >/dev/null \
-    || die "missing release branch: $release_branch"
-  git -C "$main_checkout" merge-base --is-ancestor main "$release_branch" \
-    || die "main cannot fast-forward to $release_branch"
-}
-
-human_pr_review_mode() {
-  local mode
-
-  mode=$(awk '/^review:/{f=1;next} f&&/human_pr_review:/{print $2; exit}' config.yaml)
-  mode=${mode:-self}
-  case "$mode" in
-    self|platform-team) printf '%s\n' "$mode" ;;
-    *) die "invalid review.human_pr_review '$mode' (expected self or platform-team)" ;;
-  esac
 }
 
 check_origin_main_ancestor() {
@@ -195,13 +177,11 @@
 rollback_release() {
   local status=$?
   local pre_release_head="$1"
-  local new_version="$2"
 
   trap - ERR
   set +e
-  git tag -d "v$new_version" >/dev/null 2>&1
   git reset --hard "$pre_release_head" >/dev/null 2>&1
-  echo "release: irreversible step failed; release commit and tag changes were rolled back" >&2
+  echo "release: irreversible step failed; release commit was rolled back" >&2
   exit "$status"
 }
 
@@ -210,15 +190,13 @@
   local confirm_delta="$2"
   local plan_path="work/$slug/plan.md"
   local release_branch="wt/$slug"
-  local main_checkout
   local release_checkout
   local current_version
   local new_version
   local release_note
   local pre_release_head
-  local review_mode
 
-  main_checkout=$(worktree_for_branch main) \
+  worktree_for_branch main >/dev/null \
     || die "main must be checked out in the primary worktree"
   release_checkout=$(worktree_for_branch "$release_branch") \
     || die "$release_branch must be checked out in a linked worktree"
@@ -229,64 +207,75 @@
   cd "$release_checkout"
   current_version=$(<VERSION)
   new_version=$(next_version "$current_version")
-  review_mode=$(human_pr_review_mode)
 
   check_verdict "$plan_path"
   check_clean_worktree "$release_checkout" "$release_branch"
-  check_clean_worktree "$main_checkout" "main checkout"
-  if [[ "$review_mode" == self ]]; then
-    check_ff_possible "$main_checkout" "$release_branch"
-    git rev-parse --verify --quiet "refs/tags/v$new_version" >/dev/null \
-      && die "tag v$new_version already exists"
-  else
-    check_origin_main_ancestor "$release_branch"
-  fi
+  check_origin_main_ancestor "$release_branch"
   check_gate
   check_clean_worktree "$release_checkout" "$release_branch"
   check_archi_fresh
   check_version_exceeds "$new_version" "$current_version"
-  check_clean_worktree "$main_checkout" "main checkout"
-  if [[ "$review_mode" == self ]]; then
-    check_ff_possible "$main_checkout" "$release_branch"
-  else
-    check_origin_main_ancestor "$release_branch"
-  fi
+  check_origin_main_ancestor "$release_branch"
 
   release_note=$(extract_release_note "$plan_path")
   pre_release_head=$(git rev-parse HEAD)
-  trap 'rollback_release "$pre_release_head" "$new_version"' ERR
+  trap 'rollback_release "$pre_release_head"' ERR
 
   printf '%s\n' "$new_version" >VERSION
   prepend_changelog "$new_version" "$release_note" "$confirm_delta"
 
   git add VERSION CHANGELOG.md
   git commit -m "Release v$new_version"
-  if [[ "$review_mode" == self ]]; then
-    git tag "v$new_version"
-    git -C "$main_checkout" merge --ff-only "$release_branch"
-  fi
   trap - ERR
 
-  if [[ "$review_mode" == self ]]; then
-    cat <<EOF
-release: prepared v$new_version on local main
-release: stopped before push; push requires Owner confirmation in-session
-EOF
-  else
-    cat <<EOF
+  cat <<EOF
 release: prepared v$new_version on $release_branch
 release: no tag created; local main untouched
-release: push $release_branch, open a Bitbucket PR, and have a platform engineer merge it
+release: push $release_branch, open a PR, and merge it after review
 EOF
-  fi
 }
 
+tag_after_merge() {
+  local slug="$1"
+  local release_branch="wt/$slug"
+  local release_checkout
+  local version
+  local origin_version
+  local origin_subject
+
+  release_checkout=$(worktree_for_branch "$release_branch") \
+    || die "$release_branch must be checked out in a linked worktree"
+  [[ -f "$release_checkout/VERSION" ]] || die "missing VERSION in $release_branch"
+
+  git fetch origin main
+  git rev-parse --verify --quiet origin/main >/dev/null \
+    || die "missing origin/main after fetch"
+
+  version=$(<"$release_checkout/VERSION")
+  origin_version=$(git show origin/main:VERSION) \
+    || die "origin/main does not contain VERSION"
+  origin_subject=$(git log -1 --format=%s origin/main)
+
+  [[ "$origin_version" == "$version" && "$origin_subject" == "Release v$version" ]] \
+    || die "origin/main is not Release v$version (VERSION is $origin_version; subject is '$origin_subject')"
+
+  git rev-parse --verify --quiet "refs/tags/v$version" >/dev/null \
+    && die "tag v$version already exists"
+
+  git tag "v$version" origin/main
+  printf 'release: created local tag v%s on origin/main\n' "$version"
+}
+
 if [[ $# -eq 0 ]]; then
   usage
   exit 2
 fi
 
 case "$1" in
+  tag-after-merge)
+    [[ $# -eq 2 ]] || { usage; exit 2; }
+    tag_after_merge "$2"
+    ;;
   check-version)
     [[ $# -eq 2 || $# -eq 3 ]] || { usage; exit 2; }
     current=${3:-$(<VERSION)}
diff --git a/tests/test-scripts.sh b/tests/test-scripts.sh
index 77e929164770e68220eefdedb0591fc9e25e1f0b..473311694d7e6564bdac487d41e2a595aa54d116
--- a/tests/test-scripts.sh
+++ b/tests/test-scripts.sh
@@ -58,7 +58,6 @@
   local verdict_line="$3"
   local gate_mode="$4"
   local archi_mode="$5"
-  local review_mode="${6:-self}"
   local tmp_root="$TMP/$name"
 
   REL_PRIMARY="$tmp_root/primary"
@@ -93,11 +92,7 @@
 echo "GATE: PASS"
 EOF
     chmod +x scripts/release.sh scripts/gate.sh
-    {
-      printf 'name: fixture\n'
-      printf 'review:\n'
-      printf '  human_pr_review: %s\n' "$review_mode"
-    } >config.yaml
+    printf 'name: fixture\n' >config.yaml
     printf 'merge rules\n' >CLAUDE.md
     printf '%s\n' "$version" >VERSION
     printf '# Changelog\n\nAll notable changes to this project are documented in this file.\n\n' >CHANGELOG.md
@@ -173,52 +168,21 @@
 setup_release_fixture release-version-regresses 2026.9.0 "Code-review verdict: APPROVE" pass fresh
 check_fails "release refuses when computed version does not exceed VERSION" bash -c "cd '$REL_WORKTREE' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo"
 
-setup_release_fixture release-happy 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-origin_before=$(git -C "$REL_PRIMARY" rev-parse origin/main)
-check "release happy path lands fast-forward on primary main and stops before push" bash -c "
-  cd '$REL_WORKTREE' &&
+setup_release_fixture release-happy-primary 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+main_before=$(git -C "$REL_PRIMARY" rev-parse main)
+check "release can be invoked from primary checkout" bash -c "
+  cd '$REL_PRIMARY' &&
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
-  [ \"\$(git -C '$REL_PRIMARY' branch --show-current)\" = main ] &&
-  [ \"\$(cat '$REL_PRIMARY/VERSION')\" = 2026.8.10 ] &&
-  git -C '$REL_PRIMARY' merge-base --is-ancestor wt/demo main &&
-  git -C '$REL_PRIMARY' rev-parse --verify --quiet refs/tags/v2026.8.10 &&
-  [ \"\$(git -C '$REL_PRIMARY' rev-parse origin/main)\" = '$origin_before' ]
-"
-
-setup_release_fixture release-tag-race-rolls-back 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-release_head_before=$(git -C "$REL_WORKTREE" rev-parse HEAD)
-real_git=$(command -v git)
-tag_fail_bin="$TMP/tag-fail-bin"
-mkdir -p "$tag_fail_bin"
-cat >"$tag_fail_bin/git" <<EOF
-#!/usr/bin/env bash
-if [[ "\$1" == tag && "\${2:-}" == v2026.8.10 ]]; then
-  "$real_git" tag v2026.8.10 HEAD~1
-fi
-"$real_git" "\$@"
-EOF
-chmod +x "$tag_fail_bin/git"
-check "release rolls back cleanly when tag creation fails after prechecks" bash -c "
-  cd '$REL_WORKTREE' &&
-  PATH='$tag_fail_bin:$REL_FAKEBIN':\$PATH bash scripts/release.sh demo >/dev/null 2>&1 &&
-  exit 1
-  status=\$?
-  [ \"\$status\" -ne 0 ] &&
-  [ \"\$(git rev-parse HEAD)\" = '$release_head_before' ] &&
-  [ \"\$(cat VERSION)\" = 2026.8.9 ] &&
-  git diff --quiet &&
-  git diff --cached --quiet &&
-  [ -z \"\$(git ls-files --others --exclude-standard)\" ] &&
-  ! git rev-parse --verify --quiet refs/tags/v2026.8.10
+  [ \"\$(git -C '$REL_PRIMARY' rev-parse main)\" = '$main_before' ] &&
+  [ \"\$(cat '$REL_PRIMARY/VERSION')\" = 2026.8.9 ] &&
+  [ \"\$(cat '$REL_WORKTREE/VERSION')\" = 2026.8.10 ] &&
+  ! git -C '$REL_WORKTREE' rev-parse --verify --quiet refs/tags/v2026.8.10
 "
-
-setup_release_fixture release-happy-primary 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-check "release can be invoked from primary checkout" bash -c "cd '$REL_PRIMARY' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo && [ \"\$(cat VERSION)\" = 2026.8.10 ]"
 
-setup_release_fixture release-platform-single 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
+setup_release_fixture release-single 2026.8.9 "Code-review verdict: APPROVE" pass fresh
 origin_before=$(git -C "$REL_PRIMARY" rev-parse origin/main)
 main_before=$(git -C "$REL_PRIMARY" rev-parse main)
-check "platform-team release commits bump on branch without touching main or tagging" bash -c "
+check "release commits bump on branch without touching main, origin/main, or tagging" bash -c "
   cd '$REL_WORKTREE' &&
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
   [ \"\$(git -C '$REL_PRIMARY' rev-parse main)\" = '$main_before' ] &&
@@ -228,13 +192,13 @@
   ! git rev-parse --verify --quiet refs/tags/v2026.8.10
 "
 
-setup_release_fixture release-platform-sequential 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
-check "platform-team release refuses stale branch, then computes next micro after sync" bash -c "
+setup_release_fixture release-sequential 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+check "release refuses stale branch, then computes next micro after sync" bash -c "
   set -e
   cd '$REL_WORKTREE'
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo
   git push -q origin wt/demo:main
-  rel_b='$TMP/release-platform-sequential/b-wt'
+  rel_b='$TMP/release-sequential/b-wt'
   git -C '$REL_PRIMARY' branch wt/b main
   git -C '$REL_PRIMARY' worktree add -q \"\$rel_b\" wt/b
   git -C \"\$rel_b\" config user.email tester@example.com
@@ -243,7 +207,7 @@
   sed 's/# Demo/# B/' '$REL_WORKTREE/work/demo/plan.md' > \"\$rel_b/work/b/plan.md\"
   git -C \"\$rel_b\" add work/b/plan.md
   GIT_AUTHOR_DATE='2026-08-16T10:00:30Z' GIT_COMMITTER_DATE='2026-08-16T10:00:30Z' git -C \"\$rel_b\" commit -qm 'add b plan'
-  stale_out='$TMP/platform-stale.out'
+  stale_out='$TMP/release-stale.out'
   if PATH='$REL_FAKEBIN':\$PATH bash \"\$rel_b/scripts/release.sh\" b >\"\$stale_out\" 2>&1; then
     exit 1
   fi
@@ -257,15 +221,15 @@
   ! git rev-parse --verify --quiet refs/tags/v2026.8.11
 "
 
-setup_release_fixture release-platform-mid-gate 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
+setup_release_fixture release-mid-gate 2026.8.9 "Code-review verdict: APPROVE" pass fresh
 mkdir -p "$REL_WORKTREE/scripts/gate.d"
 cat >"$REL_WORKTREE/scripts/gate.d/move-origin-main.sh" <<EOF
 #!/usr/bin/env bash
 set -euo pipefail
 repo='$REL_PRIMARY'
-printf 'platform merge during gate\n' >> "\$repo/platform.txt"
-git -C "\$repo" add platform.txt
-GIT_AUTHOR_DATE='2026-08-16T10:02:00Z' GIT_COMMITTER_DATE='2026-08-16T10:02:00Z' git -C "\$repo" commit -qm 'platform merge during gate'
+printf 'merge during gate\n' >> "\$repo/remote-change.txt"
+git -C "\$repo" add remote-change.txt
+GIT_AUTHOR_DATE='2026-08-16T10:02:00Z' GIT_COMMITTER_DATE='2026-08-16T10:02:00Z' git -C "\$repo" commit -qm 'merge during gate'
 git -C "\$repo" push -q origin main
 EOF
 chmod +x "$REL_WORKTREE/scripts/gate.d/move-origin-main.sh"
@@ -274,15 +238,58 @@
   git add scripts/gate.d/move-origin-main.sh
   GIT_AUTHOR_DATE="2026-08-16T10:00:30Z" GIT_COMMITTER_DATE="2026-08-16T10:00:30Z" git commit -qm "add mid-gate hook"
 )
-check "platform-team release catches origin/main moving during gate" bash -c "
+check "release catches origin/main moving during gate" bash -c "
   cd '$REL_WORKTREE'
-  mid_gate_out='$TMP/platform-mid-gate.out'
+  mid_gate_out='$TMP/release-mid-gate.out'
   if PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo >\"\$mid_gate_out\" 2>&1; then
     exit 1
   fi
   grep -q 'rebase/sync your branch onto origin/main' \"\$mid_gate_out\"
 "
 
+setup_release_fixture release-tag-after-merge-happy 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+real_git=$(command -v git)
+push_log="$TMP/tag-after-merge-push.log"
+tag_guard_bin="$TMP/tag-after-merge-bin"
+mkdir -p "$tag_guard_bin"
+cat >"$tag_guard_bin/git" <<EOF
+#!/usr/bin/env bash
+if [[ "\$1" == push ]]; then
+  printf 'unexpected push\n' >> "$push_log"
+  exit 99
+fi
+"$real_git" "\$@"
+EOF
+chmod +x "$tag_guard_bin/git"
+check "tag-after-merge creates local tag on origin/main and pushes nothing" bash -c "
+  cd '$REL_WORKTREE' &&
+  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
+  git push -q origin wt/demo:main &&
+  PATH='$tag_guard_bin:$REL_FAKEBIN':\$PATH bash scripts/release.sh tag-after-merge demo &&
+  [ \"\$(git rev-parse refs/tags/v2026.8.10)\" = \"\$(git rev-parse origin/main)\" ] &&
+  [ ! -s '$push_log' ]
+"
+
+setup_release_fixture release-tag-after-merge-wrong-commit 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+check "tag-after-merge refuses when origin/main advanced past the release" bash -c "
+  set -e
+  cd '$REL_WORKTREE'
+  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo
+  git push -q origin wt/demo:main
+  git -C '$REL_PRIMARY' fetch -q origin main
+  git -C '$REL_PRIMARY' reset -q --hard origin/main
+  printf 'next change\n' > '$REL_PRIMARY/after-release.txt'
+  git -C '$REL_PRIMARY' add after-release.txt
+  GIT_AUTHOR_DATE='2026-08-16T10:03:00Z' GIT_COMMITTER_DATE='2026-08-16T10:03:00Z' git -C '$REL_PRIMARY' commit -qm 'Next change'
+  git -C '$REL_PRIMARY' push -q origin main
+  wrong_out='$TMP/tag-after-merge-wrong.out'
+  if PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh tag-after-merge demo >\"\$wrong_out\" 2>&1; then
+    exit 1
+  fi
+  grep -q 'origin/main is not Release v2026.8.10' \"\$wrong_out\" &&
+  ! git rev-parse --verify --quiet refs/tags/v2026.8.10
+"
+
 # --- gate.sh runs and exits cleanly on this repo
 check "gate.sh runs on this repo" bash scripts/gate.sh
 

codex
Implemented and committed the PR-merge-only release topology.

Commit: `6ff6c42 Collapse release flow to PR merge topology`

Changed:
- Removed `review.human_pr_review` config and all self/direct-push release behavior.
- `scripts/release.sh` now commits only on `wt/<slug>`, never pushes, never tags during release, and never touches `main`.
- Added `scripts/release.sh tag-after-merge <slug>` with `origin/main` version/subject verification before local tag creation.
- Updated `/4-release`, `profiles/work.md`, and `CLAUDE.md` wording for the single PR flow.
- Updated smoke tests to remove self-mode coverage and add post-merge tag happy/wrong-commit tests.

Verification:
- `bash scripts/gate.sh` passed: 20 tests, 0 failures.
- Required greps for removed topology terms / `git push` in `scripts/release.sh` were clean.

Notes:
- I did not edit `PLAN.md` because your hard footprint list omitted it, even though the work-unit plan mentioned it.
- `work/pr-merge-topology/` remains untracked and unstaged as pre-existing/source handoff material.
diff --git a/.claude/skills/4-release/SKILL.md b/.claude/skills/4-release/SKILL.md
index 923d42b3ecf0574b4e04bc3d1d7d6b9fb9d647fe..e292a1fec26467e14eeab6dd25f32644bd12717f
--- a/.claude/skills/4-release/SKILL.md
+++ b/.claude/skills/4-release/SKILL.md
@@ -11,13 +11,11 @@
 
 1. **Confirm intent:** ask the Owner for the in-session release confirmation and capture the `Confirm-delta:` value.
 2. **Run the release script:** from the repo root, run `bash scripts/release.sh <slug> --confirm-delta "<value>"`.
-3. **React to the exit code based on `review.human_pr_review`:**
-   - Exit 0 with `self` → report the prepared version, tag, and local `main` state.
-   - Exit 0 with `platform-team` → report the bump commit on the release branch, that no tag was created, and that local `main` was untouched.
+3. **React to the exit code:**
+   - Exit 0 → report the bump commit on the release branch, that no tag exists yet, and that `main` was untouched.
    - Non-zero → report the script output and stop.
-4. **Push separately based on `review.human_pr_review`:**
-   - `self` → after the Owner confirms the push, push `main` and the new tag.
-   - `platform-team` → after the Owner confirms the push, push the release branch, print instructions to open a Bitbucket PR, and never push `main`.
+4. **Push the release branch:** after the Owner confirms the push, push the release branch, print instructions to open a PR and get it merged, and never push `main`.
+5. **Tag after merge:** once the Owner confirms the PR has merged, run `bash scripts/release.sh tag-after-merge <slug>`. If it exits non-zero, report the output and stop. If it succeeds, ask the Owner to confirm pushing the new tag, then run `git push origin v<version>`.
 
 ## Rules
 
diff --git a/CLAUDE.md b/CLAUDE.md
index bf72a9b97511c2563b248078c46726b47a5c62a8..6ec3b7c56d404abd1d28a52eb982227c2e51b4ea
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -23,7 +23,7 @@
 2. **The gate is a script.** `scripts/gate.sh` exits 0 or it doesn't. You do not overrule it, reinterpret it, or declare work done while it fails.
 3. **Implementation happens in worktrees**, never in this checkout. `scripts/worktree.sh` manages them.
 4. **Artifacts flow between stages, not transcripts.** The reviewer gets the diff + plan, never the implementation conversation.
-5. **Release is a script.** `scripts/release.sh` owns release preconditions, versioning, changelog assembly, the release commit, tag, and local fast-forward merge. It never pushes.
+5. **Release is a script.** `scripts/release.sh` owns release preconditions, versioning, changelog assembly, and the release commit on the branch. It never pushes and never touches `main`; tagging happens in `/4-release` after the PR merges via `tag-after-merge`.
 
 ## Context tiers
 
diff --git a/config.yaml b/config.yaml
index 906edc83166366a7556ac002dd81216301f98e3a..0c6fe53d7df35ed60c70d2a88dea2a1da99ab640
--- a/config.yaml
+++ b/config.yaml
@@ -14,9 +14,6 @@
   # Claude Code implementer alternative:
   # command: 'claude -p --dangerously-skip-permissions'
 
-review:
-  human_pr_review: self      # self | platform-team
-
 gate:
   command: scripts/gate.sh
   max_retries: 2             # failed-gate feedback loops before escalating to the Owner
diff --git a/profiles/work.md b/profiles/work.md
index 047b6efdfa81e3d8ed0e0fa246144863ee6762b4..4496e556b94f00ebe837b804420788283ba70e90
--- a/profiles/work.md
+++ b/profiles/work.md
@@ -4,7 +4,6 @@
 
 ## Declarations required at /init
 
-- **Review topology** — set `review.human_pr_review` to `self` or `platform-team`.
 - **Implementer runtime** — when the workplace uses Claude Code for implementation, set `implementer.runtime: claude` and use:
 
 ```yaml
@@ -16,8 +15,7 @@
 ## Adds to the loop
 
 - **Jira:** Jira keys may be recorded as read-only references in `work/<slug>/plan.md`. The loop never creates or mutates Jira issues.
-- **Self review topology:** `scripts/release.sh` keeps the base release shape: it bumps `VERSION` and `CHANGELOG.md`, creates `vX.Y.Z`, fast-forwards local `main`, and stops before push. `/4-release` pushes `main` and the tag only after Owner confirmation.
-- **Platform-team review topology:** `scripts/release.sh` fetches `origin/main`, refuses when the release branch does not contain it, bumps `VERSION` and `CHANGELOG.md` on the release branch, creates no tag, and leaves local `main` untouched. `/4-release` pushes the release branch and prints the Bitbucket PR instruction; a platform engineer merges the PR.
+- **Release:** use the base PR-merge release flow.
 
 ## Gate
 
@@ -26,15 +24,3 @@
 - Add `bitbucket-pipelines.yml`.
 - Delete `.github/workflows/ci.yml`.
 - Keep the deterministic commands equivalent: install `shellcheck`, set a git identity, run `bash tests/test-scripts.sh`, then run `bash scripts/gate.sh`.
-
-## Platform-team release sync
-
-The platform-team release path treats remote `origin/main` as the current source of truth. `scripts/release.sh` fetches it before and after the gate, then refuses with a rebase/sync message if the release branch is stale.
-
-Keep the local `main` worktree pulled from the PR-merged remote before cutting new work. The required `main` worktree check only proves the linked worktree exists; it does not prove local `main` is current, because the release guard checks `origin/main`.
-
-Tagging is permanently manual in platform-team mode. If a tag is wanted after the Bitbucket PR merges, run:
-
-```sh
-git tag vX.Y.Z <merge-commit> && git push origin vX.Y.Z
-```
diff --git a/scripts/release.sh b/scripts/release.sh
index ce19d803956becc2b39b89e57262cb47e44dd359..4e421de6d2c68f9095c6e73232b7e5e4c1e01670
--- a/scripts/release.sh
+++ b/scripts/release.sh
@@ -8,12 +8,15 @@
   cat <<'EOF'
 Usage:
   scripts/release.sh <slug> [--confirm-delta <text>]
+  scripts/release.sh tag-after-merge <slug>
   scripts/release.sh check-version <new-version> [current-version]
   scripts/release.sh next-version [current-version]
 
-The full release path never pushes. In self-review mode it commits, tags,
-fast-forward merges to local main, then stops for the Owner-confirmed push step.
-In platform-team mode it commits the bump on the release branch for PR review.
+The release path never pushes, never tags, and never touches main. It commits
+the version bump on the release branch for PR review.
+
+After the PR merges, tag-after-merge verifies origin/main is the release commit
+and creates the local version tag. The tag push is a separate confirmed step.
 EOF
 }
 
@@ -159,27 +162,6 @@
   git -C "$checkout" diff --cached --quiet || die "$label has staged changes"
   [[ -z "$(git -C "$checkout" ls-files --others --exclude-standard)" ]] \
     || die "$label has untracked files"
-}
-
-check_ff_possible() {
-  local main_checkout="$1"
-  local release_branch="$2"
-
-  git -C "$main_checkout" rev-parse --verify --quiet "$release_branch" >/dev/null \
-    || die "missing release branch: $release_branch"
-  git -C "$main_checkout" merge-base --is-ancestor main "$release_branch" \
-    || die "main cannot fast-forward to $release_branch"
-}
-
-human_pr_review_mode() {
-  local mode
-
-  mode=$(awk '/^review:/{f=1;next} f&&/human_pr_review:/{print $2; exit}' config.yaml)
-  mode=${mode:-self}
-  case "$mode" in
-    self|platform-team) printf '%s\n' "$mode" ;;
-    *) die "invalid review.human_pr_review '$mode' (expected self or platform-team)" ;;
-  esac
 }
 
 check_origin_main_ancestor() {
@@ -195,13 +177,11 @@
 rollback_release() {
   local status=$?
   local pre_release_head="$1"
-  local new_version="$2"
 
   trap - ERR
   set +e
-  git tag -d "v$new_version" >/dev/null 2>&1
   git reset --hard "$pre_release_head" >/dev/null 2>&1
-  echo "release: irreversible step failed; release commit and tag changes were rolled back" >&2
+  echo "release: irreversible step failed; release commit was rolled back" >&2
   exit "$status"
 }
 
@@ -210,15 +190,13 @@
   local confirm_delta="$2"
   local plan_path="work/$slug/plan.md"
   local release_branch="wt/$slug"
-  local main_checkout
   local release_checkout
   local current_version
   local new_version
   local release_note
   local pre_release_head
-  local review_mode
 
-  main_checkout=$(worktree_for_branch main) \
+  worktree_for_branch main >/dev/null \
     || die "main must be checked out in the primary worktree"
   release_checkout=$(worktree_for_branch "$release_branch") \
     || die "$release_branch must be checked out in a linked worktree"
@@ -229,64 +207,75 @@
   cd "$release_checkout"
   current_version=$(<VERSION)
   new_version=$(next_version "$current_version")
-  review_mode=$(human_pr_review_mode)
 
   check_verdict "$plan_path"
   check_clean_worktree "$release_checkout" "$release_branch"
-  check_clean_worktree "$main_checkout" "main checkout"
-  if [[ "$review_mode" == self ]]; then
-    check_ff_possible "$main_checkout" "$release_branch"
-    git rev-parse --verify --quiet "refs/tags/v$new_version" >/dev/null \
-      && die "tag v$new_version already exists"
-  else
-    check_origin_main_ancestor "$release_branch"
-  fi
+  check_origin_main_ancestor "$release_branch"
   check_gate
   check_clean_worktree "$release_checkout" "$release_branch"
   check_archi_fresh
   check_version_exceeds "$new_version" "$current_version"
-  check_clean_worktree "$main_checkout" "main checkout"
-  if [[ "$review_mode" == self ]]; then
-    check_ff_possible "$main_checkout" "$release_branch"
-  else
-    check_origin_main_ancestor "$release_branch"
-  fi
+  check_origin_main_ancestor "$release_branch"
 
   release_note=$(extract_release_note "$plan_path")
   pre_release_head=$(git rev-parse HEAD)
-  trap 'rollback_release "$pre_release_head" "$new_version"' ERR
+  trap 'rollback_release "$pre_release_head"' ERR
 
   printf '%s\n' "$new_version" >VERSION
   prepend_changelog "$new_version" "$release_note" "$confirm_delta"
 
   git add VERSION CHANGELOG.md
   git commit -m "Release v$new_version"
-  if [[ "$review_mode" == self ]]; then
-    git tag "v$new_version"
-    git -C "$main_checkout" merge --ff-only "$release_branch"
-  fi
   trap - ERR
 
-  if [[ "$review_mode" == self ]]; then
-    cat <<EOF
-release: prepared v$new_version on local main
-release: stopped before push; push requires Owner confirmation in-session
-EOF
-  else
-    cat <<EOF
+  cat <<EOF
 release: prepared v$new_version on $release_branch
 release: no tag created; local main untouched
-release: push $release_branch, open a Bitbucket PR, and have a platform engineer merge it
+release: push $release_branch, open a PR, and merge it after review
 EOF
-  fi
 }
 
+tag_after_merge() {
+  local slug="$1"
+  local release_branch="wt/$slug"
+  local release_checkout
+  local version
+  local origin_version
+  local origin_subject
+
+  release_checkout=$(worktree_for_branch "$release_branch") \
+    || die "$release_branch must be checked out in a linked worktree"
+  [[ -f "$release_checkout/VERSION" ]] || die "missing VERSION in $release_branch"
+
+  git fetch origin main
+  git rev-parse --verify --quiet origin/main >/dev/null \
+    || die "missing origin/main after fetch"
+
+  version=$(<"$release_checkout/VERSION")
+  origin_version=$(git show origin/main:VERSION) \
+    || die "origin/main does not contain VERSION"
+  origin_subject=$(git log -1 --format=%s origin/main)
+
+  [[ "$origin_version" == "$version" && "$origin_subject" == "Release v$version" ]] \
+    || die "origin/main is not Release v$version (VERSION is $origin_version; subject is '$origin_subject')"
+
+  git rev-parse --verify --quiet "refs/tags/v$version" >/dev/null \
+    && die "tag v$version already exists"
+
+  git tag "v$version" origin/main
+  printf 'release: created local tag v%s on origin/main\n' "$version"
+}
+
 if [[ $# -eq 0 ]]; then
   usage
   exit 2
 fi
 
 case "$1" in
+  tag-after-merge)
+    [[ $# -eq 2 ]] || { usage; exit 2; }
+    tag_after_merge "$2"
+    ;;
   check-version)
     [[ $# -eq 2 || $# -eq 3 ]] || { usage; exit 2; }
     current=${3:-$(<VERSION)}
diff --git a/tests/test-scripts.sh b/tests/test-scripts.sh
index 77e929164770e68220eefdedb0591fc9e25e1f0b..473311694d7e6564bdac487d41e2a595aa54d116
--- a/tests/test-scripts.sh
+++ b/tests/test-scripts.sh
@@ -58,7 +58,6 @@
   local verdict_line="$3"
   local gate_mode="$4"
   local archi_mode="$5"
-  local review_mode="${6:-self}"
   local tmp_root="$TMP/$name"
 
   REL_PRIMARY="$tmp_root/primary"
@@ -93,11 +92,7 @@
 echo "GATE: PASS"
 EOF
     chmod +x scripts/release.sh scripts/gate.sh
-    {
-      printf 'name: fixture\n'
-      printf 'review:\n'
-      printf '  human_pr_review: %s\n' "$review_mode"
-    } >config.yaml
+    printf 'name: fixture\n' >config.yaml
     printf 'merge rules\n' >CLAUDE.md
     printf '%s\n' "$version" >VERSION
     printf '# Changelog\n\nAll notable changes to this project are documented in this file.\n\n' >CHANGELOG.md
@@ -173,52 +168,21 @@
 setup_release_fixture release-version-regresses 2026.9.0 "Code-review verdict: APPROVE" pass fresh
 check_fails "release refuses when computed version does not exceed VERSION" bash -c "cd '$REL_WORKTREE' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo"
 
-setup_release_fixture release-happy 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-origin_before=$(git -C "$REL_PRIMARY" rev-parse origin/main)
-check "release happy path lands fast-forward on primary main and stops before push" bash -c "
-  cd '$REL_WORKTREE' &&
+setup_release_fixture release-happy-primary 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+main_before=$(git -C "$REL_PRIMARY" rev-parse main)
+check "release can be invoked from primary checkout" bash -c "
+  cd '$REL_PRIMARY' &&
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
-  [ \"\$(git -C '$REL_PRIMARY' branch --show-current)\" = main ] &&
-  [ \"\$(cat '$REL_PRIMARY/VERSION')\" = 2026.8.10 ] &&
-  git -C '$REL_PRIMARY' merge-base --is-ancestor wt/demo main &&
-  git -C '$REL_PRIMARY' rev-parse --verify --quiet refs/tags/v2026.8.10 &&
-  [ \"\$(git -C '$REL_PRIMARY' rev-parse origin/main)\" = '$origin_before' ]
-"
-
-setup_release_fixture release-tag-race-rolls-back 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-release_head_before=$(git -C "$REL_WORKTREE" rev-parse HEAD)
-real_git=$(command -v git)
-tag_fail_bin="$TMP/tag-fail-bin"
-mkdir -p "$tag_fail_bin"
-cat >"$tag_fail_bin/git" <<EOF
-#!/usr/bin/env bash
-if [[ "\$1" == tag && "\${2:-}" == v2026.8.10 ]]; then
-  "$real_git" tag v2026.8.10 HEAD~1
-fi
-"$real_git" "\$@"
-EOF
-chmod +x "$tag_fail_bin/git"
-check "release rolls back cleanly when tag creation fails after prechecks" bash -c "
-  cd '$REL_WORKTREE' &&
-  PATH='$tag_fail_bin:$REL_FAKEBIN':\$PATH bash scripts/release.sh demo >/dev/null 2>&1 &&
-  exit 1
-  status=\$?
-  [ \"\$status\" -ne 0 ] &&
-  [ \"\$(git rev-parse HEAD)\" = '$release_head_before' ] &&
-  [ \"\$(cat VERSION)\" = 2026.8.9 ] &&
-  git diff --quiet &&
-  git diff --cached --quiet &&
-  [ -z \"\$(git ls-files --others --exclude-standard)\" ] &&
-  ! git rev-parse --verify --quiet refs/tags/v2026.8.10
+  [ \"\$(git -C '$REL_PRIMARY' rev-parse main)\" = '$main_before' ] &&
+  [ \"\$(cat '$REL_PRIMARY/VERSION')\" = 2026.8.9 ] &&
+  [ \"\$(cat '$REL_WORKTREE/VERSION')\" = 2026.8.10 ] &&
+  ! git -C '$REL_WORKTREE' rev-parse --verify --quiet refs/tags/v2026.8.10
 "
-
-setup_release_fixture release-happy-primary 2026.8.9 "Code-review verdict: APPROVE" pass fresh
-check "release can be invoked from primary checkout" bash -c "cd '$REL_PRIMARY' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo && [ \"\$(cat VERSION)\" = 2026.8.10 ]"
 
-setup_release_fixture release-platform-single 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
+setup_release_fixture release-single 2026.8.9 "Code-review verdict: APPROVE" pass fresh
 origin_before=$(git -C "$REL_PRIMARY" rev-parse origin/main)
 main_before=$(git -C "$REL_PRIMARY" rev-parse main)
-check "platform-team release commits bump on branch without touching main or tagging" bash -c "
+check "release commits bump on branch without touching main, origin/main, or tagging" bash -c "
   cd '$REL_WORKTREE' &&
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
   [ \"\$(git -C '$REL_PRIMARY' rev-parse main)\" = '$main_before' ] &&
@@ -228,13 +192,13 @@
   ! git rev-parse --verify --quiet refs/tags/v2026.8.10
 "
 
-setup_release_fixture release-platform-sequential 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
-check "platform-team release refuses stale branch, then computes next micro after sync" bash -c "
+setup_release_fixture release-sequential 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+check "release refuses stale branch, then computes next micro after sync" bash -c "
   set -e
   cd '$REL_WORKTREE'
   PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo
   git push -q origin wt/demo:main
-  rel_b='$TMP/release-platform-sequential/b-wt'
+  rel_b='$TMP/release-sequential/b-wt'
   git -C '$REL_PRIMARY' branch wt/b main
   git -C '$REL_PRIMARY' worktree add -q \"\$rel_b\" wt/b
   git -C \"\$rel_b\" config user.email tester@example.com
@@ -243,7 +207,7 @@
   sed 's/# Demo/# B/' '$REL_WORKTREE/work/demo/plan.md' > \"\$rel_b/work/b/plan.md\"
   git -C \"\$rel_b\" add work/b/plan.md
   GIT_AUTHOR_DATE='2026-08-16T10:00:30Z' GIT_COMMITTER_DATE='2026-08-16T10:00:30Z' git -C \"\$rel_b\" commit -qm 'add b plan'
-  stale_out='$TMP/platform-stale.out'
+  stale_out='$TMP/release-stale.out'
   if PATH='$REL_FAKEBIN':\$PATH bash \"\$rel_b/scripts/release.sh\" b >\"\$stale_out\" 2>&1; then
     exit 1
   fi
@@ -257,15 +221,15 @@
   ! git rev-parse --verify --quiet refs/tags/v2026.8.11
 "
 
-setup_release_fixture release-platform-mid-gate 2026.8.9 "Code-review verdict: APPROVE" pass fresh platform-team
+setup_release_fixture release-mid-gate 2026.8.9 "Code-review verdict: APPROVE" pass fresh
 mkdir -p "$REL_WORKTREE/scripts/gate.d"
 cat >"$REL_WORKTREE/scripts/gate.d/move-origin-main.sh" <<EOF
 #!/usr/bin/env bash
 set -euo pipefail
 repo='$REL_PRIMARY'
-printf 'platform merge during gate\n' >> "\$repo/platform.txt"
-git -C "\$repo" add platform.txt
-GIT_AUTHOR_DATE='2026-08-16T10:02:00Z' GIT_COMMITTER_DATE='2026-08-16T10:02:00Z' git -C "\$repo" commit -qm 'platform merge during gate'
+printf 'merge during gate\n' >> "\$repo/remote-change.txt"
+git -C "\$repo" add remote-change.txt
+GIT_AUTHOR_DATE='2026-08-16T10:02:00Z' GIT_COMMITTER_DATE='2026-08-16T10:02:00Z' git -C "\$repo" commit -qm 'merge during gate'
 git -C "\$repo" push -q origin main
 EOF
 chmod +x "$REL_WORKTREE/scripts/gate.d/move-origin-main.sh"
@@ -274,15 +238,58 @@
   git add scripts/gate.d/move-origin-main.sh
   GIT_AUTHOR_DATE="2026-08-16T10:00:30Z" GIT_COMMITTER_DATE="2026-08-16T10:00:30Z" git commit -qm "add mid-gate hook"
 )
-check "platform-team release catches origin/main moving during gate" bash -c "
+check "release catches origin/main moving during gate" bash -c "
   cd '$REL_WORKTREE'
-  mid_gate_out='$TMP/platform-mid-gate.out'
+  mid_gate_out='$TMP/release-mid-gate.out'
   if PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo >\"\$mid_gate_out\" 2>&1; then
     exit 1
   fi
   grep -q 'rebase/sync your branch onto origin/main' \"\$mid_gate_out\"
 "
 
+setup_release_fixture release-tag-after-merge-happy 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+real_git=$(command -v git)
+push_log="$TMP/tag-after-merge-push.log"
+tag_guard_bin="$TMP/tag-after-merge-bin"
+mkdir -p "$tag_guard_bin"
+cat >"$tag_guard_bin/git" <<EOF
+#!/usr/bin/env bash
+if [[ "\$1" == push ]]; then
+  printf 'unexpected push\n' >> "$push_log"
+  exit 99
+fi
+"$real_git" "\$@"
+EOF
+chmod +x "$tag_guard_bin/git"
+check "tag-after-merge creates local tag on origin/main and pushes nothing" bash -c "
+  cd '$REL_WORKTREE' &&
+  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
+  git push -q origin wt/demo:main &&
+  PATH='$tag_guard_bin:$REL_FAKEBIN':\$PATH bash scripts/release.sh tag-after-merge demo &&
+  [ \"\$(git rev-parse refs/tags/v2026.8.10)\" = \"\$(git rev-parse origin/main)\" ] &&
+  [ ! -s '$push_log' ]
+"
+
+setup_release_fixture release-tag-after-merge-wrong-commit 2026.8.9 "Code-review verdict: APPROVE" pass fresh
+check "tag-after-merge refuses when origin/main advanced past the release" bash -c "
+  set -e
+  cd '$REL_WORKTREE'
+  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo
+  git push -q origin wt/demo:main
+  git -C '$REL_PRIMARY' fetch -q origin main
+  git -C '$REL_PRIMARY' reset -q --hard origin/main
+  printf 'next change\n' > '$REL_PRIMARY/after-release.txt'
+  git -C '$REL_PRIMARY' add after-release.txt
+  GIT_AUTHOR_DATE='2026-08-16T10:03:00Z' GIT_COMMITTER_DATE='2026-08-16T10:03:00Z' git -C '$REL_PRIMARY' commit -qm 'Next change'
+  git -C '$REL_PRIMARY' push -q origin main
+  wrong_out='$TMP/tag-after-merge-wrong.out'
+  if PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh tag-after-merge demo >\"\$wrong_out\" 2>&1; then
+    exit 1
+  fi
+  grep -q 'origin/main is not Release v2026.8.10' \"\$wrong_out\" &&
+  ! git rev-parse --verify --quiet refs/tags/v2026.8.10
+"
+
 # --- gate.sh runs and exits cleanly on this repo
 check "gate.sh runs on this repo" bash scripts/gate.sh
 

tokens used
52,409
Implemented and committed the PR-merge-only release topology.

Commit: `6ff6c42 Collapse release flow to PR merge topology`

Changed:
- Removed `review.human_pr_review` config and all self/direct-push release behavior.
- `scripts/release.sh` now commits only on `wt/<slug>`, never pushes, never tags during release, and never touches `main`.
- Added `scripts/release.sh tag-after-merge <slug>` with `origin/main` version/subject verification before local tag creation.
- Updated `/4-release`, `profiles/work.md`, and `CLAUDE.md` wording for the single PR flow.
- Updated smoke tests to remove self-mode coverage and add post-merge tag happy/wrong-commit tests.

Verification:
- `bash scripts/gate.sh` passed: 20 tests, 0 failures.
- Required greps for removed topology terms / `git push` in `scripts/release.sh` were clean.

Notes:
- I did not edit `PLAN.md` because your hard footprint list omitted it, even though the work-unit plan mentioned it.
- `work/pr-merge-topology/` remains untracked and unstaged as pre-existing/source handoff material.
