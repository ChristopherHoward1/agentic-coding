# Template sync — keep the GitHub template repo equal to the export

**Slug:** template-sync · **Date:** 2026-10-09 · **Status:** approved

## Goal

`scripts/export-template.sh` (v2026.10.2) writes a clean template tree, but nothing publishes it. The template-export plan left that out of scope as an outward-facing step for the Owner. `ChristopherHoward1/agentic-coding-template` already exists. It is public, not flagged as a template, has a protected `main`, and holds an older, unrelated version of the framework (`conventions/`, numbered-PR planning history). The Owner decided on 2026-10-09: keep that repo and its URL, and replace its tree with the export in one ordinary commit, so the old history stays in `git log`. After that, every release refreshes it.

Done means: `scripts/sync-template.sh` takes no arguments. It clones the template repo itself and makes a commit, on a sync branch, that makes its tree byte-equal to `export-template.sh` output for the released `HEAD`. It does nothing when the tree is already equal, and it never pushes. `/4-release` runs it after the tag push, then pushes the branch and opens a PR. The template repo is flagged as a GitHub template.

## Approach

1. **`scripts/sync-template.sh`** (new, takes no arguments, dogfood-only, export-ignored):
   - It refuses with exit 1 and a message in two cases:
     - any argument is given
     - `HEAD` doesn't carry the tag `v$(cat VERSION)` (`git tag --points-at HEAD | grep -qx "v$version"`); only released states are published
   - It clones `TEMPLATE_REPO` into a fresh `mktemp -d` clone directory. `TEMPLATE_REPO` is a constant in the script, `https://github.com/ChristopherHoward1/agentic-coding-template.git`, and an env var overrides it; tests point it at a local fixture repo. The repo name lives only in this export-ignored script, so it never ships to consumers. A fresh clone can't be dirty or already have the sync branch, so no `<clone-dir>` argument and no checks for those.
   - It exports into a separate `mktemp -d` export directory with `scripts/export-template.sh`, and always deletes that directory (trap). The clone directory is never trap-deleted.
   - In the clone it runs `git switch -c template-sync/v<version>`, `git rm -rq --ignore-unmatch .`, copies the export with `cp -R "$exp/." "$clone/"`, then `git add -Af`. The `-f` keeps a tracked file that matches the exported `.gitignore` from being dropped.
   - If `git diff --cached --quiet`, it deletes the clone directory, prints `up to date` and exits 0. Otherwise it commits `Sync from agentic-coding v<version> (<short-sha>)` and prints the clone path and branch name on two lines, exit 0. The clone path stays on disk for the push. A tooling failure exits 2. It never pushes.
2. **`.gitattributes`**: add `scripts/sync-template.sh export-ignore`.
3. **`skills/4-release/SKILL.md`**: insert step 5 after the tag push and renumber `/5-retro` to step 6. Step 5 has two parts:
   - **Unconditional:** delete the matching untracked `work/<slug>/` copies, then `git pull --ff-only`. This replaces the Rules line, so consumers keep the post-merge pull.
   - **Conditional**, because the skill ships to consumers, who have no sync script:
     > If `scripts/sync-template.sh` exists, confirm `HEAD` carries `v<version>`, then run `bash scripts/sync-template.sh`.
     >
     > - `up to date` → nothing to do.
     > - A printed branch → work from the printed clone, so `gh` resolves the template repo:
     >   1. Push the branch with `--force-with-lease`, so a retry replaces an earlier failed attempt.
     >   2. `gh pr create` against `main`.
     >   3. `gh pr list` / `gh pr close` any older open `template-sync/*` PR as superseded.
     >   4. Merge once CI is green (full TRIP, as with the release PR).
     > - Red template CI → report it and leave the PR open. The release is already done and stays done.
4. **Tests in `tests/test-export.sh`** (already export-ignored and gate-wired). Each case uses the existing `fixture` repo tagged `v$(cat VERSION)` as the source. It also uses a bare "template" fixture repo whose `main` holds stale files (`conventions/x`, an old `README.md`), with `TEMPLATE_REPO` pointing at that bare repo. The cases:
   - (a) First sync:
     - The commit lands on `template-sync/v<version>` with the expected subject.
     - `git rev-parse HEAD^{tree}` in the printed clone equals the tree hash of a scratch repo where a fresh `export-template.sh` of the fixture was committed. This pins byte-equality, including modes and symlinks.
     - `HEAD~1` equals the bare repo's original `main` tip.
     - The printed clone path still exists after the script exits.
     - The bare repo's refs (`git for-each-ref`) are unchanged, which pins "never pushes".
   - (b) No-op: fast-forward the bare repo's `main` to the (a) commit, then run again with `TMPDIR` set to a fresh empty directory. It prints `up to date` and creates no commit or branch in the bare repo. That `TMPDIR` is empty afterwards, which pins both the export trap and the no-op clone cleanup.
   - (c) Exits 1 when `HEAD` lacks `v<VERSION>`. A positive variant: `HEAD` carries both `v<VERSION>` and `other-tag`, and the sync succeeds. Together with the lightweight fixture tag in (a), this pins `--points-at` over `describe --exact-match`.
   - (d) Exits 1 when given an argument.
   - Every sync case runs the fixture's own copy of the script (`cd "$repo" && bash scripts/sync-template.sh`), never `$ROOT`'s, so the tag check reads the fixture's `HEAD`.
5. **`ARCHI.md`**: a targeted branch refresh that adds `sync-template.sh` to the `scripts/` line and to Key flows.

Alternatives considered:
- A `--sync` mode on `export-template.sh`: it mixes the pure export with git mutation of another repo.
- A `<clone-dir>` argument: it adds dirty-clone and existing-branch handling, and the gate couldn't exercise the real clone path. The env override covers testing.
- Force-pushing a fresh single-commit history to the template repo's `main`: destructive. The Owner chose replace-in-place.
- The template repo slug in `config.yaml`: it would ship to consumers.

Out of scope:
- One-time, Owner-approved repo settings (`gh repo edit --template`, refreshing the description). These run in this unit's `/4-release`, not in code.

## Footprint

Files to modify:
- `scripts/sync-template.sh` — new
- `.gitattributes` — one export-ignore line
- `tests/test-export.sh` — sync cases (a)–(d)
- `skills/4-release/SKILL.md` — new step 5, renumbering, Rules pull line folded into step 5
- `ARCHI.md` — targeted branch refresh

Files NOT to touch:
- `scripts/export-template.sh`: consumed as-is. If its behavior is wrong for syncing, stop and report.
- `scripts/release.sh`: sync is a post-tag step, not a release precondition.

## Acceptance criteria

- [ ] `bash scripts/gate.sh` exits 0, and `tests/test-export.sh` output shows sync cases (a)–(d) as `ok`.
- [ ] Every guard is pinned. Each of these mutations, verified as landed, fails a named case, recorded in `work/template-sync/mutations.md`:
  - removing the tag check
  - swapping `--points-at` for `describe --exact-match`
  - removing `git rm`
  - removing the no-op clone cleanup
  - trap-deleting the clone directory
  - adding a `git push`
- [ ] `git check-attr export-ignore scripts/sync-template.sh` reports `set`, and the existing export `success` case still passes.
- [ ] `grep -rn 'agentic-coding-template' skills config.yaml CLAUDE.md` finds nothing.
- [ ] `skills/4-release/SKILL.md` step 5's cleanup and `git pull --ff-only` sit outside the `sync-template.sh` condition (checked by reading the diff), and the Rules pull line is removed.
- [ ] Step 5's conditional part contains the tag confirmation, running `gh` from the printed clone, the force-with-lease push, closing superseded PRs, merge-on-green, and red-CI handling.
- [ ] In this unit's `/4-release`: the first sync PR's CI is green and it is merged, and `gh repo view ChristopherHoward1/agentic-coding-template --json isTemplate` reports `true`.

## Release

Release note: `scripts/sync-template.sh` keeps the GitHub template repo in step with the export. Each release opens a sync PR, which merges once its CI is green.

## Demonstration

This runs the real script, through its real clone path, against the real template repo. It writes only under `mktemp -d`, and never pushes. The branch `HEAD` is not tagged before release, so the demo runs from a throwaway clone of the branch and force-tags `v<VERSION>` only inside that clone.

```sh
d=$(mktemp -d)
git clone -q -b "$(git branch --show-current)" "$PWD" "$d/src"
git -C "$d/src" tag -f "v$(cat VERSION)" >/dev/null
out=$(cd "$d/src" && bash scripts/sync-template.sh); echo "exit=$?"
clone=$(head -1 <<<"$out")
git -C "$clone" log --oneline -2
echo "parent=$(git -C "$clone" rev-parse HEAD~1) template_main=$(git -C "$clone" rev-parse origin/main)"
(cd "$d/src" && bash scripts/export-template.sh "$d/exp" >/dev/null)
git -C "$d/exp" init -q && git -C "$d/exp" add -A
echo "synced=$(git -C "$clone" rev-parse 'HEAD^{tree}') export=$(git -C "$d/exp" write-tree)"
git -C "$clone" diff --stat HEAD~1 -- conventions | tail -1
```
Expected: `exit=0`. The log shows a `Sync from agentic-coding v<version>` commit. `parent=` equals `template_main=`. The `synced=` and `export=` tree hashes are equal. The diff stat shows the old `conventions/` files deleted.

## Review

Plan-reviewer round 1: REVISE (8 findings). All applied:
1. Step 5 fast-forwards and confirms the tag before syncing.
2. The re-run/branch-exists problem is gone because each run starts from a fresh clone. Case (b) setup is now explicit.
3. The temp lifetimes are specified: the export dir is deleted, and the clone dir is kept and printed.
4. Tree-hash equality replaces `diff -r`.
5. The `<clone-dir>` arg is dropped in favor of the `TEMPLATE_REPO` env override.
6. The orchestrator merges the sync PR on green CI, and supersedes older sync PRs.
7. Template CI must be green. Red CI leaves the PR open and doesn't affect the release.
8. `--points-at`, the parent check, and the refs-unchanged no-push pin are in.

No disagreements.

Plan-reviewer round 2: REVISE. All 8 round-1 findings were confirmed resolved. The reviewer also confirmed that the template's branch protection allows the orchestrator to merge, and that an exported `HEAD` passes the template's smoke suite (201/0). It raised four new one-line findings, all applied:
1. "Done means" now describes a script that takes no arguments.
2. Case (b) checks no-op cleanup through an empty `TMPDIR`.
3. Case (c) gains a positive multi-tag variant that pins `--points-at`.
4. The sync cases run the fixture's own copy of the script.

Plan-reviewer round 3: REVISE. All 4 round-2 fixes were confirmed resolved, and 4 new findings were raised, all applied:
1. HIGH: putting the pull under the sync condition would have dropped the post-merge `git pull --ff-only` for consumers. The cleanup and pull are now unconditional, and a criterion pins that.
2. The script uses `git add -Af`.
3. Step 5 runs `gh` from the printed clone.
4. The demo clones with an explicit `-b` and prints the parent next to `origin/main`.

No round-4 review was run. The Owner approved the plan on 2026-10-09 with the round-3 fixes applied.
Plan verdict: REVISE
