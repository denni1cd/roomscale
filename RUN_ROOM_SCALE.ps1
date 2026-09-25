$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$GodotExecutable = & (Join-Path $ProjectRoot 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
if (-not $GodotExecutable -or -not (Test-Path -LiteralPath $GodotExecutable)) {
    throw 'Godot setup did not return a valid executable path.'
}
$VisibleExecutable = $GodotExecutable -replace '_console\.exe$', '.exe'
& $VisibleExecutable --path $ProjectRoot
exit $LASTEXITCODE
