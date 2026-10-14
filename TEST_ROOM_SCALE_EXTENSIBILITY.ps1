param(
    [ValidateRange(1,20)][int]$RunCount = 3,
    [ValidateRange(1,3600)][int]$TimeoutSeconds = 180,
    [string]$OutputDirectory = 'verification/stabilization/runs/poc53-extensibility',
    [string[]]$Checks = @('innovation_extensibility','combat_mixed')
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'scripts/Invoke-RoomScaleProcess.ps1')
$OutputDirectory = Resolve-RoomScaleOutputPath -Value $OutputDirectory -ProjectRoot $PSScriptRoot
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$godot = & (Join-Path $PSScriptRoot 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
if ($Checks.Count -eq 0) { throw 'At least one focused check is required.' }
foreach ($check in $Checks) {
    if ($check -notin @('innovation_extensibility','combat_mixed')) { throw "Unknown check: $check" }
    $reference = ''
    for ($index = 1; $index -le $RunCount; $index++) {
        $resultPath = Join-Path $OutputDirectory "$check-$index.json"
        if (Test-Path -LiteralPath $resultPath) { Remove-Item -LiteralPath $resultPath }
        $run = Invoke-RoomScaleProcess -FilePath $godot -ProjectRoot $PSScriptRoot -ArgumentList @('--headless','--path',$PSScriptRoot,'--script',"res://scripts/${check}_test.gd") -LogPath (Join-Path $OutputDirectory "$check-$index.log") -TimeoutSeconds $TimeoutSeconds -Environment @{ROOMSCALE_FOCUSED_RESULT=$resultPath}
        if ($run.TimedOut -or $run.ExitCode -ne 0 -or $run.Content -match 'ERROR:|SCRIPT ERROR:' -or $run.Content -notmatch 'ROOMSCALE_(EXTENSIBILITY|MIXED_COMBAT)_PASS' -or -not (Test-Path -LiteralPath $resultPath)) { throw "Focused gate failed: $check. Inspect $($run.LogPath)" }
        $result = Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json
        if ($result.result -ne 'PASS') { throw "Failed receipt: $resultPath" }
        $fingerprint = $result | ConvertTo-Json -Depth 40 -Compress
        if ($index -eq 1) { $reference = $fingerprint }
        elseif ($fingerprint -ne $reference) { throw "Focused determinism mismatch: $check" }
        Write-Output "ROOMSCALE_FOCUSED_PASS check=$check run=$index result=$resultPath"
    }
}
Write-Output "ROOMSCALE_EXTENSIBILITY_GATES_PASS identical=$RunCount/$RunCount"
