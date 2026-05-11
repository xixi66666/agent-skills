[CmdletBinding()]
param(
    [switch]$SkipSkills,
    [switch]$SkipMcp
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Invoke-RobocopyChecked {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination,
        [Parameter(Mandatory = $true)][string[]]$Options
    )

    & robocopy $Source $Destination @Options | Out-Host
    $code = $LASTEXITCODE
    if ($code -gt 7) {
        throw "robocopy failed with exit code $code"
    }
}

if (-not $SkipSkills) {
    $source = Join-Path $env:USERPROFILE ".agents\skills"
    $target = Join-Path $repoRoot "skills"
    if (-not (Test-Path -LiteralPath $source)) {
        throw "Global skills directory not found: $source"
    }
    New-Item -ItemType Directory -Force -Path $target | Out-Null
    Invoke-RobocopyChecked -Source $source -Destination $target -Options @("/MIR", "/XD", ".git", "/NFL", "/NDL", "/NJH", "/NJS", "/NP")

    $lock = Join-Path $env:USERPROFILE ".agents\.skill-lock.json"
    if (Test-Path -LiteralPath $lock) {
        Copy-Item -LiteralPath $lock -Destination (Join-Path $repoRoot ".skill-lock.json") -Force
    }
}

if (-not $SkipMcp) {
    Write-Host "MCP export is intentionally manual. Edit mcp\shared.toml, then run scripts\install.ps1."
}

Write-Host "Local skills exported to repo."
