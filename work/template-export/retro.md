# Retro — template-export (v2026.10.2)

## 1. What did the gate miss that a reviewer caught?

**The export depended on the caller's working directory (HIGH, round 1).** `git archive HEAD` and `git ls-tree -- template/` only act on the directory they run from. Run from `scripts/`, the export wrote a partial tree and still exited 0. Every gate case ran from the repo root. Both reviewers caught it independently, and a mutation-tested subdirectory case now pins the fix.
→ **not worth keeping**: the two-reviewer design caught it as intended, the test pins it, and the sibling scripts (`gate.sh`, `worktree.sh`) already move to the repo root.

## 2. What did every check miss?

**Shellcheck version skew between local and CI.** Locally (0.11.0), shellcheck reports test functions that are only called indirectly under SC2329. CI's apt build (0.9.0) reports the same pattern under SC2317. `tests/test-export.sh` disabled only SC2329. It passed the local gate, the demo, and two review rounds, then failed PR #51's CI twice: in the smoke suite's shellcheck case, and again in "gate.sh runs on this repo". So the gate isn't deterministic across environments: it reports whatever version of the tool happens to be installed. `gate.required_tools` checks that the tool exists but not which version.
→ **mechanical**, named here but not applied (it touches CI and/or `scripts/gate.sh`): candidate `ci-shellcheck-pin`. Pin CI to the same shellcheck version as local (a release binary instead of apt), or add a minimum-version preflight to the gate.

## 3. What got re-derived that a doc would have prevented?

**How to recover when a release PR's CI fails.** The `Release v<version>` commit has to stay at the tip, or `tag-after-merge` refuses, so a fix can't go on top of it. The orchestrator worked out the sequence on the spot:
1. drop the release commit on the branch
2. commit the fix
3. run a mandatory fresh review round, because the orchestrator wrote the fix
4. re-run `release.sh`
5. `--force-with-lease` push the PR branch

→ **process**: one line in `PLAN.md` Decisions.

## 4. What friction repeated from a prior retro?

**The orchestrator wrote `Plan verdict: APPROVE` itself, again.** It happened after applying round-2 REVISE findings, and the orchestrator reset the line before showing the plan to the Owner. `acceptance-demo/retro.md` #3 called this "not worth keeping" because invariant 1 covers it. A second occurrence shows the invariant alone isn't enough here.
→ **process**: one line in `PLAN.md` Decisions.

**README drift.** The 2026-08-26 decision says `/4-release` step 3 checks the README loop and skills sections, but `skills/4-release/SKILL.md` doesn't say so. So the check never ran: Layout is missing `/docs`, `demo.sh`, `state.sh`, `archi-fresh.sh` and `codex-review.sh`. This unit's own fold rule excluded the README decision as "dogfood-only". That was wrong, because the README ships in the template.
→ **mechanical**, named here but not applied (it touches `skills/` and `README.md`): a small fix requested by the Owner. Refresh README Layout without mentioning the export script, and add the README check to `/4-release` step 3.

**The codex sandbox can't commit (fifth unit in a row).** The orchestrator committed after the gate and ran the demo itself.
→ already tracked as candidate `codex-worktree-commit`, so it is not routed again here.
