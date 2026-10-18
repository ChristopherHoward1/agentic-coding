Implemented install, contract piping, configurable architecture sources, removals, and documentation updates. All four mutation checks are recorded in [mutations.md](work/harness-install/mutations.md).

Validation: shellcheck passes; disposable committed fixture passes all 224 script cases, 12 export cases, gate, and freshness check.

**Pending:** root gate/export checks remain blocked because the untouched index still lists deleted files. Changes remain unstaged; commit and installed-copy demo were skipped under the index constraint. No additional out-of-scope findings.

Ran the Demonstration block directly:

```text
Note: add /var/folders/y6/cqq_kqw13z58pgr6c9f3fzdm0000gn/T/tmp.fV7fpmGPdH/.local/bin to PATH
install_exit=0
skills: 1-plan 2-implement 3-review 4-release 5-retro compact docs init
agents: code-reviewer.md fan-selector.md plan-reviewer.md
root=/Users/cboyfly/Documents/repos/agentic-coding-worktrees/harness-install/harness
rerun_exit=0
Error: refusing to replace non-symlink: /var/folders/y6/cqq_kqw13z58pgr6c9f3fzdm0000gn/T/tmp.fV7fpmGPdH/.claude/agents/plan-reviewer.md
conflict_exit=1
dispatch_exit=0
# Implementer Contract
1
sep_line=32 contract_lines=31
ARCHI.md is stale at HEAD; newer source path(s): src/; refresh ARCHI on the branch
archi_exit=1
```
