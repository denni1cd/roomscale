param(
    [ValidateSet('Fast','Scenario','Repeatability','All')][string]$Mode = 'All',
    [string]$OutputDirectory = 'verification/poc47/release',
    [int]$RunCount = 3,
    [int]$TimeoutSeconds = 1200,
    [switch]$CaptureVisuals,
    [string]$PythonExecutable = 'python'
)
$ErrorActionPreference = 'Stop'
$poc47Root = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $poc47Root 'scripts/Invoke-RoomScaleProcess.ps1')
$poc47Godot = & (Join-Path $poc47Root 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
$poc47Output = Resolve-RoomScaleOutputPath -Value $OutputDirectory -ProjectRoot $poc47Root
New-Item -ItemType Directory -Force -Path $poc47Output | Out-Null
$jobs = [Collections.Generic.List[object]]::new()
if ($Mode -in @('Fast','All')) {$jobs.Add(@{Name='fast'; Script='poc47_fast_test'; Days=0; Marker='POC47_FAST_PASS'})}
if ($Mode -eq 'Scenario') {$jobs.Add(@{Name='scenario'; Script='poc47_scenario_test'; Days=8; Marker='POC47_SCENARIO_PASS'})}
if ($Mode -in @('Repeatability','All')) {
    if ($RunCount -lt 3) {throw 'Repeatability requires at least three fresh runs.'}
    for ($run=1; $run -le $RunCount; $run++) {$jobs.Add(@{Name=('repeat-{0:D2}' -f $run); Script='poc47_scenario_test'; Days=8; Marker='POC47_SCENARIO_PASS'})}
}
$results = [Collections.Generic.List[object]]::new()
foreach ($job in $jobs) {
    if ($CaptureVisuals -and $job.Days -gt 0) {$job.Script = 'poc47_scenario_test'}
    $log = Join-Path $poc47Output ($job.Name + '.log')
    $resultFile = Join-Path $poc47Output ($job.Name + '.json')
    $errorText = ''
    $watch = [Diagnostics.Stopwatch]::StartNew()
    try {
        $runEnvironment = @{}
        $runEnvironment.ROOMSCALE_ROOM_FILE = ''
        $runEnvironment.ROOMSCALE_FISHBOWL = '0'
        $runEnvironment.ROOMSCALE_POC45_DAYS = [string]$job.Days
        $runEnvironment.ROOMSCALE_POC45_RESULT = $resultFile
        $runEnvironment.ROOMSCALE_DISABLE_STARTUP_CAPTURE = '1'
        $runEnvironment.ROOMSCALE_VISUAL_DIR = ''
        $arguments = @('--headless','--path',$poc47Root,'--script',('res://scripts/' + $job.Script + '.gd'))
        if ($CaptureVisuals -and $job.Days -gt 0) {
            $runEnvironment.ROOMSCALE_VISUAL_DIR = Join-Path $poc47Output ($job.Name + '-visuals')
            $arguments = @('--audio-driver','Dummy','--path',$poc47Root,'--script',('res://scripts/' + $job.Script + '.gd'))
        }
        Remove-Item -LiteralPath $resultFile -Force -ErrorAction SilentlyContinue
        $execution = Invoke-RoomScaleProcess -FilePath $poc47Godot -ArgumentList $arguments -ProjectRoot $poc47Root -LogPath $log -TimeoutSeconds $TimeoutSeconds -Environment $runEnvironment
        $timedOut = $execution.TimedOut
        $content = $execution.Content
        if ($timedOut -or $execution.ExitCode -ne 0 -or $content -notmatch [regex]::Escape($job.Marker) -or $content -match 'SCRIPT ERROR:|ERROR:|POC4[567]_\w+_FAIL') {throw "Failed $($job.Name) timeout=$timedOut exit=$($execution.ExitCode); see $log"}
        if ($job.Days -gt 0) {
            $state = Get-Content -LiteralPath $resultFile -Raw | ConvertFrom-Json
            if ($state.result -ne 'PASS') {throw 'Missing production scenario PASS result'}
        }
    } catch {$errorText = $_.Exception.Message}
    $watch.Stop()
    $results.Add([pscustomobject]@{Run=$job.Name; Passed=(-not $errorText); Seconds=[Math]::Round($watch.Elapsed.TotalSeconds,2); Days=$job.Days; Log=$log; Error=$errorText})
    $results | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $poc47Output 'summary.json')
    Write-Output "$($job.Name) $(if ($errorText) {'FAIL'} else {'PASS'}) seconds=$([Math]::Round($watch.Elapsed.TotalSeconds,2))"
    if ($errorText) {throw $errorText}
}
if ($Mode -in @('Repeatability','All')) {
    & $PythonExecutable (Join-Path $poc47Root 'scripts/canonical_results.py') $poc47Output --run-count $RunCount
    if ($LASTEXITCODE -ne 0) { throw 'Canonical founder receipts differ; inspect determinism-summary.json.' }
}
Write-Output "POC47_BATCH_PASS runs=$($results.Count)"
