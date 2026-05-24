#Requires -Version 5.1
<#
.SYNOPSIS
    Tag-Based Skill Installer for Windows.
    Scans skill directories for matching tags and installs them.

.DESCRIPTION
    Parses SKILL.md frontmatter for 'tags' field and installs all skills matching the specified tag.

.PARAMETER Tag
    Tag to match (e.g., dev-workflow, github, workflow)

.PARAMETER System
    Install to system directories

.PARAMETER Project
    Install to current project directory

.PARAMETER Agent
    Target specific agent (claude-code, kimi, codex, opencode)

.PARAMETER Dir
    Skills category directory to scan. Pass a comma-separated list or multiple values.
    Defaults to: ./dev, ./analysis, ./fe-skills, ./backend-skills, ./product

.EXAMPLE
    .\install-by-tag.ps1 -Tag dev-workflow -System
    Install all dev-workflow tagged skills to system directories

.EXAMPLE
    .\install-by-tag.ps1 -Tag analysis -System
    Install all analysis tagged skills (from the analysis/ category)

.EXAMPLE
    .\install-by-tag.ps1 -Tag github -Project
    Install all github tagged skills to current project

.EXAMPLE
    .\install-by-tag.ps1 -Tag workflow -System -Agent kimi
    Install all workflow skills to kimi system directory
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Tag,
    [switch]$System,
    [switch]$Project,
    [string]$Agent = "",
    [string[]]$Dir = @()
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ($Dir.Count -eq 0) {
    $Dir = @(
        (Join-Path $ScriptDir "dev"),
        (Join-Path $ScriptDir "analysis"),
        (Join-Path $ScriptDir "fe-skills"),
        (Join-Path $ScriptDir "backend-skills"),
        (Join-Path $ScriptDir "product")
    )
}

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}
function Write-Success { param([string]$Message) Write-ColorOutput $Message "Green" }
function Write-Warning { param([string]$Message) Write-ColorOutput $Message "Yellow" }
function Write-ErrorMsg { param([string]$Message) Write-ColorOutput $Message "Red" }
function Write-Info { param([string]$Message) Write-ColorOutput $Message "Cyan" }

function Get-SkillTags {
    param([string]$SkillMdPath)
    $content = Get-Content $SkillMdPath -Raw
    $tags = @()

    # Extract frontmatter
    if ($content -match "(?s)^---\r?\n(.+?)\r?\n---") {
        $frontmatter = $Matches[1]

        # Find tags section
        if ($frontmatter -match "(?m)^tags:\s*\r?\n((?:\s+-\s+.+\r?\n?)+)") {
            $tagsBlock = $Matches[1]
            $tagMatches = [regex]::Matches($tagsBlock, '^\s+-\s+(.+)$', 'Multiline')
            foreach ($m in $tagMatches) {
                $tags += $m.Groups[1].Value.Trim()
            }
        }
        # Inline array format: tags: [a, b, c]
        elseif ($frontmatter -match "tags:\s*\[(.+)\]") {
            $tags = $Matches[1] -split ',' | ForEach-Object { $_.Trim() }
        }
    }

    return $tags
}

function Get-SkillName {
    param([string]$SkillMdPath)
    $content = Get-Content $SkillMdPath -Raw

    if ($content -match "(?m)^name:\s*(.+)$") {
        return $Matches[1].Trim()
    }

    return (Split-Path (Split-Path $SkillMdPath -Parent) -Leaf)
}

function Find-MatchingSkills {
    param([string[]]$ScanDirs, [string]$TargetTag)
    $matches = @()

    foreach ($scanDir in $ScanDirs) {
        if (-not (Test-Path $scanDir)) { continue }
        $skillFiles = Get-ChildItem -Path $scanDir -Filter "SKILL.md" -Recurse -Depth 2
        foreach ($file in $skillFiles) {
            $tags = Get-SkillTags -SkillMdPath $file.FullName
            if ($tags -contains $TargetTag) {
                $skillRoot = $file.DirectoryName
                $skillName = Split-Path $skillRoot -Leaf
                $matches += [PSCustomObject]@{
                    Name = $skillName
                    Root = $skillRoot
                }
            }
        }
    }

    return $matches
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
        "claude-code" { $dirs += Join-Path $homePath ".claude\skills" }
        "kimi" {
            $dirs += Join-Path $homePath ".kimi\skills"
            $dirs += Join-Path $homePath ".config\agents\skills"
        }
        "codex" { $dirs += Join-Path $homePath ".codex\skills" }
        "opencode" { $dirs += Join-Path $homePath ".opencode\skills" }
        default {
            Write-ErrorMsg "Error: Unknown agent '$Agent'"
            exit 1
        }
    }
    return $dirs
}

function Get-ProjectTargetDirs {
    return @(
        (Join-Path $PWD ".agents\skills")
        (Join-Path $PWD ".kimi\skills")
        (Join-Path $PWD ".claude\skills")
    )
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

function Install-SkillToDir {
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
        catch { }
    }

    try {
        New-Item -ItemType Junction -Path $linkPath -Target $SkillRoot -Force | Out-Null
        Write-Success "  [OK]   $SkillName -> $linkPath (junction)"
        return $true
    }
    catch {
        Write-ErrorMsg "  [ERROR] Failed: $_"
        return $false
    }
}

function Main {
    if (-not $System -and -not $Project) {
        Write-ErrorMsg "Error: Must specify -System or -Project"
        exit 1
    }

    Write-Info "Scanning for skills with tag: $Tag"
    Write-Info "Scan directories:"
    foreach ($d in $Dir) {
        if (Test-Path $d) {
            Write-Host "  - $d"
        } else {
            Write-Warning "  - $d (missing, skipped)"
        }
    }
    Write-Host ""

    $matchingSkills = Find-MatchingSkills -ScanDirs $Dir -TargetTag $Tag

    if ($matchingSkills.Count -eq 0) {
        Write-Warning "No skills found with tag '$Tag'"
        Write-Host ""
        Write-Host "Available skills and tags:"
        foreach ($scanDir in $Dir) {
            if (-not (Test-Path $scanDir)) { continue }
            $allSkills = Get-ChildItem -Path $scanDir -Filter "SKILL.md" -Recurse -Depth 2
            foreach ($file in $allSkills) {
                $name = Get-SkillName -SkillMdPath $file.FullName
                $tags = Get-SkillTags -SkillMdPath $file.FullName
                if ($tags.Count -gt 0) {
                    Write-Host "  $name ($(Split-Path $scanDir -Leaf)): $($tags -join ', ')"
                }
            }
        }
        exit 1
    }

    Write-Success "Found $($matchingSkills.Count) skill(s) with tag '$Tag':"
    foreach ($skill in $matchingSkills) {
        Write-Host "  - $($skill.Name)"
    }
    Write-Host ""

    if ($System) { $targetDirs = Get-SystemTargetDirs }
    else { $targetDirs = Get-ProjectTargetDirs }

    foreach ($skill in $matchingSkills) {
        Write-Info "Installing $($skill.Name)..."
        $installed = 0
        $skipped = 0

        foreach ($targetDir in $targetDirs) {
            if (Install-SkillToDir -SkillName $skill.Name -SkillRoot $skill.Root -TargetDir $targetDir) {
                $installed++
            }
            else { $skipped++ }
        }

        Write-Success "  Installed: $installed, Skipped: $skipped"
        Write-Host ""
    }

    Write-Success "Tag-based installation complete!"
}

Main
