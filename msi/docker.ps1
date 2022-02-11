param (
    [Parameter(Mandatory = $true, Position = 0)][string]$Command,
    [bool]$Transcript = $true,
    [parameter(mandatory=$false, position=1, ValueFromRemainingArguments=$true)]$_
)

$TempDir = Join-Path $env:LOCALAPPDATA -ChildPath "Temp"
$LogFilePath = Join-Path $TempDir -ChildPath "dockerinwsl.log"

"`n--- $(Get-Date)`n" | Out-File -FilePath $LogFilePath -Append

if ($Transcript) {
    Start-Transcript -Path $LogFilePath -Append
}

$SUPERVISOR_PID = "/run/supervisord.pid"
$DISTRONAME = "clf_dockerinwsl"

function Get-TimeStamp {
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
}

function Start-Docker () {
    "$(Get-TimeStamp) Starting ..." | Out-Host
    wsl -d $DISTRONAME /bin/bash -c "[ -f $SUPERVISOR_PID ] && cat $SUPERVISOR_PID | xargs ps -p > /dev/null"
    if ($LASTEXITCODE -ne 0) {
        wsl -d $DISTRONAME /bin/bash -c "supervisord -c /etc/supervisor/supervisord.conf"
        "$(Get-TimeStamp) ... started!" | Out-Host
    }
    else {
        "$(Get-TimeStamp) docker seems to be running already. $SUPERVISOR_PID found" | Out-Host
    }
}
 
function Stop-Docker () {
    "$(Get-TimeStamp) Stopping ..." | Out-Host
    wsl -d $DISTRONAME /bin/bash -c "[ -f $SUPERVISOR_PID ] && cat $SUPERVISOR_PID | xargs ps -p > /dev/null"
    if ($LASTEXITCODE -eq 0) {
        wsl -d $DISTRONAME /bin/bash -c "supervisorctl stop all; kill `$(cat $SUPERVISOR_PID)"
        "$(Get-TimeStamp) ... stopped!" | Out-Host
    }
    else {
        "$(Get-TimeStamp) docker seems to be stopped already. $SUPERVISOR_PID not found" | Out-Host
    }
    "$(Get-TimeStamp) Shutting down WSL ..." | Out-Host
    wsl --shutdown $DISTRONAME
    "$(Get-TimeStamp) shutdown completed!" | Out-Host
} 

try {
    switch ($Command) {
        "start" { 
            Start-Docker 
        }
        "stop" { 
            Stop-Docker 
        }
        Default {
            throw "Invalid Command '$Command'. Only 'start' and 'stop' supported!"
        }
    }
} 
finally {
    if ($Transcript) {
        Stop-Transcript
    }
}
