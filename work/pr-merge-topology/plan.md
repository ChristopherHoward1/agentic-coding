# PR-merge as the only release topology

**Slug:** pr-merge-topology · **Date:** 2026-08-25 · **Status:** implemented

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

**Code review (code-reviewer, APPROVE):** all acceptance criteria met; gate 20/20; footprint exactly the six declared files. Confirmed `tag-after-merge` fetches + verifies both `VERSION` and the `Release v<version>` subject before tagging locally and pushes nothing (F1 race closed, proven by a non-vacuous wrong-commit-refusal test); no `git push` anywhere in `release.sh` (invariant #5); the collision guard's before+after-gate double-call preserved; `release()` creates no tag and never mutates `main` (`main_checkout` reduced to the existence lookup, `check_clean_worktree` calls dropped, `rollback_release` simplified). No blocking findings.
Code-review verdict: APPROVE
