Dispatching implementer in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium
  codex exec --sandbox workspace-write - < /Users/cboyfly/Documents/repos/agentic-coding/work/codex-verdict-medium/handoff.md
OpenAI Codex v0.139.0
--------
workdir: /Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium
model: gpt-5.5
provider: openai
approval: never
sandbox: workspace-write [workdir, /tmp, $TMPDIR]
reasoning effort: none
reasoning summaries: none
session id: 01a0650b-4d76-7f40-b498-0f251ebbeab5
--------
user
You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.

Work unit: work/codex-verdict-medium/plan.md  (read it in full; it is your source of truth)
Branch: wt/codex-verdict-medium (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
- `.claude/agents/code-reviewer.md`
- `scripts/codex-review.sh`
- `.claude/skills/3-review/SKILL.md`

Do NOT touch ARCHI.md, VERSION, CHANGELOG.md, the codex-review.sh verdict/exit-code machinery or its parser, or any test file (no test asserts the changed prompt text; the exit-code contract is unchanged).

Key constraints:
- The single design change: MEDIUM findings must NEVER gate the reviewer verdict or force a fresh review round. Only CRITICAL and HIGH produce REQUEST CHANGES, in ANY round. This is identical across both reviewers.

- `.claude/agents/code-reviewer.md`:
  - Severity list: change the MEDIUM line from "Blocks in rounds 1–2 only" to state MEDIUM never sets the verdict — it is reported for the orchestrator to route.
  - The REQUEST CHANGES rule (currently "requires at least one CRITICAL or HIGH finding (or MEDIUM in rounds 1–2)") must read exactly: "requires at least one CRITICAL or HIGH finding" — drop the "(or MEDIUM in rounds 1–2)" clause AND the "(or MEDIUM past round 2)" clause in the same sentence.

- `scripts/codex-review.sh`: apply the same edit to the inlined `## Severity` / `## Calibration` prompt text (the `printf` block, ~lines 108–115). The MEDIUM line currently says "Blocks rounds 1-2 only" — change it so MEDIUM never sets the verdict. Keep the CRITICAL/HIGH "REQUEST CHANGES requires at least one CRITICAL or HIGH finding" rule. Do NOT change the round number being passed (REVIEW_ROUND / "This is review round N"), the verdict-parsing logic, or the exit-code contract.

- `.claude/skills/3-review/SKILL.md`:
  - Step 4 routing (line 17): CRITICAL/HIGH → back to implementer via /2-implement (the exit-1 cases). MEDIUM → the orchestrator judges once: fix directly, send back only if load-bearing, or append to deferrals.md — but MEDIUM never forces a fresh review round by itself. LOW → record only.
  - Drop BOTH MEDIUM auto-triage phrasings: line 17's "block in rounds 1–2; in round 3+, auto-triage" and line 21's "after 3, auto-triage remaining MEDIUM findings to deferrals". The 3-round cap stays as a safety net for CRITICAL/HIGH churn; only CRITICAL/HIGH block and escalate at round 3.
  - After the edit, `grep -n 'rounds 1\|auto-triage remaining MEDIUM' .claude/skills/3-review/SKILL.md` must return nothing.

Acceptance criteria (verbatim from the plan):
- `.claude/agents/code-reviewer.md` no longer contains `rounds 1–2` or `rounds 1-2` anywhere, and its MEDIUM Severity line states it never sets the verdict.
- `.claude/agents/code-reviewer.md`'s REQUEST CHANGES rule reads exactly "requires at least one CRITICAL or HIGH finding" with no MEDIUM clause.
- `scripts/codex-review.sh`'s prompt no longer contains `Blocks rounds 1-2`; its MEDIUM line states MEDIUM never sets the verdict; the CRITICAL/HIGH REQUEST CHANGES rule is retained.
- `.claude/skills/3-review/SKILL.md` step 4 no longer routes MEDIUM as a round-blocking finding; MEDIUM is orchestrator-routed; only CRITICAL/HIGH block.
- `bash scripts/gate.sh` is green.

When done:
1. Run scripts/gate.sh from the repo root — it must pass.
2. Commit your work on this branch with a clear message.
3. Print a final summary: what changed and why, criteria partially met (if any), out-of-scope observations.

codex
I’ll first read the repo contract and the work-unit plan, then verify the branch before touching the three allowed files.
exec
/bin/zsh -lc "sed -n '1,220p' AGENTS.md" in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium
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

exec
/bin/zsh -lc 'pwd && git branch --show-current' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium
 succeeded in 0ms:
/Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium
wt/codex-verdict-medium

exec
/bin/zsh -lc "sed -n '1,260p' work/codex-verdict-medium/plan.md" in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium
 succeeded in 0ms:
# MEDIUM findings never gate the review verdict

**Slug:** codex-verdict-medium · **Date:** 2026-09-02 · **Status:** draft

## Goal

Reviews structurally run to the 3-round cap. The cause is the review contract, not a bug: both reviewers are told MEDIUM findings block in rounds 1–2. Because each round spawns a *fresh, cold* reviewer with no memory of prior rounds, every round surfaces a different batch of MEDIUM-flavored nits (robustness gaps, missing validation) on a diff that already meets its acceptance criteria. Round 1's MEDIUMs get fixed; round 2's reviewer finds new ones; repeat until the round-3 auto-triage forces a stop. The verdict never converges on its own.

`codex-review.sh` additionally contradicts itself: its prompt says `MEDIUM … Blocks rounds 1-2 only` yet its calibration says `REQUEST CHANGES requires at least one CRITICAL or HIGH finding` (no MEDIUM qualifier), so which way a MEDIUM-only diff resolves is nondeterministic per run. The Claude `code-reviewer` agent is internally consistent but encodes the same round-burning design.

Done looks like: MEDIUM never sets the verdict in either reviewer. Only CRITICAL/HIGH produce `REQUEST CHANGES`, in any round. A diff meeting its criteria with only MEDIUM/LOW findings is an APPROVE in round 1, with those findings attached for the orchestrator to route.

## Approach

Make the verdict a pure function of CRITICAL/HIGH presence, identically in both reviewers, and move MEDIUM handling entirely to the orchestrator (which already sees the artifact).

1. **`.claude/agents/code-reviewer.md`** — Severity: change MEDIUM from "Blocks in rounds 1–2 only" to "Never sets the verdict; report it for the orchestrator to route." Calibration/Output: `REQUEST CHANGES requires at least one CRITICAL or HIGH finding` — drop the `(or MEDIUM in rounds 1–2)` clause and the `(or MEDIUM past round 2)` clause.
2. **`scripts/codex-review.sh`** — same edit to the inlined `## Severity` / `## Calibration` prompt text: MEDIUM never blocks; REQUEST CHANGES iff CRITICAL/HIGH. This also removes the existing self-contradiction. The round number is still passed (kept for the reviewer's context and the artifact header) but no longer changes the verdict rule.
3. **`.claude/skills/3-review/SKILL.md`** — step 4 routing (line 17): CRITICAL/HIGH → back to implementer via `/2-implement` (these are exactly the exit-1 cases). MEDIUM → orchestrator judges once: fix directly / send back if load-bearing / append to `deferrals.md` — but MEDIUM never forces a fresh review round by itself. LOW → record only. Step 5 (line 21): the 3-round cap stays as a safety net for CRITICAL/HIGH churn; drop **both** MEDIUM auto-triage phrasings — line 17's "round 3+, auto-triage MEDIUM" and line 21's "after 3, auto-triage remaining MEDIUM findings to deferrals" — since MEDIUM no longer blocks. The exit-code contract (0=APPROVE, 1=REQUEST CHANGES, ≥2=tooling) is unchanged.

Alternative considered — just add the missing `(or MEDIUM in rounds 1–2)` qualifier to `codex-review.sh` to match the Claude agent: rejected, it makes codex internally consistent but preserves (per its own design) the exact round-burning the Owner reported.

## Footprint

Files to modify:
- `.claude/agents/code-reviewer.md`
- `scripts/codex-review.sh`
- `.claude/skills/3-review/SKILL.md`

Files NOT to touch:
- `ARCHI.md` — regenerated by `/compact`, never hand-groomed. Editing `codex-review.sh`/`SKILL.md` trips the release-time ARCHI-freshness check, but ARCHI's content needs no change: line 25 describes `/3-review` only as "dual-vendor, both APPROVE required," with no MEDIUM/round language. The `/4-release` remedy is a freshness bump (touch ARCHI on the branch) per the 2026-09-01 decision, not a content edit — nothing to rewrite.
- The `codex-review.sh` verdict/exit-code machinery and its parser — contract unchanged.

## Acceptance criteria

- [ ] `.claude/agents/code-reviewer.md` no longer contains `rounds 1–2` (or `rounds 1-2`) anywhere, and its Severity line for MEDIUM states it never sets the verdict.
- [ ] `.claude/agents/code-reviewer.md`'s REQUEST CHANGES rule reads exactly "requires at least one CRITICAL or HIGH finding" with no MEDIUM clause.
- [ ] `scripts/codex-review.sh`'s prompt no longer contains `Blocks rounds 1-2` and its MEDIUM line states MEDIUM never sets the verdict; the CRITICAL/HIGH `REQUEST CHANGES` rule is retained.
- [ ] `.claude/skills/3-review/SKILL.md` step 4 no longer routes MEDIUM as a round-blocking finding; MEDIUM is orchestrator-routed (fix/defer/optional send-back) and only CRITICAL/HIGH block.
- [ ] `bash scripts/gate.sh` is green (shellcheck + 170 smoke checks; the hermetic codex-review canned reviewer ignores prompt text, so the exit-code matrix still passes).

## Release

Release note: Review verdict now converges — MEDIUM findings are reported and orchestrator-routed but never gate the reviewer verdict or force extra rounds; only CRITICAL/HIGH block. Fixes both reviewers and resolves the codex-review.sh self-contradiction.

## Verification

- `bash scripts/gate.sh`
- `grep -n 'rounds 1\|auto-triage remaining MEDIUM' .claude/agents/code-reviewer.md scripts/codex-review.sh .claude/skills/3-review/SKILL.md` returns nothing.

## Review

plan-reviewer (opus, fresh): APPROVE. Verified the three edit sites are the only places MEDIUM-blocking is encoded (grepped the whole tree). Two minor clarity findings, both applied: (1) added `SKILL.md` to the verification grep and named line 21's second `auto-triage remaining MEDIUM` occurrence in Approach step 3; (2) stated the ARCHI remedy is a freshness bump, not a content edit. Confirmed gate stays green — no test asserts the changed prompt text; the round counter is retained (removing it would balloon the footprint into tests 746/747/749/830–837).

Plan verdict: APPROVE

codex
The branch matches the handoff, and the plan confirms the same three-file footprint. I’m reading those exact sections now so the edit stays narrowly inside the requested prompt/routing text.
exec
/bin/zsh -lc "sed -n '1,220p' .claude/agents/code-reviewer.md" in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium
exec
/bin/zsh -lc "sed -n '1,80p' .claude/skills/3-review/SKILL.md" in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium
 succeeded in 0ms:
---
name: code-reviewer
description: Reviews an implementation diff against its plan. Read-only. Spawned fresh by /3-review — never reuse the orchestrator thread or any thread that touched the implementation.
tools: Read, Grep, Glob, Bash
model: opus
---

You review a diff cold. You did not write it, you did not watch it being written, and you cannot edit it.

You receive: the diff, the plan (`work/<slug>/plan.md`), the accepted-deferral ledger (`work/<slug>/deferrals.md`, possibly empty), and read access to the checkout. You never receive the implementation conversation — judge only what is in front of you.

Procedure:

1. Read the plan first — its goal, footprint, and acceptance criteria are the review standard. Not your taste.
2. Read the full diff. Then read enough surrounding code to judge integration, not just the hunks.
3. Check each acceptance criterion individually: met / unmet / unverifiable. For behavioral criteria, name what evidence would settle them.
4. Check the footprint: files touched outside the declared list are findings, even if the change is good.
5. Run the gate yourself (`scripts/gate.sh`) — do not take reported results on faith.
6. Read the deferral ledger. Those items are settled scope from earlier rounds — do not raise them as findings. If one has become blocking, put it under a `Deferral challenge` heading and name what changed since it was accepted.
7. Hunt for the failure case: for each non-trivial hunk, ask what input or state makes this wrong, and say it concretely.

## Severity

Every finding gets exactly one severity:

- **CRITICAL** — data loss, security hole, or silent wrong result. Blocks in any round.
- **HIGH** — incorrect behavior under a realistic scenario. Blocks in any round.
- **MEDIUM** — robustness gap, missing validation, or incomplete contract. Blocks in rounds 1–2 only.
- **LOW** — style, naming, log hygiene, non-blocking edge cases. Never blocks.

A finding without a concrete failure scenario is LOW by definition — "this could be a problem" is not blocking.

## Calibration

Focus on what breaks the plan's acceptance criteria, not on what you would write differently. A diff that meets every criterion with no CRITICAL/HIGH findings is an APPROVE, even if you see things you'd improve. Report those as LOW.

## Output

Verdict (`APPROVE` / `REQUEST CHANGES`) plus numbered findings, each with severity, file:line, and a concrete failure scenario or criterion reference. Most severe first. No praise padding.

A `REQUEST CHANGES` verdict requires at least one CRITICAL or HIGH finding (or MEDIUM in rounds 1–2). If all findings are LOW (or MEDIUM past round 2), the verdict must be `APPROVE` with findings attached — a reviewer that blocks on LOW-only findings is miscalibrated.

 succeeded in 0ms:
---
name: 3-review
description: Run an independent code review of an implemented work unit via a fresh code-reviewer subagent, then drive the fix loop to a merge-ready state. Use after /2-implement passes the gate.
---

# /3-review — independent review

Input: a work unit whose worktree branch `wt/<slug>` passed the gate.

## Steps

1. **Assemble artifacts, not transcripts:** the diff (`git diff main...wt/<slug> -- ':/' ":(exclude,top)work/<slug>"`), the plan path, the accepted-deferral ledger `work/<slug>/deferrals.md` (pass `(none recorded)` if it does not exist), and nothing else, so synced handoffs, followups, and other reviewer artifacts cannot leak into the review. Reviewers must never see the implementation conversation or your own commentary on the diff.
2. **Track the round.** Before each review, read the round counter `work/<slug>/review-round` (create it with `1` if absent). Increment it after each completed round. This file is the mechanical truth for how many rounds have run — do not count from memory or conversation context. Pass the current round number to both reviewers (the code-reviewer agent in its prompt, and codex-review.sh via `REVIEW_ROUND`).
3. **Spawn both reviewers.** Launch the `code-reviewer` agent (fresh thread) with the diff, the plan path, the deferral ledger path, the current round number, and the worktree path, instructed to review per its own definition. From the primary checkout, run `REVIEW_ROUND=<N> scripts/codex-review.sh <slug>` so Codex reviews the branch plan and diff from cold, read-only context and writes `work/<slug>/codex-review.md`. Its exit-code contract is: 0 = APPROVE, so record the sentinel; 1 = REQUEST CHANGES, so route the artifact's findings to the followup flow; >=2 = tooling error, not a verdict. Never record a sentinel from prose in the artifact after a non-zero exit; fix the tooling and re-run.
4. **Route findings by severity:**
   - **CRITICAL/HIGH** → back to the implementer via `/2-implement`'s followup flow (same worktree). These block regardless of round.
   - **MEDIUM** → block in rounds 1–2; in round 3+, auto-triage to `work/<slug>/deferrals.md` for the next unit unless you judge them load-bearing.
   - **LOW** → never block. Record in the review artifact for the implementer's awareness but do not send back for a fix round.
   - Trivial mechanical fixes (typo-grade) → you may fix them directly, but then the re-review in the next step is mandatory, because you just became a writer.
   - Findings you and the Owner deliberately scope to a later unit → append to `work/<slug>/deferrals.md` in the worktree *before* the next round, one entry per finding: what was raised, why it was deferred, and where it lands. A deferral that is not written down does not exist for the next cold reviewer, and will be raised again.
5. **Re-review after any change:** spawn a *new* fresh code-reviewer thread and re-run `scripts/codex-review.sh <slug>` on the updated diff. Increment `work/<slug>/review-round` before each new round. Repeat until both approve or the counter reaches 3 — after 3, auto-triage remaining MEDIUM findings to deferrals and escalate any open CRITICAL/HIGH to the Owner. Do not start round 4.
6. **Record the approved result on the worktree branch:** when both reviewers approve, edit `work/<slug>/plan.md` in the worktree in place to include both `Code-review verdict: APPROVE` and `Codex-review verdict: APPROVE`, flip its status, and sync the current plan body. Commit that plan update in a single commit with `git -C <worktree> add work/<slug>/plan.md` and `git -C <worktree> commit ...`, then from the repo root run `scripts/worktree.sh sync-artifacts <slug>`. Do not `cp` over it from the primary checkout, because that can clobber the sentinels.
7. **Hand off to release:** report both verdicts, findings summary (resolved and open), and gate status to the Owner, then proceed through the full `/4-release` TRIP.

## Rules

- A reviewer thread or Codex reviewer run is used exactly once. Re-reviews get new fresh reviews — a reviewer that already approved a direction is anchored.
- Record final verdicts in the worktree plan's Review section as `Code-review verdict: APPROVE|REVISE` and `Codex-review verdict: APPROVE|REQUEST CHANGES`.

exec
/bin/zsh -lc "sed -n '90,140p' scripts/codex-review.sh" in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium
 succeeded in 0ms:

if git cat-file -e "$branch:$deferrals_path" 2>/dev/null; then
  git show "$branch:$deferrals_path" >>"$prompt" \
    || die2 "cannot read deferrals from $branch:$deferrals_path"
else
  printf '(none recorded)\n' >>"$prompt"
fi

printf '\n%s\n' "--- DIFF (main...$branch excluding work/$slug) ---" >>"$prompt"
git diff "main...$branch" -- ':/' ":(exclude,top)work/$slug" >>"$prompt" \
  || die2 "cannot diff main...$branch"

{
  printf '\n'
  printf '## Severity\n\n'
  printf 'Every finding gets exactly one severity:\n'
  printf '- CRITICAL: data loss, security hole, or silent wrong result. Blocks in any round.\n'
  printf '- HIGH: incorrect behavior under a realistic scenario. Blocks in any round.\n'
  printf '- MEDIUM: robustness gap, missing validation, or incomplete contract. Blocks rounds 1-2 only.\n'
  printf '- LOW: style, naming, log hygiene, non-blocking edge cases. Never blocks.\n\n'
  printf 'A finding without a concrete failure scenario is LOW by definition.\n\n'
  printf '## Calibration\n\n'
  printf 'Focus on what breaks the acceptance criteria, not on what you would write differently.\n'
  printf 'A diff that meets every criterion with no CRITICAL/HIGH findings is an APPROVE,\n'
  printf 'even if you see things you would improve. Report those as LOW.\n'
  printf 'REQUEST CHANGES requires at least one CRITICAL or HIGH finding.\n'
  printf 'If all findings are LOW, the verdict must be APPROVE with findings attached.\n\n'
  printf 'Your final line must be exactly one of:\n'
  printf 'Codex verdict: APPROVE\n'
  printf 'Codex verdict: REQUEST CHANGES\n'
} >>"$prompt"

artifact_tmp=$(mktemp "$root/work/$slug/.codex-review.XXXXXX") \
  || die2 "cannot create temporary artifact in $root/work/$slug"

bash -c "$reviewer_command" <"$prompt" >"$artifact_tmp"
reviewer_status=$?
if [[ "$reviewer_status" -ne 0 ]]; then
  die2 "reviewer command failed (exit $reviewer_status)"
fi

mv "$artifact_tmp" "$artifact" \
  || die2 "cannot write artifact: $artifact"
artifact_tmp=""

verdict_line=$(grep -E '^[[:space:]]*Codex verdict:' "$artifact" | tail -n 1 || true)
if [[ -z "$verdict_line" ]]; then
  die2 "no verdict in $artifact"
fi

verdict=${verdict_line#"${verdict_line%%[![:space:]]*}"}

exec
/bin/zsh -lc 'rg -n "MEDIUM|REQUEST CHANGES|rounds 1|round 3|auto-triage|Blocks" .claude/agents/code-reviewer.md scripts/codex-review.sh .claude/skills/3-review/SKILL.md' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium
 succeeded in 0ms:
.claude/skills/3-review/SKILL.md:14:3. **Spawn both reviewers.** Launch the `code-reviewer` agent (fresh thread) with the diff, the plan path, the deferral ledger path, the current round number, and the worktree path, instructed to review per its own definition. From the primary checkout, run `REVIEW_ROUND=<N> scripts/codex-review.sh <slug>` so Codex reviews the branch plan and diff from cold, read-only context and writes `work/<slug>/codex-review.md`. Its exit-code contract is: 0 = APPROVE, so record the sentinel; 1 = REQUEST CHANGES, so route the artifact's findings to the followup flow; >=2 = tooling error, not a verdict. Never record a sentinel from prose in the artifact after a non-zero exit; fix the tooling and re-run.
.claude/skills/3-review/SKILL.md:17:   - **MEDIUM** → block in rounds 1–2; in round 3+, auto-triage to `work/<slug>/deferrals.md` for the next unit unless you judge them load-bearing.
.claude/skills/3-review/SKILL.md:21:5. **Re-review after any change:** spawn a *new* fresh code-reviewer thread and re-run `scripts/codex-review.sh <slug>` on the updated diff. Increment `work/<slug>/review-round` before each new round. Repeat until both approve or the counter reaches 3 — after 3, auto-triage remaining MEDIUM findings to deferrals and escalate any open CRITICAL/HIGH to the Owner. Do not start round 4.
.claude/skills/3-review/SKILL.md:28:- Record final verdicts in the worktree plan's Review section as `Code-review verdict: APPROVE|REVISE` and `Codex-review verdict: APPROVE|REQUEST CHANGES`.
scripts/codex-review.sh:106:  printf '- CRITICAL: data loss, security hole, or silent wrong result. Blocks in any round.\n'
scripts/codex-review.sh:107:  printf '- HIGH: incorrect behavior under a realistic scenario. Blocks in any round.\n'
scripts/codex-review.sh:108:  printf '- MEDIUM: robustness gap, missing validation, or incomplete contract. Blocks rounds 1-2 only.\n'
scripts/codex-review.sh:115:  printf 'REQUEST CHANGES requires at least one CRITICAL or HIGH finding.\n'
scripts/codex-review.sh:119:  printf 'Codex verdict: REQUEST CHANGES\n'
scripts/codex-review.sh:149:  "REQUEST CHANGES")
.claude/agents/code-reviewer.md:26:- **CRITICAL** — data loss, security hole, or silent wrong result. Blocks in any round.
.claude/agents/code-reviewer.md:27:- **HIGH** — incorrect behavior under a realistic scenario. Blocks in any round.
.claude/agents/code-reviewer.md:28:- **MEDIUM** — robustness gap, missing validation, or incomplete contract. Blocks in rounds 1–2 only.
.claude/agents/code-reviewer.md:39:Verdict (`APPROVE` / `REQUEST CHANGES`) plus numbered findings, each with severity, file:line, and a concrete failure scenario or criterion reference. Most severe first. No praise padding.
.claude/agents/code-reviewer.md:41:A `REQUEST CHANGES` verdict requires at least one CRITICAL or HIGH finding (or MEDIUM in rounds 1–2). If all findings are LOW (or MEDIUM past round 2), the verdict must be `APPROVE` with findings attached — a reviewer that blocks on LOW-only findings is miscalibrated.

codex
I found only the expected MEDIUM-gating phrases in the allowed files. I’m replacing them with the plan’s rule: MEDIUM is reported for orchestrator routing, while only CRITICAL/HIGH block or drive more rounds.
apply patch
patch: completed
/Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium/.claude/agents/code-reviewer.md
/Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium/.claude/skills/3-review/SKILL.md
/Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium/scripts/codex-review.sh
diff --git a/.claude/agents/code-reviewer.md b/.claude/agents/code-reviewer.md
index 2141a2c90d23e1d01619ff4850c12031a01c65a5..b4c253732a455036f79e478995ac69e860f0ad21
--- a/.claude/agents/code-reviewer.md
+++ b/.claude/agents/code-reviewer.md
@@ -25,7 +25,7 @@
 
 - **CRITICAL** — data loss, security hole, or silent wrong result. Blocks in any round.
 - **HIGH** — incorrect behavior under a realistic scenario. Blocks in any round.
-- **MEDIUM** — robustness gap, missing validation, or incomplete contract. Blocks in rounds 1–2 only.
+- **MEDIUM** — robustness gap, missing validation, or incomplete contract. Never sets the verdict; report it for the orchestrator to route.
 - **LOW** — style, naming, log hygiene, non-blocking edge cases. Never blocks.
 
 A finding without a concrete failure scenario is LOW by definition — "this could be a problem" is not blocking.
@@ -38,4 +38,4 @@
 
 Verdict (`APPROVE` / `REQUEST CHANGES`) plus numbered findings, each with severity, file:line, and a concrete failure scenario or criterion reference. Most severe first. No praise padding.
 
-A `REQUEST CHANGES` verdict requires at least one CRITICAL or HIGH finding (or MEDIUM in rounds 1–2). If all findings are LOW (or MEDIUM past round 2), the verdict must be `APPROVE` with findings attached — a reviewer that blocks on LOW-only findings is miscalibrated.
+A `REQUEST CHANGES` verdict requires at least one CRITICAL or HIGH finding. If all findings are LOW or MEDIUM, the verdict must be `APPROVE` with findings attached — a reviewer that blocks on LOW-only findings is miscalibrated.
diff --git a/.claude/skills/3-review/SKILL.md b/.claude/skills/3-review/SKILL.md
index 685c4631183ebd26365df64001bd16f5ba99c077..aafd4278237955aa1e6306cde28b91632bd645fb
--- a/.claude/skills/3-review/SKILL.md
+++ b/.claude/skills/3-review/SKILL.md
@@ -14,11 +14,11 @@
 3. **Spawn both reviewers.** Launch the `code-reviewer` agent (fresh thread) with the diff, the plan path, the deferral ledger path, the current round number, and the worktree path, instructed to review per its own definition. From the primary checkout, run `REVIEW_ROUND=<N> scripts/codex-review.sh <slug>` so Codex reviews the branch plan and diff from cold, read-only context and writes `work/<slug>/codex-review.md`. Its exit-code contract is: 0 = APPROVE, so record the sentinel; 1 = REQUEST CHANGES, so route the artifact's findings to the followup flow; >=2 = tooling error, not a verdict. Never record a sentinel from prose in the artifact after a non-zero exit; fix the tooling and re-run.
 4. **Route findings by severity:**
    - **CRITICAL/HIGH** → back to the implementer via `/2-implement`'s followup flow (same worktree). These block regardless of round.
-   - **MEDIUM** → block in rounds 1–2; in round 3+, auto-triage to `work/<slug>/deferrals.md` for the next unit unless you judge them load-bearing.
+   - **MEDIUM** → the orchestrator judges once: fix directly, send back only if load-bearing, or append to `work/<slug>/deferrals.md` for the next unit. MEDIUM never forces a fresh review round by itself.
    - **LOW** → never block. Record in the review artifact for the implementer's awareness but do not send back for a fix round.
    - Trivial mechanical fixes (typo-grade) → you may fix them directly, but then the re-review in the next step is mandatory, because you just became a writer.
    - Findings you and the Owner deliberately scope to a later unit → append to `work/<slug>/deferrals.md` in the worktree *before* the next round, one entry per finding: what was raised, why it was deferred, and where it lands. A deferral that is not written down does not exist for the next cold reviewer, and will be raised again.
-5. **Re-review after any change:** spawn a *new* fresh code-reviewer thread and re-run `scripts/codex-review.sh <slug>` on the updated diff. Increment `work/<slug>/review-round` before each new round. Repeat until both approve or the counter reaches 3 — after 3, auto-triage remaining MEDIUM findings to deferrals and escalate any open CRITICAL/HIGH to the Owner. Do not start round 4.
+5. **Re-review after any change:** spawn a *new* fresh code-reviewer thread and re-run `scripts/codex-review.sh <slug>` on the updated diff. Increment `work/<slug>/review-round` before each new round. Repeat until both approve or the counter reaches 3. The 3-round cap is a safety net for CRITICAL/HIGH churn; escalate any open CRITICAL/HIGH to the Owner. Do not start round 4.
 6. **Record the approved result on the worktree branch:** when both reviewers approve, edit `work/<slug>/plan.md` in the worktree in place to include both `Code-review verdict: APPROVE` and `Codex-review verdict: APPROVE`, flip its status, and sync the current plan body. Commit that plan update in a single commit with `git -C <worktree> add work/<slug>/plan.md` and `git -C <worktree> commit ...`, then from the repo root run `scripts/worktree.sh sync-artifacts <slug>`. Do not `cp` over it from the primary checkout, because that can clobber the sentinels.
 7. **Hand off to release:** report both verdicts, findings summary (resolved and open), and gate status to the Owner, then proceed through the full `/4-release` TRIP.
 
diff --git a/scripts/codex-review.sh b/scripts/codex-review.sh
index 1e5b42bbe6e22f3f031450ede3bb896026cbe39c..c63852b709b2ed73c717c3a43e543f18fd4f8ee8
--- a/scripts/codex-review.sh
+++ b/scripts/codex-review.sh
@@ -105,7 +105,7 @@
   printf 'Every finding gets exactly one severity:\n'
   printf '- CRITICAL: data loss, security hole, or silent wrong result. Blocks in any round.\n'
   printf '- HIGH: incorrect behavior under a realistic scenario. Blocks in any round.\n'
-  printf '- MEDIUM: robustness gap, missing validation, or incomplete contract. Blocks rounds 1-2 only.\n'
+  printf '- MEDIUM: robustness gap, missing validation, or incomplete contract. Never sets the verdict; report it for the orchestrator to route.\n'
   printf '- LOW: style, naming, log hygiene, non-blocking edge cases. Never blocks.\n\n'
   printf 'A finding without a concrete failure scenario is LOW by definition.\n\n'
   printf '## Calibration\n\n'

diff --git a/.claude/agents/code-reviewer.md b/.claude/agents/code-reviewer.md
index 2141a2c90d23e1d01619ff4850c12031a01c65a5..b4c253732a455036f79e478995ac69e860f0ad21
--- a/.claude/agents/code-reviewer.md
+++ b/.claude/agents/code-reviewer.md
@@ -25,7 +25,7 @@
 
 - **CRITICAL** — data loss, security hole, or silent wrong result. Blocks in any round.
 - **HIGH** — incorrect behavior under a realistic scenario. Blocks in any round.
-- **MEDIUM** — robustness gap, missing validation, or incomplete contract. Blocks in rounds 1–2 only.
+- **MEDIUM** — robustness gap, missing validation, or incomplete contract. Never sets the verdict; report it for the orchestrator to route.
 - **LOW** — style, naming, log hygiene, non-blocking edge cases. Never blocks.
 
 A finding without a concrete failure scenario is LOW by definition — "this could be a problem" is not blocking.
@@ -38,4 +38,4 @@
 
 Verdict (`APPROVE` / `REQUEST CHANGES`) plus numbered findings, each with severity, file:line, and a concrete failure scenario or criterion reference. Most severe first. No praise padding.
 
-A `REQUEST CHANGES` verdict requires at least one CRITICAL or HIGH finding (or MEDIUM in rounds 1–2). If all findings are LOW (or MEDIUM past round 2), the verdict must be `APPROVE` with findings attached — a reviewer that blocks on LOW-only findings is miscalibrated.
+A `REQUEST CHANGES` verdict requires at least one CRITICAL or HIGH finding. If all findings are LOW or MEDIUM, the verdict must be `APPROVE` with findings attached — a reviewer that blocks on LOW-only findings is miscalibrated.
diff --git a/.claude/skills/3-review/SKILL.md b/.claude/skills/3-review/SKILL.md
index 685c4631183ebd26365df64001bd16f5ba99c077..aafd4278237955aa1e6306cde28b91632bd645fb
--- a/.claude/skills/3-review/SKILL.md
+++ b/.claude/skills/3-review/SKILL.md
@@ -14,11 +14,11 @@
 3. **Spawn both reviewers.** Launch the `code-reviewer` agent (fresh thread) with the diff, the plan path, the deferral ledger path, the current round number, and the worktree path, instructed to review per its own definition. From the primary checkout, run `REVIEW_ROUND=<N> scripts/codex-review.sh <slug>` so Codex reviews the branch plan and diff from cold, read-only context and writes `work/<slug>/codex-review.md`. Its exit-code contract is: 0 = APPROVE, so record the sentinel; 1 = REQUEST CHANGES, so route the artifact's findings to the followup flow; >=2 = tooling error, not a verdict. Never record a sentinel from prose in the artifact after a non-zero exit; fix the tooling and re-run.
 4. **Route findings by severity:**
    - **CRITICAL/HIGH** → back to the implementer via `/2-implement`'s followup flow (same worktree). These block regardless of round.
-   - **MEDIUM** → block in rounds 1–2; in round 3+, auto-triage to `work/<slug>/deferrals.md` for the next unit unless you judge them load-bearing.
+   - **MEDIUM** → the orchestrator judges once: fix directly, send back only if load-bearing, or append to `work/<slug>/deferrals.md` for the next unit. MEDIUM never forces a fresh review round by itself.
    - **LOW** → never block. Record in the review artifact for the implementer's awareness but do not send back for a fix round.
    - Trivial mechanical fixes (typo-grade) → you may fix them directly, but then the re-review in the next step is mandatory, because you just became a writer.
    - Findings you and the Owner deliberately scope to a later unit → append to `work/<slug>/deferrals.md` in the worktree *before* the next round, one entry per finding: what was raised, why it was deferred, and where it lands. A deferral that is not written down does not exist for the next cold reviewer, and will be raised again.
-5. **Re-review after any change:** spawn a *new* fresh code-reviewer thread and re-run `scripts/codex-review.sh <slug>` on the updated diff. Increment `work/<slug>/review-round` before each new round. Repeat until both approve or the counter reaches 3 — after 3, auto-triage remaining MEDIUM findings to deferrals and escalate any open CRITICAL/HIGH to the Owner. Do not start round 4.
+5. **Re-review after any change:** spawn a *new* fresh code-reviewer thread and re-run `scripts/codex-review.sh <slug>` on the updated diff. Increment `work/<slug>/review-round` before each new round. Repeat until both approve or the counter reaches 3. The 3-round cap is a safety net for CRITICAL/HIGH churn; escalate any open CRITICAL/HIGH to the Owner. Do not start round 4.
 6. **Record the approved result on the worktree branch:** when both reviewers approve, edit `work/<slug>/plan.md` in the worktree in place to include both `Code-review verdict: APPROVE` and `Codex-review verdict: APPROVE`, flip its status, and sync the current plan body. Commit that plan update in a single commit with `git -C <worktree> add work/<slug>/plan.md` and `git -C <worktree> commit ...`, then from the repo root run `scripts/worktree.sh sync-artifacts <slug>`. Do not `cp` over it from the primary checkout, because that can clobber the sentinels.
 7. **Hand off to release:** report both verdicts, findings summary (resolved and open), and gate status to the Owner, then proceed through the full `/4-release` TRIP.
 
diff --git a/scripts/codex-review.sh b/scripts/codex-review.sh
index 1e5b42bbe6e22f3f031450ede3bb896026cbe39c..c63852b709b2ed73c717c3a43e543f18fd4f8ee8
--- a/scripts/codex-review.sh
+++ b/scripts/codex-review.sh
@@ -105,7 +105,7 @@
   printf 'Every finding gets exactly one severity:\n'
   printf '- CRITICAL: data loss, security hole, or silent wrong result. Blocks in any round.\n'
   printf '- HIGH: incorrect behavior under a realistic scenario. Blocks in any round.\n'
-  printf '- MEDIUM: robustness gap, missing validation, or incomplete contract. Blocks rounds 1-2 only.\n'
+  printf '- MEDIUM: robustness gap, missing validation, or incomplete contract. Never sets the verdict; report it for the orchestrator to route.\n'
   printf '- LOW: style, naming, log hygiene, non-blocking edge cases. Never blocks.\n\n'
   printf 'A finding without a concrete failure scenario is LOW by definition.\n\n'
   printf '## Calibration\n\n'

codex
The text edits are in place. I’m checking the exact acceptance strings now before running the full gate, including the required grep that should return no matches.
exec
/bin/zsh -lc "grep -n 'rounds 1\\|auto-triage remaining MEDIUM' .claude/skills/3-review/SKILL.md" in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium
 exited 1 in 0ms:
exec
/bin/zsh -lc 'rg -n "rounds 1|rounds 1–2|rounds 1-2|auto-triage remaining MEDIUM|Blocks rounds 1-2|MEDIUM|REQUEST CHANGES requires" .claude/agents/code-reviewer.md scripts/codex-review.sh .claude/skills/3-review/SKILL.md' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium
 succeeded in 0ms:
scripts/codex-review.sh:108:  printf '- MEDIUM: robustness gap, missing validation, or incomplete contract. Never sets the verdict; report it for the orchestrator to route.\n'
scripts/codex-review.sh:115:  printf 'REQUEST CHANGES requires at least one CRITICAL or HIGH finding.\n'
.claude/skills/3-review/SKILL.md:17:   - **MEDIUM** → the orchestrator judges once: fix directly, send back only if load-bearing, or append to `work/<slug>/deferrals.md` for the next unit. MEDIUM never forces a fresh review round by itself.
.claude/agents/code-reviewer.md:28:- **MEDIUM** — robustness gap, missing validation, or incomplete contract. Never sets the verdict; report it for the orchestrator to route.
.claude/agents/code-reviewer.md:41:A `REQUEST CHANGES` verdict requires at least one CRITICAL or HIGH finding. If all findings are LOW or MEDIUM, the verdict must be `APPROVE` with findings attached — a reviewer that blocks on LOW-only findings is miscalibrated.

exec
/bin/zsh -lc 'git diff -- .claude/agents/code-reviewer.md scripts/codex-review.sh .claude/skills/3-review/SKILL.md' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium
 succeeded in 0ms:
diff --git a/.claude/agents/code-reviewer.md b/.claude/agents/code-reviewer.md
index 2141a2c..b4c2537 100644
--- a/.claude/agents/code-reviewer.md
+++ b/.claude/agents/code-reviewer.md
@@ -25,7 +25,7 @@ Every finding gets exactly one severity:
 
 - **CRITICAL** — data loss, security hole, or silent wrong result. Blocks in any round.
 - **HIGH** — incorrect behavior under a realistic scenario. Blocks in any round.
-- **MEDIUM** — robustness gap, missing validation, or incomplete contract. Blocks in rounds 1–2 only.
+- **MEDIUM** — robustness gap, missing validation, or incomplete contract. Never sets the verdict; report it for the orchestrator to route.
 - **LOW** — style, naming, log hygiene, non-blocking edge cases. Never blocks.
 
 A finding without a concrete failure scenario is LOW by definition — "this could be a problem" is not blocking.
@@ -38,4 +38,4 @@ Focus on what breaks the plan's acceptance criteria, not on what you would write
 
 Verdict (`APPROVE` / `REQUEST CHANGES`) plus numbered findings, each with severity, file:line, and a concrete failure scenario or criterion reference. Most severe first. No praise padding.
 
-A `REQUEST CHANGES` verdict requires at least one CRITICAL or HIGH finding (or MEDIUM in rounds 1–2). If all findings are LOW (or MEDIUM past round 2), the verdict must be `APPROVE` with findings attached — a reviewer that blocks on LOW-only findings is miscalibrated.
+A `REQUEST CHANGES` verdict requires at least one CRITICAL or HIGH finding. If all findings are LOW or MEDIUM, the verdict must be `APPROVE` with findings attached — a reviewer that blocks on LOW-only findings is miscalibrated.
diff --git a/scripts/codex-review.sh b/scripts/codex-review.sh
index 1e5b42b..c63852b 100755
--- a/scripts/codex-review.sh
+++ b/scripts/codex-review.sh
@@ -105,7 +105,7 @@ git diff "main...$branch" -- ':/' ":(exclude,top)work/$slug" >>"$prompt" \
   printf 'Every finding gets exactly one severity:\n'
   printf '- CRITICAL: data loss, security hole, or silent wrong result. Blocks in any round.\n'
   printf '- HIGH: incorrect behavior under a realistic scenario. Blocks in any round.\n'
-  printf '- MEDIUM: robustness gap, missing validation, or incomplete contract. Blocks rounds 1-2 only.\n'
+  printf '- MEDIUM: robustness gap, missing validation, or incomplete contract. Never sets the verdict; report it for the orchestrator to route.\n'
   printf '- LOW: style, naming, log hygiene, non-blocking edge cases. Never blocks.\n\n'
   printf 'A finding without a concrete failure scenario is LOW by definition.\n\n'
   printf '## Calibration\n\n'

diff --git a/.claude/agents/code-reviewer.md b/.claude/agents/code-reviewer.md
index 2141a2c90d23e1d01619ff4850c12031a01c65a5..b4c253732a455036f79e478995ac69e860f0ad21
--- a/.claude/agents/code-reviewer.md
+++ b/.claude/agents/code-reviewer.md
@@ -25,7 +25,7 @@
 
 - **CRITICAL** — data loss, security hole, or silent wrong result. Blocks in any round.
 - **HIGH** — incorrect behavior under a realistic scenario. Blocks in any round.
-- **MEDIUM** — robustness gap, missing validation, or incomplete contract. Blocks in rounds 1–2 only.
+- **MEDIUM** — robustness gap, missing validation, or incomplete contract. Never sets the verdict; report it for the orchestrator to route.
 - **LOW** — style, naming, log hygiene, non-blocking edge cases. Never blocks.
 
 A finding without a concrete failure scenario is LOW by definition — "this could be a problem" is not blocking.
@@ -38,4 +38,4 @@
 
 Verdict (`APPROVE` / `REQUEST CHANGES`) plus numbered findings, each with severity, file:line, and a concrete failure scenario or criterion reference. Most severe first. No praise padding.
 
-A `REQUEST CHANGES` verdict requires at least one CRITICAL or HIGH finding (or MEDIUM in rounds 1–2). If all findings are LOW (or MEDIUM past round 2), the verdict must be `APPROVE` with findings attached — a reviewer that blocks on LOW-only findings is miscalibrated.
+A `REQUEST CHANGES` verdict requires at least one CRITICAL or HIGH finding. If all findings are LOW or MEDIUM, the verdict must be `APPROVE` with findings attached — a reviewer that blocks on LOW-only findings is miscalibrated.
diff --git a/.claude/skills/3-review/SKILL.md b/.claude/skills/3-review/SKILL.md
index 685c4631183ebd26365df64001bd16f5ba99c077..aafd4278237955aa1e6306cde28b91632bd645fb
--- a/.claude/skills/3-review/SKILL.md
+++ b/.claude/skills/3-review/SKILL.md
@@ -14,11 +14,11 @@
 3. **Spawn both reviewers.** Launch the `code-reviewer` agent (fresh thread) with the diff, the plan path, the deferral ledger path, the current round number, and the worktree path, instructed to review per its own definition. From the primary checkout, run `REVIEW_ROUND=<N> scripts/codex-review.sh <slug>` so Codex reviews the branch plan and diff from cold, read-only context and writes `work/<slug>/codex-review.md`. Its exit-code contract is: 0 = APPROVE, so record the sentinel; 1 = REQUEST CHANGES, so route the artifact's findings to the followup flow; >=2 = tooling error, not a verdict. Never record a sentinel from prose in the artifact after a non-zero exit; fix the tooling and re-run.
 4. **Route findings by severity:**
    - **CRITICAL/HIGH** → back to the implementer via `/2-implement`'s followup flow (same worktree). These block regardless of round.
-   - **MEDIUM** → block in rounds 1–2; in round 3+, auto-triage to `work/<slug>/deferrals.md` for the next unit unless you judge them load-bearing.
+   - **MEDIUM** → the orchestrator judges once: fix directly, send back only if load-bearing, or append to `work/<slug>/deferrals.md` for the next unit. MEDIUM never forces a fresh review round by itself.
    - **LOW** → never block. Record in the review artifact for the implementer's awareness but do not send back for a fix round.
    - Trivial mechanical fixes (typo-grade) → you may fix them directly, but then the re-review in the next step is mandatory, because you just became a writer.
    - Findings you and the Owner deliberately scope to a later unit → append to `work/<slug>/deferrals.md` in the worktree *before* the next round, one entry per finding: what was raised, why it was deferred, and where it lands. A deferral that is not written down does not exist for the next cold reviewer, and will be raised again.
-5. **Re-review after any change:** spawn a *new* fresh code-reviewer thread and re-run `scripts/codex-review.sh <slug>` on the updated diff. Increment `work/<slug>/review-round` before each new round. Repeat until both approve or the counter reaches 3 — after 3, auto-triage remaining MEDIUM findings to deferrals and escalate any open CRITICAL/HIGH to the Owner. Do not start round 4.
+5. **Re-review after any change:** spawn a *new* fresh code-reviewer thread and re-run `scripts/codex-review.sh <slug>` on the updated diff. Increment `work/<slug>/review-round` before each new round. Repeat until both approve or the counter reaches 3. The 3-round cap is a safety net for CRITICAL/HIGH churn; escalate any open CRITICAL/HIGH to the Owner. Do not start round 4.
 6. **Record the approved result on the worktree branch:** when both reviewers approve, edit `work/<slug>/plan.md` in the worktree in place to include both `Code-review verdict: APPROVE` and `Codex-review verdict: APPROVE`, flip its status, and sync the current plan body. Commit that plan update in a single commit with `git -C <worktree> add work/<slug>/plan.md` and `git -C <worktree> commit ...`, then from the repo root run `scripts/worktree.sh sync-artifacts <slug>`. Do not `cp` over it from the primary checkout, because that can clobber the sentinels.
 7. **Hand off to release:** report both verdicts, findings summary (resolved and open), and gate status to the Owner, then proceed through the full `/4-release` TRIP.
 
diff --git a/scripts/codex-review.sh b/scripts/codex-review.sh
index 1e5b42bbe6e22f3f031450ede3bb896026cbe39c..c63852b709b2ed73c717c3a43e543f18fd4f8ee8
--- a/scripts/codex-review.sh
+++ b/scripts/codex-review.sh
@@ -105,7 +105,7 @@
   printf 'Every finding gets exactly one severity:\n'
   printf '- CRITICAL: data loss, security hole, or silent wrong result. Blocks in any round.\n'
   printf '- HIGH: incorrect behavior under a realistic scenario. Blocks in any round.\n'
-  printf '- MEDIUM: robustness gap, missing validation, or incomplete contract. Blocks rounds 1-2 only.\n'
+  printf '- MEDIUM: robustness gap, missing validation, or incomplete contract. Never sets the verdict; report it for the orchestrator to route.\n'
   printf '- LOW: style, naming, log hygiene, non-blocking edge cases. Never blocks.\n\n'
   printf 'A finding without a concrete failure scenario is LOW by definition.\n\n'
   printf '## Calibration\n\n'

exec
/bin/zsh -lc 'git diff -- .claude/skills/3-review/SKILL.md' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium
 succeeded in 0ms:
diff --git a/.claude/agents/code-reviewer.md b/.claude/agents/code-reviewer.md
index 2141a2c90d23e1d01619ff4850c12031a01c65a5..b4c253732a455036f79e478995ac69e860f0ad21
--- a/.claude/agents/code-reviewer.md
+++ b/.claude/agents/code-reviewer.md
@@ -25,7 +25,7 @@
 
 - **CRITICAL** — data loss, security hole, or silent wrong result. Blocks in any round.
 - **HIGH** — incorrect behavior under a realistic scenario. Blocks in any round.
-- **MEDIUM** — robustness gap, missing validation, or incomplete contract. Blocks in rounds 1–2 only.
+- **MEDIUM** — robustness gap, missing validation, or incomplete contract. Never sets the verdict; report it for the orchestrator to route.
 - **LOW** — style, naming, log hygiene, non-blocking edge cases. Never blocks.
 
 A finding without a concrete failure scenario is LOW by definition — "this could be a problem" is not blocking.
@@ -38,4 +38,4 @@
 
 Verdict (`APPROVE` / `REQUEST CHANGES`) plus numbered findings, each with severity, file:line, and a concrete failure scenario or criterion reference. Most severe first. No praise padding.
 
-A `REQUEST CHANGES` verdict requires at least one CRITICAL or HIGH finding (or MEDIUM in rounds 1–2). If all findings are LOW (or MEDIUM past round 2), the verdict must be `APPROVE` with findings attached — a reviewer that blocks on LOW-only findings is miscalibrated.
+A `REQUEST CHANGES` verdict requires at least one CRITICAL or HIGH finding. If all findings are LOW or MEDIUM, the verdict must be `APPROVE` with findings attached — a reviewer that blocks on LOW-only findings is miscalibrated.
diff --git a/.claude/skills/3-review/SKILL.md b/.claude/skills/3-review/SKILL.md
index 685c4631183ebd26365df64001bd16f5ba99c077..aafd4278237955aa1e6306cde28b91632bd645fb
--- a/.claude/skills/3-review/SKILL.md
+++ b/.claude/skills/3-review/SKILL.md
@@ -14,11 +14,11 @@
 3. **Spawn both reviewers.** Launch the `code-reviewer` agent (fresh thread) with the diff, the plan path, the deferral ledger path, the current round number, and the worktree path, instructed to review per its own definition. From the primary checkout, run `REVIEW_ROUND=<N> scripts/codex-review.sh <slug>` so Codex reviews the branch plan and diff from cold, read-only context and writes `work/<slug>/codex-review.md`. Its exit-code contract is: 0 = APPROVE, so record the sentinel; 1 = REQUEST CHANGES, so route the artifact's findings to the followup flow; >=2 = tooling error, not a verdict. Never record a sentinel from prose in the artifact after a non-zero exit; fix the tooling and re-run.
 4. **Route findings by severity:**
    - **CRITICAL/HIGH** → back to the implementer via `/2-implement`'s followup flow (same worktree). These block regardless of round.
-   - **MEDIUM** → block in rounds 1–2; in round 3+, auto-triage to `work/<slug>/deferrals.md` for the next unit unless you judge them load-bearing.
+   - **MEDIUM** → the orchestrator judges once: fix directly, send back only if load-bearing, or append to `work/<slug>/deferrals.md` for the next unit. MEDIUM never forces a fresh review round by itself.
    - **LOW** → never block. Record in the review artifact for the implementer's awareness but do not send back for a fix round.
    - Trivial mechanical fixes (typo-grade) → you may fix them directly, but then the re-review in the next step is mandatory, because you just became a writer.
    - Findings you and the Owner deliberately scope to a later unit → append to `work/<slug>/deferrals.md` in the worktree *before* the next round, one entry per finding: what was raised, why it was deferred, and where it lands. A deferral that is not written down does not exist for the next cold reviewer, and will be raised again.
-5. **Re-review after any change:** spawn a *new* fresh code-reviewer thread and re-run `scripts/codex-review.sh <slug>` on the updated diff. Increment `work/<slug>/review-round` before each new round. Repeat until both approve or the counter reaches 3 — after 3, auto-triage remaining MEDIUM findings to deferrals and escalate any open CRITICAL/HIGH to the Owner. Do not start round 4.
+5. **Re-review after any change:** spawn a *new* fresh code-reviewer thread and re-run `scripts/codex-review.sh <slug>` on the updated diff. Increment `work/<slug>/review-round` before each new round. Repeat until both approve or the counter reaches 3. The 3-round cap is a safety net for CRITICAL/HIGH churn; escalate any open CRITICAL/HIGH to the Owner. Do not start round 4.
 6. **Record the approved result on the worktree branch:** when both reviewers approve, edit `work/<slug>/plan.md` in the worktree in place to include both `Code-review verdict: APPROVE` and `Codex-review verdict: APPROVE`, flip its status, and sync the current plan body. Commit that plan update in a single commit with `git -C <worktree> add work/<slug>/plan.md` and `git -C <worktree> commit ...`, then from the repo root run `scripts/worktree.sh sync-artifacts <slug>`. Do not `cp` over it from the primary checkout, because that can clobber the sentinels.
 7. **Hand off to release:** report both verdicts, findings summary (resolved and open), and gate status to the Owner, then proceed through the full `/4-release` TRIP.
 
diff --git a/scripts/codex-review.sh b/scripts/codex-review.sh
index 1e5b42bbe6e22f3f031450ede3bb896026cbe39c..c63852b709b2ed73c717c3a43e543f18fd4f8ee8
--- a/scripts/codex-review.sh
+++ b/scripts/codex-review.sh
@@ -105,7 +105,7 @@
   printf 'Every finding gets exactly one severity:\n'
   printf '- CRITICAL: data loss, security hole, or silent wrong result. Blocks in any round.\n'
   printf '- HIGH: incorrect behavior under a realistic scenario. Blocks in any round.\n'
-  printf '- MEDIUM: robustness gap, missing validation, or incomplete contract. Blocks rounds 1-2 only.\n'
+  printf '- MEDIUM: robustness gap, missing validation, or incomplete contract. Never sets the verdict; report it for the orchestrator to route.\n'
   printf '- LOW: style, naming, log hygiene, non-blocking edge cases. Never blocks.\n\n'
   printf 'A finding without a concrete failure scenario is LOW by definition.\n\n'
   printf '## Calibration\n\n'

codex
The required no-match grep for `SKILL.md` is clean. One thing I’m checking before the gate: Git is showing the prompt changes, and I’m verifying the skill file’s index status so I only commit the intended footprint.
exec
/bin/zsh -lc "sed -n '12,24p' .claude/skills/3-review/SKILL.md" in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium
 succeeded in 0ms:
1. **Assemble artifacts, not transcripts:** the diff (`git diff main...wt/<slug> -- ':/' ":(exclude,top)work/<slug>"`), the plan path, the accepted-deferral ledger `work/<slug>/deferrals.md` (pass `(none recorded)` if it does not exist), and nothing else, so synced handoffs, followups, and other reviewer artifacts cannot leak into the review. Reviewers must never see the implementation conversation or your own commentary on the diff.
2. **Track the round.** Before each review, read the round counter `work/<slug>/review-round` (create it with `1` if absent). Increment it after each completed round. This file is the mechanical truth for how many rounds have run — do not count from memory or conversation context. Pass the current round number to both reviewers (the code-reviewer agent in its prompt, and codex-review.sh via `REVIEW_ROUND`).
3. **Spawn both reviewers.** Launch the `code-reviewer` agent (fresh thread) with the diff, the plan path, the deferral ledger path, the current round number, and the worktree path, instructed to review per its own definition. From the primary checkout, run `REVIEW_ROUND=<N> scripts/codex-review.sh <slug>` so Codex reviews the branch plan and diff from cold, read-only context and writes `work/<slug>/codex-review.md`. Its exit-code contract is: 0 = APPROVE, so record the sentinel; 1 = REQUEST CHANGES, so route the artifact's findings to the followup flow; >=2 = tooling error, not a verdict. Never record a sentinel from prose in the artifact after a non-zero exit; fix the tooling and re-run.
4. **Route findings by severity:**
   - **CRITICAL/HIGH** → back to the implementer via `/2-implement`'s followup flow (same worktree). These block regardless of round.
   - **MEDIUM** → the orchestrator judges once: fix directly, send back only if load-bearing, or append to `work/<slug>/deferrals.md` for the next unit. MEDIUM never forces a fresh review round by itself.
   - **LOW** → never block. Record in the review artifact for the implementer's awareness but do not send back for a fix round.
   - Trivial mechanical fixes (typo-grade) → you may fix them directly, but then the re-review in the next step is mandatory, because you just became a writer.
   - Findings you and the Owner deliberately scope to a later unit → append to `work/<slug>/deferrals.md` in the worktree *before* the next round, one entry per finding: what was raised, why it was deferred, and where it lands. A deferral that is not written down does not exist for the next cold reviewer, and will be raised again.
5. **Re-review after any change:** spawn a *new* fresh code-reviewer thread and re-run `scripts/codex-review.sh <slug>` on the updated diff. Increment `work/<slug>/review-round` before each new round. Repeat until both approve or the counter reaches 3. The 3-round cap is a safety net for CRITICAL/HIGH churn; escalate any open CRITICAL/HIGH to the Owner. Do not start round 4.
6. **Record the approved result on the worktree branch:** when both reviewers approve, edit `work/<slug>/plan.md` in the worktree in place to include both `Code-review verdict: APPROVE` and `Codex-review verdict: APPROVE`, flip its status, and sync the current plan body. Commit that plan update in a single commit with `git -C <worktree> add work/<slug>/plan.md` and `git -C <worktree> commit ...`, then from the repo root run `scripts/worktree.sh sync-artifacts <slug>`. Do not `cp` over it from the primary checkout, because that can clobber the sentinels.
7. **Hand off to release:** report both verdicts, findings summary (resolved and open), and gate status to the Owner, then proceed through the full `/4-release` TRIP.


exec
/bin/zsh -lc "git show HEAD:.claude/skills/3-review/SKILL.md | sed -n '12,24p'" in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium
 succeeded in 0ms:
fatal: path '.claude/skills/3-review/SKILL.md' exists on disk, but not in 'HEAD'

exec
/bin/zsh -lc 'git status --short' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium
 succeeded in 0ms:
 M .claude/agents/code-reviewer.md
 M scripts/codex-review.sh
 M skills/3-review/SKILL.md

exec
/bin/zsh -lc 'git ls-files -v .claude/skills/3-review/SKILL.md && git diff --name-only && git diff --stat' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium
 succeeded in 0ms:
.claude/agents/code-reviewer.md
scripts/codex-review.sh
skills/3-review/SKILL.md
 .claude/agents/code-reviewer.md | 4 ++--
 scripts/codex-review.sh         | 2 +-
 skills/3-review/SKILL.md        | 4 ++--
 3 files changed, 5 insertions(+), 5 deletions(-)

diff --git a/.claude/agents/code-reviewer.md b/.claude/agents/code-reviewer.md
index 2141a2c90d23e1d01619ff4850c12031a01c65a5..b4c253732a455036f79e478995ac69e860f0ad21
--- a/.claude/agents/code-reviewer.md
+++ b/.claude/agents/code-reviewer.md
@@ -25,7 +25,7 @@
 
 - **CRITICAL** — data loss, security hole, or silent wrong result. Blocks in any round.
 - **HIGH** — incorrect behavior under a realistic scenario. Blocks in any round.
-- **MEDIUM** — robustness gap, missing validation, or incomplete contract. Blocks in rounds 1–2 only.
+- **MEDIUM** — robustness gap, missing validation, or incomplete contract. Never sets the verdict; report it for the orchestrator to route.
 - **LOW** — style, naming, log hygiene, non-blocking edge cases. Never blocks.
 
 A finding without a concrete failure scenario is LOW by definition — "this could be a problem" is not blocking.
@@ -38,4 +38,4 @@
 
 Verdict (`APPROVE` / `REQUEST CHANGES`) plus numbered findings, each with severity, file:line, and a concrete failure scenario or criterion reference. Most severe first. No praise padding.
 
-A `REQUEST CHANGES` verdict requires at least one CRITICAL or HIGH finding (or MEDIUM in rounds 1–2). If all findings are LOW (or MEDIUM past round 2), the verdict must be `APPROVE` with findings attached — a reviewer that blocks on LOW-only findings is miscalibrated.
+A `REQUEST CHANGES` verdict requires at least one CRITICAL or HIGH finding. If all findings are LOW or MEDIUM, the verdict must be `APPROVE` with findings attached — a reviewer that blocks on LOW-only findings is miscalibrated.
diff --git a/.claude/skills/3-review/SKILL.md b/.claude/skills/3-review/SKILL.md
index 685c4631183ebd26365df64001bd16f5ba99c077..aafd4278237955aa1e6306cde28b91632bd645fb
--- a/.claude/skills/3-review/SKILL.md
+++ b/.claude/skills/3-review/SKILL.md
@@ -14,11 +14,11 @@
 3. **Spawn both reviewers.** Launch the `code-reviewer` agent (fresh thread) with the diff, the plan path, the deferral ledger path, the current round number, and the worktree path, instructed to review per its own definition. From the primary checkout, run `REVIEW_ROUND=<N> scripts/codex-review.sh <slug>` so Codex reviews the branch plan and diff from cold, read-only context and writes `work/<slug>/codex-review.md`. Its exit-code contract is: 0 = APPROVE, so record the sentinel; 1 = REQUEST CHANGES, so route the artifact's findings to the followup flow; >=2 = tooling error, not a verdict. Never record a sentinel from prose in the artifact after a non-zero exit; fix the tooling and re-run.
 4. **Route findings by severity:**
    - **CRITICAL/HIGH** → back to the implementer via `/2-implement`'s followup flow (same worktree). These block regardless of round.
-   - **MEDIUM** → block in rounds 1–2; in round 3+, auto-triage to `work/<slug>/deferrals.md` for the next unit unless you judge them load-bearing.
+   - **MEDIUM** → the orchestrator judges once: fix directly, send back only if load-bearing, or append to `work/<slug>/deferrals.md` for the next unit. MEDIUM never forces a fresh review round by itself.
    - **LOW** → never block. Record in the review artifact for the implementer's awareness but do not send back for a fix round.
    - Trivial mechanical fixes (typo-grade) → you may fix them directly, but then the re-review in the next step is mandatory, because you just became a writer.
    - Findings you and the Owner deliberately scope to a later unit → append to `work/<slug>/deferrals.md` in the worktree *before* the next round, one entry per finding: what was raised, why it was deferred, and where it lands. A deferral that is not written down does not exist for the next cold reviewer, and will be raised again.
-5. **Re-review after any change:** spawn a *new* fresh code-reviewer thread and re-run `scripts/codex-review.sh <slug>` on the updated diff. Increment `work/<slug>/review-round` before each new round. Repeat until both approve or the counter reaches 3 — after 3, auto-triage remaining MEDIUM findings to deferrals and escalate any open CRITICAL/HIGH to the Owner. Do not start round 4.
+5. **Re-review after any change:** spawn a *new* fresh code-reviewer thread and re-run `scripts/codex-review.sh <slug>` on the updated diff. Increment `work/<slug>/review-round` before each new round. Repeat until both approve or the counter reaches 3. The 3-round cap is a safety net for CRITICAL/HIGH churn; escalate any open CRITICAL/HIGH to the Owner. Do not start round 4.
 6. **Record the approved result on the worktree branch:** when both reviewers approve, edit `work/<slug>/plan.md` in the worktree in place to include both `Code-review verdict: APPROVE` and `Codex-review verdict: APPROVE`, flip its status, and sync the current plan body. Commit that plan update in a single commit with `git -C <worktree> add work/<slug>/plan.md` and `git -C <worktree> commit ...`, then from the repo root run `scripts/worktree.sh sync-artifacts <slug>`. Do not `cp` over it from the primary checkout, because that can clobber the sentinels.
 7. **Hand off to release:** report both verdicts, findings summary (resolved and open), and gate status to the Owner, then proceed through the full `/4-release` TRIP.
 
diff --git a/scripts/codex-review.sh b/scripts/codex-review.sh
index 1e5b42bbe6e22f3f031450ede3bb896026cbe39c..c63852b709b2ed73c717c3a43e543f18fd4f8ee8
--- a/scripts/codex-review.sh
+++ b/scripts/codex-review.sh
@@ -105,7 +105,7 @@
   printf 'Every finding gets exactly one severity:\n'
   printf '- CRITICAL: data loss, security hole, or silent wrong result. Blocks in any round.\n'
   printf '- HIGH: incorrect behavior under a realistic scenario. Blocks in any round.\n'
-  printf '- MEDIUM: robustness gap, missing validation, or incomplete contract. Blocks rounds 1-2 only.\n'
+  printf '- MEDIUM: robustness gap, missing validation, or incomplete contract. Never sets the verdict; report it for the orchestrator to route.\n'
   printf '- LOW: style, naming, log hygiene, non-blocking edge cases. Never blocks.\n\n'
   printf 'A finding without a concrete failure scenario is LOW by definition.\n\n'
   printf '## Calibration\n\n'

exec
/bin/zsh -lc 'ls -l .claude .claude/skills skills/3-review/SKILL.md .claude/skills/3-review/SKILL.md' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium
 succeeded in 0ms:
lrwxr-xr-x  1 cboyfly  staff     9 Sep  2 22:13 .claude/skills -> ../skills
-rw-r--r--  1 cboyfly  staff  4323 Sep  2 22:14 .claude/skills/3-review/SKILL.md
-rw-r--r--  1 cboyfly  staff  4323 Sep  2 22:14 skills/3-review/SKILL.md

.claude:
total 0
drwxr-xr-x  5 cboyfly  staff  160 Sep  2 22:13 agents
lrwxr-xr-x  1 cboyfly  staff    9 Sep  2 22:13 skills -> ../skills

exec
/bin/zsh -lc "git ls-files | rg '("'^|/)3-review/SKILL.md$|''^'"\\.claude/skills'" in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium
 succeeded in 0ms:
.claude/skills
skills/3-review/SKILL.md

exec
/bin/zsh -lc 'git diff -- skills/3-review/SKILL.md' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium
 succeeded in 0ms:
diff --git a/skills/3-review/SKILL.md b/skills/3-review/SKILL.md
index 685c463..aafd427 100644
--- a/skills/3-review/SKILL.md
+++ b/skills/3-review/SKILL.md
@@ -14,11 +14,11 @@ Input: a work unit whose worktree branch `wt/<slug>` passed the gate.
 3. **Spawn both reviewers.** Launch the `code-reviewer` agent (fresh thread) with the diff, the plan path, the deferral ledger path, the current round number, and the worktree path, instructed to review per its own definition. From the primary checkout, run `REVIEW_ROUND=<N> scripts/codex-review.sh <slug>` so Codex reviews the branch plan and diff from cold, read-only context and writes `work/<slug>/codex-review.md`. Its exit-code contract is: 0 = APPROVE, so record the sentinel; 1 = REQUEST CHANGES, so route the artifact's findings to the followup flow; >=2 = tooling error, not a verdict. Never record a sentinel from prose in the artifact after a non-zero exit; fix the tooling and re-run.
 4. **Route findings by severity:**
    - **CRITICAL/HIGH** → back to the implementer via `/2-implement`'s followup flow (same worktree). These block regardless of round.
-   - **MEDIUM** → block in rounds 1–2; in round 3+, auto-triage to `work/<slug>/deferrals.md` for the next unit unless you judge them load-bearing.
+   - **MEDIUM** → the orchestrator judges once: fix directly, send back only if load-bearing, or append to `work/<slug>/deferrals.md` for the next unit. MEDIUM never forces a fresh review round by itself.
    - **LOW** → never block. Record in the review artifact for the implementer's awareness but do not send back for a fix round.
    - Trivial mechanical fixes (typo-grade) → you may fix them directly, but then the re-review in the next step is mandatory, because you just became a writer.
    - Findings you and the Owner deliberately scope to a later unit → append to `work/<slug>/deferrals.md` in the worktree *before* the next round, one entry per finding: what was raised, why it was deferred, and where it lands. A deferral that is not written down does not exist for the next cold reviewer, and will be raised again.
-5. **Re-review after any change:** spawn a *new* fresh code-reviewer thread and re-run `scripts/codex-review.sh <slug>` on the updated diff. Increment `work/<slug>/review-round` before each new round. Repeat until both approve or the counter reaches 3 — after 3, auto-triage remaining MEDIUM findings to deferrals and escalate any open CRITICAL/HIGH to the Owner. Do not start round 4.
+5. **Re-review after any change:** spawn a *new* fresh code-reviewer thread and re-run `scripts/codex-review.sh <slug>` on the updated diff. Increment `work/<slug>/review-round` before each new round. Repeat until both approve or the counter reaches 3. The 3-round cap is a safety net for CRITICAL/HIGH churn; escalate any open CRITICAL/HIGH to the Owner. Do not start round 4.
 6. **Record the approved result on the worktree branch:** when both reviewers approve, edit `work/<slug>/plan.md` in the worktree in place to include both `Code-review verdict: APPROVE` and `Codex-review verdict: APPROVE`, flip its status, and sync the current plan body. Commit that plan update in a single commit with `git -C <worktree> add work/<slug>/plan.md` and `git -C <worktree> commit ...`, then from the repo root run `scripts/worktree.sh sync-artifacts <slug>`. Do not `cp` over it from the primary checkout, because that can clobber the sentinels.
 7. **Hand off to release:** report both verdicts, findings summary (resolved and open), and gate status to the Owner, then proceed through the full `/4-release` TRIP.
 

diff --git a/.claude/agents/code-reviewer.md b/.claude/agents/code-reviewer.md
index 2141a2c90d23e1d01619ff4850c12031a01c65a5..b4c253732a455036f79e478995ac69e860f0ad21
--- a/.claude/agents/code-reviewer.md
+++ b/.claude/agents/code-reviewer.md
@@ -25,7 +25,7 @@
 
 - **CRITICAL** — data loss, security hole, or silent wrong result. Blocks in any round.
 - **HIGH** — incorrect behavior under a realistic scenario. Blocks in any round.
-- **MEDIUM** — robustness gap, missing validation, or incomplete contract. Blocks in rounds 1–2 only.
+- **MEDIUM** — robustness gap, missing validation, or incomplete contract. Never sets the verdict; report it for the orchestrator to route.
 - **LOW** — style, naming, log hygiene, non-blocking edge cases. Never blocks.
 
 A finding without a concrete failure scenario is LOW by definition — "this could be a problem" is not blocking.
@@ -38,4 +38,4 @@
 
 Verdict (`APPROVE` / `REQUEST CHANGES`) plus numbered findings, each with severity, file:line, and a concrete failure scenario or criterion reference. Most severe first. No praise padding.
 
-A `REQUEST CHANGES` verdict requires at least one CRITICAL or HIGH finding (or MEDIUM in rounds 1–2). If all findings are LOW (or MEDIUM past round 2), the verdict must be `APPROVE` with findings attached — a reviewer that blocks on LOW-only findings is miscalibrated.
+A `REQUEST CHANGES` verdict requires at least one CRITICAL or HIGH finding. If all findings are LOW or MEDIUM, the verdict must be `APPROVE` with findings attached — a reviewer that blocks on LOW-only findings is miscalibrated.
diff --git a/.claude/skills/3-review/SKILL.md b/.claude/skills/3-review/SKILL.md
index 685c4631183ebd26365df64001bd16f5ba99c077..aafd4278237955aa1e6306cde28b91632bd645fb
--- a/.claude/skills/3-review/SKILL.md
+++ b/.claude/skills/3-review/SKILL.md
@@ -14,11 +14,11 @@
 3. **Spawn both reviewers.** Launch the `code-reviewer` agent (fresh thread) with the diff, the plan path, the deferral ledger path, the current round number, and the worktree path, instructed to review per its own definition. From the primary checkout, run `REVIEW_ROUND=<N> scripts/codex-review.sh <slug>` so Codex reviews the branch plan and diff from cold, read-only context and writes `work/<slug>/codex-review.md`. Its exit-code contract is: 0 = APPROVE, so record the sentinel; 1 = REQUEST CHANGES, so route the artifact's findings to the followup flow; >=2 = tooling error, not a verdict. Never record a sentinel from prose in the artifact after a non-zero exit; fix the tooling and re-run.
 4. **Route findings by severity:**
    - **CRITICAL/HIGH** → back to the implementer via `/2-implement`'s followup flow (same worktree). These block regardless of round.
-   - **MEDIUM** → block in rounds 1–2; in round 3+, auto-triage to `work/<slug>/deferrals.md` for the next unit unless you judge them load-bearing.
+   - **MEDIUM** → the orchestrator judges once: fix directly, send back only if load-bearing, or append to `work/<slug>/deferrals.md` for the next unit. MEDIUM never forces a fresh review round by itself.
    - **LOW** → never block. Record in the review artifact for the implementer's awareness but do not send back for a fix round.
    - Trivial mechanical fixes (typo-grade) → you may fix them directly, but then the re-review in the next step is mandatory, because you just became a writer.
    - Findings you and the Owner deliberately scope to a later unit → append to `work/<slug>/deferrals.md` in the worktree *before* the next round, one entry per finding: what was raised, why it was deferred, and where it lands. A deferral that is not written down does not exist for the next cold reviewer, and will be raised again.
-5. **Re-review after any change:** spawn a *new* fresh code-reviewer thread and re-run `scripts/codex-review.sh <slug>` on the updated diff. Increment `work/<slug>/review-round` before each new round. Repeat until both approve or the counter reaches 3 — after 3, auto-triage remaining MEDIUM findings to deferrals and escalate any open CRITICAL/HIGH to the Owner. Do not start round 4.
+5. **Re-review after any change:** spawn a *new* fresh code-reviewer thread and re-run `scripts/codex-review.sh <slug>` on the updated diff. Increment `work/<slug>/review-round` before each new round. Repeat until both approve or the counter reaches 3. The 3-round cap is a safety net for CRITICAL/HIGH churn; escalate any open CRITICAL/HIGH to the Owner. Do not start round 4.
 6. **Record the approved result on the worktree branch:** when both reviewers approve, edit `work/<slug>/plan.md` in the worktree in place to include both `Code-review verdict: APPROVE` and `Codex-review verdict: APPROVE`, flip its status, and sync the current plan body. Commit that plan update in a single commit with `git -C <worktree> add work/<slug>/plan.md` and `git -C <worktree> commit ...`, then from the repo root run `scripts/worktree.sh sync-artifacts <slug>`. Do not `cp` over it from the primary checkout, because that can clobber the sentinels.
 7. **Hand off to release:** report both verdicts, findings summary (resolved and open), and gate status to the Owner, then proceed through the full `/4-release` TRIP.
 
diff --git a/scripts/codex-review.sh b/scripts/codex-review.sh
index 1e5b42bbe6e22f3f031450ede3bb896026cbe39c..c63852b709b2ed73c717c3a43e543f18fd4f8ee8
--- a/scripts/codex-review.sh
+++ b/scripts/codex-review.sh
@@ -105,7 +105,7 @@
   printf 'Every finding gets exactly one severity:\n'
   printf '- CRITICAL: data loss, security hole, or silent wrong result. Blocks in any round.\n'
   printf '- HIGH: incorrect behavior under a realistic scenario. Blocks in any round.\n'
-  printf '- MEDIUM: robustness gap, missing validation, or incomplete contract. Blocks rounds 1-2 only.\n'
+  printf '- MEDIUM: robustness gap, missing validation, or incomplete contract. Never sets the verdict; report it for the orchestrator to route.\n'
   printf '- LOW: style, naming, log hygiene, non-blocking edge cases. Never blocks.\n\n'
   printf 'A finding without a concrete failure scenario is LOW by definition.\n\n'
   printf '## Calibration\n\n'

codex
`.claude/skills` is a tracked symlink to `skills`, so Git records that edit as `skills/3-review/SKILL.md`; the requested `.claude/skills/3-review/SKILL.md` path resolves to the same file. The diff is otherwise limited to the three intended files, and I’m running the required gate now.
exec
/bin/zsh -lc 'bash scripts/gate.sh' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium
diff --git a/.claude/agents/code-reviewer.md b/.claude/agents/code-reviewer.md
index 2141a2c90d23e1d01619ff4850c12031a01c65a5..b4c253732a455036f79e478995ac69e860f0ad21
--- a/.claude/agents/code-reviewer.md
+++ b/.claude/agents/code-reviewer.md
@@ -25,7 +25,7 @@
 
 - **CRITICAL** — data loss, security hole, or silent wrong result. Blocks in any round.
 - **HIGH** — incorrect behavior under a realistic scenario. Blocks in any round.
-- **MEDIUM** — robustness gap, missing validation, or incomplete contract. Blocks in rounds 1–2 only.
+- **MEDIUM** — robustness gap, missing validation, or incomplete contract. Never sets the verdict; report it for the orchestrator to route.
 - **LOW** — style, naming, log hygiene, non-blocking edge cases. Never blocks.
 
 A finding without a concrete failure scenario is LOW by definition — "this could be a problem" is not blocking.
@@ -38,4 +38,4 @@
 
 Verdict (`APPROVE` / `REQUEST CHANGES`) plus numbered findings, each with severity, file:line, and a concrete failure scenario or criterion reference. Most severe first. No praise padding.
 
-A `REQUEST CHANGES` verdict requires at least one CRITICAL or HIGH finding (or MEDIUM in rounds 1–2). If all findings are LOW (or MEDIUM past round 2), the verdict must be `APPROVE` with findings attached — a reviewer that blocks on LOW-only findings is miscalibrated.
+A `REQUEST CHANGES` verdict requires at least one CRITICAL or HIGH finding. If all findings are LOW or MEDIUM, the verdict must be `APPROVE` with findings attached — a reviewer that blocks on LOW-only findings is miscalibrated.
diff --git a/.claude/skills/3-review/SKILL.md b/.claude/skills/3-review/SKILL.md
index 685c4631183ebd26365df64001bd16f5ba99c077..aafd4278237955aa1e6306cde28b91632bd645fb
--- a/.claude/skills/3-review/SKILL.md
+++ b/.claude/skills/3-review/SKILL.md
@@ -14,11 +14,11 @@
 3. **Spawn both reviewers.** Launch the `code-reviewer` agent (fresh thread) with the diff, the plan path, the deferral ledger path, the current round number, and the worktree path, instructed to review per its own definition. From the primary checkout, run `REVIEW_ROUND=<N> scripts/codex-review.sh <slug>` so Codex reviews the branch plan and diff from cold, read-only context and writes `work/<slug>/codex-review.md`. Its exit-code contract is: 0 = APPROVE, so record the sentinel; 1 = REQUEST CHANGES, so route the artifact's findings to the followup flow; >=2 = tooling error, not a verdict. Never record a sentinel from prose in the artifact after a non-zero exit; fix the tooling and re-run.
 4. **Route findings by severity:**
    - **CRITICAL/HIGH** → back to the implementer via `/2-implement`'s followup flow (same worktree). These block regardless of round.
-   - **MEDIUM** → block in rounds 1–2; in round 3+, auto-triage to `work/<slug>/deferrals.md` for the next unit unless you judge them load-bearing.
+   - **MEDIUM** → the orchestrator judges once: fix directly, send back only if load-bearing, or append to `work/<slug>/deferrals.md` for the next unit. MEDIUM never forces a fresh review round by itself.
    - **LOW** → never block. Record in the review artifact for the implementer's awareness but do not send back for a fix round.
    - Trivial mechanical fixes (typo-grade) → you may fix them directly, but then the re-review in the next step is mandatory, because you just became a writer.
    - Findings you and the Owner deliberately scope to a later unit → append to `work/<slug>/deferrals.md` in the worktree *before* the next round, one entry per finding: what was raised, why it was deferred, and where it lands. A deferral that is not written down does not exist for the next cold reviewer, and will be raised again.
-5. **Re-review after any change:** spawn a *new* fresh code-reviewer thread and re-run `scripts/codex-review.sh <slug>` on the updated diff. Increment `work/<slug>/review-round` before each new round. Repeat until both approve or the counter reaches 3 — after 3, auto-triage remaining MEDIUM findings to deferrals and escalate any open CRITICAL/HIGH to the Owner. Do not start round 4.
+5. **Re-review after any change:** spawn a *new* fresh code-reviewer thread and re-run `scripts/codex-review.sh <slug>` on the updated diff. Increment `work/<slug>/review-round` before each new round. Repeat until both approve or the counter reaches 3. The 3-round cap is a safety net for CRITICAL/HIGH churn; escalate any open CRITICAL/HIGH to the Owner. Do not start round 4.
 6. **Record the approved result on the worktree branch:** when both reviewers approve, edit `work/<slug>/plan.md` in the worktree in place to include both `Code-review verdict: APPROVE` and `Codex-review verdict: APPROVE`, flip its status, and sync the current plan body. Commit that plan update in a single commit with `git -C <worktree> add work/<slug>/plan.md` and `git -C <worktree> commit ...`, then from the repo root run `scripts/worktree.sh sync-artifacts <slug>`. Do not `cp` over it from the primary checkout, because that can clobber the sentinels.
 7. **Hand off to release:** report both verdicts, findings summary (resolved and open), and gate status to the Owner, then proceed through the full `/4-release` TRIP.
 
diff --git a/scripts/codex-review.sh b/scripts/codex-review.sh
index 1e5b42bbe6e22f3f031450ede3bb896026cbe39c..c63852b709b2ed73c717c3a43e543f18fd4f8ee8
--- a/scripts/codex-review.sh
+++ b/scripts/codex-review.sh
@@ -105,7 +105,7 @@
   printf 'Every finding gets exactly one severity:\n'
   printf '- CRITICAL: data loss, security hole, or silent wrong result. Blocks in any round.\n'
   printf '- HIGH: incorrect behavior under a realistic scenario. Blocks in any round.\n'
-  printf '- MEDIUM: robustness gap, missing validation, or incomplete contract. Blocks rounds 1-2 only.\n'
+  printf '- MEDIUM: robustness gap, missing validation, or incomplete contract. Never sets the verdict; report it for the orchestrator to route.\n'
   printf '- LOW: style, naming, log hygiene, non-blocking edge cases. Never blocks.\n\n'
   printf 'A finding without a concrete failure scenario is LOW by definition.\n\n'
   printf '## Calibration\n\n'

 succeeded in 27581ms:
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
`bash scripts/gate.sh` passed with all 170 checks green. I’m doing one final targeted grep/status check, then I’ll commit the three-file change on the verified branch.
exec
/bin/zsh -lc "grep -n 'rounds 1\\|auto-triage remaining MEDIUM' .claude/agents/code-reviewer.md scripts/codex-review.sh .claude/skills/3-review/SKILL.md" in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium
 exited 1 in 0ms:
exec
/bin/zsh -lc 'git status --short' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium
 succeeded in 0ms:
 M .claude/agents/code-reviewer.md
 M scripts/codex-review.sh
 M skills/3-review/SKILL.md

exec
/bin/zsh -lc 'git diff --check' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium
 succeeded in 0ms:
diff --git a/.claude/agents/code-reviewer.md b/.claude/agents/code-reviewer.md
index 2141a2c90d23e1d01619ff4850c12031a01c65a5..b4c253732a455036f79e478995ac69e860f0ad21
--- a/.claude/agents/code-reviewer.md
+++ b/.claude/agents/code-reviewer.md
@@ -25,7 +25,7 @@
 
 - **CRITICAL** — data loss, security hole, or silent wrong result. Blocks in any round.
 - **HIGH** — incorrect behavior under a realistic scenario. Blocks in any round.
-- **MEDIUM** — robustness gap, missing validation, or incomplete contract. Blocks in rounds 1–2 only.
+- **MEDIUM** — robustness gap, missing validation, or incomplete contract. Never sets the verdict; report it for the orchestrator to route.
 - **LOW** — style, naming, log hygiene, non-blocking edge cases. Never blocks.
 
 A finding without a concrete failure scenario is LOW by definition — "this could be a problem" is not blocking.
@@ -38,4 +38,4 @@
 
 Verdict (`APPROVE` / `REQUEST CHANGES`) plus numbered findings, each with severity, file:line, and a concrete failure scenario or criterion reference. Most severe first. No praise padding.
 
-A `REQUEST CHANGES` verdict requires at least one CRITICAL or HIGH finding (or MEDIUM in rounds 1–2). If all findings are LOW (or MEDIUM past round 2), the verdict must be `APPROVE` with findings attached — a reviewer that blocks on LOW-only findings is miscalibrated.
+A `REQUEST CHANGES` verdict requires at least one CRITICAL or HIGH finding. If all findings are LOW or MEDIUM, the verdict must be `APPROVE` with findings attached — a reviewer that blocks on LOW-only findings is miscalibrated.
diff --git a/.claude/skills/3-review/SKILL.md b/.claude/skills/3-review/SKILL.md
index 685c4631183ebd26365df64001bd16f5ba99c077..aafd4278237955aa1e6306cde28b91632bd645fb
--- a/.claude/skills/3-review/SKILL.md
+++ b/.claude/skills/3-review/SKILL.md
@@ -14,11 +14,11 @@
 3. **Spawn both reviewers.** Launch the `code-reviewer` agent (fresh thread) with the diff, the plan path, the deferral ledger path, the current round number, and the worktree path, instructed to review per its own definition. From the primary checkout, run `REVIEW_ROUND=<N> scripts/codex-review.sh <slug>` so Codex reviews the branch plan and diff from cold, read-only context and writes `work/<slug>/codex-review.md`. Its exit-code contract is: 0 = APPROVE, so record the sentinel; 1 = REQUEST CHANGES, so route the artifact's findings to the followup flow; >=2 = tooling error, not a verdict. Never record a sentinel from prose in the artifact after a non-zero exit; fix the tooling and re-run.
 4. **Route findings by severity:**
    - **CRITICAL/HIGH** → back to the implementer via `/2-implement`'s followup flow (same worktree). These block regardless of round.
-   - **MEDIUM** → block in rounds 1–2; in round 3+, auto-triage to `work/<slug>/deferrals.md` for the next unit unless you judge them load-bearing.
+   - **MEDIUM** → the orchestrator judges once: fix directly, send back only if load-bearing, or append to `work/<slug>/deferrals.md` for the next unit. MEDIUM never forces a fresh review round by itself.
    - **LOW** → never block. Record in the review artifact for the implementer's awareness but do not send back for a fix round.
    - Trivial mechanical fixes (typo-grade) → you may fix them directly, but then the re-review in the next step is mandatory, because you just became a writer.
    - Findings you and the Owner deliberately scope to a later unit → append to `work/<slug>/deferrals.md` in the worktree *before* the next round, one entry per finding: what was raised, why it was deferred, and where it lands. A deferral that is not written down does not exist for the next cold reviewer, and will be raised again.
-5. **Re-review after any change:** spawn a *new* fresh code-reviewer thread and re-run `scripts/codex-review.sh <slug>` on the updated diff. Increment `work/<slug>/review-round` before each new round. Repeat until both approve or the counter reaches 3 — after 3, auto-triage remaining MEDIUM findings to deferrals and escalate any open CRITICAL/HIGH to the Owner. Do not start round 4.
+5. **Re-review after any change:** spawn a *new* fresh code-reviewer thread and re-run `scripts/codex-review.sh <slug>` on the updated diff. Increment `work/<slug>/review-round` before each new round. Repeat until both approve or the counter reaches 3. The 3-round cap is a safety net for CRITICAL/HIGH churn; escalate any open CRITICAL/HIGH to the Owner. Do not start round 4.
 6. **Record the approved result on the worktree branch:** when both reviewers approve, edit `work/<slug>/plan.md` in the worktree in place to include both `Code-review verdict: APPROVE` and `Codex-review verdict: APPROVE`, flip its status, and sync the current plan body. Commit that plan update in a single commit with `git -C <worktree> add work/<slug>/plan.md` and `git -C <worktree> commit ...`, then from the repo root run `scripts/worktree.sh sync-artifacts <slug>`. Do not `cp` over it from the primary checkout, because that can clobber the sentinels.
 7. **Hand off to release:** report both verdicts, findings summary (resolved and open), and gate status to the Owner, then proceed through the full `/4-release` TRIP.
 
diff --git a/scripts/codex-review.sh b/scripts/codex-review.sh
index 1e5b42bbe6e22f3f031450ede3bb896026cbe39c..c63852b709b2ed73c717c3a43e543f18fd4f8ee8
--- a/scripts/codex-review.sh
+++ b/scripts/codex-review.sh
@@ -105,7 +105,7 @@
   printf 'Every finding gets exactly one severity:\n'
   printf '- CRITICAL: data loss, security hole, or silent wrong result. Blocks in any round.\n'
   printf '- HIGH: incorrect behavior under a realistic scenario. Blocks in any round.\n'
-  printf '- MEDIUM: robustness gap, missing validation, or incomplete contract. Blocks rounds 1-2 only.\n'
+  printf '- MEDIUM: robustness gap, missing validation, or incomplete contract. Never sets the verdict; report it for the orchestrator to route.\n'
   printf '- LOW: style, naming, log hygiene, non-blocking edge cases. Never blocks.\n\n'
   printf 'A finding without a concrete failure scenario is LOW by definition.\n\n'
   printf '## Calibration\n\n'

codex
The targeted grep returned no matches and `git diff --check` is clean. I’m committing now with a concise message about the MEDIUM verdict rule.
exec
/bin/zsh -lc 'git add .claude/agents/code-reviewer.md scripts/codex-review.sh skills/3-review/SKILL.md && git commit -m "Make MEDIUM review findings non-blocking"' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium
 succeeded in 0ms:
[wt/codex-verdict-medium a6ed50a] Make MEDIUM review findings non-blocking
 3 files changed, 5 insertions(+), 5 deletions(-)

diff --git a/.claude/agents/code-reviewer.md b/.claude/agents/code-reviewer.md
index 2141a2c90d23e1d01619ff4850c12031a01c65a5..b4c253732a455036f79e478995ac69e860f0ad21
--- a/.claude/agents/code-reviewer.md
+++ b/.claude/agents/code-reviewer.md
@@ -25,7 +25,7 @@
 
 - **CRITICAL** — data loss, security hole, or silent wrong result. Blocks in any round.
 - **HIGH** — incorrect behavior under a realistic scenario. Blocks in any round.
-- **MEDIUM** — robustness gap, missing validation, or incomplete contract. Blocks in rounds 1–2 only.
+- **MEDIUM** — robustness gap, missing validation, or incomplete contract. Never sets the verdict; report it for the orchestrator to route.
 - **LOW** — style, naming, log hygiene, non-blocking edge cases. Never blocks.
 
 A finding without a concrete failure scenario is LOW by definition — "this could be a problem" is not blocking.
@@ -38,4 +38,4 @@
 
 Verdict (`APPROVE` / `REQUEST CHANGES`) plus numbered findings, each with severity, file:line, and a concrete failure scenario or criterion reference. Most severe first. No praise padding.
 
-A `REQUEST CHANGES` verdict requires at least one CRITICAL or HIGH finding (or MEDIUM in rounds 1–2). If all findings are LOW (or MEDIUM past round 2), the verdict must be `APPROVE` with findings attached — a reviewer that blocks on LOW-only findings is miscalibrated.
+A `REQUEST CHANGES` verdict requires at least one CRITICAL or HIGH finding. If all findings are LOW or MEDIUM, the verdict must be `APPROVE` with findings attached — a reviewer that blocks on LOW-only findings is miscalibrated.
diff --git a/.claude/skills/3-review/SKILL.md b/.claude/skills/3-review/SKILL.md
index 685c4631183ebd26365df64001bd16f5ba99c077..aafd4278237955aa1e6306cde28b91632bd645fb
--- a/.claude/skills/3-review/SKILL.md
+++ b/.claude/skills/3-review/SKILL.md
@@ -14,11 +14,11 @@
 3. **Spawn both reviewers.** Launch the `code-reviewer` agent (fresh thread) with the diff, the plan path, the deferral ledger path, the current round number, and the worktree path, instructed to review per its own definition. From the primary checkout, run `REVIEW_ROUND=<N> scripts/codex-review.sh <slug>` so Codex reviews the branch plan and diff from cold, read-only context and writes `work/<slug>/codex-review.md`. Its exit-code contract is: 0 = APPROVE, so record the sentinel; 1 = REQUEST CHANGES, so route the artifact's findings to the followup flow; >=2 = tooling error, not a verdict. Never record a sentinel from prose in the artifact after a non-zero exit; fix the tooling and re-run.
 4. **Route findings by severity:**
    - **CRITICAL/HIGH** → back to the implementer via `/2-implement`'s followup flow (same worktree). These block regardless of round.
-   - **MEDIUM** → block in rounds 1–2; in round 3+, auto-triage to `work/<slug>/deferrals.md` for the next unit unless you judge them load-bearing.
+   - **MEDIUM** → the orchestrator judges once: fix directly, send back only if load-bearing, or append to `work/<slug>/deferrals.md` for the next unit. MEDIUM never forces a fresh review round by itself.
    - **LOW** → never block. Record in the review artifact for the implementer's awareness but do not send back for a fix round.
    - Trivial mechanical fixes (typo-grade) → you may fix them directly, but then the re-review in the next step is mandatory, because you just became a writer.
    - Findings you and the Owner deliberately scope to a later unit → append to `work/<slug>/deferrals.md` in the worktree *before* the next round, one entry per finding: what was raised, why it was deferred, and where it lands. A deferral that is not written down does not exist for the next cold reviewer, and will be raised again.
-5. **Re-review after any change:** spawn a *new* fresh code-reviewer thread and re-run `scripts/codex-review.sh <slug>` on the updated diff. Increment `work/<slug>/review-round` before each new round. Repeat until both approve or the counter reaches 3 — after 3, auto-triage remaining MEDIUM findings to deferrals and escalate any open CRITICAL/HIGH to the Owner. Do not start round 4.
+5. **Re-review after any change:** spawn a *new* fresh code-reviewer thread and re-run `scripts/codex-review.sh <slug>` on the updated diff. Increment `work/<slug>/review-round` before each new round. Repeat until both approve or the counter reaches 3. The 3-round cap is a safety net for CRITICAL/HIGH churn; escalate any open CRITICAL/HIGH to the Owner. Do not start round 4.
 6. **Record the approved result on the worktree branch:** when both reviewers approve, edit `work/<slug>/plan.md` in the worktree in place to include both `Code-review verdict: APPROVE` and `Codex-review verdict: APPROVE`, flip its status, and sync the current plan body. Commit that plan update in a single commit with `git -C <worktree> add work/<slug>/plan.md` and `git -C <worktree> commit ...`, then from the repo root run `scripts/worktree.sh sync-artifacts <slug>`. Do not `cp` over it from the primary checkout, because that can clobber the sentinels.
 7. **Hand off to release:** report both verdicts, findings summary (resolved and open), and gate status to the Owner, then proceed through the full `/4-release` TRIP.
 
diff --git a/scripts/codex-review.sh b/scripts/codex-review.sh
index 1e5b42bbe6e22f3f031450ede3bb896026cbe39c..c63852b709b2ed73c717c3a43e543f18fd4f8ee8
--- a/scripts/codex-review.sh
+++ b/scripts/codex-review.sh
@@ -105,7 +105,7 @@
   printf 'Every finding gets exactly one severity:\n'
   printf '- CRITICAL: data loss, security hole, or silent wrong result. Blocks in any round.\n'
   printf '- HIGH: incorrect behavior under a realistic scenario. Blocks in any round.\n'
-  printf '- MEDIUM: robustness gap, missing validation, or incomplete contract. Blocks rounds 1-2 only.\n'
+  printf '- MEDIUM: robustness gap, missing validation, or incomplete contract. Never sets the verdict; report it for the orchestrator to route.\n'
   printf '- LOW: style, naming, log hygiene, non-blocking edge cases. Never blocks.\n\n'
   printf 'A finding without a concrete failure scenario is LOW by definition.\n\n'
   printf '## Calibration\n\n'

codex
The commit succeeded. I’m checking the branch state once more so the final summary includes the exact commit and any remaining working tree state.
exec
/bin/zsh -lc 'git rev-parse --short HEAD' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium
 succeeded in 0ms:
a6ed50a

exec
/bin/zsh -lc 'git status --short && git branch --show-current' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium
 succeeded in 0ms:
wt/codex-verdict-medium

exec
/bin/zsh -lc 'git show --stat --oneline --no-renames HEAD' in /Users/cboyfly/Documents/repos/agentic-coding-worktrees/codex-verdict-medium
 succeeded in 0ms:
a6ed50a Make MEDIUM review findings non-blocking
 .claude/agents/code-reviewer.md | 4 ++--
 scripts/codex-review.sh         | 2 +-
 skills/3-review/SKILL.md        | 4 ++--
 3 files changed, 5 insertions(+), 5 deletions(-)

diff --git a/.claude/agents/code-reviewer.md b/.claude/agents/code-reviewer.md
index 2141a2c90d23e1d01619ff4850c12031a01c65a5..b4c253732a455036f79e478995ac69e860f0ad21
--- a/.claude/agents/code-reviewer.md
+++ b/.claude/agents/code-reviewer.md
@@ -25,7 +25,7 @@
 
 - **CRITICAL** — data loss, security hole, or silent wrong result. Blocks in any round.
 - **HIGH** — incorrect behavior under a realistic scenario. Blocks in any round.
-- **MEDIUM** — robustness gap, missing validation, or incomplete contract. Blocks in rounds 1–2 only.
+- **MEDIUM** — robustness gap, missing validation, or incomplete contract. Never sets the verdict; report it for the orchestrator to route.
 - **LOW** — style, naming, log hygiene, non-blocking edge cases. Never blocks.
 
 A finding without a concrete failure scenario is LOW by definition — "this could be a problem" is not blocking.
@@ -38,4 +38,4 @@
 
 Verdict (`APPROVE` / `REQUEST CHANGES`) plus numbered findings, each with severity, file:line, and a concrete failure scenario or criterion reference. Most severe first. No praise padding.
 
-A `REQUEST CHANGES` verdict requires at least one CRITICAL or HIGH finding (or MEDIUM in rounds 1–2). If all findings are LOW (or MEDIUM past round 2), the verdict must be `APPROVE` with findings attached — a reviewer that blocks on LOW-only findings is miscalibrated.
+A `REQUEST CHANGES` verdict requires at least one CRITICAL or HIGH finding. If all findings are LOW or MEDIUM, the verdict must be `APPROVE` with findings attached — a reviewer that blocks on LOW-only findings is miscalibrated.
diff --git a/.claude/skills/3-review/SKILL.md b/.claude/skills/3-review/SKILL.md
index 685c4631183ebd26365df64001bd16f5ba99c077..aafd4278237955aa1e6306cde28b91632bd645fb
--- a/.claude/skills/3-review/SKILL.md
+++ b/.claude/skills/3-review/SKILL.md
@@ -14,11 +14,11 @@
 3. **Spawn both reviewers.** Launch the `code-reviewer` agent (fresh thread) with the diff, the plan path, the deferral ledger path, the current round number, and the worktree path, instructed to review per its own definition. From the primary checkout, run `REVIEW_ROUND=<N> scripts/codex-review.sh <slug>` so Codex reviews the branch plan and diff from cold, read-only context and writes `work/<slug>/codex-review.md`. Its exit-code contract is: 0 = APPROVE, so record the sentinel; 1 = REQUEST CHANGES, so route the artifact's findings to the followup flow; >=2 = tooling error, not a verdict. Never record a sentinel from prose in the artifact after a non-zero exit; fix the tooling and re-run.
 4. **Route findings by severity:**
    - **CRITICAL/HIGH** → back to the implementer via `/2-implement`'s followup flow (same worktree). These block regardless of round.
-   - **MEDIUM** → block in rounds 1–2; in round 3+, auto-triage to `work/<slug>/deferrals.md` for the next unit unless you judge them load-bearing.
+   - **MEDIUM** → the orchestrator judges once: fix directly, send back only if load-bearing, or append to `work/<slug>/deferrals.md` for the next unit. MEDIUM never forces a fresh review round by itself.
    - **LOW** → never block. Record in the review artifact for the implementer's awareness but do not send back for a fix round.
    - Trivial mechanical fixes (typo-grade) → you may fix them directly, but then the re-review in the next step is mandatory, because you just became a writer.
    - Findings you and the Owner deliberately scope to a later unit → append to `work/<slug>/deferrals.md` in the worktree *before* the next round, one entry per finding: what was raised, why it was deferred, and where it lands. A deferral that is not written down does not exist for the next cold reviewer, and will be raised again.
-5. **Re-review after any change:** spawn a *new* fresh code-reviewer thread and re-run `scripts/codex-review.sh <slug>` on the updated diff. Increment `work/<slug>/review-round` before each new round. Repeat until both approve or the counter reaches 3 — after 3, auto-triage remaining MEDIUM findings to deferrals and escalate any open CRITICAL/HIGH to the Owner. Do not start round 4.
+5. **Re-review after any change:** spawn a *new* fresh code-reviewer thread and re-run `scripts/codex-review.sh <slug>` on the updated diff. Increment `work/<slug>/review-round` before each new round. Repeat until both approve or the counter reaches 3. The 3-round cap is a safety net for CRITICAL/HIGH churn; escalate any open CRITICAL/HIGH to the Owner. Do not start round 4.
 6. **Record the approved result on the worktree branch:** when both reviewers approve, edit `work/<slug>/plan.md` in the worktree in place to include both `Code-review verdict: APPROVE` and `Codex-review verdict: APPROVE`, flip its status, and sync the current plan body. Commit that plan update in a single commit with `git -C <worktree> add work/<slug>/plan.md` and `git -C <worktree> commit ...`, then from the repo root run `scripts/worktree.sh sync-artifacts <slug>`. Do not `cp` over it from the primary checkout, because that can clobber the sentinels.
 7. **Hand off to release:** report both verdicts, findings summary (resolved and open), and gate status to the Owner, then proceed through the full `/4-release` TRIP.
 
diff --git a/scripts/codex-review.sh b/scripts/codex-review.sh
index 1e5b42bbe6e22f3f031450ede3bb896026cbe39c..c63852b709b2ed73c717c3a43e543f18fd4f8ee8
--- a/scripts/codex-review.sh
+++ b/scripts/codex-review.sh
@@ -105,7 +105,7 @@
   printf 'Every finding gets exactly one severity:\n'
   printf '- CRITICAL: data loss, security hole, or silent wrong result. Blocks in any round.\n'
   printf '- HIGH: incorrect behavior under a realistic scenario. Blocks in any round.\n'
-  printf '- MEDIUM: robustness gap, missing validation, or incomplete contract. Blocks rounds 1-2 only.\n'
+  printf '- MEDIUM: robustness gap, missing validation, or incomplete contract. Never sets the verdict; report it for the orchestrator to route.\n'
   printf '- LOW: style, naming, log hygiene, non-blocking edge cases. Never blocks.\n\n'
   printf 'A finding without a concrete failure scenario is LOW by definition.\n\n'
   printf '## Calibration\n\n'

codex
Implemented and committed on `wt/codex-verdict-medium`.

Commit: `a6ed50a Make MEDIUM review findings non-blocking`

Changed:
- Updated `.claude/agents/code-reviewer.md` so MEDIUM never sets the verdict, and `REQUEST CHANGES` requires exactly CRITICAL/HIGH.
- Updated `scripts/codex-review.sh` inline prompt with the same MEDIUM rule.
- Updated `.claude/skills/3-review/SKILL.md` routing so MEDIUM is orchestrator-routed, while only CRITICAL/HIGH block and drive the round cap. Git records this as `skills/3-review/SKILL.md` because `.claude/skills` is a symlink.

Verification:
- `bash scripts/gate.sh` passed: 170 passed, 0 failed.
- Required grep for `rounds 1` / `auto-triage remaining MEDIUM` returned no matches.

No acceptance criteria were partially met, and I did not touch out-of-scope files.
diff --git a/.claude/agents/code-reviewer.md b/.claude/agents/code-reviewer.md
index 2141a2c90d23e1d01619ff4850c12031a01c65a5..b4c253732a455036f79e478995ac69e860f0ad21
--- a/.claude/agents/code-reviewer.md
+++ b/.claude/agents/code-reviewer.md
@@ -25,7 +25,7 @@
 
 - **CRITICAL** — data loss, security hole, or silent wrong result. Blocks in any round.
 - **HIGH** — incorrect behavior under a realistic scenario. Blocks in any round.
-- **MEDIUM** — robustness gap, missing validation, or incomplete contract. Blocks in rounds 1–2 only.
+- **MEDIUM** — robustness gap, missing validation, or incomplete contract. Never sets the verdict; report it for the orchestrator to route.
 - **LOW** — style, naming, log hygiene, non-blocking edge cases. Never blocks.
 
 A finding without a concrete failure scenario is LOW by definition — "this could be a problem" is not blocking.
@@ -38,4 +38,4 @@
 
 Verdict (`APPROVE` / `REQUEST CHANGES`) plus numbered findings, each with severity, file:line, and a concrete failure scenario or criterion reference. Most severe first. No praise padding.
 
-A `REQUEST CHANGES` verdict requires at least one CRITICAL or HIGH finding (or MEDIUM in rounds 1–2). If all findings are LOW (or MEDIUM past round 2), the verdict must be `APPROVE` with findings attached — a reviewer that blocks on LOW-only findings is miscalibrated.
+A `REQUEST CHANGES` verdict requires at least one CRITICAL or HIGH finding. If all findings are LOW or MEDIUM, the verdict must be `APPROVE` with findings attached — a reviewer that blocks on LOW-only findings is miscalibrated.
diff --git a/.claude/skills/3-review/SKILL.md b/.claude/skills/3-review/SKILL.md
index 685c4631183ebd26365df64001bd16f5ba99c077..aafd4278237955aa1e6306cde28b91632bd645fb
--- a/.claude/skills/3-review/SKILL.md
+++ b/.claude/skills/3-review/SKILL.md
@@ -14,11 +14,11 @@
 3. **Spawn both reviewers.** Launch the `code-reviewer` agent (fresh thread) with the diff, the plan path, the deferral ledger path, the current round number, and the worktree path, instructed to review per its own definition. From the primary checkout, run `REVIEW_ROUND=<N> scripts/codex-review.sh <slug>` so Codex reviews the branch plan and diff from cold, read-only context and writes `work/<slug>/codex-review.md`. Its exit-code contract is: 0 = APPROVE, so record the sentinel; 1 = REQUEST CHANGES, so route the artifact's findings to the followup flow; >=2 = tooling error, not a verdict. Never record a sentinel from prose in the artifact after a non-zero exit; fix the tooling and re-run.
 4. **Route findings by severity:**
    - **CRITICAL/HIGH** → back to the implementer via `/2-implement`'s followup flow (same worktree). These block regardless of round.
-   - **MEDIUM** → block in rounds 1–2; in round 3+, auto-triage to `work/<slug>/deferrals.md` for the next unit unless you judge them load-bearing.
+   - **MEDIUM** → the orchestrator judges once: fix directly, send back only if load-bearing, or append to `work/<slug>/deferrals.md` for the next unit. MEDIUM never forces a fresh review round by itself.
    - **LOW** → never block. Record in the review artifact for the implementer's awareness but do not send back for a fix round.
    - Trivial mechanical fixes (typo-grade) → you may fix them directly, but then the re-review in the next step is mandatory, because you just became a writer.
    - Findings you and the Owner deliberately scope to a later unit → append to `work/<slug>/deferrals.md` in the worktree *before* the next round, one entry per finding: what was raised, why it was deferred, and where it lands. A deferral that is not written down does not exist for the next cold reviewer, and will be raised again.
-5. **Re-review after any change:** spawn a *new* fresh code-reviewer thread and re-run `scripts/codex-review.sh <slug>` on the updated diff. Increment `work/<slug>/review-round` before each new round. Repeat until both approve or the counter reaches 3 — after 3, auto-triage remaining MEDIUM findings to deferrals and escalate any open CRITICAL/HIGH to the Owner. Do not start round 4.
+5. **Re-review after any change:** spawn a *new* fresh code-reviewer thread and re-run `scripts/codex-review.sh <slug>` on the updated diff. Increment `work/<slug>/review-round` before each new round. Repeat until both approve or the counter reaches 3. The 3-round cap is a safety net for CRITICAL/HIGH churn; escalate any open CRITICAL/HIGH to the Owner. Do not start round 4.
 6. **Record the approved result on the worktree branch:** when both reviewers approve, edit `work/<slug>/plan.md` in the worktree in place to include both `Code-review verdict: APPROVE` and `Codex-review verdict: APPROVE`, flip its status, and sync the current plan body. Commit that plan update in a single commit with `git -C <worktree> add work/<slug>/plan.md` and `git -C <worktree> commit ...`, then from the repo root run `scripts/worktree.sh sync-artifacts <slug>`. Do not `cp` over it from the primary checkout, because that can clobber the sentinels.
 7. **Hand off to release:** report both verdicts, findings summary (resolved and open), and gate status to the Owner, then proceed through the full `/4-release` TRIP.
 
diff --git a/scripts/codex-review.sh b/scripts/codex-review.sh
index 1e5b42bbe6e22f3f031450ede3bb896026cbe39c..c63852b709b2ed73c717c3a43e543f18fd4f8ee8
--- a/scripts/codex-review.sh
+++ b/scripts/codex-review.sh
@@ -105,7 +105,7 @@
   printf 'Every finding gets exactly one severity:\n'
   printf '- CRITICAL: data loss, security hole, or silent wrong result. Blocks in any round.\n'
   printf '- HIGH: incorrect behavior under a realistic scenario. Blocks in any round.\n'
-  printf '- MEDIUM: robustness gap, missing validation, or incomplete contract. Blocks rounds 1-2 only.\n'
+  printf '- MEDIUM: robustness gap, missing validation, or incomplete contract. Never sets the verdict; report it for the orchestrator to route.\n'
   printf '- LOW: style, naming, log hygiene, non-blocking edge cases. Never blocks.\n\n'
   printf 'A finding without a concrete failure scenario is LOW by definition.\n\n'
   printf '## Calibration\n\n'

tokens used
27,045
Implemented and committed on `wt/codex-verdict-medium`.

Commit: `a6ed50a Make MEDIUM review findings non-blocking`

Changed:
- Updated `.claude/agents/code-reviewer.md` so MEDIUM never sets the verdict, and `REQUEST CHANGES` requires exactly CRITICAL/HIGH.
- Updated `scripts/codex-review.sh` inline prompt with the same MEDIUM rule.
- Updated `.claude/skills/3-review/SKILL.md` routing so MEDIUM is orchestrator-routed, while only CRITICAL/HIGH block and drive the round cap. Git records this as `skills/3-review/SKILL.md` because `.claude/skills` is a symlink.

Verification:
- `bash scripts/gate.sh` passed: 170 passed, 0 failed.
- Required grep for `rounds 1` / `auto-triage remaining MEDIUM` returned no matches.

No acceptance criteria were partially met, and I did not touch out-of-scope files.
