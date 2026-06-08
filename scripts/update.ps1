#Requires -Version 5.1
<#
.SYNOPSIS
    Unified Skill Updater for Windows (PowerShell).
    Re-installs skills from source to update them.

.PARAMETER Source
    Path to skills source directory

.PARAMETER System
    Update system skills (default)

.PARAMETER Project
    Update project skills

.PARAMETER Agent
    Target agent(s). Repeatable. Default: all.

.PARAMETER Skill
    Update specific skill(s) only. Repeatable.

.PARAMETER Force
    Remove existing installations before reinstalling

.EXAMPLE
    .\scripts\update.ps1 skills\devops -System -Force
    Force update all devops skills

.EXAMPLE
    .\scripts\update.ps1 skills\base -System -Skill anysearch -Force
    Force update only anysearch
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Source,
    [switch]$System,
    [switch]$Project,
    [string[]]$Agent = @(),
    [string[]]$Skill = @(),
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

# Resolve source path
if (-not [System.IO.Path]::IsPathRooted($Source)) {
    $Source = Join-Path $ProjectRoot $Source
}
if (-not (Test-Path $Source)) {
    Write-Error "Source directory not found: $Source"
    exit 1
}

$InstallMode = "system"
if ($Project) { $InstallMode = "project" }

Write-Host "[INFO] Updating skills from: $Source" -ForegroundColor Cyan
Write-Host ""

# Build args for install script
$installArgs = @($Source)
if ($InstallMode -eq "system") { $installArgs += "-System" }
else { $installArgs += "-Project" }
foreach ($a in $Agent) { $installArgs += "-Agent"; $installArgs += $a }
foreach ($s in $Skill) { $installArgs += "-Skill"; $installArgs += $s }
$installArgs += "-NoSymlink"

if ($Force) {
    Write-Host "[INFO] Force mode: removing existing installations first..." -ForegroundColor Cyan

    $SkillSparkHome = if ($env:SKILL_SPARK_HOME) { $env:SKILL_SPARK_HOME } else { Join-Path $env:USERPROFILE ".skill-spark" }
    $CanonicalDir = Join-Path $SkillSparkHome ".agents\skills"

    # Find skills in source
    $skillMds = Get-ChildItem -Path $Source -Filter "SKILL.md" -Recurse -Depth 3
    foreach ($md in $skillMds) {
        $skillDir = $md.DirectoryName
        $name = Split-Path $skillDir -Leaf

        # Check filter
        if ($Skill.Count -gt 0 -and ($Skill -notcontains $name)) {
            # Try reading name from frontmatter
            $content = Get-Content $md.FullName -Raw
            if ($content -match "(?m)^name:\s*(.+)$") {
                $frontmatterName = $Matches[1].Trim()
                if ($Skill -notcontains $frontmatterName) { continue }
                $name = $frontmatterName
            } else {
                continue
            }
        }

        # Run remove
        $removeArgs = @($name)
        if ($InstallMode -eq "system") { $removeArgs += "-System" }
        else { $removeArgs += "-Project" }
        foreach ($a in $Agent) { $removeArgs += "-Agent"; $removeArgs += $a }
        $removeArgs += "-KeepCanonical"

        & "$ScriptDir\remove.ps1" @removeArgs 2>$null
    }

    Write-Host ""
}

Write-Host "[INFO] Installing updated skills..." -ForegroundColor Cyan
& "$ScriptDir\install.ps1" @installArgs

Write-Host ""
Write-Host "Update complete!" -ForegroundColor Green
