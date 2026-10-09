# Acceptance Demonstration

**Slug:** acceptance-demo · **Date:** 2026-10-09 · **Status:** implemented

## Goal

Right now nothing checks the work against reality. The gate runs static checks and hermetic tests. Both reviewers judge the diff against the plan. Nobody runs the finished change on real inputs and looks at what it does, so a diff can match its plan and still fail at integration. The plan template's `## Verification` section is meant to hold that check, but it is free prose that no stage ever runs. Done means three things:
- Every plan carries one runnable demonstration.
- The implementer runs it before finishing, and in single-agent mode its output lands in `notes.md`. In fan mode, the reviewer's run is the only record.
- The cold code-reviewer runs it again itself and judges whether the output actually shows the goal.

## Approach

- **The demonstration is a script, like the gate.** New `scripts/demo.sh <slug> [<dir>]` reads `<dir>/work/<slug>/plan.md` (default `<dir>` is `.`). It takes the first fenced ```` ```sh ```` or ```` ```bash ```` block inside the `## Demonstration` section, runs it as plain `bash <file>` from `<dir>` (no `-e`, so a failing command doesn't stop the commands after it), and streams stdout and stderr. A `## ` line counts as a heading only outside a fence: the block runs from the first opening fence after the heading to its matching closing fence, even if a line inside the block starts with `## `. Exit codes:
  - `0`: the demonstration passed.
  - `1`: the demonstration failed. Either the block exited non-zero (the script reports the real exit code), or it dirtied the worktree: `git -C <dir> status --porcelain` differs before and after the run (message: `demo dirtied the worktree`). A dirty tree would trip `release.sh`'s `check_clean_worktree` and would mean the read-only reviewer had changed the tree under review.
  - `2`: plan or tooling error (no plan, no `## Demonstration` section, neither a block nor a `None:` line before the next `## ` heading, or `<dir>` is not a git work tree). This is never a demo verdict. The section ends at the next `## ` heading, so a block in a later section (such as a quoted command in `## Review`) is never run.
  - A section whose body is `None: <reason>` instead of a block prints `demo: none — <reason>` and exits 0. That covers docs-only and process-only units. The plan-reviewer decides whether the reason holds.
- **Replace `## Verification` in `plan.tpl` with `## Demonstration`.** No net new section. The section explains three rules:
  - The block runs the real changed behavior on real inputs, not test fixtures.
  - It writes only under `mktemp -d`.
  - It is followed by one line stating the expected output.

  Nothing parses `## Verification` today (verified by the plan-reviewer), so older plans are unaffected.
- **Who runs it.** The demo is wired into existing stages, with no new orchestration (reviewer finding 4: the simpler version):
  - The **implementer** runs `scripts/demo.sh <slug>` after the gate passes and the work is committed, so it runs on a clean tree and the dirty-tree check sees any write the demo makes. If the demo fails, it fixes the problem, re-runs the gate, commits, and runs the demo again. It runs it before finishing and pastes its output into its summary, which lands in `notes.md`. This comes from `handoff.tpl`; `followup.tpl` says to re-run both the gate and the demo. Fan samples use the same `handoff.tpl`, so fan mode needs no extra wording.
  - The **code-reviewer** runs it itself from the worktree (`cd <worktree> && scripts/demo.sh <slug>`, the branch copy, the same way it runs the gate). It doesn't trust the implementer's pasted output. A non-zero demo, or output that doesn't show the plan's goal, is HIGH and needs a concrete scenario. That HIGH goes through `/3-review`'s existing followup flow.
  - The **plan-reviewer** gains a fifth judgment: is the demonstration real? It must exercise the changed behavior and produce output a reader can check. `None:` is acceptable only when the unit has no runnable behavior.
- Alternatives considered:
  - An orchestrator demo step in `/2-implement` with its own retry routing. Dropped: there's no cited incident that justifies the extra stage logic, and a failing demo already routes through review as a HIGH.
  - Having `release.sh` refuse without a demo. Rejected: the review already gates release.
  - Wiring the demo into `codex-review.sh`. Deferred: v1 needs one independent runner.
  - Adding a timeout. Deferred: macOS has no `timeout` by default.

## Footprint

Files to modify:
- `scripts/demo.sh` (new)
- `tests/test-scripts.sh` (hermetic `demo.sh` cases)
- `skills/1-plan/prompts/plan.tpl` (`## Verification` becomes `## Demonstration`)
- `skills/2-implement/prompts/handoff.tpl` (order: gate, commit, then `demo.sh`; include its output in the summary)
- `skills/2-implement/prompts/followup.tpl` (re-run the gate, commit, then re-run `demo.sh`)
- `.claude/agents/plan-reviewer.md` (fifth judgment)
- `.claude/agents/code-reviewer.md` (run-the-demo step and its severity)
- `ARCHI.md` (targeted edit on the branch for the new script, per the 2026-09-01 decision)

Files NOT to touch:
- `skills/2-implement/SKILL.md`, `skills/3-review/SKILL.md`. There is no stage-routing change.
- `scripts/codex-review.sh`, `scripts/release.sh`, `scripts/state.sh`, `scripts/gate.sh`. Their contracts stay unchanged.
- `PLAN.md`, `README.md`. These are owned by `/4-release` and `/5-retro`.

## Acceptance criteria

- [ ] `scripts/demo.sh <slug> <dir>` runs only the first `sh`/`bash` block inside `## Demonstration`, with `<dir>` as the working directory. Two fixtures prove scoping. In one, the plan has an earlier `sh` block in another section, and that block is not run. In the other, `## Demonstration` has no block or `None:` line and the next `## ` section has an `sh` block: the result is exit 2 and that block is not run. A `bash`-fenced block is accepted. A block that contains a line starting with `## ` runs in full.
- [ ] The exit-code contract is covered by hermetic tests:
  - pass gives 0
  - a failing block gives 1, and the message includes the real exit code
  - a block that creates an untracked file in `<dir>` gives 1 with `demo dirtied the worktree`
  - `None: <reason>` gives 0 and prints the reason
  - a missing plan, a missing section, an empty section, or a `<dir>` that is not a git work tree gives 2
- [ ] Three guards are each pinned by mutation: the section start, the section end, and the dirty-tree check. The code-reviewer applies each mutation itself, confirms with `git diff` that it landed, and shows that the suite fails (per the 2026-08-28 decision).
- [ ] `plan.tpl` has `## Demonstration` with a fenced `sh` placeholder, the real-inputs, `mktemp -d` and expected-output rules, and no `## Verification`.
- [ ] `handoff.tpl` orders the steps as gate, then commit, then `scripts/demo.sh <slug>`, and asks for the demo output in the summary. `followup.tpl` says to re-run the gate, commit, then re-run `scripts/demo.sh <slug>`.
- [ ] `plan-reviewer.md` lists five judgments, including whether the demonstration is real. `code-reviewer.md` has the reviewer run the worktree's `scripts/demo.sh <slug>` itself and calls a failing or non-demonstrating demo HIGH.
- [ ] `ARCHI.md` describes `scripts/demo.sh`, updates the check count, and lists the `demo.sh` cases under `tests/test-scripts.sh` and Verification. `scripts/archi-fresh.sh wt/acceptance-demo` exits 0.
- [ ] `scripts/gate.sh` passes.

## Release

Release note: `scripts/demo.sh` runs each plan's `## Demonstration` block. The implementer runs it before finishing, and the code-reviewer re-runs it cold, so a change is shown working on real inputs, not just matched against its plan.

## Demonstration

```sh
scripts/demo.sh docs-stage .; echo "legacy exit=$?"
d=$(mktemp -d); git -C "$d" init -q; mkdir -p "$d/work/x"; f='```'
printf '## Demonstration\n\n%ssh\npwd; echo demo-ran\n%s\n' "$f" "$f" > "$d/work/x/plan.md"
scripts/demo.sh x "$d"; echo "pass-case exit=$?"
printf '## Demonstration\n\n%sbash\necho about-to-fail; exit 3\n%s\n' "$f" "$f" > "$d/work/x/plan.md"
scripts/demo.sh x "$d"; echo "fail-case exit=$?"
rm -rf "$d"
```

Expected: a "no `## Demonstration`" message and `legacy exit=2` (a real legacy plan), then the temp dir path, `demo-ran`, `pass-case exit=0`, then `about-to-fail`, a message naming exit 3, and `fail-case exit=1`. The prompt and agent wiring can't be demonstrated by running anything; diff inspection under the acceptance criteria covers it.

## Review

Reviewer: fresh `plan-reviewer` subagent (opus, cold, read-only), 2026-10-09. Verdict on the first draft: **REVISE**. All eight findings accepted:

1. The implementer was never told to run the demo. `handoff.tpl` now has the run step; `followup.tpl` now says to re-run the gate and the demo.
2. A demo that writes files would make the branch unreleasable. `demo.sh` now fails on a dirty-tree delta, and `plan.tpl` requires writes under `mktemp -d`.
3. Fan mode wasn't covered. Moot after finding 4: there are no `/2-implement` changes, and fan samples share `handoff.tpl`.
4. The simpler version was taken. The `/2-implement` orchestrator step and its retry routing are dropped; a failing demo is a review HIGH.
5. The mutation evidence had no location. The code-reviewer now applies each mutation itself.
6. It was unclear which copy of `demo.sh` runs. It's now the worktree (branch) copy for both runners. The block is plan-authored code either way, so binding the runner to `main` would add no trust.
7. The plan's own demo used only fixtures. It now also runs against the real `docs-stage` plan, and the undemoable wiring is called out.
8. Fences: both `sh` and `bash` are accepted.

Round 2: a fresh `plan-reviewer` gave **REVISE**. All five findings accepted:

1. The Goal still promised the orchestrator step that the Approach had dropped. Goal bullet 2 now matches the Approach.
2. The dirty-tree check could miss writes to files the implementer had already modified. The demo now runs after the commit, on a clean tree.
3. A missing section-end guard could run a block from a later section. Added the next-heading fixture, and that guard is now mutation-pinned.
4. A `<dir>` that isn't a git work tree is now an exit-2 case.
5. The `ARCHI.md` test count and suite list are now part of AC 7.

Round 3: a fresh `plan-reviewer` gave **APPROVE**, with four minor non-blocking findings, all applied as clarifications:

1. Fan mode doesn't record the demo output. The Goal now says so.
2. `handoff.tpl` now says what to do when the demo fails.
3. A `## ` line inside a fence no longer ends the section, and a fixture covers it.
4. The block runs as plain `bash`, with no `-e`.

Finding 5 was a note: the dirty-tree check during review has a residual gap that is acceptable for v1.

There are no disagreements.

Plan verdict: APPROVE

### Code review (round 1, 2026-10-09)

- Fresh `code-reviewer` (opus): **APPROVE**, all 8 acceptance criteria met.
  - It ran the gate (200/200) and the demonstration; the output matched Expected exactly.
  - It mutation-pinned all three guards in a throwaway clone. Each mutation failed the suite.
  - It raised 5 LOW findings and none blocks. The main ones: the dirty-tree check misses writes inside an already-untracked folder (`--untracked-files=all` would close it, but it doesn't affect the commit-then-demo flow); a stray `None: ` line in the section text exits 0; heading and fence matching is exact.
- `codex-review.sh`: **APPROVE**, with no substantive findings. Its read-only sandbox couldn't run the gate, the demo or the mutations, so the code-reviewer's runs are the only evidence for those.

Code-review verdict: APPROVE
Codex-review verdict: APPROVE
