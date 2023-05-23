param (
    [Switch]$NoTranscript,
    [parameter(mandatory=$false, position=1, ValueFromRemainingArguments=$true)]$_
)

Set-StrictMode -Version 2.0 

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
    Write-Host "Starting backup ..."
    & "$scriptPath\..\cli.exe" @('stop')
    Push-Location $LocalBase
    & wsl -d "$DISTRONAME" -u root -- sh -c 'tar -czpf backup.tar.gz /var/lib/docker'
    if($LASTEXITCODE -ne 0) {
        Write-Warning "Backup of existing WSL distro '$DISTRONAME' failed!"
    } else {
        Write-Host "WSL distro backup done"
    }
    Pop-Location
    & "$scriptPath\..\cli.exe" @('start')
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
