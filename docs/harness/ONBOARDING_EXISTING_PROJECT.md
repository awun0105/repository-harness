# Existing Project Onboarding

Use this workflow when Project Harness is added to a repository that already has
code, partial docs, tests, scripts, or production behavior.

The goal is to create a truthful baseline. Do not implement new product behavior
during onboarding.

## Rules

- Existing code and tests are evidence, not complete product intent.
- Generated template text is never source of truth.
- Missing docs are not permission to invent behavior.
- Mark uncertainty explicitly.
- If code and docs conflict, record the conflict with evidence.

## Evidence Labels

| Label | Meaning |
| --- | --- |
| confirmed | Found in code, tests, existing docs, or human-provided material |
| partial | Partly implemented, weakly proven, or missing an important path |
| unknown | Not enough evidence to make a claim |
| not implemented | No implementation evidence found |

## Recommended Outputs

- `docs/onboarding/baseline-audit.md`
- `docs/product/current-state.md`
- `docs/architecture/overview.md`
- `docs/validation/test-matrix.md`
- `docs/stories/backlog.md`
- Decision records for major existing choices when evidence is clear

## Audit Flow

1. Read `README.md`, package/build files, source entrypoints, routes, schemas,
   tests, deployment files, and existing docs.
2. List confirmed, partial, unknown, and not implemented behavior.
3. Create or update current-state product docs.
4. Create or update architecture docs from code evidence.
5. Update validation expectations with real test/proof evidence.
6. Add backlog items or stories for gaps instead of fixing everything at once.
7. Record decision files only for meaningful choices that are visible or
   human-confirmed.

## Stop Conditions

Pause for human confirmation when:

- Product intent cannot be inferred from code or docs.
- Auth, authorization, data loss, security, billing, or external providers are
  involved and evidence is incomplete.
- A generated doc conflicts with implemented behavior.
