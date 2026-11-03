#Requires -Version 5.1
<#
.SYNOPSIS
    Installs the engineering-standards baseline.
.DESCRIPTION
    No argument : installs the Claude Code skill user-wide (%USERPROFILE%\.claude\skills).
    With a path : copies every target into that repository — .cursor\rules\, .github\,
                  .claude\skills\ and AGENTS.md.
    -Cursor     : installs the skill for Cursor, user-wide (%USERPROFILE%\.cursor\skills).
    -Verify     : checks an install against the lock it left behind.

    Nothing is copied unless every file matches this repo's .engineering-standards.sha256 and
    passes the forbidden-content scan; every install writes its own lock next to what it copied.

    The generated files (.cursor, .github, AGENTS.md) are committed to this repo, so
    installing needs no build step. Regenerating them after editing
    skills\engineering-standards\ requires bash — Git Bash or WSL — and scripts\build.sh.
.EXAMPLE
    .\scripts\install.ps1
.EXAMPLE
    .\scripts\install.ps1 C:\src\my-project
.EXAMPLE
    .\scripts\install.ps1 -Cursor
.EXAMPLE
    .\scripts\install.ps1 -Verify C:\src\my-project
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string] $TargetRepo,
    [switch] $Verify,
    [switch] $Cursor
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$skill = Join-Path $root 'skills\engineering-standards'

if (-not (Test-Path (Join-Path $skill 'SKILL.md'))) {
    throw "source not found: $skill\SKILL.md"
}

$lockName = '.engineering-standards.sha256'
# Instructions never need to fetch or execute anything. Keep in sync with integrity.sh.
$forbidden = '\b(curl|wget|Invoke-WebRequest|Invoke-RestMethod|Invoke-Expression|iwr|irm|iex|eval|base64|certutil|bitsadmin)\b|https?://|\|\s*(ba|z|da)?sh\b|\b(ba|z)?sh -c\b'
$invisible = '[\u200B-\u200F\u202A-\u202E\u2066-\u2069\uFEFF]'

function Get-Sha256 {
    param([string] $Path)
    return (Get-FileHash -Algorithm SHA256 $Path).Hash.ToLowerInvariant()
}

function Assert-Clean {
    param([string] $Dir, [string[]] $Files)
    $bad = @($Files | Where-Object {
        $text = [IO.File]::ReadAllText((Join-Path $Dir $_))
        $text -match $forbidden -or $text -match $invisible
    })
    if ($bad) { throw "forbidden content in agent instructions: $($bad -join ', ')" }
}

function Assert-Lock {
    param([string] $Dir)
    $lock = Join-Path $Dir $lockName
    if (-not (Test-Path $lock)) { throw "no $lockName in $Dir" }
    $files = foreach ($line in [IO.File]::ReadAllLines($lock)) {
        $rel = $line.Substring(66)
        if ((Get-Sha256 (Join-Path $Dir $rel)) -ne $line.Substring(0, 64)) {
            throw "$rel differs from $lockName - run scripts/build.sh and review the diff"
        }
        $rel
    }
    Assert-Clean $Dir $files
}

function Write-Lock {
    param([string] $Dir, [string[]] $Files)
    Assert-Clean $Dir $Files
    $lines = foreach ($f in $Files) { "$(Get-Sha256 (Join-Path $Dir $f))  $f" }
    [IO.File]::WriteAllText((Join-Path $Dir $lockName), (($lines -join "`n") + "`n"))
}

# files under $Dir\$Sub, relative to $Dir, forward slashes like the bash lock
function Get-SkillFiles {
    param([string] $Dir, [string] $Sub)
    Get-ChildItem (Join-Path $Dir $Sub) -Recurse -File |
        Where-Object Name -ne '.DS_Store' |
        ForEach-Object { $_.FullName.Substring($Dir.Length + 1).Replace('\', '/') }
}

if ($Verify) {
    if (-not $TargetRepo) { throw 'usage: install.ps1 -Verify <dir>' }
    Assert-Lock (Resolve-Path $TargetRepo).Path
    Write-Host "ok: $TargetRepo matches $lockName"
    exit 0
}

Assert-Lock $root

function Copy-Skill {
    param([string] $DestinationParent)
    $dest = Join-Path $DestinationParent 'engineering-standards'
    if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
    New-Item -ItemType Directory -Path $DestinationParent -Force | Out-Null
    Copy-Item $skill $dest -Recurse -Force
    return $dest
}

if ($Cursor) {
    $userHome = $env:CURSOR_HOME
    if (-not $userHome) { $userHome = Join-Path $env:USERPROFILE '.cursor' }
} else {
    $userHome = $env:CLAUDE_HOME
    if (-not $userHome) { $userHome = Join-Path $env:USERPROFILE '.claude' }
}

if ($Cursor -or -not $TargetRepo) {
    $dest = Copy-Skill (Join-Path $userHome 'skills')
    Write-Lock $dest @(Get-SkillFiles $dest '.')
    Write-Host "installed skill -> $dest"
    exit 0
}

if (-not (Test-Path $TargetRepo -PathType Container)) {
    throw "no such directory: $TargetRepo"
}
$target = (Resolve-Path $TargetRepo).Path

foreach ($d in '.cursor\rules', '.github\instructions', '.claude\skills') {
    New-Item -ItemType Directory -Path (Join-Path $target $d) -Force | Out-Null
}

Copy-Item (Join-Path $root '.cursor\rules\*.mdc') (Join-Path $target '.cursor\rules') -Force
Copy-Item (Join-Path $root '.github\copilot-instructions.md') (Join-Path $target '.github') -Force
Copy-Item (Join-Path $root '.github\instructions\*.instructions.md') (Join-Path $target '.github\instructions') -Force

$locked = @('.github/copilot-instructions.md')
$locked += Get-ChildItem (Join-Path $root '.cursor\rules\*.mdc') | ForEach-Object { ".cursor/rules/$($_.Name)" }
$locked += Get-ChildItem (Join-Path $root '.github\instructions\*.instructions.md') | ForEach-Object { ".github/instructions/$($_.Name)" }

$agents = Join-Path $target 'AGENTS.md'
$hadAgents = Test-Path $agents
if (-not $hadAgents) {
    Copy-Item (Join-Path $root 'AGENTS.md') $agents -Force
    $locked += 'AGENTS.md'
}

Copy-Skill (Join-Path $target '.claude\skills') | Out-Null
$locked += Get-SkillFiles $target '.claude\skills\engineering-standards'
Write-Lock $target $locked

Write-Host "installed -> ${target}: .cursor\rules\, .github\, .claude\skills\, $lockName"
if ($hadAgents) { Write-Host 'note: AGENTS.md already existed, left untouched and unlocked - merge by hand' }
