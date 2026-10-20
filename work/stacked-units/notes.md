Implemented stacked branching, shared review-base resolution, release guards with restack commands, fan refusal, tests, and targeted documentation. Changes remain unstaged.

Validation: ShellCheck 0.11.0, 265 script checks, architecture freshness, and the worktree gate all pass on Darwin with Bash 3.2.

Mutation evidence—all replacements confirmed present, original code absent, then restored:

- Removed F→main branch: `stack base merge` failed — Darwin.
- Removed F→parent branch: `stack base rebase` failed — Darwin.
- Replaced fork-point with current-ref merge-base: `stack rewrite amend` failed — Darwin.
- Replaced fork-point with newest-ancestor reflog walk: `stack rewrite squash` failed — Darwin.
- Inverted parent-plan presence check: `stack release unmerged` and `stack release landed` failed — Darwin.

No partially met criteria or out-of-scope observations. Demonstration remains with the orchestrator, per handoff.
