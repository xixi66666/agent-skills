$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$testRoot = Join-Path $PSScriptRoot ".tmp-install-export-$PID"
$oldUserProfile = $env:USERPROFILE
$oldPath = $env:PATH

try {
    $scriptRoot = Join-Path $testRoot "repo\scripts"
    $fakeUserProfile = Join-Path $testRoot "user"
    $fakeBin = Join-Path $testRoot "bin"
    $fakeInstaller = Join-Path $fakeUserProfile ".codex\skills\.system\skill-installer\scripts\install-skill-from-github.py"
    $fakeSkill = Join-Path $fakeUserProfile ".agents\skills\example\SKILL.md"

    New-Item -ItemType Directory -Force -Path $scriptRoot | Out-Null
    New-Item -ItemType Directory -Force -Path $fakeBin | Out-Null
    New-Item -ItemType Directory -Force -Path (Split-Path $fakeInstaller -Parent) | Out-Null
    New-Item -ItemType Directory -Force -Path (Split-Path $fakeSkill -Parent) | Out-Null
    Copy-Item -LiteralPath (Join-Path $repoRoot "scripts\install-github-skill-global.ps1") -Destination $scriptRoot
    Copy-Item -LiteralPath (Join-Path $repoRoot "scripts\export-local.ps1") -Destination $scriptRoot
    Set-Content -LiteralPath $fakeInstaller -Value "# fake installer" -Encoding utf8
    Set-Content -LiteralPath $fakeSkill -Value "---`nname: example`n---" -Encoding utf8
    # 隔离网络下载，只验证成功导出后的退出码传播。
    Set-Content -LiteralPath (Join-Path $fakeBin "python.cmd") -Value "@exit /b 0" -Encoding ascii

    $env:USERPROFILE = $fakeUserProfile
    $env:PATH = "$fakeBin;$oldPath"

    $wrapper = Join-Path $scriptRoot "install-github-skill-global.ps1"
    & $wrapper -Repo "owner/repo" -Path "skills/example" -ExportLocal

    $exportedSkill = Join-Path $testRoot "repo\skills\example\SKILL.md"
    if (-not (Test-Path -LiteralPath $exportedSkill)) {
        throw "Expected the exported skill at $exportedSkill"
    }
}
finally {
    $env:USERPROFILE = $oldUserProfile
    $env:PATH = $oldPath
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}

Write-Host "PASS: successful export is not reported as a failure"
