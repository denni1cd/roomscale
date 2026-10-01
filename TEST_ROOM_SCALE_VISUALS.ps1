param([int]$TimeoutSeconds = 30, [string]$LogDirectory = 'verification/poc3/logs')
$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$GodotExecutable = & (Join-Path $ProjectRoot 'SETUP_ROOM_SCALE.ps1') | Select-Object -Last 1
New-Item -ItemType Directory -Force -Path $LogDirectory | Out-Null
$checks = @(
    @{ Name = 'resolver'; Script = 'res://scripts/visuals/visual_resolver_test.gd'; Marker = 'ROOMSCALE_VISUAL_RESOLVER_PASS' },
    @{ Name = 'asset'; Script = 'res://scripts/asset_pipeline/validate_assets.gd'; Marker = 'ROOMSCALE_ASSET_VALIDATION_PASS' },
    @{ Name = 'presentation'; Script = 'res://scripts/visuals/presentation_test.gd'; Marker = 'ROOMSCALE_PRESENTATION_PASS' }
)
foreach ($check in $checks) {
    $logPath = Join-Path $LogDirectory ("visual-check-{0}.log" -f $check.Name)
    $stdoutPath = "$logPath.stdout.tmp"
    $stderrPath = "$logPath.stderr.tmp"
    $process = Start-Process -FilePath $GodotExecutable -ArgumentList @('--headless', '--path', $ProjectRoot, '--script', $check.Script) -WorkingDirectory $ProjectRoot -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath -WindowStyle Hidden -PassThru
    $timedOut = -not $process.WaitForExit([Math]::Max(1, $TimeoutSeconds) * 1000)
    if ($timedOut) { $process.Kill($true); $process.WaitForExit() }
    $process.Refresh()
    $content = [IO.File]::ReadAllText($stdoutPath) + [Environment]::NewLine + [IO.File]::ReadAllText($stderrPath)
    [IO.File]::WriteAllText($logPath, $content, [Text.UTF8Encoding]::new($false))
    if ($timedOut -or $process.ExitCode -ne 0 -or $content -notmatch $check.Marker -or $content -match 'SCRIPT ERROR:|ERROR:') { throw "Visual check $($check.Name) failed or timed out; see $logPath" }
    Write-Output "$($check.Marker) log=$logPath"
}
