---
name: 4-release
description: Run the release script for a work unit, then handle the separate Owner-confirmed push.
---

# /4-release — release

Input: a work unit slug.

## Steps

1. **Confirm intent:** ask the Owner for the in-session release confirmation and capture the `Confirm-delta:` value.
2. **Run the release script:** from the repo root, run `bash scripts/release.sh <slug> --confirm-delta "<value>"`.
3. **React to the exit code based on `review.human_pr_review`:**
   - Exit 0 with `self` → report the prepared version, tag, and local `main` state.
   - Exit 0 with `platform-team` → report the bump commit on the release branch, that no tag was created, and that local `main` was untouched.
   - Non-zero → report the script output and stop.
4. **Push separately based on `review.human_pr_review`:**
   - `self` → after the Owner confirms the push, push `main` and the new tag.
   - `platform-team` → after the Owner confirms the push, push the release branch, print instructions to open a Bitbucket PR, and never push `main`.

## Rules

- The release script is the source of truth for the release result.
- The push is a separate Owner-confirmed action.
