param(
    [string]$OutputDirectory = 'verification/stabilization/runs/innovation',
    [int]$TimeoutSeconds = 60
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ProjectRoot 'scripts/Invoke-RoomScaleProcess.ps1')
$OutputDirectory = Resolve-RoomScaleOutputPath -Value $OutputDirectory -ProjectRoot $ProjectRoot
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$GodotExecutable = & (Join-Path $ProjectRoot 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
if (-not $GodotExecutable -or -not (Test-Path -LiteralPath $GodotExecutable)) {
    throw 'Godot setup did not return a valid executable path.'
}

$checks = @(
    @{Name='innovation-system'; Script='res://scripts/innovation_system_test.gd'; Marker='ROOMSCALE_INNOVATION_SYSTEM_PASS'},
    @{Name='innovation-robustness'; Script='res://scripts/innovation_robustness_test.gd'; Marker='ROOMSCALE_INNOVATION_ROBUSTNESS_PASS'}
)
foreach ($check in $checks) {
    $logPath = Join-Path $OutputDirectory ($check.Name + '.log')
    $run = Invoke-RoomScaleProcess -FilePath $GodotExecutable `
        -ArgumentList @('--headless', '--path', $ProjectRoot, '--script', $check.Script) `
        -ProjectRoot $ProjectRoot -LogPath $logPath -TimeoutSeconds $TimeoutSeconds
    if ($run.TimedOut -or $run.ExitCode -ne 0 -or $run.Content -notmatch $check.Marker -or $run.Content -match 'ERROR:|SCRIPT ERROR:|ROOMSCALE_INNOVATION_\w+_FAIL') {
        Write-Output $run.Content
        throw "Innovation check failed: $($check.Name). See $logPath"
    }
    Write-Output "$($check.Marker) log=$logPath"
}
Write-Output "ROOMSCALE_INNOVATION_CHECKS_PASS output=$OutputDirectory"
