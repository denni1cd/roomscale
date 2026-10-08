param(
    [string]$OutputDirectory = 'verification/stabilization/runs/civilizations',
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
    @{
        Name = 'definition'
        Script = 'res://scripts/civilization_definition_test.gd'
        Marker = 'ROOMSCALE_CIVILIZATION_DEFINITION_PASS'
        Environment = @{}
    },
    @{
        Name = 'verdant-visual'
        Script = 'res://scripts/civilization_visual_test.gd'
        Marker = 'ROOMSCALE_CIVILIZATION_VISUAL_PASS'
        Environment = @{
            ROOMSCALE_ROOM = 'room_a'
            ROOMSCALE_ROOM_FILE = ''
            ROOMSCALE_CIVILIZATION = 'verdant'
            ROOMSCALE_DISABLE_STARTUP_CAPTURE = '1'
        }
    }
)

foreach ($check in $checks) {
    $logPath = Join-Path $OutputDirectory ($check.Name + '.log')
    $run = Invoke-RoomScaleProcess `
        -FilePath $GodotExecutable `
        -ArgumentList @('--headless', '--path', $ProjectRoot, '--script', $check.Script) `
        -ProjectRoot $ProjectRoot `
        -LogPath $logPath `
        -TimeoutSeconds $TimeoutSeconds `
        -Environment $check.Environment

    Write-Output $run.Content
    if ($run.TimedOut) {
        throw "Civilization check '$($check.Name)' timed out after $TimeoutSeconds seconds. See $($run.LogPath)"
    }
    if ($run.ExitCode -ne 0) {
        throw "Civilization check '$($check.Name)' exited $($run.ExitCode). See $($run.LogPath)"
    }
    if ($run.Content -notmatch [regex]::Escape($check.Marker)) {
        throw "Civilization check '$($check.Name)' omitted marker $($check.Marker). See $($run.LogPath)"
    }
    if ($run.Content -match 'SCRIPT ERROR:|ERROR:.*CIVILIZATION|CIVILIZATIONDEFINITION_INVALID|ROOMSCALE_CIVILIZATION_.*_FAIL') {
        throw "Civilization check '$($check.Name)' emitted an error. See $($run.LogPath)"
    }
    Write-Output "$($check.Marker) log=$($run.LogPath)"
}

Write-Output 'ROOMSCALE_CIVILIZATION_CHECKS_PASS definitions=true verdant_visual=true'
