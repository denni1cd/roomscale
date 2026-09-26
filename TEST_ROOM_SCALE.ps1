param(
	[ValidateSet('room_a', 'room_b')]
	[string]$Room = 'room_a',
	[string]$LogPath = '',
	[int]$TimeoutSeconds = 360,
	[switch]$CaptureVisuals,
	[string]$VisualDirectory = ''
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$GodotExecutable = & (Join-Path $ProjectRoot 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
if (-not $GodotExecutable -or -not (Test-Path -LiteralPath $GodotExecutable)) {
    throw 'Godot setup did not return a valid executable path.'
}

if (-not $LogPath) {
	$LogPath = Join-Path $ProjectRoot "verification/poc15/$Room/full-smoke.log"
}
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $LogPath) | Out-Null
$stdoutPath = "$LogPath.stdout.tmp"
$stderrPath = "$LogPath.stderr.tmp"
$previousRoom = [Environment]::GetEnvironmentVariable('ROOMSCALE_ROOM', 'Process')
$previousVisualDirectory = [Environment]::GetEnvironmentVariable('ROOMSCALE_VISUAL_DIR', 'Process')
$previousDisableStartupCapture = [Environment]::GetEnvironmentVariable('ROOMSCALE_DISABLE_STARTUP_CAPTURE', 'Process')
$process = $null
try {
	[Environment]::SetEnvironmentVariable('ROOMSCALE_ROOM', $Room, 'Process')
	[Environment]::SetEnvironmentVariable('ROOMSCALE_DISABLE_STARTUP_CAPTURE', '1', 'Process')
	if ($CaptureVisuals) {
		if (-not $VisualDirectory) { $VisualDirectory = Join-Path $ProjectRoot "verification/poc15/visual/$Room" }
		$VisualDirectory = [System.IO.Path]::GetFullPath($VisualDirectory)
		New-Item -ItemType Directory -Force -Path $VisualDirectory | Out-Null
		[Environment]::SetEnvironmentVariable('ROOMSCALE_VISUAL_DIR', $VisualDirectory, 'Process')
	} else {
		[Environment]::SetEnvironmentVariable('ROOMSCALE_VISUAL_DIR', '', 'Process')
	}
	$arguments = @()
	if (-not $CaptureVisuals) { $arguments += '--headless' }
	$arguments += @('--path', $ProjectRoot, '--script', 'res://scripts/smoke_test.gd')
	$process = Start-Process -FilePath $GodotExecutable `
		-ArgumentList $arguments `
		-WorkingDirectory $ProjectRoot `
		-RedirectStandardOutput $stdoutPath `
		-RedirectStandardError $stderrPath `
		-PassThru -WindowStyle $(if ($CaptureVisuals) { 'Normal' } else { 'Hidden' })
	if (-not $process.WaitForExit([int]([Math]::Max(1, $TimeoutSeconds) * 1000))) {
		try {
			$process.Kill($true)
		} catch {
			& taskkill.exe /PID $process.Id /T /F 2>&1 | Out-Null
		}
		if (-not $process.WaitForExit(5000)) {
			throw "Godot did not exit within five seconds after timeout cleanup. See $LogPath"
		}
		$timeoutText = "SMOKE_TIMEOUT room=$Room after $TimeoutSeconds seconds."
		[System.IO.File]::WriteAllText($LogPath, $timeoutText + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
		Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
		throw "Godot smoke test timed out after $TimeoutSeconds seconds for $Room. See $LogPath"
	}
} finally {
	[Environment]::SetEnvironmentVariable('ROOMSCALE_ROOM', $previousRoom, 'Process')
	[Environment]::SetEnvironmentVariable('ROOMSCALE_VISUAL_DIR', $previousVisualDirectory, 'Process')
	[Environment]::SetEnvironmentVariable('ROOMSCALE_DISABLE_STARTUP_CAPTURE', $previousDisableStartupCapture, 'Process')
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
foreach ($marker in @('ROOMSCALE_M2_SMOKE_PASS', 'ROOMSCALE_M3_SMOKE_PASS', 'ROOMSCALE_M4_SMOKE_PASS', 'ROOMSCALE_M5_SMOKE_PASS', 'ROOMSCALE_M6_SMOKE_PASS', 'ROOMSCALE_M8_SMOKE_PASS')) {
	if ($combined -notmatch [regex]::Escape($marker)) {
		throw "Godot smoke test omitted required marker $marker. See $LogPath"
	}
}
if ($combined -match 'SCRIPT ERROR:|ROOMSCALE_SMOKE_FAIL:') {
	throw "Godot smoke test emitted a script/assertion error. See $LogPath"
}
if ($null -ne $exitCode -and $exitCode -ne 0) {
	throw "Godot smoke test failed with exit code $exitCode. See $LogPath"
}
