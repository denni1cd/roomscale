param(
	[int]$RunCount = 10,
	[int]$PerRunTimeoutSeconds = 300,
	[int]$OverallTimeoutMinutes = 40,
	[string]$OutputDirectory = ''
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $OutputDirectory) {
	$OutputDirectory = Join-Path $ProjectRoot 'verification/milestone7-runs'
}
$OutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

$GodotExecutable = & (Join-Path $ProjectRoot 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
if (-not $GodotExecutable -or -not (Test-Path -LiteralPath $GodotExecutable)) {
	throw 'Godot setup did not return a valid executable path.'
}
if ($RunCount -lt 1 -or $PerRunTimeoutSeconds -lt 1 -or $OverallTimeoutMinutes -lt 1) {
	throw 'Run count and timeout values must be positive.'
}

$requiredMarkers = @(
	'ROOMSCALE_M2_SMOKE_PASS',
	'ROOMSCALE_M3_SMOKE_PASS',
	'ROOMSCALE_M4_SMOKE_PASS',
	'ROOMSCALE_M5_SMOKE_PASS',
	'ROOMSCALE_M6_SMOKE_PASS'
)
$results = [System.Collections.Generic.List[object]]::new()
$overallWatch = [System.Diagnostics.Stopwatch]::StartNew()
$overallTimeoutMilliseconds = [long]$OverallTimeoutMinutes * 60 * 1000
$failure = ''

for ($run = 1; $run -le $RunCount; $run++) {
	$remainingOverall = $overallTimeoutMilliseconds - $overallWatch.ElapsedMilliseconds
	if ($remainingOverall -le 0) {
		$failure = "Overall timeout of $OverallTimeoutMinutes minutes expired before run $run."
		break
	}
	$runLabel = 'run-{0:D2}' -f $run
	$stdoutPath = Join-Path $OutputDirectory "$runLabel.stdout.tmp"
	$stderrPath = Join-Path $OutputDirectory "$runLabel.stderr.tmp"
	$logPath = Join-Path $OutputDirectory "$runLabel.log"
	$runWatch = [System.Diagnostics.Stopwatch]::StartNew()
	$startedAt = [DateTime]::UtcNow
	$timedOut = $false
	$exitCode = $null
	$runFailure = ''
	$process = $null
	try {
		$process = Start-Process -FilePath $GodotExecutable `
			-ArgumentList @('--headless', '--path', $ProjectRoot, '--script', 'res://scripts/smoke_test.gd') `
			-WorkingDirectory $ProjectRoot `
			-RedirectStandardOutput $stdoutPath `
			-RedirectStandardError $stderrPath `
			-PassThru -WindowStyle Hidden
		$waitMilliseconds = [int][Math]::Min([long]$PerRunTimeoutSeconds * 1000, $remainingOverall)
		if (-not $process.WaitForExit($waitMilliseconds)) {
			$timedOut = $true
			$runFailure = if ($remainingOverall -le [long]$PerRunTimeoutSeconds * 1000) {
				"Overall timeout expired during $runLabel."
			} else {
				"Per-run timeout of $PerRunTimeoutSeconds seconds expired."
			}
			try {
				$process.Kill($true)
			} catch {
				& taskkill.exe /PID $process.Id /T /F 2>&1 | Out-Null
			}
			if (-not $process.WaitForExit(5000)) {
				$runFailure = "$runFailure Godot process did not exit within 5 seconds after the tree-kill request."
			}
		} else {
			$process.Refresh()
			$exitCode = $process.ExitCode
		}
	} catch {
		$runFailure = "Could not launch or monitor Godot: $($_.Exception.Message)"
	}
	$runWatch.Stop()
	$stdout = if (Test-Path -LiteralPath $stdoutPath) { [System.IO.File]::ReadAllText($stdoutPath) } else { '' }
	$stderr = if (Test-Path -LiteralPath $stderrPath) { [System.IO.File]::ReadAllText($stderrPath) } else { '' }
	$combined = @(
		"RUN: $run/$RunCount",
		"STARTED_UTC: $($startedAt.ToString('o'))",
		"DURATION_SECONDS: $([Math]::Round($runWatch.Elapsed.TotalSeconds, 2))",
		"EXIT_CODE: $(if ($null -eq $exitCode) { 'unknown' } else { $exitCode })",
		"TIMED_OUT: $timedOut",
		"FAILURE: $runFailure",
		'--- STDOUT ---',
		$stdout,
		'--- STDERR ---',
		$stderr
	) -join [Environment]::NewLine
	[System.IO.File]::WriteAllText($logPath, $combined, [System.Text.UTF8Encoding]::new($false))
	Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue

	$missingMarkers = @($requiredMarkers | Where-Object { $stdout -notmatch [regex]::Escape($_) })
	$hasSmokeFailure = $stdout -match 'ROOMSCALE_SMOKE_FAIL:' -or $stderr -match 'ROOMSCALE_SMOKE_FAIL:'
	$hasScriptError = $stdout -match 'SCRIPT ERROR:' -or $stderr -match 'SCRIPT ERROR:'
	$passed = -not $timedOut -and $null -ne $exitCode -and $exitCode -eq 0 -and $missingMarkers.Count -eq 0 -and -not $hasSmokeFailure -and -not $hasScriptError -and [string]::IsNullOrEmpty($runFailure)
	$results.Add([pscustomobject]@{
		Run = $run
		StartedUtc = $startedAt.ToString('o')
		DurationSeconds = [Math]::Round($runWatch.Elapsed.TotalSeconds, 2)
		ExitCode = $exitCode
		TimedOut = $timedOut
		Passed = $passed
		MissingMarkers = ($missingMarkers -join ', ')
		Log = $logPath
	})
	Write-Output ("{0} {1} exit={2} seconds={3} log={4}" -f $runLabel, $(if ($passed) { 'PASS' } else { 'FAIL' }), $exitCode, [Math]::Round($runWatch.Elapsed.TotalSeconds, 2), $logPath)

	if (-not $passed) {
		if ($runFailure) { $failure = $runFailure }
		elseif ($missingMarkers.Count -gt 0) { $failure = "Missing smoke pass marker(s): $($missingMarkers -join ', ')." }
		elseif ($hasScriptError) { $failure = 'Godot emitted SCRIPT ERROR.' }
		elseif ($hasSmokeFailure) { $failure = 'Smoke assertions reported failure.' }
		else { $failure = "Godot exited with code $exitCode." }
		break
	}
}
$overallWatch.Stop()

$passedCount = @($results | Where-Object Passed).Count
$resultState = if (-not $failure -and $passedCount -eq $RunCount) { 'PASS' } else { 'FAIL' }
$runRows = if ($results.Count -eq 0) {
	'| — | NOT RUN | — | — | — |'
} else {
	($results | ForEach-Object {
		"| $($_.Run) | $(if ($_.Passed) { 'PASS' } else { 'FAIL' }) | $($_.ExitCode) | $($_.DurationSeconds) | ``$([System.IO.Path]::GetFileName($_.Log))`` |"
	}) -join [Environment]::NewLine
}
$summary = @(
	'# RoomScale M7 Repeatability Run',
	'',
	"**Status: $resultState**",
	'',
	"- Fresh Godot processes passed: $passedCount / $RunCount",
	"- Per-run timeout: $PerRunTimeoutSeconds seconds",
	"- Overall timeout: $OverallTimeoutMinutes minutes",
	"- Total elapsed: $([Math]::Round($overallWatch.Elapsed.TotalMinutes, 2)) minutes",
	"- Godot: $GodotExecutable",
	"- Failure: $(if ($failure) { $failure } else { 'None' })",
	'',
	'| Run | Result | Exit | Seconds | Log |',
	'| --- | --- | ---: | ---: | --- |',
	$runRows,
	'',
	'Each run launched `scripts/smoke_test.gd` in a new headless Godot process and required M2–M6 pass markers.'
) -join [Environment]::NewLine
$summaryPath = Join-Path $ProjectRoot 'verification/milestone7-repeatability-summary.md'
$statusPath = Join-Path $ProjectRoot 'verification/milestone7-status.md'
[System.IO.File]::WriteAllText($summaryPath, $summary + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
$status = @(
	'# Milestone 7 — Automated Verification',
	'',
	"**Status: $resultState**",
	'',
	"The repeatability harness launched $passedCount of $RunCount full-scenario fresh-process runs successfully. The first failure stops the batch. Per-run logs and bounded timeout settings are recorded in `milestone7-repeatability-summary.md`.",
	'',
	"- Per-run timeout: $PerRunTimeoutSeconds seconds.",
	"- Overall timeout: $OverallTimeoutMinutes minutes.",
	"- Failure: $(if ($failure) { $failure } else { 'None' }).",
	'',
	'## Next',
	'',
	$(if ($resultState -eq 'PASS') { 'M7 repeatability passed. Proceed to M8 only after review.' } else { 'Fix the first failed run and rerun M7. M8 remains blocked.' })
) -join [Environment]::NewLine
[System.IO.File]::WriteAllText($statusPath, $status + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
Write-Output "SUMMARY: $summaryPath"
Write-Output "M7_STATUS: $statusPath ($resultState, $passedCount/$RunCount)"
if ($resultState -ne 'PASS') { exit 1 }
