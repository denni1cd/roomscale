param(
	[string]$Room = 'room_a',
	[string]$Civilization = 'clockwork',
	[string]$LogPath = '',
	[int]$TimeoutSeconds = 360,
	[switch]$CaptureVisuals,
	[string]$VisualDirectory = '',
	[string[]]$VisualPhases = @()
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ProjectRoot 'scripts/Resolve-RoomScaleRoom.ps1')
. (Join-Path $ProjectRoot 'scripts/Invoke-RoomScaleProcess.ps1')
$SelectedRoom = Resolve-RoomScaleRoomInput -Value $Room -ProjectRoot $ProjectRoot
$knownVisualPhases = @('initial-room', 'citizen-inspection', 'living-civilization', 'settlement-close', 'citizen-close', 'resource-carry-close', 'builder-close', 'citizen-climb-close', 'elevated-citizen-close', 'grapple-complete', 'target-investigation', 'resource-hauling', 'construction', 'grapple-deployment', 'citizen-traversal', 'citizen-traversal-detail', 'elevated-surface-exploration', 'elevated-surface-exploration-detail')
foreach ($phase in $VisualPhases) {
	if ($phase -notin $knownVisualPhases) { throw "Unknown visual phase '$phase'. Choose one of: $($knownVisualPhases -join ', ')" }
}
$GodotExecutable = & (Join-Path $ProjectRoot 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
if (-not $GodotExecutable -or -not (Test-Path -LiteralPath $GodotExecutable)) {
    throw 'Godot setup did not return a valid executable path.'
}

if (-not $LogPath) {
	$LogPath = Join-Path $ProjectRoot "verification/poc15/$($SelectedRoom.RoomId)/$($Civilization.ToLowerInvariant())-full-smoke.log"
}
$LogPath = Resolve-RoomScaleOutputPath -Value $LogPath -ProjectRoot $ProjectRoot
$runEnvironment = @{
    ROOMSCALE_ROOM = $SelectedRoom.RoomId
    ROOMSCALE_ROOM_FILE = $(if ($SelectedRoom.IsExplicitFile) { $SelectedRoom.File } else { '' })
    ROOMSCALE_CIVILIZATION = $Civilization.Trim().ToLowerInvariant()
    ROOMSCALE_DISABLE_STARTUP_CAPTURE = '1'
    ROOMSCALE_VISUAL_DIR = ''
    ROOMSCALE_VISUAL_PHASES = $(if ($VisualPhases.Count -gt 0) { $VisualPhases -join ',' } else { '' })
}
if ($CaptureVisuals) {
    if (-not $VisualDirectory) { $VisualDirectory = "verification/poc15/visual/$($SelectedRoom.RoomId)/$($Civilization.ToLowerInvariant())" }
    $VisualDirectory = Resolve-RoomScaleOutputPath -Value $VisualDirectory -ProjectRoot $ProjectRoot
    New-Item -ItemType Directory -Force -Path $VisualDirectory | Out-Null
    $runEnvironment.ROOMSCALE_VISUAL_DIR = $VisualDirectory
}
$arguments = @()
if (-not $CaptureVisuals) { $arguments += '--headless' }
$arguments += @('--path', $ProjectRoot, '--script', 'res://scripts/smoke_test.gd')
$execution = Invoke-RoomScaleProcess -FilePath $GodotExecutable -ArgumentList $arguments -ProjectRoot $ProjectRoot -LogPath $LogPath -TimeoutSeconds $TimeoutSeconds -Environment $runEnvironment
$combined = $execution.Content
$exitCode = $execution.ExitCode
Write-Output $combined
if ($execution.TimedOut) { throw "Godot smoke test timed out after $TimeoutSeconds seconds for $Room civilization=$Civilization. See $LogPath" }
foreach ($marker in @('ROOMSCALE_M2_SMOKE_PASS', 'ROOMSCALE_M3_SMOKE_PASS', 'ROOMSCALE_M4_SMOKE_PASS', 'ROOMSCALE_M5_SMOKE_PASS', 'ROOMSCALE_M6_SMOKE_PASS', 'ROOMSCALE_M8_SMOKE_PASS')) {
	if ($combined -notmatch [regex]::Escape($marker)) {
		throw "Godot smoke test omitted required marker $marker. See $LogPath"
	}
}
if ($combined -match 'SCRIPT ERROR:|ERROR:|ROOMSCALE_SMOKE_FAIL:|CIVILIZATIONDEFINITION_INVALID') {
	throw "Godot smoke test emitted a script/assertion/civilization error. See $LogPath"
}
if ($null -ne $exitCode -and $exitCode -ne 0) {
	throw "Godot smoke test failed with exit code $exitCode. See $LogPath"
}
