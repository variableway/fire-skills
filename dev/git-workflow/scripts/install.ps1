#Requires -Version 5.1
<#
.SYNOPSIS
    Git Workflow Skill Installer for Windows.

.DESCRIPTION
    Installs the git-workflow skill to system or project agent directories.

.PARAMETER System
    Install to system directories

.PARAMETER Project
    Install to current project directory

.PARAMETER Agent
    Target specific agent (claude-code, kimi, codex, opencode)

.PARAMETER Hooks
    Also install git hooks to .git/hooks/

.EXAMPLE
    .\install.ps1 -System
    Install to all system agent directories

.EXAMPLE
    .\install.ps1 -System -Agent kimi
    Install to kimi system directory only

.EXAMPLE
    .\install.ps1 -Project -Hooks
    Install to current project and install git hooks
#>

param(
    [switch]$System,
    [switch]$Project,
    [string]$Agent = "",
    [switch]$Hooks
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

function Test-GhInstalled {
    try {
        $version = gh --version | Select-Object -First 1
        Write-Success "[OK] GitHub CLI found: $version"
        return $true
    }
    catch {
        Write-Warning "[WARN] GitHub CLI (gh) is not installed."
        return $false
    }
}

function Install-Gh {
    Write-Info "Installing GitHub CLI..."

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --id GitHub.cli -e --source winget
    }
    elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        choco install gh -y
    }
    elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
        scoop install gh
    }
    else {
        Write-ErrorMsg "Error: No supported package manager found (winget, chocolatey, scoop)."
        Write-Host "Please install GitHub CLI manually: https://github.com/cli/cli#installation"
        exit 1
    }

    # Refresh PATH so gh is available in this session
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
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
    param([string]$TargetDir)
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

function Install-Hooks {
    Write-Host ""
    Write-Info "Installing git hooks..."

    $gitHooksDir = Join-Path $PWD ".git\hooks"
    if (-not (Test-Path $gitHooksDir)) {
        Write-Warning "Warning: Not a git repository or .git/hooks not found."
        return
    }

    $hooksSourceDir = Join-Path $SkillRoot "hooks"
    $hookNames = @("prepare-commit-msg", "post-commit")

    foreach ($hookName in $hookNames) {
        $src = Join-Path $hooksSourceDir $hookName
        $dst = Join-Path $gitHooksDir $hookName
        if (Test-Path $src) {
            if ((Test-Path $dst) -and -not ((Get-Item $dst).Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
                Write-Warning "  [SKIP] $dst already exists (not overwriting)"
            } else {
                Copy-Item $src $dst -Force
                Write-Success "  [OK]   $dst"
            }
        }
    }
}

function Install-ClaudeCodeHook {
    Write-Host ""
    Write-Info "Configuring Claude Code hook (.claude/settings.json)..."

    $settingsDir = Join-Path $PWD ".claude"
    $settingsFile = Join-Path $settingsDir "settings.json"
    $hookScript = Join-Path $SkillRoot "hooks\claude-auto-issue.sh"

    if (-not (Test-Path $hookScript)) {
        Write-Warning "  [SKIP] claude-auto-issue.sh not found in skill"
        return
    }

    # Determine relative path
    $skillRelPath = Resolve-Path -Relative $SkillRoot
    $hookCmd = "bash $skillRelPath/hooks/claude-auto-issue.sh"

    if (Test-Path $settingsFile) {
        # Merge hooks into existing settings.json
        try {
            $settings = Get-Content $settingsFile -Raw | ConvertFrom-Json

            if (-not ($settings.PSObject.Properties.Name -contains "hooks")) {
                $settings | Add-Member -NotePropertyName "hooks" -NotePropertyValue @{}
            }

            $hookConfig = @{
                UserPromptSubmit = @(
                    @{
                        matcher = "*"
                        hooks = @(
                            @{
                                type = "command"
                                command = $hookCmd
                                timeout = 10
                            }
                        )
                    }
                )
            }

            $settings.hooks = $hookConfig
            $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsFile
            Write-Success "  [OK]   Updated $settingsFile with UserPromptSubmit hook"
        }
        catch {
            Write-ErrorMsg "  [ERROR] Failed to update $settingsFile: $_"
        }
    }
    else {
        New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null

        $settings = @{
            hooks = @{
                UserPromptSubmit = @(
                    @{
                        matcher = "*"
                        hooks = @(
                            @{
                                type = "command"
                                command = $hookCmd
                                timeout = 10
                            }
                        )
                    }
                )
            }
        }

        $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsFile
        Write-Success "  [OK]   Created $settingsFile with UserPromptSubmit hook"
    }
}

function Install-ClaudeMD {
    Write-Host ""
    Write-Info "Creating CLAUDE.md with git-workflow instructions..."

    $claudeMd = Join-Path $PWD "CLAUDE.md"

    if ((Test-Path $claudeMd) -and ((Get-Content $claudeMd -Raw) -match "git-workflow")) {
        Write-Warning "  [SKIP] CLAUDE.md already contains git-workflow instructions"
        return
    }

    $skillRelPath = Resolve-Path -Relative $SkillRoot

    $workflowBlock = @"

## Task Execution Workflow

When the user asks to **execute a task**, **implement a task**, or **run a task** (e.g., "execute Task 9"), you MUST use the `git-workflow` skill:

1. **INIT** -- Create a GitHub Issue:
   ``````bash
   python $skillRelPath/scripts/orchestrate.py init --title "<task title>" --description "<task description>"
   ``````

2. **IMPLEMENT** -- Execute the task (code changes, tests, etc.)

3. **FINISH** -- Append completion message and close the Issue:
   ``````bash
   python $skillRelPath/scripts/orchestrate.py finish --message "<completion summary>"
   ``````

This applies to all tasks referenced from task files.

**Do NOT skip the workflow** -- always create an Issue first, then close it after completion.
"@

    if (Test-Path $claudeMd) {
        Add-Content $claudeMd $workflowBlock
        Write-Success "  [OK]   Appended git-workflow instructions to CLAUDE.md"
    }
    else {
        Set-Content $claudeMd "# Project Instructions"
        Add-Content $claudeMd $workflowBlock
        Write-Success "  [OK]   Created CLAUDE.md with git-workflow instructions"
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

    if (-not (Test-GhInstalled)) {
        $response = Read-Host "Install GitHub CLI (gh) now? (y/N)"
        if ($response -match "^[Yy]$") {
            Install-Gh
        }
        else {
            Write-Warning "Skipping gh installation. Some features may not work."
        }
    }

    Write-Host ""

    if ($System) {
        Install-System
    }
    elseif ($Project) {
        Install-Project
        # Always configure Claude Code integration for project installs
        Install-ClaudeCodeHook
        Install-ClaudeMD
    }

    if ($Hooks) {
        Install-Hooks
    }

    Write-Host ""
    Write-Host "Skill installed: $SkillName"
}

Main
