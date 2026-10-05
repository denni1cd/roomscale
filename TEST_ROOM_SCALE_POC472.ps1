param(
    [ValidateSet('Development','Full','Placement','Soak','Reproduce','Review','Control')][string]$Mode = 'Full',
    [string]$Scenario = '',
    [string]$OutputDirectory = 'verification/poc472/final',
    [int]$Workers = 2,
    [string]$PythonExecutable = 'python'
)
$ErrorActionPreference = 'Stop'
$placementRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$placementGodot = & (Join-Path $placementRoot 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
$placementArgs = @((Join-Path $placementRoot 'scripts/poc472_campaign.py'), '--mode', $Mode.ToLower(), '--godot', $placementGodot, '--output', $OutputDirectory, '--workers', $Workers)
if ($Scenario) {$placementArgs += @('--scenario', $Scenario)}
& $PythonExecutable @placementArgs
if ($LASTEXITCODE -ne 0) {throw "POC472 campaign failed: exit=$LASTEXITCODE; inspect $OutputDirectory"}
