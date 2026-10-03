# One-shot autosync, invoked by Task Scheduler on a timer.
# Keeps PowerShell 5.1 compatible (no ternary, no ?? ).

$ErrorActionPreference = 'Continue'

$repo    = 'C:\Users\Isreal\Downloads\.zip\laptoip roblox hax'
$gitExe  = 'C:\Program Files\Git\cmd\git.exe'
$logFile = 'C:\Users\Isreal\Downloads\.zip\laptoip roblox hax\autosync.log'
$bashExe = 'C:\Program Files\Git\bin\bash.exe'

function Write-Log($msg) {
    $line = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + ' ' + $msg
    Add-Content -Path $logFile -Value $line
    # keep the log bounded: last 200 lines
    $all = Get-Content -Path $logFile -ErrorAction SilentlyContinue
    if ($all.Count -gt 200) {
        $all | Select-Object -Last 200 | Set-Content -Path $logFile
    }
}

if (-not (Test-Path $bashExe)) { Write-Log 'bash.exe not found, aborting'; exit 1 }
if (-not (Test-Path $gitExe))  { Write-Log 'git.exe not found, aborting'; exit 1 }

Push-Location $repo

# is anything actually new/changed?
$status = & $gitExe status --porcelain 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Log ('git status failed: ' + ($status -join ' '))
    Pop-Location
    exit 1
}
if (-not $status -or $status.Count -eq 0) {
    Write-Log 'no changes'
    Pop-Location
    exit 0
}

$changed = $status.Count
$stamp   = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$msg     = "autosync: $changed file(s) at $stamp"

& $gitExe add -A 2>&1 | Out-Null
& $gitExe commit -m $msg 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Log "commit FAILED for $changed file(s)"
    Pop-Location
    exit 1
}

& $gitExe push origin HEAD 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Log "committed + pushed: $msg"
} else {
    Write-Log "committed LOCALLY only (push failed): $msg"
}

Pop-Location
exit 0
