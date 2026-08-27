You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.

Work unit: work/retro-stage/plan.md  (read it in full; it is your source of truth — including the Review section's round-3/4 applied findings)
Branch: wt/retro-stage (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
- skills/5-retro/SKILL.md (new)
- skills/4-release/SKILL.md (final numbered step invoking /5-retro)
- CLAUDE.md (Loop section)
- scripts/release.sh (marker write + check_previous_retro + rollback git clean)
- tests/test-scripts.sh (fixture machinery + new cases)
- PLAN.md (one Decisions line)
Do NOT touch: knowledge/README.md, scripts/worktree.sh, ARCHI.md (regenerated later by /compact, not by you).

Key constraints:
- release.sh, three edits exactly:
  1. check_previous_retro, inserted BETWEEN the pre-gate check_origin_main_ancestor call and check_gate: if `work/.last-released` exists in the release checkout, `work/$(cat work/.last-released)/retro.md` must exist and be non-empty (`[[ -s ]]`), else die with a message containing the literal `has no retro.md` (and naming both remedies: run /5-retro, or sync onto origin/main). Must stay grep-distinct from the ancestor check's `is stale` message. No marker file → pass (self-bootstrapping).
  2. Marker write: on the release path, write the slug to `work/.last-released` and `git add` it so it lands inside the release commit, within the existing `trap rollback_release ERR` window.
  3. rollback_release gains `git clean -f work/.last-released` — `git reset --hard` alone leaves a first-time (previously untracked) marker on disk, and the next attempt would die at check_clean_worktree.
- skills/5-retro/SKILL.md (new): frontmatter `name: 5-retro` + `description:`. Steps must contain: the four retro questions (what did the gate miss that a reviewer caught / what did every check miss / what got re-derived that a doc would have prevented / what friction repeated from a prior retro); the literal routing labels `mechanical`, `contextual`, `process`, `not worth keeping` — each answer routes to exactly one; the flow `bash scripts/worktree.sh add retro-<slug>` → write `work/<slug>/retro.md` and apply every routing on that branch → push → PR to main; the rule that an unapplied routing means the stage is not done; "nothing learned" is a valid one-line retro; the mechanical restriction that the retro branch may only touch `knowledge/`, `PLAN.md`, and `work/<slug>/retro.md` — anything under `scripts/` or `gate.d/` becomes a /1-plan unit named in the retro.
- skills/4-release/SKILL.md: add a final numbered step invoking /5-retro for the released unit (literal string `/5-retro`).
- CLAUDE.md Loop section: the code block becomes `/1-plan → /2-implement → /3-review → /4-release → /5-retro` plus a one-line stage description matching the existing style. Touch nothing else in CLAUDE.md.
- PLAN.md: one line under Decisions: 2026-08-26 — /5-retro stage; release.sh refuses unit N until unit N−1's retro exists non-empty — work/retro-stage.
- tests/test-scripts.sh: `setup_release_fixture` gains OPTIONAL trailing params (marker slug, retro presence/content) — appended and defaulted so all existing call sites stay untouched. New cases:
  1. successful release leaves work/.last-released containing the slug, included in the release commit;
  2. forced post-bump commit failure rolls the marker back — force it with a `.git/hooks/pre-commit` exiting 1 installed in the fixture primary (linked worktrees share the common hooks dir); assert the marker is gone after rollback;
  3. marker naming a unit with no retro.md → refusal, stderr contains `has no retro.md`;
  4. marker + EMPTY retro.md → same refusal;
  5. marker + non-empty retro.md → release proceeds;
  6. no marker → proceeds (existing cases must keep passing unmodified);
  7. branch both behind origin/main AND missing the retro → dies with the ancestor message (`is stale`), NOT the retro one (ordering falsifiable).
- Shell style: `set -uo pipefail`, must pass shellcheck (the gate runs it).

When done:
1. Run scripts/gate.sh from the repo root — it must pass.
2. Commit your work on this branch with a clear message.
3. Print a final summary: what changed and why, criteria partially met (if any), out-of-scope observations.
