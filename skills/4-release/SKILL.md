---
name: 4-release
description: Run the release script for a work unit, then handle the separate Owner-confirmed push.
---

# /4-release — release

Input: a work unit slug.

## Steps

1. **Confirm intent:** ask the Owner for the in-session release confirmation and capture the `Confirm-delta:` value.
2. **Run the release script:** from the repo root, run `bash scripts/release.sh <slug> --confirm-delta "<value>"`.
3. **React to the exit code:**
   - Exit 0 → report the bump commit on the release branch, that no tag exists yet, and that `main` was untouched.
   - Non-zero → report the script output and stop.
4. **Push the release branch:** after the Owner confirms the push, push the release branch, print instructions to open a PR and get it merged, and never push `main`.
5. **Tag after merge:** once the Owner confirms the PR has merged, run `bash scripts/release.sh tag-after-merge <slug>`. If it exits non-zero, report the output and stop. If it succeeds, ask the Owner to confirm pushing the new tag, then run `git push origin v<version>`.

## Rules

- The release script is the source of truth for the release result.
- The push is a separate Owner-confirmed action.
