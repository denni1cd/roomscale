param([string]$PythonExecutable = 'python', [string]$OutputDirectory = 'verification/stabilization/runs/tooling')
$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ProjectRoot 'scripts/Invoke-RoomScaleProcess.ps1')
$OutputDirectory = Resolve-RoomScaleOutputPath -Value $OutputDirectory -ProjectRoot $ProjectRoot
$priorPoison = [Environment]::GetEnvironmentVariable('ROOMSCALE_POISON','Process')
try {
    $env:ROOMSCALE_POISON = 'inherited'
    $code = "import json,os,sys; print(json.dumps({'arguments':sys.argv[1:],'room':os.getenv('ROOMSCALE_ROOM'),'poison':os.getenv('ROOMSCALE_POISON')}, ensure_ascii=False)); print('stderr café',file=sys.stderr)"
    $arguments = @('-X','utf8','-c',$code,'path with spaces','literal"quote','café')
    $run = Invoke-RoomScaleProcess -FilePath $PythonExecutable -ArgumentList $arguments -ProjectRoot $ProjectRoot -LogPath (Join-Path $OutputDirectory 'quoting.log') -Environment @{ROOMSCALE_ROOM='selected'}
    $state = ($run.Content -split "`r?`n")[0] | ConvertFrom-Json
    if ($run.ExitCode -ne 0 -or $state.arguments[0] -ne 'path with spaces' -or $state.arguments[1] -ne 'literal"quote' -or $state.arguments[2] -ne 'café' -or $state.room -ne 'selected' -or $null -ne $state.poison -or $run.Content -notmatch 'stderr café') { throw 'Process argument/UTF-8/environment regression failed.' }
    if ($env:ROOMSCALE_POISON -ne 'inherited') { throw 'Child process changed parent environment.' }
    $run = Invoke-RoomScaleProcess -FilePath $PythonExecutable -ArgumentList @('-c','import sys; print("failure evidence",file=sys.stderr); sys.exit(7)') -ProjectRoot $ProjectRoot -LogPath (Join-Path $OutputDirectory 'failure.log')
    if ($run.ExitCode -ne 7 -or $run.Content -notmatch 'failure evidence') { throw 'Process failure evidence/exit regression failed.' }
    $run = Invoke-RoomScaleProcess -FilePath $PythonExecutable -ArgumentList @('-c','import time; print("before timeout",flush=True); time.sleep(30)') -ProjectRoot $ProjectRoot -LogPath (Join-Path $OutputDirectory 'timeout.log') -TimeoutSeconds 1
    if (-not $run.TimedOut -or $run.Content -notmatch 'before timeout' -or $run.Content -notmatch 'ROOMSCALE_PROCESS_TIMEOUT') { throw 'Timeout evidence regression failed.' }
    Write-Output 'ROOMSCALE_TOOLING_PASS quoting utf8 environment failure timeout'
} finally {
    [Environment]::SetEnvironmentVariable('ROOMSCALE_POISON',$priorPoison,'Process')
}
