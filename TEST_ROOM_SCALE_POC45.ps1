param(
    [ValidateSet('Fast','Survival','Scenario','Repeatability','Stability','All')][string]$Mode = 'All',
    [string]$OutputDirectory = 'verification/poc45/release',
    [int]$RunCount = 3,
    [int]$TimeoutSeconds = 1200,
    [switch]$CaptureVisuals
)
$ErrorActionPreference = 'Stop'
$poc45Root = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $poc45Root 'scripts/Invoke-RoomScaleProcess.ps1')
$poc45Godot = & (Join-Path $poc45Root 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
$poc45Output = Resolve-RoomScaleOutputPath -Value $OutputDirectory -ProjectRoot $poc45Root
New-Item -ItemType Directory -Force -Path $poc45Output | Out-Null
$jobs = [Collections.Generic.List[object]]::new()
if ($Mode -in @('Fast','All')) {$jobs.Add(@{Name='fast'; Script='poc45_fast_test'; Days=0; Marker='POC45_FAST_PASS'})}
if ($Mode -in @('Survival','All')) {$jobs.Add(@{Name='survival'; Script='poc45_survival_test'; Days=0; Marker='POC45_SURVIVAL_PASS'})}
if ($Mode -eq 'Scenario') {$jobs.Add(@{Name='scenario'; Script='poc45_scenario_test'; Days=8; Marker='POC45_SCENARIO_PASS'})}
if ($Mode -in @('Repeatability','All')) {
    if ($RunCount -lt 3) {throw 'Repeatability requires at least three fresh runs.'}
    for ($run=1; $run -le $RunCount; $run++) {$jobs.Add(@{Name=('repeat-{0:D2}' -f $run); Script='poc45_scenario_test'; Days=8; Marker='POC45_SCENARIO_PASS'})}
}
if ($Mode -in @('Stability','All')) {$jobs.Add(@{Name='stability-60days'; Script='poc45_scenario_test'; Days=60; Marker='POC45_SCENARIO_PASS'})}
$results = [Collections.Generic.List[object]]::new()
foreach ($job in $jobs) {
    $log = Join-Path $poc45Output ($job.Name + '.log')
    $resultFile = Join-Path $poc45Output ($job.Name + '.json')
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
        $arguments = @('--headless','--path',$poc45Root,'--script',('res://scripts/' + $job.Script + '.gd'))
        if ($CaptureVisuals -and $job.Script -eq 'poc45_scenario_test') {
            $runEnvironment.ROOMSCALE_VISUAL_DIR = Join-Path $poc45Output ($job.Name + '-visuals')
            $arguments = @('--path',$poc45Root,'--script',('res://scripts/' + $job.Script + '.gd'))
        }
        Remove-Item -LiteralPath $resultFile -Force -ErrorAction SilentlyContinue
        $execution = Invoke-RoomScaleProcess -FilePath $poc45Godot -ArgumentList $arguments -ProjectRoot $poc45Root -LogPath $log -TimeoutSeconds $TimeoutSeconds -Environment $runEnvironment
        $timedOut = $execution.TimedOut
        $content = $execution.Content
        if ($timedOut -or $execution.ExitCode -ne 0 -or $content -notmatch [regex]::Escape($job.Marker) -or $content -match 'SCRIPT ERROR:|ERROR:|POC45_\w+_FAIL') {throw "Failed $($job.Name) timeout=$timedOut exit=$($execution.ExitCode); see $log"}
        if ($job.Script -eq 'poc45_scenario_test') {
            $state = Get-Content -LiteralPath $resultFile -Raw | ConvertFrom-Json
            if ($state.result -ne 'PASS') {throw 'Missing production scenario PASS result'}
            if ($job.Days -eq 60 -and ($state.status.days -lt 60 -or $state.maxima.population -lt 100)) {throw 'Stability must reach 60 days and 100 real citizens'}
        }
    } catch {$errorText = $_.Exception.Message}
    $watch.Stop()
    $results.Add([pscustomobject]@{Run=$job.Name; Passed=(-not $errorText); Seconds=[Math]::Round($watch.Elapsed.TotalSeconds,2); Days=$job.Days; Log=$log; Error=$errorText})
    $results | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $poc45Output 'summary.json')
    Write-Output "$($job.Name) $(if ($errorText) {'FAIL'} else {'PASS'}) seconds=$([Math]::Round($watch.Elapsed.TotalSeconds,2))"
    if ($errorText) {throw $errorText}
}
Write-Output "POC45_BATCH_PASS runs=$($results.Count)"
