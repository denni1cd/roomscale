param(
    [string]$OutputDirectory = 'verification/stabilization/runs/innovation-live',
    [switch]$CancellationProbe,
    [switch]$CaptureVisuals,
    [string]$Room = 'room_poc47',
    [switch]$RequireLivingStructure,
    [string[]]$Civilizations = @('clockwork','verdant','scavenger'),
    [ValidateRange(1,20)][int]$RunCount = 2,
    [ValidateRange(1,3600)][int]$TimeoutSeconds = 120
)
$ErrorActionPreference = 'Stop'
$ProjectRoot = $PSScriptRoot
. (Join-Path $ProjectRoot 'scripts/Invoke-RoomScaleProcess.ps1')
$OutputDirectory = Resolve-RoomScaleOutputPath -Value $OutputDirectory -ProjectRoot $ProjectRoot
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
if ($Civilizations.Count -eq 0) { throw 'At least one civilization is required.' }
$GodotExecutable = & (Join-Path $ProjectRoot 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
foreach ($civilization in $Civilizations) {
    $reference = ''
    for ($runIndex = 1; $runIndex -le $RunCount; $runIndex++) {
        $resultPath = Join-Path $OutputDirectory "$civilization-$runIndex.json"
        if (Test-Path -LiteralPath $resultPath) { Remove-Item -LiteralPath $resultPath }
        $arguments = @('--path',$ProjectRoot,'--script','res://scripts/innovation_live_test.gd')
        if (-not $CaptureVisuals) { $arguments = @('--headless') + $arguments }
        $visualDirectory = if ($CaptureVisuals) { Join-Path $OutputDirectory "$civilization-$runIndex-visuals" } else { '' }
        $run = Invoke-RoomScaleProcess -FilePath $GodotExecutable -ProjectRoot $ProjectRoot `
            -ArgumentList $arguments `
            -LogPath (Join-Path $OutputDirectory "$civilization-$runIndex.log") -TimeoutSeconds $TimeoutSeconds `
            -Environment @{ROOMSCALE_ROOM=$Room;ROOMSCALE_REQUIRE_LIVING_STRUCTURE=$(if ($RequireLivingStructure) {'1'} else {'0'});ROOMSCALE_VISUAL_DIR=$visualDirectory;ROOMSCALE_INNOVATION_CANCEL_PROBE=$(if ($CancellationProbe) {'1'} else {'0'});ROOMSCALE_CIVILIZATION=$civilization;ROOMSCALE_INNOVATION_RESULT=$resultPath}
        if ($run.ExitCode -ne 0 -or $run.TimedOut -or $run.Content -match 'ERROR:|SCRIPT ERROR:' -or $run.Content -notmatch 'ROOMSCALE_INNOVATION_LIVE_PASS' -or -not (Test-Path -LiteralPath $resultPath)) {
            Write-Output $run.Content
            throw "Live innovation failed: $civilization run=$runIndex. See $($run.LogPath)"
        }
        $result = Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json
        if ($result.result -ne 'PASS') { throw "Live innovation receipt failed: $resultPath" }
        $fingerprint = $result | ConvertTo-Json -Depth 30 -Compress
        if ($runIndex -eq 1) { $reference = $fingerprint }
        elseif ($fingerprint -ne $reference) { throw "Live innovation determinism mismatch: $civilization" }
        Write-Output "ROOMSCALE_INNOVATION_LIVE_PASS civilization=$civilization run=$runIndex result=$resultPath"
    }
}
Write-Output 'ROOMSCALE_INNOVATION_LIVE_CHECKS_PASS'
