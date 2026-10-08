param([string]$Room = 'room_conflict', [switch]$ManualCamera)
$ErrorActionPreference = 'Stop'
$conflictRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$previousConflict = [Environment]::GetEnvironmentVariable('ROOMSCALE_CONFLICT','Process')
$conflictExitCode = 0
try {
    $env:ROOMSCALE_CONFLICT = '1'
    & (Join-Path $conflictRoot 'RUN_ROOM_SCALE_FISHBOWL.ps1') -Room $Room -ManualCamera:$ManualCamera
    $conflictExitCode = $LASTEXITCODE
} finally {
    [Environment]::SetEnvironmentVariable('ROOMSCALE_CONFLICT',$previousConflict,'Process')
}

exit $conflictExitCode
