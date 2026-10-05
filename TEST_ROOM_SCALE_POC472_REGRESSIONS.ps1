param(
    [string]$OutputDirectory = 'verification/poc472/regressions',
    [ValidateSet('Full','Focused')][string]$Mode = 'Full',
    [string]$PythonExecutable = 'python',
    [int]$TimeoutSeconds = 1200
)
$ErrorActionPreference = 'Stop'
$regressionRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $regressionRoot 'scripts/Invoke-RoomScaleProcess.ps1')
$regressionOutput = Resolve-RoomScaleOutputPath -Value $OutputDirectory -ProjectRoot $regressionRoot
New-Item -ItemType Directory -Force -Path $regressionOutput | Out-Null
Remove-Item -LiteralPath (Join-Path $regressionOutput 'commands.json') -Force -ErrorAction SilentlyContinue
$regressionCommands = @(
    @('TEST_ROOM_SCALE_POC47.ps1','-Mode','All','-OutputDirectory',"$regressionOutput/poc47"),
    @('TEST_ROOM_SCALE_POC46.ps1','-Mode','Fast','-OutputDirectory',"$regressionOutput/poc46-fast"),
    @('TEST_ROOM_SCALE_POC46.ps1','-Mode','Scenario','-OutputDirectory',"$regressionOutput/poc46-scenario"),
    @('TEST_ROOM_SCALE_POC45.ps1','-Mode','Fast','-OutputDirectory',"$regressionOutput/poc45-fast"),
    @('TEST_ROOM_SCALE_POC45.ps1','-Mode','Survival','-OutputDirectory',"$regressionOutput/poc45-survival"),
    @('TEST_ROOM_SCALE_POC45.ps1','-Mode','Scenario','-OutputDirectory',"$regressionOutput/poc45-scenario"),
    @('TEST_ROOM_SCALE_POC4.ps1','-Mode','Fast','-OutputDirectory',"$regressionOutput/poc4-fast"),
    @('TEST_ROOM_SCALE_POC4.ps1','-Mode','Sustained','-TimeoutSeconds','400','-OutputDirectory',"$regressionOutput/poc4-sustained"),
    @('TEST_ROOM_SCALE_FAST.ps1','-LogPath',"$regressionOutput/room-definition-fast.log")
)
$regressionReceipts = [Collections.Generic.List[object]]::new()
if ($Mode -eq 'Full') {
    foreach ($regressionCommand in $regressionCommands) {
        $regressionScript = Join-Path $regressionRoot $regressionCommand[0]
        $regressionArguments = @{}
        for ($index = 1; $index -lt $regressionCommand.Count; $index += 2) {
            $regressionArguments[$regressionCommand[$index].TrimStart('-')] = $regressionCommand[$index+1]
        }
        if ($regressionCommand[0] -eq 'TEST_ROOM_SCALE_POC47.ps1') { $regressionArguments.PythonExecutable = $PythonExecutable }
        & $regressionScript @regressionArguments
        $regressionReceipts.Add([pscustomobject]@{Command=('./' + ($regressionCommand -join ' ')); Passed=$true})
        $regressionReceipts | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $regressionOutput 'commands.json') -Encoding utf8
    }
}
$regressionGodot = & (Join-Path $regressionRoot 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
$focused = @(
    @{Script='poc471_navigation_test'; Marker='POC471_NAVIGATION_PASS'},
    @{Script='poc471_unreachable_task_test'; Marker='POC471_UNREACHABLE_PASS'},
    @{Script='poc471_midlink_test'; Marker='POC471_MIDLINK_PASS'},
    @{Script='poc472_planner_test'; Marker='POC472_PLANNER_PASS'}
)
foreach ($check in $focused) {
    $log = Join-Path $regressionOutput ($check.Script + '.log')
    $run = Invoke-RoomScaleProcess -FilePath $regressionGodot -ArgumentList @('--headless','--path',$regressionRoot,'--script',("res://scripts/" + $check.Script + '.gd')) -ProjectRoot $regressionRoot -LogPath $log -TimeoutSeconds $TimeoutSeconds
    if ($run.TimedOut -or $run.ExitCode -ne 0 -or $run.Content -notmatch $check.Marker -or $run.Content -match 'SCRIPT ERROR:|ERROR:|_FAIL') { throw "Focused regression failed: $($check.Script). See $log" }
    $regressionReceipts.Add([pscustomobject]@{Command=('$godot --headless --path . --script res://scripts/' + $check.Script + '.gd'); Passed=$true})
    $regressionReceipts | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $regressionOutput 'commands.json') -Encoding utf8
    Write-Output "$($check.Marker) log=$log"
}
$packingInput = Join-Path $regressionOutput 'packing-input/PLACE-031.json'
$packingGenerator = 'import sys; from pathlib import Path; sys.path.insert(0,sys.argv[1]); import poc472_campaign as c; c.prior.write(Path(sys.argv[2]),c.packing_layout()["definition"])'
$generation = Invoke-RoomScaleProcess -FilePath $PythonExecutable -ArgumentList @('-X','utf8','-c',$packingGenerator,(Join-Path $regressionRoot 'scripts'),$packingInput) -ProjectRoot $regressionRoot -LogPath (Join-Path $regressionOutput 'packing-generation.log') -TimeoutSeconds 30
if ($generation.TimedOut -or $generation.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $packingInput)) { throw 'Packing fixture generation failed.' }
$packingLog = Join-Path $regressionOutput 'poc472_packing_test.log'
$run = Invoke-RoomScaleProcess -FilePath $regressionGodot -ArgumentList @('--headless','--path',$regressionRoot,'--script','res://scripts/poc472_packing_test.gd') -ProjectRoot $regressionRoot -LogPath $packingLog -TimeoutSeconds $TimeoutSeconds -Environment @{ROOMSCALE_ROOM_FILE=$packingInput}
if ($run.TimedOut -or $run.ExitCode -ne 0 -or $run.Content -notmatch 'POC472_PACKING_PASS' -or $run.Content -match 'SCRIPT ERROR:|ERROR:|_FAIL') { throw "Packing regression failed. See $packingLog" }
$regressionReceipts.Add([pscustomobject]@{Command=('python -c "' + $packingGenerator + '" "scripts" "' + $packingInput + '"'); Passed=$true})
$regressionReceipts.Add([pscustomobject]@{Command=('$env:ROOMSCALE_ROOM_FILE = "' + $packingInput + '"; $godot --headless --path . --script res://scripts/poc472_packing_test.gd'); Passed=$true})
$regressionReceipts | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $regressionOutput 'commands.json') -Encoding utf8
Write-Output "POC472_PACKING_PASS log=$packingLog"
Write-Output "POC472_REGRESSIONS_PASS commands=$($regressionReceipts.Count) mode=$Mode"
