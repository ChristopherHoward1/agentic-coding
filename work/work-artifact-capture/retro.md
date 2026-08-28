# Retro — work-artifact-capture (v2026.8.11)

Six dual-vendor review rounds; the Owner authorized rounds 4, 5, and 6 past the cap on explicit escalation. Shipped clean: both reviewers APPROVE at round 6, gate at 137 checks (105 before the unit), `scripts/release.sh` byte-identical throughout. The unit's own nine artifacts reached `main` via the feature it added — the first release needing no catch-up commit.

The cost is the headline: **the most rounds any unit has taken, and every round found a defect in the previous round's fix.**

## Q1 — What did the gate miss that a reviewer caught?

Everything, at every round. The suite was green at 117, 121, 126, 132, 136 and 137 checks while reviewers found: symlink targets being materialized into the branch, path-based worktree resolution that would commit to the wrong branch, `git commit` without a pathspec sweeping the entire index, a cwd-relative pathspec silently truncating the reviewer's diff, and a non-ASCII filename leaving the worktree dirty and blocking release.

One pattern runs through three of those, and it is the finding worth keeping: **cwd- or checkout-dependence producing a silent no-op instead of a loud error.**

- `sync-artifacts` invoked from inside the worktree resolved `ROOT` to the worktree, copied nothing, and exited 0 (round 3).
- `codex-review.sh`'s exclusion pathspec used `.`, so a subdirectory invocation truncated the reviewer's diff and could yield a mechanically recorded APPROVE over a diff never shown (round 4).
- Dropping `,top` from that same pathspec re-leaked eight artifact files while the suite stayed green (round 5).

A fourth instance hit the orchestrator's own dispatch during round 6: a stale shell cwd made `scripts/agent-exec.sh` unresolvable, the dispatch never ran, and the outer command still reported exit 0. Four instances of one failure mode in one unit. → **contextual**, applied.

## Q2 — What did every check miss?

Two guards that are correct but unpinned — a mutation to either leaves the suite green, so only drift detection is missing:

- Replacing `git add -- "work/$slug"` with `git add -A` passes 137/137. Bounded by the pinned commit pathspec, but drift would silently stage unrelated worktree edits.
- Collapsing the commit guard to `git commit … || true` passes 137/137, despite the plan naming that prohibition as an implementation hazard.

Both need `tests/` edits, which this branch may not touch → **/1-plan candidate** below.

Also noted and **not worth keeping**: `/4-release` gained a pre-release stop condition (a removed worktree makes sync exit 1 before `release.sh` runs), and gitignored primary strays are physically copied into the worktree working directory. Both are loud and recoverable; `release.sh` is untouched.

## Q3 — What got re-derived that a doc would have prevented?

Nothing was re-derived — this unit's problem was the opposite. The knowledge doc *was* cited in the handoff (the new 2026-08-27 decision working as intended), and the implementer still shipped a vacuous test in round 1 and an unpinned guard in round 5. Citation got the doc loaded; it did not get the check performed.

What is missing is not a doc for the implementer but a doc for **reviewers and the orchestrator** on the specific vacuity shapes this repo keeps producing, and on the fact that a mutation can silently fail to apply — which happened twice here, producing false greens that nearly let both a vacuous test and an unpinned guard through. → folded into the same **contextual** routing as Q1.

## Q4 — What friction repeated from a prior retro?

**Vacuous tests and unpinned guards, for the third consecutive unit.** `ds-hygiene-hook` (v2026.8.9) produced `knowledge/test-helper-contract.md` about exactly this; `gate-tool-preflight` (v2026.8.10) shipped a vacuous test anyway and its retro added the "cite the doc" decision; this unit cited the doc and *still* hit the pattern in five of six rounds.

The escalating remedies — write the doc, then cite the doc — have not worked, because both target the implementer's *knowledge*, and the failure is in *verification*. What did work, every time, was a reviewer independently running mutations. That is a costly manual step performed at reviewer discretion, and its absence is invisible. → **process**, applied.

Second repetition, resolved: the manual artifact catch-up commit that motivated this unit did not recur — this release captured its artifacts automatically.

## Routings

- **contextual** (applied): new `knowledge/silent-no-op-hazards.md` — the cwd/checkout-dependence failure family, the three code instances plus the orchestration one, the anchoring idioms that fix them (`:/`, `:(exclude,top)`, `--git-dir` vs `--git-common-dir`, absolute dispatch paths), and the "assert your mutation landed" rule with the two false greens that motivated it.
- **process** (applied): `PLAN.md` Decisions — a guard is not pinned until a mutation to it has been shown to fail the suite *and* the mutation was verified to have landed; reviewer-run mutation testing is what has actually caught this, three units running.
- **/1-plan candidate** (named, not applied — needs `tests/`): `pin-sync-guards` — add cases so `git add -A` in place of the scoped add, and `|| true` in place of the commit guard, both fail the suite. Two tests; likely the small-fix path.
- **not worth keeping**: the `/4-release` pre-release stop condition and the copied gitignored strays (Q2 — both loud, recoverable, `release.sh` untouched); the six-round count itself (a symptom of Q4's routing, already covered there).
