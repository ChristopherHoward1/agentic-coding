You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.
Follow its build-discipline section while staying inside the plan footprint.

Work unit: work/archi-fresh-in-review/plan.md  (read it in full; it is your source of truth)
Branch: wt/archi-fresh-in-review (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
- CREATE scripts/archi-fresh.sh — ref-aware ARCHI freshness check.
- MODIFY scripts/release.sh — replace the inline body of check_archi_fresh (lines ~118–130) with a call to scripts/archi-fresh.sh; keep the check_archi_fresh wrapper and its call site at release.sh:247.
- MODIFY skills/3-review/SKILL.md — add the post-verdict freshness step (details below).
- MODIFY tests/test-scripts.sh — add hermetic cases for archi-fresh.sh and confirm the existing release stale-ARCHI refusal still passes.
- Do NOT touch ARCHI.md. Its freshness line for archi-fresh.sh is the orchestrator's job in /3-review, not yours. (This unit intentionally dogfoods; leave ARCHI to the orchestrator.)

Key constraints:
- scripts/archi-fresh.sh contract:
  - Usage: `scripts/archi-fresh.sh [<ref>]`; default ref is HEAD. `--help`/`-h` prints usage documenting the ref arg and exits 0.
  - Compares the last-commit epoch of ARCHI.md against the newest last-commit epoch among the source paths: `scripts/ skills/ profiles/ config.yaml CLAUDE.md`, at <ref>, using `git log -1 --format=%ct <ref> -- <paths>`.
  - Preserve today's STRICT semantics: stale iff `archi_epoch < source_epoch`. Equal epochs PASS (a single commit touching both ARCHI and source is fresh).
  - Exit 0 = fresh. Exit 1 = stale, printing a message that names the newer source path(s) and says to refresh ARCHI on the branch. Exit 2 = either side has no git history at <ref> (mirrors today's "no git history" die).
  - `set -uo pipefail`; `cd` to repo root like the other scripts; must pass shellcheck.
  - Define the source path set ONCE, here. Do not duplicate it elsewhere.
- scripts/release.sh: the existing check_archi_fresh currently does the epoch comparison inline (release.sh ~118–130) and is called at ~247 after the script cd's into the worktree (~237), so a bare `scripts/archi-fresh.sh` there sees HEAD = the release branch. Replace the inline body with `scripts/archi-fresh.sh || die "ARCHI.md is stale; refresh it on the branch"` (keep a `|| die` wrapper so the `release: ` prefix and `set -e` behavior are preserved). Do not change the call site or the surrounding preconditions. The existing stale-ARCHI refusal test must still pass.
- skills/3-review/SKILL.md: insert a new step BETWEEN current step 6 (record the approved result on the worktree branch) and current step 7 (hand off to release). It must instruct the orchestrator: after both APPROVE sentinels are recorded, run `scripts/archi-fresh.sh wt/<slug>` from the primary checkout; if it reports stale (exit 1), make a targeted ARCHI.md edit on the wt/<slug> worktree describing the added/renamed/removed surface, commit it on the branch, run `scripts/worktree.sh sync-artifacts <slug>`, and re-run the check until fresh — THEN hand off. State explicitly that this ARCHI-freshness heal is EXEMPT from step-19's "you just became a writer → re-review is mandatory" rule (it is a description-sync of already-approved code, not a behavior change), so it does not spawn a fresh review round. Renumber following steps/rules as needed and keep cross-references (e.g. "the next step") correct.
- tests/test-scripts.sh: add hermetic cases for archi-fresh.sh — fresh (exit 0), stale (exit 1), equal-epoch passes, ref selects a specific branch's history, and missing-history (exit 2). Follow the existing hermetic-fixture style in that file (there is a fixture around lines 90–156 and the existing stale-ARCHI release refusal around 1546–1547). Reuse existing helpers; do not invent a new harness.

When done:
1. Run scripts/gate.sh from the repo root — it must pass (shellcheck + full smoke suite).
2. Commit your work on this branch with a clear message.
3. Print a final summary: what changed and why, criteria partially met (if any), out-of-scope observations.
