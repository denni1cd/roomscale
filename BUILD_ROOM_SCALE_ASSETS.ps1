param([string]$LogDirectory = 'verification/poc3/logs')
$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$GodotExecutable = & (Join-Path $ProjectRoot 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
New-Item -ItemType Directory -Force -Path $LogDirectory | Out-Null
& $GodotExecutable --headless --path $ProjectRoot --script res://scripts/asset_pipeline/generate_desk.gd 2>&1 | Tee-Object -FilePath (Join-Path $LogDirectory 'asset-generation.log')
if ($LASTEXITCODE -ne 0) { throw 'Desk generation failed; see asset-generation.log' }
$bytes = [IO.File]::ReadAllBytes((Join-Path $ProjectRoot 'assets/generated/writing_desk.glb'))
if ($bytes.Length -lt 20 -or [Text.Encoding]::ASCII.GetString($bytes, 0, 4) -ne 'glTF' -or [BitConverter]::ToUInt32($bytes, 4) -ne 2 -or [BitConverter]::ToUInt32($bytes, 8) -ne $bytes.Length) { throw 'Generated GLB header/version/length invalid' }
& $GodotExecutable --headless --path $ProjectRoot --editor --import 2>&1 | Tee-Object -FilePath (Join-Path $LogDirectory 'asset-import.log')
if ($LASTEXITCODE -ne 0) { throw 'Godot import failed; see asset-import.log' }
& $GodotExecutable --headless --path $ProjectRoot --script res://scripts/asset_pipeline/validate_assets.gd 2>&1 | Tee-Object -FilePath (Join-Path $LogDirectory 'asset-validation.log')
if ($LASTEXITCODE -ne 0) { throw 'Asset validation failed; see asset-validation.log' }
