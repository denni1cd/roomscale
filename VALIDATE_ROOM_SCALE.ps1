param([Parameter(Mandatory)][string]$Room, [string]$LogPath = '', [int]$TimeoutSeconds = 60)
$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ProjectRoot 'scripts/Resolve-RoomScaleRoom.ps1')
. (Join-Path $ProjectRoot 'scripts/Invoke-RoomScaleProcess.ps1')
$SelectedRoom = Resolve-RoomScaleRoomInput -Value $Room -ProjectRoot $ProjectRoot
$GodotExecutable = & (Join-Path $ProjectRoot 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
if (-not $LogPath) { $LogPath = "verification/poc2/validation/$($SelectedRoom.RoomId)-validation.log" }
$runEnvironment = @{
    ROOMSCALE_ROOM = $SelectedRoom.RoomId
    ROOMSCALE_ROOM_FILE = $(if ($SelectedRoom.IsExplicitFile) { $SelectedRoom.File } else { '' })
}
$execution = Invoke-RoomScaleProcess -FilePath $GodotExecutable -ArgumentList @('--headless','--path',$ProjectRoot,'--script','res://scripts/validate_room_definition.gd') -ProjectRoot $ProjectRoot -LogPath $LogPath -TimeoutSeconds $TimeoutSeconds -Environment $runEnvironment
Write-Output $execution.Content
if ($execution.TimedOut -or $execution.ExitCode -ne 0 -or $execution.Content -notmatch 'ROOMSCALE_VALIDATION_PASS' -or $execution.Content -match 'SCRIPT ERROR:|ERROR:|ROOMSCALE_VALIDATION_FAIL') {
    throw "RoomDefinition validation failed. See $($execution.LogPath)"
}
