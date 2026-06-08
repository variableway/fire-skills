#Requires -Version 5.1
<#
.SYNOPSIS
    Local Workflow Skill Installer for Windows.

.DESCRIPTION
    Installs the local-workflow skill to system or project agent directories.

.PARAMETER System
    Install to system directories

.PARAMETER Project
    Install to current project directory

.PARAMETER Agent
    Target specific agent (claude-code, kimi, codex, opencode)

.EXAMPLE
    .\install.ps1 -System
    Install to all system agent directories

.EXAMPLE
    .\install.ps1 -System -Agent kimi
    Install to kimi system directory only

.EXAMPLE
    .\install.ps1 -Project
    Install to current project
#>

param(
    [switch]$System,
    [switch]$Project,
    [string]$Agent = ""
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillRoot = Split-Path -Parent $ScriptDir
$SkillName = Split-Path -Leaf $SkillRoot

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}
function Write-Success { param([string]$Message) Write-ColorOutput $Message "Green" }
function Write-Warning { param([string]$Message) Write-ColorOutput $Message "Yellow" }
function Write-ErrorMsg { param([string]$Message) Write-ColorOutput $Message "Red" }
function Write-Info { param([string]$Message) Write-ColorOutput $Message "Cyan" }

function Get-SystemTargetDirs {
    $dirs = @()
    $homePath = $env:USERPROFILE

    switch ($Agent) {
        "" {
            $dirs += Join-Path $homePath ".config\agents\skills"
            $dirs += Join-Path $homePath ".claude\skills"
            $dirs += Join-Path $homePath ".kimi\skills"
            $dirs += Join-Path $homePath ".codex\skills"
            $dirs += Join-Path $homePath ".opencode\skills"
        }
        "claude-code" {
            $dirs += Join-Path $homePath ".claude\skills"
        }
        "kimi" {
            $dirs += Join-Path $homePath ".kimi\skills"
            $dirs += Join-Path $homePath ".config\agents\skills"
        }
        "codex" {
            $dirs += Join-Path $homePath ".codex\skills"
        }
        "opencode" {
            $dirs += Join-Path $homePath ".opencode\skills"
        }
        default {
            Write-ErrorMsg "Error: Unknown agent '$Agent'"
            Write-Host "Supported agents: claude-code, kimi, codex, opencode"
            exit 1
        }
    }
    return $dirs
}

function Get-ProjectTargetDirs {
    $dirs = @()
    $dirs += Join-Path $PWD ".agents\skills"
    $dirs += Join-Path $PWD ".kimi\skills"
    $dirs += Join-Path $PWD ".claude\skills"
    return $dirs
}

function Test-SymlinkCapability {
    $testPath = Join-Path $env:TEMP "symlink_test_$(Get-Random)"
    $testTarget = Join-Path $env:TEMP "symlink_test_target_$(Get-Random)"
    try {
        New-Item -ItemType Directory -Path $testTarget -Force | Out-Null
        New-Item -ItemType SymbolicLink -Path $testPath -Target $testTarget -Force | Out-Null
        Remove-Item $testPath -Force
        Remove-Item $testTarget -Force
        return $true
    }
    catch {
        return $false
    }
}

function New-SkillLink {
    param([string]$TargetDir)
    $linkPath = Join-Path $TargetDir $SkillName

    if ((Test-Path $linkPath) -or (Get-Item $linkPath -ErrorAction SilentlyContinue)) {
        Write-Warning "  [SKIP] $SkillName already exists at $linkPath"
        return $false
    fi

    $parentDir = Split-Path -Parent $linkPath
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    fi

    if (Test-SymlinkCapability) {
        try {
            New-Item -ItemType SymbolicLink -Path $linkPath -Target $SkillRoot -Force | Out-Null
            Write-Success "  [OK]   $SkillName -> $linkPath"
            return $true
        }
        catch {
            # fall through
        }
    }

    try {
        New-Item -ItemType Junction -Path $linkPath -Target $SkillRoot -Force | Out-Null
        Write-Success "  [OK]   $SkillName -> $linkPath (junction)"
        return $true
    }
    catch {
        Write-ErrorMsg "  [ERROR] Failed to create link: $_"
        return $false
    }
}

function Install-System {
    Write-Info "Installing $SkillName to system directories..."
    $targetDirs = Get-SystemTargetDirs
    $installed = 0
    $skipped = 0

    foreach ($targetDir in $targetDirs) {
        $result = New-SkillLink -TargetDir $targetDir
        if ($result) {
            $installed++
        }
        else {
            $skipped++
        }
    }

    Write-Host ""
    Write-Success "System installation complete."
    Write-Host "  Installed: $installed"
    Write-Host "  Skipped: $skipped"
}

function Install-Project {
    Write-Info "Installing $SkillName to project directories..."

    if (-not (Test-Path ".git")) {
        Write-Warning "Warning: Current directory is not a git repository."
        $response = Read-Host "Continue anyway? (y/N)"
        if ($response -notmatch "^[Yy]$") {
            exit 1
        }
    }

    $targetDirs = Get-ProjectTargetDirs
    $installed = 0
    $skipped = 0

    foreach ($targetDir in $targetDirs) {
        $result = New-SkillLink -TargetDir $targetDir
        if ($result) {
            $installed++
        }
        else {
            $skipped++
        }
    }

    Write-Host ""
    Write-Success "Project installation complete."
    Write-Host "  Installed: $installed"
    Write-Host "  Skipped: $skipped"
}

function Install-ClaudeMD {
    Write-Host ""
    Write-Info "Updating CLAUDE.md with local-workflow instructions..."

    $claudeMd = Join-Path $PWD "CLAUDE.md"

    if ((Test-Path $claudeMd) -and ((Get-Content $claudeMd -Raw) -match "local-workflow")) {
        Write-Warning "  [SKIP] CLAUDE.md already contains local-workflow instructions"
        return
    }

    $skillRelPath = Resolve-Path -Relative $SkillRoot

    $workflowBlock = @"

## Local Task Execution Workflow

When the user asks to **execute a task locally** or **use local-workflow** (no GitHub needed), follow:

1. **INIT** -- Initialize local tracking:
   ``````bash
   python $skillRelPath/scripts/orchestrate.py init <task-file.md>
   ``````

2. **IMPLEMENT** -- Execute the task (code changes, tests, etc.)

3. **FINISH** -- Mark task complete and commit:
   ``````bash
   python $skillRelPath/scripts/orchestrate.py finish
   ``````

Tracking records are saved to `tasks/tracing/`. No GitHub Issues required.
"@

    if (Test-Path $claudeMd) {
        Add-Content $claudeMd $workflowBlock
        Write-Success "  [OK]   Appended local-workflow instructions to CLAUDE.md"
    }
    else {
        Set-Content $claudeMd "# Project Instructions"
        Add-Content $claudeMd $workflowBlock
        Write-Success "  [OK]   Created CLAUDE.md with local-workflow instructions"
    }
}

function Main {
    if (-not $System -and -not $Project) {
        Write-ErrorMsg "Error: Must specify -System or -Project"
        Write-Host ""
        Write-Host "Usage:"
        Write-Host "  .\install.ps1 -System"
        Write-Host "  .\install.ps1 -System -Agent kimi"
        Write-Host "  .\install.ps1 -Project"
        exit 1
    }

    Write-Info "Detected OS: Windows"
    Write-Host ""

    if ($System) {
        Install-System
    }
    elseif ($Project) {
        Install-Project
        Install-ClaudeMD
    }

    Write-Host ""
    Write-Host "Skill installed: $SkillName"
}

Main
