Code review returned REQUEST CHANGES on your implementation of work/codex-reviewer/plan.md. You are resuming in the same worktree on branch wt/codex-reviewer. (The gate is green — these are review findings the gate does not cover. Two independent reviewers, one Claude and one codex, reviewed the diff.)

Findings to fix, most severe first:

```
1. scripts/codex-review.sh:66,68 — the `|| exit 2` guards are dead code. The { ... }
   group is the left side of a pipeline, so it runs in a subshell; `exit 2` kills only
   the subshell. Reproduced: a plan path missing from the branch prints the git error
   but the script continues, the reviewer gets a prompt with instructions and nothing
   else, and its answer becomes the verdict (observed exit 0 / APPROVE for a review of
   nothing). Fix: build the prompt into a variable or temp file BEFORE invoking the
   reviewer, checking each `git show` status directly (no pipeline), and exit 2 with a
   distinct stderr message if either fails.

2. scripts/codex-review.sh:69 — the reviewer command's exit status is unchecked (both
   reviewers flagged this independently). A reviewer that crashes mid-stream can leave
   a trailing "Codex verdict: APPROVE" (e.g. quoted from its own prompt) and the
   failure is invisible; a command that isn't on PATH exits 127 but gets misdiagnosed
   as "no verdict in output". Capture the reviewer's exit status (PIPESTATUS or run it
   without a pipeline) and exit 2 with a "reviewer command failed (exit N)" stderr
   message before any verdict parsing when it is non-zero.

3. scripts/codex-review.sh:65 — `printf '--- PLAN ...'` fails on every run: printf
   parses the leading `--` as an option terminator, prints "printf: --: invalid
   option" to stderr, and the PLAN delimiter is never emitted (the reviewer sees plan
   and diff concatenated with no boundary). Use `printf '%s\n' "..."` or
   `printf -- '...'`. Check the DIFF delimiter line for the same hazard.

4. Add hermetic test cases for 1 and 2: (a) slug whose branch lacks the plan file →
   exit 2 + distinct stderr substring, no reviewer invocation; (b) canned reviewer
   that prints an APPROVE line and then exits non-zero → exit 2 ("reviewer command
   failed"), not 0.

Non-blocking nits — fix cheaply while in the file, none require design changes:
   - rename local `command` variable to `reviewer_command`;
   - awk comment-stripping runs before quote removal, so a `#` inside the quoted
     command would truncate it (guard or note it);
   - tests/test-scripts.sh:130: `[[ -n "$x" ]] && printf ...` leaves status 1 when
     empty — make it an if, so a future `set -e` doesn't trip.
```

Stay inside the plan's footprint. Re-run scripts/gate.sh until it passes, commit the fix, and print an updated summary. If a failure cannot be fixed within the plan's scope, stop and explain why instead of working around it.
