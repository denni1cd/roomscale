param(
	[int]$PerRunTimeoutSeconds = 360,
	[int]$OverallTimeoutMinutes = 18,
	[string]$OutputDirectory = '',
	[switch]$CaptureVisuals
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ProjectRoot 'scripts/Invoke-RoomScaleProcess.ps1')
if (-not $OutputDirectory) {
	$OutputDirectory = Join-Path $ProjectRoot 'verification/poc15/cross-room'
}
$OutputDirectory = Resolve-RoomScaleOutputPath -Value $OutputDirectory -ProjectRoot $ProjectRoot
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$sequence = @('room_a','room_b','room_a')
$overall = [System.Diagnostics.Stopwatch]::StartNew()
$results = [System.Collections.Generic.List[object]]::new()
$failure = ''
for ($index = 0; $index -lt $sequence.Count; $index++) {
	$remaining = [long]$OverallTimeoutMinutes * 60 * 1000 - $overall.ElapsedMilliseconds
	if ($remaining -le 0) { $failure = 'Overall cross-room timeout expired.'; break }
	$room = $sequence[$index]
	$label = 'step-{0:D2}-{1}' -f ($index + 1), $room
	$logPath = Join-Path $OutputDirectory "$label.log"
	$limit = [int][Math]::Max(1, [Math]::Min([long]$PerRunTimeoutSeconds, [long][Math]::Floor($remaining / 1000)))
	$watch = [System.Diagnostics.Stopwatch]::StartNew()
	$passed = $false
	$runError = ''
	try {
		$runArguments = @{ Room=$room; TimeoutSeconds=$limit; LogPath=$logPath }
		if ($CaptureVisuals) {
			$runArguments.CaptureVisuals = $true
			$runArguments.VisualDirectory = Join-Path (Split-Path -Parent $OutputDirectory) "visual/cross-room/$label"
		}
		& (Join-Path $ProjectRoot 'TEST_ROOM_SCALE.ps1') @runArguments | Out-Null
		$passed = $true
	} catch { $runError = $_.Exception.Message }
	$watch.Stop()
	if ($passed) {
		$content = [System.IO.File]::ReadAllText($logPath)
		$passed = $content -match "ROOMSCALE_ROOM=$room\b" -and $content -match 'ROOMSCALE_M6_SMOKE_PASS' -and $content -notmatch 'ROOMSCALE_SMOKE_FAIL:|SCRIPT ERROR:|SMOKE_TIMEOUT'
		if (-not $passed) { $runError = 'Required room identity/full-scenario evidence is absent.' }
	}
	$results.Add([pscustomobject]@{Step=($index+1); Room=$room; Passed=$passed; Seconds=[Math]::Round($watch.Elapsed.TotalSeconds,2); Log=$logPath; Error=$runError})
	Write-Output ("{0} {1} seconds={2} log={3}" -f $label, $(if ($passed) {'PASS'} else {'FAIL'}), [Math]::Round($watch.Elapsed.TotalSeconds,2), $logPath)
	if (-not $passed) { $failure = $runError; break }
}
$overall.Stop()
$passCount = @($results | Where-Object Passed).Count
$state = if (-not $failure -and $passCount -eq 3) {'PASS'} else {'FAIL'}
$rows = if ($results.Count -eq 0) {'| - | - | NOT RUN | - |'} else { ($results | ForEach-Object { "| $($_.Step) | $($_.Room) | $(if ($_.Passed) {'PASS'} else {'FAIL'}) | ``$([System.IO.Path]::GetFileName($_.Log))`` |" }) -join [Environment]::NewLine }
$summary = @(
	'# RoomScale POC 1.5 Cross-Room Regression',
	'',
	"**Status: $state**",
	'',
	'- Required sequence: Room A -> Room B -> Room A',
	"- Passed steps: $passCount / 3",
	"- Per-run timeout: $PerRunTimeoutSeconds seconds",
	"- Overall timeout: $OverallTimeoutMinutes minutes",
	"- Elapsed: $([Math]::Round($overall.Elapsed.TotalMinutes,2)) minutes",
	"- Failure: $(if ($failure) {$failure} else {'None'})",
	'',
	'| Step | Room | Result | Log |',
	'| ---: | --- | --- | --- |',
	$rows
) -join [Environment]::NewLine
$summaryPath = Join-Path $OutputDirectory 'summary.md'
[System.IO.File]::WriteAllText($summaryPath, $summary + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
Write-Output "SUMMARY: $summaryPath ($state, $passCount/3)"
if ($state -ne 'PASS') { throw $failure }
