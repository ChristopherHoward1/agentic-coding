# Profile: work

For workplace repositories that use Atlassian/Bitbucket review and CI conventions while keeping this template as the single source.

## Declarations required at /init

- **Review topology** — set `review.human_pr_review` to `self` or `platform-team`.
- **Implementer runtime** — when the workplace uses Claude Code for implementation, set `implementer.runtime: claude` and use:

```yaml
implementer:
  runtime: claude
  command: 'claude -p --dangerously-skip-permissions'
```

## Adds to the loop

- **Jira:** Jira keys may be recorded as read-only references in `work/<slug>/plan.md`. The loop never creates or mutates Jira issues.
- **Self review topology:** `scripts/release.sh` keeps the base release shape: it bumps `VERSION` and `CHANGELOG.md`, creates `vX.Y.Z`, fast-forwards local `main`, and stops before push. `/4-release` pushes `main` and the tag only after Owner confirmation.
- **Platform-team review topology:** `scripts/release.sh` fetches `origin/main`, refuses when the release branch does not contain it, bumps `VERSION` and `CHANGELOG.md` on the release branch, creates no tag, and leaves local `main` untouched. `/4-release` pushes the release branch and prints the Bitbucket PR instruction; a platform engineer merges the PR.

## Gate

Replace GitHub Actions with Bitbucket Pipelines during /init:

- Add `bitbucket-pipelines.yml`.
- Delete `.github/workflows/ci.yml`.
- Keep the deterministic commands equivalent: install `shellcheck`, set a git identity, run `bash tests/test-scripts.sh`, then run `bash scripts/gate.sh`.

## Platform-team release sync

The platform-team release path treats remote `origin/main` as the current source of truth. `scripts/release.sh` fetches it before and after the gate, then refuses with a rebase/sync message if the release branch is stale.

Keep the local `main` worktree pulled from the PR-merged remote before cutting new work. The required `main` worktree check only proves the linked worktree exists; it does not prove local `main` is current, because the release guard checks `origin/main`.

Tagging is permanently manual in platform-team mode. If a tag is wanted after the Bitbucket PR merges, run:

```sh
git tag vX.Y.Z <merge-commit> && git push origin vX.Y.Z
```
