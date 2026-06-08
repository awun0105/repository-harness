# Project Documentation Map

This directory is the shared source of truth for humans and agents.

Project Harness does not create separate human docs and agent docs. Humans read
these files to understand the project. Agents read the same files to preserve
product behavior, architecture boundaries, decisions, and proof expectations
before changing code.

## Source Of Truth Areas

```text
docs/
  product/       current product behavior and product vocabulary
  requirements/  SRS, DFD, use cases, non-functional requirements, and specs
  architecture/  technical structure, data flow, APIs, security, deployment
  planning/      roadmap, milestones, release plans, and project direction
  stories/       story packets, backlog, and work history
  decisions/     durable decisions and tradeoffs
  validation/    proof matrix, validation reports, and test expectations
  onboarding/    baseline audits for existing projects
  harness/       agent operating rules, process docs, and templates
```

## Reading Paths

### Human: Understand The Project

1. `README.md`
2. `docs/product/`
3. `docs/requirements/`
4. `docs/architecture/`
5. `docs/decisions/`
6. `docs/validation/`

### Agent: Change The Project

1. `AGENTS.md`
2. `docs/harness/HARNESS.md`
3. `docs/harness/FEATURE_INTAKE.md`
4. `docs/harness/CONTEXT_RULES.md`
5. The relevant source-of-truth area above
6. `docs/validation/test-matrix.md` or `scripts/bin/harness-cli query matrix`

### Existing Project Onboarding

Use `docs/harness/ONBOARDING_EXISTING_PROJECT.md` when Project Harness is added
to a repo that already has code. The first task should audit the current repo
and write baseline docs before treating generated docs as truth.

## Freshness Rule

If code and docs disagree, do not silently choose one as true.

Record the conflict, cite evidence, and mark the state as one of:

- `confirmed`: visible in code, tests, or existing docs
- `partial`: partly implemented or weakly proven
- `unknown`: not enough evidence
- `not implemented`: no evidence found

Use `docs/harness/templates/doc-conflict.md` when the conflict needs to be kept
for follow-up.
