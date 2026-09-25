param(
	[string]$LogPath = '',
	[int]$TimeoutSeconds = 300
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$GodotExecutable = & (Join-Path $ProjectRoot 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
if (-not $GodotExecutable -or -not (Test-Path -LiteralPath $GodotExecutable)) {
    throw 'Godot setup did not return a valid executable path.'
}

if (-not $LogPath) {
	$LogPath = Join-Path $ProjectRoot 'verification/headless-smoke.log'
}
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $LogPath) | Out-Null
$stdoutPath = "$LogPath.stdout.tmp"
$stderrPath = "$LogPath.stderr.tmp"
$process = Start-Process -FilePath $GodotExecutable `
	-ArgumentList @('--headless', '--path', $ProjectRoot, '--script', 'res://scripts/smoke_test.gd') `
	-WorkingDirectory $ProjectRoot `
	-RedirectStandardOutput $stdoutPath `
	-RedirectStandardError $stderrPath `
	-PassThru -WindowStyle Hidden
if (-not $process.WaitForExit([int]([Math]::Max(1, $TimeoutSeconds) * 1000))) {
	try {
		$process.Kill($true)
	} catch {
		& taskkill.exe /PID $process.Id /T /F 2>&1 | Out-Null
	}
	if (-not $process.WaitForExit(5000)) {
		throw "Godot did not exit within five seconds after timeout cleanup. See $LogPath"
	}
	$timeoutText = "SMOKE_TIMEOUT after $TimeoutSeconds seconds."
	[System.IO.File]::WriteAllText($LogPath, $timeoutText + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
	Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
	throw "Godot smoke test timed out after $TimeoutSeconds seconds. See $LogPath"
}
$process.Refresh()
$combined = @(
	if (Test-Path -LiteralPath $stdoutPath) { [System.IO.File]::ReadAllText($stdoutPath) }
	if (Test-Path -LiteralPath $stderrPath) { [System.IO.File]::ReadAllText($stderrPath) }
) -join [Environment]::NewLine
[System.IO.File]::WriteAllText($LogPath, $combined, [System.Text.UTF8Encoding]::new($false))
Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
Write-Output $combined
if ($process.ExitCode -ne 0) {
	throw "Godot smoke test failed with exit code $($process.ExitCode). See $LogPath"
}
foreach ($marker in @('ROOMSCALE_M2_SMOKE_PASS', 'ROOMSCALE_M3_SMOKE_PASS', 'ROOMSCALE_M4_SMOKE_PASS', 'ROOMSCALE_M5_SMOKE_PASS', 'ROOMSCALE_M6_SMOKE_PASS', 'ROOMSCALE_M8_SMOKE_PASS')) {
	if ($combined -notmatch [regex]::Escape($marker)) {
		throw "Godot smoke test omitted required marker $marker. See $LogPath"
	}
}
if ($combined -match 'SCRIPT ERROR:|ROOMSCALE_SMOKE_FAIL:') {
	throw "Godot smoke test emitted a script/assertion error. See $LogPath"
}
