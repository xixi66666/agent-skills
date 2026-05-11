[CmdletBinding()]
param(
    [switch]$MirrorSkills,
    [switch]$SkipSkills,
    [switch]$SkipMcp
)

$ErrorActionPreference = "Stop"

function Get-RepoRoot {
    return (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

function New-Backup {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$BackupRoot
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
    $name = Split-Path -Leaf $Path
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backup = Join-Path $BackupRoot "$name.$timestamp.bak"
    Copy-Item -LiteralPath $Path -Destination $backup -Recurse -Force
    return $backup
}

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

function Sync-Skills {
    param([string]$RepoRoot)

    $source = Join-Path $RepoRoot "skills"
    $agentsRoot = Join-Path $env:USERPROFILE ".agents"
    $target = Join-Path $agentsRoot "skills"
    $backupRoot = Join-Path $RepoRoot ".backup"

    if (-not (Test-Path -LiteralPath $source)) {
        throw "Skills source not found: $source"
    }

    New-Item -ItemType Directory -Force -Path $agentsRoot | Out-Null
    New-Item -ItemType Directory -Force -Path $target | Out-Null

    $backup = New-Backup -Path $target -BackupRoot $backupRoot
    if ($backup) {
        Write-Host "Backed up skills to $backup"
    }

    if ($MirrorSkills) {
        Invoke-RobocopyChecked -Source $source -Destination $target -Options @("/MIR", "/XD", ".git", "/NFL", "/NDL", "/NJH", "/NJS", "/NP")
    }
    else {
        Invoke-RobocopyChecked -Source $source -Destination $target -Options @("/E", "/XD", ".git", "/NFL", "/NDL", "/NJH", "/NJS", "/NP")
    }

    $lockSource = Join-Path $RepoRoot ".skill-lock.json"
    if (Test-Path -LiteralPath $lockSource) {
        Copy-Item -LiteralPath $lockSource -Destination (Join-Path $agentsRoot ".skill-lock.json") -Force
    }

    Write-Host "Skills synced to $target"
}

function Get-McpServerNames {
    param([string]$Toml)

    $names = New-Object "System.Collections.Generic.HashSet[string]"
    $regex = [regex]'(?m)^\s*\[mcp_servers\.((?:"[^"]+")|[A-Za-z0-9_-]+)(?=[\].])'
    foreach ($match in $regex.Matches($Toml)) {
        $name = $match.Groups[1].Value.Trim('"')
        [void]$names.Add($name)
    }
    return @($names)
}

function Remove-ManagedBlock {
    param([string]$Text)

    $start = "# BEGIN codex-global-config managed mcp"
    $end = "# END codex-global-config managed mcp"
    $pattern = "(?ms)\r?\n?" + [regex]::Escape($start) + ".*?" + [regex]::Escape($end) + "\r?\n?"
    return [regex]::Replace($Text, $pattern, "`r`n")
}

function Remove-McpSections {
    param(
        [string]$Text,
        [string[]]$ServerNames
    )

    $lines = [regex]::Split($Text, "\r?\n")
    $output = New-Object "System.Collections.Generic.List[string]"
    $skip = $false

    foreach ($line in $lines) {
        $headerMatch = [regex]::Match($line, '^\s*\[([^\]]+)\]\s*$')
        if ($headerMatch.Success) {
            $header = $headerMatch.Groups[1].Value
            $skip = $false
            foreach ($name in $ServerNames) {
                if ($header -eq "mcp_servers.$name" -or $header.StartsWith("mcp_servers.$name.")) {
                    $skip = $true
                    break
                }
            }
        }

        if (-not $skip) {
            $output.Add($line)
        }
    }

    return (($output -join "`r`n").TrimEnd() + "`r`n")
}

function Expand-Template {
    param([string]$Text)

    $userProfileEscaped = $env:USERPROFILE.Replace("\", "\\")
    $expanded = $Text.Replace("{{USERPROFILE}}", $userProfileEscaped)
    $expanded = $expanded.Replace("{{HOME}}", $userProfileEscaped)
    return $expanded
}

function Sync-Mcp {
    param([string]$RepoRoot)

    $sharedMcp = Join-Path $RepoRoot "mcp\shared.toml"
    if (-not (Test-Path -LiteralPath $sharedMcp)) {
        throw "Shared MCP config not found: $sharedMcp"
    }

    $codexRoot = Join-Path $env:USERPROFILE ".codex"
    $configPath = Join-Path $codexRoot "config.toml"
    $backupRoot = Join-Path $RepoRoot ".backup"
    New-Item -ItemType Directory -Force -Path $codexRoot | Out-Null

    if (-not (Test-Path -LiteralPath $configPath)) {
        New-Item -ItemType File -Force -Path $configPath | Out-Null
    }

    $backup = New-Backup -Path $configPath -BackupRoot $backupRoot
    if ($backup) {
        Write-Host "Backed up Codex config to $backup"
    }

    $sharedText = Expand-Template -Text (Get-Content -LiteralPath $sharedMcp -Raw)
    $serverNames = Get-McpServerNames -Toml $sharedText
    $current = Get-Content -LiteralPath $configPath -Raw
    $current = Remove-ManagedBlock -Text $current
    $current = Remove-McpSections -Text $current -ServerNames $serverNames

    $block = @"
# BEGIN codex-global-config managed mcp
$($sharedText.Trim())
# END codex-global-config managed mcp
"@

    $next = $current.TrimEnd() + "`r`n`r`n" + $block + "`r`n"
    Set-Content -LiteralPath $configPath -Value $next -Encoding UTF8
    Write-Host "MCP config synced to $configPath"
}

$repoRoot = Get-RepoRoot

if (-not $SkipSkills) {
    Sync-Skills -RepoRoot $repoRoot
}

if (-not $SkipMcp) {
    Sync-Mcp -RepoRoot $repoRoot
}

Write-Host "Done."
