# Profile: work

For workplace repositories that use Atlassian/Bitbucket review and CI conventions while keeping this template as the single source.

## Declarations required at /init

- **Implementer runtime** — when the workplace uses Claude Code for implementation, set `implementer.runtime: claude` and use:

```yaml
implementer:
  runtime: claude
  command: 'claude -p --dangerously-skip-permissions'
```

## Adds to the loop

- **Jira:** Jira keys may be recorded as read-only references in `work/<slug>/plan.md`. The loop never creates or mutates Jira issues.
- **Release:** use the base PR-merge release flow.

## Gate

Replace GitHub Actions with Bitbucket Pipelines during /init:

- Add `bitbucket-pipelines.yml`.
- Delete `.github/workflows/ci.yml`.
- Keep the deterministic commands equivalent: install `shellcheck`, set a git identity, run `bash tests/test-scripts.sh`, then run `bash scripts/gate.sh`.
