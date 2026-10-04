param(
    [ValidateSet('Fast','Scenario','Sustained','Repeatability','Stability','All')][string]$Mode = 'All',
    [string]$OutputDirectory = 'verification/poc4/final',
    [int]$TimeoutSeconds = 300,
    [int]$RunCount = 5,
    [switch]$CaptureVisuals
)
$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ProjectRoot 'scripts/Invoke-RoomScaleProcess.ps1')
$GodotExecutable = & (Join-Path $ProjectRoot 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
$OutputDirectory = Resolve-RoomScaleOutputPath -Value $OutputDirectory -ProjectRoot $ProjectRoot
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$runs = [Collections.Generic.List[object]]::new()
if ($Mode -in @('Fast','All')) { $runs.Add(@{Name='fast'; Script='res://scripts/poc4_fast_test.gd'; Days=0; Marker='POC4_FAST_PASS'}) }
if ($Mode -in @('Fast','All')) { $runs.Add(@{Name='contract'; Script='res://scripts/poc4_contract_test.gd'; Days=0; Marker='POC4_CONTRACT_PASS'}) }
if ($Mode -in @('Fast','All')) { $runs.Add(@{Name='cleanup'; Script='res://scripts/poc4_cleanup_test.gd'; Days=0; Marker='POC4_CLEANUP_PASS'}) }
if ($Mode -eq 'Scenario') { $runs.Add(@{Name='scenario'; Script='res://scripts/poc4_scenario_test.gd'; Days=0; Marker='POC4_SCENARIO_PASS'}) }
if ($Mode -eq 'Sustained') { $runs.Add(@{Name='sustained-7days'; Script='res://scripts/poc4_scenario_test.gd'; Days=7; Marker='POC4_SUSTAINED_PASS days_after_recovery=7'}) }
if ($Mode -in @('Repeatability','All')) {
    for ($i=1; $i -le $RunCount; $i++) { $runs.Add(@{Name=('repeat-{0:D2}' -f $i); Script='res://scripts/poc4_scenario_test.gd'; Days=7; Marker='POC4_SUSTAINED_PASS days_after_recovery=7'}) }
}
if ($Mode -in @('Stability','All')) { $runs.Add(@{Name='stability-30days'; Script='res://scripts/poc4_scenario_test.gd'; Days=30; Marker='POC4_SUSTAINED_PASS days_after_recovery=30'}) }
$results = [Collections.Generic.List[object]]::new()
$overall = [Diagnostics.Stopwatch]::StartNew()
foreach ($run in $runs) {
    $log = Join-Path $OutputDirectory ($run.Name + '.log')
    $resultFile = Join-Path $OutputDirectory ($run.Name + '.json')
    $errorText = ''
    $watch = [Diagnostics.Stopwatch]::StartNew()
    try {
        $runEnvironment = @{}
        $runEnvironment.ROOMSCALE_ROOM = 'room_a'
        $runEnvironment.ROOMSCALE_ROOM_FILE = ''
        $runEnvironment.ROOMSCALE_DISABLE_STARTUP_CAPTURE = '1'
        $runEnvironment.ROOMSCALE_POC4_DAYS = [string]$run.Days
        $runEnvironment.ROOMSCALE_POC4_RESULT = $resultFile
        $runEnvironment.ROOMSCALE_VISUAL_DIR = ''
        $arguments = @('--headless','--path',$ProjectRoot,'--script',$run.Script)
        if ($CaptureVisuals -and $run.Script -like '*scenario*') {
            $runEnvironment.ROOMSCALE_VISUAL_DIR = Join-Path $OutputDirectory ($run.Name + '-visuals')
            $arguments = @('--path',$ProjectRoot,'--script',$run.Script)
        }
        Remove-Item -LiteralPath $resultFile -Force -ErrorAction SilentlyContinue
        $execution = Invoke-RoomScaleProcess -FilePath $GodotExecutable -ArgumentList $arguments -ProjectRoot $ProjectRoot -LogPath $log -TimeoutSeconds $TimeoutSeconds -Environment $runEnvironment
        $timedOut = $execution.TimedOut
        $content = $execution.Content
        if ($timedOut -or $execution.ExitCode -ne 0 -or $content -notmatch [regex]::Escape($run.Marker) -or $content -match 'SCRIPT ERROR:|ERROR:|POC4_\w+_FAIL') { throw "Run $($run.Name) failed (timeout=$timedOut exit=$($execution.ExitCode)); see $log" }
        if ($run.Script -like '*scenario*' -and ($content -notmatch 'POC4_SCENARIO_PASS' -or -not (Test-Path -LiteralPath $resultFile))) { throw "Missing full production scenario result: $log" }
    } catch { $errorText = $_.Exception.Message }
    $watch.Stop()
    $results.Add([pscustomobject]@{Run=$run.Name; Passed=(-not $errorText); Seconds=[Math]::Round($watch.Elapsed.TotalSeconds,2); DaysAfterRecovery=$run.Days; Log=$log; Error=$errorText})
    $results | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'summary.json')
    Write-Output "$($run.Name) $(if ($errorText) {'FAIL'} else {'PASS'}) seconds=$([Math]::Round($watch.Elapsed.TotalSeconds,2)) days=$($run.Days) log=$log"
    if ($errorText) { throw $errorText }
}
Write-Output "POC4_BATCH_PASS runs=$($results.Count) elapsed=$([Math]::Round($overall.Elapsed.TotalSeconds,2)) summary=$(Join-Path $OutputDirectory 'summary.json')"
