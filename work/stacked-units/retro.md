# Retro: stacked-units (v2026.10.9)

Shipped: a plan can declare `Stacked on: <parent>`. `worktree add` branches from `wt/<parent>`, `worktree base` gives both reviews the parent's exact `--fork-point` as their diff base, and release refuses until the parent lands, printing the one restack command.
- **Plan review:** five rounds, then Owner approval over a round-5 REVISE. The fork-point rule went merge-base → `git cherry` → newest-ancestor reflog walk → `git merge-base --fork-point`.
- **Implementation:** one dispatch, zero gate retries, two review followups.
- **Code review:** three rounds; both reviewers approved round 3. Two MEDIUMs deferred (`deferrals.md`).
- **Shelved and unshelved:** another session shelved the unit on main (bfcde68) while round 3 was running. Release's stale-branch refusal surfaced it, and the Owner chose to ship.

1. **What did the gate miss that a reviewer caught?**
   - **Inert assertions under macOS Bash 3.2.** The stack cases ran under `bash -e -c`, but in Bash 3.2 a failing `[[ ]]` that isn't the last command doesn't trip errexit. Nine checks could never fail locally. The implementer's five mutations each still failed a case, so the evidence looked complete. The code-reviewer found it by mutating guards the implementer hadn't. → **contextual:** a section in `knowledge/test-helper-contract.md`, which every handoff already cites.
   - **A printed rebase with no branch argument (codex round-2 HIGH).** The orchestrator's round-1 followup prescribed dropping `-C` when the child had no worktree, so the printed command would rebase whatever was checked out. → **not worth keeping:** the fresh-review rule caught it in the next round, as designed, and the fix is in the code.
2. **What did every check miss?**
   - Nothing surfaced after release. The shelve collision was caught by `release.sh`'s stale-branch check before anything was pushed. → **not worth keeping:** a one-off coordination gap between two sessions; the existing fetch guard was enough.
3. **What got re-derived that a doc would have prevented?**
   - The fork-point rule took four plan rounds to reach git's built-in. → **not worth keeping:** the rule and its expiry limit now live in ARCHI.md and `lib/stack.sh`, and the plan records why the alternatives fail.
4. **What friction repeated from a prior retro?**
   - **The `PLAN.md` footprint LOW.** Both reviewers flagged the orchestrator's branch "In progress" line in every round (six times), the second unit in a row. `codex-worktree-commit`'s retro called it not worth keeping; it is now recurring noise. → **mechanical:** a `PLAN.md` candidate, since the fix touches `harness/` (`plan.tpl`'s NOT-to-touch default, or a line in `code-reviewer.md`).
   - **`demo-fail-fast`.** This plan's demo again needed `|| exit 1` on every check. → **mechanical:** the existing `PLAN.md` candidate stays, with this recurrence noted.
   - **Deferred MEDIUMs.** → **process:** one `PLAN.md` candidate, `stacked-units-followups`, starting only when work use asks (roadmap frozen).
