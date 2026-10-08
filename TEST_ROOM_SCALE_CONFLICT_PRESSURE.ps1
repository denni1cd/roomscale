param(
    [int]$TimeoutSeconds = 180,
    [string]$OutputDirectory = 'verification/stabilization/runs/poc51'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $root 'scripts/Invoke-RoomScaleProcess.ps1')
$OutputDirectory = Resolve-RoomScaleOutputPath -Value $OutputDirectory -ProjectRoot $root
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$godot = & (Join-Path $root 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
$logPath = Join-Path $OutputDirectory 'conflict-pressure.log'
$environment = @{
    ROOMSCALE_ROOM = 'room_conflict'
    ROOMSCALE_CONFLICT = '1'
    ROOMSCALE_MANUAL_CAMERA = '1'
    ROOMSCALE_DISABLE_STARTUP_CAPTURE = '1'
}
$arguments = @('--headless','--path',$root,'--script','res://scripts/conflict_pressure_test.gd')
$execution = Invoke-RoomScaleProcess -FilePath $godot -ArgumentList $arguments -ProjectRoot $root -LogPath $logPath -Environment $environment -TimeoutSeconds $TimeoutSeconds
if ($execution.TimedOut -or $execution.ExitCode -ne 0 -or $execution.Content -match 'ERROR:|SCRIPT ERROR:|ROOMSCALE_CONFLICT_PRESSURE_FAIL' -or $execution.Content -notmatch 'ROOMSCALE_CONFLICT_PRESSURE_PASS') {
    throw "Conflict pressure test failed; inspect $logPath"
}
Write-Output "ROOMSCALE_CONFLICT_PRESSURE_PASS log=$logPath"
