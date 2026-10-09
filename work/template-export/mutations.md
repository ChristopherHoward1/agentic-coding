# Mutation checks

Each mutation was checked byte-for-byte before running the suite; the original script was restored afterward.

- argument-count: mutation verified; suite exit 1; FAIL: no arguments refuses with usage; FAIL: extra arguments refuses with usage and writes nothing
- nonempty-destination: mutation verified; suite exit 1; FAIL: non-empty destination refuses without writes
- file-destination: mutation verified; suite exit 1; FAIL: file destination refuses without writes
- base-HEAD: mutation verified; suite exit 1; FAIL: base and overlay both reflect HEAD
- overlay-HEAD: mutation verified; suite exit 1; FAIL: base and overlay both reflect HEAD
