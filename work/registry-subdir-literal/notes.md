# Notes — registry-subdir-literal

## Implementer summary

Implemented literal handling for registry subdirectories: `register.sh` escapes Git ignore metacharacters and uses a literal pathspec for the tracked-file check. Added the registry regression case and updated the targeted ARCHI description.

`harness gate` passed. The new case also failed as expected under all three requested mutations.

One acceptance criterion remains pending: `harness archi-fresh wt/registry-subdir-literal` reports the branch stale because it reads committed history and cannot see the uncommitted ARCHI edit. The orchestrator can rerun it after committing. No out-of-scope changes were made.

## Gate

GATE: PASS (passed: 6, failed: 0); `harness archi-fresh wt/registry-subdir-literal` exit 0 after the implementer commit.

## Demo

```
/var/folders/y6/cqq_kqw13z58pgr6c9f3fzdm0000gn/T/tmp.dLbNBLWYkp/hh/projects/demo
Owner: run /add-dir /var/folders/y6/cqq_kqw13z58pgr6c9f3fzdm0000gn/T/tmp.dLbNBLWYkp/hh/projects/demo or add it to permissions.additionalDirectories
Owner: run /add-dir /var/folders/y6/cqq_kqw13z58pgr6c9f3fzdm0000gn/T/tmp.dLbNBLWYkp/hh/projects/demo or add it to permissions.additionalDirectories
/app\[1\]/CLAUDE.local.md
status=[]
/var/folders/y6/cqq_kqw13z58pgr6c9f3fzdm0000gn/T/tmp.dLbNBLWYkp/hh/projects/demo2
Owner: run /add-dir /var/folders/y6/cqq_kqw13z58pgr6c9f3fzdm0000gn/T/tmp.dLbNBLWYkp/hh/projects/demo2 or add it to permissions.additionalDirectories
?? axb/CLAUDE.local.md
```
