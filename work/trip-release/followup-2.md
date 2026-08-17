Review round 2 of your implementation of work/trip-release/plan.md returned REVISE. Round-1 fixes all verified correct. You are resuming in the same worktree on branch wt/trip-release. Two findings to fix; stay inside the plan's footprint.

```
1. (High) skills/3-review/SKILL.md step 5 still reads: "Hand to the Owner: verdict,
   findings summary..., gate status, and the merge command. The Owner merges; you
   never do." This contradicts the new CLAUDE.md merge-authority model this unit
   introduces (orchestrator releases via /4-release with one Owner confirm before
   push). The plan's Goal requires no surviving contradictory sentence anywhere.
   Rewrite step 5 to hand off to /4-release under the new model: on APPROVE, report
   verdict + findings + gate status to the Owner and proceed to /4-release (which
   itself stops for the Owner's push confirm). Check the rest of the file for any
   other sentence that assumes Owner-performed merges.

2. (Medium) scripts/release.sh:210-225 rollback only covers ff-merge failure. If
   `git commit` fails (hook, disk) or `git tag` fails (race after the existence
   check), set -e aborts before the rollback block, leaving a dirty tree or a
   committed-but-untagged release commit. Make cleanup cover the whole irreversible
   section — e.g. a trap-based rollback armed after preconditions pass and disarmed
   on success, restoring $pre_release_head and deleting the tag if present. Add a
   test exercising at least one of these mid-sequence failures (e.g. force `git tag`
   to fail via a pre-existing tag injected after checks, or a failing hook) and
   assert the worktree is left clean at pre-release state.
```

Non-blocking nit, fix if trivial: stray leading whitespace inside CLAUDE.md's fenced loop diagram.

Re-run scripts/gate.sh until it passes, then TRY to commit; if the sandbox again cannot write the git index, leave the working tree in its final state and say so in your summary — the orchestrator will commit. Print an updated summary.
