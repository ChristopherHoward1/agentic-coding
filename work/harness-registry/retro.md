# Retro — harness-registry (v2026.10.6)

1. **What did the gate miss that a reviewer caught?**
   - Both code reviewers caught `register --subdir ./app` writing a `/./app/` exclude line that git ignores, so the generated `CLAUDE.local.md` showed as untracked. The Claude reviewer also showed that the state-dir gate-hook test passed even with the hook path reverted. Both were fixed in one followup.
   - → **not worth keeping**: the existing 2026-08-28 Decision (reviewer-run mutation testing catches unpinned guards) worked exactly as written. There's nothing new to route.
2. **What did every check miss?**
   - The local gate (shellcheck 0.11), the implementer's checks and both review rounds all passed, but release PR #60 CI (apt shellcheck 0.9) failed. The new test functions disabled only `SC2329`, and 0.9 reports `SC2317`.
   - Recovery, per the 2026-10-09 Decision: drop the release commit, fix, run a third review round, re-release and force-push. That cost one review round.
   - This is the second time (after `template-export`). → **mechanical**: CI's `.github/workflows/ci.yml` is outside the retro file boundary, so the `ci-shellcheck-pin` candidate in `PLAN.md` now records the recurrence and is next in line for `/1-plan`.
3. **What got re-derived that a doc would have prevented?**
   - Plan review took 3 rounds and 26 findings. Three of the blocking ones were test-suite structure that each new plan re-derives from the code:
     - the gate fixtures' stripped `PATH` (no `dirname`)
     - fixtures copying scripts one at a time, so a sourced lib must be copied too, including the `wt.sh`-at-root fixture
     - static greps pinning literal strings in skills and scripts
   - → **contextual**: added "Adding a script, or a file that scripts source" to `knowledge/test-helper-contract.md`.
4. **What friction repeated from a prior retro?**
   - The codex sandbox git-index workaround, for the eighth unit in a row. Stating the recipe up front again gave zero gate retries.
   - New: dispatch 1 produced nothing. The handoff said "stop if any other test edit is needed", and codex stopped on an edit the plan itself required (adding `HARNESS_HOME` to the cleanup trap).
   - → **process**: the `codex-worktree-commit` candidate in `PLAN.md` now also asks the `handoff.tpl` default to authorize edits the plan names.

Also recorded: `PLAN.md` Now marks v2026.10.6 shipped and strikes `harness-registry` from the roadmap. Next on the roadmap is `harness-publish`.
