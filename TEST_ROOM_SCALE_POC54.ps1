param(
    [ValidateRange(1,20)][int]$RunCount = 3,
    [switch]$CaptureVisuals,
    [string]$OutputDirectory = 'verification/stabilization/runs/poc54',
    [int]$TimeoutSeconds = 360
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'scripts/Invoke-RoomScaleProcess.ps1')
$OutputDirectory = Resolve-RoomScaleOutputPath -Value $OutputDirectory -ProjectRoot $PSScriptRoot
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$godot = & (Join-Path $PSScriptRoot 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
foreach ($check in @('ownership','data','armory','behavior')) {
    $reference = ''
    for ($index=1; $index -le $(if ($check -in @('ownership','data')) {1} else {$RunCount}); $index++) {
        $resultPath = Join-Path $OutputDirectory "$check-$index.json"
        if (Test-Path -LiteralPath $resultPath) { Remove-Item -LiteralPath $resultPath }
        $environment = @{ROOMSCALE_FOCUSED_RESULT=$resultPath}
        $arguments = @('--headless','--path',$PSScriptRoot,'--script',$(if ($check -eq 'ownership') {'res://scripts/economy_ownership_test.gd'} else {"res://scripts/poc54_${check}_test.gd"}))
        if ($CaptureVisuals -and $check -eq 'behavior' -and $index -eq 1) {
            $arguments = @('--path',$PSScriptRoot,'--script',$(if ($check -eq 'ownership') {'res://scripts/economy_ownership_test.gd'} else {"res://scripts/poc54_${check}_test.gd"}))
            $environment.ROOMSCALE_VISUAL_DIR = Join-Path $OutputDirectory 'ability-visuals'
        }
        $run = Invoke-RoomScaleProcess -FilePath $godot -ProjectRoot $PSScriptRoot -ArgumentList $arguments -Environment $environment -LogPath (Join-Path $OutputDirectory "$check-$index.log") -TimeoutSeconds $TimeoutSeconds
        if ($run.TimedOut -or $run.ExitCode -ne 0 -or $run.Content -match 'ERROR:|SCRIPT ERROR:' -or $run.Content -notmatch 'ROOMSCALE_(POC54_(DATA|ARMORY|BEHAVIOR)|ECONOMY_OWNERSHIP)_PASS') { throw "POC54 $check failed; inspect $($run.LogPath)" }
        if ($check -notin @('ownership','data')) {
            if (-not (Test-Path -LiteralPath $resultPath)) { throw 'Missing POC54 receipt' }
            $result = Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json
            if ($result.result -ne 'PASS') { throw 'POC54 receipt failed' }
            $fingerprint = $result | ConvertTo-Json -Depth 60 -Compress
            if ($index -eq 1) { $reference = $fingerprint }
            elseif ($reference -ne $fingerprint) { throw "Fresh-process $check determinism mismatch" }
        }
        Write-Output "ROOMSCALE_POC54_FOCUSED_PASS check=$check run=$index"
    }
}
& (Join-Path $PSScriptRoot 'TEST_ROOM_SCALE_CONFLICT.ps1') -Room room_conflict_c -Scenario three_party_conflict -Innovation -RunCount $RunCount -CaptureVisuals:$CaptureVisuals -OutputDirectory (Join-Path $OutputDirectory 'live') -TimeoutSeconds $TimeoutSeconds
Write-Output "ROOMSCALE_POC54_PASS identical=$RunCount/$RunCount"
