# Harness split — move the framework under `harness/`, reached through one location-independent command

**Slug:** harness-split · **Date:** 2026-10-18 · **Status:** approved

## Goal

The Owner wants the framework to become a standalone harness. It should be cloned once from the public `agentic-coding-template` repo into the Owner's home, and leave nothing in work repos (Owner decisions 2026-10-17/18).

Today that's impossible. Framework and instance files share one root, and every skill, agent, template and test names framework scripts by repo-relative paths (`scripts/gate.sh` and similar).

This unit is the first slice: a relocation that separates **where the harness lives** from **which repo it acts on**. Done means:
- every framework file lives under `harness/`
- every skill and agent reaches a script through a `harness <command>` dispatcher that resolves its own location
- this repo still dogfoods the full loop, with the gate green

The Owner's requirements are split into units:
- **This unit:** relocation and the separation of harness root from git root (requirements 1 and 3a).
- **`harness-install`** (requirements 2, 3b and 4):
  - links into `~/.claude/`
  - registers each repo under `~/.harness/projects/<repo>/`, with its config and unit artifacts
  - lets the project root be a subfolder of the git root
  - makes ARCHI sources config-driven
  - moves `AGENTS.md` into `harness/` and sends it with the handoff
  - records the local gate result against the commit SHA
  - drops committed CI files and the bootstrap forwarders added here
- **`harness-publish`** (requirements 6 and 7): the public sync publishes only `harness/`, replacing `export-template.sh`, `sync-template.sh`, `template/` and `test-export.sh`. It also adds the pre-push denylist guard.
- **`forge: none`** (requirement 5) goes with the later `pr-release` unit, since both define the forge abstraction.

## Approach

1. **Move with `git mv`.** Framework files go under `harness/`; instance files stay at root.

   | From | To |
   |---|---|
   | `scripts/{gate,worktree,agent-exec,fan-exec,codex-review,demo,release,state,archi-fresh}.sh` | `harness/scripts/` |
   | `scripts/gate.d/examples/*.sh` | `harness/examples/gate.d/` |
   | `skills/` | `harness/skills/` |
   | `.claude/agents/*.md` | `harness/agents/` |
   | `profiles/` | `harness/profiles/` |
   | `tests/test-scripts.sh` | `harness/tests/test-scripts.sh` |
   | `CLAUDE.md` body | `harness/CONSTITUTION.md` |

   - Root `CLAUDE.md` becomes the single line `@harness/CONSTITUTION.md`.
   - These stay at root:
     - **Dogfood-only:** `scripts/export-template.sh`, `scripts/sync-template.sh`, `scripts/gate.d/test-scripts.sh`, `scripts/gate.d/.gitkeep`, `tests/test-export.sh` and `template/`.
     - **Instance files:** `ARCHI.md`, `PLAN.md`, `config.yaml`, `VERSION`, `CHANGELOG.md`, `knowledge/`, `work/`, `README.md`, `LICENSE`, `.github/`, `bitbucket-pipelines.yml` and `.gitattributes`.
     - **`AGENTS.md`**, unchanged. It moves in `harness-install`, where it first matters (plan-reviewer round 2, finding 7). Until then, its `scripts/gate.sh` references reach the bootstrap forwarder.
     - The three bootstrap forwarders (step 8).
   - Symlinks: retarget `.claude/skills → ../harness/skills`. Replace the `.claude/agents` directory with the symlink `.claude/agents → ../harness/agents`.
2. **`harness/bin/harness` dispatcher** (new, bash 3.2-safe, shellchecked):
   - It resolves its own real path through any chain of symlinks with a `readlink` loop; macOS has no `readlink -f`. Its root is the parent of `bin/`.
   - `harness root` prints that root.
   - `harness <name> [args]` first rejects any name not matching `^[a-z-]+$`. It then runs `exec bash "$root/scripts/<name>.sh" "$@"` if that file exists.
   - No arguments, a rejected name, or an unknown name prints usage, listing the available names, to stderr and exits 2.
3. **Two locations inside the scripts.**
   - Each script that calls a sibling first sets `HERE=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)`, **before any `cd`** (`release.sh:5` and `fan-exec.sh:9` both `cd`). It then calls `"$HERE/<sibling>.sh"`.
   - That covers `release.sh` (gate at `:115`, archi-fresh at `:119`) and `fan-exec.sh` (worktree at `:70` and `:113`, agent-exec at `:73`, gate at `:79`).
   - Project-side paths stay relative to the git toplevel, unchanged: `config.yaml`, `work/`, `VERSION` and the project gate hooks in `scripts/gate.d/*.sh`.
   - Usage strings and `state.sh`'s `next_action` change to `harness <name>` forms.
4. **ARCHI sources.** `archi-fresh.sh:7` becomes `SOURCE_PATHS=(harness/ scripts/ config.yaml CLAUDE.md)`. That's the same coverage under the new layout: root `scripts/` stays watched for the export/sync scripts and `gate.d`. Config-driven sources come in `harness-install`.
5. **Rewrite references.**
   - Skills, agents, the constitution, profiles and the handoff/followup templates replace every `scripts/<framework>.sh` with `harness <name>`, for example `harness worktree add <slug>`, `harness demo <slug>` and `harness release tag-after-merge <slug>`. They also replace every `tests/test-scripts.sh` with `harness/tests/test-scripts.sh`; `profiles/work.md:65` is one.
   - Example-hook references in profiles become `$(harness root)/examples/gate.d/<hook>.sh`.
   - `config.yaml → profiles/` becomes `$(harness root)/profiles/`.
   - `config.yaml`'s `gate.command` becomes `harness gate`.
   - The `5-retro` file boundary ("edit `scripts/` or `gate.d/`", `skills/5-retro/SKILL.md:25`) becomes `harness/` plus root `scripts/gate.d/`.
   - Skill-local `prompts/*.tpl` references stay relative to the skill directory.
   - `skills/4-release` keeps `scripts/sync-template.sh` as a repo-root path, because it's dogfood-only.
6. **Tests.** Changes to `harness/tests/test-scripts.sh`:
   - **Source paths:** `$ROOT/scripts/X` becomes `$ROOT/harness/scripts/X`, and likewise for examples, skills and agents. `ROOT` is the git toplevel, so these resolve after the move. Fixture repos keep their internal `scripts/` layout, so `HERE`-relative sibling calls resolve as they do today.
   - **Bare cwd-relative paths:** the file `cd "$ROOT"`s at `:48`, so some top-level checks use bare paths, and these must be rewritten to `harness/…` too:
     - `:942-947` and `:953-955` (`scripts/codex-review.sh`)
     - `:948` and `:956-959` (`skills/3-review/SKILL.md`)
     - `:1459` (`check_fails … bash scripts/agent-exec.sh …`)
     - `:1738-1739` (`bash scripts/release.sh check-version …`)

     The `check_fails` cases at `:1459` and `:1739` would otherwise pass without testing anything, because a missing file exits 127. The `.claude/agents/code-reviewer.md` checks (`:949-952`) still resolve through the symlink.
   - **ARCHI-fresh fixture:** `setup_archi_fresh_fixture` (`:183-215`) makes its edit in `harness/skills/fixture.md` instead of `skills/fixture.md`.
   - **Five assertions** follow the new strings:
     - `:829`: `Usage: harness demo`
     - `:838` and `:846`: stderr names `harness/`
     - `:853`: `Usage: harness archi-fresh`
     - `:883`: `next_action: run harness gate`

     The `release-archi-stale` fixture (`:155`, which edits `CLAUDE.md`) is unaffected.
   - **Shellcheck coverage:** the explicit shellcheck line (`:730`) becomes `shellcheck harness/scripts/*.sh harness/tests/*.sh harness/bin/harness`. `gate.sh:112` only checks `*.sh`, so this line is what covers the extensionless dispatcher.
   - **Self-gate:** `:2023` (`gate.sh runs on this repo`) runs `bash "$ROOT/harness/bin/harness" gate`, so it survives the deletion of the forwarders.
   - **New cases:**
     - (a) The dispatcher through a two-link symlink chain, one absolute link and one relative (`ln -s link1 "$d/bin/harness"`), run from a directory outside any repo: `harness root` prints the real harness path, and `harness demo --help` prints `Usage: harness demo <slug> [<dir>]`.
     - (b) No arguments, an unknown name, and `harness ../x` each exit 2 with usage on stderr.

   Other test files:
   - Root `scripts/gate.d/test-scripts.sh` runs `harness/tests/test-scripts.sh` and `tests/test-export.sh`.
   - `tests/test-export.sh` updates its expected paths (e.g. `$dest/harness/tests/test-scripts.sh`). It runs the exported dispatcher by path at `:55`: `bash "$dest/harness/bin/harness" gate` and `… archi-fresh`. Its `:52` check that no exported file contains `export-template` still holds, so the README rewrite must not name the export script.
7. **CI and docs.**
   - `.github/workflows/ci.yml` and `bitbucket-pipelines.yml` run `bash harness/tests/test-scripts.sh` and `bash harness/bin/harness gate`.
   - `.gitattributes` export-ignore paths don't change.
   - Refresh README Layout and Getting started, and make a targeted `ARCHI.md` refresh on the branch.
   - `knowledge/release-script-binding.md` gains a section on the binding shift (step 9).
8. **Bootstrap.** Main's loop machinery, which uses the old paths, drives this unit.
   - Keep `scripts/gate.sh`, `scripts/archi-fresh.sh` and `scripts/demo.sh` at root as two-line forwarders: `exec bash "$(dirname "$0")/../harness/scripts/<name>.sh" "$@"`. These keep three callers working on this branch:
     - main's `/2-implement` (`cd "$WT" && scripts/gate.sh`)
     - main's `release.sh` (`:115` and `:119`, which run inside the release worktree)
     - main's code-reviewer and handoff/followup templates (`scripts/demo.sh <slug>`)

     `harness-install` deletes the forwarders.
   - Before merge, the orchestrator confirms agent discovery through the symlinked directory. From `$WT`, a fresh `claude -p` session lists its available subagents, and the output goes in `work/harness-split/notes.md`. If any reviewer agent is missing, the branch switches to per-file symlinks (`.claude/agents/<name>.md → ../../harness/agents/<name>.md`) before review.
   - After merge, in `/4-release`, `tag-after-merge` runs in its usual place: step 4, before the pull, where the primary still has the old `scripts/release.sh`. After the pull, and before the sync-template step and `/5-retro`, run a one-time `ln -sf "$PWD/harness/bin/harness" ~/.local/bin/harness`.
   - This release's template sync publishes the new layout, so README Getting started gains the same one-line `ln -s` install step. That way a consumer's `/init` finds `harness`. The README still never names the export script.
9. **Accepted binding shift.**
   - **Today:** the branch's own `gate.sh`, `archi-fresh.sh` and `demo.sh` run against the branch, through `cd "$WT" && scripts/gate.sh`, `fan-exec.sh:79`, release's checks, and the reviewer's demo re-run.
   - **After this unit:** the global `harness` and `$HERE` run the **installed (main) copies** against the branch tree. That's the intended harness model, since work repos can only ever run the installed harness.
   - **Coverage stays:** the branch's scripts are still exercised, because the gate hook runs the branch's `harness/tests/test-scripts.sh` against the branch's script copies through `$ROOT`.
   - This is recorded in `knowledge/release-script-binding.md`.

Alternatives considered:
- **Repo-relative `harness/scripts/…` in skills:** only works inside this repo, so `harness-install` would rewrite every reference again.
- **Harness root from the skill's base directory:** Claude Code reports the symlink path (`.claude/skills/<name>`), so going two levels up lands in `.claude/`.
- **A SessionStart hook exporting `HARNESS_ROOT`:** wouldn't reach the headless implementer, and it's unverified.
- **Config-driven `archi.sources`, and moving `AGENTS.md`, now:** deferred to `harness-install` (plan-reviewer findings: round 1 #5, round 2 #7). No consumer repo exists until then, and both add test churn here.

Out of scope: everything Goal assigns to later units. Also out of scope: moving `knowledge/`, and any script behavior change beyond the sibling lookup and the `SOURCE_PATHS` list.

## Footprint

Files to modify:
- `harness/**`: all moved files in Approach 1, the new `harness/bin/harness`, and the reference rewrites inside them
- `scripts/gate.sh`, `scripts/archi-fresh.sh`, `scripts/demo.sh`: become bootstrap forwarders
- `scripts/gate.d/test-scripts.sh` and `tests/test-export.sh`
- `CLAUDE.md` (the import line) and `config.yaml` (`gate.command`)
- `.claude/skills` and `.claude/agents` (symlinks, or the per-file fallback in Approach 8)
- `.github/workflows/ci.yml` and `bitbucket-pipelines.yml`
- `README.md`, `ARCHI.md` and `knowledge/release-script-binding.md`

Files NOT to touch:
- `scripts/export-template.sh`, `scripts/sync-template.sh` and `template/`. `harness-publish` replaces them. If the export breaks under the new layout beyond the expected-path updates in `tests/test-export.sh`, stop and report.
- `AGENTS.md`: it moves in `harness-install`.
- Other `knowledge/**` files, and `work/**` outside this unit's directory.
- `.claude/settings.local.json`.

## Acceptance criteria

- [ ] `bash harness/bin/harness gate` exits 0 from the worktree root and from `harness/scripts/`. The test output shows new cases (a) and (b) as `ok`. `shellcheck harness/bin/harness` exits 0.
- [ ] At root, `git ls-files scripts tests` lists exactly eight files:
  - `scripts/archi-fresh.sh`, `scripts/demo.sh` and `scripts/gate.sh` (the forwarders)
  - `scripts/export-template.sh` and `scripts/sync-template.sh`
  - `scripts/gate.d/.gitkeep` and `scripts/gate.d/test-scripts.sh`
  - `tests/test-export.sh`

  `git log --follow --oneline` shows pre-move history for `harness/scripts/release.sh`, `harness/skills/3-review/SKILL.md` and `harness/agents/code-reviewer.md`.
- [ ] All of these print nothing:
  - `grep -rnE '(^|[^/a-z])scripts/(gate|worktree|agent-exec|fan-exec|codex-review|demo|release|state|archi-fresh)\.sh' harness/skills harness/agents harness/profiles harness/scripts harness/CONSTITUTION.md CLAUDE.md config.yaml README.md`
  - `grep -rnE '(^|[^/])tests/test-scripts\.sh' harness/skills harness/agents harness/profiles harness/CONSTITUTION.md README.md`
  - `grep -rnE 'scripts/gate\.d/examples/|(^|[^/a-z)])profiles/' harness/skills harness/agents harness/profiles harness/scripts harness/CONSTITUTION.md CLAUDE.md`
  - `grep -nE '^check(_fails|_exit)? .*[ ](scripts/[a-z-]+\.sh|skills/)' harness/tests/test-scripts.sh | grep -v "cd '"`
- [ ] `grep -F 'harness/bin/harness' README.md` matches (the Getting started install step).
- [ ] `readlink .claude/skills` prints `../harness/skills`. `.claude/agents` is either the symlink `../harness/agents` or the per-file fallback. `ls -L .claude/agents/` lists the three agent files. `work/harness-split/notes.md` records a fresh `claude -p` session from `$WT` listing `plan-reviewer`, `code-reviewer` and `fan-selector`.
- [ ] Root `CLAUDE.md` is the single line `@harness/CONSTITUTION.md`. `git diff main:CLAUDE.md HEAD:harness/CONSTITUTION.md` shows only the script-reference rewrites.
- [ ] Inside the worktree:
  - `scripts/gate.sh`, executed directly, forwards and exits 0
  - `scripts/archi-fresh.sh HEAD` forwards with the same exit as `bash harness/bin/harness archi-fresh HEAD`
  - `scripts/demo.sh --help`, executed directly, prints the `harness demo` usage
  - `git ls-files -s scripts/gate.sh scripts/demo.sh scripts/archi-fresh.sh harness/bin/harness` shows mode `100755` for all four
- [ ] Every new guard is pinned. Each of these mutations, verified as landed, fails a named case, recorded in `work/harness-split/mutations.md`:
  - removing the dispatcher's symlink loop (fails a)
  - making an unknown name exit 0 (fails b)
  - removing the `^[a-z-]+$` name check (fails b, via `../x`)
- [ ] The existing export cases pass with the updated expected paths. The exported copy's `harness gate`, run by path, passes inside `tests/test-export.sh`.

## Release

Release note: The framework moves under `harness/`, and skills and agents reach its scripts through the `harness` command.

Binding note (`knowledge/release-script-binding.md`): this unit is released by main's pre-move `release.sh`, through the bootstrap forwarders. From the next unit onward, `harness release` runs the installed copy.

## Demonstration

This runs the branch's real dispatcher through a symlink chain outside the repo:
- it gates an unrelated fresh repo, which shows the harness root and target repo are separate
- it reads this repo's real unit state
- it checks ARCHI freshness

It writes only under `mktemp -d`.

```sh
d=$(mktemp -d); mkdir "$d/bin"
ln -s "$PWD/harness/bin/harness" "$d/bin/link1"; ln -s "$d/bin/link1" "$d/bin/harness"
export PATH="$d/bin:$PATH"
echo "root=$(harness root)"
git init -q "$d/proj"; printf '#!/usr/bin/env bash\necho hi\n' > "$d/proj/a.sh"
git -C "$d/proj" add a.sh; git -C "$d/proj" -c user.name=d -c user.email=d@d commit -qm init
(cd "$d/proj" && harness gate) > "$d/gate.log"; echo "gate_exit=$?"
grep -F '▶ shellcheck' "$d/gate.log"; tail -1 "$d/gate.log"
harness state template-sync
harness archi-fresh; echo "archi_exit=$?"
harness ../x 2>/dev/null; echo "traversal_exit=$?"
```

Expected:
- `root=` prints this worktree's `harness` directory as a real path.
- `gate_exit=0`, then `▶ shellcheck a.sh`, then `GATE: PASS`.
- The state lines `slug: template-sync` / `stage: plan` / `review: approve` / `next_action: finish /1-plan`, the same as on main today (the known `state-owner-approval` candidate).
- `archi_exit=0`.
- `traversal_exit=2`.

## Review

Plan-reviewer round 1: REVISE (11 findings), all applied. The main changes:
- Bootstrap forwarders and post-merge steps.
- Explicit test churn.
- A scoped grep.
- The binding shift is accepted and recorded.
- `archi.sources` is deferred.
- The export runs the exported dispatcher.
- An agent-discovery check.
- A fuller demo.
- `HERE` is set before the `cd`.
- Named case (a) and the history samples.

Plan-reviewer round 2: REVISE (8 findings), all applied:
1. The demo commits in `proj` (`agent-exec`'s `rev-parse HEAD` dies on an empty repo; that dispatch step is gone now anyway), and it shows the shellcheck line.
2. Added a `scripts/demo.sh` forwarder, so the root has 8 files.
3. ARCHI-fresh fixture churn: the edit moves to `harness/skills/fixture.md`, `:838` and `:846` expect `harness/` (five assertion updates), and `release-archi-stale` is unaffected.
4. The dispatcher is shellchecked via `:730`, and the self-gate at `:2023` uses the dispatcher.
5. The agent-discovery check is now before merge, with the per-file fallback in the footprint.
6. A second grep for `tests/test-scripts.sh`, and the `5-retro` boundary rewrite.
7. Took the simpler version: `AGENTS.md` and the contract piping are deferred to `harness-install`, which drops case (c), the fixture stubs and the special follow-up dispatch.
8. Fixed the `:52` reference, removed the follow-up piping wording, and added the dispatcher name check plus `../x` to case (b).

No disagreements.

Plan-reviewer round 3: REVISE (6 findings), all applied:
1. Bare cwd-relative test paths (`:942-959`, `:1459`, `:1738-1739`) are listed, so the two `check_fails` cases can't pass without testing anything, and a grep criterion pins it.
2. README Getting started gains the `ln -s` install step, because this release's sync publishes the new layout.
3. The forwarders are executed directly, and the 100755 modes are checked.
4. `tag-after-merge` keeps its usual step-4 place. Only the post-pull `ln -sf` is added.
5. `gate.d/examples/` and `profiles/` references are added to the grep.
6. Case (a) uses one relative symlink.

No disagreements. Round 3 is the cap; this goes to the Owner.

Owner approval: 2026-10-18, approved as-is with the round-3 fixes applied. The Owner made no separate call on skipping the sync, so this release's template sync runs as normal.

Plan verdict: APPROVE
