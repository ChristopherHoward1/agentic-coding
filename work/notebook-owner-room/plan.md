# Notebook owner room: short descriptive analysis per heading, plus an empty Owner cell

**Slug:** notebook-owner-room · **Date:** 2026-11-23 · **Status:** implemented

## Goal

The Owner has used `work-slim` a lot, and agent-written notebooks come out heavy with the agent's own reasoning, leaving no room for the Owner's. `7f7c87b` (on `main`, unreleased) swung to "at most a line or two of core findings, no interpretation." The Owner wants some analysis kept, and an explicit place for their own reasoning. Done = both profiles' notebook-writing rule allows two or three lines of *descriptive* analysis per heading (direction, size, and how it compares with the baseline or a prior run) but no conclusions, and ends every heading's section with an empty `**Owner:**` markdown cell that the agent never writes in, edits or deletes. The unit ships in a release so `publish.sh` carries it to the template that work machines install from.

## Approach

Replace the three-bullet notebook rule that `7f7c87b` added, in both places, with the same text (profiles don't merge, so the two copies are deliberate):

> Notebooks the agent writes or edits carry structure, core findings and a short descriptive read. Reasoning about what the results mean is left to the Owner, more so here than for backing scripts.
> - Markdown cells hold headings and subheadings: one question per heading, followed by the code that answers it.
> - After the code: the core finding (the number, its n and interval, the partition), then at most two or three lines of descriptive analysis: direction, size, and how it compares with the baseline or a prior run.
> - Each question heading's section (not each subheading) ends with a markdown cell holding only `**Owner:**`. Add one to each section the agent writes or edits; leave sections it doesn't touch as they are. The agent never writes in, edits or deletes an Owner cell; an existing Owner cell keeps its text and moves with its heading.
> - No interpretation of what a result means, recommendations, caveat lists or next steps unless the Owner asks. When asked, expand only the section named.

In `work-slim.md` the paragraph and its bullets stay indented three spaces under the Explore list item, so the Explore / Ship / Loop numbering holds.

`work-slim`'s `reports/<topic>.md` rule (Read left blank for the Owner) stays as is. `ARCHI.md`'s `harness/profiles/` bullet gets a targeted edit: `machine-learning` gains `notebook writing (headings, core findings, a short descriptive read, an empty Owner cell per question)` and `work-slim` gains `the same notebook-writing rule`; `harness/` is already newer than `ARCHI.md` on `main` because of `7f7c87b`, so release refuses without it.

Alternative considered: a single "Owner notes" cell at the end of the notebook. Rejected: the Owner reasons per question, and a per-heading cell sits next to the numbers it's about.

## Footprint

Files to modify:
- `harness/profiles/work-slim.md` (Explore lane's notebook bullets)
- `harness/profiles/machine-learning.md` (`## Notebook writing`)
- `ARCHI.md` (`harness/profiles/` bullet)
- `PLAN.md` (orchestrator: this unit's Now line, committed on the branch)

Files NOT to touch:
- `harness/profiles/work.md`

## Acceptance criteria

- [ ] Both profiles contain the rule text from Approach, identical apart from work-slim's three-space indent: `a=$(sed -n '/^ *Notebooks the agent writes/,/expand only the section named/p' harness/profiles/work-slim.md | sed 's/^   //'); b=$(sed -n '/^Notebooks the agent writes/,/expand only the section named/p' harness/profiles/machine-learning.md); [ -n "$a" ] && [ "$a" = "$b" ]` exits 0.
- [ ] The text matches the plan's own blockquote: with `b` from the previous criterion, `diff <(sed -n '/^> Notebooks the agent writes/,/expand only the section named/p' work/notebook-owner-room/plan.md | sed 's/^> \{0,1\}//') <(printf '%s\n' "$b")` exits 0.
- [ ] `work-slim.md`'s lanes are still numbered `1.` Explore, `2.` Ship, `3.` Loop, with the notebook paragraph indented under item 1.
- [ ] `grep -c 'at most a line or two' harness/profiles/*.md` reports 0 for every file (the old rule is gone).
- [ ] `grep -c 'The agent never writes in, edits or deletes an Owner cell' harness/profiles/work-slim.md harness/profiles/machine-learning.md` reports 1 for each file.
- [ ] `grep -c 'left blank for the Owner. Fill it only when asked.' harness/profiles/work-slim.md` reports 1 (report Read bullet unchanged).
- [ ] `grep -c 'an empty Owner cell per question' ARCHI.md` reports 1, `grep -c 'the same notebook-writing rule' ARCHI.md` reports 1, and `harness archi-fresh wt/notebook-owner-room` exits 0.
- [ ] `harness gate` passes.

## Release

Release note: Agent-written notebooks (`machine-learning`, `work-slim`) keep headings, core findings and two or three lines of descriptive analysis per question, and end each question with an empty `**Owner:**` cell the agent never touches.

## Demonstration

None: prose-only change to profile guidance; there is no runnable behavior.

## Review

Round 1 (plan-reviewer): REVISE. All five findings applied:
1. HIGH: criterion 1's work-slim extraction could never match the indented paragraph. The range start is now `/^ *Notebooks…/`, and the Approach says the copy stays indented under Explore (plus a numbering criterion).
2. Owner cells go per question heading, not per subheading.
3. Editing existing notebooks: add Owner cells only to sections the agent writes; an existing Owner cell keeps its text and moves with its heading.
4. "anything unexpected" dropped; the list ends "how it compares with the baseline or a prior run".
5. Criteria 3–5 are now grep commands; the ARCHI criterion names exact strings, not a line number.

Round 2 (fresh plan-reviewer): APPROVE, with four small findings, all applied: the Goal's analysis list now matches the rule; a criterion pins the profile text to this plan's blockquote; the ARCHI `work-slim` check is a grep; Owner cells go in sections the agent writes or edits. Noted, no change: `work.md` doesn't point at `## Notebook writing`, so `work`-profile repos don't get the rule (out of scope here).

Plan verdict: APPROVE

Code review round 1 (fresh code-reviewer): APPROVE; all eight criteria met, gate and demo pass. Two LOWs, not acted on: a blank line added before `2. **Ship**` in `work-slim.md` (harmless; numbering holds), and "holding only `**Owner:**`" could read as forbidding a filled-in Owner cell (the never-writes-in/edits/deletes sentence already prevents the bad outcome).
Codex review round 1: APPROVE, no findings.

Code-review verdict: APPROVE
Codex-review verdict: APPROVE
