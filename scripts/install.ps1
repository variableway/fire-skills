#Requires -Version 5.1
<#
.SYNOPSIS
    Unified Skill Installer for Windows (PowerShell).
    Copies skills to canonical storage then symlinks/junctions to agent directories.

.PARAMETER Source
    Path to skills source directory (e.g., skills\devops, skills\base)

.PARAMETER System
    Install to system skill directories (default)

.PARAMETER Project
    Install to current project directory

.PARAMETER Global
    Alias for -System

.PARAMETER Agent
    Target agent(s). Repeatable. Default: all supported agents.

.PARAMETER Skill
    Install specific skill(s) only. Repeatable.

.PARAMETER NoSymlink
    Copy directly instead of creating symlinks/junctions.

.EXAMPLE
    .\scripts\install.ps1 skills\devops -System
    Install all devops skills to system directories

.EXAMPLE
    .\scripts\install.ps1 skills\base -Project -Agent claude-code
    Install base skills to project .claude\skills

.EXAMPLE
    .\scripts\install.ps1 skills\devops -System -Skill git-workflow -Skill local-workflow
    Install only git-workflow and local-workflow
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Source,
    [switch]$System,
    [switch]$Project,
    [switch]$Global,
    [string[]]$Agent = @(),
    [string[]]$Skill = @(),
    [switch]$NoSymlink
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$SkillSparkHome = if ($env:SKILL_SPARK_HOME) { $env:SKILL_SPARK_HOME } else { Join-Path $env:USERPROFILE ".skill-spark" }
$CanonicalDir = Join-Path $SkillSparkHome ".agents\skills"

# Resolve source path
if (-not [System.IO.Path]::IsPathRooted($Source)) {
    $Source = Join-Path $ProjectRoot $Source
}
if (-not (Test-Path $Source)) {
    Write-Error "Source directory not found: $Source"
    exit 1
}

# Determine install mode
$InstallMode = "system"
if ($Project) { $InstallMode = "project" }
# -Global is alias for -System

# Agent target directories
$SystemTargets = @{
    "claude-code" = Join-Path $env:USERPROFILE ".claude\skills"
    "kimi"        = Join-Path $env:USERPROFILE ".kimi\skills"
    "codex"       = Join-Path $env:USERPROFILE ".codex\skills"
    "opencode"    = Join-Path $env:USERPROFILE ".opencode\skills"
    "trae"        = Join-Path $env:USERPROFILE ".trae\skills"
    "trae-solo"   = Join-Path $env:USERPROFILE ".trae\skills"
    "workbuddy"   = Join-Path $env:USERPROFILE ".workbuddy\skills"
}

$ProjectTargets = @{
    "claude-code" = ".claude\skills"
    "kimi"        = ".kimi\skills"
    "codex"       = ".codex\skills"
    "opencode"    = ".opencode\skills"
    "trae"        = ".trae\skills"
    "trae-solo"   = ".trae\skills"
    "workbuddy"   = ".workbuddy\skills"
    "common"      = ".agents\skills"
}

function Write-Info    { param([string]$Msg) Write-Host "[INFO] $Msg" -ForegroundColor Cyan }
function Write-Ok      { param([string]$Msg) Write-Host "  [OK]   $Msg" -ForegroundColor Green }
function Write-Skip    { param([string]$Msg) Write-Host "  [SKIP] $Msg" -ForegroundColor Yellow }
function Write-Err     { param([string]$Msg) Write-Host "  [ERR]  $Msg" -ForegroundColor Red }
function Write-Detail  { param([string]$Msg) Write-Host "         $Msg" -ForegroundColor Gray }

function Get-SkillName {
    param([string]$SkillDir)
    $skillMd = Join-Path $SkillDir "SKILL.md"
    if (Test-Path $skillMd) {
        $content = Get-Content $skillMd -Raw
        if ($content -match "(?m)^name:\s*(.+)$") {
            return $Matches[1].Trim()
        }
    }
    return Split-Path $SkillDir -Leaf
}

function Find-Skills {
    param([string]$SourcePath)
    $found = @()

    # Direct skill
    if (Test-Path (Join-Path $SourcePath "SKILL.md")) {
        $found += $SourcePath
        return $found
    }

    # Category directory
    $skillMds = Get-ChildItem -Path $SourcePath -Filter "SKILL.md" -Recurse -Depth 2
    foreach ($md in $skillMds) {
        $found += $md.DirectoryName
    }

    return $found | Select-Object -Unique
}

function Copy-ToCanonical {
    param([string]$SourcePath, [string]$Name)
    $target = Join-Path $CanonicalDir $Name

    if (Test-Path $target) {
        Remove-Item $target -Recurse -Force
    }
    New-Item -ItemType Directory -Path $target -Force | Out-Null

    $excluded = @(".git", "node_modules", "__pycache__", ".DS_Store", ".env", ".env.local")
    Get-ChildItem -Path $SourcePath -Force | Where-Object {
        $excluded -notcontains $_.Name
    } | ForEach-Object {
        $dest = Join-Path $target $_.Name
        if ($_.PSIsContainer) {
            Copy-Item $_.FullName -Destination $dest -Recurse -Force
        } else {
            Copy-Item $_.FullName -Destination $dest -Force
        }
    }
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
    catch { return $false }
}

function Install-ToAgent {
    param([string]$Name, [string]$AgentName, [string]$AgentDir)

    $linkPath = Join-Path $AgentDir $Name

    if ((Test-Path $linkPath) -or (Get-Item $linkPath -ErrorAction SilentlyContinue)) {
        Write-Skip "$Name -> $AgentName (already exists)"
        return $false
    }

    $parentDir = Split-Path -Parent $linkPath
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    $canonicalPath = Join-Path $CanonicalDir $Name

    if (-not $NoSymlink) {
        # Try symlink first
        if (Test-SymlinkCapability) {
            try {
                New-Item -ItemType SymbolicLink -Path $linkPath -Target $canonicalPath -Force | Out-Null
                Write-Ok "$Name -> $AgentName"
                Write-Detail $linkPath
                return $true
            }
            catch { }
        }

        # Fallback to junction
        try {
            New-Item -ItemType Junction -Path $linkPath -Target $canonicalPath -Force | Out-Null
            Write-Ok "$Name -> $AgentName (junction)"
            Write-Detail $linkPath
            return $true
        }
        catch {
            Write-Err "Failed to create link: $_"
            return $false
        }
    } else {
        # Direct copy
        Copy-Item -Path $canonicalPath -Destination $linkPath -Recurse -Force
        Write-Ok "$Name -> $AgentName (copy)"
        Write-Detail $linkPath
        return $true
    }
}

# Main
function Main {
    # Default agents
    if ($Agent.Count -eq 0) {
        $Agent = @("claude-code", "kimi", "codex", "opencode", "trae", "trae-solo", "workbuddy")
    }

    # Validate agents
    foreach ($a in $Agent) {
        if (-not $SystemTargets.ContainsKey($a)) {
            Write-Error "Unknown agent: $a. Supported: $($SystemTargets.Keys -join ', ')"
            exit 1
        }
    }

    $osLabel = if ($env:WSL_DISTRO_NAME) { "Windows WSL2" } else { "Windows" }
    Write-Info "Detected: $osLabel"
    Write-Info "Mode: $InstallMode | Agents: $($Agent -join ', ')"
    Write-Host ""

    # Find skills
    $skillDirs = Find-Skills -SourcePath $Source
    if ($skillDirs.Count -eq 0) {
        Write-Error "No skills found in: $Source"
        exit 1
    }

    # Filter by --skill
    if ($Skill.Count -gt 0) {
        $skillDirs = $skillDirs | Where-Object {
            $name = Get-SkillName $_
            $dirName = Split-Path $_ -Leaf
            ($Skill -contains $name) -or ($Skill -contains $dirName)
        }
    }

    if ($skillDirs.Count -eq 0) {
        Write-Error "No matching skills found for: $($Skill -join ', ')"
        exit 1
    }

    Write-Info "Skills found: $($skillDirs.Count)"
    Write-Host ""

    $totalInstalled = 0
    $totalSkipped = 0

    foreach ($skillDir in $skillDirs) {
        $name = Get-SkillName $skillDir
        Write-Host "[$name]" -ForegroundColor Cyan

        # Copy to canonical storage
        if (-not $NoSymlink) {
            Copy-ToCanonical -SourcePath $skillDir -Name $name
            Write-Detail "canonical: $(Join-Path $CanonicalDir $name)"
        }

        $installed = 0
        $skipped = 0

        foreach ($a in $Agent) {
            if ($InstallMode -eq "system") {
                $agentDir = $SystemTargets[$a]
            } else {
                $agentDir = $ProjectTargets[$a]
            }

            if (Install-ToAgent -Name $name -AgentName $a -AgentDir $agentDir) {
                $installed++
            } else {
                $skipped++
            }
        }

        $totalInstalled += $installed
        $totalSkipped += $skipped
        Write-Host ""
    }

    Write-Host "Installation complete! Installed: $totalInstalled, Skipped: $totalSkipped" -ForegroundColor Green
}

Main
