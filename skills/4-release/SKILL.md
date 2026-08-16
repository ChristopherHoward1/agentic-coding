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
   - Exit 0 → report the prepared version, tag, and local `main` state.
   - Non-zero → report the script output and stop.
4. **Push separately:** after the Owner confirms the push, push `main` and the new tag.

## Rules

- The release script is the source of truth for the release result.
- The push is a separate Owner-confirmed action.
