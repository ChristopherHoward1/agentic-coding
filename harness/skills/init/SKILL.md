---
name: init
description: Bootstrap this framework onto a project — scan the codebase, generate ARCHI.md, fill config.yaml, and verify the gate runs. Use once when adopting the framework, or after `harness register`.
---

# /init — bootstrap a project

## Steps

0. For a work repo, run `harness register [--subdir <path>]` first. Every file this skill writes goes under `$(harness project)`. Delete nothing from the repo. Launch from the project root; follow the printed `/add-dir` step.
   - Copy each missing `config.yaml`, `ARCHI.md` and `PLAN.md` from `$(harness root)/skeleton/` into `$(harness project)`. In repo mode only, also copy missing `VERSION` and `CHANGELOG.md`. Never overwrite existing files.
   - In repo mode only, ensure the project root's `CLAUDE.md` imports `@<harness root>/CONSTITUTION.md`, `@ARCHI.md` and `@PLAN.md`. Use the root printed by `harness root`, written as `~/…` when it is under `$HOME` so the committed import works on other machines. If `CLAUDE.md` is absent, write those three lines; if present, append only the import lines it lacks. Any existing `@…/CONSTITUTION.md` line counts as the constitution import, whatever its path. Never rewrite or delete existing content.
1. **Scan the codebase** (or note that it's greenfield): languages, frameworks, layout, entry points, existing test/lint commands.
2. **Classify** the project and set `profile:` in `config.yaml` (`software` | `machine-learning` | `database` | `work`). Read the chosen profile and ask the Owner for any declaration it requires (e.g. ML's eval slots).
   A profile's one-time infra swaps, such as implementer runtime changes, happen by the orchestrator following the chosen `$(harness root)/profiles/*.md` prose.
3. Set `archi.sources` in `config.yaml` to the project’s architecture-relevant paths (colon-separated). **Generate `ARCHI.md`** from the scan — replace every placeholder. Conventions section: only what an agent would get wrong by guessing.
4. **Wire the gate:** confirm `harness gate` detects the project's stacks; add anything project-specific as a `scripts/gate.d/*.sh` hook. Run it and show the Owner the output.
5. **Confirm the implementer:** check the configured runtime exists (`command -v codex` or equivalent); if not, ask the Owner what to set in `config.yaml`.
6. **Seed `PLAN.md`:** fill Objective with the Owner, leave the rest empty.

Done when: ARCHI.md has no placeholders, the gate runs (pass or legitimately fail), and config.yaml reflects reality.
