param (
    [Parameter(Position = 0)]
    [string]$Command="help",
    [Switch]$NoTranscript,
    [parameter(mandatory=$false, position=1, ValueFromRemainingArguments=$true)]$_
)

$ScriptExitCode = 0
$Transcript = -not $NoTranscript
$TempDir = Join-Path $env:LOCALAPPDATA -ChildPath "Temp"
$LogFilePath = Join-Path $TempDir -ChildPath "dockerinwsl.log"
$LocalBase = "$env:LOCALAPPDATA\DockerInWSL"

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

function Invoke-DockerEngineBackup {
    Stop-Docker
    Push-Location $LocalBase
    & wsl -d "$DISTRONAME" -u root -- sh -c 'wsl-mount && tar -czpf backup.tar.gz /var/lib/docker'
    if($LASTEXITCODE -ne 0) {
        Write-Warning "Backup of existing WSL distro '$DISTRONAME' failed!"
    } else {
        Write-Host "WSL distro backup done"
    }
    Pop-Location
    Start-Docker
}

function Invoke-DockerEngineRestore {
    if (Test-Path ( Join-Path -Path $LocalBase -ChildPath "backup.tar.gz" )) {
        Write-Host "Existing Docker backup found! Restoring ..."
        Stop-Docker
        Push-Location $LocalBase
        & wsl -d "$DISTRONAME" -u root -- sh -c 'wsl-mount && cd / && tar -xpzf $(pwd)/backup.tar.gz -C /'
        if($LASTEXITCODE -ne 0) {
            Write-Warning "Restore Docker on WSL distro '$DISTRONAME' failed! Please inspect the backup-file at $LocalBase\backup.tar.gz and apply it manually to /var/lib/docker inside WSL"
        }
        Pop-Location
        Start-Docker
        Write-Host "Docker restored"
    } else {
        Write-Warning "Restore Docker on WSL distro '$DISTRONAME' failed! No Backup-File found at $LocalBase\backup.tar.gz"
    }
}

function Write-CommandHelp {
    "USAGE: ./$(Get-CalledName) ($($cmds.Keys -join '|'))" | Write-Host
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
    "restore"     = { Invoke-DockerEngineRestore }
    "backup"      = { Invoke-DockerEngineBackup }
    "help"        = { Write-CommandHelp }
}

try {
    if ($Transcript) {
        Start-Transcript -Path $LogFilePath -Append | Out-Null
    }

    if(-not ($Command -in $cmds.Keys)) {
        throw "Unknown command!"
    }
    $cmds[$Command].invoke()
}
catch {
   "ERROR: $($Error[0])" | Write-Output 
    "" | Write-Output
    Write-CommandHelp
    $ScriptExitCode = 1
}
finally {
    if ($Transcript) {
        Stop-Transcript | Out-Null
    }
}

Exit $ScriptExitCode
