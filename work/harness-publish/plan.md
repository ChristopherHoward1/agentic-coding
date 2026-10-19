# Harness publish — publish only `harness/` to the public template

**Slug:** harness-publish · **Date:** 2026-10-19 · **Status:** approved

## Goal

The public `agentic-coding-template` repo is still a copy of this repo with skeleton overlays: `scripts/export-template.sh` plus `template/`, published by `scripts/sync-template.sh`. Under the standalone-harness direction (PLAN.md Decision 2026-10-18), consumers clone it into their home directory, run `harness install`, and `harness register` their work repos. So the public repo should carry only the harness.

Done means:
- The public sync publishes exactly `harness/` + `README.md` + `LICENSE` from the tagged release commit.
- The export script, `.gitattributes` export rules and `tests/test-export.sh` are gone.
- The starting files `/init` builds from move from `template/` into the published tree as `harness/skeleton/`.
- `/init` copies any of those files that are missing into the project, and in repo mode writes the `CLAUDE.md` that loads the constitution.

Owner decisions (2026-10-19):
- The public repo holds `harness/` + README + LICENSE. No `template/` skeleton overlays, VERSION/CHANGELOG, `config.yaml` or CI at its root, and it is un-flagged as a GitHub template.
- The pre-push work-term denylist, originally part of this roadmap item, is dropped: the Owner won't push from work machines (see Review).

## Approach

1. **`scripts/publish.sh`** (new, dogfood-only) replaces `scripts/export-template.sh` and `scripts/sync-template.sh`. It takes no args. Exit 0 success or up to date, 1 refusal, 2 tooling error. Order:
   1. Usage check.
   2. Require that HEAD carries the literal tag `v<VERSION>` (same rule as today).
   3. Export `git archive HEAD -- harness README.md LICENSE` into `mktemp -d "${TMPDIR:-/tmp}/publish.XXXXXX"`, removed by trap. Never use a bare `mktemp -d`: `knowledge/silent-no-op-hazards.md` records that on macOS it misses a redirected `TMPDIR`.
   4. Clone `TEMPLATE_REPO` (env override kept, default `https://github.com/ChristopherHoward1/agentic-coding-template.git`) into `mktemp -d "${TMPDIR:-/tmp}/publish.XXXXXX"`, then switch to branch `template-sync/v<version>`.
   5. Replace the whole tree with the export, then either commit `Sync from agentic-coding v<version> (<sha>)` or print `up to date` and remove the clone.
   6. Print the clone path and branch. Never push.
2. **Delete and move.**
   - Delete `scripts/export-template.sh`, `scripts/sync-template.sh`, `tests/test-export.sh` and `.gitattributes`. Its rules are all `export-ignore`, dead under a path-limited archive.
   - `git mv` `template/{ARCHI.md,PLAN.md,CHANGELOG.md,VERSION}` to `harness/skeleton/`.
   - Add `harness/skeleton/config.yaml`: a copy of root `config.yaml` with `gate.required_tools` emptied and `archi.sources` replaced by a commented example. Everything else stays the same.
3. **`/init`** (`harness/skills/init/SKILL.md`).
   - Step 0 gains two lines:
     - Copy each of `config.yaml`, `ARCHI.md` and `PLAN.md` from `$(harness root)/skeleton/` into `$(harness project)` when it is missing there. In repo mode only, also copy `VERSION` and `CHANGELOG.md`. Never overwrite.
     - In repo mode only, make the project root's `CLAUDE.md` import the hot tier, mirroring what `register` writes for registry mode. The import lines are `@<harness root>/CONSTITUTION.md`, `@ARCHI.md` and `@PLAN.md`. `<harness root>` is the root `harness root` prints, written as `~/…` when it is under `$HOME`, because the file is committed and an absolute `/Users/…` path breaks on other machines.
       - If `CLAUDE.md` is absent, write it with those three lines.
       - If it exists, append only the import lines it lacks. Any existing `@…/CONSTITUTION.md` line counts as the constitution import, whatever its path. Never rewrite or delete existing content.
   - The frontmatter's "or on a freshly cloned template" becomes "or after `harness register`".
4. **Tests.** `tests/test-publish.sh` (new, dogfood) ports `test-export.sh`'s `sync_*` cases to `publish.sh`. It also adds one consumer case, replacing `test-export.sh`'s `success` case:
   1. `git init` a fresh project repo.
   2. Copy in `harness/skeleton/{config.yaml,ARCHI.md,PLAN.md}` from the published clone, plus a `CLAUDE.md`, and commit.
   3. Run the published clone's `harness/bin/harness gate` and `harness archi-fresh` in that project, with `HARNESS_HOME` isolated and `GATE_REQUIRED_TOOLS` unset. Both must exit 0. `scripts/gate.d/test-scripts.sh` runs it in place of `test-export.sh`. Fixtures set `TMPDIR` under the test tmp dir, point `TEMPLATE_REPO` at a local bare repo whose default branch is `main`, and export `GIT_AUTHOR_*`/`GIT_COMMITTER_*`.
5. **`/4-release`** (`harness/skills/4-release/SKILL.md`).
   - Step 3: "README ships in exported templates" becomes "README is published".
   - Step 5:
     - `scripts/sync-template.sh` becomes `scripts/publish.sh`.
     - The public repo has no CI after this unit, so merge the sync PR with `gh pr merge --rebase` once it is open.
     - Drop the "red template CI" branch.
6. **README.md** (it is published).
   - Getting started becomes the clone-to-home flow:
     1. Clone the template into the home directory.
     2. Run `<clone>/harness/bin/harness install`.
     3. In a work repo, run `harness register [--subdir <path>]`, then `/init`.
     4. For a personal repo in repo mode, run `/init` directly.
   - Layout is split into two parts:
     - **"This repo (`harness/`)"**: what is published, with `harness/skeleton/` added.
     - **"Per-project state"**, at the project root in repo mode or in the registry state dir:
       - `CLAUDE.md`/`CLAUDE.local.md`: from `register`, or from `/init` in repo mode.
       - `ARCHI.md`, `PLAN.md`, `config.yaml` and, in repo mode, `VERSION`/`CHANGELOG`: from `/init`'s copy of `harness/skeleton/`.
       - `work/` and `knowledge/`: from `register`, or created by the loop.
       - `scripts/gate.d/`: optional, added by hand.
   - README never names dogfood-only scripts (`publish.sh`).
7. **ARCHI.md**, as a targeted edit on the branch:
   - Drop the export/sync/`template/`/`test-export` descriptions and the `scripts/export-template.sh` entry point.
   - Add `scripts/publish.sh`, `tests/test-publish.sh`, `harness/skeleton/` and `/init`'s skeleton copy.
   - Change "README ships in exported templates" to "README is published".
   - Fix three lines that become false but that the grep check can't see:
     - the CI line "work repos delete it during `/init`": consumers never receive `ci.yml` now;
     - Key flows' "merges on green CI": the sync PR merges with `--rebase` without CI;
     - the closing paragraph's "Root `scripts/` retains the export/sync tools": it now retains `publish.sh` and the gate hooks;
     - the `scripts/` line's "`test-scripts.sh` wires the smoke and export suites in": it becomes "the smoke and publish suites".

## Footprint

Files to add:
- `scripts/publish.sh`
- `tests/test-publish.sh`
- `harness/skeleton/config.yaml`

Files to modify:
- `harness/skills/init/SKILL.md` (frontmatter description + step 0 only)
- `harness/skills/4-release/SKILL.md` (step 3's README wording and step 5 only)
- `scripts/gate.d/test-scripts.sh`
- `README.md` (Getting started + Layout only)
- `ARCHI.md`

Files to move (`git mv`, content unchanged):
- `template/{ARCHI.md,PLAN.md,CHANGELOG.md,VERSION}` → `harness/skeleton/`

Files to delete:
- `scripts/export-template.sh`, `scripts/sync-template.sh`, `tests/test-export.sh`, `.gitattributes`

Files NOT to touch:
- `.github/workflows/ci.yml`: this repo keeps its CI (Decision 2026-10-18), and the gate it runs reaches `tests/test-publish.sh` through `gate.d`.
- `PLAN.md`, `VERSION`, `CHANGELOG.md`: the orchestrator and `release.sh` own these. Before `/3-review`, the orchestrator commits the `PLAN.md` edit to `wt/harness-publish` (never `main`, per Decision 2026-09-08): the roadmap entry loses "pre-push work-term denylist", and a one-line 2026-10-19 Decision records the dropped denylist.
- `harness/scripts/`, `harness/tests/test-scripts.sh`, `harness/bin/harness`: no harness script changes in this unit.

## Acceptance criteria

- [ ] `harness gate` passes, with `tests/test-publish.sh` running under it.
- [ ] `git grep -E -e export-template -e sync-template -e test-export -e '(^|[^-])template/' -- ':!work/' ':!CHANGELOG.md' ':!PLAN.md' ':!tests/test-publish.sh'` prints nothing.
- [ ] **publish:**
  - The published commit's tree is exactly `git ls-tree -r HEAD -- harness README.md LICENSE`, and no `work/`, `ARCHI.md`, `PLAN.md`, `config.yaml`, `VERSION`, `CHANGELOG.md`, `.github/` or `template/` path exists at its root.
  - The published tree contains `harness/skeleton/{config.yaml,ARCHI.md,PLAN.md,CHANGELOG.md,VERSION}`. `harness/skeleton/config.yaml` has no non-comment `archi.sources` value and an empty `required_tools`.
  - The template repo's prior history is kept as the parent.
  - Nothing is pushed. The clone path and branch are printed, and the clone is the only entry left under `TMPDIR`.
  - Uncommitted working-tree changes are not published.
  - When nothing changed: prints `up to date`, and `TMPDIR` is empty after exit.
  - A missing or near-match tag → exit 1, and `TMPDIR` is empty after exit.
  - Arguments → exit 1.
  - **Consumer case:** a fresh project seeded from the published `harness/skeleton/` passes the published harness's `gate` and `archi-fresh`.
- [ ] Each new guard fails its test when mutated, with the mutation verified to have landed (`knowledge/silent-no-op-hazards.md`). The guards are:
  - the path-limited archive (mutated to a full-HEAD archive);
  - the tag check;
  - the export temp dir's removal.
  Evidence goes in `work/harness-publish/notes.md`, one line per guard: the mutation, its landing check, the name of the test that failed, and the platform it ran on. The export-temp-dir removal mutation must be run on macOS by the orchestrator or reviewer, not taken from the implementer sandbox: `knowledge/silent-no-op-hazards.md` records a cleanup mutation that the sandbox wrongly reported as failing.
- [ ] `/init` step 0 names:
  - the skeleton copy: missing-only, never overwriting, with `VERSION`/`CHANGELOG.md` in repo mode only;
  - the repo-mode `CLAUDE.md` imports (`@~/…`-relative constitution, `@ARCHI.md`, `@PLAN.md`) in both branches: absent → write, present → append only the missing lines.
- [ ] README Getting started describes the clone → install → register → `/init` flow, Layout is split as in Approach step 6, and README names no dogfood-only script.
- [ ] `/4-release` step 5 names `scripts/publish.sh` and has no CI-wait branch. Step 3 says README is published.

## Release

Release note: The public template now publishes only `harness/`, README and LICENSE. `scripts/publish.sh` replaces the template export, the skeletons move to `harness/skeleton/`, and `/init` copies them into a project.

One-time steps in this unit's `/4-release`:
- `/4-release` loads its skill text before the pull. So after step 5's `git pull`, the orchestrator follows the **new** step 5: run `bash scripts/publish.sh` (`sync-template.sh` is gone), and merge the sync PR with `gh pr merge --rebase` without waiting for CI. The sync deletes the template's `.github/`, and its ruleset requires no status checks.
- After the sync PR merges, run `gh repo edit ChristopherHoward1/agentic-coding-template --template=false`.

## Demonstration

```sh
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT; export TMPDIR="$d/tmp"; mkdir -p "$TMPDIR"
export GIT_AUTHOR_NAME=Demo GIT_AUTHOR_EMAIL=demo@example.com GIT_COMMITTER_NAME=Demo GIT_COMMITTER_EMAIL=demo@example.com
c="$d/clone"
git clone -q . "$c" || exit 1
git init -q --bare --initial-branch=main "$d/public.git" || exit 1
git -C "$c" push -q "$d/public.git" HEAD~1:refs/heads/main || exit 1
printf '2099.1.0\n' >"$c/VERSION" && git -C "$c" commit -qam 'demo version' && git -C "$c" tag v2099.1.0 || exit 1
(cd "$c" && TEMPLATE_REPO="$d/public.git" bash scripts/publish.sh) >"$d/out" || exit 1
out=$(sed -n 1p "$d/out"); [ -d "$out" ] || exit 1
git -C "$out" ls-tree --name-only HEAD
git -C "$out" ls-tree --name-only HEAD harness/skeleton/
[ "$(git -C "$out" rev-parse HEAD~1)" = "$(git -C "$d/public.git" rev-parse main)" ] || exit 1; echo "published on top of remote history"
[ "$(ls "$TMPDIR" | wc -l | tr -d ' ')" = 1 ] || exit 1; echo "only the clone left in TMPDIR"
```
Expected output, in order:
1. The top-level entries, exactly `LICENSE`, `README.md`, `harness`.
2. The five paths `harness/skeleton/{ARCHI.md,CHANGELOG.md,PLAN.md,VERSION,config.yaml}`.
3. `published on top of remote history`.
4. `only the clone left in TMPDIR`.

## Review

**Earlier scope.** Plan-review rounds 1–4 covered an earlier version that also had a pre-push work-term denylist (`harness denylist` plus a hook wired by `harness install`). Rounds 1–3 came back REVISE, with 9, 5 and 7 findings, and round 4 approved it. The publish, skeleton, `/init`, README and release findings from those rounds are carried into this version.

**Denylist dropped.** On 2026-10-19 the Owner dropped the denylist, because they won't push harness changes from work machines. Work friction gets documented there and fixed in this repo. Design lessons, kept in case it comes back:
- **Hook location:** `core.hooksPath` set outside the repo would make the hook machine-wide.
- **What to scan:** the author/committer email is the likeliest leak, and ref names need scanning too.
- **Diff scanning:** scan messages separately from diffs, take file names from `--name-only --diff-filter=d`, and keep only `+` lines.
- **Hook ownership:** decide it by a marker line, not by matching content byte for byte.

This reduced scope needs a fresh plan-review round.

Round 5 (plan-reviewer, reduced scope): REVISE, 5 findings, all applied.
1. **Repo-mode `CLAUDE.md`.** In repo mode `/init` writes, or appends to, `CLAUDE.md` the constitution, `ARCHI.md` and `PLAN.md` imports, with a `~/`-relative root.
2. **macOS mutation run.** The cleanup mutation must run on macOS, and `notes.md` records the platform.
3. **Stale ARCHI lines.** The three stale ARCHI lines are now listed in step 7.
4. **`PLAN.md` edit.** The roadmap and Decision edit has an owner (the orchestrator) and a location (the branch).
5. **Demo false pass.** The demo now guards against an empty `out`.

Reviewer's simpler-version check: nothing to cut.

Round 6 (plan-reviewer): APPROVE. It listed 3 non-blocking findings, all applied without a further round:
1. **Consumer case.** One test runs the published gate and `archi-fresh` on a project seeded from the skeleton.
2. **ARCHI `scripts/` line.** The "export suites" wording is added to step 7's list.
3. **Constitution import.** Any existing `@…/CONSTITUTION.md` line counts as the import.

Plan verdict: APPROVE
