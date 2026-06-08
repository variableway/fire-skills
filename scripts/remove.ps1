#Requires -Version 5.1
<#
.SYNOPSIS
    Unified Skill Remover for Windows (PowerShell).
    Removes skills from agent directories and canonical storage.

.PARAMETER SkillName
    Name of the skill to remove

.PARAMETER System
    Remove from system directories (default)

.PARAMETER Project
    Remove from project directories

.PARAMETER Agent
    Target agent(s). Repeatable. Default: all supported agents.

.PARAMETER KeepCanonical
    Don't remove from canonical storage

.PARAMETER DryRun
    Show what would be removed without deleting

.EXAMPLE
    .\scripts\remove.ps1 git-workflow -System
    Remove git-workflow from all system agent directories

.EXAMPLE
    .\scripts\remove.ps1 anysearch -Project -Agent claude-code
    Remove anysearch from project .claude\skills
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$SkillName,
    [switch]$System,
    [switch]$Project,
    [string[]]$Agent = @(),
    [switch]$KeepCanonical,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$SkillSparkHome = if ($env:SKILL_SPARK_HOME) { $env:SKILL_SPARK_HOME } else { Join-Path $env:USERPROFILE ".skill-spark" }
$CanonicalDir = Join-Path $SkillSparkHome ".agents\skills"

$InstallMode = "system"
if ($Project) { $InstallMode = "project" }

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

function Write-Info  { param([string]$Msg) Write-Host "[INFO] $Msg" -ForegroundColor Cyan }
function Write-Ok    { param([string]$Msg) Write-Host "  [OK]   $Msg" -ForegroundColor Green }
function Write-Skip  { param([string]$Msg) Write-Host "  [SKIP] $Msg" -ForegroundColor Yellow }
function Write-Dry   { param([string]$Msg) Write-Host "  [DRY]  would remove: $Msg" -ForegroundColor Yellow }

function Remove-FromPath {
    param([string]$Path, [string]$Label)

    if (-not (Test-Path $Path) -and -not (Get-Item $Path -ErrorAction SilentlyContinue)) {
        Write-Skip "$Label (not found)"
        return
    }

    if ($DryRun) {
        Write-Dry "$Label -> $Path"
        return
    }

    Remove-Item $Path -Recurse -Force
    Write-Ok "Removed $Label"
    Write-Host "         $Path" -ForegroundColor Gray
}

# Main
if ($Agent.Count -eq 0) {
    $Agent = @("claude-code", "kimi", "codex", "opencode", "trae", "trae-solo", "workbuddy")
}

if ($DryRun) {
    Write-Host "=== DRY RUN ===" -ForegroundColor Yellow
}

Write-Info "Removing '$SkillName' from $InstallMode directories..."
Write-Host ""

foreach ($a in $Agent) {
    if ($InstallMode -eq "system") {
        $agentDir = $SystemTargets[$a]
    } else {
        $agentDir = $ProjectTargets[$a]
    }
    $path = Join-Path $agentDir $SkillName
    Remove-FromPath -Path $path -Label $a
}

# Remove from canonical storage
if (-not $KeepCanonical -and $InstallMode -eq "system") {
    Write-Host ""
    $canonicalPath = Join-Path $CanonicalDir $SkillName
    Remove-FromPath -Path $canonicalPath -Label "canonical storage"
}

Write-Host ""
if ($DryRun) {
    Write-Info "Dry run complete. No files were deleted."
} else {
    Write-Host "Removal complete." -ForegroundColor Green
}
