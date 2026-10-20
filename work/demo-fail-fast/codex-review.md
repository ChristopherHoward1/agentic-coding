No CRITICAL/HIGH findings.

- LOW — `ARCHI.md:21` lists “expected-failure forms” as hermetic test coverage, but those tests were deliberately dropped. Remove that phrase to match the suite.

The runner and regression tests match the planned behavior. Syntax validation passed; an in-memory comparison confirmed `bash -e` stops at `false` with exit 1, while plain Bash prints `after` and exits 0.

The read-only environment prevented running the gate and the required on-disk mutation test; those acceptance checks remain unverified.

Codex verdict: APPROVE
