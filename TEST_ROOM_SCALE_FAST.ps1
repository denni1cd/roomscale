param([int]$TimeoutSeconds = 30, [string]$LogPath = '')
$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ProjectRoot 'scripts/Invoke-RoomScaleProcess.ps1')
if (-not $LogPath) { $LogPath = 'verification/poc15/fast-test.log' }
$GodotExecutable = & (Join-Path $ProjectRoot 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
$execution = Invoke-RoomScaleProcess -FilePath $GodotExecutable -ArgumentList @('--headless','--path',$ProjectRoot,'--script','res://scripts/room_definition_test.gd') -ProjectRoot $ProjectRoot -LogPath $LogPath -TimeoutSeconds $TimeoutSeconds
Write-Output $execution.Content
if ($execution.TimedOut -or $execution.ExitCode -ne 0 -or $execution.Content -notmatch 'ROOMSCALE_FAST_TEST_PASS' -or $execution.Content -match 'ROOMSCALE_FAST_TEST_FAIL:|SCRIPT ERROR:|ERROR:') {
    throw "Fast verification failed. See $($execution.LogPath)"
}
