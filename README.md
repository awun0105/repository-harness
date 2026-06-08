# Project Harness

Turn an existing software project into a shared source of truth for humans and
coding agents.

Project Harness is a documentation and workflow layer for projects maintained
with humans and coding agents such as Claude Code, Codex, Cursor, and similar
tools. It gives the repository a durable map of current behavior, requirements,
architecture, decisions, stories, and validation proof.

The key rule is simple:

```text
One project truth, shared by humans and agents.
```

`docs/harness/` contains the operating rules for agents. The rest of `docs/`
contains project truth that humans and agents both use.

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
- `docs/requirements/` — SRS, DFD, use cases, and requirement material.
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

The CLI can list and copy registered templates:

```bash
scripts/bin/harness-cli template list
scripts/bin/harness-cli scaffold source_inventory
```

OpenAI describes this shift as an agent-first world where humans steer and
agents execute:

https://openai.com/index/harness-engineering/

## Install Project Harness Into A Project

Most existing projects should start with the process layer only:

```bash
curl -fsSL "https://raw.githubusercontent.com/awun0105/repository-harness/refs/heads/custom/project-harness/scripts/install-harness.sh?$(date +%s)" | bash -s -- --layout harness-only --merge --yes
```

On Windows PowerShell:

```powershell
& ([scriptblock]::Create((irm "https://raw.githubusercontent.com/awun0105/repository-harness/refs/heads/custom/project-harness/scripts/install-harness.ps1"))) -Layout harness-only -Merge -Yes
```

`harness-only` installs `AGENTS.md`, `docs/harness/`, reusable templates,
`docs/validation/`, scripts, and `.gitignore` rules. It avoids creating
product, architecture, requirements, planning, story, and decision docs before
the existing codebase has been audited.

After installing into an existing repo, run the onboarding workflow in:

```text
docs/harness/ONBOARDING_EXISTING_PROJECT.md
```

Use the full project layout for a new repo or a repo you intentionally want to
convert into the complete Project Harness source-of-truth structure:

```bash
curl -fsSL "https://raw.githubusercontent.com/awun0105/repository-harness/refs/heads/custom/project-harness/scripts/install-harness.sh?$(date +%s)" | bash -s -- --layout project --yes
```

```powershell
& ([scriptblock]::Create((irm "https://raw.githubusercontent.com/awun0105/repository-harness/refs/heads/custom/project-harness/scripts/install-harness.ps1"))) -Layout project -Yes
```

If the target already has `AGENTS.md`, `docs/`, or `scripts/`, choose a conflict
mode:

- `--merge`: keep existing files and create only missing Project Harness files.
- `--override`: back up and replace `AGENTS.md`, `docs/`, and `scripts/`.
- default interactive mode: ask before continuing.

For older Harness installs whose `AGENTS.md` still contains the full generated
operating guide, refresh it into the small stable shim:

```bash
curl -fsSL "https://raw.githubusercontent.com/awun0105/repository-harness/refs/heads/custom/project-harness/scripts/install-harness.sh?$(date +%s)" | bash -s -- --merge --refresh-agent-shim --yes
```

The refresh backs up the existing file. If it detects the old
Harness-generated guide, it replaces it with the shim. If the file appears
custom, it appends or updates a marked Harness block instead of overwriting the
project's local instructions.

If the project is driven with Claude Code, add `--claude`. Claude Code never
auto-loads `AGENTS.md`, so without this the installed harness is invisible to
fresh sessions. The flag installs (or refreshes) a `CLAUDE.md` whose marked
Harness block `@`-imports `AGENTS.md` and `docs/harness/FEATURE_INTAKE.md` into every
session's context. An existing `CLAUDE.md` gets the block appended after a
backup; plain installs without the flag never touch `CLAUDE.md`:

```bash
curl -fsSL "https://raw.githubusercontent.com/awun0105/repository-harness/refs/heads/custom/project-harness/scripts/install-harness.sh?$(date +%s)" | bash -s -- --claude --yes
```

Or install into a specific path:

```bash
curl -fsSL "https://raw.githubusercontent.com/awun0105/repository-harness/refs/heads/custom/project-harness/scripts/install-harness.sh?$(date +%s)" | bash -s -- --directory /path/to/project --yes
```

```powershell
& ([scriptblock]::Create((irm "https://raw.githubusercontent.com/awun0105/repository-harness/refs/heads/custom/project-harness/scripts/install-harness.ps1"))) -Directory C:\path\to\project -Yes
```

Use `--dry-run` on Bash or `-DryRun` on PowerShell to preview changes before
writing files.

The installer also downloads the prebuilt Harness CLI for the current platform,
verifies its `.sha256` checksum, and installs it at
`scripts/bin/harness-cli` on macOS/Linux or `scripts/bin/harness-cli.exe` on
Windows. The Rust CLI is the main Harness tool and stable command path.

Harness CLI release assets are published from tags by the
`Harness CLI Release` GitHub Actions workflow. The installer expects each
release to include `harness-cli-<platform>` and
`harness-cli-<platform>.sha256` assets for macOS arm64, macOS x64, Linux x64,
Linux arm64, and Windows x64. The Windows asset is
`harness-cli-windows-x64.exe` plus `harness-cli-windows-x64.exe.sha256`.

## Try The Flow

The fastest way to understand the harness is to inspect the tiny demo:

- `docs/demo/README.md`: shows how a simple product idea becomes product docs,
  stories, validation expectations, and decisions before implementation starts.

A typical flow looks like this:

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

## Product Sources

No product contract is currently defined for this harness repository itself.

When a user provides a project specification, add or reference it as the input
spec for the first buildout, then derive smaller living artifacts from it:

- `docs/product/`: current product contract files, created from the spec.
- `docs/requirements/`: SRS, DFD, use cases, and non-functional requirements.
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
      templates/
    demo/
  scripts/
    README.md
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
