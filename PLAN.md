# Plan

One screen, always. Reasoning lives in work units — link, don't restate.

## Objective

An end-to-end agentic development framework for a solo developer: skills-driven plan/implement/review loop, mechanically enforced writer≠reviewer, deterministic gate, worktree isolation. Thin by design — framework work stops the moment real use stops demanding it.

## Now

- **Shipped:** v2026.8.6 `work/codex-reviewer` (dual-vendor review) · v2026.8.7 `work/retro-stage` (`/5-retro`; marker arms next release) · v2026.8.8 `work/loop-hardening` (marker byte-identity, main-bound codex reviewer, /5-retro resume+cleanup, null-dispatch detection). Reviewers on opus.
- Candidate: `agent-exec-noop-scope` — soften the null-dispatch guard so a clean-tree no-op re-dispatch doesn't hard-fail (`work/loop-hardening/retro.md`; small, may be a small-fix).
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
- 2026-08-27 — A plan-reviewer's "drop this marginal fix" is a cost signal: keeping a flagged-inert fix tends to spend its savings back as review-round churn (fix 3 drew 3 of 4 rounds) — `work/loop-hardening/retro.md`

## Risks

- Correlated validators: mitigated 2026-08-26 by the codex second reviewer (`work/codex-reviewer`); residual — orchestrator and Claude reviewer still share a vendor.
- The PR-merge flow's `tag-after-merge` verify assumes the PR lands as a fast-forward/rebase so `origin/main`'s tip stays the `Release v<version>` commit; a merge-commit or squash strategy would (correctly) fail the guard and block tagging.
