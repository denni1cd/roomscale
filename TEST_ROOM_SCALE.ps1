param(
    [string]$LogPath = ''
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$GodotExecutable = & (Join-Path $ProjectRoot 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
if (-not $GodotExecutable -or -not (Test-Path -LiteralPath $GodotExecutable)) {
    throw 'Godot setup did not return a valid executable path.'
}

if (-not $LogPath) {
    $LogPath = Join-Path $ProjectRoot 'verification/headless-smoke.log'
}
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $LogPath) | Out-Null
& $GodotExecutable --headless --path $ProjectRoot --script res://scripts/smoke_test.gd 2>&1 | Tee-Object -FilePath $LogPath
if ($LASTEXITCODE -ne 0) {
    throw "Godot smoke test failed with exit code $LASTEXITCODE. See $LogPath"
}
