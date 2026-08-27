# Gate tool preflight — a skipped check must not read as a passed check

**Slug:** gate-tool-preflight · **Date:** 2026-08-27 · **Status:** approved

## Goal

`scripts/gate.sh` guards every stack's checks behind a `command -v` test (`shellcheck`, `node`, `ruff`, `pytest`, `cargo`, `go`). When the tool is absent the check is not run, nothing is printed, and the script still prints `GATE: PASS` and exits 0. The gate therefore reports the same success for "all checks ran and passed" and "the checks were never run", which voids the exit-code contract invariant #2 rests on: agents are told to trust the gate, and the gate is not distinguishing those cases. On this machine `node`, `ruff`, `cargo`, and `go` are all absent and the gate is green.

This is not hypothetical. The framework is about to be scaffolded onto a SageMaker-hosted work project where `shellcheck` cannot be `apt-get`-installed (no sudo in most Studio images) and where nothing installed outside the EFS home survives an app restart. The realistic failure is a green gate on a machine that silently lost its linter after a restart.

Done = the gate makes skipped checks visible in every run, a project can declare tools whose absence is a hard failure, and this repo declares `shellcheck` so the mechanism is exercised rather than shipped dormant.

## Approach

1. **Visibility (always on, no configuration).** Every `command -v` guard that declines to run a check prints one `⊘ skipped: <tool> (not installed)` line. No declaration to maintain, so nothing can drift out of sync with the detection logic. Exit codes unchanged. The skip line fires only when the *stack is present and the tool is missing* — a shell-only repo must not report skipping `cargo`.
2. **Enforcement (declared, not dormant).** `gate.required_tools` in `config.yaml` — a colon-separated scalar, the same shape as the existing `DS_DATA_ALLOW_DIRS` — read with the naive awk idiom already used in `worktree.sh:13`. `GATE_REQUIRED_TOOLS` overrides it as an env var. Absent config parses to empty, so `gate.sh` still runs standalone in a repo with no `config.yaml`.
3. **Declare it here.** Set `required_tools: shellcheck` in this repo's `config.yaml`. ARCHI's Stack line already states shellcheck is the gate's only external tool, CI installs it, and it is present locally — so this is a no-risk declaration that makes the motivating failure actually fail.

**Preflight semantics:** a missing required tool aborts *before* any stack check runs — print the missing tools, exit non-zero, emit no `▶` lines. If a declared tool is absent the gate cannot be meaningful anyway, and aborting gives the failure an unambiguous observable to test against.

**Why `config.yaml` and not an env var alone** *(reversed from the first draft, which claimed a list value was hard to parse with naive awk — verified false: the format is a colon-separated scalar, and `awk '/^gate:/{f=1;next} f&&/required_tools:/{print $2; exit}'` returns it correctly).* Config is the file whose job is per-project knobs; the env-var-only design would have required each project to edit a framework-shared script to make its requirement durable, which is strictly worse. Env-var-only also leaves enforcement off whenever the variable is unset — the silent-skip failure one level up.

**Why in `gate.sh` and not a `gate.d/` hook.** `gate.sh` is the only place that knows which checks it actually considered and skipped; requirement #1 is not expressible in a hook at all, and putting the required list in a hook would separate it from the logic it describes — the exact drift this unit exists to prevent.

Alternative rejected: fail whenever *any* detected stack's tool is missing, with no declaration. Too aggressive — a contributor without Go installed could not run the gate on a repo containing one Go file.

## Footprint

Files to modify:
- `scripts/gate.sh` — skip lines on each `command -v` guard; required-tools preflight
- `config.yaml` — `gate.required_tools: shellcheck`
- `tests/test-scripts.sh` — hermetic cases for both behaviors
- `profiles/work.md` — document the knob (the motivating project is a `work`-profile repo; knob declarations live in profiles by the `DS_*` precedent)
- `README.md` — one clause in Requirements (line ~134 lists the gate's tool prerequisites)
- `ARCHI.md` — Stack line (shellcheck now declared, not just needed), Layout `config.yaml` line, Conventions YAML-parsing line (add `gate.sh` to the naive-awk list), Verification check count

Files NOT to touch:
- `scripts/gate.d/examples/*` — this is not another opt-in example hook
- `scripts/release.sh`, `scripts/agent-exec.sh` — the exit-code contract they consume is unchanged when nothing is declared

## Acceptance criteria

- [ ] `bash scripts/gate.sh` in this repo exits 0 with `required_tools: shellcheck` declared.
- [ ] In a hermetic fixture repo whose `PATH` lacks a stack's tool while the stack marker file is present, the output contains a `skipped` line naming that tool.
- [ ] In a hermetic fixture with no `Cargo.toml`, `go.mod`, or `package.json`, the output contains no skip line for `cargo`, `go`, or `node` — the negative case.
- [ ] When a check does run, no skip line is printed for its tool.
- [ ] Hermetic required-tools pair: a fake executable in a temp dir prepended to `PATH` with that name declared → exit 0; the same declaration with the dir dropped from `PATH` → non-zero, naming the tool. (Replaces a host-dependent "shellcheck is installed" assertion.)
- [ ] Two missing declared tools are both named in the output, not just the first.
- [ ] With a required tool missing, the output contains no `▶` lines — the preflight aborts before stack checks.
- [ ] A repo with no `config.yaml` and no `GATE_REQUIRED_TOOLS` runs the gate without error — empty default.
- [ ] `GATE_REQUIRED_TOOLS` overrides the `config.yaml` value when both are set.
- [ ] ARCHI's Verification check count matches `tests/test-scripts.sh` output (currently 90), and the Stack line reflects the new knob.
- [ ] Each new test has been shown to fail with its guard removed (per the 2026-08-27 decision in `PLAN.md`; a passing assertion that cannot fail is not a test).
- [ ] `bash scripts/gate.sh` passes with shellcheck clean over the modified scripts.

## Implementation hazards

- `tests/test-scripts.sh` runs `bash scripts/gate.sh` on this repo, and the suite itself runs as the `scripts/gate.d/test-scripts.sh` hook (recursion-guarded by `TEST_SCRIPTS_RUNNING`). New cases must set `GATE_REQUIRED_TOOLS` **per-command**, never `export` it — an exported value leaks into that nested invocation and into the rest of the suite.
- Requirement #1 means restructuring the combined guards at `gate.sh:21` (`[[ -f package.json ]] && command -v node`), `:46`, and `:47`, so the skip line is conditional on the stack marker, not on the tool alone.

## Release

Release note: Gate reports skipped checks and hard-fails on declared missing tools (`gate.required_tools`), so a green gate no longer hides checks that never ran.

## Verification

- `bash scripts/gate.sh` (full suite; check count rises from 90)
- `GATE_REQUIRED_TOOLS=nope bash scripts/gate.sh; echo $?` — expect non-zero, no `▶` lines

## Review

Reviewer: fresh `plan-reviewer` subagent (opus, cold context, read-only). Verdict on the first draft: **REVISE**, nine findings. All nine accepted; no disagreements to arbitrate.

Applied:
1. **`config.yaml` rejection rested on a false premise.** The draft claimed a list value was materially harder to parse with naive awk, but the format is a colon-separated *scalar* — the same shape as `DS_DATA_ALLOW_DIRS`, parsed by the idiom already in `worktree.sh:13`. Verified directly. The config surface moved to `gate.required_tools`, and the draft's entire "Durability of the declaration" paragraph is deleted rather than documented.
2. **Default-off left the motivating scenario unfixed on ship day.** Now declares `shellcheck` in this repo, so the mechanism ships exercised.
3. **Footprint understated** — added `profiles/work.md`, `README.md`, and the specific ARCHI lines (Stack, Layout, Conventions YAML-parsing, Verification count).
4. **Fact error:** the check count is 90, not 95. Confirmed via `bash tests/test-scripts.sh`; the draft's number came from a bad grep proxy.
5. **AC "exits 0 where shellcheck is installed" was near-vacuous and host-dependent** — inverts meaning on the very SageMaker box in the Goal. Replaced with a hermetic fake-executable pair.
6. **No negative case** — added the shell-only-repo criterion and the check-ran criterion, which is where the guard restructuring will actually break.
7. **"Message is not buried" named no observable** — semantics now decided (abort before stack checks) and stated as "no `▶` lines".
8. **No AC covered the ARCHI edit** despite `release.sh` enforcing its freshness — added.
9. **Env-leak hazard** in the nested gate invocation — recorded under Implementation hazards.

Plan verdict: APPROVE (revised draft; Owner-approved 2026-08-27 after the reviewer's REVISE findings were applied in full).
