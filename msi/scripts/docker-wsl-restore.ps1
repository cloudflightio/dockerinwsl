param (
    [Switch]$NoTranscript,
    [parameter(mandatory=$false, position=1, ValueFromRemainingArguments=$true)]$_
)

$ScriptExitCode = 0
$Transcript = -not $NoTranscript
$TempDir = Join-Path $env:LOCALAPPDATA -ChildPath "Temp"
$LogFilePath = Join-Path $TempDir -ChildPath "dockerinwsl.log"
$LocalBase = "$env:LOCALAPPDATA\DockerInWSL"

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

$DISTRONAME = "dockerinwsl_data"

try {
    if ($Transcript) {
        Start-Transcript -Path $LogFilePath -Append | Out-Null
    }

    if (Test-Path ( Join-Path -Path $LocalBase -ChildPath "backup.tar.gz" )) {
        Write-Host "Existing Docker backup found! Restoring ..."
        & "$scriptPath\..\cli.exe" @('stop')
        Push-Location $LocalBase
        & wsl -d "$DISTRONAME" -u root -- sh -c 'cd / && tar -xpzf $(pwd)/backup.tar.gz -C /'
        if($LASTEXITCODE -ne 0) {
            Write-Warning "Restore Docker on WSL distro '$DISTRONAME' failed! Please inspect the backup-file at $LocalBase\backup.tar.gz and apply it manually to /var/lib/docker inside WSL"
        }
        Pop-Location
        & "$scriptPath\..\cli.exe" @('start')
        Write-Host "Docker restored"
    } else {
        Write-Warning "Restore Docker on WSL distro '$DISTRONAME' failed! No Backup-File found at $LocalBase\backup.tar.gz"
    }
}
catch {
   "ERROR: $($Error[0])" | Write-Output 
    $ScriptExitCode = 1
}
finally {
    if ($Transcript) {
        Stop-Transcript | Out-Null
    }
}

Exit $ScriptExitCode
