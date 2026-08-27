# Retro — gate-tool-preflight (v2026.8.10)

Made the gate stop reporting PASS for checks it never ran. Three dual-vendor review rounds, both vendors APPROVE at round 3; four non-blocking findings carried here rather than fixed in a fourth dispatch.

## Q1 — What did the gate miss that a reviewer caught?

The suite was green at every round — 102, then 105 checks — while reviewers found four real defects. Two are worth separating from the usual "adversarial reader beats the spec" pattern, because the gate was *structurally* incapable of catching them:

- **A vacuous test.** `preflight aborts before stack checks` passed with the abort removed entirely; its fixture had no runnable tool, so no implementation could emit a `▶` line. A green suite cannot distinguish an assertion that proves something from one that cannot fail — the gate is the wrong instrument by construction.
- **Inbound environment leakage.** `GATE_REQUIRED_TOOLS=shellcheck bash scripts/gate.sh` failed 8 of 15 new tests. The gate cannot catch this because the gate is the thing being poisoned: the variable reaches the `gate.d/test-scripts.sh` hook and then every fixture, whose restricted `PATH` lacks the tool.

The other two (a commented-out `# required_tools:` line bricking the gate via unanchored awk; `GATE_REQUIRED_TOOLS=` failing to override because the guard tested emptiness rather than presence) are ordinary spec-silence caught by a cold reader. Dual review working as designed — **not worth keeping** as a new artifact.

## Q2 — What did every check miss?

Two defects nothing mechanical catches, both surfaced only by a round-3 reviewer running mutations by hand:

- **Dead code shipped.** The awk comment-skip rule at `scripts/gate.sh:29` is unreachable — deleting it leaves the suite at 105/0. A column-0 comment is already excluded by the top-level-key rule, and an indented comment can never match `^[[:space:]]*required_tools:`. CLAUDE.md says delete dead code; it shipped anyway because no check can see an inert branch.
- **A hermeticity property that is positional, not structural.** `unset GATE_REQUIRED_TOOLS` sits ~180 lines into `tests/test-scripts.sh` with no comment. It is correct today only because every real-gate invocation happens to come after it. A future case added above that line silently loses the protection, and would fail only on a dev box that happens to export the variable.

Both need `scripts/` or `tests/` edits, which this branch may not touch → **/1-plan candidate** below.

Also noted and **not worth keeping**: a space-separated `required_tools` value becomes one bogus tool name. It fails loudly, and both `profiles/work.md` and ARCHI document the colon-separated shape.

## Q3 — What got re-derived that a doc would have prevented?

Environment hermeticity for the nested suite, in the direction nobody had written down. `knowledge/test-helper-contract.md` covers what each helper asserts and how vacuity happens, but says nothing about the suite running *inside* `scripts/gate.sh` via the `gate.d/` hook — so the plan's hazard note named only the outbound direction ("never `export`"), the implementer honoured exactly that, and the inbound direction cost a full review round. → **contextual**, applied.

## Q4 — What friction repeated from a prior retro?

**A vacuous test shipped to review despite a doc that exists to prevent exactly that.** `ds-hygiene-hook` (v2026.8.9) produced `knowledge/test-helper-contract.md`, whose "A green suite is not a real suite" section says: delete the guard, re-run, and if the suite stays green the case is decoration. One release later, a vacuous test reached review round 2 anyway.

The doc was not the problem — the routing was. `knowledge/` is cold tier, loaded only on citation, and the handoff cited the *decision* from `PLAN.md` without naming the doc that explains how to satisfy it. An uncited cold doc does not exist for a cold implementer. → **process**, applied.

Second repetition, smaller: the unit's own artifacts (`handoff.md`, `notes.md`, `followup-*.md`, `codex-review.md`) never reached the branch — `worktree.sh` seeds only `plan.md` — so they sit untracked in the primary checkout exactly as `ds-hygiene-hook`'s did, which needed a manual `chore/ds-hygiene-artifacts` catch-up commit that is *still* unmerged. Two units in a row. → **/1-plan candidate** below.

## Routings

- **contextual** (applied): addendum to `knowledge/test-helper-contract.md` — the suite runs nested inside `gate.sh`, so environment hermeticity is bidirectional: no case may `export`, and the suite must survive an inherited value.
- **process** (applied): `PLAN.md` Decisions line — a handoff that cites a `PLAN.md` decision must also name the `knowledge/` doc that says how to satisfy it; cold-tier docs load on citation only.
- **/1-plan candidate** (named, not applied — needs `scripts/`+`tests/`): `gate-preflight-cleanup` — delete the unreachable awk comment-skip rule, and move `unset GATE_REQUIRED_TOOLS` beside `cd "$ROOT"` with a comment so hermeticity is structural. Both one-liners; likely the small-fix path rather than a full unit.
- **/1-plan candidate** (named, not applied — needs `scripts/`): `work-artifact-capture` — have the loop record `handoff.md` / `notes.md` / `followup-*.md` / `codex-review.md` onto the branch as `worktree.sh` already does for `plan.md`, so a released unit's artifacts are not left untracked. Second occurrence; `chore/ds-hygiene-artifacts` is the unmerged evidence of the first.
- **not worth keeping**: adversarial-edge findings (Q1 — dual review already covers them); space-separated tool list (Q2 — fails loudly, shape is documented).
