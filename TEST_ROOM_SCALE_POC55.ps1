param(
    [ValidateSet('Focused','Isolation','Graphics','All')][string]$Mode = 'All',
    [string]$OutputDirectory = 'verification/poc55',
    [int]$TimeoutSeconds = 600
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'scripts/Invoke-RoomScaleProcess.ps1')
$destination = Resolve-RoomScaleOutputPath -Value $OutputDirectory -ProjectRoot $PSScriptRoot
New-Item -ItemType Directory -Force -Path $destination | Out-Null
$godot = & (Join-Path $PSScriptRoot 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
function Invoke-Poc55([string]$Name, [string]$Script, [hashtable]$Environment, [bool]$Rendered = $false) {
    $arguments = @('--path', $PSScriptRoot, '--script', "res://scripts/$Script.gd")
    if (-not $Rendered) { $arguments = @('--headless') + $arguments }
    $run = Invoke-RoomScaleProcess -FilePath $godot -ProjectRoot $PSScriptRoot -ArgumentList $arguments -Environment $Environment -LogPath (Join-Path $destination "$Name.log") -TimeoutSeconds $TimeoutSeconds
    if ($run.TimedOut -or $run.ExitCode -ne 0 -or $run.Content -match 'SCRIPT ERROR:|ERROR:' -or $run.Content -notmatch 'POC55_.*PASS|POC55_EVENTS.*"pass":true') {
        throw "POC55 $Name failed; inspect $($run.LogPath)"
    }
    Write-Output "POC55_VERIFIED $Name"
}
if ($Mode -in @('Focused','All')) {
    foreach ($script in @('poc55_events_test','poc55_director_test','poc55_target_lifecycle_test','poc55_producer_test','poc55_ui_test')) {
        Invoke-Poc55 $script $script @{ROOMSCALE_PRODUCER_RESULT=(Join-Path $destination 'producers.json'); ROOMSCALE_VISUAL_DIR=''; ROOMSCALE_CONFLICT=''; ROOMSCALE_ROOM_FILE=''}
    }
}
if ($Mode -in @('Isolation','All')) {
    $reference = $null
    foreach ($directorMode in @('OFF','PRIORITY','RANDOM','FOLLOW')) {
        $resultPath = Join-Path $destination ("isolation-" + $directorMode.ToLower() + '.json')
        Invoke-Poc55 ("isolation-" + $directorMode.ToLower()) 'poc55_live_test' @{ROOMSCALE_DIRECTOR_MODE=$directorMode; ROOMSCALE_FOCUSED_RESULT=$resultPath; ROOMSCALE_VISUAL_DIR=''; ROOMSCALE_ROOM_FILE=''}
        $result = Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json
        $digest = $result.digests | ConvertTo-Json -Compress
        if ($result.result -ne 'PASS') { throw "Live $directorMode failed" }
        if ($null -eq $reference) { $reference = $digest }
        elseif ($digest -ne $reference) { throw "Director $directorMode changes simulation results" }
    }
    @{result='PASS'; modes=@('OFF','PRIORITY','RANDOM','FOLLOW'); digests=($reference | ConvertFrom-Json)} | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath (Join-Path $destination 'isolation-summary.json')
}
if ($Mode -in @('Graphics','All')) {
    Invoke-Poc55 'ui-rendered' 'poc55_ui_test' @{ROOMSCALE_CONFLICT=''; ROOMSCALE_ROOM_FILE=''; ROOMSCALE_VISUAL_DIR=(Join-Path $destination 'graphics')} $true
    foreach ($directorMode in @('PRIORITY','RANDOM')) {
        Invoke-Poc55 ("graphics-" + $directorMode.ToLower()) 'poc55_live_test' @{ROOMSCALE_DIRECTOR_MODE=$directorMode; ROOMSCALE_FOCUSED_RESULT=(Join-Path $destination ("graphics-" + $directorMode.ToLower() + '.json')); ROOMSCALE_VISUAL_DIR=(Join-Path $destination 'graphics'); ROOMSCALE_ROOM_FILE=''} $true
    }
}
Write-Output "ROOMSCALE_POC55_PASS mode=$Mode"
