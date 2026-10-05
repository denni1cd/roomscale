param([string]$OutputDirectory = 'verification/poc472/regressions')
$ErrorActionPreference = 'Stop'
$regressionRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$regressionOutput = [IO.Path]::GetFullPath((Join-Path $regressionRoot $OutputDirectory))
New-Item -ItemType Directory -Force -Path $regressionOutput | Out-Null
$regressionCommands = @(
    @('TEST_ROOM_SCALE_POC47.ps1','-Mode','All','-OutputDirectory',"$OutputDirectory/poc47"),
    @('TEST_ROOM_SCALE_POC46.ps1','-Mode','Fast','-OutputDirectory',"$OutputDirectory/poc46-fast"),
    @('TEST_ROOM_SCALE_POC46.ps1','-Mode','Scenario','-OutputDirectory',"$OutputDirectory/poc46-scenario"),
    @('TEST_ROOM_SCALE_POC45.ps1','-Mode','Fast','-OutputDirectory',"$OutputDirectory/poc45-fast"),
    @('TEST_ROOM_SCALE_POC45.ps1','-Mode','Survival','-OutputDirectory',"$OutputDirectory/poc45-survival"),
    @('TEST_ROOM_SCALE_POC45.ps1','-Mode','Scenario','-OutputDirectory',"$OutputDirectory/poc45-scenario"),
    @('TEST_ROOM_SCALE_POC4.ps1','-Mode','Fast','-OutputDirectory',"$OutputDirectory/poc4-fast"),
    @('TEST_ROOM_SCALE_POC4.ps1','-Mode','Sustained','-TimeoutSeconds','400','-OutputDirectory',"$OutputDirectory/poc4-sustained"),
    @('TEST_ROOM_SCALE_FAST.ps1','-LogPath',"$OutputDirectory/room-definition-fast.log")
)
$regressionReceipts = [Collections.Generic.List[object]]::new()
foreach ($regressionCommand in $regressionCommands) {
    $regressionScript = Join-Path $regressionRoot $regressionCommand[0]
    $regressionArguments = @{}
    for ($regressionIndex = 1; $regressionIndex -lt $regressionCommand.Count; $regressionIndex += 2) {
        $regressionArguments[$regressionCommand[$regressionIndex].TrimStart('-')] = $regressionCommand[$regressionIndex+1]
    }
    & $regressionScript @regressionArguments
    $regressionReceipts.Add([pscustomobject]@{Command=('./' + ($regressionCommand -join ' ')); Passed=$true})
    $regressionReceipts | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $regressionOutput 'commands.json')
}
$regressionGodot = & (Join-Path $regressionRoot 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
foreach ($regressionUnit in @('poc471_navigation_test','poc471_unreachable_task_test','poc471_midlink_test','poc472_planner_test')) {
    $regressionLog = Join-Path $regressionOutput ($regressionUnit + '.log')
    & $regressionGodot --headless --path $regressionRoot --script "res://scripts/$regressionUnit.gd" 2>&1 | Tee-Object -FilePath $regressionLog
    if ($LASTEXITCODE -ne 0 -or (Get-Content -LiteralPath $regressionLog -Raw) -match 'SCRIPT ERROR:|ERROR:|_FAIL') {throw "Focused regression failed: $regressionUnit"}
    $regressionReceipts.Add([pscustomobject]@{Command=('$godot --headless --path . --script res://scripts/' + $regressionUnit + '.gd'); Passed=$true})
    $regressionReceipts | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $regressionOutput 'commands.json')
}
$packingInput = Join-Path $regressionOutput 'packing-input/PLACE-031.json'
$packingGenerator = "import sys; from pathlib import Path; sys.path.insert(0,'scripts'); import poc472_campaign as c; c.prior.write(Path(sys.argv[1]),c.packing_layout()['definition'])"
& python -c $packingGenerator $packingInput
if ($LASTEXITCODE -ne 0) {throw 'Packing fixture generation failed'}
$packingPreviousRoom = $env:ROOMSCALE_ROOM_FILE
try {
    $env:ROOMSCALE_ROOM_FILE = $packingInput
    $packingLog = Join-Path $regressionOutput 'poc472_packing_test.log'
    & $regressionGodot --headless --path $regressionRoot --script res://scripts/poc472_packing_test.gd 2>&1 | Tee-Object -FilePath $packingLog
    if ($LASTEXITCODE -ne 0 -or (Get-Content -LiteralPath $packingLog -Raw) -notmatch 'POC472_PACKING_PASS') {throw 'Packing regression failed'}
} finally {$env:ROOMSCALE_ROOM_FILE = $packingPreviousRoom}
$regressionReceipts.Add([pscustomobject]@{Command=('python -c "' + $packingGenerator + '" "' + $packingInput + '"'); Passed=$true})
$regressionReceipts.Add([pscustomobject]@{Command=('$env:ROOMSCALE_ROOM_FILE = "' + $packingInput + '"; $godot --headless --path . --script res://scripts/poc472_packing_test.gd'); Passed=$true})
$regressionReceipts | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $regressionOutput 'commands.json')
Write-Output "POC472_REGRESSIONS_PASS commands=$($regressionReceipts.Count)"
