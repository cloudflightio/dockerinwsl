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

Push-Location $PSScriptRoot
& $msbuild /p:Configuration=Release /t:"Clean,Build"
Pop-Location

if ($LASTEXITCODE -ne 0) {
    throw "Can't build msi"
}
