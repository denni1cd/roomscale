# Requires PowerShell 7 and .NET process argument/environment APIs.
function Resolve-RoomScaleOutputPath {
    param([Parameter(Mandatory)][string]$Value, [Parameter(Mandatory)][string]$ProjectRoot)
    if (-not [IO.Path]::IsPathRooted($Value)) { $Value = Join-Path $ProjectRoot $Value }
    return [IO.Path]::GetFullPath($Value)
}

function Invoke-RoomScaleProcess {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$ArgumentList,
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$LogPath,
        [ValidateRange(1, 2147483)][int]$TimeoutSeconds = 300,
        [hashtable]$Environment = @{}
    )
    if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'RoomScale test tooling requires PowerShell 7 (pwsh).' }
    $LogPath = Resolve-RoomScaleOutputPath -Value $LogPath -ProjectRoot $ProjectRoot
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $LogPath) | Out-Null
    $info = [Diagnostics.ProcessStartInfo]::new()
    $info.FileName = $FilePath
    $info.WorkingDirectory = $ProjectRoot
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.StandardOutputEncoding = [Text.UTF8Encoding]::new($false)
    $info.StandardErrorEncoding = [Text.UTF8Encoding]::new($false)
    foreach ($argument in $ArgumentList) { $info.ArgumentList.Add($argument) }
    # Test runs must not inherit unrelated RoomScale room/scenario overrides.
    foreach ($key in @($info.Environment.Keys)) {
        if ($key.StartsWith('ROOMSCALE_', [StringComparison]::OrdinalIgnoreCase)) { $info.Environment.Remove($key) | Out-Null }
    }
    foreach ($key in $Environment.Keys) { $info.Environment[$key] = [string]$Environment[$key] }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $info
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $started = $false
    try {
        if (-not $process.Start()) { throw "Failed to start $FilePath" }
        $started = $true
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        $timedOut = -not $process.WaitForExit($TimeoutSeconds * 1000)
        if ($timedOut) {
            $process.Kill($true)
            if (-not $process.WaitForExit(5000)) { throw "Process did not stop within five seconds after timeout: $FilePath" }
        }
        # Both streams are drained concurrently, avoiding full-pipe deadlocks.
        if (-not [Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]@($stdout, $stderr), 5000)) {
            throw "Output streams did not close after process exit: $FilePath"
        }
        $content = $stdout.Result + [Environment]::NewLine + $stderr.Result
        if ($timedOut) { $content = "ROOMSCALE_PROCESS_TIMEOUT after $TimeoutSeconds seconds." + [Environment]::NewLine + $content }
        [IO.File]::WriteAllText($LogPath, $content, [Text.UTF8Encoding]::new($false))
        $watch.Stop()
        return [pscustomobject]@{ Content=$content; ExitCode=$process.ExitCode; TimedOut=$timedOut; Seconds=$watch.Elapsed.TotalSeconds; LogPath=$LogPath }
    } finally {
        if ($started -and -not $process.HasExited) {
            $process.Kill($true)
            $process.WaitForExit(5000) | Out-Null
        }
        $process.Dispose()
    }
}
