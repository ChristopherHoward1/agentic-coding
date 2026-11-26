Code review round 1 of your implementation of /Users/cboyfly/Documents/repos/agentic-coding/work/pr-release/plan.md raised blocking findings. You are resuming in the same worktree on branch wt/pr-release.

Failure output (both reviewers, round 1):
```
HIGH (code-reviewer) / MEDIUM (codex) — Most new test assertions are inert on macOS bash 3.2. A failing mid-function `[[ ... ]]` does not stop `bash -e` there (`bash -e -c '[[ 1 == 2 ]]; echo survived'` prints `survived`). Inert: `else [[ ! -e "$S/work/demo/pr.md" ]]`, every bare `[[ ]]` in the happy path (last line Reviewed-SHA, one Reviewed-SHA line, HEAD unchanged/empty porcelain, no VERSION/CHANGELOG/.last-released, origin for-each-ref unchanged), `[[ $status == 1 ]]` in tag-after-merge. `[[ $status -ne 0 ]] && grep -Fq ...` skips the grep when release exits 0. Proof: deleting the post-gate check_clean_worktree + HEAD==Reviewed-SHA re-check leaves the suite 306/306 green; gate-commit then exits 0 and writes pr.md.

HIGH (codex) — harness/skills/4-release/SKILL.md step 1 (registry) says run harness release, fill pr.md, push, open the PR; the stop-on-nonzero instruction is only in step 2, so following step 1 in order can push after a refused release.

LOW — step 2's Exit 0 bullet ("report the bump commit") is wrong for registry, which makes no commit.
LOW — work-slim.md: the unindented "Merge Loop PRs…" paragraph between list items 3 and 4 breaks the numbered list.
LOW — the happy path greps "Goal text." anywhere in pr.md rather than under `## Why`, and checks only the primary checkout's HEAD, not wt/demo's.
```

Fix:
- **Every assertion must be fatal on bash 3.2.** Use `[[ ... ]] || return 1`, the style `registry_flow` already uses, for every `[[ ]]` in your new test functions. Split each refusal check into two lines: `[[ $status -ne 0 ]] || return 1`, then `grep -Fq -- "$expected" "$REG/out" || return 1`. The same applies to `cmp` and every other check that must fail the case.
- **Prove it.** Temporarily delete the post-gate re-check lines in `release.sh`, confirm the suite now fails (the gate-commit and gate-untracked cases), then restore them. State in your summary that you did this.
- **`/4-release` step 1, registry mode:** the exit-code check comes right after `harness release <slug>`. On non-zero, report and stop before touching `pr.md`, pushing or opening a PR. Fix step 2's Exit 0 bullet so registry mode reports the `pr.md` path, not a bump commit.
- **`work-slim.md`:** make the merge-strategy text part of the Loop item, indented, so the numbered list stays intact.
- **Happy path test:** assert that `Goal text.` appears in the `## Why` section, and that `wt/demo`'s HEAD is unchanged.

Stay inside the plan's footprint. Re-run harness gate until it passes, then print an updated summary. If a failure cannot be fixed within the plan's scope, stop and explain why instead of working around it.
