param(
	[Parameter(Mandatory = $true)][string]$Room,
	[string]$LogPath = '',
	[int]$TimeoutSeconds = 60
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ProjectRoot 'scripts/Resolve-RoomScaleRoom.ps1')
$SelectedRoom = Resolve-RoomScaleRoomInput -Value $Room -ProjectRoot $ProjectRoot
$GodotExecutable = & (Join-Path $ProjectRoot 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
if (-not $GodotExecutable -or -not (Test-Path -LiteralPath $GodotExecutable)) {
	throw 'Godot setup did not return a valid executable path.'
}

if (-not $LogPath) {
	$LogPath = Join-Path $ProjectRoot "verification/poc2/validation/$($SelectedRoom.RoomId)-validation.log"
} elseif (-not [System.IO.Path]::IsPathRooted($LogPath)) {
	$LogPath = Join-Path $ProjectRoot $LogPath
}
$LogPath = [System.IO.Path]::GetFullPath($LogPath)
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $LogPath) | Out-Null
$stdoutPath = "$LogPath.stdout.tmp"
$stderrPath = "$LogPath.stderr.tmp"
$previousRoom = [Environment]::GetEnvironmentVariable('ROOMSCALE_ROOM', 'Process')
$previousRoomFile = [Environment]::GetEnvironmentVariable('ROOMSCALE_ROOM_FILE', 'Process')
$process = $null
try {
	[Environment]::SetEnvironmentVariable('ROOMSCALE_ROOM', $SelectedRoom.RoomId, 'Process')
	[Environment]::SetEnvironmentVariable('ROOMSCALE_ROOM_FILE', $(if ($SelectedRoom.IsExplicitFile) { $SelectedRoom.File } else { '' }), 'Process')
	$process = Start-Process -FilePath $GodotExecutable `
		-ArgumentList @('--headless', '--path', $ProjectRoot, '--script', 'res://scripts/validate_room_definition.gd') `
		-WorkingDirectory $ProjectRoot `
		-RedirectStandardOutput $stdoutPath `
		-RedirectStandardError $stderrPath `
		-PassThru -WindowStyle Hidden
	if (-not $process.WaitForExit([int]([Math]::Max(1, $TimeoutSeconds) * 1000))) {
		try { $process.Kill($true) } catch { & taskkill.exe /PID $process.Id /T /F 2>&1 | Out-Null }
		if (-not $process.WaitForExit(5000)) {
			throw "Godot validator did not exit within five seconds after timeout cleanup. See $LogPath"
		}
		[System.IO.File]::WriteAllText($LogPath, "ROOMSCALE_VALIDATION_TIMEOUT after $TimeoutSeconds seconds.`n", [System.Text.UTF8Encoding]::new($false))
		Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
		throw "RoomDefinition validation timed out after $TimeoutSeconds seconds. See $LogPath"
	}
} finally {
	[Environment]::SetEnvironmentVariable('ROOMSCALE_ROOM', $previousRoom, 'Process')
	[Environment]::SetEnvironmentVariable('ROOMSCALE_ROOM_FILE', $previousRoomFile, 'Process')
}

$process.Refresh()
$exitCode = $process.ExitCode
$combined = @(
	if (Test-Path -LiteralPath $stdoutPath) { [System.IO.File]::ReadAllText($stdoutPath) }
	if (Test-Path -LiteralPath $stderrPath) { [System.IO.File]::ReadAllText($stderrPath) }
) -join [Environment]::NewLine
[System.IO.File]::WriteAllText($LogPath, $combined, [System.Text.UTF8Encoding]::new($false))
Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
Write-Output $combined
if ($null -ne $exitCode -and $exitCode -ne 0) {
	throw "RoomDefinition validation failed with exit code $exitCode. See $LogPath"
}
if ($combined -notmatch 'ROOMSCALE_VALIDATION_PASS') {
	throw "RoomDefinition validator omitted its explicit pass result. See $LogPath"
}
