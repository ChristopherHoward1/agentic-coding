Implemented stacked branching, shared review-base resolution, release guards with restack commands, fan refusal, tests, and targeted documentation. Changes remain unstaged.

Validation: ShellCheck 0.11.0, 265 script checks, architecture freshness, and the worktree gate all pass on Darwin with Bash 3.2.

Mutation evidence—all replacements confirmed present, original code absent, then restored:

- Removed F→main branch: `stack base merge` failed — Darwin.
- Removed F→parent branch: `stack base rebase` failed — Darwin.
- Replaced fork-point with current-ref merge-base: `stack rewrite amend` failed — Darwin.
- Replaced fork-point with newest-ancestor reflog walk: `stack rewrite squash` failed — Darwin.
- Inverted parent-plan presence check: `stack release unmerged` and `stack release landed` failed — Darwin.

No partially met criteria or out-of-scope observations. Demonstration remains with the orchestrator, per handoff.

## Demo (orchestrator, exit 0)

```
Preparing worktree (new branch 'wt/p')
branch 'wt/p' set up to track 'origin/main'.
HEAD is now at 2256158 init
Preparing worktree (new branch 'wt/c')
HEAD is now at d31e02f parent
base while p unmerged: wt/p
diff files: child.txt 
base after p amended: fork-point SHA (note printed)
diff files: child.txt 
base after merge-commit landing of amended p: fork-point SHA
diff files: child.txt 
```
