[CmdletBinding()]
param(
    [switch]$NoPull,
    [switch]$MirrorSkills,
    [switch]$SkipSkills,
    [switch]$SkipMcp
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

if (-not $NoPull -and (Test-Path -LiteralPath (Join-Path $repoRoot ".git"))) {
    $remotes = & git -C $repoRoot remote
    if ($LASTEXITCODE -eq 0 -and $remotes) {
        & git -C $repoRoot pull --ff-only
        if ($LASTEXITCODE -ne 0) {
            throw "git pull failed"
        }
    }
    else {
        Write-Host "No Git remote configured; skipping pull."
    }
}

$install = Join-Path $PSScriptRoot "install.ps1"
& $install -MirrorSkills:$MirrorSkills -SkipSkills:$SkipSkills -SkipMcp:$SkipMcp
