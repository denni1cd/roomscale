param(
    [ValidateRange(1,20)][int]$RunCount = 3,
    [switch]$CaptureVisuals,
    [string]$OutputDirectory = 'verification/stabilization/runs/combat-roles',
    [int]$TimeoutSeconds = 180
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'scripts/Invoke-RoomScaleProcess.ps1')
$OutputDirectory = Resolve-RoomScaleOutputPath -Value $OutputDirectory -ProjectRoot $PSScriptRoot
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$godot = & (Join-Path $PSScriptRoot 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
foreach ($test in @('combat_roles','combat_role_behavior')) {
    $reference = ''
    for ($index=1; $index -le $(if ($test -eq 'combat_roles') {1} else {$RunCount}); $index++) {
        $resultPath = Join-Path $OutputDirectory "$test-$index.json"
        if (Test-Path -LiteralPath $resultPath) { Remove-Item -LiteralPath $resultPath }
        $environment = @{ROOMSCALE_FOCUSED_RESULT=$resultPath}
        $arguments = @('--headless','--path',$PSScriptRoot,'--script',"res://scripts/${test}_test.gd")
        if ($CaptureVisuals -and $test -eq 'combat_role_behavior' -and $index -eq 1) {
            $arguments = @('--path',$PSScriptRoot,'--script',"res://scripts/${test}_test.gd")
            $environment.ROOMSCALE_VISUAL_DIR = Join-Path $OutputDirectory 'visuals'
        }
        $run = Invoke-RoomScaleProcess -FilePath $godot -ArgumentList $arguments -ProjectRoot $PSScriptRoot -LogPath (Join-Path $OutputDirectory "$test-$index.log") -Environment $environment -TimeoutSeconds $TimeoutSeconds
        if ($run.TimedOut -or $run.ExitCode -ne 0 -or $run.Content -match 'ERROR:|SCRIPT ERROR:' -or $run.Content -notmatch 'ROOMSCALE_(ROLES|ROLE_BEHAVIOR)_PASS') { throw "Combat roles failed: $test. See $($run.LogPath)" }
        if ($test -eq 'combat_role_behavior') {
            if (-not (Test-Path -LiteralPath $resultPath)) { throw 'Missing role behavior receipt' }
            $result = Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json
            if ($result.result -ne 'PASS') { throw 'Failed role behavior receipt' }
            $fingerprint = $result.observations | ConvertTo-Json -Depth 40 -Compress
            if ($index -eq 1) { $reference = $fingerprint }
            elseif ($reference -ne $fingerprint) { throw 'Fresh-process role combat replay differs' }
        }
        Write-Output "ROOMSCALE_COMBAT_ROLE_GATE_PASS test=$test run=$index"
    }
}
Write-Output "ROOMSCALE_COMBAT_ROLE_REPLAY_PASS identical=$RunCount/$RunCount"
