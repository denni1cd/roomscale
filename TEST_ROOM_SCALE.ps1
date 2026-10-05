<#
Current verification entry point (PowerShell 7).
Fast: Python quality/tooling, schema, founder fast, navigation focused tests.
Canonical: three fresh eight-day founder runs.
Regression: meaningful POC4/4.5/4.6 checks and legacy Room A/B smoke.
Robustness:37 POC472 development worlds, including31 placements and feasible NEG-03.
Soak: existing 90/60/60-day founder runs. All includes every category.
Legacy -Room calls, with Mode omitted, retain the historical smoke contract.
Outputs default to ignored verification/stabilization/runs; accepted evidence is curated separately.
#>
param(
    [ValidateSet('Fast','Canonical','Regression','Robustness','Soak','All','Smoke')][string]$Mode = 'Fast',
    [string]$Room = 'room_a',
    [string]$OutputDirectory = 'verification/stabilization/runs',
    [string]$PythonExecutable = 'python',
    [int]$TimeoutSeconds = 1200,
    [string]$LogPath = '',
    [switch]$CaptureVisuals,
    [string]$VisualDirectory = '',
    [string[]]$VisualPhases = @(),
    [int]$Workers = 2
)
$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ProjectRoot 'scripts/Invoke-RoomScaleProcess.ps1')
if (-not $PSBoundParameters.ContainsKey('Mode') -and @('Room','LogPath','CaptureVisuals','VisualDirectory','VisualPhases').Where({$PSBoundParameters.ContainsKey($_)}).Count -gt 0) { $Mode = 'Smoke' }
if ($Mode -eq 'Smoke') {
    if (-not $PSBoundParameters.ContainsKey('TimeoutSeconds')) { $TimeoutSeconds = 360 }
    $smoke = @{Room=$Room; TimeoutSeconds=$TimeoutSeconds; LogPath=$LogPath; CaptureVisuals=$CaptureVisuals; VisualDirectory=$VisualDirectory; VisualPhases=$VisualPhases}
    & (Join-Path $ProjectRoot 'TEST_ROOM_SCALE_SMOKE.ps1') @smoke
    return
}
$OutputDirectory = Resolve-RoomScaleOutputPath -Value $OutputDirectory -ProjectRoot $ProjectRoot
$categories = if ($Mode -eq 'All') { @('Fast','Canonical','Regression','Robustness','Soak') } else { @($Mode) }
foreach ($category in $categories) {
    $out = Join-Path $OutputDirectory $category.ToLower()
    New-Item -ItemType Directory -Force -Path $out | Out-Null
    switch ($category) {
        'Fast' {
            Push-Location $ProjectRoot
            try {
                & $PythonExecutable -m ruff check .
                if ($LASTEXITCODE -ne 0) { throw 'Ruff check failed.' }
                & $PythonExecutable -m ruff format --check .
                if ($LASTEXITCODE -ne 0) { throw 'Ruff format check failed.' }
                & $PythonExecutable -m unittest discover -s scripts -p test_tooling.py
                if ($LASTEXITCODE -ne 0) { throw 'Python tooling regressions failed.' }
            } finally { Pop-Location }
            & (Join-Path $ProjectRoot 'TEST_ROOM_SCALE_TOOLING.ps1') -PythonExecutable $PythonExecutable -OutputDirectory (Join-Path $out 'tooling')
            & (Join-Path $ProjectRoot 'TEST_ROOM_SCALE_FAST.ps1') -LogPath (Join-Path $out 'room-definition.log')
            & (Join-Path $ProjectRoot 'TEST_ROOM_SCALE_POC47.ps1') -Mode Fast -OutputDirectory (Join-Path $out 'founder') -TimeoutSeconds $TimeoutSeconds
            $godot = & (Join-Path $ProjectRoot 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
            foreach ($check in @(@{Script='verification/evidence_io_test'; Marker='ROOMSCALE_EVIDENCE_IO_PASS'}, @{Script='stabilization_core_test'; Marker='STABILIZATION_CORE_PASS'})) {
                $run = Invoke-RoomScaleProcess -FilePath $godot -ArgumentList @('--headless','--path',$ProjectRoot,'--script',("res://scripts/" + $check.Script + '.gd')) -ProjectRoot $ProjectRoot -LogPath (Join-Path $out ($check.Script + '.log')) -TimeoutSeconds $TimeoutSeconds
                if ($run.TimedOut -or $run.ExitCode -ne 0 -or $run.Content -notmatch $check.Marker -or $run.Content -match 'ERROR:|SCRIPT ERROR:') { throw "Focused regression failed: $($check.Script). See $($run.LogPath)" }
                Write-Output "$($check.Marker) log=$($run.LogPath)"
            }
            & (Join-Path $ProjectRoot 'TEST_ROOM_SCALE_POC472_REGRESSIONS.ps1') -Mode Focused -OutputDirectory (Join-Path $out 'placement') -PythonExecutable $PythonExecutable -TimeoutSeconds $TimeoutSeconds
        }
        'Canonical' { & (Join-Path $ProjectRoot 'TEST_ROOM_SCALE_POC47.ps1') -Mode Repeatability -RunCount 3 -OutputDirectory $out -TimeoutSeconds $TimeoutSeconds -CaptureVisuals:$CaptureVisuals -PythonExecutable $PythonExecutable }
        'Regression' {
            & (Join-Path $ProjectRoot 'TEST_ROOM_SCALE_POC46.ps1') -Mode Fast -OutputDirectory (Join-Path $out 'poc46-fast') -TimeoutSeconds $TimeoutSeconds
            & (Join-Path $ProjectRoot 'TEST_ROOM_SCALE_POC46.ps1') -Mode Scenario -OutputDirectory (Join-Path $out 'poc46-scenario') -TimeoutSeconds $TimeoutSeconds
            & (Join-Path $ProjectRoot 'TEST_ROOM_SCALE_POC45.ps1') -Mode Fast -OutputDirectory (Join-Path $out 'poc45-fast') -TimeoutSeconds $TimeoutSeconds
            & (Join-Path $ProjectRoot 'TEST_ROOM_SCALE_POC45.ps1') -Mode Survival -OutputDirectory (Join-Path $out 'poc45-survival') -TimeoutSeconds $TimeoutSeconds
            & (Join-Path $ProjectRoot 'TEST_ROOM_SCALE_POC45.ps1') -Mode Scenario -OutputDirectory (Join-Path $out 'poc45-scenario') -TimeoutSeconds $TimeoutSeconds
            & (Join-Path $ProjectRoot 'TEST_ROOM_SCALE_POC4.ps1') -Mode Fast -OutputDirectory (Join-Path $out 'poc4-fast') -TimeoutSeconds $TimeoutSeconds
            & (Join-Path $ProjectRoot 'TEST_ROOM_SCALE_POC4.ps1') -Mode Sustained -OutputDirectory (Join-Path $out 'poc4-sustained') -TimeoutSeconds $TimeoutSeconds
            foreach ($legacyRoom in @('room_a','room_b')) {
                & (Join-Path $ProjectRoot 'TEST_ROOM_SCALE_SMOKE.ps1') -Room $legacyRoom -LogPath (Join-Path $out ($legacyRoom + '.log')) -TimeoutSeconds $TimeoutSeconds
            }
            & (Join-Path $ProjectRoot 'TEST_ROOM_SCALE_POC472_REGRESSIONS.ps1') -Mode Focused -OutputDirectory (Join-Path $out 'placement') -PythonExecutable $PythonExecutable -TimeoutSeconds $TimeoutSeconds
            & (Join-Path $ProjectRoot 'TEST_ROOM_SCALE_POC471.ps1') -Mode Explore -OutputDirectory (Join-Path $out 'poc471-positive-exploration') -PythonExecutable $PythonExecutable -Workers $Workers
        }
        'Robustness' { & (Join-Path $ProjectRoot 'TEST_ROOM_SCALE_POC472.ps1') -Mode Development -OutputDirectory $out -Workers $Workers -PythonExecutable $PythonExecutable }
        'Soak' { & (Join-Path $ProjectRoot 'TEST_ROOM_SCALE_POC472.ps1') -Mode Soak -OutputDirectory $out -Workers $Workers -PythonExecutable $PythonExecutable }
    }
    Write-Output "ROOMSCALE_CATEGORY_PASS category=$category output=$out"
}
