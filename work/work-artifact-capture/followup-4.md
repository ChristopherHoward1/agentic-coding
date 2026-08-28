Round-4 review findings on work/work-artifact-capture/plan.md. You are resuming in the same worktree on branch wt/work-artifact-capture.

**The Owner has authorized a fifth round.** Codex returned APPROVE this round; the Claude reviewer returned REVISE with two blocking findings, both of which the orchestrator independently reproduced. Your round-4 work was otherwise verified sound — the reviewer mutation-tested eleven mutants and every new guard has a test that fails when it is broken.

Three fixes. Do not redesign anything else.

## Finding 1 (blocking) — the exclusion pathspec is cwd-relative, so a subdirectory invocation silently truncates the reviewer's diff

`scripts/codex-review.sh:82`:

    git diff "main...$branch" -- . ":(exclude)work/$slug" >>"$prompt"

`.` means the current working directory. The script computes `root` but deliberately never `cd`s — it supports being run from anywhere, and before this change `git diff main...$branch` was cwd-independent. Now it is not. Reproduced in a scratch repo: with a branch changing both `TOPFILE.md` and `sub/a.txt`, running from `sub/` produces a diff containing **only** `sub/a.txt`; from the root it contains both.

Why this is blocking: Codex receives a diff missing most of the change, finds nothing objectionable, exits 0, and `/3-review` mechanically records `Codex-review verdict: APPROVE` over a diff that was never shown. It fails **silently** — `die2` fires only on a git error, and a short diff is not an error. That is the same class of defect this unit exists to close, inverted.

Fix (verified equivalent from both root and subdirectory):

    git diff "main...$branch" -- ':/' ":(exclude,top)work/$slug" >>"$prompt"

`:/` anchors to the repo root; `,top` makes the exclusion root-relative too. Keep the existing `|| die2`. Alternatively `cd "$root"` after line 23 — pick one, but the pathspec form is the smaller change.

Test gap to close: every codex-review check in `tests/test-scripts.sh:554-600` invokes via `cd '$COD_PRIMARY' && …`, so only the root case is exercised. Add a subdirectory invocation of the existing `capture-prompt` fixture asserting a top-level change still appears in the built prompt.

## Finding 2 (blocking) — a non-ASCII artifact filename fails the sync and leaves the worktree staged-dirty, blocking the release

`scripts/worktree.sh:85-90`. `git diff --cached --name-only` C-quotes non-ASCII paths (`core.quotePath` defaults on), and the quoted string is then fed back as a literal pathspec. Reproduced against the real script on this branch:

    $ printf 'accented\n' > work/work-artifact-capture/résumé.md
    $ bash scripts/worktree.sh sync-artifacts work-artifact-capture
    error: pathspec '"work/work-artifact-capture/r\303\251sum\303\251.md"' did not match any file(s) known to git
    exit=1
    $ git -C <worktree> status --porcelain
    A  "work/work-artifact-capture/r\303\251sum\303\251.md"     ← staged, left behind

`git add` has already run when the failure hits, so the worktree is left dirty. At the `/4-release` call site the very next command is `release.sh`, whose `check_clean_worktree` then refuses — so the plan's "no new way for a release to fail" and the "leaves the worktree clean" criterion both have a hole. Reachable whenever any artifact under `work/<slug>/` carries an accented character or a typographic dash.

Fix — drop the filenames-as-text round-trip entirely and use pathspecs on both the guard and the commit:

    git diff --cached --quiet -- "work/$slug" ":(exclude)work/$slug/plan.md" \
      || git commit -q -m "Record artifacts for $slug" -- "work/$slug" ":(exclude)work/$slug/plan.md"

This removes the `staged_paths` array and its name/semantics mismatch (`git commit -- <paths>` is a partial commit taking worktree content, not the index, so the array never described what was actually committed). Confirm the existing mutants still fail after the rewrite — particularly the unscoped-commit and idempotency ones.

Add a test: an artifact with a non-ASCII filename syncs successfully, is committed, and leaves the worktree clean.

## Finding 3 — nothing mechanically keeps the two exclusion sites in sync

The exclusion now lives in `scripts/codex-review.sh` and in `skills/3-review/SKILL.md:12`. The suite pins the script (a mutation there fails a test) and pins nothing about the skill. If a future `/compact` or edit drops the pathspec from step 1, the Claude reviewer starts seeing handoffs, followups, and the prior codex review again — and the gate stays green.

`tests/test-scripts.sh:548-551` already greps `codex-review.sh` for invariant strings. Add one analogous grep over `skills/3-review/SKILL.md` asserting step 1 still carries the exclusion.

## Explicitly declined — do NOT fix

- The dead `":(exclude)…/plan.md"` in the `--name-only` query — the rewrite in finding 2 removes it anyway.
- `git commit -- <paths>` partial-commit semantics as a standalone concern — finding 2's rewrite makes the intent explicit, which is enough.
- Reconciling the "leaves the worktree clean" criterion with "pre-existing plan dirt stays pending" — the orchestrator will amend that criterion's wording when recording verdicts. Leave the plan's criteria list alone this round except where finding 2 changes behavior.

## Nit — take it

`skills/2-implement/SKILL.md:19` packs the retry cap and the sync call into one sentence, so "up to `gate.max_retries`" now reads as an afterthought. Split it.

## Constraints (unchanged)

- `set -euo pipefail`; commit gated on `git diff --cached --quiet`, never `|| true`.
- `worktree.sh` only asks git, never inspects `.git` directly.
- Tests set environment per-command, never `export`. See `knowledge/test-helper-contract.md`.
- Mutation requirement on every new/changed test, and **assert the mutation actually landed before trusting a green run** — a false green from an unapplied mutation has already bitten twice in this unit.
- `scripts/release.sh` stays byte-identical.
- Update ARCHI's check count to whatever the suite reports (currently 132).

## When done

1. `bash scripts/gate.sh` from the repo root — must pass.
2. `git diff main...HEAD -- scripts/release.sh` empty.
3. Confirm the prompt `codex-review.sh` builds contains the full change when invoked from a subdirectory.
4. Confirm a non-ASCII artifact filename syncs and leaves the worktree clean.
5. Commit on this branch.
6. Print a summary: what changed, what you observed during mutation checks, anything still open.
