Set-StrictMode -Version 3

. "$PSScriptRoot\_common.ps1"

$distroname = $InstallConfig.distroname
$distroname_data = $InstallConfig.distroname_data
$restoreAfterUpdate = $false

$TempDir = Join-Path $env:LOCALAPPDATA -ChildPath "Temp"

function Get-LogFilePath {
    param(
        [ValidateSet('err','out',$null)] 
        $type=$null, 
        
        $app=$null, 
        
        [switch]
        $withTimestamp=$false
    )
    $timestamp = if($withTimestamp) { "$((Get-Date).Ticks)" } else { $null }
    $filename = @("dockerinwsl-install",$app, $timestamp,$type,"log").Where({ $null -ne $_ }) -join '.'
    return Join-Path $TempDir -ChildPath $filename
}

$LogFilePath = Get-LogFilePath

Start-Transcript -Path $LogFilePath -Append

try {
    if (-not (Test-Command wsl)) {
        throw "No WSL installed. Please install Microsoft-Windows-Subsystem-Linux (version 2)."
    }

    $wslList = Get-WslDistroList

    if ($wslList -match $distroname) {
        Write-Warning "WSL distro '$distroname' already installed. Updating ..."

        & wsl -d "$distroname" -- command -v wsl-mount
        if($LASTEXITCODE -ne 0){
            Write-Warning "WSL distro '$distroname' is pre-data-volume version. Using Backup/Restore update"
            $restoreAfterUpdate = $true

            Push-Location $InstallConfig.local_base
            try {
                & wsl -d "$DISTRONAME" -u root -- sh -c 'tar -czpf backup.tar.gz /var/lib/docker'
                if($LASTEXITCODE -ne 0){
                    throw "Backup of existing WSL distro '$distroname' failed!"
                }
                Write-Host "WSL distro backup done"
            } 
            finally {
                Pop-Location
            }
        }

        Stop-WslDistro -Distroname $distroname
        Remove-WslDistro -Distroname $distroname
    }

    Import-WslDistro `
        -Distroname $distroname `
        -WslImportFrom (Resolve-Path -Path "$PSScriptRoot\..\image.tar").Path `
        -WslImportTo (Join-Path -Path $InstallConfig.local_base -ChildPath "wsl")

    # import data after other distro to avoid setting it as default
    if ($wslList -notmatch $distroname_data) {
        Import-WslDistro `
            -Distroname $distroname_data `
            -WslImportFrom (Resolve-Path -Path "$PSScriptRoot\..\image-data.tar").Path `
            -WslImportTo (Join-Path -Path $InstallConfig.local_base -ChildPath "wsl-data")
    }

    if($restoreAfterUpdate) {
        Write-Warning "Restoring backup ..."

        if (Test-Path ( Join-Path -Path $InstallConfig.local_base -ChildPath "backup.tar.gz" )) {
            Write-Host "Existing Docker backup found! Restoring ..."
            Push-Location $InstallConfig.local_base
            & wsl -d "$DISTRONAME" -u root -- sh -c 'ONESHOT=1 wsl-mount && cd / && tar -xpzf $(pwd)/backup.tar.gz -C /'
            if($LASTEXITCODE -ne 0){
                Write-Warning "Restore Docker on WSL distro '$distroname' failed! Please inspect the backup-file at $($InstallConfig.local_base)\backup.tar.gz and apply it manually to /var/lib/docker inside WSL"
            }
            Pop-Location
            Write-Host "Docker restored"
        }

    }

    . "$PSScriptRoot\..\scripts\docker-wsl-control.ps1" -Command "start" -NoTranscript

} finally {
    Stop-Transcript
}