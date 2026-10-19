# Implementer notes — harness-registry

Dispatch 1: no changes; codex stopped asking to authorize adding HARNESS_HOME to the existing cleanup trap (plan-required). Handoff amended to authorize it.

## Dispatch 2 final summary
119,021
Implemented registry state resolution, `register`/`project` commands, script integration, documentation, and hermetic tests.

Validation passed: shellcheck, 227 smoke cases, 12 export cases, all seven mutation pins, `harness gate`, and ARCHI freshness.

Direct demonstration output:

```text
register_exit=0
state=hh/projects/repo-app mode=registry
local_md=@hh/projects/repo-app/CLAUDE.md
porcelain=[]
branch_files=app/ok.sh bad.sh
▶ shellcheck ok.sh
GATE: PASS
app
demo_exit=0
release: registry mode has no release script yet (pr-release); open the PR by hand
release_exit=1
```

Left unstaged under the handoff’s git-index restriction. The orchestrator still owns the commit, installed-copy demo rerun, and manual `/memory` check.

Out of scope: example hygiene hooks still scan the git toplevel; this limit is documented.
