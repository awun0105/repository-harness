# Project Rules

<!-- HARNESS:BEGIN -->
## Harness

Claude Code loads this file into every session, but it does not auto-load
`AGENTS.md`. The bare `@` lines below import the always-required harness
context (the "Must in all lanes" set from `docs/harness/CONTEXT_RULES.md`) at
context-load time. Never wrap them in backticks; that disables the import.

@AGENTS.md

@docs/harness/FEATURE_INTAKE.md

Also run `scripts/bin/harness-cli query matrix` before starting work.
If the binary is unavailable, read `docs/validation/test-matrix.md` directly
and state that the durable matrix could not be queried.

Lane-dependent context (`README.md`, `docs/harness/HARNESS.md`, `docs/architecture/overview.md`,
`docs/harness/CONTEXT_RULES.md`, product docs, stories, decisions) is intentionally not
imported — read it per lane, as `docs/harness/CONTEXT_RULES.md` prescribes.
<!-- HARNESS:END -->
