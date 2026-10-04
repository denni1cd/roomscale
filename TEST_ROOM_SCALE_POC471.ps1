param(
    [ValidateSet('Short','Full','Soak','Reproduce','Generate','Review','Explore')][string]$Mode = 'Full',
    [string]$Scenario = '',
    [string]$OutputDirectory = 'verification/poc471/final',
    [int]$Count = 40,
    [int]$Seed = 471000,
    [double]$Days = 8,
    [int]$Workers = 2
)
$ErrorActionPreference = 'Stop'
$campaignRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$campaignGodot = & (Join-Path $campaignRoot 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
$campaignArgs = @((Join-Path $campaignRoot 'scripts/poc471_campaign.py'), '--mode', $Mode.ToLower(), '--godot', $campaignGodot, '--output', $OutputDirectory, '--count', $Count, '--seed', $Seed, '--days', $Days, '--workers', $Workers)
if ($Scenario) {$campaignArgs += @('--scenario', $Scenario)}
& python @campaignArgs
if ($LASTEXITCODE -ne 0) {throw "POC471 campaign failed: exit=$LASTEXITCODE; inspect $OutputDirectory"}
