# Notes

## Implementer summary

Implemented within the four-file footprint.

- Demo blocks now run under `bash -e`; exit and dirty-tree contracts remain intact.
- Added fail-fast tests and updated help, plan guidance, and ARCHI.
- Removing `-e` failed all four new checks; restoring it passed all 19 demo checks.
- `harness gate`: PASS. Architecture freshness passes.

No partially met criteria or out-of-scope observations. No commits made.

## Demo (orchestrator, exit 0)

```
before
demo: block exited with code 1
fail-fast exit=1
rc=3 out=hi
exit=4
demo-fail-fast-ok
```
