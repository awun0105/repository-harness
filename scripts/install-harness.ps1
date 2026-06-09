param(
    [Alias("d")]
    [string]$Directory = $env:HARNESS_TARGET_DIR,
    [Alias("y")]
    [switch]$Yes,
    [switch]$Merge,
    [switch]$RefreshAgentShim,
    [switch]$Override,
    [switch]$Force,
    [switch]$DryRun,
    [string]$Layout = "project"
)

$ErrorActionPreference = "Stop"

function Write-Step([string]$Message) {
    Write-Host $Message
}

function Fail([string]$Message) {
    throw "Error: $Message"
}

function Resolve-TargetPath([string]$PathValue) {
    if ([string]::IsNullOrWhiteSpace($PathValue)) {
        $PathValue = (Get-Location).Path
    }

    $expanded = [Environment]::ExpandEnvironmentVariables($PathValue)
    if ($expanded.StartsWith("~")) {
        $expanded = Join-Path $HOME $expanded.Substring(1).TrimStart("\", "/")
    }
    if ([System.IO.Path]::IsPathRooted($expanded)) {
        return [System.IO.Path]::GetFullPath($expanded)
    }
    return [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $expanded))
}

function Get-SourceMode {
    if ($PSScriptRoot) {
        $candidate = Split-Path -Parent $PSScriptRoot
        if ((Test-Path (Join-Path $candidate "AGENTS.md")) -and (Test-Path (Join-Path $candidate "docs/harness/HARNESS.md"))) {
            return @{ Mode = "local"; Root = $candidate }
        }
    }
    return @{ Mode = "remote"; Root = "" }
}

function Read-RemoteText([string]$Url) {
    return (Invoke-WebRequest -UseBasicParsing -Uri $Url).Content
}

function Write-SourceFile([string]$Relative, [string]$Target) {
    if ($script:Source.Mode -eq "local") {
        $source = Join-Path $script:Source.Root $Relative
        if (!(Test-Path $source)) {
            Fail "Source file missing: $source"
        }
        Copy-Item -LiteralPath $source -Destination $Target -Force
        return
    }

    $url = "$script:SourceBaseUrl/$($Relative -replace '\\','/')"
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $Target
}

function Merge-Gitignore([string]$Target) {
    $rules = @(
        "# Harness durable layer",
        "harness.db",
        "harness.db-wal",
        "harness.db-shm",
        "scripts/bin/harness-cli",
        "scripts/bin/harness-cli.exe"
    )

    $existing = if (Test-Path $Target) { Get-Content -LiteralPath $Target } else { @() }
    $missing = $rules | Where-Object { $existing -notcontains $_ }
    if ($missing.Count -eq 0) {
        Write-Step "skip     .gitignore (harness rules already present)"
        $script:Skipped++
        return
    }

    if ($DryRun) {
        Write-Step "update   .gitignore (append harness rules)"
    } else {
        $prefix = if ((Test-Path $Target) -and ((Get-Item $Target).Length -gt 0)) { "`n" } else { "" }
        Add-Content -LiteralPath $Target -Value ($prefix + (($missing -join "`n") + "`n")) -NoNewline
        Write-Step "updated  .gitignore (appended harness rules)"
    }
    $script:Updated++
}

function Copy-HarnessFile([string]$Relative) {
    $target = Join-Path $script:TargetDir $Relative

    if ($Relative -eq ".gitignore" -and (Test-Path $target) -and !$Force) {
        Merge-Gitignore $target
        return
    }

    if (Test-Path $target) {
        if ($script:ConflictAction -eq "merge") {
            Write-Step "skip     $Relative (merge keeps existing file)"
            $script:Skipped++
        } elseif ($Force) {
            if ($DryRun) {
                Write-Step "overwrite $Relative (backup first)"
            } else {
                $backup = Join-Path $script:BackupDir $Relative
                New-Item -ItemType Directory -Force -Path (Split-Path -Parent $backup) | Out-Null
                Copy-Item -LiteralPath $target -Destination $backup -Force
                Write-SourceFile $Relative $target
                Write-Step "updated  $Relative (backup: $($backup.Substring($script:TargetDir.Length + 1)))"
            }
            $script:Updated++
        } else {
            Write-Step "skip     $Relative (already exists)"
            $script:Skipped++
        }
        return
    }

    if ($DryRun) {
        Write-Step "create   $Relative"
    } else {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
        Write-SourceFile $Relative $target
        Write-Step "created  $Relative"
    }
    $script:Created++
}

function Get-AgentShimBlock {
@'
<!-- HARNESS:BEGIN -->
## Harness

This repo uses Harness. Before work, read:

- `README.md`
- `docs/README.md`
- `docs/harness/HARNESS.md`
- `docs/harness/FEATURE_INTAKE.md`
- `docs/architecture/overview.md`
- `docs/harness/CONTEXT_RULES.md`
- `scripts/bin/harness-cli query matrix` on macOS/Linux, or `.\scripts\bin\harness-cli.exe query matrix` on Windows

Before creating, normalizing, or syncing documentation, also read:

- `docs/harness/TEMPLATE_REGISTRY.md`

Use registered templates from `docs/harness/templates/`. Do not invent a
documentation format when a registered template exists. Do not overwrite
existing project docs during onboarding without a doc sync plan.

Use the Rust Harness CLI at `scripts/bin/harness-cli` on macOS/Linux or
`scripts/bin/harness-cli.exe` on Windows as the main operational tool. If the
CLI binary is unavailable in a checkout, read `docs/validation/test-matrix.md`
directly and state that the durable matrix could not be queried.
<!-- HARNESS:END -->
'@
}

function Refresh-AgentShimFile {
    if (!$RefreshAgentShim) {
        return
    }
    $target = Join-Path $script:TargetDir "AGENTS.md"
    if (!(Test-Path $target)) {
        return
    }

    if ($DryRun) {
        Write-Step "refresh  AGENTS.md (replace marked Harness block, backup first)"
        $script:Updated++
        return
    }

    New-Item -ItemType Directory -Force -Path $script:BackupDir | Out-Null
    $backup = Join-Path $script:BackupDir "AGENTS.md"
    if (!(Test-Path $backup)) {
        Copy-Item -LiteralPath $target -Destination $backup
    }

    $content = Get-Content -LiteralPath $target -Raw
    $block = Get-AgentShimBlock
    if ($content -match "(?s)<!-- HARNESS:BEGIN -->.*?<!-- HARNESS:END -->") {
        $content = [regex]::Replace($content, "(?s)<!-- HARNESS:BEGIN -->.*?<!-- HARNESS:END -->", [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $block })
    } else {
        $content = $content.TrimEnd() + "`n`n" + $block + "`n"
    }
    Set-Content -LiteralPath $target -Value $content -NoNewline
    Write-Step "updated  AGENTS.md (refreshed Harness block; backup: $($backup.Substring($script:TargetDir.Length + 1)))"
    $script:Updated++
}

function Read-CliReleaseTag {
    $relative = "scripts/harness-cli-release-tag"
    if ($script:Source.Mode -eq "local") {
        $path = Join-Path $script:Source.Root $relative
        if (Test-Path $path) {
            return ((Get-Content -LiteralPath $path | Where-Object { $_ -match "\S" -and $_ -notmatch "^\s*#" } | Select-Object -First 1) -as [string]).Trim()
        }
        return ""
    }

    try {
        $text = Read-RemoteText "$script:SourceBaseUrl/$relative"
        return (($text -split "`n" | Where-Object { $_ -match "\S" -and $_ -notmatch "^\s*#" } | Select-Object -First 1) -as [string]).Trim()
    } catch {
        return ""
    }
}

function Get-DefaultCliBaseUrl {
    $tag = $env:HARNESS_CLI_RELEASE_TAG
    $defaultTag = "harness-cli-v0.1.14-project-harness"
    if ([string]::IsNullOrWhiteSpace($tag)) {
        $tag = Read-CliReleaseTag
    }
    if ([string]::IsNullOrWhiteSpace($tag)) {
        $tag = $defaultTag
    }
    if (![string]::IsNullOrWhiteSpace($tag) -and $tag -ne "latest") {
        return "https://github.com/awun0105/repository-harness/releases/download/$tag"
    }
    return "https://github.com/awun0105/repository-harness/releases/latest/download"
}

function Install-HarnessCliBinary {
    $platform = if ($env:HARNESS_CLI_PLATFORM) { $env:HARNESS_CLI_PLATFORM } else { "windows-x64" }
    if ($platform -ne "windows-x64") {
        Fail "Unsupported Windows Harness CLI platform: $platform"
    }

    $binaryName = "harness-cli-windows-x64.exe"
    $binaryUrl = "$script:CliBaseUrl/$binaryName"
    $checksumUrl = "$binaryUrl.sha256"
    $target = Join-Path $script:TargetDir "scripts/bin/harness-cli.exe"

    if ((Test-Path $target) -and $script:ConflictAction -eq "merge" -and !$Force) {
        Write-Step "skip     scripts/bin/harness-cli.exe (merge keeps existing file)"
        $script:Skipped++
        return
    }

    if ($DryRun) {
        Write-Step "download $binaryName -> scripts/bin/harness-cli.exe"
        Write-Step "verify   $binaryName.sha256"
        $script:Created++
        return
    }

    $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-cli-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null
    try {
        $binaryTmp = Join-Path $tmpDir $binaryName
        $checksumTmp = Join-Path $tmpDir "$binaryName.sha256"
        Invoke-WebRequest -UseBasicParsing -Uri $binaryUrl -OutFile $binaryTmp
        Invoke-WebRequest -UseBasicParsing -Uri $checksumUrl -OutFile $checksumTmp

        $expected = ((Get-Content -LiteralPath $checksumTmp -Raw) -split "\s+")[0].ToLowerInvariant()
        if ([string]::IsNullOrWhiteSpace($expected)) {
            Fail "Checksum file is empty: $checksumUrl"
        }
        $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $binaryTmp).Hash.ToLowerInvariant()
        if ($actual -ne $expected) {
            Fail "Checksum mismatch for $binaryName`: expected $expected, got $actual"
        }

        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
        if (Test-Path $target) {
            if ($Force) {
                $backup = Join-Path $script:BackupDir "scripts/bin/harness-cli.exe"
                New-Item -ItemType Directory -Force -Path (Split-Path -Parent $backup) | Out-Null
                Copy-Item -LiteralPath $target -Destination $backup -Force
            }
            $script:Updated++
            Write-Step "updated  scripts/bin/harness-cli.exe"
        } else {
            $script:Created++
            Write-Step "created  scripts/bin/harness-cli.exe"
        }
        Copy-Item -LiteralPath $binaryTmp -Destination $target -Force
        Write-Step "verified scripts/bin/harness-cli.exe ($platform)"
    } finally {
        Remove-Item -LiteralPath $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$script:Created = 0
$script:Updated = 0
$script:Skipped = 0
$script:Source = Get-SourceMode
$script:SourceBaseUrl = if ($env:HARNESS_SOURCE_BASE_URL) { $env:HARNESS_SOURCE_BASE_URL.TrimEnd("/") } else { "https://raw.githubusercontent.com/awun0105/repository-harness/refs/heads/custom/project-harness" }
$script:CliBaseUrl = if ($env:HARNESS_CLI_BASE_URL) { $env:HARNESS_CLI_BASE_URL.TrimEnd("/") } else { Get-DefaultCliBaseUrl }
$script:TargetDir = Resolve-TargetPath $Directory
$script:BackupDir = Join-Path $script:TargetDir (".harness-backup/" + (Get-Date -Format "yyyyMMddHHmmss"))
$script:ConflictAction = "install"

if ($env:HARNESS_LAYOUT -and $Layout -eq "project") {
    $Layout = $env:HARNESS_LAYOUT
}

if ($Layout -eq "legacy") {
    Fail "-Layout legacy is not available in the Project Harness fork yet. Use -Layout project or -Layout harness-only."
}
if ($Layout -notin @("project", "harness-only")) {
    Fail "Unknown layout: $Layout. Expected project or harness-only."
}

if ($Merge -and $Override) {
    Fail "Use only one of -Merge or -Override"
}

if (!$DryRun -and !(Test-Path $script:TargetDir)) {
    New-Item -ItemType Directory -Force -Path $script:TargetDir | Out-Null
}

$conflicts = @("AGENTS.md", "docs", "scripts") | Where-Object { Test-Path (Join-Path $script:TargetDir $_) }
if ($conflicts.Count -gt 0) {
    if ($Merge) {
        $script:ConflictAction = "merge"
        Write-Step "Continuing with merge. Existing files will be skipped."
    } elseif ($Override) {
        $script:ConflictAction = "override"
        foreach ($protected in @("AGENTS.md", "docs", "scripts")) {
            $path = Join-Path $script:TargetDir $protected
            if (!(Test-Path $path)) { continue }
            if ($DryRun) {
                Write-Step "override $protected (backup first)"
            } else {
                New-Item -ItemType Directory -Force -Path $script:BackupDir | Out-Null
                Move-Item -LiteralPath $path -Destination (Join-Path $script:BackupDir $protected)
                Write-Step "removed  $protected (backup: $($script:BackupDir.Substring($script:TargetDir.Length + 1))/$protected)"
            }
        }
    } elseif ($Yes) {
        Fail "target already contains protected Harness paths: $($conflicts -join ', '). Use -Merge or -Override."
    } else {
        Write-Host "Warning: target already contains protected Harness paths: $($conflicts -join ', ')"
        $choice = Read-Host "Choose Merge, Override, or Stop [Stop]"
        switch -Regex ($choice) {
            "^(m|merge)$" { $script:ConflictAction = "merge"; Write-Step "Continuing with merge. Existing files will be skipped." }
            "^(o|override)$" {
                $script:ConflictAction = "override"
                foreach ($protected in @("AGENTS.md", "docs", "scripts")) {
                    $path = Join-Path $script:TargetDir $protected
                    if (Test-Path $path) {
                        New-Item -ItemType Directory -Force -Path $script:BackupDir | Out-Null
                        Move-Item -LiteralPath $path -Destination (Join-Path $script:BackupDir $protected)
                    }
                }
            }
            default { Fail "installation stopped" }
        }
    }
}

if ($script:Source.Mode -eq "local") {
    Write-Step "Harness source: $($script:Source.Root)"
} else {
    Write-Step "Harness source: $script:SourceBaseUrl"
}
Write-Step "Harness CLI source: $script:CliBaseUrl"
Write-Step "Target project: $script:TargetDir"
Write-Step "Layout: $Layout"

$files = @(
    "AGENTS.md",
    "README.md",
    "docs/architecture/overview.md",
    "docs/architecture/README.md",
    "docs/harness/CONTEXT_RULES.md",
    "docs/harness/FEATURE_INTAKE.md",
    "docs/GLOSSARY.md",
    "docs/harness/HARNESS.md",
    "docs/harness/HARNESS_BACKLOG.md",
    "docs/harness/HARNESS_COMPONENTS.md",
    "docs/harness/HARNESS_MATURITY.md",
    "docs/harness/ONBOARDING_EXISTING_PROJECT.md",
    "docs/harness/TEMPLATE_REGISTRY.md",
    "docs/README.md",
    "docs/onboarding/README.md",
    "docs/planning/README.md",
    "docs/requirements/README.md",
    "docs/validation/test-matrix.md",
    "docs/validation/README.md",
    "docs/harness/TRACE_SPEC.md",
    "docs/decisions/0001-harness-first-development.md",
    "docs/decisions/0002-post-spec-product-lifecycle.md",
    "docs/decisions/0003-generic-spec-intake-harness.md",
    "docs/decisions/0004-sqlite-durable-layer.md",
    "docs/decisions/0005-prebuilt-rust-harness-cli.md",
    "docs/decisions/0006-phase-4-benchmark-triage.md",
    "docs/decisions/README.md",
    "docs/product/README.md",
    "docs/stories/README.md",
    "docs/stories/backlog.md",
    "docs/harness/templates/decisions/decision.md",
    "docs/harness/templates/manifest.yml",
    "docs/harness/templates/docs-suite/README.md",
    "docs/harness/templates/docs-suite/EN/README.md",
    "docs/harness/templates/docs-suite/EN/api.md",
    "docs/harness/templates/docs-suite/EN/architecture.md",
    "docs/harness/templates/docs-suite/EN/configuration.md",
    "docs/harness/templates/docs-suite/EN/data-flow.md",
    "docs/harness/templates/docs-suite/EN/deployment/backup-restore.md",
    "docs/harness/templates/docs-suite/EN/deployment/setup.md",
    "docs/harness/templates/docs-suite/EN/evaluation.md",
    "docs/harness/templates/docs-suite/EN/local-development.md",
    "docs/harness/templates/docs-suite/EN/operations.md",
    "docs/harness/templates/docs-suite/EN/overview.md",
    "docs/harness/templates/docs-suite/EN/scripts.md",
    "docs/harness/templates/docs-suite/VN/README.md",
    "docs/harness/templates/docs-suite/VN/api.md",
    "docs/harness/templates/docs-suite/VN/architecture.md",
    "docs/harness/templates/docs-suite/VN/configuration.md",
    "docs/harness/templates/docs-suite/VN/data-flow.md",
    "docs/harness/templates/docs-suite/VN/deployment/backup-restore.md",
    "docs/harness/templates/docs-suite/VN/deployment/setup.md",
    "docs/harness/templates/docs-suite/VN/evaluation.md",
    "docs/harness/templates/docs-suite/VN/local-development.md",
    "docs/harness/templates/docs-suite/VN/operations.md",
    "docs/harness/templates/docs-suite/VN/overview.md",
    "docs/harness/templates/docs-suite/VN/scripts.md",
    "docs/harness/templates/intake/spec-intake.md",
    "docs/harness/templates/onboarding/baseline-audit.md",
    "docs/harness/templates/onboarding/doc-conflict.md",
    "docs/harness/templates/onboarding/doc-sync-plan.md",
    "docs/harness/templates/onboarding/source-inventory.md",
    "docs/harness/templates/product/domain.md",
    "docs/harness/templates/readme/README_TEMPLATE.md",
    "docs/harness/templates/readme/README_VN_TEMPLATE.md",
    "docs/harness/templates/requirements/srds.md",
    "docs/harness/templates/stories/story.md",
    "docs/harness/templates/stories/high-risk/design.md",
    "docs/harness/templates/stories/high-risk/execplan.md",
    "docs/harness/templates/stories/high-risk/overview.md",
    "docs/harness/templates/stories/high-risk/validation.md",
    "docs/harness/templates/validation/validation-report.md",
    "scripts/README.md",
    "scripts/schema/001-init.sql",
    "scripts/schema/002-story-verify.sql",
    "scripts/schema/003-onboarding-statuses.sql",
    ".gitignore"
)

if ($Layout -eq "harness-only") {
    $projectOnlyPattern = "^(README\.md|docs/architecture/|docs/GLOSSARY\.md|docs/onboarding/|docs/planning/|docs/requirements/|docs/decisions/|docs/product/|docs/stories/)"
    $files = $files | Where-Object { $_ -notmatch $projectOnlyPattern }
}

foreach ($file in $files) {
    Copy-HarnessFile $file
}

Refresh-AgentShimFile
Install-HarnessCliBinary

Write-Step ""
Write-Step "Done. Created: $script:Created, updated: $script:Updated, skipped: $script:Skipped."
if ($script:Skipped -gt 0 -and !$Force) {
    Write-Step "Existing files were left untouched. Re-run with -Force to overwrite with backups."
}
if ($Force -and $script:Updated -gt 0 -and !$DryRun) {
    Write-Step "Backups were written to: $script:BackupDir"
}
