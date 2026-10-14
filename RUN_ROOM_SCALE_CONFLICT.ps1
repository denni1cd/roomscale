param([string]$Room = 'room_conflict', [switch]$ManualCamera, [string]$Scenario = 'clockwork_vs_verdant', [switch]$Innovation)
$ErrorActionPreference = 'Stop'
$conflictRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$previousConflict = [Environment]::GetEnvironmentVariable('ROOMSCALE_CONFLICT','Process')
$previousScenario = [Environment]::GetEnvironmentVariable('ROOMSCALE_CONFLICT_SCENARIO','Process')
$conflictExitCode = 0
try {
    $env:ROOMSCALE_CONFLICT = '1'
    $env:ROOMSCALE_CONFLICT_SCENARIO = $Scenario
    & (Join-Path $conflictRoot 'RUN_ROOM_SCALE_FISHBOWL.ps1') -Room $Room -ManualCamera:$ManualCamera -Innovation:$Innovation
    $conflictExitCode = $LASTEXITCODE
} finally {
    [Environment]::SetEnvironmentVariable('ROOMSCALE_CONFLICT',$previousConflict,'Process')
    [Environment]::SetEnvironmentVariable('ROOMSCALE_CONFLICT_SCENARIO',$previousScenario,'Process')
}

exit $conflictExitCode
