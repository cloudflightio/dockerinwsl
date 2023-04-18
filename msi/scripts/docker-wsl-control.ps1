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

$DISTRONAME = "clf_dockerinwsl"

function Get-TimeStamp {
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
}

function Get-CalledName {
    $callstack = Get-PSCallStack
    return ($callstack[1].Location -split ':')[0]
}

function Invoke-DockerEngineBackup {
    Stop-Docker
    Push-Location $LocalBase
    & wsl -d "$DISTRONAME" -u root -- sh -c 'ONESHOT=1 wsl-mount && tar -czpf backup.tar.gz /var/lib/docker'
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
        & wsl -d "$DISTRONAME" -u root -- sh -c 'ONESHOT=1 wsl-mount && cd / && tar -xpzf $(pwd)/backup.tar.gz -C /'
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
    "restore"     = { Invoke-DockerEngineRestore }
    "backup"      = { Invoke-DockerEngineBackup }
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
