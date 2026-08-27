# Loop hardening

**Slug:** loop-hardening · **Date:** 2026-08-26 · **Status:** implemented

## Goal

Close the enforcement gaps named in `work/retro-stage/retro.md` and the v2026.8.6/7
review findings. Gaps 1–2 (marker deletable/mutable; codex reviewer executes
attacker-editable branch config) are closed by an exit code with a hermetic test.
Gap 3 (dispatch disconnects look like success) is closed for the produced-nothing
case only — the after-work disconnect is indistinguishable at dispatch level from a
normal uncommitted implementer and stays gate-covered. Gap 4 (`/5-retro` cannot
resume) is a procedure fix in skill prose, not enforcement.

## Approach

Four mechanical fixes, no new stages or scripts:

1. **Marker integrity guard** (`scripts/release.sh`): in `check_previous_retro`, if
   `git show origin/main:work/.last-released` succeeds, the release checkout's
   marker must be byte-identical to it — deletion dies with a message containing
   `marker deleted`, any content difference dies with a message containing
   `marker differs from origin/main`. Comparison mechanism: `git show
   origin/main:work/.last-released | cmp -s - work/.last-released` — NOT command
   substitution, which strips trailing newlines and would let `demo\n\n` pass as
   equal. One comparison subsumes deletion, mutation to an older slug, emptying,
   and multi-line garbage. No fetch and no fallback inside the guard:
   `check_origin_main_ancestor` (release.sh:229) has already fetched, died if
   `origin/main` is missing, and proven ancestry before `check_previous_retro`
   (release.sh:230) runs — bootstrap is defined solely by `git show
   origin/main:work/.last-released` failing on a ref known to exist. In the
   bootstrap case, keep today's pass-through but die `malformed` if a local marker
   exists and is empty or multi-line. Known legitimate trip (round 3 finding 2): a
   `/4-release` retry on a branch already carrying its release commit has branch
   marker = `<slug>` ≠ origin/main's — an improvement over today's silent version
   double-bump, but the die message must name that case: the `marker differs`
   message also says `if this branch already carries its release commit, merge its
   PR instead of re-running release`. *(Round 1 finding 4 collapsed deletion-guard
   + validation into byte-identity; round 2 finding 2 removed the redundant
   fetch/no-ref fallback; round 3 findings 2–3 specified the cmp mechanism and the
   already-released message.)*
2. **Reviewer-command source fix** (`scripts/codex-review.sh`): read
   `reviewer.command` from `main:config.yaml` instead of the branch's. This deletes
   the vulnerability (branch content can no longer choose the reviewer binary)
   rather than guarding it — no block comparator, no deadlock for units that
   legitimately change `reviewer:` (their change binds at the next unit's review,
   same shape as the release-script binding; the Release honesty note carries this
   — no knowledge-doc addendum, per round 3 finding 6: nothing has been re-derived
   about reviewer binding, and `knowledge/README.md` requires an instance).
   The historical reason for branch-sourcing is dead: the `reviewer:` block now
   exists on `main` (config.yaml:19). Test impact is a fixture rewrite, not a
   tweak: `setup_codex_review_fixture` currently has no `config.yaml` on fixture
   main at all — each `command_mode` writes it inside the worktree — so the
   `command_mode` config-writing moves to fixture main before `wt/demo` is cut, and
   test line ~381 (`codex-review reads config from branch`) is replaced by a
   `main:config.yaml` structural check. New fixture mode for the key case
   (round 3 finding 4): main carries an approve command, `wt/demo` carries a
   request-changes override → expect exit 0, proving the branch override is dead.
   *(Replaces round-1's deadlocking drift guard — findings 1–2; fixture reality per
   round 2 finding 3.)*
3. **Dispatch null-result detection** (`scripts/agent-exec.sh`): record the
   worktree's HEAD before dispatch; after the implementer command exits 0, exit
   non-zero (distinct message containing `no new commit`) only if HEAD is unchanged
   **and** `git status --porcelain` is empty — the dispatch produced literally
   nothing. Honest scope (round 2 findings 1 and 4): this catches a dispatch that
   dies before any work while exiting 0. It does NOT catch the incident in
   `work/codex-reviewer/notes.md` (disconnect *after* work, dirty tree — that path
   is indistinguishable from a normal uncommitted implementer and remains covered
   by the gate + `2-implement` step 6), and it is inert whenever the pre-dispatch
   tree is dirty — in practice Fan Mode (`seed_work_dir` copies `work/<slug>/`
   over the committed plan; dirty whenever that directory carries files beyond
   `plan.md`, which it does for real units via handoff/notes) and gate-failure
   re-dispatches — so its scope is a dispatch into a clean worktree, the default
   single-agent first-dispatch path (`implementer.fan: 1`). Fix 3's test
   scaffolding is the unit's only brand-new fixture (agent-exec today has a single
   argument-validation test); if footprint pressure appears mid-implementation,
   this is where it surfaces. Do NOT otherwise restructure
   agent-exec.sh, and do NOT touch its config-parsing awk (known-latent lookahead
   bug, out of scope).
4. **/5-retro resume + cleanup** (`skills/5-retro/SKILL.md` prose only): step 1
   gains the literal sentence `If the worktree already exists, reuse it instead of
   running worktree.sh add again` (because `worktree.sh add` hard-fails on an
   existing path — worktree.sh:24); a final step runs `worktree.sh remove
   retro-<slug>` after the PR merges. Grep targets: `reuse it instead` and
   `worktree.sh remove`. This is
   procedure, not enforcement — it doesn't collide with the "enforcement never
   lives in skill prose" convention because nothing here gates anything; it tells
   the orchestrator how to resume. (`worktree.sh` idempotent-add was considered —
   round 2 finding 5 — and declined: Owner scoped `worktree.sh` out.)

Explicitly out of scope: agent-exec's awk parser, whitespace-only-retro tightening,
test deduplication, `worktree.sh` changes.

## Footprint

Files to modify:
- scripts/release.sh
- scripts/codex-review.sh
- scripts/agent-exec.sh
- skills/5-retro/SKILL.md
- tests/test-scripts.sh
- PLAN.md (retire the Risks bullet on `reviewer.command` being executable branch
  content — fix 2 deletes that vulnerability and supersedes the drift-guard
  mitigation named there; one Decisions line pointing here; refresh the "Next
  candidate" line)
- ARCHI.md (regenerated by /compact pre-release — its "read from the *branch's*
  config" and check-count lines go stale with this unit; listed so the edit doesn't
  read as out-of-scope at /3-review)

Files NOT to touch:
- scripts/worktree.sh, scripts/fan-exec.sh, CLAUDE.md, README.md, .claude/agents/*,
  AGENTS.md, skills/2-implement/SKILL.md

## Acceptance criteria

- [ ] Hermetic marker tests (existing fixture style): marker on origin/main but
      deleted on branch → die, stderr contains `marker deleted`; marker mutated to a
      different (retro-complete) slug → die, stderr contains `marker differs`;
      marker with trailing extra newline vs origin/main's → die `marker differs`
      (proves byte comparison, not substitution-stripped); re-run on a branch
      already carrying its release commit → die, stderr names the already-released
      condition; bootstrap (no marker on origin/main) with empty or multi-line
      local marker → die `malformed`; the existing marker/retro matrix cases pass
      with their assertions unmodified.
- [ ] codex-review source tests: fixture main carries the reviewer config; new
      mode with an approve command on main and a request-changes override on
      `wt/demo` → exit 0 (branch override has no effect); missing `reviewer:` on
      fixture main → exit 2; all existing codex exit-code/stderr matrix cases keep
      their assertions; the `reads config from branch` structural check is replaced
      by a `main:config.yaml` structural check.
- [ ] agent-exec tests: canned implementer that commits → exit 0; canned
      implementer that leaves uncommitted changes without committing → exit 0
      (2-implement/fan path preserved); canned implementer that exits 0 touching
      nothing → non-zero, stderr contains `no new commit`.
- [ ] Existing hermetic fan-exec cases pass unmodified.
- [ ] `skills/5-retro/SKILL.md` greps for `reuse it instead` (step 1 resume
      instruction) and `worktree.sh remove` (cleanup step).
- [ ] `PLAN.md` no longer lists the `reviewer.command` branch-content risk;
      Decisions carries one line for this unit.
- [ ] `bash scripts/gate.sh` green.

## Release

Release note: Enforcement hardening — retro marker must match origin/main byte-for-
byte, codex reviewer command now sourced from main (branch config can no longer
choose the reviewer), dispatch fails loudly when the implementer produced nothing.

Pre-release: touches scripts/ and skills/ — run /compact before /4-release. Honest
note: per `knowledge/release-script-binding.md`, the new release.sh guard first runs
at the *next* unit's release; the codex-review and agent-exec changes bind
immediately.

## Verification

- `bash scripts/gate.sh` (runs `tests/test-scripts.sh` via gate.d)

## Review

Round 1: REVISE — all six findings verified and applied: deadlocking drift guard
replaced by main-sourcing the reviewer command; no-new-commit check softened to
HEAD-unchanged ∧ clean tree; marker fixes collapsed into byte-identity with
origin/main; ARCHI.md added to footprint; fan-exec-regression AC added.

Round 2: REVISE — findings 1–5 verified and applied: fix 3 reframed to its honest
scope (produced-nothing only; the observed after-work disconnect is not catchable
at dispatch level and stays gate-covered; inert in Fan Mode and on dirty
re-dispatches), release.sh ordering claim corrected and the redundant fetch/no-ref
fallback removed, codex fixture rewrite acknowledged (config moves to fixture main;
structural test replaced), Goal narrowed to distinguish enforcement (1–2) from
procedure (4).

**Disagreement (round 2 finding 6, Owner arbitrates):** the reviewer recommends
shipping only fixes 1–2 and dropping 3 (inert on the motivating incident) and 4
(small-fix-sized prose). Kept both: the Owner's request named all four gaps; fix 3
still converts a silent null dispatch into an exit code on the default path at
trivial cost, and fix 4 bundled here keeps the retro-named gaps closing in one
audited unit rather than a side-channel edit. If the Owner prefers the narrow
unit, cut 3–4 and remove agent-exec.sh + skills/5-retro/SKILL.md from the
footprint.

Round 3: REVISE — all seven findings applied: PLAN.md added to the footprint (its
Risks bullet asserts the vulnerability fix 2 deletes), the already-released re-run
case named in the guard's die message + AC, byte-comparison mechanism pinned to
`cmp -s` with a trailing-newline test, the branch-vs-main override fixture mode
named, the Fan-Mode-inertness claim restated as tree-dirtiness-contingent, the
knowledge-doc addendum dropped (no re-derived instance; the Release honesty note
carries it — note: the Owner's original draft requested that addendum for the
now-replaced drift-guard design, so its rationale died with that design), and the
/5-retro grep targets made literal. Reviewer also flagged fix 3's ACs as the
unit's only new fixture — noted in Approach as the likely pressure point.

Owner arbitration (2026-08-26): all four fixes ship; the knowledge-doc addendum
stays dropped.

Plan verdict: APPROVE (rounds 1–3 applied; Owner arbitrated both open items)

### Implementation review (2026-08-26/27)

Four dual-vendor rounds (Owner authorized round 4 after the 3-round budget):
- R1: Claude APPROVE / codex REQUEST CHANGES → fixed symlink marker bypass; agent-exec post-dispatch `git -C`.
- R2: Claude APPROVE / codex REQUEST CHANGES → normalized worktree path to absolute; bootstrap symlink refusal; ARCHI.md regenerated on-branch via /compact.
- R3: Claude APPROVE / codex REQUEST CHANGES → null-dispatch guard scoped to clean-before-dispatch (Owner authorized fix + round 4).
- R4: both APPROVE. Gate green (76 checks).

Recorded deviations: symlink refusals are review-added scope (closes cmp-follows-symlinks bypass); the guard also fires on a clean-tree no-op re-dispatch (loud, orchestrator-recoverable — retro item); codex reviewer binds to local `main`, so a stale primary `main` runs an older reviewer (as designed; retro item).

Code-review verdict: APPROVE
Codex-review verdict: APPROVE
