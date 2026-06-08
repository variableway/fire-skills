#!/usr/bin/env pwsh
# Unified Dev Workflow skill manager for Windows PowerShell and pwsh.

param(
    [Parameter(Position = 0)]
    [ValidateSet("install", "add", "remove", "delete", "update", "outdated", "status", "hooks", "list", "verify", "doctor")]
    [string]$Command = "install",

    [ValidateSet("project", "system", "global")]
    [string]$Scope = "project",

    [Alias("a")]
    [string[]]$Agent = @("codex"),

    [Alias("s")]
    [string[]]$Skill = @("git-workflow", "local-workflow"),

    [switch]$Global,
    [switch]$Project,
    [switch]$AllDevops,
    [switch]$NoSymlink,
    [switch]$Force,
    [switch]$Yes
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = (Resolve-Path (Join-Path $ScriptDir "..")).Path
$Cli = Join-Path $RootDir "dist/skill-spark"
$IsWindowsHost = $env:OS -eq "Windows_NT"
if ($IsWindowsHost) {
    $CliCmd = $Cli + ".cmd"
    if (Test-Path $CliCmd) { $Cli = $CliCmd }
}
$Source = Join-Path $RootDir "skills/devops"
$AllDevopsSkills = @("gh-create-release", "git-workflow", "github-cli", "local-workflow", "scanning-for-secrets")

if ($Global) { $Scope = "system" }
if ($Project) { $Scope = "project" }
if ($AllDevops -and $Command -in @("install", "add", "list")) { $Skill = @() }
elseif ($AllDevops) { $Skill = $AllDevopsSkills }
if (-not $Yes -and -not $Force) { $Yes = $true }

function Normalize-Agent([string]$Name) {
    switch ($Name) {
        "kimi" { "kimi-cli"; break }
        "claude" { "claude-code"; break }
        default { $Name }
    }
}

function Get-ConfigHome {
    if ($env:XDG_CONFIG_HOME) { return $env:XDG_CONFIG_HOME }
    return Join-Path $HOME ".config"
}

function Get-GlobalSkillDir([string]$Name) {
    $agentName = Normalize-Agent $Name
    $configHome = Get-ConfigHome
    switch ($agentName) {
        "codex" {
            if ($env:CODEX_HOME) { return Join-Path $env:CODEX_HOME "skills" }
            return Join-Path $HOME ".codex/skills"
        }
        "claude-code" {
            if ($env:CLAUDE_CONFIG_DIR) { return Join-Path $env:CLAUDE_CONFIG_DIR "skills" }
            return Join-Path $HOME ".claude/skills"
        }
        "opencode" { return Join-Path $configHome "opencode/skills" }
        "trae" { return Join-Path $HOME ".trae/skills" }
        "trae-cn" { return Join-Path $HOME ".trae-cn/skills" }
        "kimi-cli" { return Join-Path $configHome "agents/skills" }
        "universal" { return Join-Path $configHome "agents/skills" }
        default { return Join-Path $HOME ".$agentName/skills" }
    }
}

function Get-ProjectSkillDir([string]$Name) {
    $agentName = Normalize-Agent $Name
    switch ($agentName) {
        "claude-code" { return Join-Path $RootDir ".claude/skills" }
        "trae" { return Join-Path $RootDir ".trae/skills" }
        "trae-cn" { return Join-Path $RootDir ".trae/skills" }
        default { return Join-Path $RootDir ".agents/skills" }
    }
}

function Invoke-SkillSpark([string[]]$ArgsList) {
    if (-not (Test-Path $Cli)) {
        throw "skill-spark executable not found at $Cli. Build it first."
    }
    & $Cli @ArgsList
    if ($LASTEXITCODE -ne 0) {
        throw "skill-spark failed with exit code $LASTEXITCODE"
    }
}

function Remove-WorkflowPaths {
    foreach ($agentName in $Agent) {
        if ($Scope -eq "system" -or $Scope -eq "global") {
            $base = Get-GlobalSkillDir $agentName
        } else {
            $base = Get-ProjectSkillDir $agentName
        }
        foreach ($skillName in $Skill) {
            $path = Join-Path $base $skillName
            Remove-Item -Recurse -Force $path -ErrorAction SilentlyContinue
            Write-Host "Removed $path"
        }
    }
}

function Remove-GlobalLockEntries {
    $lock = Join-Path $HOME ".skill-spark/skills.lock"
    if (-not (Test-Path $lock)) { return }

    try {
        $data = Get-Content $lock -Raw | ConvertFrom-Json
    } catch {
        return
    }

    if (-not $data.skills) { return }
    foreach ($skillName in $Skill) {
        $key = "skill:$($skillName.ToLowerInvariant())"
        $data.skills.PSObject.Properties.Remove($key)
    }

    if ($data.skills.PSObject.Properties.Count -gt 0) {
        $data | ConvertTo-Json -Depth 20 | Set-Content -Path $lock -Encoding UTF8
    } else {
        Remove-Item -Force $lock -ErrorAction SilentlyContinue
    }
}

function Test-WorkflowPaths {
    $missing = $false
    foreach ($agentName in $Agent) {
        if ($Scope -eq "system" -or $Scope -eq "global") {
            $base = Get-GlobalSkillDir $agentName
        } else {
            $base = Get-ProjectSkillDir $agentName
        }
        foreach ($skillName in $Skill) {
            $path = Join-Path (Join-Path $base $skillName) "SKILL.md"
            if (Test-Path $path) {
                Write-Host "OK: $path"
            } else {
                Write-Error "Missing: $path" -ErrorAction Continue
                $missing = $true
            }
        }
    }
    if ($missing) { exit 1 }
}

function Install-GitWorkflowHooks {
    $hooksDir = (& git rev-parse --git-path hooks 2>$null)
    if (-not $hooksDir) {
        Write-Warning "Not a git repository; skip git hooks"
        return
    }
    New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
    $srcDir = Join-Path $RootDir ".agents/skills/git-workflow/hooks"
    if (-not (Test-Path $srcDir)) { $srcDir = Join-Path $RootDir "skills/devops/git-workflow/hooks" }
    foreach ($hookName in @("prepare-commit-msg", "post-commit")) {
        $src = Join-Path $srcDir $hookName
        $dst = Join-Path $hooksDir $hookName
        if (Test-Path $src) {
            Copy-Item $src $dst -Force
            Write-Host "OK: $dst"
        }
    }
}

function Install-ClaudeWorkflowHook {
    $settingsDir = Join-Path $RootDir ".claude"
    New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
    $settingsFile = Join-Path $settingsDir "settings.json"
    $hookCmd = "bash .agents/skills/git-workflow/hooks/claude-auto-issue.sh"
    if (-not (Test-Path (Join-Path $RootDir ".agents/skills/git-workflow/hooks/claude-auto-issue.sh")) -and (Test-Path (Join-Path $RootDir ".claude/skills/git-workflow/hooks/claude-auto-issue.sh"))) {
        $hookCmd = "bash .claude/skills/git-workflow/hooks/claude-auto-issue.sh"
    }
    if (Test-Path $settingsFile) {
        try { $settings = Get-Content $settingsFile -Raw | ConvertFrom-Json } catch { $settings = [pscustomobject]@{} }
    } else {
        $settings = [pscustomobject]@{}
    }
    if (-not ($settings.PSObject.Properties.Name -contains "hooks")) {
        $settings | Add-Member -NotePropertyName "hooks" -NotePropertyValue ([pscustomobject]@{})
    }
    $settings.hooks | Add-Member -Force -NotePropertyName "UserPromptSubmit" -NotePropertyValue @(
        [pscustomobject]@{
            matcher = "*"
            hooks = @([pscustomobject]@{ type = "command"; command = $hookCmd; timeout = 10 })
        }
    )
    $settings | ConvertTo-Json -Depth 20 | Set-Content -Path $settingsFile -Encoding UTF8
    Write-Host "OK: $settingsFile UserPromptSubmit -> $hookCmd"
}

function Show-HookDiagnosis {
    Write-Host "Hook diagnosis:"
    $codexSkill = Join-Path $RootDir ".agents/skills/git-workflow/SKILL.md"
    if (Test-Path $codexSkill) { Write-Host "  OK: git-workflow installed for Codex/universal agents" }
    else { Write-Host "  Missing: $codexSkill" }
    $claudeSettings = Join-Path $RootDir ".claude/settings.json"
    if (Test-Path $claudeSettings) { Write-Host "  OK: .claude/settings.json exists" }
    else { Write-Host "  Missing: .claude/settings.json (Claude Code hook is not installed)" }
    $hooksDir = (& git rev-parse --git-path hooks 2>$null)
    if ($hooksDir) {
        Write-Host "- Git hooks dir: $hooksDir"
        foreach ($hookName in @("prepare-commit-msg", "post-commit")) {
            $hookPath = Join-Path $hooksDir $hookName
            if (Test-Path $hookPath) { Write-Host "  OK: $hookName" }
            else { Write-Host "  Missing: $hookName" }
        }
    }
}

$normalizedAgents = @()
foreach ($agentName in $Agent) { $normalizedAgents += (Normalize-Agent $agentName) }
$Agent = $normalizedAgents

$globalArgs = @()
if ($Scope -eq "system" -or $Scope -eq "global") { $globalArgs += "--global" }

$agentArgs = @()
foreach ($agentName in $Agent) { $agentArgs += @("--agent", $agentName) }

$skillArgs = @()
foreach ($skillName in $Skill) { $skillArgs += @("--skill", $skillName) }

$confirmArgs = @()
if ($Force) { $confirmArgs += "--force" } elseif ($Yes) { $confirmArgs += "--yes" }
if ($NoSymlink) { $confirmArgs += "--no-symlink" }

Set-Location $RootDir

switch ($Command) {
    { $_ -in @("install", "add") } {
        Invoke-SkillSpark (@("add", $Source) + $globalArgs + $agentArgs + $skillArgs + $confirmArgs)
    }
    { $_ -in @("remove", "delete") } {
        if ($Scope -eq "project") {
            try {
                Invoke-SkillSpark (@("remove") + $Skill + $confirmArgs + @("--silent"))
            } catch {
                Write-Warning $_
            }
        } else {
            Remove-GlobalLockEntries
        }
        Remove-WorkflowPaths
    }
    "update" {
        Invoke-SkillSpark (@("update") + $Skill + $confirmArgs)
    }
    { $_ -in @("outdated", "status") } {
        Invoke-SkillSpark (@("outdated") + $Skill)
    }
    "hooks" {
        Show-HookDiagnosis
        Install-GitWorkflowHooks
        foreach ($agentName in $Agent) {
            if ($agentName -eq "claude-code" -or $agentName -eq "claude") {
                Install-ClaudeWorkflowHook
            }
        }
    }
    "list" {
        Invoke-SkillSpark @("add", $Source, "--list", "--silent")
    }
    { $_ -in @("verify", "doctor") } {
        Invoke-SkillSpark @("doctor")
        python3 skills/meta/skill-creator/scripts/quick_validate.py skills/devops/git-workflow
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        python3 skills/meta/skill-creator/scripts/quick_validate.py skills/devops/local-workflow
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        Test-WorkflowPaths
    }
}
