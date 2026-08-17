+
+- The release script is the source of truth for the release result.
+- The push is a separate Owner-confirmed action.

tokens used
73,041
Implemented and committed on `wt/trip-release`.

Commit: `37fc95e Add release stage`

Changed:
- Added `scripts/release.sh` with shell-enforced preconditions, numeric CalVer handling, changelog prepending, release commit/tag, local ff-merge, and no push.
- Added `/4-release` skill, `VERSION`, and `CHANGELOG.md`.
- Updated `CLAUDE.md` for confirm-then-push release authority, `Confirm-delta:`, and the 4-clean-release manual promotion rule.
- Updated plan/review templates for `Release note:` and exact `Verdict: APPROVE|REVISE`.

Verified:
- `bash scripts/gate.sh` passes.
- Sandbox demos covered missing verdict, gate failure, stale `ARCHI.md`, non-increasing computed version, `.9 -> .10` accepted, `.10 -> .9` refused, and happy-path local release artifacts.
- `grep -n "Owner's call" CLAUDE.md` returns nothing.
- Worktree is clean.

Partially met: none.

Out of scope noted: `work/trip-release/plan.md` still contains `Verdict: REVISE` in its Review section despite the handoff saying approved; I left it untouched because it was outside the allowed footprint.
