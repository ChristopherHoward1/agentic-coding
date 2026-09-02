# Plan

One screen, always. Reasoning lives in work units — link, don't restate.

## Objective

An end-to-end agentic development framework for a solo developer: skills-driven plan/implement/review loop, mechanically enforced writer≠reviewer, deterministic gate, worktree isolation. Thin by design — framework work stops the moment real use stops demanding it.

## Now

- **Shipped:** v2026.9.0 `work/exec-state` (`scripts/state.sh` — read-only per-work-unit execution-state deriver: stage/review/next_action from observable facts) · v2026.8.11 `work/work-artifact-capture` (`sync-artifacts`; reviewer diff excludes unit artifacts) · v2026.8.10 `work/gate-tool-preflight` (gate reports skipped checks; `gate.required_tools` hard-fail) · v2026.8.6 `work/codex-reviewer` (dual-vendor review) · v2026.8.7 `work/retro-stage` (`/5-retro`; marker arms next release) · v2026.8.8 `work/loop-hardening` (marker byte-identity, main-bound codex reviewer, /5-retro resume+cleanup, null-dispatch detection) · v2026.8.9 `work/ds-hygiene-hook` (opt-in DS hygiene gate hook; ML + work profiles wired). Reviewers on opus.
- Candidate: `agent-exec-noop-scope` — soften the null-dispatch guard so a clean-tree no-op re-dispatch doesn't hard-fail (`work/loop-hardening/retro.md`; small, may be a small-fix).
- Candidate: `review-diff-base-origin-main` — base the `/3-review` + `codex-review.sh` diff on a freshly-fetched `origin/main`, not local `main`, so a stale local `main` can't pollute the review diff (`work/exec-state/retro.md`).
- Candidate: `codex-review-printf-dash` — quote the `printf` format args in `codex-review.sh` (≈ lines 106–109 emit `printf: - : invalid option`, silently dropping reviewer-prompt lines) (`work/exec-state/retro.md`; small-fix).
- **Full TRIP autonomy reached** (2026-08-25): 4/4 `none` releases (2026.8.1–2026.8.4); `/4-release` push confirmation removed from CLAUDE.md.
- Remaining candidate: `/2-implement` batching — deferred until real use demands it.

## Decisions

- 2026-08-15 — No custom runtime; Claude Code is the orchestrator (Overstory's archival was the cautionary tale) — `3b80c19`
- 2026-08-15 — Gate is a shell script with an exit-code contract; agents never overrule it — `3b80c19`
- 2026-08-15 — knowledge/ starts empty; docs earn their way in — `3b80c19`
- 2026-08-16 — Merge autonomy: confirm-then-push (C), auto-promoting to full TRIP (A) after 4 releases where the confirm changed nothing — `work/trip-release`
- 2026-08-16 — CalVer, not SemVer; all release preconditions enforced by `release.sh` exit codes, never skill prose — `work/trip-release`
- 2026-08-16 — Release validates ARCHI freshness but never regenerates it; `/compact` stays the only ARCHI pipeline — `work/trip-release`
- 2026-08-24 — `work` profile for Atlassian/Bitbucket: config-selected release topology (self ff-merges main; platform-team fetch-guards `origin/main` + pushes a branch for PR), one template not a fork — `work/work-profile` *(topology superseded 2026-08-25)*
- 2026-08-25 — One universal PR-merge release topology under protected `main`; `self` direct-push + `review.human_pr_review` knob removed; tagging moves post-merge to `release.sh tag-after-merge` (verify-then-tag, no push) — `work/pr-merge-topology`
- 2026-08-26 — /5-retro stage; release.sh refuses unit N until unit N−1's retro exists non-empty — work/retro-stage
- 2026-08-26 — README loop/skills sections are release-note-owned: checked at /4-release step 3, fixed via the small-fix path — `work/retro-stage/retro.md`
- 2026-08-26 — codex reviewer command is main-bound (branch config cannot choose the reviewer binary); marker byte-identity vs origin/main — work/loop-hardening
- 2026-08-27 — A test asserting a guard exists is not done until it has been shown to fail with that guard removed; a green suite cannot distinguish a real case from a vacuous one — `knowledge/test-helper-contract.md`, `work/ds-hygiene-hook/retro.md`
- 2026-08-27 — A handoff citing a `PLAN.md` decision must also name the `knowledge/` doc that says how to satisfy it; cold-tier docs load on citation only, so an uncited doc does not exist for a cold implementer — `work/gate-tool-preflight/retro.md`
- 2026-08-27 — A plan-reviewer's "drop this marginal fix" is a cost signal: keeping a flagged-inert fix tends to spend its savings back as review-round churn (fix 3 drew 3 of 4 rounds) — `work/loop-hardening/retro.md`
- 2026-09-01 — A unit that adds/renames a `scripts/` or `skills/` file must refresh `ARCHI.md` **on the release branch** with a targeted edit: `release.sh` checks ARCHI freshness on the branch, and `/compact` from a `main` checkout cannot describe branch-only code, so "run /compact" is not the remedy here — `work/exec-state/retro.md`
- 2026-08-28 — A guard is not pinned until a mutation to it has been shown to fail the suite **and** that mutation was verified to have landed; writing the doc then citing the doc did not stop a third consecutive unit shipping unpinned guards, while reviewer-run mutation testing caught every one — `knowledge/silent-no-op-hazards.md`, `work/work-artifact-capture/retro.md`

## Risks

- Correlated validators: mitigated 2026-08-26 by the codex second reviewer (`work/codex-reviewer`); residual — orchestrator and Claude reviewer still share a vendor.
- The PR-merge flow's `tag-after-merge` verify assumes the PR lands as a fast-forward/rebase so `origin/main`'s tip stays the `Release v<version>` commit; a merge-commit or squash strategy would (correctly) fail the guard and block tagging.
