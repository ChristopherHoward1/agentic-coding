# Work profile — Atlassian/Bitbucket adaptation

**Slug:** work-profile · **Date:** 2026-08-24 · **Status:** merged

## Goal

Make the framework adoptable in an Atlassian/Bitbucket workplace via config, not a fork. Scaffold this template into a work repo, pick the `work` profile, and get: the implementer running as Claude (no Codex there), a Bitbucket Pipelines gate, and a release path that matches the repo's human-review policy. Two policies exist for real, and they are different release *topologies*, not different reminder text:

- **self** — main protected, only the author reviews. Current topology is already correct: `release.sh` ff-merges the release branch into local `main`, `/4-release` pushes `main` + tag.
- **platform-team** — a platform engineer must merge. `release.sh` must **not** touch `main`; it stages the version bump on the release branch and `/4-release` pushes the *branch* for a Bitbucket PR that the platform engineer merges.

Jira is out of scope by design — `work/<slug>/` units are the tracker; a Jira key is at most a read-only reference in a plan header, never created. Done = one template that adapts through `config.yaml` + `profiles/work.md`, both review topologies actually enforced, no second "lite" repo to maintain.

## Approach

Single template, new profile + a config-selected release topology.

- **`config.yaml`** — add `review.human_pr_review: self` (values `self | platform-team`); list `work` among valid `profile:` values; document the Claude implementer `command:` as a commented alternative. The template's own active values stay `profile: software`, `implementer.runtime: codex` (keeps dogfooding Codex; `work` is the per-project option).
- **`scripts/release.sh`** — read `review.human_pr_review` (naive awk, same style as `agent-exec.sh`). Shared preconditions (verdict, gate, ARCHI fresh, version increasing, clean release worktree) run in **both** modes. The `main` worktree lookup (`release.sh:198-199`) **stays required in both modes** — worktrees are always cut from it. Then branch:
  - `self` → unchanged: local-main ff precondition + ff-merge into local `main`; message stays "stopped before push".
  - `platform-team` → `git fetch origin main`, then require `origin/main` is an ancestor of the release branch (branch already contains the latest merged release) — else die telling the Owner to rebase/sync. This fetch+ancestor guard runs **twice — once before `check_gate` and once after**, mirroring the existing `check_ff_possible` double-call (`release.sh:213,221`): the gate takes real time and a platform engineer can merge another PR into shared `origin/main` mid-run, so a single check would let two near-simultaneous releases both pass and compute the same version. Compute `next_version` from the release branch's `VERSION` (post-rebase = newest merged release); the guard only re-fetches/re-checks ancestry and never rebases, so `VERSION` is unchanged between the two checks — read it once as self-mode does (`release.sh:208`), no need to relocate the computation → **collision closed deterministically**. Then commit the VERSION+CHANGELOG bump on `wt/<slug>`, do **not** ff-merge `main`. Replace the local-main ff precondition with the `origin/main`-ancestor guard. Print the branch name + a "push this branch, open a Bitbucket PR, platform engineer merges" message. The fetch is read-only — invariant #5 ("never pushes") is intact; only release.sh's purely-local character loosens.
  - **Tagging in platform-team mode is permanently out of scope, not deferred work.** The mode never creates a `v<version>` tag (`VERSION`, not tags, is the source of truth for `next_version`, so nothing depends on it). If tags are wanted, the platform engineer or Owner runs `git tag vX.Y.Z <merge-commit> && git push origin vX.Y.Z` manually after the PR merges — documented in `profiles/work.md`, never automated here.
- **`tests/test-scripts.sh`** — add platform-team coverage over a **bare-remote** topology: single release (main untouched, no `v<version>` tag, bump commit on the release branch) **and a sequential two-release scenario** proving the guard — release A, simulate the platform-team PR merge into remote `main`, then attempt B off a stale local `main`: release.sh must **refuse** until B's branch contains `origin/main`; after sync/rebase, B computes the next micro (no collision). **Plus a mid-gate case**: `origin/main` moves during the gate run (e.g. a temporary `gate.d/` hook that pushes to the bare `origin`) must be caught by the post-gate re-check — proving the double-check earns its place. Reuse the existing `setup_release_fixture` bare `origin`. Keep the existing self-mode assertions.
- **`skills/4-release/SKILL.md`** — **steps 3 and 4** both branch on `review.human_pr_review`. Step 3's report is mode-conditional (self: prepared version, tag, local `main` advanced; platform-team: bump commit on branch, no tag, `main` untouched). Step 4: self → push `main` + tag (as today); platform-team → push the release branch, print the PR instruction, never push `main`.
- **`skills/init/SKILL.md`** — add `work` to the hardcoded profile enum in step 2; state plainly that a profile's one-time infra swaps (Bitbucket CI, implementer runtime) happen by the orchestrator following `profiles/work.md` prose — that prose *is* the mechanism.
- **`profiles/work.md`** — new: Claude implementer `command:`, both `human_pr_review` topologies and what each does, the CI swap (add `bitbucket-pipelines.yml`, delete `.github/workflows/ci.yml`), the platform-team **sync workflow** (release.sh fetches and refuses on a stale branch; keep local `main` pulled from the PR-merged remote — note the required `main` worktree check does **not** imply local `main` is current, since the guard checks `origin/main`), the permanent no-tag limitation + the manual tag command, and the Jira reference-only stance.
- **`bitbucket-pipelines.yml`** — new: mirror `.github/workflows/ci.yml` **step-for-step** — install shellcheck, **set a git identity** (`user.email`/`user.name`; the smoke-suite fixtures `git commit`), run `bash tests/test-scripts.sh` then `bash scripts/gate.sh`. Eyeball-only, so don't paraphrase the shorter list — match ci.yml.

Alternative rejected: fork a "work-lite" repo — two templates drift; the profile mechanism exists to avoid this.

## Footprint

Files to modify:
- `config.yaml` — `review:` block, `work` profile value, Claude implementer comment
- `scripts/release.sh` — config-selected release topology (self vs platform-team)
- `tests/test-scripts.sh` — platform-team mode assertions
- `skills/4-release/SKILL.md` — push step branches on review topology
- `skills/init/SKILL.md` — `work` in profile enum; profile-prose-drives-infra note

Files to add:
- `profiles/work.md`
- `bitbucket-pipelines.yml`

Files NOT to touch:
- `scripts/agent-exec.sh` — already reads `implementer.command` generically; the Claude swap is pure config.
- `ARCHI.md` — regenerated by `/compact`; touching `scripts/ skills/ profiles/ config.yaml` makes it stale, so `/compact` runs before `/4-release` (expected).
- The template's own active `config.yaml` values (`software` / `codex`).

## Acceptance criteria

- [ ] `config.yaml` has a `review:` block with `human_pr_review: self`, lists `work` among `profile:` values, and shows the Claude implementer command as a commented alternative.
- [ ] `scripts/release.sh` reads `review.human_pr_review`; `self` mode is byte-for-byte unchanged (existing tests still pass); `platform-team` mode runs the fetch + `origin/main`-ancestor guard **both before and after `check_gate`**, commits the bump on the release branch, does **not** ff-merge `main`, creates **no** `v<version>` tag, and prints branch-push/PR guidance. The `main` worktree lookup stays required in both modes.
- [ ] `tests/test-scripts.sh` covers platform-team single-release (main unchanged, no tag, bump on branch), the sequential two-release collision scenario (stale-main release refused; passes after sync), **and a mid-gate `origin/main`-moves case caught by the post-gate re-check**, over a bare-remote topology; self-mode assertions still pass; `bash scripts/gate.sh` exits 0.
- [ ] `skills/4-release/SKILL.md` step 4 branches its push action on `review.human_pr_review` (self: push main+tag; platform-team: push branch, open PR, never push main).
- [ ] `skills/init/SKILL.md` step 2 lists `work` and states profile prose drives one-time infra swaps.
- [ ] `profiles/work.md` documents: Claude implementer command, both review topologies, the CI swap (add bitbucket-pipelines.yml / delete ci.yml), the platform-team tagging limitation, and Jira reference-only.
- [ ] `bitbucket-pipelines.yml` installs shellcheck and runs `bash tests/test-scripts.sh` + `bash scripts/gate.sh`.

## Release

Release note: Add `work` profile with a config-selected release topology (self vs platform-team), Bitbucket Pipelines CI, and a Claude implementer runtime for Atlassian workplaces.

## Verification

- `bash scripts/gate.sh` — green (shellcheck over `release.sh`/`tests`, smoke suite incl. new platform-team cases).
- `bitbucket-pipelines.yml` is eyeball-verified only — no Bitbucket runner in this repo; residual risk accepted for a template file.
- Run `/compact` before `/4-release` to refresh ARCHI (profiles/ + config.yaml + scripts/ touched → staleness gate will otherwise refuse release).

## Review

**Round 1 (plan-reviewer, REVISE):**
- *Platform-team flavor was cosmetic* — agreed; Owner chose to build the real topology. `release.sh` + tests + 4-release skill now carry a config-selected release path; platform-team never merges/pushes `main`.
- *`skills/init/SKILL.md` missing from footprint* — agreed; added, with the profile-prose-is-the-mechanism note made explicit.
- *Goal boilerplate / bitbucket-yml unverifiable* — agreed; goal rewritten around the two topologies, Verification states the eyeball-only limit.

**Round 2 (plan-reviewer, REVISE):**
- *Version-collision hazard* — platform-team never bumps local `main`, so successive same-month releases recompute the same version. Owner chose the authoritative fix: `release.sh` does `git fetch origin main` in platform-team mode and refuses unless `origin/main` is an ancestor of the release branch, computing the version off the newest merged release. Fetch is read-only; invariant #5 holds.
- *No resync mechanism / test wouldn't catch it* — added the fetch guard + a sequential two-release test over a bare remote that proves the refusal-then-pass behavior.
- *main_checkout lookup ambiguity* — resolved: stays required in both modes (worktrees are cut from it); only the ff-merge/local-main precondition is mode-specific.

**Round 3 (plan-reviewer, REVISE):**
- *Guard checked only once — race reopens across `check_gate`* — agreed; the guard now re-fetches and re-checks **before and after** `check_gate`, mirroring `check_ff_possible`'s double-call, with a mid-gate-move test case.
- *Tag timing was vague* — agreed; platform-team mode never tags (permanent, not deferred); the manual post-merge tag command is documented in `profiles/work.md`.
- *4-release step 3 also mode-dependent* — agreed; both steps 3 and 4 branch on the mode.
- *Local-main-current vs required main worktree* — agreed; one-line note in `profiles/work.md`.

**Round 4 (plan-reviewer, APPROVE):** two non-blocking implementation notes folded in — `bitbucket-pipelines.yml` mirrors `ci.yml` step-for-step incl. the git-identity step; `next_version` is read once (guard doesn't rebase, so VERSION is stable across the two checks).

Plan verdict: APPROVE

**Code review (code-reviewer, APPROVE):** all 7 acceptance criteria met; gate 20/20; shellcheck clean; footprint exact. Confirmed self mode byte-identical to main, the platform-team guard runs before+after the gate, no tag/no main-merge in platform-team, and the three new tests are non-vacuous (mid-gate test pushes a competing commit to origin during the gate and proves the post-gate re-check catches it). No blocking findings.
Code-review verdict: APPROVE
