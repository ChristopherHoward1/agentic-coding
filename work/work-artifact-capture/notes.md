# Implementer notes — work-artifact-capture

Runtime: codex (`codex exec --sandbox workspace-write`), fan=1, single dispatch, no followup rounds.
Commit: `63bdd72 Capture work artifacts in worktrees` on `wt/work-artifact-capture`.

## Implementer summary (verbatim)

What changed:
- Added `scripts/worktree.sh sync-artifacts <slug>`.
  - Copies top-level regular non-dot files from primary `work/<slug>/`.
  - Excludes `plan.md`.
  - Stages `work/<slug>` as a directory.
  - Commits only when staged changes exist.
  - Refuses missing slug, missing worktree, or missing primary work dir.
- Added the three skill call sites in `/2-implement`, `/3-review`, and `/4-release`.
- Added hermetic `sync-artifacts` tests covering artifact copy, plan preservation, refresh, idempotency, dotfile/subdir exclusion, ignored `.DS_Store`, refusals, and clean worktree.
- Updated `ARCHI.md` and the verification count to `117`.

Verification:
- `bash scripts/gate.sh` passed: `117` checks, `0` failed.
- `git diff main...HEAD -- scripts/release.sh` is empty.
- Working tree is clean after commit.

Mutation checks observed:
- Removing missing-slug guard failed the usage stderr test.
- Removing missing-primary guard failed the missing primary directory refusal.
- Allowing `plan.md` copy failed sentinel preservation.
- Allowing subdirectories or dotfiles failed the exclusion test.
- Removing the staged-diff commit guard failed the idempotent no-op test.
- Adding skip-if-present failed refreshed `notes.md`.

No acceptance criteria are partially met. I did not touch the forbidden files.

## Orchestrator verification (independent of the implementer's claim)

| Check | Result |
|---|---|
| `bash scripts/gate.sh; echo $?` in worktree | `0` |
| Suite count | 117, up from 105 (12 new) |
| `git diff main...HEAD -- scripts/release.sh` | empty — byte-identical criterion holds |
| Footprint | exactly the 6 declared files + `plan.md` recorded by `worktree.sh` |
| Worktree clean after commit | yes (`git status --porcelain` empty) |
| `worktree.sh` growth | +16 lines, close to the ~8-line target in the plan |

Dogfooded: this unit's own `handoff.md` and `notes.md` reached the branch via the new
`sync-artifacts` subcommand rather than a manual catch-up commit — the first unit for which
that is true.
