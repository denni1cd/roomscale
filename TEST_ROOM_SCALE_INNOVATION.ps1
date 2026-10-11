param(
    [string]$OutputDirectory = 'verification/stabilization/runs/innovation',
    [int]$TimeoutSeconds = 60
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ProjectRoot 'scripts/Invoke-RoomScaleProcess.ps1')
$OutputDirectory = Resolve-RoomScaleOutputPath -Value $OutputDirectory -ProjectRoot $ProjectRoot
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$GodotExecutable = & (Join-Path $ProjectRoot 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
if (-not $GodotExecutable -or -not (Test-Path -LiteralPath $GodotExecutable)) {
    throw 'Godot setup did not return a valid executable path.'
}

$logPath = Join-Path $OutputDirectory 'innovation-system.log'
$run = Invoke-RoomScaleProcess `
    -FilePath $GodotExecutable `
    -ArgumentList @('--headless', '--path', $ProjectRoot, '--script', 'res://scripts/innovation_system_test.gd') `
    -ProjectRoot $ProjectRoot `
    -LogPath $logPath `
    -TimeoutSeconds $TimeoutSeconds

Write-Output $run.Content
if ($run.TimedOut) {
    throw "Innovation system check timed out after $TimeoutSeconds seconds. See $($run.LogPath)"
}
if ($run.ExitCode -ne 0) {
    throw "Innovation system check exited $($run.ExitCode). See $($run.LogPath)"
}
if ($run.Content -notmatch 'ROOMSCALE_INNOVATION_SYSTEM_PASS') {
    throw "Innovation system check omitted pass marker. See $($run.LogPath)"
}
if ($run.Content -match 'SCRIPT ERROR:|ROOMSCALE_INNOVATION_SYSTEM_FAIL') {
    throw "Innovation system check emitted an error. See $($run.LogPath)"
}

Write-Output "ROOMSCALE_INNOVATION_CHECKS_PASS log=$($run.LogPath)"
