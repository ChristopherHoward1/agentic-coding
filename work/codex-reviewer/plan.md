# Codex as second reviewer

**Slug:** codex-reviewer · **Date:** 2026-08-26 · **Status:** approved

## Goal

The validator ensemble is all-Claude (orchestrator + plan-reviewer + code-reviewer + fan-selector) — `PLAN.md` risk #1. Wire codex in as a second, independent code reviewer with a machine-checkable verdict contract, so a unit can release only when **two vendors** have approved — enforced by `release.sh` exit codes, not skill prose.

## Approach

A new script `scripts/codex-review.sh <slug>` — a **pure reader**, run from the primary checkout, never `cd`s anywhere, writes nothing but its own artifact. Prompt in, verdict out:

1. Reads `reviewer.command` from **`git show wt/<slug>:config.yaml`** (default `codex exec --sandbox read-only -`) — branch content, not the working tree. This makes the script a pure reader of the branch throughout (symmetric with the plan body, step 2) and makes the dogfood work unmodified: on this unit's own review, the `reviewer:` block exists only on `wt/codex-reviewer`, so a working-tree read would exit 2 every time. The awk parser **terminates at the next top-level key** (`f && /^[^[:space:]#]/ {exit}`) and **anchors the key match** (`/^[[:space:]]*command:/`, leading-`#` rejected) — neither the `implementer:` parser's lookahead bug nor its commented-alternative hazard is inherited; both are checked by tests, not policed by convention.
2. Builds the prompt via an in-script heredoc: plan body **from the branch** (`git show wt/<slug>:work/<slug>/plan.md` — the copy release reads; primary and worktree plans can diverge) + `git diff main...wt/<slug>`, ending with the literal instruction that the reply's final line must be `Codex verdict: APPROVE` or `Codex verdict: REQUEST CHANGES`.
3. Runs the reviewer with the prompt on stdin; stdout only is captured to `$(git rev-parse --show-toplevel)/work/<slug>/codex-review.md` — root-pinned, never cwd-relative (stderr passes through, never into the artifact).
4. Verdict: take the **last** line of the captured output matching `^[[:space:]]*Codex verdict:` (whitespace-tolerant — codex may indent or prefix its final line; a column-zero anchor would fail on real output that canned tests never exercise), trim, exact-compare the remainder. `APPROVE` → exit 0; `REQUEST CHANGES` → exit 1; missing/malformed verdict → exit 2; unset `reviewer.command` → exit 2. Each exit-2 cause has a distinct stderr message, asserted by substring in the tests.

**Sentinel recording (orchestrator, not script):** on exit 0, the orchestrator records `Codex-review verdict: APPROVE` alongside the Claude `Code-review verdict:` line in the **same single edit-and-commit on the worktree plan** it already performs today (cf. `fb4b0e0`) — both sentinels written there, never copied over from the primary (a whole-file copy would clobber them). This keeps the script free of worktree-path lookup, strip/write logic, and cross-checkout commit paths. An orchestrator could write the sentinel without running the reviewer — true, and identically true of the existing Claude sentinel; `work/<slug>/codex-review.md` is the audit trail, and enforcement lives in `release.sh` either way.

**Release enforcement:** `release.sh`'s `check_verdict` gains a second `grep -qx 'Codex-review verdict: APPROVE'` with a distinct `die` message. Test fixtures: `setup_release_fixture` has **10** call sites, and `verdict_line` is one positional param — the "refuses without codex sentinel" case needs the Claude sentinel *only*, so the fixture gains a **second verdict parameter** (a signature change, not string edits); existing call sites updated accordingly. `/3-review`'s SKILL.md orchestrates (both reviewers per round, findings from either route through the same followup flow, both re-run fresh after any change, 3-round cap covers the pair) but enforces nothing. The SKILL.md's recording step names the mechanics explicitly — both sentinels edited into the **worktree** plan and committed there in a **single commit** (`git -C <worktree> …`), never copied whole-file from the primary (the `fb4b0e0` whole-file shape is exactly the clobber hazard). The same commit **syncs the current plan body** onto the branch — `worktree.sh` seeds the plan only once, so without this the two vendors can judge different plan revisions.

**Writer≠reviewer note (recorded, deliberate):** codex is also the implementer, so the codex reviewer shares a *vendor* with the writer — but never a thread or context (`codex exec` starts cold, read-only). The Claude code-reviewer's APPROVE is still independently required, so this is strictly additive. Alternative — codex reviews only Claude-implemented units — rejected: under the current config that path would never run.

**Honesty note for the release report:** this unit's own `/4-release` runs the *old* `check_verdict`; the two-vendor enforcement first binds the **next** unit. The dogfood criterion observes the script working, not the enforcement.

Drive-by fixes (same diff): `skills/3-review/SKILL.md`'s stale "push confirmation" line (missed by `37e40e3`); `README.md`'s loop-diagram edge gains the second verdict (no skill regenerates README, so `/compact` won't catch it).

## Footprint

Files to modify:
- `scripts/codex-review.sh` (new)
- `scripts/release.sh` (second verdict sentinel in `check_verdict`)
- `config.yaml` (new `reviewer:` block: `command`)
- `skills/3-review/SKILL.md` (dual-reviewer steps, single-commit sentinel recording, stale-line fix)
- `tests/test-scripts.sh` (hermetic cases, `check_exit <n>` helper with stderr-substring assertion, `setup_release_fixture` second-verdict param + 10 call sites)
- `README.md` (loop-diagram edge)

Files NOT to touch:
- `scripts/agent-exec.sh` — stays write-oriented (its awk lookahead bug is out of scope; noted for a retro).
- `scripts/worktree.sh` — nothing here changes; the script never resolves worktree paths.
- `.claude/agents/code-reviewer.md` — the Claude reviewer is unchanged.

## Acceptance criteria

- [ ] `scripts/codex-review.sh <slug>` runs from the primary checkout, writes `work/<slug>/codex-review.md` (stdout only) there, and touches nothing else — after a canned run, `git status --porcelain` shows only that artifact.
- [ ] Exit codes via `check_exit <n>` (+ stderr substring): canned `APPROVE` → 0; **indented** `  Codex verdict: APPROVE` → 0 (whitespace tolerance proven); `REQUEST CHANGES` → 1; missing verdict → 2 ("no verdict"); `reviewer.command` absent from branch config → 2 ("reviewer.command"); absent but a later block defining `command:` present → still 2 (parser termination proven); a commented `# command:` above the real one → the real one wins (anchor proven).
- [ ] Both plan body **and** config come from `git show wt/<slug>:...` (grep the script); the heredoc contains the literal instruction naming the `Codex verdict: APPROVE|REQUEST CHANGES` format (grep); after a run, `git -C <worktree> status --porcelain` is empty (the criterion that actually protects release).
- [ ] `release.sh` refuses (distinct `die` message) when `Code-review verdict: APPROVE` is present but `Codex-review verdict: APPROVE` is absent — smoke test via the fixture's new second-verdict param; the other release cases still pass with both sentinels.
- [ ] `config.yaml`'s `reviewer.command` contains `--sandbox read-only` (grep).
- [ ] `skills/3-review/SKILL.md` contains `Codex-review verdict:`, contains the worktree-recording mechanics (`git -C` and `single commit` greppable), and no longer contains `push confirmation`; `README.md`'s mermaid block contains a `Codex-review verdict: APPROVE` edge (greps).
- [ ] Dogfood, observable: `work/codex-reviewer/codex-review.md` exists and its last `Codex verdict:` line is `APPROVE` before this unit releases.
- [ ] `bash scripts/gate.sh` green.

## Release

Release note: Release now requires a second, read-only codex review — cross-vendor approval enforced by `release.sh`, not prose. (Binds from the next unit onward.)

Pre-release step: this unit touches `scripts/`, `skills/`, and `config.yaml`, so ARCHI.md goes stale (including its hard-coded check count) — run `/compact` before `/4-release`.

## Verification

- Hermetic tests in `tests/test-scripts.sh` (canned reviewer: approve, indented-approve, request-changes, no-verdict, config-missing, parser-termination, artifact-only-write, release-refusal-without-codex-sentinel).
- Live dogfood, exact command from the primary checkout: `bash "$(git rev-parse --show-toplevel)/../agentic-coding-worktrees/codex-reviewer/scripts/codex-review.sh" codex-reviewer` — the script exists only on the branch at review time; it reads all inputs via `git show wt/codex-reviewer:…`, so invoking the worktree's copy from the primary cwd works and writes the artifact into the primary.

## Review

Round 1 (plan-reviewer, opus): REVISE — 7 findings applied: release.sh sentinel enforcement; artifact destination pinned; read-only made checkable; named exit codes + `check_exit`; `/compact` pre-release; verdict extraction specified; stale 3-review line fixed. Adopted: in-script heredoc over `prompts/review.tpl`.

Round 2 (plan-reviewer, opus, fresh): REVISE — all 6 applied: sentinel moved to the worktree plan where release.sh reads it; awk parser termination + test; stale-sentinel stripping; README + fixture call sites in footprint; heredoc-format grep + observable dogfood; stderr-substring exit-code assertions. Adopted: no `cd` into the worktree.

Round 3 (plan-reviewer, opus, fresh): REVISE — adopted the reviewer's simpler shape, which resolves finding 1 (two-writers clobber hazard) structurally: `codex-review.sh` is now a pure reader (no sentinel write, no strip logic, no worktree-path lookup — finding 3a moot); the orchestrator records both sentinels in its existing single worktree commit, stated in SKILL.md. Also applied: (2) whitespace-tolerant verdict match + indented-verdict test; (3b) prompt plan body pinned to `git show wt/<slug>:…`; (4) 10 call sites corrected, fixture gains a second-verdict *parameter* (signature change acknowledged); (5) criterion 6 reduced to greps; (6) honesty note — enforcement first binds the next unit, release report must not overclaim.
Round 4 (plan-reviewer, opus, fresh): REVISE — three findings, all applied: (1) config read moved to `git show wt/<slug>:config.yaml` — with a working-tree read the dogfood deterministically exits 2 (no `reviewer:` block in the primary) or dirties the release checkout; branch-sourced config removes the case entirely, exact dogfood command now in Verification, plus a worktree-clean AC; (2) awk key match anchored (`/^[[:space:]]*command:/`, `#`-rejected) with a commented-alternative test — checked, not policed by convention; (3) SKILL.md's sentinel-recording mechanics (worktree plan, single commit, never whole-file copy) made explicit and greppable — `fb4b0e0`'s whole-file shape is the hazard, not the precedent.
Round 5 (plan-reviewer, opus, fresh): **APPROVE** — round-4 applications verified against the code; four nitpick-grade notes, adopted as implementation notes: (1) fixture's second verdict may be an *appended defaulted* param (`${6:-…}`) instead of a signature insertion — implementer's call, fewer churned lines; (2) artifact path pinned to `$(git rev-parse --show-toplevel)/work/<slug>/` (cwd-relative write was a silent-misplacement hazard); (3) SKILL.md's recording step also syncs the current plan body into the same worktree commit that carries both sentinels — otherwise the two vendors can judge different plan revisions; (4) optional `git rev-parse --verify wt/<slug>` precheck for an honest error on a missing branch.
Plan verdict: APPROVE
