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
