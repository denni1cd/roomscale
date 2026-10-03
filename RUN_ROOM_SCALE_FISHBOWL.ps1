# Spectator mode: autonomous 10x, automatic camera, F3 details.
param([string]$Room = 'room_poc45', [switch]$ManualCamera)
$ErrorActionPreference = 'Stop'
$fishbowlRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$previousAutonomy = [Environment]::GetEnvironmentVariable('ROOMSCALE_FISHBOWL', 'Process')
$previousCamera = [Environment]::GetEnvironmentVariable('ROOMSCALE_MANUAL_CAMERA', 'Process')
try {
    $env:ROOMSCALE_FISHBOWL = '1'
    $env:ROOMSCALE_MANUAL_CAMERA = $(if ($ManualCamera) {'1'} else {'0'})
    & (Join-Path $fishbowlRoot 'RUN_ROOM_SCALE.ps1') -Room $Room
} finally {
    [Environment]::SetEnvironmentVariable('ROOMSCALE_FISHBOWL', $previousAutonomy, 'Process')
    [Environment]::SetEnvironmentVariable('ROOMSCALE_MANUAL_CAMERA', $previousCamera, 'Process')
}
