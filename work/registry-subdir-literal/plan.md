# Registry subdir literal paths

**Slug:** registry-subdir-literal · **Date:** 2026-11-25 · **Status:** implemented

## Goal

`harness register --subdir` writes the subdir into two places that git reads as patterns (`work/harness-registry/deferrals.md`). Each failure below was verified in a scratch repo:

- **Missing the real file (`[`).** The exclude line `/app[1]/CLAUDE.local.md` is a glob matching `app1/`, so the real `app[1]/CLAUDE.local.md` shows as untracked.
- **Over-matching siblings (`*`, `?`, `\`).** `/a*b/CLAUDE.local.md` also excludes `axb/CLAUDE.local.md`, `/q?/…` excludes `qx/…`, and `/a\b/…` excludes `ab/…`.
- **The tracked check is a glob pathspec.** With `git ls-files -- 'app[1]/CLAUDE.local.md'`, a tracked `app1/CLAUDE.local.md` makes register die with `CLAUDE.local.md is tracked`. A tracked `axb/…` blocks `--subdir 'a*b'` the same way.

This unit also carries the unreleased small fix 0515dd9 (the codex reviewer runs at `model_reasoning_effort=high`) to the template, and refreshes `ARCHI.md`, which `harness archi-fresh` reports stale at HEAD (`harness/ config.yaml`, from 0515dd9). Done = register handles `[`, `*`, `?` and `\` in subdir names literally, and a release ships it alongside 0515dd9.

## Approach

In `harness/scripts/register.sh`:

1. Build the exclude line from the subdir with each gitignore metacharacter `[ ] * ? \` backslash-escaped (e.g. `sed 's/[][\\*?]/\\&/g'`). The idempotency `grep -qxF` compares against the escaped line, so a re-run still adds no duplicate.
2. Run the tracked check with a `:(literal)` pathspec: `git ls-files -- ":(literal)${subdir:+$subdir/}CLAUDE.local.md"`.

Nothing else reads the subdir as a git pattern (`PROJECT_SUBDIR` is used only as a filesystem path in `lib/project.sh` and `agent-exec.sh`). The default `--name` derivation already rejects these characters (`invalid name; use --name`), so callers pass `--name`. That is unchanged.

Not done:
- Escaping trailing spaces or a leading `#`/`!`. The exclude line always starts with `/` and ends in `/CLAUDE.local.md`, so neither can occur.
- Cleaning up an unescaped line left by an earlier register of a metacharacter subdir. A re-run appends the escaped line beside it. Nobody is known to have hit this, so the stale line is left for hand removal.

## Footprint

Files to modify:
- `harness/scripts/register.sh`
- `harness/tests/test-scripts.sh` (a new case in the registry section)
- `ARCHI.md`: targeted edit to the `register.sh` clause only (literal handling). This also refreshes it past 0515dd9. The reasoning-effort value stays in `config.yaml` and its `PLAN.md` decision line.
- `PLAN.md` (orchestrator: this unit's Now line)

Files NOT to touch:
- `work/harness-registry/deferrals.md`: this is a historical record, and the release note closes it.

## Acceptance criteria

- [ ] Missing-file case: in a fresh repo, `harness register --name x --subdir 'app[1]'` writes the exclude line `/app\[1\]/CLAUDE.local.md`, and `git status --porcelain` is then empty.
- [ ] Over-match cases, each in its own fixture: `a*b`, `q?` and `a\b` each sit beside an untracked sibling (`axb/`, `qx/`, `ab/`, each holding a `CLAUDE.local.md`). After register, `git check-ignore -q '<registered>/CLAUDE.local.md'` succeeds and `git check-ignore -q '<sibling>/CLAUDE.local.md'` fails. `check-ignore` takes each argument as a literal path, so neither quoting nor porcelain's collapsing of untracked folders affects the check.
- [ ] Tracked check: register succeeds with a tracked `app1/CLAUDE.local.md` (`--subdir 'app[1]'`) and with a tracked `axb/CLAUDE.local.md` (`--subdir 'a*b'`). With a tracked `app[1]/CLAUDE.local.md`, it still refuses with `CLAUDE.local.md is tracked`.
- [ ] Re-running register with the same metacharacter subdir leaves exactly one matching exclude line.
- [ ] Each fix is pinned by mutation, re-running the new case after each mutation lands. The reviewer shows the case fails when:
  - the escaping is removed entirely;
  - only the `*` escape is dropped (`sed 's/[][\\?]/\\&/g'`);
  - `:(literal)` is dropped.
- [ ] The existing registry cases (`registry subdir normalization…`, `registry register preflight…`) pass unchanged.
- [ ] `harness archi-fresh wt/registry-subdir-literal` exits 0.
- [ ] `harness gate` passes.

## Release

Release note: `harness register --subdir` treats `[`, `*`, `?` and `\` in the subdir literally: the exclude line is escaped and the tracked check uses a literal pathspec (closes the `harness-registry` deferral). The codex reviewer now runs at `model_reasoning_effort=high`, in this repo's config and the skeleton.

## Demonstration

Runs the branch's dispatcher (`$PWD/harness/bin/harness`), not the installed one, which resolves to the primary checkout's `main`.

```sh
H="$PWD/harness/bin/harness"
d=$(mktemp -d)
trap 'rm -rf "$d"' EXIT
export HARNESS_HOME="$d/hh"
mk() { git -C "$d" init -qb main "$1"; }
commit() { git -C "$d/$1" add -A; git -C "$d/$1" -c user.name=t -c user.email=t@t commit -qm init; }
# Missing-file case plus the tracked-check false positive: app1/CLAUDE.local.md is tracked.
mk repo
mkdir -p "$d/repo/app[1]" "$d/repo/app1"
echo x >"$d/repo/app1/CLAUDE.local.md"
commit repo
(cd "$d/repo" && bash "$H" register --name demo --subdir 'app[1]')
(cd "$d/repo" && bash "$H" register --name demo --subdir 'app[1]') >/dev/null
grep -F 'CLAUDE.local.md' "$d/repo/.git/info/exclude"
echo "status=[$(git -C "$d/repo" status --porcelain)]"
# Over-match case: an untracked sibling axb/ must stay visible.
mk star
mkdir -p "$d/star/a*b" "$d/star/axb"
echo keep >"$d/star/a*b/.keep"
commit star
echo x >"$d/star/axb/CLAUDE.local.md"
(cd "$d/star" && bash "$H" register --name demo2 --subdir 'a*b')
git -C "$d/star" status --porcelain -uall
```
Expected:
- The first repo prints its state dir path (`$d/hh/projects/demo`) and the `/add-dir` hint on stderr. It then prints exactly one exclude line, `/app\[1\]/CLAUDE.local.md`, and `status=[]`.
- The second repo prints `$d/hh/projects/demo2`, the hint, and then exactly `?? axb/CLAUDE.local.md`.

## Review

Plan review round 1: REVISE, with four findings, all applied.
1. The criteria couldn't tell fixed from broken for `*`, `?` and `\`, because their bug is over-matching siblings. The Goal, criteria and mutations now cover sibling folders and a `*`-only mutation.
2. The `config.yaml` sentence was dropped from the ARCHI edit.
3. The demo's first register now keeps stderr, so a failure shows its message.
4. Old unescaped lines are not cleaned up; recorded under Not done.

Plan review round 2: APPROVE, with three findings, all applied.
1. The over-match criterion now uses `git check-ignore` rather than porcelain text.
2. The demo adds an over-match repo (`a*b` beside an untracked `axb/`).
3. The demo cleans up with `trap` and keeps stderr on both register calls.
Plan verdict: APPROVE

Code review round 1: both reviewers APPROVE. The code-reviewer ran the plan's three mutations plus four more (dropping the `?`, `\` or `[]` escapes, and disabling the idempotency grep); each one failed the new case. It also checked the released range (0515dd9) against the release note. Codex: no findings. Three LOWs were left as they are:
1. `GIT_LITERAL_PATHSPECS=1` in the caller's environment would turn `:(literal)` into a literal prefix. The `foreign CLAUDE.local.md` check still refuses, so this was not worth changing.
2. The `PLAN.md` Now line is added at release.
3. The demo's second register also prints the `/add-dir` hint on stderr.

Code-review verdict: APPROVE
Codex-review verdict: APPROVE
