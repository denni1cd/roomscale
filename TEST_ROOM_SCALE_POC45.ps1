param(
    [ValidateSet('Fast','Survival','Scenario','Repeatability','Stability','All')][string]$Mode = 'All',
    [string]$OutputDirectory = 'verification/poc45/release',
    [int]$RunCount = 3,
    [int]$TimeoutSeconds = 1200,
    [switch]$CaptureVisuals
)
$ErrorActionPreference = 'Stop'
$poc45Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$poc45Godot = & (Join-Path $poc45Root 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
$poc45Output = [IO.Path]::GetFullPath((Join-Path $poc45Root $OutputDirectory))
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
    $stdout = $log + '.stdout.tmp'
    $stderr = $log + '.stderr.tmp'
    $previous = @{}
    foreach ($key in @('ROOMSCALE_ROOM','ROOMSCALE_ROOM_FILE','ROOMSCALE_FISHBOWL','ROOMSCALE_POC45_DAYS','ROOMSCALE_POC45_RESULT','ROOMSCALE_VISUAL_DIR','ROOMSCALE_DISABLE_STARTUP_CAPTURE')) {$previous[$key] = [Environment]::GetEnvironmentVariable($key,'Process')}
    $errorText = ''
    $watch = [Diagnostics.Stopwatch]::StartNew()
    try {
        $env:ROOMSCALE_ROOM_FILE = ''
        $env:ROOMSCALE_FISHBOWL = '0'
        $env:ROOMSCALE_POC45_DAYS = [string]$job.Days
        $env:ROOMSCALE_POC45_RESULT = $resultFile
        $env:ROOMSCALE_DISABLE_STARTUP_CAPTURE = '1'
        $env:ROOMSCALE_VISUAL_DIR = ''
        $arguments = @('--headless','--path',$poc45Root,'--script',('res://scripts/' + $job.Script + '.gd'))
        if ($CaptureVisuals -and $job.Script -eq 'poc45_scenario_test') {
            $env:ROOMSCALE_VISUAL_DIR = Join-Path $poc45Output ($job.Name + '-visuals')
            $arguments = @('--path',$poc45Root,'--script',('res://scripts/' + $job.Script + '.gd'))
        }
        $process = Start-Process -FilePath $poc45Godot -ArgumentList $arguments -WorkingDirectory $poc45Root -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru -WindowStyle Hidden
        $timedOut = -not $process.WaitForExit([Math]::Max(1,$TimeoutSeconds) * 1000)
        if ($timedOut) {$process.Kill($true); $process.WaitForExit(5000) | Out-Null}
        $process.Refresh()
        $content = [IO.File]::ReadAllText($stdout) + [Environment]::NewLine + [IO.File]::ReadAllText($stderr)
        [IO.File]::WriteAllText($log,$content,[Text.UTF8Encoding]::new($false))
        if ($timedOut -or $process.ExitCode -ne 0 -or $content -notmatch [regex]::Escape($job.Marker) -or $content -match 'SCRIPT ERROR:|ERROR:|POC45_\w+_FAIL') {throw "Failed $($job.Name) timeout=$timedOut exit=$($process.ExitCode); see $log"}
        if ($job.Script -eq 'poc45_scenario_test') {
            $state = Get-Content -LiteralPath $resultFile -Raw | ConvertFrom-Json
            if ($state.result -ne 'PASS') {throw 'Missing production scenario PASS result'}
            if ($job.Days -eq 60 -and ($state.status.days -lt 60 -or $state.maxima.population -lt 100)) {throw 'Stability must reach 60 days and 100 real citizens'}
        }
    } catch {$errorText = $_.Exception.Message}
    finally {
        foreach ($key in $previous.Keys) {[Environment]::SetEnvironmentVariable($key,$previous[$key],'Process')}
        Remove-Item -LiteralPath $stdout,$stderr -Force -ErrorAction SilentlyContinue
    }
    $watch.Stop()
    $results.Add([pscustomobject]@{Run=$job.Name; Passed=(-not $errorText); Seconds=[Math]::Round($watch.Elapsed.TotalSeconds,2); Days=$job.Days; Log=$log; Error=$errorText})
    $results | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $poc45Output 'summary.json')
    Write-Output "$($job.Name) $(if ($errorText) {'FAIL'} else {'PASS'}) seconds=$([Math]::Round($watch.Elapsed.TotalSeconds,2))"
    if ($errorText) {throw $errorText}
}
Write-Output "POC45_BATCH_PASS runs=$($results.Count)"
