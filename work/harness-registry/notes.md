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

## Review round 1 followup

Normalized explicit `--subdir` values before directory checks, default naming, registry entries, and exclude patterns. Empty values and dot/dot-dot components fail before writes. Added hermetic normalization/rejection coverage and an external gate-hook marker that proves invocation and project cwd. Removed duplicate fixture library copies and corrected the review deferrals path.

Both requested mutations failed their targeted cases, with landing and restoration verified; see `mutations.md`.

Direct demonstration rerun from the worktree root (including register stderr):

```text
Owner: run /add-dir /private/var/folders/y6/cqq_kqw13z58pgr6c9f3fzdm0000gn/T/tmp.K6dmYO3lmz/hh/projects/repo-app or add it to permissions.additionalDirectories
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

The manual Claude `/memory` and `/add-dir` acceptance check remains with the orchestrator, as recorded above. Example hygiene hooks still scan the git toplevel; left out of scope. Changes remain unstaged for the orchestrator.

Validation: all four required direct commands passed (exit 0): shellcheck; `bash harness/tests/test-scripts.sh` (228 passed, 0 failed); `bash tests/test-export.sh` (12 passed, 0 failed); `bash harness/bin/harness gate` (`GATE: PASS`). `git diff --check` also passed.
