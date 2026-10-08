param(
    [string]$Room = 'room_conflict',
    [int]$RunCount = 1,
    [switch]$CaptureVisuals,
    [string]$OutputDirectory = 'verification/stabilization/runs/poc5/conflict',
    [int]$TimeoutSeconds = 180
)
$ErrorActionPreference = 'Stop'
$conflictRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $conflictRoot 'scripts/Invoke-RoomScaleProcess.ps1')
$OutputDirectory = Resolve-RoomScaleOutputPath -Value $OutputDirectory -ProjectRoot $conflictRoot
$godot = & (Join-Path $conflictRoot 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
$fingerprints = @()
for ($runIndex = 1; $runIndex -le $RunCount; $runIndex++) {
    $runDirectory = Join-Path $OutputDirectory "$Room-$runIndex"
    New-Item -ItemType Directory -Force -Path $runDirectory | Out-Null
    $resultPath = Join-Path $runDirectory 'result.json'
    if (Test-Path -LiteralPath $resultPath) { Remove-Item -LiteralPath $resultPath }
    $runEnvironment = @{ROOMSCALE_ROOM=$Room; ROOMSCALE_CONFLICT='1'; ROOMSCALE_MANUAL_CAMERA='1'; ROOMSCALE_DISABLE_STARTUP_CAPTURE='1'; ROOMSCALE_CONFLICT_RESULT=$resultPath}
    $arguments = @('--path',$conflictRoot,'--script','res://scripts/conflict_test.gd')
    if ($CaptureVisuals) { $runEnvironment.ROOMSCALE_VISUAL_DIR = Join-Path $runDirectory 'evidence' }
    else { $arguments = @('--headless') + $arguments }
    $execution = Invoke-RoomScaleProcess -FilePath $godot -ArgumentList $arguments -ProjectRoot $conflictRoot -LogPath (Join-Path $runDirectory 'run.log') -Environment $runEnvironment -TimeoutSeconds $TimeoutSeconds
    if ($execution.TimedOut -or $execution.ExitCode -ne 0 -or $execution.Content -match 'ERROR:|SCRIPT ERROR:|ROOMSCALE_CONFLICT_FAIL' -or $execution.Content -notmatch 'ROOMSCALE_CONFLICT_PASS' -or -not (Test-Path -LiteralPath $resultPath)) { throw "Conflict failed; inspect $($execution.LogPath)" }
    $result = Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json
    if ($result.result -ne 'PASS') { throw "Conflict result failed: $($result.failures)" }
    $fingerprint = $result | Select-Object first_contact_tick,battle_start_tick,force_sizes,casualties,retreating_side,winner,site_capture_tick,attacks,morale,returned,living_populations | ConvertTo-Json -Depth 8 -Compress
    $fingerprints += $fingerprint
    if ($fingerprint -ne $fingerprints[0]) { throw 'Conflict determinism mismatch.' }
    Write-Output "ROOMSCALE_CONFLICT_PASS room=$Room run=$runIndex winner=$($result.winner) capture_tick=$($result.site_capture_tick) result=$resultPath"
}
Write-Output "ROOMSCALE_CONFLICT_REPEATABILITY_PASS identical=$RunCount/$RunCount"
