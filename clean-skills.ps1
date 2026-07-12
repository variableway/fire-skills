#Requires -Version 5.1
<#
.SYNOPSIS
    Clean up AI Agent Skills using skill-spark

.DESCRIPTION
    Removes tracked skills via skill-spark remove, and deletes untracked
    skill directories directly. Supports project-level and global scopes.

.PARAMETER All
    Clean all skills (default if no other filter)

.PARAMETER Global
    Target global skills only (default: project-level)

.PARAMETER Skill
    Clean specific skill by name

.PARAMETER Dir
    Clean all skills under a specific directory

.PARAMETER Agent
    Clean all skills for a specific agent

.PARAMETER DryRun
    Show what would be deleted without actually deleting

.PARAMETER Force
    Auto-confirm without prompting

.EXAMPLE
    .\clean-skills.ps1 -All
    .\clean-skills.ps1 -Skill git-workflow
    .\clean-skills.ps1 -Agent claude-code -DryRun
    .\clean-skills.ps1 -Dir .\.agents\skills -Force

.NOTES
    Directory structure consistency:
    skill-spark supports multiple installation modes (add, sync, map) and
    symlink vs. copy. The installed directory structure is NOT always identical
    to the source directory (e.g. skills/base/):

    - symlink mode (default): source files are copied to central storage
      (.agents/skills/ for project, ~/.skill-spark/.agents/skills/ for global),
      then symlinked into each agent's skills directory.
    - no-symlink mode: files are copied directly into each agent directory.
    - map command: creates symlinks from .agents/skills/ into target agents.

    Because of this, cleanup must handle three layers:
      a) Tracked skills -> use "skill-spark remove" (handles symlink targets)
      b) Untracked/orphaned skills -> delete directly from all agent dirs
      c) Empty directories -> removed after skills are deleted

    This script handles all three layers across all supported agents.
#>
[CmdletBinding()]
param(
    [switch]$All,
    [switch]$Global,
    [string]$Skill,
    [string]$Dir,
    [string]$Agent,
    [switch]$DryRun,
    [switch]$Force
)

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------
$Red    = "`e[0;31m"
$Green  = "`e[0;32m"
$Yellow = "`e[1;33m"
$Blue   = "`e[0;34m"
$Cyan   = "`e[0;36m"
$Reset  = "`e[0m"

function Log-Info  { param([string]$m) Write-Host "${Blue}ℹ${Reset}  $m" }
function Log-Ok    { param([string]$m) Write-Host "${Green}✓${Reset}  $m" }
function Log-Warn  { param([string]$m) Write-Host "${Yellow}⚠${Reset}  $m" }
function Log-Error { param([string]$m) Write-Host "${Red}✗${Reset}  $m" }
function Log-Dry   { param([string]$m) Write-Host "${Cyan}[DRY-RUN]${Reset} $m" }

# ---------------------------------------------------------------------------
# Resolve skill-spark
# ---------------------------------------------------------------------------
function Get-SkillSpark {
    $candidates = @(
        "skill-spark"
        (Join-Path $PSScriptRoot "dist\skill-spark.exe")
        (Join-Path $PSScriptRoot "dist\skill-spark")
    )
    foreach ($c in $candidates) {
        if (Get-Command $c -ErrorAction SilentlyContinue) {
            return $c
        }
    }
    # Try bun dev
    $bun = Get-Command bun -ErrorAction SilentlyContinue
    $tsEntry = Join-Path $PSScriptRoot "src\index.ts"
    if ($bun -and (Test-Path $tsEntry)) {
        return "bun `"$tsEntry`""
    }
    # Try npx
    $npx = Get-Command npx -ErrorAction SilentlyContinue
    if ($npx) {
        return "npx skill-spark"
    }
    throw "skill-spark not found. Please install it first: npm install -g skill-spark"
}

$SkillSpark = $null
try {
    $SkillSpark = Get-SkillSpark
} catch {
    Log-Error $_.Exception.Message
    exit 1
}

function Invoke-SkillSpark {
    param([string[]]$ArgsArray)
    if ($DryRun) {
        Log-Dry "skill-spark $($ArgsArray -join ' ')"
        return
    }
    & $SkillSpark @ArgsArray
}

# ---------------------------------------------------------------------------
# Argument defaults
# ---------------------------------------------------------------------------
if (-not $All -and -not $Skill -and -not $Dir -and -not $Agent) {
    $All = $true
}

# ---------------------------------------------------------------------------
# Lock helpers
# ---------------------------------------------------------------------------
function Get-ProjectLock {
    param([string]$cwd = (Get-Location))
    $p = Join-Path $cwd "skills.lock"
    if (Test-Path $p) { return $p }
    return $null
}

function Get-GlobalLock {
    $p = Join-Path $env:USERPROFILE ".skill-spark\skills.lock"
    if (Test-Path $p) { return $p }
    return $null
}

function Extract-SkillsFromLock {
    param([string]$LockFile)
    if (-not $LockFile -or -not (Test-Path $LockFile)) { return @() }
    try {
        $json = Get-Content $LockFile -Raw | ConvertFrom-Json
        $json.skills.PSObject.Properties.Value | ForEach-Object { $_.name }
    } catch {
        @()
    }
}

# ---------------------------------------------------------------------------
# Agent directory discovery
# ---------------------------------------------------------------------------
function Get-AgentProjectDirs {
    param([string]$cwd = (Get-Location))
    @(
        (Join-Path $cwd ".agents\skills"),
        (Join-Path $cwd ".claude\skills"),
        (Join-Path $cwd ".trae\skills"),
        (Join-Path $cwd ".codex\skills"),
        (Join-Path $cwd ".opencode\skills"),
        (Join-Path $cwd ".cursor\skills"),
        (Join-Path $cwd ".gemini\skills"),
        (Join-Path $cwd ".github-copilot\skills"),
        (Join-Path $cwd ".roo\skills"),
        (Join-Path $cwd ".continue\skills"),
        (Join-Path $cwd ".windsurf\skills"),
        (Join-Path $cwd ".augment\skills"),
        (Join-Path $cwd ".codebuddy\skills"),
        (Join-Path $cwd ".goose\skills"),
        (Join-Path $cwd ".crush\skills"),
        (Join-Path $cwd ".factory\skills"),
        (Join-Path $cwd ".openhands\skills"),
        (Join-Path $cwd ".pi\skills"),
        (Join-Path $cwd ".qwen\skills"),
        (Join-Path $cwd ".qoder\skills"),
        (Join-Path $cwd ".junie\skills"),
        (Join-Path $cwd ".kilocode\skills"),
        (Join-Path $cwd ".mux\skills"),
        (Join-Path $cwd ".vibe\skills"),
        (Join-Path $cwd ".adal\skills"),
        (Join-Path $cwd ".neovate\skills"),
        (Join-Path $cwd ".pochi\skills"),
        (Join-Path $cwd ".zencoder\skills"),
        (Join-Path $cwd ".agent\skills"),
        (Join-Path $cwd ".commandcode\skills"),
        (Join-Path $cwd ".cortex\skills"),
        (Join-Path $cwd ".iflow\skills"),
        (Join-Path $cwd ".kiro\skills"),
        (Join-Path $cwd ".kode\skills"),
        (Join-Path $cwd ".letta\skills"),
        (Join-Path $cwd ".mcpjam\skills"),
        (Join-Path $cwd ".skills"),
        (Join-Path $cwd "skills")
    )
}

function Get-AgentGlobalDirs {
    $homeDir = $env:USERPROFILE
    $configHome = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $homeDir ".config" }
    @(
        (Join-Path $homeDir ".skill-spark\.agents\skills"),
        (Join-Path $homeDir ".agents\skills"),
        (Join-Path $homeDir ".claude\skills"),
        (Join-Path $homeDir ".trae\skills"),
        (Join-Path $homeDir ".trae-cn\skills"),
        (Join-Path $homeDir ".codex\skills"),
        (Join-Path $homeDir ".opencode\skills"),
        (Join-Path $homeDir ".cursor\skills"),
        (Join-Path $homeDir ".copilot\skills"),
        (Join-Path $homeDir ".roo\skills"),
        (Join-Path $homeDir ".continue\skills"),
        (Join-Path $homeDir ".codeium\windsurf\skills"),
        (Join-Path $homeDir ".windsurf\skills"),
        (Join-Path $homeDir ".augment\skills"),
        (Join-Path $homeDir ".codebuddy\skills"),
        (Join-Path $homeDir ".goose\skills"),
        (Join-Path $configHome "goose\skills"),
        (Join-Path $homeDir ".crush\skills"),
        (Join-Path $configHome "crush\skills"),
        (Join-Path $homeDir ".factory\skills"),
        (Join-Path $homeDir ".openhands\skills"),
        (Join-Path $homeDir ".pi\agent\skills"),
        (Join-Path $homeDir ".qwen\skills"),
        (Join-Path $homeDir ".qoder\skills"),
        (Join-Path $homeDir ".junie\skills"),
        (Join-Path $homeDir ".kilocode\skills"),
        (Join-Path $homeDir ".mux\skills"),
        (Join-Path $homeDir ".vibe\skills"),
        (Join-Path $homeDir ".adal\skills"),
        (Join-Path $homeDir ".neovate\skills"),
        (Join-Path $homeDir ".pochi\skills"),
        (Join-Path $homeDir ".zencoder\skills"),
        (Join-Path $homeDir ".agent\skills"),
        (Join-Path $homeDir ".commandcode\skills"),
        (Join-Path $homeDir ".snowflake\cortex\skills"),
        (Join-Path $homeDir ".iflow\skills"),
        (Join-Path $homeDir ".kiro\skills"),
        (Join-Path $homeDir ".kode\skills"),
        (Join-Path $homeDir ".letta\skills"),
        (Join-Path $homeDir ".mcpjam\skills"),
        (Join-Path $configHome "agents\skills"),
        (Join-Path $configHome "opencode\skills"),
        (Join-Path $homeDir ".skills")
    )
}

# ---------------------------------------------------------------------------
# Core helpers
# ---------------------------------------------------------------------------
function Remove-TrackedSkills {
    param([string]$scope, [string[]]$names)
    if ($names.Count -eq 0) { return }
    $extra = @()
    if ($Force) { $extra += "--force" }
    foreach ($name in $names) {
        Log-Info "Removing ${scope} tracked skill: $name"
        Invoke-SkillSpark -ArgsArray (@("remove") + $extra + $name)
    }
}

function Remove-SkillDir {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return }
    if ($DryRun) {
        $item = Get-Item $Path
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            $target = $item.Target
            Log-Dry "Would delete symlink: $Path -> $target"
        } else {
            Log-Dry "Would delete directory: $Path"
        }
        return
    }
    Remove-Item -Recurse -Force $Path
    Log-Ok "Deleted: $Path"
}

function Remove-CommandFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return }
    if ($DryRun) {
        Log-Dry "Would delete command file: $Path"
        return
    }
    Remove-Item -Force $Path
    Log-Ok "Deleted command: $Path"
}

function Clear-EmptyDirs {
    param([string[]]$dirs)
    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) { continue }
        $children = Get-ChildItem $dir -Force -ErrorAction SilentlyContinue
        if (-not $children) {
            if ($DryRun) {
                Log-Dry "Would remove empty dir: $dir"
            } else {
                Remove-Item $dir -Force
                Log-Ok "Removed empty dir: $dir"
            }
        }
    }
}

# ---------------------------------------------------------------------------
# Modes
# ---------------------------------------------------------------------------
function Invoke-CleanAll {
    Log-Info "Mode: clean ALL skills"

    $trackedProject = @()
    $trackedGlobal  = @()

    $projLock = Get-ProjectLock
    if ($projLock) { $trackedProject = Extract-SkillsFromLock $projLock }

    $globLock = Get-GlobalLock
    if ($globLock) { $trackedGlobal = Extract-SkillsFromLock $globLock }

    if (-not $Global) {
        Remove-TrackedSkills -scope "project" -names $trackedProject
    }
    Remove-TrackedSkills -scope "global" -names $trackedGlobal

    $allDirs = @()
    if (-not $Global) {
        $allDirs += Get-AgentProjectDirs
    }
    $allDirs += Get-AgentGlobalDirs

    foreach ($dir in $allDirs) {
        if (-not (Test-Path $dir)) { continue }
        $items = Get-ChildItem $dir -Force -ErrorAction SilentlyContinue
        foreach ($item in $items) {
            $base = $item.Name
            # Skip tracked items we already removed
            $isTracked = $trackedProject + $trackedGlobal | ForEach-Object { $_.ToLower() } | Where-Object { $_ -eq $base.ToLower() }
            if ($isTracked) { continue }

            # Only delete items that look like skills
            if ($item.PSIsContainer) {
                $skillMd = Join-Path $item.FullName "SKILL.md"
                if (Test-Path $skillMd) {
                    Remove-SkillDir $item.FullName
                }
            } elseif ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                Remove-SkillDir $item.FullName
            } elseif ($base.EndsWith(".md")) {
                Remove-CommandFile $item.FullName
            }
        }
    }

    Clear-EmptyDirs $allDirs
}

function Invoke-CleanSkill {
    param([string]$name)
    Log-Info "Mode: clean specific skill '$name'"

    # Try skill-spark remove first
    Invoke-SkillSpark -ArgsArray @("remove", "--force", $name)

    # Also scan directories for stray copies
    $allDirs = @()
    if (-not $Global) { $allDirs += Get-AgentProjectDirs }
    $allDirs += Get-AgentGlobalDirs

    $found = $false
    foreach ($dir in $allDirs) {
        if (-not (Test-Path $dir)) { continue }
        $candidates = @(
            (Join-Path $dir $name),
            (Join-Path $dir "$name.md")
        )
        foreach ($c in $candidates) {
            if (Test-Path $c) {
                if ((Get-Item $c).PSIsContainer) {
                    Remove-SkillDir $c
                } else {
                    Remove-CommandFile $c
                }
                $found = $true
            }
        }
    }

    if (-not $found -and -not $DryRun) {
        Log-Warn "Skill not found anywhere: $name"
    }
}

function Invoke-CleanDir {
    param([string]$target)
    $target = Resolve-Path $target -ErrorAction SilentlyContinue
    if (-not $target -or -not (Test-Path $target)) {
        Log-Error "Directory does not exist: $target"
        exit 1
    }

    Log-Info "Mode: clean all skills under directory: $target"

    $items = Get-ChildItem $target -Force -ErrorAction SilentlyContinue
    foreach ($item in $items) {
        if ($item.PSIsContainer -and (Test-Path (Join-Path $item.FullName "SKILL.md"))) {
            Remove-SkillDir $item.FullName
        } elseif ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            Remove-SkillDir $item.FullName
        } elseif ($item.Name.EndsWith(".md")) {
            Remove-CommandFile $item.FullName
        }
    }

    # Remove lock file if sibling exists
    $parent = Split-Path $target -Parent
    $lockFile = Join-Path $parent "skills.lock"
    if (Test-Path $lockFile) {
        if ($DryRun) {
            Log-Dry "Would clear lock file: $lockFile"
        } else {
            Remove-Item $lockFile -Force
            Log-Ok "Removed lock file: $lockFile"
        }
    }
}

function Invoke-CleanAgent {
    param([string]$agent)
    Log-Info "Mode: clean all skills for agent: $agent"

    $agentLower = $agent.ToLower()
    $dirsToCheck = @()

    switch -Regex ($agentLower) {
        "^(claude|claudecode|claude-code)$" {
            $dirsToCheck += ".claude\skills", "$env:USERPROFILE\.claude\skills"
        }
        "^(kimi|kimi-cli|kimicode|kimi-code)$" {
            $dirsToCheck += ".agents\skills", "$env:USERPROFILE\.agents\skills"
        }
        "^codex$" {
            $dirsToCheck += ".agents\skills", ".codex\skills", "$env:USERPROFILE\.codex\skills"
        }
        "^(opencode|open-code)$" {
            $dirsToCheck += ".agents\skills", ".opencode\skills", "$env:USERPROFILE\.opencode\skills"
        }
        "^trae$" {
            $dirsToCheck += ".trae\skills", "$env:USERPROFILE\.trae\skills"
        }
        "^(trae-cn|traecn)$" {
            $dirsToCheck += ".trae\skills", "$env:USERPROFILE\.trae-cn\skills"
        }
        "^cursor$" {
            $dirsToCheck += ".agents\skills", "$env:USERPROFILE\.cursor\skills"
        }
        "^(copilot|github-copilot)$" {
            $dirsToCheck += ".agents\skills", "$env:USERPROFILE\.copilot\skills"
        }
        "^droid$" {
            $dirsToCheck += ".factory\skills", "$env:USERPROFILE\.factory\skills"
        }
        "^windsurf$" {
            $dirsToCheck += ".windsurf\skills", "$env:USERPROFILE\.codeium\windsurf\skills", "$env:USERPROFILE\.windsurf\skills"
        }
        "^(roo|roo-code)$" {
            $dirsToCheck += ".roo\skills", "$env:USERPROFILE\.roo\skills"
        }
        "^continue$" {
            $dirsToCheck += ".continue\skills", "$env:USERPROFILE\.continue\skills"
        }
        "^augment$" {
            $dirsToCheck += ".augment\skills", "$env:USERPROFILE\.augment\skills"
        }
        "^codebuddy$" {
            $dirsToCheck += ".codebuddy\skills", "$env:USERPROFILE\.codebuddy\skills"
        }
        "^goose$" {
            $dirsToCheck += ".goose\skills", "$env:USERPROFILE\.goose\skills", "$env:XDG_CONFIG_HOME\goose\skills"
        }
        "^crush$" {
            $dirsToCheck += ".crush\skills", "$env:USERPROFILE\.crush\skills", "$env:XDG_CONFIG_HOME\crush\skills"
        }
        "^openhands$" {
            $dirsToCheck += ".openhands\skills", "$env:USERPROFILE\.openhands\skills"
        }
        "^pi$" {
            $dirsToCheck += ".pi\skills", "$env:USERPROFILE\.pi\agent\skills"
        }
        "^(qwen|qwen-code)$" {
            $dirsToCheck += ".qwen\skills", "$env:USERPROFILE\.qwen\skills"
        }
        "^qoder$" {
            $dirsToCheck += ".qoder\skills", "$env:USERPROFILE\.qoder\skills"
        }
        "^junie$" {
            $dirsToCheck += ".junie\skills", "$env:USERPROFILE\.junie\skills"
        }
        "^(kilo|kilocode)$" {
            $dirsToCheck += ".kilocode\skills", "$env:USERPROFILE\.kilocode\skills"
        }
        "^mux$" {
            $dirsToCheck += ".mux\skills", "$env:USERPROFILE\.mux\skills"
        }
        "^(vibe|mistral-vibe|mistral)$" {
            $dirsToCheck += ".vibe\skills", "$env:USERPROFILE\.vibe\skills"
        }
        "^adal$" {
            $dirsToCheck += ".adal\skills", "$env:USERPROFILE\.adal\skills"
        }
        "^neovate$" {
            $dirsToCheck += ".neovate\skills", "$env:USERPROFILE\.neovate\skills"
        }
        "^pochi$" {
            $dirsToCheck += ".pochi\skills", "$env:USERPROFILE\.pochi\skills"
        }
        "^zencoder$" {
            $dirsToCheck += ".zencoder\skills", "$env:USERPROFILE\.zencoder\skills"
        }
        "^cortex$" {
            $dirsToCheck += ".cortex\skills", "$env:USERPROFILE\.snowflake\cortex\skills"
        }
        "^command-code$" {
            $dirsToCheck += ".commandcode\skills", "$env:USERPROFILE\.commandcode\skills"
        }
        "^(iflow|iflow-cli)$" {
            $dirsToCheck += ".iflow\skills", "$env:USERPROFILE\.iflow\skills"
        }
        "^(kiro|kiro-cli)$" {
            $dirsToCheck += ".kiro\skills", "$env:USERPROFILE\.kiro\skills"
        }
        "^kode$" {
            $dirsToCheck += ".kode\skills", "$env:USERPROFILE\.kode\skills"
        }
        "^letta$" {
            $dirsToCheck += ".skills", "$env:USERPROFILE\.letta\skills"
        }
        "^mcpjam$" {
            $dirsToCheck += ".mcpjam\skills", "$env:USERPROFILE\.mcpjam\skills"
        }
        "^(universal|common|agents|agent)$" {
            $dirsToCheck += ".agents\skills", "$env:USERPROFILE\.agents\skills", "$env:USERPROFILE\.skill-spark\.agents\skills"
        }
        default {
            Log-Warn "Unknown agent '$agent', trying generic paths..."
            $dirsToCheck += ".$agent\skills", "$env:USERPROFILE\.$agent\skills"
        }
    }

    $foundAny = $false
    foreach ($rel in $dirsToCheck) {
        $dir = $rel
        if (-not [System.IO.Path]::IsPathRooted($rel)) {
            $dir = Join-Path (Get-Location) $rel
        }
        if (-not (Test-Path $dir)) { continue }
        $foundAny = $true
        $items = Get-ChildItem $dir -Force -ErrorAction SilentlyContinue
        foreach ($item in $items) {
            Remove-SkillDir $item.FullName
        }
        Clear-EmptyDirs @($dir)
    }

    if (-not $foundAny) {
        Log-Warn "No skill directories found for agent: $agent"
    }
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
if ($DryRun) {
    Write-Host ""
    Log-Dry "DRY RUN — no files will be deleted"
    Write-Host ""
}

if ($Skill) {
    Invoke-CleanSkill $Skill
} elseif ($Dir) {
    Invoke-CleanDir $Dir
} elseif ($Agent) {
    Invoke-CleanAgent $Agent
} elseif ($All) {
    Invoke-CleanAll
}

Write-Host ""
if ($DryRun) {
    Log-Dry "Dry run complete. No files were deleted."
} else {
    Log-Ok "Clean complete."
}
