param(
	[int]$TimeoutSeconds = 30,
	[string]$LogPath = ''
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $LogPath) {
	$LogPath = Join-Path $ProjectRoot 'verification/poc15/fast-test.log'
}
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $LogPath) | Out-Null
$GodotExecutable = & (Join-Path $ProjectRoot 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
if (-not $GodotExecutable -or -not (Test-Path -LiteralPath $GodotExecutable)) {
	throw 'Godot setup did not return a valid executable path.'
}
$stdoutPath = "$LogPath.stdout.tmp"
$stderrPath = "$LogPath.stderr.tmp"
$process = Start-Process -FilePath $GodotExecutable `
	-ArgumentList @('--headless','--path',$ProjectRoot,'--script','res://scripts/room_definition_test.gd') `
	-WorkingDirectory $ProjectRoot -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath `
	-PassThru -WindowStyle Hidden
if (-not $process.WaitForExit([Math]::Max(1, $TimeoutSeconds) * 1000)) {
	$process.Kill($true)
	if (-not $process.WaitForExit(5000)) { throw 'Fast verification did not stop after tree-kill.' }
	[System.IO.File]::WriteAllText($LogPath, "FAST_TEST_TIMEOUT after $TimeoutSeconds seconds.`n", [System.Text.UTF8Encoding]::new($false))
	Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
	throw "Fast verification timed out after $TimeoutSeconds seconds."
}
$process.Refresh()
$exitCode = $process.ExitCode
$content = @(
	if (Test-Path -LiteralPath $stdoutPath) { [System.IO.File]::ReadAllText($stdoutPath) }
	if (Test-Path -LiteralPath $stderrPath) { [System.IO.File]::ReadAllText($stderrPath) }
) -join [Environment]::NewLine
[System.IO.File]::WriteAllText($LogPath, $content, [System.Text.UTF8Encoding]::new($false))
Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
Write-Output $content
if (($null -ne $exitCode -and $exitCode -ne 0) -or $content -notmatch 'ROOMSCALE_FAST_TEST_PASS' -or $content -match 'ROOMSCALE_FAST_TEST_FAIL:|SCRIPT ERROR:') {
	throw "Fast verification failed with exit code $exitCode. See $LogPath"
}
