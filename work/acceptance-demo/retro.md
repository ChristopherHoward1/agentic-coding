# Retro: acceptance-demo (v2026.10.1)

## 1. What did the gate miss that a reviewer caught?

Nothing blocking. The code-reviewer raised 5 LOW findings. One is worth a one-flag fix: `demo.sh`'s dirty-tree check uses plain `git status --porcelain`, so it misses writes inside an untracked folder that already existed before the demo ran. `--untracked-files=all` closes it.
→ **mechanical**, named and not applied here (it touches `scripts/`): candidate `demo-untracked-all`, small enough for the small-fix path. The other four LOWs → **not worth keeping**: they're loud failures (exit 2) or cosmetic.

## 2. What did every check miss?

**The implementer's demo step can't run under the codex runtime.** `handoff.tpl` now says gate, commit, then demo, so the demo runs on a clean tree. But the codex sandbox still can't commit (`index.lock`, see `docs-stage/retro.md` #2). So codex reached the commit step, stopped, and never ran the demo. The orchestrator committed and ran the demo itself. The plan, three plan-review rounds and both code reviewers all checked the step order. None of them checked whether the configured runtime could actually carry it out. `docs-stage` dropped `codex-worktree-commit` as "not worth keeping" because the loop already absorbs the failure. That no longer holds: the commit failure now silently disables half of this unit's design.
→ **mechanical**, named and not applied here (it touches `skills/2-implement/SKILL.md` or the sandbox config): revive candidate `codex-worktree-commit`. The cheapest version adds to `/2-implement` step 6: "if you committed for the implementer, run `scripts/demo.sh <slug>` and record the output in `notes.md`."

**Codex review is diff-reading only.** Its read-only sandbox couldn't create the temp files it needed, so it couldn't run the gate, the demo or the mutations. All of the runtime evidence came from the Claude reviewer alone.
→ **process**: added to the `PLAN.md` Risks line on correlated validators.

## 3. What got re-derived that a doc would have prevented?

While applying round-1 REVISE findings, the orchestrator wrote `Plan verdict: APPROVE` itself. It caught the mistake and reset the line before anything read it. → **not worth keeping**: invariant 1 (writer never reviews) already covers this, and it was caught right away.

## 4. What friction repeated from a prior retro?

The codex commit failure, now in its fourth unit (see #2).

The primary checkout's untracked `work/<slug>/` copies blocked `git pull --ff-only` after the merge. They had to be compared against `origin/main` (`plan.md` was a strict subset of the merged copy) and deleted by hand.
→ **process**: one line in `PLAN.md` Decisions.
