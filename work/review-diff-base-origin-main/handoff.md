You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.
Follow its build-discipline section while staying inside the plan footprint.

Work unit: work/review-diff-base-origin-main/plan.md  (read it in full; it is your source of truth)
Branch: wt/review-diff-base-origin-main (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
- MODIFY scripts/codex-review.sh — base the review diff on freshly-fetched origin/main with a local-main fallback (details below).
- MODIFY skills/3-review/SKILL.md — step 1 diff prose: fetch + origin/main...wt/<slug>.
- MODIFY tests/test-scripts.sh — update one existing assertion (line ~846) and add two hermetic cases (details below).
- Do NOT touch scripts/release.sh, and do NOT change the `git show "main:config.yaml"` reviewer-command read in codex-review.sh (lines ~35/63) — the config read deliberately STAYS on local `main` this unit. tests/test-scripts.sh:830 (the `git show "main:config.yaml"` assertion) and :1574 (fan-exec `main...wt/demo`) must stay unchanged and green.

Key constraints:
- scripts/codex-review.sh diff base:
  - Currently (lines ~98–100): `git diff "main...$branch" -- ':/' ":(exclude,top)work/$slug"` with a DIFF header line `--- DIFF (main...$branch excluding work/$slug) ---`.
  - Change to: before computing the diff, do a best-effort all-refs fetch `git fetch origin --quiet` (a failed fetch must NOT abort the review — do not let it kill the script; e.g. `git fetch origin --quiet || true`, mind `set -euo pipefail`). Then choose the base: `base=origin/main` if `git show-ref --verify --quiet refs/remotes/origin/main`, else `base=main` (offline / no-remote fallback = today's behavior). Use `$base` in BOTH the diff command and the DIFF header text.
  - Mirror worktree.sh's existing fetch/verify pattern exactly (all-refs `git fetch origin --quiet`, and `git show-ref --verify --quiet refs/remotes/origin/main`) — read scripts/worktree.sh `add` to match style.
  - The reviewer-command config read (`git show "main:config.yaml"`) is UNCHANGED — leave it on local `main`.
- skills/3-review/SKILL.md step 1: change the orchestrator-run diff prose from `git diff main...wt/<slug> -- ':/' ":(exclude,top)work/<slug>"` to fetch first (`git fetch origin --quiet`) and diff `origin/main...wt/<slug>` with the SAME pathspec `-- ':/' ":(exclude,top)work/<slug>"`. Keep the rest of the step's wording intact.
- tests/test-scripts.sh:
  - (a) Update the existing string-assertion around line 846 that greps skills/3-review/SKILL.md for the literal `git diff main...wt/<slug> -- ':/' ...` so it matches the NEW `origin/main...wt/<slug>` string. Find it (search for `main...wt/<slug>` near the "3-review skill keeps codex-review work artifacts out of diff" area) and update the expected string. Do NOT touch the assertion at line ~830 (`git show "main:config.yaml"`) or the fan-exec one at ~1574.
  - (b) Add two hermetic codex-review cases:
    1. Pollution-excluded: build a fixture with a BARE remote where origin/main is AHEAD of local main by a commit that changes a file the branch does NOT touch; run codex-review.sh and assert that file does NOT appear in the produced diff/prompt (i.e. the diff is scoped to the branch's own changes). This test MUST fail if the base were still `main...`. The current `setup_codex_review_fixture` (~line 222) builds no origin — you need a fixture with a bare remote; model it on the bare-remote pattern already in this file around lines 953–1026 (search for `NO_ORIGIN` / bare `git init --bare` / `STALE_REPO` patterns).
    2. No-remote fallback: with no origin/main ref, codex-review.sh still runs and bases on local `main`; assert it still produces the expected verdict/diff behavior (exit unchanged). Existing codex-review tests already implicitly exercise this (their fixture has no origin), so a targeted assertion is fine.
  - Reuse existing helpers (`check`, `check_exit`, the canned-reviewer setup). Do not invent a new harness. Follow the existing hermetic-fixture style.

When done:
1. Run scripts/gate.sh from the repo root — it must pass (shellcheck + full smoke suite).
2. Commit your work on this branch with a clear message.
3. Print a final summary: what changed and why, criteria partially met (if any), out-of-scope observations.
