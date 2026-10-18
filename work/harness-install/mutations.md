# Mutation checks

Each run uses the new cases extracted verbatim from `harness/tests/test-scripts.sh`, with its helpers and hermetic fixtures. Install cases copy the harness into their disposable home and resolve the copy physically, so mutations cannot write into the checkout. `GATE_REQUIRED_TOOLS` is unset per command. All originals are restored byte-for-byte in `finally`.

- **install directory symlink:** replaced `ln -sfn ` with `ln -sf `. Failing case: **install replaces directory symlink without writing into old directory** (runner exit 1). Verified mutation landed by asserting the replacement is present and the original exact text is absent after reading the file back.

- **install preflight:** removed the entire conflict-checking loop and refusal before link creation. Failing case: **install conflicts name every path and create no links** (runner exit 1). Read the file back and asserted that the complete original block was absent and the replacement comment `# mutation: complete preflight removed` was present.

- **agent-exec contract:** replaced `{ cat "$CONTRACT"; printf` with `{ printf`. Failing case: **agent-exec prepends contract then separator then handoff** (runner exit 1). Verified mutation landed by asserting the replacement is present and the original exact text is absent after reading the file back.

- **archi.sources config:** replaced `IFS=: read -r -a SOURCE_PATHS <<<"$sources"` with `: # mutation: config ignored`. Failing case: **archi.sources ignores newer harness alone** (runner exit 1). Verified mutation landed by asserting the replacement is present and the original exact text is absent after reading the file back.


Baseline: all 18 new cases pass. The successful contract case checks the invocation marker exists before the missing/empty-contract cases remove it and assert it stays absent. The directory-symlink mutation creates an entry inside the old directory; the preflight mutation creates links despite the regular-file conflicts, proving both absence assertions can fail.
