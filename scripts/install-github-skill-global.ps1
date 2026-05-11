[CmdletBinding(DefaultParameterSetName = "Repo")]
param(
    [Parameter(Mandatory = $true, ParameterSetName = "Repo")]
    [string]$Repo,

    [Parameter(Mandatory = $true, ParameterSetName = "Url")]
    [string]$Url,

    [Parameter(Mandatory = $true, ParameterSetName = "Repo")]
    [Parameter(ParameterSetName = "Url")]
    [string[]]$Path,

    [string]$Ref = "main",
    [string]$Name,

    [ValidateSet("auto", "download", "git")]
    [string]$Method = "auto",

    [Parameter(ParameterSetName = "Help")]
    [switch]$Help,
    [switch]$ExportLocal
)

$ErrorActionPreference = "Stop"

if ($Help) {
    @"
Install GitHub skill(s) into the global Codex skills directory:
  $env:USERPROFILE\.agents\skills

Examples:
  powershell -ExecutionPolicy Bypass -File .\scripts\install-github-skill-global.ps1 -Repo owner/repo -Path path/to/skill
  powershell -ExecutionPolicy Bypass -File .\scripts\install-github-skill-global.ps1 -Url https://github.com/owner/repo/tree/main/path/to/skill
  powershell -ExecutionPolicy Bypass -File .\scripts\install-github-skill-global.ps1 -Repo owner/repo -Path path/to/a,path/to/b -ExportLocal

Options:
  -Repo owner/repo
  -Url https://github.com/owner/repo/tree/ref/path/to/skill
  -Path path/to/skill[,path/to/another-skill]
  -Ref branch-or-tag
  -Name skill-name
  -Method auto|download|git
  -ExportLocal
"@ | Write-Host
    return
}

$installer = Join-Path $env:USERPROFILE ".codex\skills\.system\skill-installer\scripts\install-skill-from-github.py"
$globalSkills = Join-Path $env:USERPROFILE ".agents\skills"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

if (-not (Test-Path -LiteralPath $installer)) {
    throw "Codex skill installer not found: $installer"
}

New-Item -ItemType Directory -Force -Path $globalSkills | Out-Null

$argsList = @($installer, "--dest", $globalSkills, "--ref", $Ref, "--method", $Method)

if ($PSCmdlet.ParameterSetName -eq "Repo") {
    $argsList += @("--repo", $Repo)
}
else {
    $argsList += @("--url", $Url)
}

if ($Path -and $Path.Count -gt 0) {
    $argsList += "--path"
    $argsList += $Path
}

if (-not [string]::IsNullOrWhiteSpace($Name)) {
    $argsList += @("--name", $Name)
}

Write-Host "Installing skill(s) into $globalSkills"
& python @argsList
if ($LASTEXITCODE -ne 0) {
    throw "Skill installer failed with exit code $LASTEXITCODE"
}

if ($ExportLocal) {
    $exportScript = Join-Path $PSScriptRoot "export-local.ps1"
    & $exportScript -SkipMcp
    if ($LASTEXITCODE -ne 0) {
        throw "export-local.ps1 failed with exit code $LASTEXITCODE"
    }
    Write-Host "Exported global skills back to $repoRoot"
}

Write-Host "Done. Restart Codex to pick up new skills."
