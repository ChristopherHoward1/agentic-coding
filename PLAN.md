# Plan

One screen, always. Reasoning lives in work units — link, don't restate.

## Objective

An end-to-end agentic development framework for a solo developer: skills-driven plan/implement/review loop, mechanically enforced writer≠reviewer, deterministic gate, worktree isolation. Thin by design — framework work stops the moment real use stops demanding it.

## Now

- **Shipped 2026-08-26:** v2026.8.6 `work/codex-reviewer` (dual-vendor review, release-enforced) and v2026.8.7 `work/retro-stage` (`/5-retro`; marker arms next release). Reviewers on opus.
- Next candidate: `loop-hardening` — named in `work/retro-stage/retro.md` (marker guard/validation, /5-retro resume+cleanup, dispatch disconnect detection).
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

## Risks

- Correlated validators: mitigated 2026-08-26 by the codex second reviewer (`work/codex-reviewer`); residual — orchestrator and Claude reviewer still share a vendor.
- `reviewer.command` is executable branch content: an implementer could edit its own branch's `reviewer:` block to self-approve the codex gate. Mitigation today: the Claude reviewer sees `config.yaml` in the diff. Candidate hardening: `codex-review.sh` refuses when the branch's `reviewer:` block differs from `main`'s.
- The PR-merge flow's `tag-after-merge` verify assumes the PR lands as a fast-forward/rebase so `origin/main`'s tip stays the `Release v<version>` commit; a merge-commit or squash strategy would (correctly) fail the guard and block tagging.
