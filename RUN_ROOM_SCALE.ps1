param(
	[string]$Room = 'room_a'
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ProjectRoot 'scripts/Resolve-RoomScaleRoom.ps1')
$SelectedRoom = Resolve-RoomScaleRoomInput -Value $Room -ProjectRoot $ProjectRoot
$GodotExecutable = & (Join-Path $ProjectRoot 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
if (-not $GodotExecutable -or -not (Test-Path -LiteralPath $GodotExecutable)) {
	throw 'Godot setup did not return a valid executable path.'
}
$VisibleExecutable = $GodotExecutable -replace '_console\.exe$', '.exe'
$PreviousRoom = [Environment]::GetEnvironmentVariable('ROOMSCALE_ROOM', 'Process')
$PreviousRoomFile = [Environment]::GetEnvironmentVariable('ROOMSCALE_ROOM_FILE', 'Process')
$RunExitCode = 0
try {
	[Environment]::SetEnvironmentVariable('ROOMSCALE_ROOM', $SelectedRoom.RoomId, 'Process')
	[Environment]::SetEnvironmentVariable('ROOMSCALE_ROOM_FILE', $(if ($SelectedRoom.IsExplicitFile) { $SelectedRoom.File } else { '' }), 'Process')
	& $VisibleExecutable --path $ProjectRoot
	$RunExitCode = $LASTEXITCODE
} finally {
	[Environment]::SetEnvironmentVariable('ROOMSCALE_ROOM', $PreviousRoom, 'Process')
	[Environment]::SetEnvironmentVariable('ROOMSCALE_ROOM_FILE', $PreviousRoomFile, 'Process')
}
exit $RunExitCode
