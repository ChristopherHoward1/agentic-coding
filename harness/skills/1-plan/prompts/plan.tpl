# {{TITLE}}

**Slug:** {{SLUG}} · **Date:** {{DATE}} · **Status:** draft | approved | implemented | merged

{{Optional header line when this unit builds on an unmerged parent: Stacked on: <parent-slug>}}

## Goal

{{One paragraph: the problem and what done looks like.}}

## Approach

{{The shape of the change. Alternatives considered, one line each, only if a real choice was made.}}

## Footprint

Files to modify:
- {{path}}

Files NOT to touch:
- {{path — only when there's a live hazard}}

## Acceptance criteria

- [ ] {{Each checkable by a command, diff inspection, or named observable behavior.}}

## Release

Release note: {{One line for CHANGELOG.md.}}

## Demonstration

Run real changed behavior on real inputs, not test fixtures; write only under `mktemp -d`. Use `None: <reason>` only for units with no runnable behavior.
The block runs under `bash -e`; show expected failures with `cmd || echo "exit=$?"`.
To capture output and status, use `rc=0; out=$(cmd) || rc=$?`.
Use `[ ]` / `test` for mid-block checks, or `[[ ... ]] || exit 1`: Bash 3.2 does not stop on mid-block `[[ ]]` failures.

```sh
{{Commands demonstrating the changed behavior.}}
```
Expected: {{One line stating the expected output.}}

## Review

{{Filled by /1-plan step 4: reviewer verdict, applied findings, disagreements + reasoning.}}
Plan verdict: {{APPROVE|REVISE}}
