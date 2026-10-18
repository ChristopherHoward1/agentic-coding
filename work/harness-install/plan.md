# Harness install — one command links the harness into the home directory; the repo stops carrying bootstrap glue

**Slug:** harness-install · **Date:** 2026-10-18 · **Status:** implemented

## Goal

After `harness-split`, a clone of the harness still only works through repo-local glue: `.claude/skills` and `.claude/agents` symlinks, three root `scripts/` forwarders, a hand-typed `ln -s` for the dispatcher, a root `AGENTS.md` that codex happens to auto-read, a hard-coded ARCHI source list, and a committed Bitbucket CI file for work repos.

Done means:
- `harness install`, run once from any clone, links the dispatcher, skills and agents into the home directory, idempotently.
- The implementer contract lives at `harness/AGENTS.md` and `agent-exec` sends it ahead of every handoff, so no repo needs to carry it.
- `archi-fresh` reads its source paths from `config.yaml`.
- The forwarders, `bitbucket-pipelines.yml` and the repo's `.claude/` symlinks are gone, and so are the two `harness-split` deferrals.

Scope, per the Owner's call on 2026-10-18 (split recommended and approved):
- This unit covers the roadmap's install, `AGENTS.md`, `archi.sources` and "drop forwarders + CI" items.
- The `~/.harness/projects/<repo>/` registry and project root ≠ git root move to a new unit, **`harness-registry`**. Plans and verdict sentinels currently flow as commits on `wt/<slug>`, so moving state out of the repo needs its own design. Loading the constitution without a committed `CLAUDE.md` goes there too.
- **Gate result bound to SHA** moves to `pr-release`. The PR is its only consumer.
- This repo's `.github/workflows/ci.yml` stays (Owner, 2026-10-18). It is the public harness's own CI, and template-sync merges on its green.

## Approach

1. **`harness/scripts/install.sh`** (new; bash 3.2-safe; shellchecked). The dispatcher finds it through `scripts/*.sh`, so `harness install` needs no dispatcher change. The first run is `./harness/bin/harness install` from the clone.
   - `root=$(cd -P "$HERE/.." && pwd)`. `claude_dir=${CLAUDE_CONFIG_DIR:-$HOME/.claude}`, which is the variable Claude Code itself honours.
   - Link plan:
     - `$HOME/.local/bin/harness → $root/bin/harness`
     - each `$root/skills/<name>/` → `$claude_dir/skills/<name>`
     - each `$root/agents/<name>.md` → `$claude_dir/agents/<name>.md`
   - **Preflight before any write.** If a target exists and is not a symlink, print every such path to stderr, link nothing, and exit 1. A target that is already a symlink, pointing anywhere, is replaced with `ln -sfn` (`-n` so a symlinked skill dir is replaced, not linked into).
   - Creates the parent dirs and prints one line per link. If `$HOME/.local/bin` is not on `PATH`, prints a note to stderr. Still exits 0.
   - `--help`/`-h` print usage and exit 0. Any other argument prints usage to stderr and exits 2.
   - No pruning of links to removed skills: nothing has been removed yet. `ponytail:` comment.
2. **Contract piping.**
   - `git mv AGENTS.md harness/AGENTS.md`. Rule 3 becomes `harness gate` from the repo root.
   - `agent-exec.sh` sets `HERE=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)` and `CONTRACT="$HERE/../AGENTS.md"`. If the contract is missing or empty, it exits 1 naming the path, before the implementer is invoked.
   - It writes the contract, then a `---` separator line, then the handoff into a `mktemp` file (removed by an EXIT trap), and redirects that file into `eval "$CMD"`. Redirection, not a pipe, so `eval` still runs in the current shell.
   - The dispatch echo names both files.
   - Side effect, intended: `codex-review.sh` runs codex from the primary root, so today it also auto-reads the root `AGENTS.md`. That file is the implementer's contract ("You are the implementer"). After the move the reviewer no longer sees it.
   - `fan-exec` and `/docs` both dispatch through `agent-exec`, so they get the contract with no change.
   - First lines of the handoff templates:
     - `2-implement/prompts/handoff.tpl`: "The implementer contract precedes this handoff — it is your contract."
     - `docs/prompts/handoff.tpl`: the same, keeping "Its gate rule does not apply to docs units: do not run the gate."
3. **`archi.sources`.**
   - `archi-fresh.sh` reads `archi.sources` from `git show "$ref:config.yaml"`, so the branch config governs a branch check, the same way the history already does.
   - Parsing reuses `gate.sh`'s section-scoped awk for `required_tools`: top-level `archi:` section only, `#` comments stripped, quotes stripped. The value is colon-separated, matching `required_tools` and its `IFS=:` split.
   - No config at the ref, no key, or an empty value falls back to today's list `harness/ scripts/ config.yaml CLAUDE.md`. Every existing fixture (`config.yaml` is `name: fixture`) keeps passing unchanged.
   - This repo's `config.yaml` gains `archi:` / `  sources: harness/:scripts/:config.yaml:CLAUDE.md`.
4. **Removals.**
   - `git rm` `scripts/{gate,demo,archi-fresh}.sh`, `bitbucket-pipelines.yml`, `.claude/skills` and `.claude/agents` (both symlinks).
   - `.claude/settings.local.json` is untracked and stays.
   - Root `CLAUDE.md` stays: constitution loading without it is `harness-registry`'s.
5. **References.**
   - Prose that names `.claude/agents/` as where reviewers are defined now names `harness/agents/` (installed into `~/.claude/agents/`): `harness/CONSTITUTION.md:23`, `README.md:53` and `:107`, and the three `config.yaml` model comments.
   - `harness/tests/test-scripts.sh:982-985` grep `harness/agents/code-reviewer.md`.
   - `knowledge/test-helper-contract.md:56` and `:63`, and the `test-scripts.sh:50` comment, say `harness gate` instead of `scripts/gate.sh`.
   - `test-scripts.sh:885` (the archi-fresh help case) runs from `$ROOT` through the deleted forwarder. It calls `harness/scripts/archi-fresh.sh` instead.
   - `template/ARCHI.md:23` says `harness gate` (deferral 1).
   - README Getting started step 2 becomes `./harness/bin/harness install` (deferral 2: the install is idempotent, so the `ln -s` re-run failure goes away). The Layout block drops the `.claude/agents/` line, names `harness/agents/` and `harness/AGENTS.md`, and adds `install.sh`.
   - `harness/profiles/work.md` Gate section: work repos commit no CI file. `/init` deletes `.github/workflows/ci.yml` and the gate runs locally. The `required_tools` paragraph is kept.
   - `ARCHI.md`: targeted branch edit of `:12` (`config.yaml` keys gain `archi.sources`), `:13`, `:14`, `:16` (archi-fresh path list, agent-exec contract, new `install.sh`), `:18` (work profile CI), `:21`, `:23` (`AGENTS.md` → `harness/AGENTS.md`), `:42`, `:46` (release-precondition path list), `:47` (awk list gains `archi-fresh.sh`) and the closing paragraph.
   - `harness/skills/1-plan/SKILL.md:20` becomes: "Footprints name canonical tracked paths (`harness/…`), never installed `~/.claude/` aliases."
   - `README.md:102` (Layout `config.yaml` line) adds archi sources.
   - `harness/skills/init/SKILL.md:12`: drop "Bitbucket CI" from the example infra swaps. Step 3 adds: set `archi.sources` in `config.yaml` to the project's architecture-relevant paths (F4, round 2).
   - `harness/skills/4-release/SKILL.md` step 5: after `git pull --ff-only`, run `harness install`. It's idempotent, and it means a skill or agent added in a later unit gets linked on the next release. Per-entry links lose the auto-pickup that the old directory symlinks gave.

Alternatives considered:
- **Per-repo links under `.git/info/exclude` instead of `~/.claude`.** Rejected. The roadmap names `~/.claude`, and per-repo scoping belongs to `harness-registry` if real use asks for it. Trade-off for the Owner (plan-reviewer finding 2): every project on the machine gains all 8 skills, including `init` and `compact`, which sit beside or shadow Claude Code's built-in `/init` and `/compact`. Today that only happens in this repo. The Owner accepted this on 2026-10-18.
- **Linking `CONSTITUTION.md` from `~/.claude/CLAUDE.md`.** Rejected: it would load the constitution into every project. Deferred to `harness-registry`.

## Footprint

Files to modify:
- `harness/scripts/install.sh` (new)
- `harness/scripts/agent-exec.sh`
- `harness/scripts/archi-fresh.sh`
- `AGENTS.md` → `harness/AGENTS.md` (move + rule 3)
- `harness/skills/2-implement/prompts/handoff.tpl`
- `harness/skills/docs/prompts/handoff.tpl`
- `harness/skills/init/SKILL.md`
- `harness/skills/4-release/SKILL.md`
- `harness/skills/1-plan/SKILL.md`
- `PLAN.md` (roadmap and Decision only, committed by the orchestrator; see Release)
- `harness/tests/test-scripts.sh`
- `harness/CONSTITUTION.md`
- `harness/profiles/work.md`
- `config.yaml`
- `README.md`
- `ARCHI.md`
- `knowledge/test-helper-contract.md`
- `template/ARCHI.md`
- deleted: `scripts/gate.sh`, `scripts/demo.sh`, `scripts/archi-fresh.sh`, `bitbucket-pipelines.yml`, `.claude/skills`, `.claude/agents`

Files NOT to touch:
- `.github/workflows/ci.yml` (kept by Owner decision)
- `harness/bin/harness` (discovers `install.sh` by itself)
- `CLAUDE.md`, `scripts/export-template.sh`, `scripts/sync-template.sh`, `tests/test-export.sh`, `template/` other than `ARCHI.md:23` (`harness-publish` replaces them)
- `harness/scripts/{release,worktree,state,codex-review,fan-exec,demo,gate}.sh` (registry work, not this unit)

## Acceptance criteria

New `test-scripts.sh` cases are hermetic: `HOME=$(mktemp -d)`, with `CLAUDE_CONFIG_DIR` unset per command unless the case sets it. Every listed mutation is shown to fail its case, and the mutation is verified to have landed (`knowledge/silent-no-op-hazards.md`); the results go in `work/harness-install/mutations.md`.

- [ ] **install (a):** a fresh install creates one link per entry in `ls "$ROOT/harness/skills"` and per `"$ROOT/harness/agents"/*.md`, with no hard-coded counts, plus the dispatcher link. Each resolves (`cd -P`/`readlink`) to the matching path under `$ROOT/harness`, and `"$HOME/.local/bin/harness" root` prints `$ROOT/harness`.
- [ ] **install (b):** a re-run exits 0 with identical link targets.
- [ ] **install (c):** a skill link pointing at another real directory is replaced, and nothing is created inside that directory. Mutation: drop `-n` from `ln -sfn`.
- [ ] **install (d):** a regular file at one agent target → exit 1, stderr names it, and no link exists anywhere under the temp `HOME`. Mutation: remove the preflight.
- [ ] **install (e):** with `CLAUDE_CONFIG_DIR=<tmp>/cfg`, the skills and agents land there and not under `$HOME/.claude`.
- [ ] **install (f):** an extra argument exits 2 with `Usage:`, and `--help` exits 0.
- [ ] **agent-exec contract:** a canned implementer that saves its stdin shows the fixture `AGENTS.md` text first, then `---`, then the handoff text. A missing fixture contract → exit 1 naming `AGENTS.md`, and the implementer is never invoked (marker file absent). Mutation: drop the contract from the combined file. The agent-exec fixture (`test-scripts.sh:406`) and the fan-exec fixture (`:522`, whose `fan-exec.sh:75` calls the copied `agent-exec.sh`) each commit a stub `AGENTS.md` at the fixture root in their initial commit, and every existing agent-exec and fan-exec case still passes.
- [ ] **archi.sources:**
  - With `archi:\n  sources: src/` at the ref, a newer `src/` commit → exit 1 naming `src/`, and a newer `harness/` commit alone → exit 0. Mutation: ignore the config value.
  - A commented-out key, or a `sources:` under another top-level section, falls back to the default list.
  - The key is read at the ref: a `wt/demo` config that differs from HEAD's governs `archi-fresh wt/demo`.
- [ ] `git ls-files AGENTS.md scripts/gate.sh scripts/demo.sh scripts/archi-fresh.sh bitbucket-pipelines.yml .claude` prints nothing, and `harness/AGENTS.md` is tracked.
- [ ] `git grep -nE '(^|[^/])scripts/(gate|demo|archi-fresh)\.sh|bitbucket-pipelines|(^|[^/])\.claude/(agents|skills)|AGENTS\.md in the repo root' -- ':!work' ':!CHANGELOG.md' ':!harness/tests' ':!knowledge/release-script-binding.md' ':!PLAN.md'` prints nothing.
- [ ] README Getting started contains `./harness/bin/harness install` and no `ln -s`. The existing `bash harness` reference check still passes.
- [ ] `harness gate` passes on the branch, and `harness archi-fresh wt/harness-install` exits 0.

## Release

Release note: `harness install` links the harness into the home directory; the implementer contract now travels with every handoff, ARCHI sources come from `config.yaml`, and the bootstrap forwarders, repo `.claude/` symlinks and Bitbucket CI file are gone.

Binding: main's `release.sh` releases this unit, as usual (`knowledge/release-script-binding.md`). Nothing on main calls the deleted forwarders: `release.sh` reaches its siblings via `$HERE`.

- **Follow-up dispatches.** Main's installed `agent-exec` doesn't send the contract, and once the branch moves `AGENTS.md`, codex no longer finds it at the root. For this unit only, the orchestrator prepends the worktree's `harness/AGENTS.md` to each follow-up handoff file before dispatch.
- **Roadmap record.** The orchestrator commits this on `wt/harness-install` right after `harness worktree add`, so it reaches `main` only through this unit's release PR. A local-only commit on `main` would break `/4-release`'s `git pull --ff-only`. It contains:
  - the `PLAN.md` roadmap edit: `harness-install` (this scope) → `harness-registry` (registry, project root ≠ git root, loading the constitution without a committed `CLAUDE.md`) → `harness-publish` → … → `pr-release`, which gains the gate result bound to SHA;
  - a one-line Decision for the split, linking this plan.
- **Discovery check, at the end of `/2-implement`.** Once the gate is green and before `/3-review`, any fix it forces still gets reviewed.
  - The orchestrator runs `$WT/harness/bin/harness install` for real.
  - From `$(mktemp -d)`, a fresh `claude -p` lists its available subagents and skills.
  - That output and `ls -l` of `~/.claude/{skills,agents}` go in `work/harness-install/notes.md`.
  - Then it deletes the `~/.claude/{skills,agents}` links that point into `$WT`, and runs `ln -sfn <primary>/harness/bin/harness ~/.local/bin/harness`. Review and release then load main's skills, agents and dispatcher, as they do today.

Post-merge, this unit only: main's pre-merge `/4-release` text has no install step yet. So after the `--ff-only` pull, the orchestrator runs `harness install` once by hand. That restores this repo's skills and agents, which the deleted `.claude/` symlinks used to provide. Later releases get the step from the skill itself.

## Demonstration

This runs the branch's real install, contract piping and freshness check against a temp `HOME`. It writes only under `mktemp -d`.

```sh
h="$PWD/harness/bin/harness"; d=$(mktemp -d)
env -u CLAUDE_CONFIG_DIR HOME="$d" "$h" install >/dev/null; echo "install_exit=$?"
echo "skills: $(ls "$d/.claude/skills" | tr '\n' ' ')"
echo "agents: $(ls "$d/.claude/agents" | tr '\n' ' ')"
echo "root=$("$d/.local/bin/harness" root)"
env -u CLAUDE_CONFIG_DIR HOME="$d" "$h" install >/dev/null 2>&1; echo "rerun_exit=$?"
rm "$d/.claude/agents/plan-reviewer.md"; printf 'mine\n' >"$d/.claude/agents/plan-reviewer.md"
env -u CLAUDE_CONFIG_DIR HOME="$d" "$h" install; echo "conflict_exit=$?"
p="$d/proj"; git init -q "$p"
printf "implementer:\n  command: 'cat > stdin.txt'\n" >"$p/config.yaml"
git -C "$p" add config.yaml; git -C "$p" -c user.name=d -c user.email=d@d commit -qm init
printf 'HANDOFF-BODY\n' >"$d/handoff.md"
(cd "$p" && "$h" agent-exec "$p" "$d/handoff.md" 2>/dev/null); echo "dispatch_exit=$?"
head -1 "$p/stdin.txt"; grep -c 'HANDOFF-BODY' "$p/stdin.txt"
echo "sep_line=$(grep -nx -- --- "$p/stdin.txt" | cut -d: -f1) contract_lines=$(wc -l <harness/AGENTS.md | tr -d ' ')"
a="$d/archi"; git init -q "$a"; c() { git -C "$a" add -A && git -C "$a" -c user.name=d -c user.email=d@d commit -qm "$1"; }
printf 'arch\n' >"$a/ARCHI.md"; c archi
printf 'archi:\n  sources: src/\n' >"$a/config.yaml"; mkdir "$a/src"; printf 'x\n' >"$a/src/x"; sleep 1; c src
(cd "$a" && "$h" archi-fresh); echo "archi_exit=$?"
```

Expected:
- a PATH note on stderr (the temp `.local/bin` is not on `PATH`), then `install_exit=0`
- the 8 skill names, then `code-reviewer.md fan-selector.md plan-reviewer.md`
- `root=` this worktree's `harness` directory
- `rerun_exit=0`
- a stderr line naming `…/agents/plan-reviewer.md`, then `conflict_exit=1`. The preflight refuses before the PATH note is reached, so the note doesn't print.
- `dispatch_exit=0`, then `# Implementer Contract`, then `1`
- `sep_line` equal to `contract_lines` + 1
- a stale line naming `src/`, then `archi_exit=1`

## Review

Plan-reviewer round 1: REVISE (9 findings). Findings 1 and 3–9 are applied:
1. The `.claude/` grep now ignores `~/.claude` and `$HOME/.claude` paths.
3. Stub `AGENTS.md` in both the agent-exec and fan-exec fixtures.
4. For this unit, follow-up handoffs get the contract prepended by hand.
5. The full list of ARCHI lines to edit, plus `init/SKILL.md:12`.
6. The demo now shows `archi.sources` biting and the separator's position.
7. The discovery check runs before merge, with the dispatcher pointed back at main afterwards.
8. `archi.sources` is colon-separated, with this repo's value written out.
9. The roadmap and Decision get committed on main when the plan is approved.

Round-1 finding 2: global `init`/`compact`/`docs` sit beside Claude Code's built-in `/init` and `/compact` in every project. Owner, 2026-10-18: link all 8 and accept it. Per-repo scoping goes to `harness-registry` if it bites.

No disagreements.

Plan-reviewer round 2: REVISE (6 findings), all applied:
1. Added `test-scripts.sh:885`: it ran through a deleted forwarder. Fixed the `:522` reference.
2. Added `harness install` to `/4-release` step 5 after the pull, so new skills and agents get linked. This unit still needs one manual run, because main's pre-merge skill text runs its release.
3. The discovery check moves to the end of `/2-implement` and cleans up its worktree links afterwards.
4. `/init` now sets `archi.sources`.
5. Added `ARCHI.md:12` and `README.md:102`.
6. The demo's Expected now covers the PATH note.

No disagreements.

Plan-reviewer round 3 (the cap): REVISE (1 blocking finding, 3 LOW), all applied:
1. The roadmap and Decision edit is committed on the unit branch, not on local `main`, so the `--ff-only` pull still works. `PLAN.md` is added to the footprint.
2. The codex reviewer no longer auto-reading the contract is now stated, and intended.
3. `1-plan/SKILL.md:20` is reworded to say installed `~/.claude/` aliases.
4. The install test counts come from the directory listing.

No disagreements. Round 3 is the cap, so the plan goes to the Owner.

Owner approval: 2026-10-18, approved as-is with the round-3 fixes applied. The `PLAN.md → Now` entry goes on the unit branch together with the roadmap record.

Plan verdict: APPROVE

Code review:
- **Round 1.** Both reviewers approved.
  - The Claude reviewer re-ran the gate (224/0, export 12/0) and the demo, which matched Expected line for line. In its own clones it re-ran all four mutation pins, each verified to land. It also ran `install.sh` and `archi-fresh.sh` under `/bin/bash` 3.2.57.
  - Codex passed shellcheck. Its read-only sandbox could not run the gate or the mutations (the known residual risk).
  - LOWs, recorded and not acted on:
    - `install.sh`'s preflight checks only the link targets, not their parent dirs. A regular file at `~/.claude/agents` would leave a partial install.
    - The install tests run a copy at `$HOME/clone/harness`, not `$ROOT/harness`. The demo covers the real path.
    - A malformed `archi.sources` value exits 2 saying "no git history" instead of pointing at the config.

Code-review verdict: APPROVE
Codex-review verdict: APPROVE
