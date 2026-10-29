param(
	[ValidateRange(60, 1800)][int]$TimeoutSeconds = 600,
	[string]$GodotExecutable = '',
	[ValidateSet('', 'room-a', 'room-b', 'reconstructed-room')][string]$OnlyCase = ''
)

$ErrorActionPreference = 'Stop'
$EvidenceDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $EvidenceDirectory '..\..\..'))
. (Join-Path $ProjectRoot 'scripts/Invoke-RoomScaleProcess.ps1')

if ([string]::IsNullOrWhiteSpace($GodotExecutable)) {
	$GodotExecutable = Join-Path $ProjectRoot '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe'
}
if (-not (Test-Path -LiteralPath $GodotExecutable -PathType Leaf)) {
	throw "Godot 4.7.2 console executable not found: $GodotExecutable"
}

$RegistryResourcePath = 'res://verification/poc25/final/best-current-art-showcase-registry-v089.json'
$RegistryPath = Join-Path $ProjectRoot 'verification/poc25/final/best-current-art-showcase-registry-v089.json'
$ProductionRegistryPath = Join-Path $ProjectRoot 'art/registry.json'
$CitizenAgentPath = Join-Path $ProjectRoot 'scripts/citizen_agent.gd'
$RegistryHash = (Get-FileHash -LiteralPath $RegistryPath -Algorithm SHA256).Hash.ToLowerInvariant()
$ProductionRegistryHash = (Get-FileHash -LiteralPath $ProductionRegistryPath -Algorithm SHA256).Hash.ToLowerInvariant()
$CitizenAgentHash = (Get-FileHash -LiteralPath $CitizenAgentPath -Algorithm SHA256).Hash.ToLowerInvariant()
$SourceCommit = (& git -C $ProjectRoot rev-parse HEAD).Trim()
$Cases = @(
	[pscustomobject]@{ Name = 'room-a'; Room = 'room_a'; RoomFile = '' },
	[pscustomobject]@{ Name = 'room-b'; Room = 'room_b'; RoomFile = '' },
	[pscustomobject]@{ Name = 'reconstructed-room'; Room = 'room_photo_luna'; RoomFile = (Join-Path $ProjectRoot 'verification/poc2/candidates/primary/attempt-7/room_photo_luna.json') }
)
if (-not [string]::IsNullOrWhiteSpace($OnlyCase)) {
	$Cases = @($Cases | Where-Object { $_.Name -eq $OnlyCase })
}
$RequiredMarkers = @(
	'ROOMSCALE_M2_SMOKE_PASS',
	'ROOMSCALE_M3_SMOKE_PASS',
	'ROOMSCALE_M4_SMOKE_PASS',
	'ROOMSCALE_M5_SMOKE_PASS',
	'ROOMSCALE_M6_SMOKE_PASS',
	'ROOMSCALE_M8_SMOKE_PASS',
	'ROOMSCALE_CIVILIZATION_SMOKE_PASS'
)
$Results = [System.Collections.Generic.List[object]]::new()

$RegistryTestEnvironment = @{
	ROOMSCALE_ROOM = 'room_photo_luna'
	ROOMSCALE_ROOM_FILE = (Join-Path $ProjectRoot 'verification/poc2/candidates/primary/attempt-7/room_photo_luna.json')
	ROOMSCALE_CIVILIZATION = 'clockwork'
	ROOMSCALE_DISABLE_STARTUP_CAPTURE = '1'
	ROOMSCALE_VISUAL_DIR = ''
	ROOMSCALE_VISUAL_PHASES = ''
	ROOMSCALE_ART_REGISTRY = $RegistryResourcePath
	ROOMSCALE_ART_REGISTRY_MODE = 'review_showcase'
}
$RegistryTestLog = Join-Path $EvidenceDirectory 'v089-review-registry-contract.log'
$RegistryTest = Invoke-RoomScaleProcess `
	-FilePath $GodotExecutable `
	-ArgumentList @('--headless', '--path', $ProjectRoot, '--script', 'res://verification/poc25/final/verify-v089-review-registry.gd') `
	-ProjectRoot $ProjectRoot `
	-LogPath $RegistryTestLog `
	-TimeoutSeconds 180 `
	-Environment $RegistryTestEnvironment
if ($RegistryTest.TimedOut -or $RegistryTest.ExitCode -ne 0 -or $RegistryTest.Content -notmatch 'ROOMSCALE_V089_REVIEW_REGISTRY_PASS' -or $RegistryTest.Content -match 'SCRIPT ERROR:|ROOMSCALE_V089_REVIEW_REGISTRY_FAIL:|ROOMSCALE_REQUIRED_VISUAL_ASSET_FAILURE') {
	throw "Exact v089 review-only registry contract failed; see $RegistryTestLog"
}
$RegistryTestHeader = @(
	"source_commit=$SourceCommit",
	"tested_citizen_agent_sha256=$CitizenAgentHash",
	"art_registry=$RegistryResourcePath",
	"art_registry_sha256=$RegistryHash",
	'art_registry_mode=review_showcase',
	"production_registry_sha256=$ProductionRegistryHash"
) -join [Environment]::NewLine
[System.IO.File]::WriteAllText($RegistryTestLog, $RegistryTestHeader + [Environment]::NewLine + [Environment]::NewLine + $RegistryTest.Content, [System.Text.UTF8Encoding]::new($false))
Write-Output "POC25_V089_REVIEW_REGISTRY_PASS log=$RegistryTestLog"

foreach ($Case in $Cases) {
	$Environment = @{
		ROOMSCALE_ROOM = $Case.Room
		ROOMSCALE_ROOM_FILE = $Case.RoomFile
		ROOMSCALE_CIVILIZATION = 'clockwork'
		ROOMSCALE_DISABLE_STARTUP_CAPTURE = '1'
		ROOMSCALE_VISUAL_DIR = ''
		ROOMSCALE_VISUAL_PHASES = ''
		ROOMSCALE_ART_REGISTRY = $RegistryResourcePath
		ROOMSCALE_ART_REGISTRY_MODE = 'review_showcase'
	}
	$LogPath = Join-Path $EvidenceDirectory ("{0}-v089-review-showcase.log" -f $Case.Name)
	$Execution = Invoke-RoomScaleProcess `
		-FilePath $GodotExecutable `
		-ArgumentList @('--headless', '--path', $ProjectRoot, '--script', 'res://scripts/smoke_test.gd') `
		-ProjectRoot $ProjectRoot `
		-LogPath $LogPath `
		-TimeoutSeconds $TimeoutSeconds `
		-Environment $Environment
	$Output = [string]$Execution.Content
	if ($Execution.TimedOut) { throw "$($Case.Name) timed out; see $LogPath" }
	if ($Execution.ExitCode -ne 0) { throw "$($Case.Name) exited $($Execution.ExitCode); see $LogPath" }
	foreach ($Marker in $RequiredMarkers) {
		if ($Output -notmatch [regex]::Escape($Marker)) { throw "$($Case.Name) omitted $Marker; see $LogPath" }
	}
	$RoomMarker = 'ROOMSCALE_M2_SMOKE_PASS room={0} citizens=50 ' -f [regex]::Escape($Case.Room)
	if ($Output -notmatch $RoomMarker) { throw "$($Case.Name) did not report 50 production citizens; see $LogPath" }
	if ($Output -notmatch 'ROOMSCALE_M4_SMOKE_PASS[^\r\n]*deliveries=11') { throw "$($Case.Name) did not verify all 11 deliveries; see $LogPath" }
	if ($Output -notmatch 'ROOMSCALE_M5_SMOKE_PASS[^\r\n]*walked=[0-9.]+in') { throw "$($Case.Name) did not verify actual grapple traversal; see $LogPath" }
	if ($Output -notmatch 'ROOMSCALE_M6_SMOKE_PASS[^\r\n]*explorations=3') { throw "$($Case.Name) did not verify continued exploration; see $LogPath" }
	if ($Output -match 'ROOMSCALE_REQUIRED_VISUAL_ASSET_FAILURE|SCRIPT ERROR:|ROOMSCALE_SMOKE_FAIL:|CIVILIZATIONDEFINITION_INVALID') {
		throw "$($Case.Name) reported an asset or runtime failure; see $LogPath"
	}
	$V089BridgeCount = [regex]::Matches($Output, 'ROOMSCALE_MPFB_CITIZEN_V089_BRIDGE_PASS').Count
	if ($V089BridgeCount -ne 50) {
		throw "$($Case.Name) did not bridge all 50 citizens through v089; count=$V089BridgeCount; see $LogPath"
	}
	if ($Output -notmatch 'ROOMSCALE_VISUAL_ASSET object=ArtPresentation source=res://art/settlement_workshop/iterations/v004/generated/settlement_workshop\.tscn registry_status=accepted review_only=true') {
		throw "$($Case.Name) did not instantiate the registered workshop through review_showcase mode; see $LogPath"
	}
	if ($Case.Room -eq 'room_photo_luna' -and $Output -notmatch 'ROOMSCALE_VISUAL_ASSET object=computer-desk source=res://art/desk/iterations/v007/generated/desk\.tscn registry_status=best_current_review review_only=true') {
		throw "$($Case.Name) did not instantiate desk-v007 from the explicit review-only registry; see $LogPath"
	}
	$Header = @(
		"POC25_V089_SHOWCASE_SMOKE case=$($Case.Name) result=PASS",
		"source_commit=$SourceCommit",
		"tested_citizen_agent_sha256=$CitizenAgentHash",
		"room=$($Case.Room)",
		"room_definition_file=$($Case.RoomFile)",
		"civilization=clockwork",
		"art_registry=$RegistryResourcePath",
		"art_registry_sha256=$RegistryHash",
		'art_registry_mode=review_showcase',
		"production_registry_sha256_before=$ProductionRegistryHash",
		"godot=$((& $GodotExecutable --version).Trim())",
		"v089_bridge_instances=$V089BridgeCount",
		'assertions=50_citizens,navigation,11_deliveries,construction,grapple_deployment,physical_climb,continued_exploration,review_only_registry,no_required_asset_failures,no_script_errors'
	) -join [Environment]::NewLine
	[System.IO.File]::WriteAllText($LogPath, $Header + [Environment]::NewLine + [Environment]::NewLine + $Output, [System.Text.UTF8Encoding]::new($false))
	$Results.Add([pscustomobject]@{
		case = $Case.Name
		room = $Case.Room
		room_definition_file = $Case.RoomFile
		result = 'PASS'
		log = [System.IO.Path]::GetFileName($LogPath)
		seconds = [Math]::Round($Execution.Seconds, 2)
		markers = $RequiredMarkers
		art_registry = $RegistryResourcePath
		art_registry_sha256 = $RegistryHash
		art_registry_mode = 'review_showcase'
	})
	Write-Output "POC25_V089_SHOWCASE_SMOKE_PASS case=$($Case.Name) seconds=$([Math]::Round($Execution.Seconds, 2)) log=$LogPath"
}

$ProductionRegistryHashAfter = (Get-FileHash -LiteralPath $ProductionRegistryPath -Algorithm SHA256).Hash.ToLowerInvariant()
if ($ProductionRegistryHashAfter -ne $ProductionRegistryHash) { throw 'Canonical production art/registry.json changed during the review-only smoke suite.' }
$Summary = [ordered]@{
	result = 'PASS'
	source_commit = $SourceCommit
	runtime_source = 'scripts/citizen_agent.gd'
	runtime_source_sha256 = $CitizenAgentHash
	engine = (& $GodotExecutable --version).Trim()
	civilization = 'clockwork'
	room_definition_sha256 = (Get-FileHash -LiteralPath (Join-Path $ProjectRoot 'verification/poc2/candidates/primary/attempt-7/room_photo_luna.json') -Algorithm SHA256).Hash.ToLowerInvariant()
	art_registry = $RegistryResourcePath
	art_registry_sha256 = $RegistryHash
	art_registry_mode = 'review_showcase'
	production_registry_sha256_before = $ProductionRegistryHash
	production_registry_sha256_after = $ProductionRegistryHashAfter
	production_registry_unchanged = $true
	cases = @($Results)
}
$SummaryPath = Join-Path $EvidenceDirectory 'v089-showcase-smoke-summary.json'
[System.IO.File]::WriteAllText($SummaryPath, ($Summary | ConvertTo-Json -Depth 8) + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
Write-Output "POC25_V089_SHOWCASE_SMOKE_SUITE_PASS summary=$SummaryPath"
