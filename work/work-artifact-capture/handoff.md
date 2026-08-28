You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.

Work unit: work/work-artifact-capture/plan.md  (read it in full; it is your source of truth)
Branch: wt/work-artifact-capture (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
- scripts/worktree.sh — new `sync-artifacts <slug>` subcommand + usage header
- skills/2-implement/SKILL.md — call it after dispatch
- skills/3-review/SKILL.md — call it at step 5
- skills/4-release/SKILL.md — call it before release.sh
- tests/test-scripts.sh — hermetic cases
- ARCHI.md — worktree.sh Layout line, its Entry-points line, Verification check count

Do NOT touch: scripts/release.sh (a criterion asserts it is byte-identical), scripts/codex-review.sh,
scripts/agent-exec.sh, worktree.sh's existing `add` path, skills/5-retro/SKILL.md.

## What to build

`scripts/worktree.sh sync-artifacts <slug>` — copy the primary checkout's `work/<slug>/`
artifacts into the unit's worktree and commit them, so a released unit's handoff, notes,
followups, and codex review reach main with it instead of needing a manual catch-up commit.

The whole subcommand is roughly eight lines. Resist making it bigger; the plan's Approach
section deliberately removed the complexity that a first draft had.

### Exact semantics

1. **Scope of the copy:** top-level **regular, non-dot** files in `$ROOT/work/<slug>/`.
   - **Exclude `plan.md` outright.** It reaches the branch via `add`, and `/3-review` step 5
     writes the review sentinels into the *worktree* copy. Overwriting it from the primary
     checkout would clobber those sentinels — `skills/3-review/SKILL.md:18` already warns
     about exactly this. Excluding it is not an optimisation, it is the point.
   - **No subdirectories.** Do not recurse.
   - **No dotfiles.** `scripts/codex-review.sh:92` creates `mktemp "$root/work/$slug/.codex-review.XXXXXX"`
     in that very directory, cleaned by an EXIT trap that a SIGKILL defeats. Syncing dotfiles
     would commit reviewer garbage.
2. **Copy every in-scope file unconditionally** — no "skip if it already exists" comparison.
   A second sync must refresh a `notes.md` that a followup round rewrote.
3. **Stage the directory, not each file:** `git add -- work/<slug>`. This matters: `.DS_Store`
   is gitignored, and `git add` of an explicitly-named ignored path FAILS, which under
   `set -euo pipefail` would abort the whole subcommand. Staging the directory lets git skip
   ignored strays silently.
4. **Commit only if something is staged.** `worktree.sh` runs under `set -euo pipefail` and
   `git commit` with nothing staged exits non-zero, which would abort the script. Gate the
   commit on `git diff --cached --quiet` failing. Do NOT use `|| true` — it would also swallow
   real failures. Exit 0 having committed nothing when there is nothing to do.
5. **Refusals** (non-zero exit, clear message on stderr):
   - no worktree exists for `<slug>`
   - the primary checkout has no `work/<slug>/` directory
   - `<slug>` argument missing (match the existing `add`/`remove` usage style)
6. **Leave the worktree clean.** `git status --porcelain` in the worktree must be empty
   afterwards, so `scripts/release.sh`'s `check_clean_worktree` still passes.

### Constraints specific to this script

- `worktree.sh` must only ask git (`git worktree`, `git rev-parse`) and never inspect `.git`
  directly — it runs from inside worktrees where `.git` is a file. ARCHI names this as a
  property to preserve. Find the existing worktree path the way the script already does.
- Update the usage header comment block at the top of the file, and the `usage:` line in the
  `*)` case, to include the new subcommand.
- `scripts/fan-exec.sh:38` already does `cp -R "$ROOT/work/$slug" "$wt/work/"` — a related but
  deliberately different operation (it seeds a whole directory uncommitted). Do not refactor
  it or try to share code with it.

## Skill call sites

Add a call to `scripts/worktree.sh sync-artifacts <slug>` in three skills. Keep the prose
minimal and in the surrounding voice — one clause or one short step, not a paragraph:
- `skills/2-implement/SKILL.md` — after dispatch, once `notes.md` exists.
- `skills/3-review/SKILL.md` — at step 5, alongside the existing in-place plan commit.
- `skills/4-release/SKILL.md` — at the start, before `scripts/release.sh` runs.

Three call sites because `/3-review` step 5 only fires on double-APPROVE; a unit escalated at
the 3-round cap would otherwise lose its handoff, notes, and followups.

## Testing

The plan's acceptance criteria list fourteen items; each is meant to be a test or a check.
Build hermetic fixture repos in a temp dir, following the established pattern in
`tests/test-scripts.sh` (see the `worktree.sh add` seed cases and the gate fixtures).

**Read `knowledge/test-helper-contract.md` before writing cases.** It documents what each
helper actually asserts (`check` / `check_fails` / `check_exit`), the two vacuity shapes that
have cost this repo review rounds, and the bidirectional environment hazard — the suite runs
nested inside `scripts/gate.sh` via the `gate.d/` hook, so set any environment per-command and
never `export` it.

**Mutation requirement** (2026-08-27 decision in PLAN.md): for each new test, break the
corresponding behavior in `worktree.sh`, confirm the test goes red, restore. Report what you
observed. A test asserting a guard exists is not done until it has been shown to fail with
that guard removed — note especially that a fixture too impoverished to exhibit the behaviour
produces a test that cannot fail.

Update ARCHI.md's Verification check count to whatever the suite reports when you are done
(currently 105); `release.sh` checks ARCHI freshness and the count is a release-checked artifact.

## When done

1. Run `bash scripts/gate.sh` from the repo root — it must pass.
2. Confirm `git diff main...HEAD -- scripts/release.sh` is empty.
3. Commit your work on this branch with a clear message.
4. Print a final summary: what changed and why, criteria partially met (if any), out-of-scope observations.
