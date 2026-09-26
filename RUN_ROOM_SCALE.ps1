param(
	[ValidateSet('room_a', 'room_b')]
	[string]$Room = 'room_a'
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$GodotExecutable = & (Join-Path $ProjectRoot 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
if (-not $GodotExecutable -or -not (Test-Path -LiteralPath $GodotExecutable)) {
	throw 'Godot setup did not return a valid executable path.'
}
$VisibleExecutable = $GodotExecutable -replace '_console\.exe$', '.exe'
$PreviousRoom = [Environment]::GetEnvironmentVariable('ROOMSCALE_ROOM', 'Process')
$RunExitCode = 0
try {
	[Environment]::SetEnvironmentVariable('ROOMSCALE_ROOM', $Room, 'Process')
	& $VisibleExecutable --path $ProjectRoot
	$RunExitCode = $LASTEXITCODE
} finally {
	[Environment]::SetEnvironmentVariable('ROOMSCALE_ROOM', $PreviousRoom, 'Process')
}
exit $RunExitCode
