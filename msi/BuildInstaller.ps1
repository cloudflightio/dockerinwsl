$ErrorActionPreference = "Stop"

$msbuild = &"${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -prerelease -products * -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe

New-Item -Path $PSScriptRoot/tmp -ItemType Directory -Force -ErrorAction SilentlyContinue

function Get-ArgFromDockerfile {
    param (
        $Arg,
        $DockerfilePath="$PSScriptRoot/../docker/Dockerfile"
    )
    (Get-Content $DockerfilePath | Select-String "ARG $Arg=(.*)").Matches.Groups[1].Value.Trim()
}

function Get-RemoteArchive {
    param (
        $Path,
        $ArchivePath,
        $Url,
        $Hash=$null
    )

    if (([bool]$Hash) -and (Test-Path  $Path) -and ((Get-FileHash  $Path).Hash -eq $Hash)) {
        Write-Host "'$Path' up-to-date"
    } else {
        Start-BitsTransfer -Source $Url -Destination $ArchivePath
        Expand-Archive $ArchivePath -DestinationPath (Split-Path $Path) -Force
        $currentHash = (Get-FileHash $Path).Hash
        if (([bool]$Hash) -and ($currentHash -ne $Hash)) {
            Write-Host "Invalid filehash! $currentHash != $Hash"
            return $false
        }
    }
    return $true
}

function Get-RemoteFile {
    param (
        $Path,
        $Url,
        $Hash=$null
    )

    if (([bool]$Hash) -and (Test-Path  $Path) -and ((Get-FileHash  $Path).Hash -eq $Hash)) {
        Write-Host "'$Path' up-to-date"
    } else {
        Start-BitsTransfer -Source $Url -Destination $Path
        $currentHash = (Get-FileHash $Path).Hash
        if (([bool]$Hash) -and ($currentHash -ne $Hash)) {
            Write-Host "Invalid filehash! $currentHash != $Hash"
            return $false
        }
    }
    return $true
}

$VPNKIT_VERSION = Get-ArgFromDockerfile "VPNKIT_VERSION"
$NPIPERELAY_VERSION = Get-ArgFromDockerfile "NPIPERELAY_VERSION"

if (-not (Get-RemoteFile `
    -Path "$PSScriptRoot/tmp/vpnkit.exe" `
    -Url "https://github.com/sakai135/vpnkit/releases/download/v${VPNKIT_VERSION}/vpnkit.exe" `
    -Hash "DC8F989CA2D78403778C2DCB417409CA594CE7977030EA430ECEC99F3D3BC012")) { exit 1 }

if (-not (Get-RemoteArchive `
    -Path "$PSScriptRoot/tmp/npiperelay.exe" `
    -ArchivePath "$PSScriptRoot/tmp/npiperelay.zip" `
    -Url "https://github.com/jstarks/npiperelay/releases/download/v${NPIPERELAY_VERSION}/npiperelay_windows_amd64.zip"  `
    -Hash "FF41951C3F519138BB0E61038D7155C6C38194D4D8A3304F46C67C4572EE8BEC")) { exit 1 }

Push-Location $PSScriptRoot
& $msbuild /p:Configuration=Release /t:"Clean,Build"
Pop-Location

if ($LASTEXITCODE -ne 0) {
    throw "Can't build msi"
}
