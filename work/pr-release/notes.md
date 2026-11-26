# Notes — pr-release

## Implementer summary (dispatch 1)

Implemented registry release preparation and state tracking. Release checks the verdicts, reviewed SHA, worktree, integration base and gate before writing `pr.md`; state uses the locally fetched integration ref to determine when the reviewed SHA has merged. The review, release and profile guidance was updated.

`harness gate` passed, as did `harness archi-fresh wt/pr-release`. The required placeholder grep returned no matches.

Acceptance is **partial**: the new test covers the happy path, moved HEAD and no-fetch state behavior, but the full refusal and mid-gate test matrix was not added, and the reviewer mutation pins were not verified. No out-of-scope files were changed.

Gate PASS (283 / 6); archi-fresh 0; demo 0, output matched the plan.

## Followup 1 (missing refusal/mid-gate/integration test matrix)

Added the missing registry release tests in [test-scripts.sh](/Users/cboyfly/Documents/repos/agentic-coding-worktrees/pr-release/harness/tests/test-scripts.sh). They cover:

- Every requested pre-gate refusal, with a marker proving the gate did not run.
- Gate failure, stale and missing `ARCHI.md`, and commits or untracked files created during the gate.
- Both `origin/dev` base scenarios and the registry no-tags refusal.
- Happy-path PR contents, unchanged origin refs and work repo, and absence of release artifacts.
- Stale PR SHA, no-fetch state behavior, and done state after fetch.

The tests also check that refusals leave `pr.md` absent or preserve its existing bytes. No implementation changes were needed.

`harness gate` passes, including 306 script tests. The reviewer mutation pins remain unverified; the plan assigns those checks to the reviewer.

Gate PASS (306 / 6); demo 0. ARCHI healed on the branch (test-suite description) before review.

## Followup 2 (review round 1: inert bash 3.2 assertions, /4-release exit-code order, LOWs)

Updated the registry release tests so assertions fail reliably on Bash 3.2, including checks that the Goal text appears under `## Why` and that the worktree HEAD stays unchanged. Updated the release instructions to stop immediately on a non-zero exit, corrected the registry success report, and indented the Loop merge guidance.

For the requested mutation check, I temporarily removed the post-gate checks and confirmed that both `gate-commit` and `gate-untracked` failed. I restored the checks afterward.

`harness gate` passed: 306 script tests and 6 publish tests. No acceptance criteria remain partially met, and no additional issues were identified outside the plan’s scope.

Gate PASS (306 / 6); demo 0; ARCHI healed on the branch before round 2.

## Followup 3 (release PR CI failure: git 2.56 updates the tracking ref on a URL push)

Diagnosed with a throwaway draft PR (#90, closed, branch deleted) tracing registry_release_flow on Ubuntu. The Release v2026.11.5 commit was dropped from the branch per Decision 2026-10-09. The test now advances origin from a separate clone. Gate PASS; ARCHI healed.
