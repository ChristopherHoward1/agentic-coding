Finding: HIGH - `scripts/codex-review.sh` does not actually fall back on fetch failure when an `origin/main` ref already exists.

The plan says a failed `git fetch origin --quiet` should proceed to the fallback, and the goal calls for a freshly fetched `origin/main` with a defined fallback when fetch fails. The implementation discards fetch failure with `|| true`, then still selects `origin/main` whenever `refs/remotes/origin/main` exists:

```sh
git fetch origin --quiet 2>/dev/null || true
if git show-ref --verify --quiet refs/remotes/origin/main; then
  base=origin/main
else
  base=main
fi
```

Concrete failure scenario: a repo has a stale `refs/remotes/origin/main` from an earlier fetch, but the current review run cannot fetch due to network/auth failure. The script will diff against that stale remote-tracking ref, not freshly fetched `origin/main` and not the documented local-`main` fallback. That violates the plan’s stated behavior and can still produce a polluted or incorrect review diff.

A minimal fix is to record fetch success and only use `origin/main` when both fetch succeeded and the ref exists; otherwise use `main`. Add a hermetic test with an existing stale `origin/main` plus a fetch failure to lock this down.

Codex verdict: REQUEST CHANGES
