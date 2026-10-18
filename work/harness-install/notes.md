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


## Discovery check (orchestrator, end of /2-implement, 2026-10-18)

Installed from the worktree, then ran `claude -p` from a non-harness `mktemp -d`. All 3 harness agents and all 8 harness skills were discovered through per-file links.

```
agent:claude
agent:code-reviewer
agent:Explore
agent:fan-selector
agent:general-purpose
agent:Plan
agent:plan-reviewer
agent:statusline-setup
agent:fork
skill:1-plan
skill:2-implement
skill:3-review
skill:4-release
skill:5-retro
skill:compact
skill:docs
skill:init
skill:dataviz
skill:update-config
skill:keybindings-help
skill:code-review
skill:simplify
skill:fewer-permission-prompts
skill:loop
skill:schedule
skill:claude-api
skill:run
skill:plugin-authoring
skill:security-review
skill:anthropic-skills:built-in-browser
skill:anthropic-skills:chrome-browser
skill:anthropic-skills:computer-use
skill:anthropic-skills:deep-research
skill:anthropic-skills:docs
skill:anthropic-skills:docx
skill:anthropic-skills:google-workspace
skill:anthropic-skills:import-memory
skill:anthropic-skills:morning
skill:anthropic-skills:pdf
skill:anthropic-skills:pptx
skill:anthropic-skills:skill-creator
skill:anthropic-skills:xlsx
```

Links at check time:

```
/Users/cboyfly/.local/bin/harness -> /Users/cboyfly/Documents/repos/agentic-coding-worktrees/harness-install/harness/bin/harness

/Users/cboyfly/.claude/agents:
total 0
code-reviewer.md -> /Users/cboyfly/Documents/repos/agentic-coding-worktrees/harness-install/harness/agents/code-reviewer.md
fan-selector.md -> /Users/cboyfly/Documents/repos/agentic-coding-worktrees/harness-install/harness/agents/fan-selector.md
plan-reviewer.md -> /Users/cboyfly/Documents/repos/agentic-coding-worktrees/harness-install/harness/agents/plan-reviewer.md

/Users/cboyfly/.claude/skills:
total 0
1-plan -> /Users/cboyfly/Documents/repos/agentic-coding-worktrees/harness-install/harness/skills/1-plan
2-implement -> /Users/cboyfly/Documents/repos/agentic-coding-worktrees/harness-install/harness/skills/2-implement
3-review -> /Users/cboyfly/Documents/repos/agentic-coding-worktrees/harness-install/harness/skills/3-review
4-release -> /Users/cboyfly/Documents/repos/agentic-coding-worktrees/harness-install/harness/skills/4-release
5-retro -> /Users/cboyfly/Documents/repos/agentic-coding-worktrees/harness-install/harness/skills/5-retro
compact -> /Users/cboyfly/Documents/repos/agentic-coding-worktrees/harness-install/harness/skills/compact
docs -> /Users/cboyfly/Documents/repos/agentic-coding-worktrees/harness-install/harness/skills/docs
init -> /Users/cboyfly/Documents/repos/agentic-coding-worktrees/harness-install/harness/skills/init
synced
```
