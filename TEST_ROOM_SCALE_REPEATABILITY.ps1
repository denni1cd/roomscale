param(
	[ValidateSet('room_a', 'room_b')]
	[string]$Room = 'room_a',
	[int]$RunCount = 5,
	[int]$PerRunTimeoutSeconds = 360,
	[int]$OverallTimeoutMinutes = 40,
	[string]$OutputDirectory = ''
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ProjectRoot 'scripts/Invoke-RoomScaleProcess.ps1')
if (-not $OutputDirectory) {
	$OutputDirectory = Join-Path $ProjectRoot "verification/poc15/repeatability/$Room"
}
$OutputDirectory = Resolve-RoomScaleOutputPath -Value $OutputDirectory -ProjectRoot $ProjectRoot
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
if ($RunCount -lt 1 -or $PerRunTimeoutSeconds -lt 1 -or $OverallTimeoutMinutes -lt 1) {
	throw 'Run count and timeout values must be positive.'
}

$results = [System.Collections.Generic.List[object]]::new()
$overall = [System.Diagnostics.Stopwatch]::StartNew()
$overallLimit = [long]$OverallTimeoutMinutes * 60 * 1000
$failure = ''
for ($run = 1; $run -le $RunCount; $run++) {
	$remaining = $overallLimit - $overall.ElapsedMilliseconds
	if ($remaining -le 0) {
		$failure = "Overall timeout expired before run $run."
		break
	}
	$label = 'run-{0:D2}' -f $run
	$logPath = Join-Path $OutputDirectory "$label.log"
	$runTimeout = [int][Math]::Max(1, [Math]::Min([long]$PerRunTimeoutSeconds, [long][Math]::Floor($remaining / 1000)))
	$watch = [System.Diagnostics.Stopwatch]::StartNew()
	$passed = $false
	$runError = ''
	try {
		& (Join-Path $ProjectRoot 'TEST_ROOM_SCALE.ps1') -Room $Room -TimeoutSeconds $runTimeout -LogPath $logPath | Out-Null
		$passed = $true
	} catch {
		$runError = $_.Exception.Message
	}
	$watch.Stop()
	if ($passed) {
		$content = if (Test-Path -LiteralPath $logPath) { [System.IO.File]::ReadAllText($logPath) } else { '' }
		$required = @('ROOMSCALE_M2_SMOKE_PASS','ROOMSCALE_M3_SMOKE_PASS','ROOMSCALE_M4_SMOKE_PASS','ROOMSCALE_M5_SMOKE_PASS','ROOMSCALE_M6_SMOKE_PASS','ROOMSCALE_M8_SMOKE_PASS')
		$passed = @($required | Where-Object { $content -notmatch [regex]::Escape($_) }).Count -eq 0 -and $content -notmatch 'ROOMSCALE_SMOKE_FAIL:|SCRIPT ERROR:|SMOKE_TIMEOUT'
		if (-not $passed) { $runError = 'One or more required smoke markers are missing or report an error.' }
	}
	$results.Add([pscustomobject]@{Run=$run; Passed=$passed; Seconds=[Math]::Round($watch.Elapsed.TotalSeconds,2); Error=$runError; Log=$logPath})
	Write-Output ("{0} {1} room={2} seconds={3} log={4}" -f $label, $(if ($passed) {'PASS'} else {'FAIL'}), $Room, [Math]::Round($watch.Elapsed.TotalSeconds,2), $logPath)
	if (-not $passed) { $failure = $runError; break }
}
$overall.Stop()
$passCount = @($results | Where-Object Passed).Count
$state = if (-not $failure -and $passCount -eq $RunCount) {'PASS'} else {'FAIL'}
$rows = if ($results.Count -eq 0) {'| - | NOT RUN | - | - |'} else { ($results | ForEach-Object { "| $($_.Run) | $(if ($_.Passed) {'PASS'} else {'FAIL'}) | $($_.Seconds) | ``$([System.IO.Path]::GetFileName($_.Log))`` |" }) -join [Environment]::NewLine }
$summary = @(
	"# RoomScale POC 1.5 Repeatability - $Room",
	'',
	"**Status: $state**",
	'',
	"- Fresh full-scenario runs passed: $passCount / $RunCount",
	"- Per-run timeout: $PerRunTimeoutSeconds seconds",
	"- Overall timeout: $OverallTimeoutMinutes minutes",
	"- Total elapsed: $([Math]::Round($overall.Elapsed.TotalMinutes,2)) minutes",
	"- Failure: $(if ($failure) {$failure} else {'None'})",
	'',
	'| Run | Result | Seconds | Log |',
	'| --- | ---: | ---: | --- |',
	$rows,
	'',
	'Each log records the room identity and full M2-M6 and M8 production scenario markers.'
) -join [Environment]::NewLine
$summaryPath = Join-Path $OutputDirectory 'summary.md'
[System.IO.File]::WriteAllText($summaryPath, $summary + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
Write-Output "SUMMARY: $summaryPath ($state, $passCount/$RunCount)"
if ($state -ne 'PASS') { throw $failure }
