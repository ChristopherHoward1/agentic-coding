# Implementation notes

Implemented only the declared footprint. Reused the export script and test fixture; Git supplies clone, staging, tree comparison, and history preservation without new dependencies.

The release skill combines its existing PR merge/tag action in step 4 to accommodate the requested sync step 5 and retro step 6. Cleanup and pull remain unconditional.

The export suite passes all 12 cases; all six required guard mutations fail their named cases (see mutations.md). The new script and tests pass explicit shellcheck. Export-ignore is set and the template repository name is absent from skills/, config.yaml, and CLAUDE.md.

Actual template PR merge, CI, and template repository settings remain the Orchestrator/Owner’s release actions.
