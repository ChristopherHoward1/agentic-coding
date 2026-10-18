No substantive findings. The diff matches the approved scope, and the new tests cover the specified install, contract-piping, and ref-specific configuration cases.

ShellCheck passed for the changed scripts and test suite. Runtime verification was limited by the read-only sandbox: `archi-fresh` encountered a temporary-file error, and I could not independently run the gate or mutation checks.

Codex verdict: APPROVE
