$ErrorActionPreference = 'Stop'

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$GodotVersion = '4.7.2'
$GodotDirectory = Join-Path $ProjectRoot '.tools/godot-4.7.2'
$GodotExecutable = Join-Path $GodotDirectory 'Godot_v4.7.2-stable_win64_console.exe'
$DownloadUrl = 'https://godot-releases.nbg1.your-objectstorage.com/4.7.2-stable/Godot_v4.7.2-stable_win64.exe.zip'
$ZipPath = Join-Path $GodotDirectory 'godot-win64.zip'

if (-not (Test-Path -LiteralPath $GodotExecutable)) {
    New-Item -ItemType Directory -Force -Path $GodotDirectory | Out-Null
    Write-Host "Downloading Godot $GodotVersion standard Windows x86-64..."
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipPath
    Expand-Archive -LiteralPath $ZipPath -DestinationPath $GodotDirectory -Force
    Remove-Item -LiteralPath $ZipPath -Force
}

if (-not (Test-Path -LiteralPath $GodotExecutable)) {
    throw "Godot console executable was not found after extracting $ZipPath."
}

$VersionOutput = & $GodotExecutable --version
if ($LASTEXITCODE -ne 0 -or $VersionOutput -notmatch '^4\.7\.2\.stable') {
    throw "Expected Godot $GodotVersion stable, got: $VersionOutput"
}

Write-Host "Godot runtime ready: $VersionOutput"
Write-Host "Executable: $GodotExecutable"
Write-Output $GodotExecutable
