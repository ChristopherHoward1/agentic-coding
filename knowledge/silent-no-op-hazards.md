# Silent no-ops: cwd- and checkout-dependence

Cited when writing or reviewing a script that resolves paths, or when mutation-testing a guard.
Not hot context.

Written after `work-artifact-capture` (v2026.8.11) hit the same failure family **four times in one
unit** — three in the code under review, one in the orchestrator's own dispatch. Six review rounds;
the suite was green through all of them.

## The family

A command runs, does nothing or does less than intended, and **exits 0**. Nothing fails, so nothing
alerts. This is worse than a crash in exactly the places the loop trusts an exit code.

The four instances, all from one unit:

| Instance | Symptom |
|---|---|
| `sync-artifacts` run from inside the worktree | `ROOT` resolved to the worktree, copied nothing, exit 0 |
| `codex-review.sh` diff pathspec `--  .` | From a subdirectory, reviewer's diff silently truncated |
| Same pathspec missing `,top` on the exclude | Exclusion stopped matching; eight artifact files leaked back in |
| `scripts/agent-exec.sh` with a stale shell cwd | Dispatch never ran; outer command still reported exit 0 |

The third one is the sharpest: a reviewer receives a diff missing most of the change, finds nothing
objectionable, exits 0, and the loop **mechanically records an APPROVE over a diff that was never
shown**. An empty or short diff is not a git error, so `die`-style handling never fires.

## The idioms that fix them

- **Anchor pathspecs to the repo root, not the cwd.** `git diff … -- ':/' ':(exclude,top)work/<slug>'`.
  `:/` includes from the root; **`,top` is required** on the exclude or it gets the cwd prefix applied
  and quietly stops matching. Verify by comparing output from the root and from a subdirectory —
  identical, or the anchor is wrong.
- **Ask "am I in the primary checkout", not "where is `main`".**
  `[[ "$(git rev-parse --git-dir)" == "$(git rev-parse --git-common-dir)" ]]` is true only in the
  primary checkout, and is immune to whichever branch happens to be checked out. Resolving by branch
  name instead gives both false refusals (a small fix left on a branch blocks a release) and false
  acceptances (`main` checked out in a linked worktree).
- **`cd "$ROOT"` early**, as `worktree.sh` does, or accept that every relative path in the script is
  caller-dependent. Do not do half of this.
- **Dispatch with absolute paths.** Shell cwd persists across an orchestrator's commands; a relative
  `scripts/…` resolves against wherever the last probe left it.
- **Filenames are not text.** `git diff --cached --name-only` C-quotes non-ASCII paths, and feeding
  those back as pathspecs fails (`pathspec '"work/…/r\303\251sum\303\251.md"' did not match`) —
  after `git add` has already run, so the tree is left dirty. Use a pathspec on both the guard and
  the commit instead of round-tripping through filenames.

## Assert your mutation actually landed

Mutation testing is the only thing that has caught vacuous tests in this repo — but a mutation that
*fails to apply* produces a false green indistinguishable from a passing guard. This happened
**twice** in one unit, nearly letting both a vacuous test and an unpinned guard ship.

Before trusting red-or-green, prove the edit is in the file:

    # after editing, assert the old text is gone and the new text is present
    grep -c 'exclude,top' scripts/codex-review.sh   # expect 0 after mutating it out
    git diff --stat                                  # expect a non-empty diff

A reviewer's `sed`/`python3` replace that silently matched nothing looks exactly like a well-pinned
guard. The check costs one line.

## Two vacuity shapes seen here

Both are in `knowledge/test-helper-contract.md` too; repeated because this unit produced one of each.

1. **A fixture too impoverished to exhibit the behaviour.** A case asserted the gate aborts *before*
   running checks, by grepping for the absence of a run marker — in a fixture with no runnable tool,
   where no implementation could ever print one.
2. **An assertion the environment satisfies regardless.** A `.DS_Store` placed in the *worktree* was
   asserted absent from the tree — but gitignore excludes it under every implementation, so the
   staging strategy it was meant to pin had no test behind it at all. The fix was a *non-dot*
   gitignored stray in the *primary* directory.
