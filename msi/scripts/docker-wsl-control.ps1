param (
    [Parameter(Position = 0)]
    [string]$Command,
    [Switch]$NoTranscript,
    [parameter(mandatory=$false, position=1, ValueFromRemainingArguments=$true)]$_
)

$ScriptExitCode = 0
$Transcript = -not $NoTranscript
$TempDir = Join-Path $env:LOCALAPPDATA -ChildPath "Temp"
$LogFilePath = Join-Path $TempDir -ChildPath "dockerinwsl.log"

$SUPERVISOR_PID = "/run/supervisord.pid"
$DISTRONAME = "clf_dockerinwsl"

function Get-TimeStamp {
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
}

function Start-Docker () {
    "$(Get-TimeStamp) Starting ..." | Out-Host
    wsl -d $DISTRONAME -u root /bin/bash -c "[ -f $SUPERVISOR_PID ] && cat $SUPERVISOR_PID | xargs ps -p > /dev/null"
    if ($LASTEXITCODE -ne 0) {
        wsl -d $DISTRONAME -u root /bin/bash -c "supervisord -c /etc/supervisor/supervisord.conf"
        "$(Get-TimeStamp) ... started!" | Out-Host
    }
    else {
        "$(Get-TimeStamp) docker seems to be running already. $SUPERVISOR_PID found" | Out-Host
    }
}
 
function Stop-Docker () {
    "$(Get-TimeStamp) Stopping ..." | Out-Host
    wsl -d $DISTRONAME -u root /bin/bash -c "[ -f $SUPERVISOR_PID ] && cat $SUPERVISOR_PID | xargs ps -p > /dev/null"
    if ($LASTEXITCODE -eq 0) {
        wsl -d $DISTRONAME -u root /bin/bash -c "supervisorctl stop all; kill `$(cat $SUPERVISOR_PID)"
        "$(Get-TimeStamp) ... stopped!" | Out-Host
    }
    else {
        "$(Get-TimeStamp) docker seems to be stopped already. $SUPERVISOR_PID not found" | Out-Host
    }
    "$(Get-TimeStamp) Shutting down WSL ..." | Out-Host
    wsl -t $DISTRONAME
    "$(Get-TimeStamp) shutdown completed!" | Out-Host
} 

function Restart-Docker () {
    Stop-Docker
    Start-Docker
}

function Show-Logs() {
    Invoke-Item "\\wsl$\$DISTRONAME\var\log"
}

function Show-ConfigFolder() {
    Invoke-Item (Join-Path (Join-Path $env:APPDATA -ChildPath "DockerInWsl") -ChildPath "config")
}

function Enter-DockerMachineAsUser {
    Start-Process -FilePath "wsl" -ArgumentList @("-d", $DISTRONAME) -Wait -NoNewWindow 
}

function Enter-DockerMachineAsRoot {
    Start-Process -FilePath "wsl" -ArgumentList @("-d", $DISTRONAME, "-u", "root") -Wait -NoNewWindow 
}

function Get-DockerMachineStatus {
    wsl -d $DISTRONAME -u root supervisorctl status
}

function Get-CalledName {
    $callstack = Get-PSCallStack
    return ($callstack[1].Location -split ':')[0]
}

$cmds = [ordered]@{
    "start"       = { Start-Docker }
    "stop"        = { Stop-Docker }
    "restart"     = { Restart-Docker }
    "status"      = { Get-DockerMachineStatus }
    "enter"       = { Enter-DockerMachineAsUser }
    "enter-root"  = { Enter-DockerMachineAsRoot }
    "show-logs"   = { Show-Logs }
    "show-config" = { Show-ConfigFolder }
}

try {
    if ($Transcript) {
        Start-Transcript -Path $LogFilePath -Append | Out-Null
    }

    if(-not ($Command -in $cmds.Keys)) {
        throw "Unknown or missing command!"
    }
   "invoking $Command ..." |  Write-Output
    $cmds[$Command].invoke()
}
catch {
   "ERROR: $($Error[0])" | Write-Output 
    "" | Write-Output
    "USAGE: ./$(Get-CalledName) ($($cmds.Keys -join '|'))" | Write-Output 
    $ScriptExitCode = 1
}
finally {
    if ($Transcript) {
        Stop-Transcript | Out-Null
    }
}

Exit $ScriptExitCode
