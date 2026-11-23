# README refresh: correct the loop, add shared-repo use, tighten the rationale

**Slug:** readme-refresh · **Date:** 2026-11-23 · **Status:** approved (docs unit, small-fix lane)

## Goal

`README.md` was last edited for `stacked-units` (v2026.10.9) and has drifted. It says the Owner merges, but under full TRIP autonomy the Orchestrator merges. It doesn't describe how the harness is used in a shared repository (registry mode, `work-slim`, `integration_branch`, Promote). And "Why the agents grill each other" reads as padded. Done = the README describes the shipped harness accurately and briefly.

## Changes

1. **Who merges.**
   - The intro: the Owner sets direction; the Orchestrator runs the release, including the push, PR, merge and tag (full TRIP autonomy).
   - The mermaid `Merge` node: "Orchestrator merges PR (rebase / fast-forward)". Drop the `human` class from that node.
   - One sentence noting that in registry mode the loop stops after review and the Owner (or the profile's lanes) takes the PR from there.
2. **Loop details that shipped.** One short clause each, in the diagram labels or the text right after it:
   - `/2-implement` runs the plan's `## Demonstration` block (`harness demo`) after the gate passes.
   - `/3-review` uses two independent reviewers: a fresh Claude `code-reviewer` and a codex second-vendor reviewer. Both must APPROVE.
   - A plan can declare `Stacked on: <parent>` to build on an unmerged unit.
3. **New section "Using it in a shared repo"**, placed after "Best-of-N implement".
   - Keep it at most about 20 lines and generic: no employer, team, product or tool names other than git, Bitbucket/GitHub-neutral wording, and Claude Code.
   - `harness register` keeps all harness state in a home-directory state dir, so nothing harness-related is committed.
   - The `work-slim` profile's lanes, one line each:
     - **Explore:** notebooks and reports, no loop.
     - **Ship:** gate plus a fresh reviewer, then a self-merged PR.
     - **Loop:** the full loop, for changes that could cost days.
     - **Promote:** one PR from the integration branch to a protected `main`, listing each change as `[reviewed]` or `[unreviewed]`.
   - `integration_branch` in `config.yaml` (for example `dev`) moves unit worktrees and review diffs off `main`, so small PRs land without waiting on a protected-branch approval.
   - Source of truth for the details: `harness/profiles/work-slim.md`. Describe, don't copy.
4. **Rewrite "Why the agents grill each other"** to at most about 12 lines.
   - Keep the four ideas, one short paragraph or bullet each:
     - writer ≠ reviewer, enforced by read-only tools;
     - fresh cold context per review, and per re-review;
     - a different model or vendor per role;
     - the gate script that nobody overrules.
   - End with one sentence on why both are needed: the gate catches mechanical defects, and reviewers catch what a green gate hides.
   - Cut the rhetorical framing ("The core bet…", "motivated to declare victory", "routinely surface"), the blockquote and the bold lead-ins. Plain, direct sentences.
5. **Leave everything else unchanged unless it is now wrong.** That covers Design rules, Layout, Getting started and Requirements. In Layout's `harness/profiles/` line, `work-slim` is already listed.

## Footprint

Files to modify:
- `README.md`

Files NOT to touch:
- everything else (no `harness/`, `ARCHI.md` or `PLAN.md` edits)

## Constraints

- The README is published in the public template, so name no dogfood-only scripts (for example `scripts/publish.sh`) and nothing about the Owner's employer or work environment.
- Don't invent features. Every claim must match the shipped skills, scripts and profiles under `harness/`; check a claim against those files when in doubt.
- Keep the two mermaid diagrams valid mermaid, and keep the existing `classDef` styling.
- Total README length should not grow by more than about 15 lines; the rationale cut should pay for the new section.
- Plain prose, no filler, no emoji, no marketing tone.

## Release

Small-fix lane: branch plus a PR to `main`. No VERSION bump. The README reaches the template with the next release.
