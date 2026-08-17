# /4-release stage + merge-authority amendment

**Slug:** trip-release · **Date:** 2026-08-16 · **Status:** merged (2026-08-17)

## Context

First full dogfood cycle (`/init` → `/1-plan` → `/2-implement` → `/3-review` → merge) is done; CI is live and green. This unit is retro candidate #3. It changes a stated invariant — `CLAUDE.md`: "Merge — the Owner's call, always" — deliberately, not as a side effect.

## Decisions (Owner, 2026-08-16)

- **Autonomy: (C) now, promoting to (A) by pre-registered rule.** Orchestrator runs the full release sequence including push, after one in-session Owner confirm. Each CHANGELOG release entry carries a `Confirm-delta:` line (`none`, or what the confirm changed). After **4 consecutive `none`** entries, the Owner drops the confirm (full TRIP) via a one-line CLAUDE.md edit — the rule is written in CLAUDE.md now, but the promotion is executed by hand, not by machinery. (Reviewer finding: an auto-promotion counter can't be validated without 4 real releases; building it now is speculative.)
- **Enforcement lives in shell, not prose.** Every precondition — review verdict, gate, ARCHI freshness, version monotonicity — is checked by `scripts/release.sh` (exit-code contract, same as gate.sh). The skill runs the script; it never enforces anything itself. Precise definitions so the checks aren't gameable:
  - *Verdict:* `release.sh` requires the exact line `Code-review verdict: APPROVE` in the unit's `plan.md → ## Review` (written only by `/3-review`; plan-stage reviews use the distinct `Plan verdict:` label so a clean plan approval can never satisfy release). Amended 2026-08-16 per review round 1 finding 3 — original spec was a single ambiguous `Verdict:` sentinel.
  - *ARCHI freshness:* stale ⇔ `git log -1 --format=%ct -- scripts/ skills/ profiles/ config.yaml CLAUDE.md` is newer than the last commit touching `ARCHI.md`.
  - *Version:* CalVer compared numerically field-by-field, never as strings (MICRO is unpadded; `2026.8.10 > 2026.8.9` must hold).
- **Versioning: CalVer (`YYYY.MM.MICRO`), in this unit.** No semantic judgment in the bump path. `VERSION` file + `CHANGELOG.md` (Keep-a-Changelog shape, CalVer headings).
- **Changelog entries are authored in the work unit, not at release time.** Each unit's `plan.md` carries a one-line `Release note:` field; `release.sh` prepends it. Release is deterministic assembly, never composition.
- **ARCHI sync is out of scope.** Release does not regenerate ARCHI.md (that stays `/compact`'s job, one pipeline). `release.sh` instead fails when ARCHI.md is stale (older than the newest commit touching tracked source dirs) with "run /compact first."

## Goal

`/4-release <slug>`: preconditions via `release.sh` → version bump → changelog prepend → release commit → tag → ff-merge to `main` → Owner confirm → push. Plus the CLAUDE.md amendment stating the (C)→(A) model and promotion rule, with no surviving contradictory sentence.

## Footprint

Create: `skills/4-release/SKILL.md`, `scripts/release.sh`, `VERSION`, `CHANGELOG.md`, `scripts/gate.d/test-scripts.sh` (wires the tests into the gate via its sanctioned extension point — added 2026-08-16 with review finding 2).
Modify: `CLAUDE.md` (merge-authority + promotion rule), `PLAN.md` (decision lines), `skills/1-plan/prompts/plan.tpl` (add `Release note:` field and `Verdict:` line to the `## Review` section), `skills/3-review/SKILL.md` (one line: record the final verdict as `Verdict: APPROVE|REVISE`), `tests/test-scripts.sh` (release.sh coverage: four refusals + happy path in a real worktree-topology fixture — added 2026-08-16 after review finding 2).
Do not touch: `scripts/gate.sh`, `scripts/worktree.sh`, `scripts/agent-exec.sh`, skills other than the two edits named above. No promotion-counter machinery anywhere.

## Acceptance criteria

- [ ] `scripts/release.sh` exits non-zero when: no `^Verdict: APPROVE$` line in the unit's `plan.md`; `gate.sh` fails; ARCHI.md is stale per the git-log definition above; or the computed version does not exceed `VERSION` numerically. Each refusal demonstrated in a sandbox worktree, not described.
- [ ] Version comparison test includes a MICRO ≥ 10 case (`.9` → `.10` bumps; `.10` → `.9` refuses).
- [ ] `release.sh` passes `scripts/gate.sh` (shellcheck).
- [ ] On green+APPROVE it produces: bumped `VERSION`, prepended `CHANGELOG.md` entry containing the unit's `Release note:` and a `Confirm-delta:` line, release commit, tag `vYYYY.MM.MICRO`, ff-merge to local `main` — then stops for the confirm before push.
- [ ] `skills/4-release/SKILL.md` matches sibling skill format and contains no enforcement language — preconditions are cited as release.sh behavior only.
- [ ] `grep -n "Owner's call" CLAUDE.md` returns nothing; the amendment states (C), the `Confirm-delta:` log, and the k=4 manual promotion rule.
- [ ] `plan.tpl` carries `Release note:` and `Verdict:` placeholders; `skills/3-review/SKILL.md` instructs writing the `Verdict:` line.
- [ ] Decision lines dated 2026-08-16 in `PLAN.md`.

## Verification

`bash scripts/gate.sh` → PASS; sandbox dry-runs of release.sh covering all four refusals and the happy path; the grep above.

**Release note:** Add /4-release: CalVer release stage with shell-enforced preconditions; merge authority moves to orchestrator-with-confirm, auto-promoting to full autonomy after 4 clean releases.

## Review

Verdict: REVISE → revised 2026-08-16, all five findings applied, no disagreements:
1. Auto-promotion counter unbuilt/untestable → descoped to a `Confirm-delta:` line per CHANGELOG entry; promotion is a manual Owner edit per the pre-registered rule.
2. Wrong footprint file for `Release note:` → corrected to `skills/1-plan/prompts/plan.tpl`.
3. APPROVE grep gameable in prose → exact `^Verdict: APPROVE$` sentinel; `plan.tpl` + `/3-review` write it.
4. Staleness dirs and CalVer comparison underspecified → pinned git-log path set; numeric field-wise compare with MICRO ≥ 10 test.
5. Simpler version → adopted (that's #1's resolution).

**Status:** revised draft — Owner approved 2026-08-16; implemented by codex on `wt/trip-release`.

### Code review (3 rounds, fresh reviewer each)

- R1 REVISE: broken ff-merge topology (git switch inside worktree), no tests, ambiguous verdict sentinel → all fixed.
- R2 REVISE: "Owner merges; you never do" survived in /3-review skill; rollback didn't cover commit/tag failure → both fixed (trap-based rollback + regression test).
- R3: all criteria verified, gate 17/17. Non-blocking nit: sentinel matches any line, relies on /3-review's overwrite-the-final-verdict discipline.

Code-review verdict: APPROVE
