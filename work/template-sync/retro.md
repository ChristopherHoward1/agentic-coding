# Retro — template-sync (v2026.10.3)

1. **What did the gate miss that a reviewer caught?**
   - **Bare `mktemp -d` on macOS ignored the test's `TMPDIR`.** Both cleanup pins in case (b) checked nothing on the local gate, even though `mutations.md` (recorded from inside the codex sandbox) claimed they did. The code-reviewer caught this by re-running the mutations on macOS. → **contextual**: added to `knowledge/silent-no-op-hazards.md`.
   - **The tag guard matched `VERSION` as a regex** (`grep -qx`, where `.` matches any character). Codex caught it. → **not worth keeping**: a one-off `-F` miss, with nothing general to learn beyond "use -F for literals".
2. **What did every check miss?**
   - **The Demonstration block passed while the sync inside it failed.** In codex's sandbox the clone failed with exit 2, the block kept going, and `demo.sh` exited 0. Only the implementer reading its own output noticed. → **mechanical**: new `/1-plan` candidate `demo-fail-fast` (`scripts/demo.sh` runs the block with errexit). It is outside the retro file boundary.
   - **`state.sh` reported `stage: plan` for a released unit.** The Owner approved the plan over a round-3 REVISE, and `state.sh` has no way to see that. → **mechanical**: new candidate `state-owner-approval`.
3. **What got re-derived that a doc would have prevented?**
   - **The primary checkout was behind `origin/main` when the session started.** The template-export retro looked missing, and `/4-release` ran from the pre-pull skill text, which skipped the README-drift step. That step was caught afterwards. → **process**: a `PLAN.md` Decision.
4. **What friction repeated from a prior retro?**
   - **The codex sandbox can't commit or reach the network, again.** One of the two dispatches couldn't commit. The real-repo demo needed github.com, so the orchestrator ran it. → **process**: the existing `codex-worktree-commit` candidate is extended to cover network-dependent demos.
