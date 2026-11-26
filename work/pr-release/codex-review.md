1. **HIGH — Registry release instructions can push after a failed gate.** In [4-release/SKILL.md](/Users/cboyfly/Documents/repos/agentic-coding/harness/skills/4-release/SKILL.md:12), step 1 tells the orchestrator to run `harness release`, fill in `pr.md`, push, and open the PR. The instruction to stop on a nonzero exit appears only in step 2. If release refuses because the branch moved or the gate failed, following the steps in order can push and open the PR before reacting to that refusal. Move the exit-code check immediately after the release command, before the PR actions.

2. **MEDIUM — Refusal tests do not enforce their expected exit status or message.** In [test-scripts.sh](/Users/cboyfly/Documents/repos/agentic-coding/harness/tests/test-scripts.sh:2662), `[[ $status -ne 0 ]] && grep ...` is an AND list whose failure is followed by other commands. Under `set -e`, a failed first test in that list does not terminate the function; a missing expected message also does not necessarily determine its final status. Consequently, a refusal can emit the wrong message and still pass its case. Make the status and message checks independently fatal.

The read-only environment prevented running the gate and the required mutation checks.

Codex verdict: REQUEST CHANGES
