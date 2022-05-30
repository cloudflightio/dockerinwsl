Set-StrictMode -Version 3

. "$PSScriptRoot\_common.ps1"

$distroname = $InstallConfig.distroname
$distroname_data = $InstallConfig.distroname_data

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

    $wslList = wsl --list
    if (!$wslList) {
        throw "Failed to execute wsl command (error: $LASTEXITCODE)."
    }
    # Hotfix for https://github.com/microsoft/WSL/issues/7767
    $wslList = (($wslList -join ' ').ToCharArray() | % {$result = ""} { $result += ($_ | Where-Object { $_ -imatch "[ a-z_]" }) } { $result })

    if ($wslList -notmatch $distroname_data) {
        Import-WslDistro `
            -Distroname $distroname_data `
            -WslImportFrom (Resolve-Path -Path "$PSScriptRoot\..\image-data.tar").Path `
            -WslImportTo (Join-Path -Path $InstallConfig.local_base -ChildPath "wsl-data")
    }

    if ($wslList -match $distroname) {
        Write-Warning "WSL distro '$distroname' already installed. Updating ..."

        Stop-WslDistro -Distroname $distroname
        Remove-WslDistro -Distroname $distroname
    }

    Import-WslDistro `
        -Distroname $distroname `
        -WslImportFrom (Resolve-Path -Path "$PSScriptRoot\..\image.tar").Path `
        -WslImportTo (Join-Path -Path $InstallConfig.local_base -ChildPath "wsl")

    . "$PSScriptRoot\..\scripts\docker-wsl-control.ps1" -Command "start" -NoTranscript
} finally {
    Stop-Transcript
}