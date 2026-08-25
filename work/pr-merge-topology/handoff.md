You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.

Work unit: work/pr-merge-topology/plan.md  (read it in full; it is your source of truth)
Branch: wt/pr-merge-topology (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

## What this change does

Collapse the two release topologies (`self` direct-push-to-`main` and `platform-team` PR-merge) into ONE universal PR-merge topology, and remove the `review.human_pr_review` config knob entirely. `scripts/release.sh` must never touch `main` and never tag. Automatic tagging survives via a NEW `scripts/release.sh tag-after-merge <slug>` subcommand that `/4-release` runs after the PR merges. The plan is authoritative — follow its Approach and Acceptance criteria exactly.

Footprint (the hard boundary — do not modify files outside this list):
- `scripts/release.sh` — remove the `self` path, `human_pr_review_mode()`, `check_ff_possible()`, the `git tag`/tag-exists check, the `git -C "$main_checkout" merge --ff-only`; drop the two `check_clean_worktree "$main_checkout"` calls (keep the `worktree_for_branch main` existence lookup); simplify `rollback_release` to just reset the branch HEAD (no tag deletion); rewrite `usage()` so no "self-review"/"platform-team" prose survives. ADD a `tag-after-merge <slug>` subcommand (see constraints).
- `config.yaml` — remove the `review:` block entirely.
- `.claude/skills/4-release/SKILL.md` — single Owner-confirmed push of the release BRANCH (never `main`); add a post-merge tag phase that runs `bash scripts/release.sh tag-after-merge <slug>` then, Owner-confirmed, `git push origin v<version>`.
- `profiles/work.md` — delete the "Review topology" declaration, both topology sections, the platform-team sync subtlety, and the manual-tag section. Keep only: the Claude implementer runtime/command, the Bitbucket Pipelines CI swap, and the Jira reference-only stance. Release topology is now base behavior — a one-line pointer to the base flow is enough.
- `CLAUDE.md` — invariant #5 wording only: `release.sh` no longer creates a tag or fast-forward-merges `main`. New sense: it owns preconditions, versioning, changelog assembly, and the release commit on the branch; it never pushes and never touches `main`; tagging happens in `/4-release` after the PR merges (via `tag-after-merge`).
- `tests/test-scripts.sh` — see constraints.

Do NOT touch: `ARCHI.md` (regenerated later by `/compact`), `.claude/skills/init/SKILL.md`, `scripts/agent-exec.sh`, `scripts/worktree.sh`, `scripts/gate.sh`, `bitbucket-pipelines.yml`, `work/**` other than this unit.

## Key constraints

1. **`release()` single flow** — after removing the `self` branch, `release()` runs the shared preconditions and calls `check_origin_main_ancestor` BOTH before and after `check_gate` (this is the existing collision guard — leave its double-call intact), commits the `VERSION`+`CHANGELOG.md` bump on `wt/<slug>`, creates NO tag, and never merges/touches `main`. Print the branch-push/PR guidance message. Keep `next_version` read once off the branch `VERSION`.

2. **`tag-after-merge <slug>` subcommand** — must:
   - `git fetch origin main`.
   - Read the release branch's `VERSION` → `<version>`.
   - VERIFY `origin/main`'s tip is actually this release: the tip commit's tree has `VERSION` == `<version>` AND the tip commit's subject is exactly `Release v<version>`. If not, `die` with a clear message (this prevents tagging the wrong commit when another PR merged to `origin/main` between the merge and the fetch).
   - Refuse if tag `v<version>` already exists.
   - Create the tag `v<version>` on the `origin/main` tip, LOCALLY. Do NOT push — there must be NO `git push` anywhere in `release.sh`. The push is the orchestrator's job in `/4-release`.
   - Read `origin/main`'s VERSION content via `git show origin/main:VERSION` (or equivalent); read its subject via `git log -1 --format=%s origin/main`.

3. **`invariant #5 / never pushes`** — `release.sh` must contain no `git push`. Verify with grep before finishing.

4. **Tests** (`tests/test-scripts.sh`):
   - Drop `setup_release_fixture`'s `review_mode` parameter (currently `local review_mode="${6:-self}"`) and stop writing the `review:`/`human_pr_review:` block into the fixture `config.yaml`.
   - DELETE the self-only tests: `release-happy` (asserts ff-merge into main + tag), `release-tag-race-rolls-back`, and remove the tag expectation from `release-happy-primary`.
   - PROMOTE the three `release-platform-*` tests to be THE canonical release tests (rename their descriptions off "platform-team"; drop the trailing `platform-team` fixture arg): happy = bump-commit-on-branch + `main` unchanged + `origin/main` unchanged + no `v<version>` tag; keep the sequential-collision test (stale branch refused with the `rebase/sync` message, then next micro after sync) and the mid-gate test (competing push to `origin` during the gate caught by the post-gate re-check).
   - Keep the mode-agnostic refusal tests (no-verdict, gate-fails, archi-stale, version-regresses) and a "runnable from primary checkout" variant (without the tag assertion).
   - ADD `tag-after-merge` coverage: (a) HAPPY — after the bump commit is pushed to `origin/main` (simulating the merged PR), `tag-after-merge` creates `v<version>` locally on the `origin/main` tip and pushes nothing; (b) WRONG-COMMIT REFUSAL — `origin/main` has advanced one commit past this release's bump (subject/VERSION no longer match), so `tag-after-merge` dies without creating the tag.

## When done
1. Run `scripts/gate.sh` from the repo root — it must pass (shellcheck + the smoke suite including your new tests).
2. Commit your work on this branch with a clear message.
3. Print a final summary: what changed and why, any acceptance criteria only partially met, and any out-of-scope observations. If you believe the footprint must expand, STOP and report it rather than editing outside the list.
