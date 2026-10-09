# Retro: docs-stage

Shipped v2026.10.0. Adds the `/docs` stage: codex/GPT writes documentation prose in a worktree, ships by the small-fix lane, and runs no gate and no self-review. Two review rounds. The release was messy because a pre-review version had already been merged to `main`.

## What did the gate miss that a reviewer caught?

Gaps in prose contracts that a shell gate cannot see. Codex's HIGH: the skill never said how to fill the handoff placeholders, which would let the writer go out with no footprint boundary. Claude's MEDIUM: the handoff pointed the writer at AGENTS.md, whose gate rule contradicts "no gate". Both were fixed in `987973d`. The reviewers did their job, so this is **not worth keeping**.

## What did every check miss?

1. **The unreviewed implementation was merged to `main`.** PR #45 (`wt/docs-stage`, 2026-09-21) merged the round-0 implementation before `/3-review` ran. Review continued on the same branch, and its fixes, the ARCHI refresh and the review record (`64ddb70`) never reached `main`. Nothing stops a non-release PR from a `wt/<slug>` branch being merged. `release.sh`'s `Code-review verdict: APPROVE` check caught it, 18 days later. Recovery: the work was restored from `64ddb70` onto a fresh `wt/docs-stage` and released in PR #47. → **process**.
2. **The clean-up check said "fully landed" when it wasn't.** While cleaning worktrees on 2026-10-05, the orchestrator decided `wt/docs-stage` was on `main` and removed it along with its branch. Cause, checked in-session: an unquoted `$files` in zsh does not word-split, so the pathspec matched nothing and the empty diff was read as "nothing differs". → **contextual**.

## What got re-derived that a doc would have prevented?

Nothing.

## What friction repeated from a prior retro?

1. **`codex-review-printf-dash`, the 4th time.** Round 1 of codex's review ran without its severity definitions. Now fixed in PR #46 (small-fix, 2026-10-05), and its "Next" line is removed from `PLAN.md`.
2. **The codex sandbox still can't commit** (`index.lock: Operation not permitted`). This has happened in every codex unit since `ds-hygiene-hook`, which named `codex-worktree-commit` as a candidate. **Not worth keeping:** the loop already absorbs it, because `agent-exec.sh` accepts uncommitted changes and the orchestrator commits them. Dropping the candidate.

## Routing

- **process (applied):** a `PLAN.md` Decisions line saying a `wt/<slug>` branch reaches `main` only through its `/4-release` PR.
- **contextual (applied):** a new section in `knowledge/silent-no-op-hazards.md`, "An empty 'nothing differs' check".
- **small-fix (already shipped):** the printf fix in PR #46. Its `PLAN.md` Next line is removed and v2026.10.0 is added to Shipped.
- **not worth keeping:** the reviewer-caught prose gaps (reviewers working as designed) and `codex-worktree-commit` (the loop absorbs it).
