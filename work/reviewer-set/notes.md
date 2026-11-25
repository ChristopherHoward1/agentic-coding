# Notes — reviewer-set

## Implementer summary

Implemented the mode-specific review transition. Registry units now move to release after code-review approval, and an existing review-round directs either mode to `/3-review`. Updated the refusal message, skill guidance, architecture notes, and tests.

`harness gate` passed, including shellcheck; `harness archi-fresh wt/reviewer-set` passed, and the placeholder search returned no matches. The mutation-pin runs are designated for the reviewer and were not performed here. No out-of-scope changes were made.

## Gate

GATE: PASS (passed: 282 / 6, failed: 0); archi-fresh exit 0.

## Demo

```
stage: review
next_action: run harness gate
next_action: /3-review
stage: release
review: approve
next_action: /4-release
codex-review: registry mode has no codex reviewer; /3-review uses the code-reviewer only
codex-review exit=2
```
