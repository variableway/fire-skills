#Requires -Version 5.1
<#
.SYNOPSIS
    Dev Workflow Combined Installer for Windows.
    Installs all dev-workflow related skills.

.DESCRIPTION
    Installs: github-cli-skill, gh-create-release, git-workflow, local-workflow

.PARAMETER System
    Install to system directories

.PARAMETER Project
    Install to current project directory

.PARAMETER Agent
    Target specific agent (claude-code, kimi, codex, opencode)

.PARAMETER Hooks
    Also install git hooks (git-workflow only)

.EXAMPLE
    .\dev-workflow-install.ps1 -System
    Install to all system agent directories

.EXAMPLE
    .\dev-workflow-install.ps1 -System -Agent kimi
    Install to kimi system directory only

.EXAMPLE
    .\dev-workflow-install.ps1 -Project
    Install to current project
#>

param(
    [switch]$System,
    [switch]$Project,
    [string]$Agent = "",
    [switch]$Hooks
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Skills to install (relative to ScriptDir)
$Skills = @(
    "github-cli-skill"
    "gh-create-release"
    "git-workflow"
    "local-workflow"
)

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}
function Write-Success { param([string]$Message) Write-ColorOutput $Message "Green" }
function Write-Warning { param([string]$Message) Write-ColorOutput $Message "Yellow" }
function Write-ErrorMsg { param([string]$Message) Write-ColorOutput $Message "Red" }
function Write-Info { param([string]$Message) Write-ColorOutput $Message "Cyan" }

function Test-GhInstalled {
    try {
        $version = gh --version | Select-Object -First 1
        Write-Success "[OK] GitHub CLI found: $version"
        return $true
    }
    catch {
        Write-Warning "[WARN] GitHub CLI (gh) is not installed."
        Write-Host "  Install: https://cli.github.com/"
        return $false
    }
}

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
    param([string]$SkillName, [string]$SkillRoot, [string]$TargetDir)
    $linkPath = Join-Path $TargetDir $SkillName

    if ((Test-Path $linkPath) -or (Get-Item $linkPath -ErrorAction SilentlyContinue)) {
        Write-Warning "  [SKIP] $SkillName already exists at $linkPath"
        return $false
    }

    $parentDir = Split-Path -Parent $linkPath
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

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

function Install-Skill {
    param([string]$SkillName)
    $skillRoot = Join-Path $ScriptDir $SkillName

    if (-not (Test-Path $skillRoot)) {
        Write-ErrorMsg "  [ERROR] Skill directory not found: $skillRoot"
        return
    }

    Write-Info "Installing $SkillName..."

    if ($System) {
        $targetDirs = Get-SystemTargetDirs
    }
    else {
        $targetDirs = Get-ProjectTargetDirs
    }

    $installed = 0
    $skipped = 0

    foreach ($targetDir in $targetDirs) {
        if (New-SkillLink -SkillName $SkillName -SkillRoot $skillRoot -TargetDir $targetDir) {
            $installed++
        }
        else {
            $skipped++
        }
    }

    Write-Success "  Installed: $installed, Skipped: $skipped"
}

function Install-GitHooks {
    $gitWorkflowRoot = Join-Path $ScriptDir "git-workflow"
    $hooksDir = Join-Path $gitWorkflowRoot "hooks"

    if (-not (Test-Path $hooksDir)) {
        Write-Warning "  [SKIP] git-workflow hooks not found"
        return
    }

    Write-Info "Installing git hooks..."

    $gitHooksDir = ".git\hooks"
    if (-not (Test-Path $gitHooksDir)) {
        Write-Warning "Warning: Not a git repository or .git\hooks not found."
        return
    }

    foreach ($hook in @("prepare-commit-msg", "post-commit")) {
        $src = Join-Path $hooksDir $hook
        $dst = Join-Path $gitHooksDir $hook
        if (Test-Path $src) {
            if ((Test-Path $dst) -and -not (Get-Item $dst -ErrorAction SilentlyContinue).LinkType) {
                Write-Warning "  [SKIP] $dst already exists (not overwriting)"
            }
            else {
                Copy-Item $src $dst -Force
                Write-Success "  [OK]   $dst"
            }
        }
    }
}

function Main {
    if (-not $System -and -not $Project) {
        Write-ErrorMsg "Error: Must specify -System or -Project"
        Write-Host ""
        Write-Host "Usage:"
        Write-Host "  .\dev-workflow-install.ps1 -System"
        Write-Host "  .\dev-workflow-install.ps1 -System -Agent kimi"
        Write-Host "  .\dev-workflow-install.ps1 -Project"
        exit 1
    }

    Write-Info "Detected OS: Windows"
    Write-Info "Skills to install: $($Skills -join ', ')"
    Write-Host ""

    Test-GhInstalled | Out-Null
    Write-Host ""

    foreach ($skill in $Skills) {
        Install-Skill -SkillName $skill
        Write-Host ""
    }

    if ($Hooks -and $Project) {
        Install-GitHooks
        Write-Host ""
    }

    Write-Success "Dev workflow installation complete!"
    Write-Host "Skills installed: $($Skills -join ', ')"
}

Main
