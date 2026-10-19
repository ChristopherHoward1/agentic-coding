# Harness registry — a work repo's harness state lives in the home directory, and nothing harness-related is committed

**Slug:** harness-registry · **Date:** 2026-10-19 · **Status:** implemented

## Goal

The 2026-10-18 Decision says work repos carry **zero harness footprint**. After `harness-install`, the dispatcher, skills and agents already come from the home directory. But every script still reads the project's harness state from the git toplevel: `config.yaml`, `ARCHI.md`, `PLAN.md`, `work/<slug>/`, `scripts/gate.d/` and `knowledge/`. The constitution also loads only through a committed `CLAUDE.md`. So today, adopting the harness in a work repo means committing all of that.

The field report adds a second gap: the project is sometimes a subfolder of the git repo.

Done means:
- `harness register [--subdir <path>]`, run once from a work repo's primary checkout, creates `~/.harness/projects/<name>/` as that project's **state dir**.
- Every script resolves state the same way:
  - **Registry mode:** the repo's primary checkout is registered, so state comes from the state dir.
  - **Repo mode:** no registry entry, so state comes from the git toplevel, exactly as today.
- In registry mode:
  - The gate, the implementer, the demo and ARCHI freshness all act on the **project root**, `<checkout>/<subdir>`.
  - The constitution loads through an untracked `CLAUDE.local.md` that is listed in `.git/info/exclude`.
  - `git status` in the work repo stays empty.
- This repo stays in repo mode, and every existing test keeps passing.

## Approach

### 1. Resolution: `harness/scripts/lib/project.sh` (new, sourced)

It lives in `lib/` because the dispatcher globs only `scripts/*.sh`, so `lib/` never becomes a command. It defines `resolve_project`, which sets:

- `GIT_ROOT`: `git rev-parse --show-toplevel`. This is the current checkout and may be a linked worktree.
- `PRIMARY_ROOT`: the first `worktree` entry of `git worktree list --porcelain`. It only asks git (ARCHI convention), so a script run inside a linked worktree finds the same registry entry.
- `HARNESS_HOME`: `${HARNESS_HOME:-$HOME/.harness}`.
- **Lookup.** Read each `$HARNESS_HOME/projects/*/project`. Each file has `root=<abs path>` and `subdir=<rel path or empty>` lines, read with `while read`, never sourced. An entry matches when its `root` equals `PRIMARY_ROOT` after `cd -P … && pwd`.
  - An entry is **skipped**, not treated as an error, when its file is malformed (no `root=` line) or its `root` no longer resolves. The skip is guarded (`if r=$(cd -P … 2>/dev/null && pwd); then …`) so `set -e` callers survive it. One moved or deleted registered repo must never break harness commands in other repos.
  - **0 matches → repo mode:**
    - `PROJECT_MODE=repo`
    - `STATE_DIR=$GIT_ROOT`
    - `PROJECT_SUBDIR=`
    - `PROJECT_ROOT=$GIT_ROOT`
  - **1 match → registry mode:**
    - `PROJECT_MODE=registry`
    - `STATE_DIR` is the entry's directory
    - `PROJECT_SUBDIR` is the entry's subdir
    - `PROJECT_ROOT=$GIT_ROOT/$PROJECT_SUBDIR` with no trailing slash when the subdir is empty. It must exist, or exit 2.
    - A missing `$STATE_DIR/config.yaml` (registered, `/init` not yet run) is read as empty config. No script aborts on it, `worktree.sh`'s `set -e` awk read included.
  - **More than 1 match:** exit 2 naming the entries. `register` refuses to create a second entry for one root, so this only happens through hand edits. A `ponytail:` comment says multi-project repos come when real use asks for them.
- **Signature.** `resolve_project [<dir>]` runs its git calls as `git -C "${1:-.}"`, so `demo.sh` resolves from `<dir>` without changing directory. It sets the variables in the caller's shell, so callers must never invoke it in a subshell.
- **Builtins only.** The lib uses only bash builtins, `git` and `awk`: no `dirname`, `basename`, `sed`, `head` or `realpath`. The gate fixtures run `gate.sh` with `PATH` reduced to `bash`, `git` and `awk` (`test-scripts.sh:582-599`). It starts with `# shellcheck shell=bash` and `# shellcheck disable=SC2034`, because callers use the variables it sets. Every `source` line carries `# shellcheck source=/dev/null`. A real path would raise SC1091 under `test-scripts.sh:737`, which runs shellcheck without `-x`. `gate.sh` lists `lib/project.sh` through `git ls-files '*.sh'`, so it must pass shellcheck too.
- **`HERE` in each script.**
  - `gate.sh` must not use `dirname`. It computes `HERE` from `${BASH_SOURCE[0]}`: if the path contains `/`, strip the last component; otherwise use `.`. Then `cd -P`/`pwd`. That way `bash gate.sh`, run from inside `scripts/`, still works.
  - `agent-exec`, `release` and `fan-exec` keep their existing `HERE` line.
  - `worktree`, `demo`, `state`, `codex-review` and `archi-fresh` have none today. Each gains `HERE=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)` before any `cd`.
  - The fixture at `test-scripts.sh:1103` copies `worktree.sh` to the repo root as `wt.sh`. Its lib copy therefore goes to `<root>/lib/`.
- **When it runs.** Each script calls `resolve_project` only *after* its argument and `--help` handling and after its existing "inside a git checkout" check. That keeps every existing early-error message and exit code: dispatcher case (a) `demo --help` outside a repo, demo's "not a git work tree", and state's "not inside a git checkout". The one exception is `codex-review.sh` (§4).

### 2. `harness/scripts/project.sh` (new)

- `harness project` prints `STATE_DIR`.
- `harness project mode` prints `repo` or `registry`.
- `harness project root` prints `PROJECT_ROOT`.

Skills use `$(harness project)` to find state files.

### 3. `harness/scripts/register.sh` (new)

Usage: `harness register [--name <name>] [--subdir <path>]`. It must run from the primary checkout; from a linked worktree it exits 1.

Inputs:
- **Name:** defaults to the basename of `PRIMARY_ROOT`, plus `-<subdir with / → ->` when there is a subdir. Must match `^[A-Za-z0-9][A-Za-z0-9._-]*$`, so `.` and `..` are rejected. If a given or default name fails, exit 1 and suggest `--name`.
- **Subdir:** given relative to the toplevel. It must be an existing directory and must not contain `..`. `register` `cd`s to `GIT_ROOT` first, so `git rev-parse --git-path info/exclude` resolves correctly.

**Preflight before any write** (exit 1, nothing written):
- An entry for another root already uses `<name>`.
- Another entry already exists for this root under a different name, or under the same name with a different subdir. Either exits 1, telling the Owner to remove that entry, its `CLAUDE.local.md` and its exclude line by hand. There is no automatic move.
- `<project root>/CLAUDE.local.md` is tracked by git.
- `<project root>/CLAUDE.local.md` exists with content other than the exact line this script writes.

Writes (idempotent: a re-run with the same name and subdir rewrites the generated files and exits 0):
- `$STATE/project`: `root=` and `subdir=`
- `$STATE/work/` and `$STATE/knowledge/` (directories)
- `$STATE/CLAUDE.md` (generated): `@<harness root>/CONSTITUTION.md`, `@<STATE>/ARCHI.md` and `@<STATE>/PLAN.md`, so the hot tier loads mechanically. Then one paragraph saying this project runs in registry mode, its harness files live in `<STATE>`, and nothing harness-related is committed to the repository. `STATE` is written exactly as resolved, without extra canonicalization.
- `<project root>/CLAUDE.local.md`: the single line `@<STATE>/CLAUDE.md`.
- One line, `/<subdir/>CLAUDE.local.md`, appended to `$(git rev-parse --git-path info/exclude)` unless it's already there. The `info/` directory is created first if it's missing, which happens with a custom `init.templateDir`.

It does **not** write `config.yaml`, `ARCHI.md` or `PLAN.md`; `/init` does that. It prints the state dir.

It also prints one Owner step to stderr: run `/add-dir <STATE>` or add the state dir to `permissions.additionalDirectories`. Every orchestrator write in registry mode lands outside the launch directory, so without this each Edit prompts. `register` does not edit settings JSON.

Claude Code facts this relies on (code.claude.com/docs/en/memory, checked 2026-10-19):
- `CLAUDE.local.md` loads alongside `CLAUDE.md` from the launch directory and every directory above it.
- `@` imports may be absolute. Imports resolving outside the working directory trigger a one-time approval dialog per project.
- A `CLAUDE.local.md` stops Claude from reading a repo `AGENTS.md` on its own. The Owner should launch from the project root.

### 4. Scripts honor the resolution

Every changed script sources `"$HERE/lib/project.sh"`. Repo-mode behavior is byte-for-byte today's.

- **`gate.sh`:**
  - Registry mode `cd`s to `PROJECT_ROOT`, so `git ls-files '*.sh'` covers only the project.
  - It reads `required_tools` from `$STATE_DIR/config.yaml`.
  - It runs `$STATE_DIR/scripts/gate.d/*.sh` hooks with cwd `PROJECT_ROOT`. That's the same relative layout as repo mode, so the existing `init` and profile text ("put hooks in `scripts/gate.d/`") stays correct under the "relative to `$(harness project)`" rule.
  - Known limit, recorded in `work.md`: the example hooks `harness/examples/gate.d/{nb-clean,ds-hygiene}.sh` start with `cd "$(git rev-parse --show-toplevel)"`, so in subfolder mode they scan the whole repo. Narrowing them is left until real use asks for it.
- **`worktree.sh`:**
  - It reads `worktrees.dir` from `$STATE_DIR/config.yaml`; the default stays `../<basename GIT_ROOT>-worktrees`.
  - In registry mode `add` does not commit the plan onto the branch, and `sync-artifacts` prints `registry mode: unit artifacts live in <STATE_DIR>; nothing to sync` and exits 0.
  - `add` still prints the worktree root.
- **`agent-exec.sh`:** reads `implementer.command` from `$STATE_DIR/config.yaml` and runs the implementer with cwd `$WORKTREE/$PROJECT_SUBDIR`. The no-commit check is unchanged.
- **`demo.sh`:** resolves from `<dir>`. In registry mode it reads the plan from `$STATE_DIR/work/<slug>/plan.md` and runs the block with cwd `<dir's toplevel>/$PROJECT_SUBDIR`. The porcelain check is unchanged.
- **`state.sh`:** in registry mode the plan and unit files come from `$STATE_DIR/work/<slug>/`, never from the branch. Only the `plan → implement → review` rules apply. With the Codex sentinel unreachable until `reviewer-set`, a registry unit stays in `review` with `next_action` unchanged. Release and done rules for registry mode belong to `pr-release`; a `ponytail:` comment says so.
- **`codex-review.sh`:** the registry guard comes right after the `root=` line, before the branch check and the `main:config.yaml` read, because work repos have no `config.yaml` on `main`. In registry mode it exits 2 with `codex-review: registry mode has no second reviewer yet (reviewer-set)`. Registry mode is for work repos, which have no codex (Decision 2026-10-18), and `reviewer-set` decides what replaces the second reviewer. The repo-mode code keeps the literal strings `git show "$branch:$plan_path"` and `git show "main:config.yaml"`, which the static greps at `test-scripts.sh:977-978` require.
- **`archi-fresh.sh`:** in registry mode, sources come from `$STATE_DIR/config.yaml` `archi.sources`, defaulting to `.`. Each source is checked with `git log -1 --format=%ct <ref> -- <source>`, from cwd `PROJECT_ROOT`. These are compared with the mtime of `$STATE_DIR/ARCHI.md` from `date -r <file> +%s`, which works on both BSD and GNU. A missing `ARCHI.md` exits 2. The exit codes are unchanged.
- **`release.sh`:** in registry mode, `release <slug>` and `tag-after-merge` exit 1 with `release: registry mode has no release script yet (pr-release); open the PR by hand`.
- **`fan-exec.sh`:** in registry mode it exits 1 with `fan-exec: fan mode is repo-mode only`.

### 5. Prose

- **`harness/CONSTITUTION.md`** gains a short "Project state" section:
  - Primary-checkout paths `config.yaml`, `ARCHI.md`, `PLAN.md`, `work/` and `knowledge/` in skills and agents are relative to `$(harness project)`. Instructions that explicitly say "in the worktree" or "on the branch" keep that meaning in repo mode.
  - In registry mode, steps that commit unit artifacts to `wt/<slug>`, or open a retro branch, write the state file in place instead.
  - The gate, demo and implementer act on `$(harness project root)`.
  - Line 11 (`work/<slug>/plan.md`) gets the same prefix.
- **`2-implement` (`SKILL.md:8,18,19,21,34,35`):**
  - `handoff.tpl`, `followup.tpl` and `docs/prompts/handoff.tpl` name the plan as `{{PLAN_PATH}}`, an absolute path the orchestrator fills from `$(harness project)/work/<slug>/plan.md`. In registry mode the plan isn't in the worktree.
  - The handoff and `notes.md` are written and passed under `$(harness project)/work/<slug>/`, so registry mode never creates an untracked `work/` in the work repo.
- **`docs` (`SKILL.md:8,13,14`):** the same changes as `2-implement`, for the plan, the handoff and `notes.md`.
- **`1-plan`:** step 2 drafts `$(harness project)/work/<slug>/plan.md`.
- **`3-review`**, split per step by mode:
  - Step 1 (the diff pathspec `":(exclude,top)work/<slug>"`): unchanged; `test-scripts.sh:994` pins it.
  - Step 2 (`review-round`): `$(harness project)/work/<slug>/review-round` in both modes. The literal `work/<slug>/review-round` stays in the text (`test-scripts.sh:991`).
  - Steps 4 and 6 (deferrals, verdict sentinels): repo mode is unchanged, "in the worktree", because codex and `release.sh` read the branch copies. Registry mode edits `$(harness project)/work/<slug>/` in place with no commit.
  - Step 7 (ARCHI heal): in registry mode it edits `$(harness project)/ARCHI.md`.
  - The skill says registry mode records only `Code-review verdict:` until `reviewer-set` lands, so `harness state` keeps a registry unit in `review`.
- **`code-reviewer.md`:** keeps the literal `work/<slug>/deferrals.md` (`test-scripts.sh:984`).
- **`harness/AGENTS.md:3`, `harness/agents/code-reviewer.md:10` and `harness/agents/fan-selector.md:10`:** "the work unit (`work/<slug>/plan.md`)" becomes "the work unit's plan (the path the handoff or orchestrator names)".
- **`4-release`:** step 1 — in registry mode, stop after the review, report that `pr-release` owns this, and hand the Owner the branch to PR by hand.
- **`5-retro`:** in registry mode, write directly into the state dir. There's no retro worktree or PR, and the file boundary still applies.
- **`init`:** a new step 0: for a work repo, run `harness register [--subdir <path>]` first. Every file `/init` writes then goes under `$(harness project)`, and `/init` deletes nothing from the repo.
- **`harness/profiles/work.md`:** the Gate section says work repos use `harness register`, with no committed files.
- **`README.md`:** Getting started gains a "work repo" line.
- **`ARCHI.md`:** a targeted branch edit covering `lib/`, `project.sh`, `register.sh` and the registry-mode notes in each script line.

### Alternatives considered

- **A SessionStart hook that prints the constitution.** Rejected: `~/.claude/settings.json` already carries another tool's hooks, and editing JSON from bash without `jq` is fragile.
- **Keeping plans on branch commits in registry mode.** Rejected: a branch commit reaches the work repo's PR.
- **Making the state dir its own git repo.** Not now; nothing needs its history yet.

## Footprint

Files to modify:
- `harness/scripts/lib/project.sh` (new), `harness/scripts/project.sh` (new), `harness/scripts/register.sh` (new)
- `harness/scripts/{gate,worktree,agent-exec,demo,state,codex-review,archi-fresh,release,fan-exec}.sh`
- `harness/tests/test-scripts.sh`
- `tests/test-export.sh`: one `HARNESS_HOME` export line only
- `harness/CONSTITUTION.md`, `harness/AGENTS.md`, `harness/agents/{code-reviewer,fan-selector}.md`
- `harness/skills/{1-plan,2-implement,3-review,4-release,5-retro,init,docs}/SKILL.md`
- `harness/skills/2-implement/prompts/{handoff,followup}.tpl`, `harness/skills/docs/prompts/handoff.tpl`
- `harness/profiles/work.md`, `README.md`, `ARCHI.md`
- `PLAN.md` (the `Now` entry only, committed by the orchestrator on the unit branch)

Files NOT to touch:
- `harness/bin/harness`: it discovers the new commands itself, and `lib/` stays hidden.
- `harness/scripts/install.sh`.
- Root `CLAUDE.md`, `config.yaml`, `scripts/`, `template/` and `.github/workflows/ci.yml`: this repo stays in repo mode, and `harness-publish` owns the export.
- `harness/examples/gate.d/*.sh` and `harness/profiles/{software,machine-learning}.md`: their `scripts/gate.d/` wording stays correct (see §4 gate).

## Acceptance criteria

Every new case is hermetic:
- `test-scripts.sh` exports `HARNESS_HOME=$(mktemp -d)` at its top, next to `unset GATE_REQUIRED_TOOLS`. The existing `trap` at about line 769 also removes it. `tests/test-export.sh` exports its own temp `HARNESS_HOME` the same way, so the Owner's real `~/.harness` never reaches a fixture or the exported consumer gate.
- Every fixture that copies a harness script also copies `harness/scripts/lib/`, before that fixture's first commit, so porcelain comparisons see no new untracked file.

Every listed mutation is shown to fail its case, with the landing verified (`knowledge/silent-no-op-hazards.md`). The results go in `work/harness-registry/mutations.md`.

- [ ] **Repo mode unchanged:** every existing `test-scripts.sh` and `test-export.sh` case passes, including the stripped-`PATH` gate fixtures. The only edits to existing cases are the `lib/` copy and the `HARNESS_HOME` exports.
- [ ] **Lookup:**
  - A repo with an entry for a *different* root resolves to `repo` mode.
  - A registered repo resolves to `registry` mode from its primary checkout, from a subdirectory, and from a linked worktree.
  - Two entries for one root exit 2.
  - A stale entry (deleted root) and a malformed entry (no `root=`) are both skipped: an unrelated repo with a committed `config.yaml` still resolves to `repo` mode, and `harness worktree list` exits 0.
  - A registered repo with no state `config.yaml` can still run `harness worktree add`.
  - Mutations: match any entry regardless of `root`; drop the stale-root guard.
- [ ] **register:**
  - A fresh register creates `project`, `CLAUDE.md`, `work/` and `knowledge/`, plus `CLAUDE.local.md`, and appends one exclude line.
  - The generated `CLAUDE.md` contains exactly the three `@` lines: `CONSTITUTION.md`, the state `ARCHI.md` and the state `PLAN.md`.
  - `--name ..`, and a default name that fails the regex (a repo dir with a space), each exit 1 suggesting `--name`.
  - A repo with no `.git/info/` directory still gets its exclude line.
  - Afterwards `git status --porcelain` is empty.
  - A re-run exits 0 with no duplicate exclude line.
  - Each of these exits 1 with nothing written under `HARNESS_HOME` and no `CLAUDE.local.md` change:
    - a foreign `CLAUDE.local.md`
    - a tracked `CLAUDE.local.md`
    - a second name for the same root
    - the same name with a different `--subdir`
    - a run from a linked worktree
  - Mutation: remove the preflight.
- [ ] **gate, registry + subdir:**
  - A shellcheck-failing `bad.sh` outside the subdir does not fail the gate.
  - The same file inside the subdir does fail it.
  - A `$STATE_DIR/scripts/gate.d/` hook runs, and its cwd is the project root.
  - Mutation: `cd` to `GIT_ROOT` instead of `PROJECT_ROOT`.
- [ ] **worktree, registry:**
  - The fixture plants `$GIT_ROOT/work/<slug>/plan.md`, and `add` still commits no `work/` path onto `wt/<slug>`.
  - `sync-artifacts` exits 0 with the registry message.
  - Mutation: restore the plan commit in registry mode.
- [ ] **agent-exec, registry + subdir:** a canned implementer records its `pwd`, which equals `$WT/<subdir>`, and its `implementer.command` comes from the state config.
- [ ] **demo, registry:**
  - The demo runs the state plan's block, not a different plan committed on the branch, with cwd `<wt>/<subdir>`.
  - Mutation: read `<dir>/work/<slug>/plan.md`.
- [ ] **state, registry:**
  - `plan` → `implement` → `review` is derived from state-dir files alone, with no `wt/<slug>` plan copy.
  - A registry unit with only `Code-review verdict: APPROVE` stays in `review`.
- [ ] **codex-review, registry:** in a fixture with no `config.yaml` on `main`, it exits 2 with the `reviewer-set` message, and the canned reviewer is never invoked (marker file absent).
- [ ] **archi-fresh, registry:**
  - With `touch -t 200001010000 ARCHI.md` before the source commit, the check exits 1.
  - `touch`ing `ARCHI.md` to now afterwards exits 0.
  - A missing `ARCHI.md` exits 2.
- [ ] **release / fan-exec, registry:** both exit 1 with their messages. Mutation: drop the release guard.
- [ ] `harness project`, `project mode` and `project root` print the expected values in both modes. `harness` with no arguments lists `project` and `register`, and not `lib` or `project` twice.
- [ ] `git grep -nE '(^|[^)/])work/(<slug>|\{\{SLUG\}\})/(handoff|plan|notes)\.md' harness/skills harness/CONSTITUTION.md harness/AGENTS.md harness/agents` prints only lines that also contain `harness project`, `PLAN_PATH` or "in the worktree". Also, `grep -c 'harness project' harness/skills/3-review/SKILL.md` is at least 3, covering steps 2, 4/6 and 7.
- [ ] **Constitution loads, a manual check at the end of `/2-implement`.**
  - The orchestrator runs the Demonstration's register steps in a temp repo, starts `claude` interactively in its `app/` and accepts the external-import prompt.
  - It confirms `/memory` lists `CLAUDE.local.md`, the state `CLAUDE.md` and `CONSTITUTION.md`.
  - After `/add-dir <STATE>`, an Edit to the state `plan.md` goes through without a permission prompt.
  - It records the output in `work/harness-registry/notes.md`.
- [ ] `harness gate` passes on the branch, and `harness archi-fresh wt/harness-registry` exits 0.

## Release

Release note: `harness register` gives a work repo a home-directory state dir (`~/.harness/projects/<name>/`), and every script, skill and the constitution load from it, so a registered repo carries no harness files and its project can live in a subfolder.

Binding: main's `release.sh` releases this unit in repo mode, as usual. Nothing on main reads a registry.

## Demonstration

This registers a real temp repo with a subfolder project, under a temp `HARNESS_HOME`. It writes only under `mktemp -d`.

```sh
h="$PWD/harness/bin/harness"; d=$(cd -P "$(mktemp -d)" && pwd); export HARNESS_HOME="$d/hh"
r="$d/repo"; git init -q -b main "$r"; mkdir "$r/app"
printf '#!/usr/bin/env bash\necho ok\n' >"$r/app/ok.sh"
printf '#!/usr/bin/env bash\necho $UNQUOTED\n' >"$r/bad.sh"
git -C "$r" add -A; git -C "$r" -c user.name=d -c user.email=d@d commit -qm init
(cd "$r" && "$h" register --subdir app >/dev/null); echo "register_exit=$?"
s=$(cd "$r" && "$h" project); echo "state=${s#"$d"/} mode=$(cd "$r" && "$h" project mode)"
echo "local_md=$(sed "s|$d/||" "$r/app/CLAUDE.local.md")"
echo "porcelain=[$(git -C "$r" status --porcelain)]"
printf 'worktrees:\n  dir: %s\n' "$d/wts" >"$s/config.yaml"
mkdir -p "$s/work/demo"; printf '# Demo\n\n## Demonstration\n\n```sh\nbasename "$PWD"\n```\n' >"$s/work/demo/plan.md"
mkdir -p "$r/work/demo"; printf 'decoy\n' >"$r/work/demo/plan.md"
wt=$(cd "$r" && "$h" worktree add demo 2>/dev/null); echo "branch_files=$(git -C "$wt" ls-files | paste -sd' ' -)"
(cd "$wt" && "$h" gate) | grep -E '^(▶ shellcheck|GATE)'
(cd "$r" && "$h" demo demo "$wt"); echo "demo_exit=$?"
(cd "$r" && "$h" release demo 2>&1); echo "release_exit=$?"
```

Expected:
- `register_exit=0`
- `state=hh/projects/repo-app mode=registry`
- `local_md=@hh/projects/repo-app/CLAUDE.md`
- `porcelain=[]`
- `branch_files=app/ok.sh bad.sh`: no `work/` path, even with a decoy plan in the primary's `work/demo/`, which today's `worktree add` would commit
- `▶ shellcheck ok.sh` then `GATE: PASS`, because `bad.sh` sits outside the project
- `app`, then `demo_exit=0`
- `release: registry mode has no release script yet (pr-release); open the PR by hand`, then `release_exit=1`

## Review

Plan-reviewer round 1: REVISE (10 findings), all applied:
1. The lib uses only bash builtins, `git` and `awk`, and `gate.sh` computes `HERE` without `dirname`, because the gate fixtures strip `PATH`. Fixtures copy `lib/` before their first commit.
2. Registry hooks live at `$STATE_DIR/scripts/gate.d/`, so the init and profile text stays correct. The example hooks' toplevel `cd` is recorded as a known limit in `work.md`.
3. `1-plan/SKILL.md`, `AGENTS.md`, `code-reviewer.md` and `fan-selector.md` are added to the footprint and to the grep.
4. Stale or malformed registry entries are skipped, with a test and a mutation. `test-export.sh` exports its own `HARNESS_HOME`.
5. `resolve_project` runs after argument handling and the git-checkout checks. The codex-review static-grep strings are named.
6. `codex-review.sh` refuses in registry mode, pending `reviewer-set`. `3-review` says so.
7. A re-register with a different subdir is refused.
8. The demo canonicalizes the temp dir and uses `paste -sd' ' -`.
9. The temp `HARNESS_HOME` is removed by the existing trap.
10. The state `CLAUDE.md` imports `ARCHI.md` and `PLAN.md`.

No disagreements.

Plan-reviewer round 2: REVISE (10 findings), all applied:
1. `3-review` is split per step. The step-1 pathspec stays as it is. Repo-mode deferrals and sentinels stay in the worktree. Registry mode uses the state dir.
2. The grep now covers `{{SLUG}}` and `notes.md`. `notes.md` moves under `$(harness project)`. The pinned literals stay.
3. The codex-review guard comes before the `main:config.yaml` read, and its test fixture has no config on `main`.
4. A test checks the three `@` lines, and a manual `/memory` check is named.
5. The five scripts without one gain a `HERE` line. `gate.sh` handles a path with no slash. The `wt.sh` fixture's lib goes at the repo root. Shellcheck directives are required.
6. Registry `state.sh` stops at `review`; release and done rules wait for `pr-release`.
7. The archi-fresh test backdates `ARCHI.md` with `touch -t`.
8. The demo plants a decoy plan in the primary's `work/`, so `branch_files` actually proves the change. The release refusal is quoted exactly.
9. The name regex rejects `.`/`..` and suggests `--name`. `info/` is created when it's missing.
10. The `docs` and `2-implement` lines are named. `resolve_project [<dir>]` resolves without changing directory, and is never called in a subshell.

No disagreements.

Plan-reviewer round 3 (the cap): APPROVE, with 2 MEDIUM and 4 LOW findings, all applied:
1. The lib uses `source=/dev/null` and `disable=SC2034` (checked against shellcheck 0.11).
2. `register` prints the `/add-dir` step, and the manual check confirms an Edit to state goes through without a prompt.
3. A missing state `config.yaml` reads as empty, and the stale-entry fixture commits a `config.yaml`.
4. `--subdir` is relative to the toplevel, and `register` `cd`s to `GIT_ROOT` first.
5. A positive `harness project` grep was added for `3-review`.
6. `PROJECT_ROOT` has no trailing slash.

No disagreements.

Owner approval: 2026-10-19, approved as presented. The `PLAN.md → Now` entry goes on the unit branch.

Plan verdict: APPROVE

Code review:
- **Round 1.** The Claude reviewer approved; codex requested changes.
  - Codex HIGH (the Claude reviewer rated the same behavior MEDIUM): `register --subdir ./app` wrote a `/./app/` exclude line that git doesn't match, so `CLAUDE.local.md` showed as untracked. → followup-1 normalizes `--subdir`, with tests and a mutation.
  - Claude MEDIUM: the state-dir gate hook wasn't proven to run. → followup-1 adds a marker and a mutation.
  - Two LOW cleanups were also in followup-1. The other LOWs are recorded in `code-review-r1.md`.
- **Round 2.** Both reviewers approved.
  - Codex MEDIUM and Claude LOW: gitignore metacharacters in `--subdir`. → `deferrals.md`.
  - Claude MEDIUM: ARCHI freshness after the followup commit. → healed by step 7.
  - Remaining LOWs are recorded in `code-review-r2.md`.
- Manual `/memory` check: the Owner verified the constitution, `ARCHI.md` and `PLAN.md` load through `CLAUDE.local.md` (see `notes.md`). The `/add-dir` edit check was not exercised.

Code-review verdict: APPROVE
Codex-review verdict: APPROVE
