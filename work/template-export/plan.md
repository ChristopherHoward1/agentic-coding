# Template export — a clean, capabilities-only template generated from this repo

**Slug:** template-export · **Date:** 2026-10-09 · **Status:** approved

## Goal

The Owner wants to reuse the harness in other repos for what it can do, without its history or the record of how it earned its autonomy. Today, a GitHub template made from this repo would also copy the dogfood state: every `work/` unit, the `PLAN.md` decisions and Now section, `CHANGELOG.md`, `VERSION`, an `ARCHI.md` that describes the framework, a `CLAUDE.md` TRIP line explaining how autonomy was earned, a hardcoded `agentic-coding` worktree dir, and the 66-second framework smoke suite inside every consumer gate.

Done means: `scripts/export-template.sh <dest>` writes a clean template tree from `HEAD`. That tree has full capabilities, full TRIP from day one, no history, and a gate that passes once it is `git init`ed. This repo stays the dogfood instance and the single source of truth, so re-running the export picks up framework fixes.

## Approach

**Generate the template; don't fork it.** A hand-made second repo would drift on its first framework fix. The export is a deterministic script, so the template is always "this repo at HEAD, minus the instance".

1. **Make the shared files history-free at the source, so they need no transformation:**
   - `CLAUDE.md`: replace the "Full TRIP autonomy: promoted 2026-08-25 after 4…" paragraph with a plain rule: the `/4-release` push, PR and tag run without an in-session Owner confirmation. The history already lives in `PLAN.md` Decisions and `work/trip-release`.
   - `config.yaml`: delete the `worktrees:` block. `worktree.sh:15` and `fan-exec.sh:116` already fall back to `../$(basename "$ROOT")-worktrees`, which from the primary checkout is `../agentic-coding-worktrees`, so dogfood behavior doesn't change there. (Run from inside a worktree, the fallback would resolve to `../<slug>-worktrees`. Today's skills call `add`/`remove` only from the primary checkout, so this is accepted.) Delete the block outright rather than commenting it out: both awk readers match any `dir:` line after `worktrees:`, so a commented `# dir:` would be parsed as the value.
2. **Exclude dogfood-only paths via `.gitattributes` `export-ignore`, which `git archive` already honors.** The list lives in one place, with no delete list in the script. Mark these paths:
   - `work/` and `template/`
   - `scripts/export-template.sh` and `tests/test-export.sh`
   - `scripts/gate.d/test-scripts.sh`: consumer gates stay fast, and the template's CI files still run the smoke suite
   - `.gitattributes` itself

   `knowledge/` ships whole. Its three docs are general guidance, and `tests/test-scripts.sh:53` cites one of them. Their `work/…` provenance links will dangle in a consumer; that's accepted.
3. **Add `template/` overlay files** with instance-specific skeletons:
   - `ARCHI.md` and `PLAN.md`: the placeholder skeletons from `3b80c19`, which `/init` already fills
   - `CHANGELOG.md`: header only, matching what `release.sh` keeps above the first `## `
   - `VERSION` = `1970.1.0`: valid for `valid_version`, and lower than any real CalVer, so the first `release.sh` bump passes `version_gt`. With no `work/.last-released`, `check_previous_retro` returns 0, so the first release isn't blocked.
4. **Add `scripts/export-template.sh <dest>`:**
   - Refuse with exit 1 and usage on wrong arg count. Refuse with exit 1 if `<dest>` exists and is non-empty, writing nothing.
   - Otherwise `git archive HEAD | tar -x -C <dest>`, so only committed, tracked, non-export-ignored content ships. Then overlay the `template/` files from `HEAD`: `git ls-tree -r --name-only HEAD -- template/`, then `git show HEAD:<path>` for each file into `<dest>/<path minus template/>`. Never copy them from the working tree. `template/` is itself export-ignored, so `git archive HEAD template` silently yields nothing. Print the dest path.
   - Exit 0 on success, 1 on refusal, 2 on tooling error.
5. **Test it against fixtures, never against the live repo's HEAD.** In `/2-implement`, the gate runs before anything is committed, so the live HEAD doesn't yet contain this unit.
   - Every case in `tests/test-export.sh` first builds a fixture repo: copy the current working tree's tracked and new files into `mktemp -d`, then `git init` and commit. It runs the export against that fixture, and against the result runs only the exported `scripts/gate.sh` (fast, because the hook is gone). The exported smoke suite runs only in this unit's Demonstration, so this repo's gate doesn't gain another 66s. Accepted risk: a later change that makes `tests/test-scripts.sh` depend on an export-ignored path would break consumer CI unnoticed. CI can't cheaply cover this, because the CI files ship to consumers that have no export script.
   - The HEAD-vs-working-tree case leaves uncommitted edits in the fixture (never the live checkout), in both a regular tracked file and `template/VERSION`. It asserts that the export has the committed content for both.
   - `scripts/gate.d/test-scripts.sh` also runs `tests/test-export.sh`, placed after the `TEST_SCRIPTS_RUNNING` guard so the nested gate inside `test-scripts.sh` doesn't run it a second time.
6. **Pin the worktree-dir fallback in `tests/test-scripts.sh`.** Every existing worktree fixture sets `worktrees: dir:` explicitly, so the fallback both repos now rely on is untested. Add one case: in a fixture whose `config.yaml` has no `worktrees:` block, `worktree.sh add x` creates the worktree at `../<basename>-worktrees/x`. It goes in the shipped suite because the template ships this behavior.
7. **Fold generic `PLAN.md` decisions into the skills and agents that act on them**, because a template `PLAN.md` starts empty. One terse rule line each, no dates or history.
   - **Rule:** fold a decision when it prescribes how a stage behaves in any repo using the harness, and no script, skill or agent states it today. Exclude framework-design rationale (no custom runtime, CalVer, gate/release-as-script: already in `CLAUDE.md` or enforced by scripts). Exclude rules already in a skill (ARCHI branch heal: `/3-review` step 7). Exclude dogfood-only rules (README sections release-note-owned). Exclude soft heuristics (plan-reviewer "drop marginal fix" is a cost signal).
   - Under that rule, fold these six:
     - `skills/3-review/SKILL.md`: for a CRITICAL/HIGH finding the orchestrator believes is wrong: analyze it on the merits, weigh the other reviewer's severity on the same behavior, escalate to the Owner, and override only with the analysis recorded in the plan's Review section.
     - `skills/1-plan/SKILL.md`: footprints name the canonical tracked path, never a `.claude/` symlink alias.
     - `skills/2-implement/SKILL.md`: `wt/<slug>` reaches `main` only through its `/4-release` PR. The primary checkout stays on a clean `main`.
     - `skills/2-implement/SKILL.md`: a handoff that cites a `PLAN.md` decision also names the `knowledge/` doc that says how to satisfy it.
     - `skills/4-release/SKILL.md`: after the release PR merges, delete the primary checkout's untracked `work/<slug>/` copies before `git pull --ff-only`, first checking each one against `origin/main`.
     - `skills/4-release/SKILL.md` step 1: drop "`Confirm-delta` is vestigial and" and keep only that it is logged as `none` (earning history).
     - `.claude/agents/code-reviewer.md`: a guard counts as pinned only when a mutation that removes it has been shown to fail the suite, and that mutation was verified to have landed.
   - The dogfood `PLAN.md` Decisions keep their lines. The decision is the record; the skill line is the rule.
8. **Targeted `ARCHI.md` branch refresh** covering:
   - the export script, `template/`, `.gitattributes`, and `tests/test-export.sh`
   - the `worktrees.dir` basename default
   - "run `scripts/export-template.sh <dest>` to produce a clean template". This note goes in `ARCHI.md` rather than README so the export never mentions a script it doesn't contain: the template's `ARCHI.md` is the skeleton.

Alternatives considered:
- A hand-forked template repo: drifts.
- Skills and agents as a Claude Code plugin plus a thin template: a better upgrade path, but much larger and premature. Revisit if re-exporting gets painful.
- A delete list inside the script: replaced by `export-ignore`.
- Keeping the smoke suite in the consumer gate: adds 66s to every gate run in every consumer.

Out of scope:
- Creating or pushing the GitHub template repo. That's an outward-facing step for after release, and needs Owner confirmation.
- Making `/5-retro` optional. It stays a capability.
- `release.sh` still requires `--confirm-delta` and writes `- Confirm-delta: none` into each consumer changelog entry. This residue is accepted: `release.sh` is untouched.

## Footprint

Files to modify:
- `scripts/export-template.sh` — new
- `.gitattributes` — new (export-ignore list)
- `template/ARCHI.md`, `template/PLAN.md`, `template/CHANGELOG.md`, `template/VERSION` — new
- `tests/test-export.sh` — new
- `tests/test-scripts.sh` — the one worktree-dir fallback case only
- `scripts/gate.d/test-scripts.sh` — also run `tests/test-export.sh`
- `CLAUDE.md` — TRIP paragraph made history-free
- `config.yaml` — `worktrees:` block removed
- `skills/1-plan/SKILL.md`, `skills/2-implement/SKILL.md`, `skills/3-review/SKILL.md`, `skills/4-release/SKILL.md`, `.claude/agents/code-reviewer.md` — the step-7 rule lines
- `ARCHI.md` — targeted branch refresh

Files NOT to touch:
- `scripts/release.sh`, `scripts/worktree.sh`, `scripts/fan-exec.sh`: the bootstrap and fallback paths already behave correctly. If one doesn't, stop and report it rather than changing it.
- `README.md`: it ships in the template, so it must not mention the export script.
- `.github/workflows/ci.yml`, `bitbucket-pipelines.yml`, `PLAN.md`, `knowledge/*`

## Acceptance criteria

- [ ] Exporting a working-tree fixture (`scripts/export-template.sh "$d"`) exits 0. The result contains no `work/`, `template/`, `.gitattributes`, `scripts/export-template.sh`, `tests/test-export.sh` or `scripts/gate.d/test-scripts.sh`. It does contain `tests/test-scripts.sh` and `knowledge/`.
- [ ] In the export, `VERSION` is `1970.1.0`, `CHANGELOG.md` has no `## [` entry, and `PLAN.md` / `ARCHI.md` are byte-identical to `template/PLAN.md` / `template/ARCHI.md`.
- [ ] `grep -rn "agentic-coding-worktrees\|promoted 2026\|Confirm-delta releases\|export-template" "$d"` finds nothing.
- [ ] After `git init && git add -A && git commit` in the export, `bash scripts/gate.sh` and `scripts/archi-fresh.sh` both exit 0 (asserted in `tests/test-export.sh`). `bash tests/test-scripts.sh` exits 0 there too (shown in the Demonstration).
- [ ] Refusals: a non-empty existing `<dest>` → exit 1 and nothing written; no args or extra args → exit 1 with usage. Each refusal is pinned by a case in `tests/test-export.sh`, and that case has been shown to fail when its guard is removed.
- [ ] The export reflects `HEAD`, not the working tree: uncommitted fixture edits to a tracked file and to `template/VERSION` are both absent from the export, which has the committed content (pinned by a test case).
- [ ] A new `tests/test-scripts.sh` case shows that, with no `worktrees:` block in `config.yaml`, `worktree.sh add x` creates `../<basename>-worktrees/x`. This repo's `config.yaml` has no `worktrees:` block.
- [ ] Each of the six step-7 rule lines is present in its named file, and `skills/4-release/SKILL.md` no longer contains `vestigial`. `CLAUDE.md` no longer contains `promoted 2026-08-25`.
- [ ] `bash scripts/gate.sh` passes in this repo (now including `tests/test-export.sh`). `scripts/archi-fresh.sh` exits 0 on the branch.

## Release

Release note: `scripts/export-template.sh <dest>` generates a clean, capabilities-only template from this repo. It has full TRIP, no work history, skeleton `PLAN.md`/`ARCHI.md`, and no framework smoke suite in the consumer gate. The generic `PLAN.md` decisions now live as rules in the skills and agents that apply them.

## Demonstration

```sh
d=$(mktemp -d)/tpl
scripts/export-template.sh "$d"
cd "$d" && git init -q && git add -A && git -c user.email=d@d -c user.name=d commit -qm init
ls -A; cat VERSION; cat CHANGELOG.md
test ! -e work && test ! -e template && echo "no instance dirs"
grep -c "promoted 2026" CLAUDE.md || true
grep -rn "agentic-coding-worktrees\|export-template" . --exclude-dir=.git || echo clean
bash scripts/gate.sh >/dev/null && echo GATE-OK
scripts/archi-fresh.sh && echo ARCHI-OK
bash tests/test-scripts.sh >/tmp/x 2>&1; echo "suite exit $?"; tail -1 /tmp/x
```
Expected:
- the top-level listing has no `work/`, `template/` or `.gitattributes`
- `VERSION` prints `1970.1.0`, and `CHANGELOG.md` prints its header with no release entries
- then, in order: `no instance dirs`, `0`, `clean`, `GATE-OK`, `ARCHI-OK`, `suite exit 0`, then `passed: <N>, failed: 0`

## Review

**Round 1 (plan-reviewer): REVISE.** All 7 findings were applied:
- fixture-based export tests instead of the live HEAD
- a worktree-dir fallback test in the shipped suite
- no export-script mention in the shipped README
- `knowledge/` ships whole
- an explicit fold rule, which adds two more decisions
- a stronger Demonstration
- `.gitattributes` `export-ignore` instead of a delete list

**Round 2 (fresh plan-reviewer): REVISE.** Findings 1–7 were applied:
- the overlay goes through `git ls-tree`/`git show HEAD:`
- the HEAD test also covers `template/VERSION`
- the exported-suite CI gap is recorded as an accepted risk instead of a CI step, because CI files ship to consumers that have no export script
- the `vestigial` wording is dropped from `/4-release`, and the `release.sh` Confirm-delta residue is accepted
- the hook placement goes after the guard
- the Demonstration uses a literal summary line and an exit code
- the worktree-fallback sentence is qualified

Disagreement on #8 (split step 7, the decision-folding, into its own unit): kept here. The folded rules are what make the exported template usable "for its capabilities", and a second loop run for six prose lines is process for its own sake. Owner to arbitrate.

Owner (2026-10-09): keep step 7 here; approved to implement.

Plan verdict: APPROVE
