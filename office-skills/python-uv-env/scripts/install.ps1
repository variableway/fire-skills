#Requires -Version 5.1
<#
.SYNOPSIS
    Python UV Env Skill Installer for Windows.
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

function Write-ColorOutput { param([string]$Message, [string]$Color = "White") Write-Host $Message -ForegroundColor $Color }
function Write-Success { param([string]$Message) Write-ColorOutput $Message "Green" }
function Write-Warning { param([string]$Message) Write-ColorOutput $Message "Yellow" }
function Write-ErrorMsg { param([string]$Message) Write-ColorOutput $Message "Red" }
function Write-Info { param([string]$Message) Write-ColorOutput $Message "Cyan" }

function Test-Deps {
    Write-Info "Checking dependencies..."
    try { uv --version 2>$null | Out-Null; Write-Success "[OK] uv available" }
    catch {
        Write-Warning "[WARN] uv not found."
        Write-Host "  Install: powershell -c 'irm https://astral.sh/uv/install.ps1 | iex'"
        $response = Read-Host "Continue anyway? (y/N)"
        if ($response -notmatch "^[Yy]$") { exit 1 }
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
            $dirs += Join-Path $homePath ".trae\skills"
        }
        "claude-code" { $dirs += Join-Path $homePath ".claude\skills" }
        "kimi" { $dirs += Join-Path $homePath ".kimi\skills"; $dirs += Join-Path $homePath ".config\agents\skills" }
        "codex" { $dirs += Join-Path $homePath ".codex\skills" }
        "opencode" { $dirs += Join-Path $homePath ".opencode\skills" }
        { $_ -in "trae", "trae-solo" } { $dirs += Join-Path $homePath ".trae\skills" }
        default { Write-ErrorMsg "Error: Unknown agent '$Agent'"; exit 1 }
    }
    return $dirs
}

function Get-ProjectTargetDirs {
    return @((Join-Path $PWD ".agents\skills"), (Join-Path $PWD ".kimi\skills"), (Join-Path $PWD ".claude\skills"))
}

function New-SkillLink {
    param([string]$TargetDir)
    $linkPath = Join-Path $TargetDir $SkillName
    if ((Test-Path $linkPath) -or (Get-Item $linkPath -ErrorAction SilentlyContinue)) {
        Write-Warning "  [SKIP] $SkillName already exists at $linkPath"
        return $false
    }
    $parentDir = Split-Path -Parent $linkPath
    if (-not (Test-Path $parentDir)) { New-Item -ItemType Directory -Path $parentDir -Force | Out-Null }
    try {
        New-Item -ItemType SymbolicLink -Path $linkPath -Target $SkillRoot -Force | Out-Null
        Write-Success "  [OK]   $SkillName -> $linkPath"
        return $true
    } catch {
        try {
            New-Item -ItemType Junction -Path $linkPath -Target $SkillRoot -Force | Out-Null
            Write-Success "  [OK]   $SkillName -> $linkPath (junction)"
            return $true
        } catch {
            Write-ErrorMsg "  [ERROR] Failed to create link: $_"
            return $false
        }
    }
}

function Install-System {
    Write-Info "Installing $SkillName to system directories..."
    $targetDirs = Get-SystemTargetDirs
    $installed = 0; $skipped = 0
    foreach ($targetDir in $targetDirs) {
        if (New-SkillLink -TargetDir $targetDir) { $installed++ } else { $skipped++ }
    }
    Write-Host ""; Write-Success "System installation complete."; Write-Host "  Installed: $installed`n  Skipped: $skipped"
}

function Install-Project {
    Write-Info "Installing $SkillName to project directories..."
    if (-not (Test-Path ".git")) {
        Write-Warning "Warning: Not a git repository."
        $response = Read-Host "Continue anyway? (y/N)"
        if ($response -notmatch "^[Yy]$") { exit 1 }
    }
    $targetDirs = Get-ProjectTargetDirs
    $installed = 0; $skipped = 0
    foreach ($targetDir in $targetDirs) {
        if (New-SkillLink -TargetDir $targetDir) { $installed++ } else { $skipped++ }
    }
    Write-Host ""; Write-Success "Project installation complete."; Write-Host "  Installed: $installed`n  Skipped: $skipped"
}

function Main {
    if (-not $System -and -not $Project) {
        Write-ErrorMsg "Error: Must specify -System or -Project"
        Write-Host "  .\install.ps1 -System`n  .\install.ps1 -System -Agent trae`n  .\install.ps1 -Project"
        exit 1
    }
    Write-Info "Detected OS: Windows`n"
    Test-Deps; Write-Host ""
    if ($System) { Install-System } elseif ($Project) { Install-Project }
    Write-Host "`nSkill installed: $SkillName"
}

Main
