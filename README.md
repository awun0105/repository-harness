# Project Harness

Turn a software project into one shared source of truth for humans and coding
agents.

Project Harness is a documentation, workflow, and lightweight CLI layer for
projects maintained with humans and coding agents such as Claude Code, Codex,
Cursor, and similar tools. It gives a repository a durable map of current
behavior, requirements, architecture, decisions, stories, validation proof, and
prior agent work.

The key rule is simple:

```text
One project truth, shared by humans and agents.
```

`docs/harness/` contains the operating rules for agents. The rest of `docs/`
contains project truth that humans and agents both use.

Project Harness is not an application scaffold. It does not choose your tech
stack, invent product domains, or generate accepted requirements without
review. It gives humans and agents a disciplined way to turn real intent, code,
tests, and existing docs into a project baseline that can be updated safely.

## The Problem

Most repos are built for humans reading code in a familiar codebase. Coding
agents usually enter with only a chat prompt and a shallow snapshot of files.
That leads to common failure modes:

- The agent edits code before understanding product intent.
- Important constraints live only in chat history or in someone's head.
- Validation expectations are vague or discovered too late.
- Architecture tradeoffs are repeated instead of inherited.
- Large requests do not get broken into reviewable story-sized work.
- Existing projects get template docs that do not match the current code.

## The Harness Approach

A repository starts to have a useful harness when it helps humans and agents
answer practical engineering questions without relying only on chat history:

- What is the current product behavior?
- Which docs are source of truth?
- What is implemented, partial, unknown, or planned?
- What should an agent read before changing code?
- How risky is this request?
- What proof is required before work is considered done?
- Which decisions should future work inherit?

In this repo, those answers live in:

- `AGENTS.md` — the stable agent shim with local project notes and Harness
  doc links.
- `docs/README.md` — the shared documentation map for humans and agents.
- `docs/product/` — current product behavior and product vocabulary.
- `docs/requirements/` — SRDS and other requirement material.
- `docs/architecture/` — technical architecture and system boundaries.
- `docs/validation/` — proof matrix and validation reports.
- `docs/harness/HARNESS.md` — the human-agent collaboration model.
- `docs/harness/FEATURE_INTAKE.md` — tiny, normal, and high-risk work classification.
- `docs/stories/` — story packets and backlog items.
- `docs/decisions/` — durable decisions and tradeoffs.
- `docs/harness/templates/` — reusable onboarding, story, decision, validation,
  and README/docs templates.
- `docs/harness/TEMPLATE_REGISTRY.md` — the map from doc type to registered
  template and output path.

OpenAI describes this shift as an agent-first world where humans steer and
agents execute:

https://openai.com/index/harness-engineering/

## Install And Use-Case Paths

The fastest way to understand the harness is to inspect `docs/demo/README.md`.
It shows how a simple product idea becomes product docs, stories, validation
expectations, and decisions before implementation starts.

A typical Harness flow looks like this:

```text
human intent or product spec
  -> product contract
  -> feature intake
  -> story packet
  -> validation expectations
  -> implementation work
  -> decision or lesson captured for future agents
```

Implementation prompts do not go straight to code. They first pass through
feature intake, become story-sized work when needed, and then carry both product
validation and harness maintenance expectations.

### Existing Project

Use this when the repository already has code, tests, scripts, or old docs.
Most existing projects should start with `harness-only`, which installs the
Harness process layer without creating fake product truth before the codebase is
audited.

```bash
curl -fsSL "https://raw.githubusercontent.com/awun0105/repository-harness/refs/heads/custom/project-harness/scripts/install-harness.sh?$(date +%s)" | bash -s -- --layout harness-only --merge --yes
```

```powershell
& ([scriptblock]::Create((irm "https://raw.githubusercontent.com/awun0105/repository-harness/refs/heads/custom/project-harness/scripts/install-harness.ps1"))) -Layout harness-only -Merge -Yes
```

```text
developer installs harness-only
  -> developer prompts the coding agent to onboard the repo
  -> agent reads AGENTS.md, onboarding workflow, and template registry
  -> agent inventories existing docs/code/tests/config
  -> agent creates source inventory, doc sync plan, and baseline audit
  -> developer reviews conflicts and unknowns
  -> agent updates baseline docs
  -> agent imports/queries durable state with harness-cli
  -> future work uses intake, stories, proof, decisions, and traces
```

Prompt:

```text
Read AGENTS.md and follow the Harness existing-project onboarding workflow for this repository without implementing product behavior.
```

Review after onboarding:

- `docs/onboarding/source-inventory.md`
- `docs/onboarding/doc-sync-plan.md`
- `docs/onboarding/baseline-audit.md`
- `docs/onboarding/doc-conflicts.md`
- `docs/product/current-state.md`
- `docs/architecture/overview.md`
- `docs/validation/test-matrix.md`
- `docs/stories/backlog.md`

Then ask the agent to update the baseline and run the required Harness CLI
sync/query steps:

```text
Update the Harness baseline from my answers, then run the required harness-cli sync and query steps and summarize the current matrix, open backlog, and stats.
```

### New Project

Use this when the repo starts from a human spec instead of existing code. The
full `project` layout creates the complete source-of-truth structure up front.

```bash
curl -fsSL "https://raw.githubusercontent.com/awun0105/repository-harness/refs/heads/custom/project-harness/scripts/install-harness.sh?$(date +%s)" | bash -s -- --layout project --yes
```

```powershell
& ([scriptblock]::Create((irm "https://raw.githubusercontent.com/awun0105/repository-harness/refs/heads/custom/project-harness/scripts/install-harness.ps1"))) -Layout project -Yes
```

```text
human spec
  -> feature intake
  -> registered templates
  -> draft product/SRDS/architecture/story docs
  -> human review
  -> implementation stories and validation proof
```

Prompt:

```text
Read AGENTS.md and use Project Harness to turn this spec into reviewed product, SRDS, architecture, validation, and story docs before implementation.
```

### Normal Feature Work

Use this after a project baseline already exists.

```text
developer asks for a change
  -> agent classifies the request in FEATURE_INTAKE
  -> agent chooses tiny, normal, or high-risk lane
  -> agent reads the relevant source-of-truth docs
  -> agent creates or updates a story when needed
  -> agent implements the smallest useful vertical slice
  -> agent runs proof checks
  -> agent updates harness-cli story status and proof flags
  -> agent records a trace
```

Prompt:

```text
Read AGENTS.md and handle this request through Harness intake, story, validation, implementation, proof update, and trace recording.
```

### Installer Options

Use `--dry-run` on Bash or `-DryRun` on PowerShell to preview changes before
writing files. Use `--merge` for repos with existing docs. Use `--override` only
when replacing `AGENTS.md`, `docs/`, and `scripts/` is intentional. Add
`--claude` when the project is driven by Claude Code so `CLAUDE.md` imports the
Harness instructions. Use `--directory /path/to/project` or
`-Directory C:\path\to\project` to install into another path.

The installer downloads the prebuilt Harness CLI for the current platform,
verifies its checksum, and installs it at `scripts/bin/harness-cli` on
macOS/Linux or `scripts/bin/harness-cli.exe` on Windows.

### Useful CLI Commands

```bash
scripts/bin/harness-cli query matrix
scripts/bin/harness-cli query backlog --open
scripts/bin/harness-cli query decisions
scripts/bin/harness-cli query traces
scripts/bin/harness-cli query stats
scripts/bin/harness-cli template list
scripts/bin/harness-cli scaffold product_domain --output docs/product/tasks.md
```

`harness-cli scaffold` only copies registered templates. It does not decide
what is true. Agents and humans must fill scaffolded docs from specs, code,
tests, existing docs, or explicit human confirmation.

## Current State

This fork is becoming Project Harness.

Compared with the upstream layout, this branch is optimized for existing
codebases:

- Shared project docs are separate from Harness process docs.
- Existing project onboarding is a first-class workflow.
- Empty or generated docs must not be treated as source of truth.
- The validation matrix supports partial and unknown states.
- README, docs-suite, requirements, onboarding, story, decision, and validation
  templates live under categorized folders in `docs/harness/templates/`.
- `docs/harness/TEMPLATE_REGISTRY.md` tells agents which template to use before
  creating, normalizing, or syncing docs.
- `scripts/bin/harness-cli template list` and `scripts/bin/harness-cli scaffold`
  expose registered templates mechanically.
- The installer pulls this fork's published `harness-cli` release assets and
  verifies checksums.

## Product Sources

No product contract is currently defined for this harness repository itself.

When a user provides a project specification, add or reference it as the input
spec for the first buildout, then derive smaller living artifacts from it:

- `docs/product/`: current product contract files, created from the spec.
- `docs/requirements/`: SRDS plus any additional requirement material selected
  by the project.
- `docs/architecture/`: technical structure and boundary docs.
- `docs/stories/`: story packets and backlog created from selected work.
- `docs/validation/test-matrix.md`: behavior-to-proof control panel.
- `docs/decisions/`: durable decisions and tradeoffs.

When adding Project Harness to an existing repo, run the onboarding workflow in
`docs/harness/ONBOARDING_EXISTING_PROJECT.md` before trusting generated docs as
truth.

## Repository Structure

```text
project/
  AGENTS.md
  README.md
  docs/
    README.md
    product/
    requirements/
    architecture/
    planning/
    stories/
    decisions/
    validation/
    onboarding/
    harness/
      HARNESS.md
      FEATURE_INTAKE.md
      CONTEXT_RULES.md
      ONBOARDING_EXISTING_PROJECT.md
      TEMPLATE_REGISTRY.md
      templates/
    demo/
  scripts/
    README.md
    schema/
  crates/
    harness-cli/
```

## Contributing

This project is early and benefits most from real-world agent failure cases,
example harness installs, docs improvements, and reusable workflow patterns.
See `CONTRIBUTING.md` for contribution ideas.

Useful contributions include:

- Show how the harness works in a real project.
- Add missing templates or improve existing ones.
- Propose validation patterns for different stacks.
- Share failures where an agent made the wrong change because the repo lacked
  context.
- Compare harness behavior across Claude Code, Codex, Cursor, and other tools.

## Share

If this idea resonates, please star the repo and share it with someone building
with coding agents.

Short description:

> An agent-ready repo harness for Claude Code, Codex, Cursor, and other coding
> agents: AGENTS.md, product contracts, story packets, validation matrix, and
> decision records.
