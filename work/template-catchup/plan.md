# Template catch-up: release the merged small fixes

**Slug:** template-catchup · **Date:** 2026-11-23 · **Status:** implemented

## Goal

Three small fixes have merged to `main` since v2026.11.1, but the public template only syncs on a release: #79 (README refresh), #80 (`/docs` has the orchestrator write prose; the codex handoff template is removed) and #81 (`plan.tpl` lists the `PLAN.md` Now line in every footprint). The Owner asked for a release so the template gets them. Done = a release whose note names all three, followed by the template sync.

## Approach

A release-only unit, with no code change. The branch carries this plan and the orchestrator's `PLAN.md` Now line. The release note lists the three fixes. The code-reviewer also reads `git diff v2026.11.1..origin/main`, the range being released, to check the note against it.

## Footprint

Files to modify:
- `PLAN.md` (orchestrator: this unit's Now line)
- `harness/skills/docs/SKILL.md` and `ARCHI.md`: round-1 fix (see Review)

## Acceptance criteria

- [ ] The release note names the README refresh, the `/docs` change and the `plan.tpl` footprint default, and each matches `git diff v2026.11.1..origin/main`.
- [ ] `/docs` opens its PR to the branch the worktree was based on (`integration_branch` when set, otherwise `main`), and names where the slug comes from.
- [ ] `harness archi-fresh wt/template-catchup` exits 0.
- [ ] `harness gate` passes.

## Release

Release note: Ships three small fixes. The README describes the current loop, shared-repo use and a shorter rationale. `/docs` has the orchestrator write prose directly, with no codex dispatch. `plan.tpl`'s footprint lists the `PLAN.md` Now line by default. `/docs` opens its PR to the integration branch when one is set.

## Demonstration

None: release-only unit; the released changes are prose and a template line, with no runnable behavior.

## Review

Release-only unit, planned at the Owner's request ("cut a release so the template gets these"); no plan-reviewer round (no design to review).
Owner approval (2026-11-23): release the merged small fixes #79–#81 to the template.
Plan verdict: APPROVE

Code review round 1: codex APPROVE. Code-reviewer APPROVE, with one MEDIUM in the released range: `/docs` (#80) branched from the integration branch but opened its PR to the default branch, bypassing Promote. The orchestrator fixed it directly in this unit, since it wrote #80: the PR targets the worktree's base branch, and the slug's source is now stated. A fresh round follows. LOWs left as-is: the constitution's small-fix wording versus `/docs`' merge step, and the handoff template's deletion not named in the note.

Code review round 2: code-reviewer APPROVE (two LOWs: "otherwise `main`" simplifies the reused-branch and no-origin cases; criterion 1's wording doesn't cover the branch's own `/docs` fix). Codex APPROVE, no findings.

Code-review verdict: APPROVE
Codex-review verdict: APPROVE
