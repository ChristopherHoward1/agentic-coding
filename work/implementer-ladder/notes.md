Dispatching implementer in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/implementer-ladder
  codex exec --sandbox workspace-write - < /Users/cboyfly/Documents/repos/agentic-coding/work/implementer-ladder/handoff.md
OpenAI Codex v0.139.0
--------
workdir: /Users/cboyfly/Documents/repos/agentic-coding-worktrees/implementer-ladder
model: gpt-5.5
provider: openai
approval: never
sandbox: workspace-write [workdir, /tmp, $TMPDIR]
reasoning effort: none
reasoning summaries: none
session id: 01a06d6e-edb6-71a3-8945-871209a75056
--------
user
You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract. Note: this unit *edits* AGENTS.md itself, so you are amending your own contract; keep the existing rules and tone intact.

Work unit: work/implementer-ladder/plan.md  (read it in full; it is your source of truth)
Branch: wt/implementer-ladder (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

## What to do

Add a lazy/YAGNI **build-discipline** section to `AGENTS.md`, borrowing the *text* of the "ponytail ladder" (source material below — paraphrase to fit AGENTS.md's terse rule style; do not copy verbatim wholesale). Then add ONE reinforcing line to the handoff template pointing at it. The substance lives only in AGENTS.md — do not duplicate the ladder into the template.

AGENTS.md today enforces *scope* ("Scope is the plan. Nothing more.") but says nothing about how lazily to build *within* scope. This section fills that gap.

## Source material (the ponytail ladder — paraphrase, don't dump)

**The ladder** — stop at the first rung that holds; run it *after* you understand the problem, not instead of it (read the task and the code it touches, trace the real flow end to end, then climb):
1. Does this need to exist at all? Speculative need → skip it, say so in one line. (YAGNI)
2. Already in this codebase? A helper/util/type/pattern that already lives here → reuse it.
3. Stdlib does it? Use it.
4. Native platform feature covers it? Use it.
5. Already-installed dependency solves it? Use it. Never add a new dep for what a few lines do.
6. Can it be one line? One line.
7. Only then: the minimum code that works.

**Bug fix = root cause, not symptom:** a report names a symptom. Grep every caller of the function you touch and fix the shared function once — one guard there is a smaller diff than one per caller, and patching only the path the ticket names leaves sibling callers broken.

**Never lazy about (boundaries — load-bearing, keep these explicit):** understanding the problem; input validation at trust boundaries; error handling that prevents data loss; security; accessibility; anything explicitly requested or named in the plan. Laziness that skips comprehension to ship a small diff is the dangerous kind. The ladder shortens the solution, never the reading.

**`ponytail:` comment marker:** mark a deliberate simplification that cuts a real corner with a known ceiling using a `ponytail:` comment naming the ceiling and upgrade path (e.g. `# ponytail: global lock, per-account locks if throughput matters`).

## Footprint (hard boundary — do not touch anything else)

- `AGENTS.md` — add the build-discipline section (ladder + root-cause + boundaries + marker)
- `.claude/skills/2-implement/prompts/handoff.tpl` — one reinforcing line referencing the build discipline in AGENTS.md

Do NOT touch `.claude/agents/code-reviewer.md` or `scripts/codex-review.sh` — the review-side lens is a separate unit.

## Key constraints

- `AGENTS.md` must stay tight: **≤ 45 lines total** (`wc -l AGENTS.md`). Mechanical rules, not an essay.
- Preserve the existing final line "Honest and brief beats thorough and padded."
- Keep all seven ladder rungs, in priority order, with the "understand first / trace the real flow" guard.
- No duplicated ladder text in the handoff template — just a pointer.

## When done

1. Run scripts/gate.sh from the repo root — it must pass.
2. Commit your work on this branch with a clear message.
3. Print a final summary: what changed and why, any acceptance criteria partially met, out-of-scope observations.

codex
I’ll read the contract and plan first, then verify the branch before touching the two allowed files. After that I’ll keep the edits narrow and run the repo gate before committing.
exec
/bin/zsh -lc "sed -n '1,260p' work/implementer-ladder/plan.md" in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/implementer-ladder
exec
/bin/zsh -lc "sed -n '1,220p' AGENTS.md" in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/implementer-ladder
 succeeded in 0ms:
# Implementer Contract

You are the implementer. Your source of truth is the handoff you received; it names the work unit (`work/<slug>/plan.md`), the branch, and the file footprint.

## Rules

1. **Scope is the plan. Nothing more.** No refactoring adjacent code, no speculative features. If the work seems to require a file outside the declared footprint, stop and say so instead of expanding it yourself.
2. **You are in a worktree on a pre-created branch.** Verify the branch matches the handoff before changing anything. Do not switch, merge, rebase, or reset.
3. **Run the gate before finishing:** `scripts/gate.sh` from the repo root. Do not report done while it fails.
4. **Finish with a summary**: what changed and why, any acceptance criteria only partially met (and why), anything you noticed but left out of scope.
5. **Stop and surface** rather than guess when: acceptance criteria conflict, the plan seems wrong against the actual code, or a decision belongs to the Orchestrator or Owner.

Honest and brief beats thorough and padded.

 succeeded in 0ms:
# Implementer ladder: lazy/YAGNI build discipline in the contract

**Slug:** implementer-ladder · **Date:** 2026-09-04 · **Status:** approved

## Goal

Codex's implementer contract (`AGENTS.md`) enforces *scope* ("Scope is the plan. Nothing more.") but says nothing about *how lazily to build within that scope*. So codex can build an over-engineered version of exactly the planned feature — a factory for one product, a hand-rolled stdlib routine, a speculative config knob — and pass both the contract and the plan's acceptance criteria. Nothing downstream catches it either: `/3-review` scores over-engineering as LOW, which never blocks. Done looks like: the contract carries a short, mechanical build-discipline rule (ponytail's "ladder") so codex reaches for the leaner rung by default, with the guardrails that keep laziness from cutting real corners.

## Approach

Borrow the *text* of ponytail's ladder, not its machinery (no hooks, no skills, no multi-platform distribution). One authoritative home: `AGENTS.md`, which the handoff already names as the contract codex reads first. Add:

- **The ladder** — stop at the first rung that holds: needs to exist at all (YAGNI) → already in this codebase → stdlib → native platform feature → already-installed dep → one line → minimum code. Runs *after* understanding the problem, not instead of it.
- **Root cause, not symptom** — grep the callers, fix the shared function once.
- **Boundaries (never lazy about)** — input validation at trust boundaries, error handling that prevents data loss, security, accessibility, and anything explicitly requested or in the plan. This clause is load-bearing: without it a "be lazy" instruction reads as license to strip validation.
- **`ponytail:` comment marker** for a deliberate corner cut with a known ceiling (names the ceiling + upgrade path).

`handoff.tpl` gets a single reinforcing line pointing at the build discipline; the substance lives only in `AGENTS.md` (one source of truth — adding the full ladder to both would be the exact duplication the ladder warns against).

Alternative considered: a warm-tier profile addition instead of `AGENTS.md` — rejected, the ladder is universal build discipline, not profile-specific, and `AGENTS.md` is already the read-first contract.

## Footprint

Files to modify:
- `AGENTS.md` — add the build-discipline section (ladder + root-cause + boundaries + marker)
- `.claude/skills/2-implement/prompts/handoff.tpl` — one reinforcing line

Files NOT to touch:
- `.claude/agents/code-reviewer.md` and `scripts/codex-review.sh` — the review-side complexity lens is recommendation #2, a separate unit; keep this diff to the build side.

## Acceptance criteria

- [ ] `AGENTS.md` contains a build-discipline rule listing the ladder rungs in priority order (YAGNI → already-in-codebase → stdlib → native platform → installed dep → one line → minimum code), with the explicit "understand the problem first / trace the real flow" guard.
- [ ] `AGENTS.md` states root-cause-over-symptom (grep callers, fix the shared function once).
- [ ] `AGENTS.md` retains an explicit "never lazy about" boundary naming at least: input validation at trust boundaries, error handling against data loss, security, and anything explicitly requested/in the plan.
- [ ] `AGENTS.md` documents the `ponytail:` comment convention for a deliberately cut corner (ceiling + upgrade path).
- [ ] `handoff.tpl` references the build discipline in `AGENTS.md` (no duplicated ladder text).
- [ ] `AGENTS.md` stays tight (≤ 45 lines total, `wc -l`) — the addition is mechanical rules, not an essay; the existing "Honest and brief beats thorough and padded" line survives.
- [ ] `scripts/gate.sh` passes.

## Release

Release note: Implementer contract now carries a lazy/YAGNI build ladder (borrowed from ponytail) so codex writes the leanest working diff within scope, with explicit boundaries protecting validation/security/error-handling.

## Verification

- `scripts/gate.sh`
- Diff inspection against the acceptance criteria (docs-only change; no runtime behavior to test).

## Review

Plan-reviewer (fresh thread) verified all codebase claims and returned APPROVE with three minor findings:
1. Soft "≤ ~40 lines" ceiling → **applied**: made it a hard `≤ 45 lines (wc -l)`.
2. "seven ladder rungs" pinned an exact count against paraphrased source → **applied**: softened to "the ladder rungs in priority order" with the rungs listed inline.
3. This is a contract *nudge* with zero enforcement — over-engineering stays undetectable downstream, only less likely. No revision needed; the plan does not overclaim (Done = "codex reaches for the leaner rung by default"). Recorded for the Owner's awareness.

Plan verdict: APPROVE

exec
/bin/zsh -lc 'pwd && git branch --show-current' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/implementer-ladder
 succeeded in 0ms:
/Users/cboyfly/Documents/repos/agentic-coding-worktrees/implementer-ladder
wt/implementer-ladder

codex
The branch matches the handoff, and the plan confirms the footprint is only `AGENTS.md` plus the handoff template. I’m checking the template shape now so the pointer lands in the right place without duplicating the ladder.
exec
/bin/zsh -lc "sed -n '1,260p' .claude/skills/2-implement/prompts/handoff.tpl" in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/implementer-ladder
 succeeded in 0ms:
You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.

Work unit: work/{{SLUG}}/plan.md  (read it in full; it is your source of truth)
Branch: wt/{{SLUG}} (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
{{FILES_TO_MODIFY}}

Key constraints:
{{CONSTRAINTS}}

When done:
1. Run scripts/gate.sh from the repo root — it must pass.
2. Commit your work on this branch with a clear message.
3. Print a final summary: what changed and why, criteria partially met (if any), out-of-scope observations.

exec
/bin/zsh -lc 'git status --short' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/implementer-ladder
 succeeded in 0ms:
exec
/bin/zsh -lc 'wc -l AGENTS.md .claude/skills/2-implement/prompts/handoff.tpl' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/implementer-ladder
 succeeded in 0ms:
      13 AGENTS.md
      15 .claude/skills/2-implement/prompts/handoff.tpl
      28 total

codex
I’m going to add a compact build-discipline section before the preserved closing line, then add a single template sentence that points implementers back to that section. The wording will stay rule-like and avoid restating the ladder in the template.
apply patch
patch: completed
/Users/cboyfly/Documents/repos/agentic-coding-worktrees/implementer-ladder/.claude/skills/2-implement/prompts/handoff.tpl
/Users/cboyfly/Documents/repos/agentic-coding-worktrees/implementer-ladder/AGENTS.md
diff --git a/.claude/skills/2-implement/prompts/handoff.tpl b/.claude/skills/2-implement/prompts/handoff.tpl
index d0b569a9943af6d9aa290729206077d157aaf2dd..7702761b09183825da100e951007cce9e058296c
--- a/.claude/skills/2-implement/prompts/handoff.tpl
+++ b/.claude/skills/2-implement/prompts/handoff.tpl
@@ -1,4 +1,5 @@
 You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.
+Follow its build-discipline section while staying inside the plan footprint.
 
 Work unit: work/{{SLUG}}/plan.md  (read it in full; it is your source of truth)
 Branch: wt/{{SLUG}} (already checked out in this worktree — verify with `git branch --show-current` before changing anything)
diff --git a/AGENTS.md b/AGENTS.md
index b0adffb336f00f77f5c98ff26d9dd524b8988c15..a9fdda75796dc206927acca081f06cc1850f5bbb
--- a/AGENTS.md
+++ b/AGENTS.md
@@ -10,4 +10,22 @@
 4. **Finish with a summary**: what changed and why, any acceptance criteria only partially met (and why), anything you noticed but left out of scope.
 5. **Stop and surface** rather than guess when: acceptance criteria conflict, the plan seems wrong against the actual code, or a decision belongs to the Orchestrator or Owner.
 
+## Build Discipline
+
+Run this after you understand the task and trace the real flow end to end:
+
+1. Does this need to exist at all? If it is speculative, skip it and say so in one line.
+2. Already in this codebase? Reuse the helper, util, type, or pattern that lives here.
+3. Stdlib does it? Use stdlib.
+4. Native platform feature covers it? Use the platform.
+5. Already-installed dependency solves it? Use it. Do not add a dependency for what a few lines do.
+6. Can it be one line? Make it one line.
+7. Only then write the minimum code that works.
+
+For bug fixes, fix the root cause, not the named symptom: grep every caller of the function you touch and prefer one shared guard over per-caller patches.
+
+Never be lazy about understanding the problem, input validation at trust boundaries, error handling that prevents data loss, security, accessibility, or anything explicitly requested or named in the plan.
+
+Use a `ponytail:` comment for a deliberate simplification that cuts a real corner; name the ceiling and upgrade path.
+
 Honest and brief beats thorough and padded.

diff --git a/.claude/skills/2-implement/prompts/handoff.tpl b/.claude/skills/2-implement/prompts/handoff.tpl
index d0b569a9943af6d9aa290729206077d157aaf2dd..7702761b09183825da100e951007cce9e058296c
--- a/.claude/skills/2-implement/prompts/handoff.tpl
+++ b/.claude/skills/2-implement/prompts/handoff.tpl
@@ -1,4 +1,5 @@
 You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.
+Follow its build-discipline section while staying inside the plan footprint.
 
 Work unit: work/{{SLUG}}/plan.md  (read it in full; it is your source of truth)
 Branch: wt/{{SLUG}} (already checked out in this worktree — verify with `git branch --show-current` before changing anything)
diff --git a/AGENTS.md b/AGENTS.md
index b0adffb336f00f77f5c98ff26d9dd524b8988c15..a9fdda75796dc206927acca081f06cc1850f5bbb
--- a/AGENTS.md
+++ b/AGENTS.md
@@ -10,4 +10,22 @@
 4. **Finish with a summary**: what changed and why, any acceptance criteria only partially met (and why), anything you noticed but left out of scope.
 5. **Stop and surface** rather than guess when: acceptance criteria conflict, the plan seems wrong against the actual code, or a decision belongs to the Orchestrator or Owner.
 
+## Build Discipline
+
+Run this after you understand the task and trace the real flow end to end:
+
+1. Does this need to exist at all? If it is speculative, skip it and say so in one line.
+2. Already in this codebase? Reuse the helper, util, type, or pattern that lives here.
+3. Stdlib does it? Use stdlib.
+4. Native platform feature covers it? Use the platform.
+5. Already-installed dependency solves it? Use it. Do not add a dependency for what a few lines do.
+6. Can it be one line? Make it one line.
+7. Only then write the minimum code that works.
+
+For bug fixes, fix the root cause, not the named symptom: grep every caller of the function you touch and prefer one shared guard over per-caller patches.
+
+Never be lazy about understanding the problem, input validation at trust boundaries, error handling that prevents data loss, security, accessibility, or anything explicitly requested or named in the plan.
+
+Use a `ponytail:` comment for a deliberate simplification that cuts a real corner; name the ceiling and upgrade path.
+
 Honest and brief beats thorough and padded.

codex
The two edits are in place. I’m checking line count and the resulting text against the acceptance criteria before running the gate.
exec
/bin/zsh -lc 'wc -l AGENTS.md' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/implementer-ladder
exec
/bin/zsh -lc "sed -n '1,220p' AGENTS.md" in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/implementer-ladder
 succeeded in 0ms:
      31 AGENTS.md

 succeeded in 0ms:
# Implementer Contract

You are the implementer. Your source of truth is the handoff you received; it names the work unit (`work/<slug>/plan.md`), the branch, and the file footprint.

## Rules

1. **Scope is the plan. Nothing more.** No refactoring adjacent code, no speculative features. If the work seems to require a file outside the declared footprint, stop and say so instead of expanding it yourself.
2. **You are in a worktree on a pre-created branch.** Verify the branch matches the handoff before changing anything. Do not switch, merge, rebase, or reset.
3. **Run the gate before finishing:** `scripts/gate.sh` from the repo root. Do not report done while it fails.
4. **Finish with a summary**: what changed and why, any acceptance criteria only partially met (and why), anything you noticed but left out of scope.
5. **Stop and surface** rather than guess when: acceptance criteria conflict, the plan seems wrong against the actual code, or a decision belongs to the Orchestrator or Owner.

## Build Discipline

Run this after you understand the task and trace the real flow end to end:

1. Does this need to exist at all? If it is speculative, skip it and say so in one line.
2. Already in this codebase? Reuse the helper, util, type, or pattern that lives here.
3. Stdlib does it? Use stdlib.
4. Native platform feature covers it? Use the platform.
5. Already-installed dependency solves it? Use it. Do not add a dependency for what a few lines do.
6. Can it be one line? Make it one line.
7. Only then write the minimum code that works.

For bug fixes, fix the root cause, not the named symptom: grep every caller of the function you touch and prefer one shared guard over per-caller patches.

Never be lazy about understanding the problem, input validation at trust boundaries, error handling that prevents data loss, security, accessibility, or anything explicitly requested or named in the plan.

Use a `ponytail:` comment for a deliberate simplification that cuts a real corner; name the ceiling and upgrade path.

Honest and brief beats thorough and padded.

exec
/bin/zsh -lc "sed -n '1,80p' .claude/skills/2-implement/prompts/handoff.tpl" in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/implementer-ladder
 succeeded in 0ms:
You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.
Follow its build-discipline section while staying inside the plan footprint.

Work unit: work/{{SLUG}}/plan.md  (read it in full; it is your source of truth)
Branch: wt/{{SLUG}} (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
{{FILES_TO_MODIFY}}

Key constraints:
{{CONSTRAINTS}}

When done:
1. Run scripts/gate.sh from the repo root — it must pass.
2. Commit your work on this branch with a clear message.
3. Print a final summary: what changed and why, criteria partially met (if any), out-of-scope observations.

exec
/bin/zsh -lc 'git diff -- AGENTS.md .claude/skills/2-implement/prompts/handoff.tpl' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/implementer-ladder
 succeeded in 0ms:
diff --git a/AGENTS.md b/AGENTS.md
index b0adffb..a9fdda7 100644
--- a/AGENTS.md
+++ b/AGENTS.md
@@ -10,4 +10,22 @@ You are the implementer. Your source of truth is the handoff you received; it na
 4. **Finish with a summary**: what changed and why, any acceptance criteria only partially met (and why), anything you noticed but left out of scope.
 5. **Stop and surface** rather than guess when: acceptance criteria conflict, the plan seems wrong against the actual code, or a decision belongs to the Orchestrator or Owner.
 
+## Build Discipline
+
+Run this after you understand the task and trace the real flow end to end:
+
+1. Does this need to exist at all? If it is speculative, skip it and say so in one line.
+2. Already in this codebase? Reuse the helper, util, type, or pattern that lives here.
+3. Stdlib does it? Use stdlib.
+4. Native platform feature covers it? Use the platform.
+5. Already-installed dependency solves it? Use it. Do not add a dependency for what a few lines do.
+6. Can it be one line? Make it one line.
+7. Only then write the minimum code that works.
+
+For bug fixes, fix the root cause, not the named symptom: grep every caller of the function you touch and prefer one shared guard over per-caller patches.
+
+Never be lazy about understanding the problem, input validation at trust boundaries, error handling that prevents data loss, security, accessibility, or anything explicitly requested or named in the plan.
+
+Use a `ponytail:` comment for a deliberate simplification that cuts a real corner; name the ceiling and upgrade path.
+
 Honest and brief beats thorough and padded.

diff --git a/.claude/skills/2-implement/prompts/handoff.tpl b/.claude/skills/2-implement/prompts/handoff.tpl
index d0b569a9943af6d9aa290729206077d157aaf2dd..7702761b09183825da100e951007cce9e058296c
--- a/.claude/skills/2-implement/prompts/handoff.tpl
+++ b/.claude/skills/2-implement/prompts/handoff.tpl
@@ -1,4 +1,5 @@
 You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.
+Follow its build-discipline section while staying inside the plan footprint.
 
 Work unit: work/{{SLUG}}/plan.md  (read it in full; it is your source of truth)
 Branch: wt/{{SLUG}} (already checked out in this worktree — verify with `git branch --show-current` before changing anything)
diff --git a/AGENTS.md b/AGENTS.md
index b0adffb336f00f77f5c98ff26d9dd524b8988c15..a9fdda75796dc206927acca081f06cc1850f5bbb
--- a/AGENTS.md
+++ b/AGENTS.md
@@ -10,4 +10,22 @@
 4. **Finish with a summary**: what changed and why, any acceptance criteria only partially met (and why), anything you noticed but left out of scope.
 5. **Stop and surface** rather than guess when: acceptance criteria conflict, the plan seems wrong against the actual code, or a decision belongs to the Orchestrator or Owner.
 
+## Build Discipline
+
+Run this after you understand the task and trace the real flow end to end:
+
+1. Does this need to exist at all? If it is speculative, skip it and say so in one line.
+2. Already in this codebase? Reuse the helper, util, type, or pattern that lives here.
+3. Stdlib does it? Use stdlib.
+4. Native platform feature covers it? Use the platform.
+5. Already-installed dependency solves it? Use it. Do not add a dependency for what a few lines do.
+6. Can it be one line? Make it one line.
+7. Only then write the minimum code that works.
+
+For bug fixes, fix the root cause, not the named symptom: grep every caller of the function you touch and prefer one shared guard over per-caller patches.
+
+Never be lazy about understanding the problem, input validation at trust boundaries, error handling that prevents data loss, security, accessibility, or anything explicitly requested or named in the plan.
+
+Use a `ponytail:` comment for a deliberate simplification that cuts a real corner; name the ceiling and upgrade path.
+
 Honest and brief beats thorough and padded.

codex
`AGENTS.md` is 31 lines, under the 45-line cap, and the final line is preserved. The ladder is only in `AGENTS.md`; the template just points to it. I’m running the required gate now.
exec
/bin/zsh -lc scripts/gate.sh in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/implementer-ladder
diff --git a/.claude/skills/2-implement/prompts/handoff.tpl b/.claude/skills/2-implement/prompts/handoff.tpl
index d0b569a9943af6d9aa290729206077d157aaf2dd..7702761b09183825da100e951007cce9e058296c
--- a/.claude/skills/2-implement/prompts/handoff.tpl
+++ b/.claude/skills/2-implement/prompts/handoff.tpl
@@ -1,4 +1,5 @@
 You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.
+Follow its build-discipline section while staying inside the plan footprint.
 
 Work unit: work/{{SLUG}}/plan.md  (read it in full; it is your source of truth)
 Branch: wt/{{SLUG}} (already checked out in this worktree — verify with `git branch --show-current` before changing anything)
diff --git a/AGENTS.md b/AGENTS.md
index b0adffb336f00f77f5c98ff26d9dd524b8988c15..a9fdda75796dc206927acca081f06cc1850f5bbb
--- a/AGENTS.md
+++ b/AGENTS.md
@@ -10,4 +10,22 @@
 4. **Finish with a summary**: what changed and why, any acceptance criteria only partially met (and why), anything you noticed but left out of scope.
 5. **Stop and surface** rather than guess when: acceptance criteria conflict, the plan seems wrong against the actual code, or a decision belongs to the Orchestrator or Owner.
 
+## Build Discipline
+
+Run this after you understand the task and trace the real flow end to end:
+
+1. Does this need to exist at all? If it is speculative, skip it and say so in one line.
+2. Already in this codebase? Reuse the helper, util, type, or pattern that lives here.
+3. Stdlib does it? Use stdlib.
+4. Native platform feature covers it? Use the platform.
+5. Already-installed dependency solves it? Use it. Do not add a dependency for what a few lines do.
+6. Can it be one line? Make it one line.
+7. Only then write the minimum code that works.
+
+For bug fixes, fix the root cause, not the named symptom: grep every caller of the function you touch and prefer one shared guard over per-caller patches.
+
+Never be lazy about understanding the problem, input validation at trust boundaries, error handling that prevents data loss, security, accessibility, or anything explicitly requested or named in the plan.
+
+Use a `ponytail:` comment for a deliberate simplification that cuts a real corner; name the ceiling and upgrade path.
+
 Honest and brief beats thorough and padded.

 succeeded in 27203ms:
▶ shellcheck scripts/agent-exec.sh scripts/codex-review.sh scripts/fan-exec.sh scripts/gate.d/examples/ds-hygiene.sh scripts/gate.d/examples/nb-clean.sh scripts/gate.d/test-scripts.sh scripts/gate.sh scripts/release.sh scripts/state.sh scripts/worktree.sh tests/test-scripts.sh
▶ bash scripts/gate.d/test-scripts.sh
ok: shellcheck scripts
ok: state missing plan exits non-zero
ok: state derives plan stage
ok: state derives implement stage
ok: state derives review stage before codex review
ok: state derives release stage before marker
ok: state derives release stage for retro
ok: state derives done stage
ok: state reads review sentinels from wt branch when it exists
ok: state run is read-only
ok: state requires both review approval sentinels
ok: codex-review reads plan body from branch
ok: codex-review reads config from main
ok: codex-review prompt names exact verdict format
ok: codex-review emits verdict instruction after diff
ok: codex-review reads deferrals from branch
ok: codex-review emits deferrals before the diff
ok: 3-review skill routes deferrals to the ledger
ok: code-reviewer agent is told deferrals are settled scope
ok: code-reviewer agent defines severity taxonomy
ok: code-reviewer agent has calibration section
ok: code-reviewer agent requires concrete failure for blocking
ok: codex-review prompt includes severity taxonomy
ok: codex-review prompt includes calibration guidance
ok: codex-review prompt passes round number
ok: 3-review skill tracks round counter
ok: 3-review skill routes by severity
ok: 3-review skill caps at round 3 mechanically
ok: 3-review skill keeps codex-review work artifacts out of diff
ok: codex-review approve exits 0
ok: codex-review writes stdout artifact
ok: codex-review accepts indented approve verdict
ok: codex-review request-changes exits 1
ok: codex-review ignores branch reviewer.command override
ok: codex-review missing verdict exits 2
ok: codex-review missing reviewer.command exits 2
ok: codex-review parser stops before later command
ok: codex-review ignores commented command and uses real one
ok: codex-review missing branch plan exits 2 before reviewer
ok: codex-review does not invoke reviewer when branch plan is missing
ok: codex-review reviewer failure exits 2 before verdict parsing
ok: codex-review reviewer failure preserves previous artifact
ok: codex-review refuses wt checkout as root
ok: codex-review artifact-only run exits 0
ok: codex-review only dirties primary artifact
ok: codex-review leaves worktree branch clean
ok: codex-review with branch artifacts exits 0
ok: codex-review excludes work unit artifacts from reviewer diff
ok: codex-review from subdirectory exits 0
ok: codex-review from subdirectory includes top-level branch diff
ok: codex-review from subdirectory excludes work unit artifacts
ok: codex-review marks an absent deferral ledger explicitly
ok: codex-review with a deferral ledger exits 0
ok: codex-review injects the deferral ledger into the prompt
ok: codex-review deferral ledger is not treated as absent
ok: codex-review prompt includes round number from REVIEW_ROUND
ok: codex-review passes custom round number
ok: codex-review prompt contains round 3
ok: worktree add creates directory
ok: worktree branch checked out
ok: worktree.sh works FROM INSIDE a worktree (.git-as-file)
ok: worktree remove
ok: worktree add without slug fails
ok: worktree add bases new branch on origin/main from feature branch
ok: worktree add falls back to HEAD without origin/main
ok: worktree add uses stale origin/main when fetch fails
ok: worktree add commits plan.md and leaves worktree clean
ok: worktree add resume path does not duplicate plan commit
ok: worktree sync-artifacts without slug fails
ok: worktree sync-artifacts refuses missing worktree
ok: worktree sync-artifacts refuses missing primary work dir
ok: worktree sync-artifacts refuses invocation from unit worktree
ok: worktree sync-artifacts copies primary artifacts
ok: worktree sync-artifacts records handoff notes followup and codex review
ok: worktree sync-artifacts commits non-ASCII artifact filename
ok: worktree sync-artifacts preserves worktree plan sentinels
ok: worktree sync-artifacts excludes dotfiles and subdirectories
ok: worktree sync-artifacts keeps ignored primary stray absent after successful sync
ok: worktree sync-artifacts deliberately commits existing worktree-side unit files
ok: worktree sync-artifacts does not materialize symlink targets
ok: worktree sync-artifacts leaves worktree clean
ok: worktree sync-artifacts idempotent no-op exits zero
ok: worktree sync-artifacts no-op makes no extra commit
ok: worktree sync-artifacts refreshes changed artifact
ok: worktree sync-artifacts copied refreshed notes
ok: worktree sync-artifacts leaves pending worktree plan edit uncommitted
ok: worktree sync-artifacts keeps pending plan edit in worktree
ok: worktree sync-artifacts artifact commit excludes pending plan edit
ok: worktree sync-artifacts ignores unrelated staged files
ok: worktree sync-artifacts commit excludes unrelated staged file
ok: worktree sync-artifacts leaves unrelated unstaged edit alone
ok: worktree sync-artifacts does not stage unrelated worktree edit
ok: worktree sync-artifacts propagates a failed artifact commit
ok: worktree sync-artifacts accepts primary checkout on non-main branch
ok: worktree sync-artifacts synced from non-main primary checkout
ok: worktree sync-artifacts refuses expected path on wrong branch
ok: worktree sync-artifacts wrong branch receives no artifact commit
ok: gate reports skipped node when package.json exists and node is missing
ok: gate reports skipped lines for every missing guarded tool
ok: gate does not report absent cargo go or node in shell-only repo
ok: gate does not report skipped pytest when no tests match
ok: gate does not report skipped node when node check runs
ok: gate required tool passes when fake executable is on PATH
ok: gate required tool fails and names missing executable
ok: gate required tool preflight reports every missing executable
ok: gate required tool preflight aborts before stack checks
ok: gate runs without config.yaml or GATE_REQUIRED_TOOLS
ok: gate uses GATE_REQUIRED_TOOLS instead of config required_tools
ok: gate reads required_tools from config.yaml
ok: gate ignores commented-out required_tools
ok: gate ignores required_tools outside gate section
ok: gate treats empty GATE_REQUIRED_TOOLS as no required tools
ok: agent-exec rejects missing handoff
ok: agent-exec exits 0 when implementer commits
ok: agent-exec exits 0 with relative worktree path when implementer commits
ok: agent-exec exits 0 when implementer cd's elsewhere then commits
ok: agent-exec exits 0 when implementer leaves uncommitted changes
ok: agent-exec exits 0 when dirty redispatch cleans tree without commit
ok: agent-exec exits non-zero when implementer produces nothing
ok: notebook hook flags dirty tracked notebook
ok: notebook hook passes cleaned tracked notebook
ok: ds hygiene hook flags oversized tracked artifact
ok: ds hygiene hook exempts default allowed directory
ok: ds hygiene hook treats empty allow dirs as no allowed dirs
ok: ds hygiene hook flags Unix local path in Python
ok: ds hygiene hook flags Windows local path in Python
ok: ds hygiene hook still flags artifact when path scan is disabled
ok: ds hygiene hook still flags local path when artifact scan is disabled
ok: ds hygiene hook disables artifact scan independently
ok: ds hygiene hook reports artifact and local path together
ok: ds hygiene hook passes clean fixture
ok: ds hygiene hook disables path scan independently
ok: ds hygiene hook skips deleted tracked artifact without stderr
ok: ds hygiene hook honours colon-separated allow dirs
ok: ds hygiene hook ignores empty allow-dir prefix
ok: fan dispatch manifest lists only gate passers
ok: fan adopt repoints canonical branch and cleans samples
ok: fan dispatch auto-commits non-committing sample work
ok: fan adopt preserves auto-committed sample work and cleans samples
ok: fan adopt force-cleans dirty sample worktrees and branches
ok: fan dispatch emits empty manifest and exits 0 with no survivors
ok: release version compare accepts .10 over .9
ok: release version compare rejects .9 after .10
ok: release refuses without code-review approval
ok: release refuses without codex-review approval
ok: release refuses when gate fails
ok: release refuses when ARCHI.md is stale
ok: release refuses when computed version does not exceed VERSION
ok: release can be invoked from primary checkout
ok: release commits bump on branch without touching main, origin/main, or tagging
ok: release writes last-released marker into release commit
ok: release rollback removes first-time last-released marker
ok: release refuses marker with missing retro
ok: release refuses marker with empty retro
ok: release proceeds when previous retro is non-empty
ok: release refuses deleted last-released marker
ok: release refuses mutated last-released marker
ok: release refuses symlinked last-released marker
ok: release refuses last-released marker with extra trailing newline
ok: release re-run on release branch names merge guidance
ok: release refuses empty bootstrap last-released marker
ok: release refuses multi-line bootstrap last-released marker
ok: release refuses symlinked bootstrap last-released marker
ok: release proceeds without last-released marker
ok: release reports stale branch before missing retro
ok: release refuses stale branch, then computes next micro after sync
ok: release catches origin/main moving during gate
ok: tag-after-merge creates local tag on origin/main and pushes nothing
ok: tag-after-merge refuses when origin/main advanced past the release
ok: gate.sh runs on this repo

passed: 170, failed: 0
GATE: PASS

codex
The gate passed. I’m doing one final status/diff check, then I’ll commit the two-file change on the verified branch.
exec
/bin/zsh -lc 'git diff --stat' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/implementer-ladder
 succeeded in 0ms:
 AGENTS.md                              | 18 ++++++++++++++++++
 skills/2-implement/prompts/handoff.tpl |  1 +
 2 files changed, 19 insertions(+)

exec
/bin/zsh -lc 'git status --short' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/implementer-ladder
 succeeded in 0ms:
 M AGENTS.md
 M skills/2-implement/prompts/handoff.tpl

exec
/bin/zsh -lc 'git diff -- .claude/skills/2-implement/prompts/handoff.tpl' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/implementer-ladder
 succeeded in 0ms:
diff --git a/.claude/skills/2-implement/prompts/handoff.tpl b/.claude/skills/2-implement/prompts/handoff.tpl
index d0b569a9943af6d9aa290729206077d157aaf2dd..7702761b09183825da100e951007cce9e058296c
--- a/.claude/skills/2-implement/prompts/handoff.tpl
+++ b/.claude/skills/2-implement/prompts/handoff.tpl
@@ -1,4 +1,5 @@
 You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.
+Follow its build-discipline section while staying inside the plan footprint.
 
 Work unit: work/{{SLUG}}/plan.md  (read it in full; it is your source of truth)
 Branch: wt/{{SLUG}} (already checked out in this worktree — verify with `git branch --show-current` before changing anything)
diff --git a/AGENTS.md b/AGENTS.md
index b0adffb336f00f77f5c98ff26d9dd524b8988c15..a9fdda75796dc206927acca081f06cc1850f5bbb
--- a/AGENTS.md
+++ b/AGENTS.md
@@ -10,4 +10,22 @@
 4. **Finish with a summary**: what changed and why, any acceptance criteria only partially met (and why), anything you noticed but left out of scope.
 5. **Stop and surface** rather than guess when: acceptance criteria conflict, the plan seems wrong against the actual code, or a decision belongs to the Orchestrator or Owner.
 
+## Build Discipline
+
+Run this after you understand the task and trace the real flow end to end:
+
+1. Does this need to exist at all? If it is speculative, skip it and say so in one line.
+2. Already in this codebase? Reuse the helper, util, type, or pattern that lives here.
+3. Stdlib does it? Use stdlib.
+4. Native platform feature covers it? Use the platform.
+5. Already-installed dependency solves it? Use it. Do not add a dependency for what a few lines do.
+6. Can it be one line? Make it one line.
+7. Only then write the minimum code that works.
+
+For bug fixes, fix the root cause, not the named symptom: grep every caller of the function you touch and prefer one shared guard over per-caller patches.
+
+Never be lazy about understanding the problem, input validation at trust boundaries, error handling that prevents data loss, security, accessibility, or anything explicitly requested or named in the plan.
+
+Use a `ponytail:` comment for a deliberate simplification that cuts a real corner; name the ceiling and upgrade path.
+
 Honest and brief beats thorough and padded.

codex
One note from the final check: the template is tracked in git as `skills/2-implement/prompts/handoff.tpl`; the `.claude/...` path in the handoff resolves to that same file. I’ll commit the tracked two-file diff now.
exec
/bin/zsh -lc 'git diff -- skills/2-implement/prompts/handoff.tpl' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/implementer-ladder
 succeeded in 0ms:
diff --git a/skills/2-implement/prompts/handoff.tpl b/skills/2-implement/prompts/handoff.tpl
index d0b569a..7702761 100644
--- a/skills/2-implement/prompts/handoff.tpl
+++ b/skills/2-implement/prompts/handoff.tpl
@@ -1,4 +1,5 @@
 You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.
+Follow its build-discipline section while staying inside the plan footprint.
 
 Work unit: work/{{SLUG}}/plan.md  (read it in full; it is your source of truth)
 Branch: wt/{{SLUG}} (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

exec
/bin/zsh -lc 'ls -ld .claude .claude/skills skills' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/implementer-ladder
 succeeded in 0ms:
drwxr-xr-x  4 cboyfly  staff  128 Sep  4 13:19 .claude
lrwxr-xr-x  1 cboyfly  staff    9 Sep  4 13:19 .claude/skills -> ../skills
drwxr-xr-x  9 cboyfly  staff  288 Sep  4 13:19 skills

diff --git a/.claude/skills/2-implement/prompts/handoff.tpl b/.claude/skills/2-implement/prompts/handoff.tpl
index d0b569a9943af6d9aa290729206077d157aaf2dd..7702761b09183825da100e951007cce9e058296c
--- a/.claude/skills/2-implement/prompts/handoff.tpl
+++ b/.claude/skills/2-implement/prompts/handoff.tpl
@@ -1,4 +1,5 @@
 You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.
+Follow its build-discipline section while staying inside the plan footprint.
 
 Work unit: work/{{SLUG}}/plan.md  (read it in full; it is your source of truth)
 Branch: wt/{{SLUG}} (already checked out in this worktree — verify with `git branch --show-current` before changing anything)
diff --git a/AGENTS.md b/AGENTS.md
index b0adffb336f00f77f5c98ff26d9dd524b8988c15..a9fdda75796dc206927acca081f06cc1850f5bbb
--- a/AGENTS.md
+++ b/AGENTS.md
@@ -10,4 +10,22 @@
 4. **Finish with a summary**: what changed and why, any acceptance criteria only partially met (and why), anything you noticed but left out of scope.
 5. **Stop and surface** rather than guess when: acceptance criteria conflict, the plan seems wrong against the actual code, or a decision belongs to the Orchestrator or Owner.
 
+## Build Discipline
+
+Run this after you understand the task and trace the real flow end to end:
+
+1. Does this need to exist at all? If it is speculative, skip it and say so in one line.
+2. Already in this codebase? Reuse the helper, util, type, or pattern that lives here.
+3. Stdlib does it? Use stdlib.
+4. Native platform feature covers it? Use the platform.
+5. Already-installed dependency solves it? Use it. Do not add a dependency for what a few lines do.
+6. Can it be one line? Make it one line.
+7. Only then write the minimum code that works.
+
+For bug fixes, fix the root cause, not the named symptom: grep every caller of the function you touch and prefer one shared guard over per-caller patches.
+
+Never be lazy about understanding the problem, input validation at trust boundaries, error handling that prevents data loss, security, accessibility, or anything explicitly requested or named in the plan.
+
+Use a `ponytail:` comment for a deliberate simplification that cuts a real corner; name the ceiling and upgrade path.
+
 Honest and brief beats thorough and padded.

exec
/bin/zsh -lc 'git add AGENTS.md skills/2-implement/prompts/handoff.tpl && git commit -m "Add implementer build discipline"' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/implementer-ladder
 succeeded in 0ms:
[wt/implementer-ladder 2b8da48] Add implementer build discipline
 2 files changed, 19 insertions(+)

diff --git a/.claude/skills/2-implement/prompts/handoff.tpl b/.claude/skills/2-implement/prompts/handoff.tpl
index d0b569a9943af6d9aa290729206077d157aaf2dd..7702761b09183825da100e951007cce9e058296c
--- a/.claude/skills/2-implement/prompts/handoff.tpl
+++ b/.claude/skills/2-implement/prompts/handoff.tpl
@@ -1,4 +1,5 @@
 You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.
+Follow its build-discipline section while staying inside the plan footprint.
 
 Work unit: work/{{SLUG}}/plan.md  (read it in full; it is your source of truth)
 Branch: wt/{{SLUG}} (already checked out in this worktree — verify with `git branch --show-current` before changing anything)
diff --git a/AGENTS.md b/AGENTS.md
index b0adffb336f00f77f5c98ff26d9dd524b8988c15..a9fdda75796dc206927acca081f06cc1850f5bbb
--- a/AGENTS.md
+++ b/AGENTS.md
@@ -10,4 +10,22 @@
 4. **Finish with a summary**: what changed and why, any acceptance criteria only partially met (and why), anything you noticed but left out of scope.
 5. **Stop and surface** rather than guess when: acceptance criteria conflict, the plan seems wrong against the actual code, or a decision belongs to the Orchestrator or Owner.
 
+## Build Discipline
+
+Run this after you understand the task and trace the real flow end to end:
+
+1. Does this need to exist at all? If it is speculative, skip it and say so in one line.
+2. Already in this codebase? Reuse the helper, util, type, or pattern that lives here.
+3. Stdlib does it? Use stdlib.
+4. Native platform feature covers it? Use the platform.
+5. Already-installed dependency solves it? Use it. Do not add a dependency for what a few lines do.
+6. Can it be one line? Make it one line.
+7. Only then write the minimum code that works.
+
+For bug fixes, fix the root cause, not the named symptom: grep every caller of the function you touch and prefer one shared guard over per-caller patches.
+
+Never be lazy about understanding the problem, input validation at trust boundaries, error handling that prevents data loss, security, accessibility, or anything explicitly requested or named in the plan.
+
+Use a `ponytail:` comment for a deliberate simplification that cuts a real corner; name the ceiling and upgrade path.
+
 Honest and brief beats thorough and padded.

codex
The commit succeeded. I’m checking the branch state once more so the final summary can include the exact verification result.
exec
/bin/zsh -lc 'wc -l AGENTS.md' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/implementer-ladder
 succeeded in 0ms:
      31 AGENTS.md

exec
/bin/zsh -lc 'git log -1 --oneline' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/implementer-ladder
 succeeded in 0ms:
2b8da48 Add implementer build discipline

exec
/bin/zsh -lc 'git status --short' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/implementer-ladder
 succeeded in 0ms:
diff --git a/.claude/skills/2-implement/prompts/handoff.tpl b/.claude/skills/2-implement/prompts/handoff.tpl
index d0b569a9943af6d9aa290729206077d157aaf2dd..7702761b09183825da100e951007cce9e058296c
--- a/.claude/skills/2-implement/prompts/handoff.tpl
+++ b/.claude/skills/2-implement/prompts/handoff.tpl
@@ -1,4 +1,5 @@
 You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.
+Follow its build-discipline section while staying inside the plan footprint.
 
 Work unit: work/{{SLUG}}/plan.md  (read it in full; it is your source of truth)
 Branch: wt/{{SLUG}} (already checked out in this worktree — verify with `git branch --show-current` before changing anything)
diff --git a/AGENTS.md b/AGENTS.md
index b0adffb336f00f77f5c98ff26d9dd524b8988c15..a9fdda75796dc206927acca081f06cc1850f5bbb
--- a/AGENTS.md
+++ b/AGENTS.md
@@ -10,4 +10,22 @@
 4. **Finish with a summary**: what changed and why, any acceptance criteria only partially met (and why), anything you noticed but left out of scope.
 5. **Stop and surface** rather than guess when: acceptance criteria conflict, the plan seems wrong against the actual code, or a decision belongs to the Orchestrator or Owner.
 
+## Build Discipline
+
+Run this after you understand the task and trace the real flow end to end:
+
+1. Does this need to exist at all? If it is speculative, skip it and say so in one line.
+2. Already in this codebase? Reuse the helper, util, type, or pattern that lives here.
+3. Stdlib does it? Use stdlib.
+4. Native platform feature covers it? Use the platform.
+5. Already-installed dependency solves it? Use it. Do not add a dependency for what a few lines do.
+6. Can it be one line? Make it one line.
+7. Only then write the minimum code that works.
+
+For bug fixes, fix the root cause, not the named symptom: grep every caller of the function you touch and prefer one shared guard over per-caller patches.
+
+Never be lazy about understanding the problem, input validation at trust boundaries, error handling that prevents data loss, security, accessibility, or anything explicitly requested or named in the plan.
+
+Use a `ponytail:` comment for a deliberate simplification that cuts a real corner; name the ceiling and upgrade path.
+
 Honest and brief beats thorough and padded.

codex
Implemented and committed on `wt/implementer-ladder`.

Changed `AGENTS.md` to add a tight `Build Discipline` section with the seven-rung lazy/YAGNI ladder, the understand-first guard, root-cause bug-fix guidance, explicit “never lazy about” boundaries, and the `ponytail:` marker convention. `AGENTS.md` is 31 lines, under the 45-line cap, and the final line is preserved.

Added one reinforcing line to the implementer handoff template pointing at that section without duplicating the ladder.

Verification: `scripts/gate.sh` passed with `GATE: PASS`.

Commit: `2b8da48 Add implementer build discipline`

No acceptance criteria were partially met. Out-of-scope note: `.claude/skills/...` resolves through a symlink to the tracked `skills/...` path; no extra files were touched.
diff --git a/.claude/skills/2-implement/prompts/handoff.tpl b/.claude/skills/2-implement/prompts/handoff.tpl
index d0b569a9943af6d9aa290729206077d157aaf2dd..7702761b09183825da100e951007cce9e058296c
--- a/.claude/skills/2-implement/prompts/handoff.tpl
+++ b/.claude/skills/2-implement/prompts/handoff.tpl
@@ -1,4 +1,5 @@
 You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.
+Follow its build-discipline section while staying inside the plan footprint.
 
 Work unit: work/{{SLUG}}/plan.md  (read it in full; it is your source of truth)
 Branch: wt/{{SLUG}} (already checked out in this worktree — verify with `git branch --show-current` before changing anything)
diff --git a/AGENTS.md b/AGENTS.md
index b0adffb336f00f77f5c98ff26d9dd524b8988c15..a9fdda75796dc206927acca081f06cc1850f5bbb
--- a/AGENTS.md
+++ b/AGENTS.md
@@ -10,4 +10,22 @@
 4. **Finish with a summary**: what changed and why, any acceptance criteria only partially met (and why), anything you noticed but left out of scope.
 5. **Stop and surface** rather than guess when: acceptance criteria conflict, the plan seems wrong against the actual code, or a decision belongs to the Orchestrator or Owner.
 
+## Build Discipline
+
+Run this after you understand the task and trace the real flow end to end:
+
+1. Does this need to exist at all? If it is speculative, skip it and say so in one line.
+2. Already in this codebase? Reuse the helper, util, type, or pattern that lives here.
+3. Stdlib does it? Use stdlib.
+4. Native platform feature covers it? Use the platform.
+5. Already-installed dependency solves it? Use it. Do not add a dependency for what a few lines do.
+6. Can it be one line? Make it one line.
+7. Only then write the minimum code that works.
+
+For bug fixes, fix the root cause, not the named symptom: grep every caller of the function you touch and prefer one shared guard over per-caller patches.
+
+Never be lazy about understanding the problem, input validation at trust boundaries, error handling that prevents data loss, security, accessibility, or anything explicitly requested or named in the plan.
+
+Use a `ponytail:` comment for a deliberate simplification that cuts a real corner; name the ceiling and upgrade path.
+
 Honest and brief beats thorough and padded.

tokens used
19,605
Implemented and committed on `wt/implementer-ladder`.

Changed `AGENTS.md` to add a tight `Build Discipline` section with the seven-rung lazy/YAGNI ladder, the understand-first guard, root-cause bug-fix guidance, explicit “never lazy about” boundaries, and the `ponytail:` marker convention. `AGENTS.md` is 31 lines, under the 45-line cap, and the final line is preserved.

Added one reinforcing line to the implementer handoff template pointing at that section without duplicating the ladder.

Verification: `scripts/gate.sh` passed with `GATE: PASS`.

Commit: `2b8da48 Add implementer build discipline`

No acceptance criteria were partially met. Out-of-scope note: `.claude/skills/...` resolves through a symlink to the tracked `skills/...` path; no extra files were touched.
