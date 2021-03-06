Set-StrictMode -Version 3

$Global:InstallConfig = @{
    distroname      = 'clf_dockerinwsl'
    distroname_data = 'dockerinwsl_data' # not starting with clf_ because of install check would match on data
    local_base      = "$env:LOCALAPPDATA\DockerInWSL"
}

$ErrorActionPreference = 'Stop'; # stop on all errors

function Test-Command($command) {
    Get-Command $command -ErrorAction SilentlyContinue | Out-Null;
    return $?
}

function Get-WslDistroList {
    $wslList = wsl --list
    if (!$wslList) {
        throw "Failed to execute wsl command (error: $LASTEXITCODE)."
    }
    # Hotfix for https://github.com/microsoft/WSL/issues/7767
    $wslList = (($wslList -join ' ').ToCharArray() | % {$result = ""} { $result += ($_ | Where-Object { $_ -imatch "[ a-z_]" }) } { $result })

    return $wslList
}

function Import-WslDistro {
    param(
        [Parameter(Mandatory=$true)]
        $Distroname, 
        [Parameter(Mandatory=$true)]
        $WslImportFrom, 
        [Parameter(Mandatory=$true)]
        $WslImportTo
    )
    
    $ErrFilePath = Get-LogFilePath -withTimestamp -type err -app $Distroname
    $OutFilePath = Get-LogFilePath -withTimestamp -type out -app $Distroname

    New-Item -ItemType Directory -Force -Path $WslImportTo

    Write-Host "Importing WSL distro '$Distroname' from '$WslImportFrom' to '$WslImportTo' ..."
    $p1 = Start-Process -FilePath "wsl" -ArgumentList @("--import", """$Distroname""", """$WslImportTo""", """$WslImportFrom""", "--version", "2") `
                        -NoNewWindow -PassThru -Wait -RedirectStandardError $ErrFilePath -RedirectStandardOutput $OutFilePath
    if($p1.ExitCode -ne 0){
        throw "Unable to import WSL distro from '$WslImportFrom' to '$WslImportTo'"
    }
    Write-Host "WSL Distro '$Distroname' imported"
}

function Stop-WslDistro {
    param(
        [Parameter(Mandatory=$true)]
        $Distroname 
    )

    & wsl "-t" "$Distroname"
    if($LASTEXITCODE -ne 0){
        throw "Unable to shutdown WSL distro '$Distroname'!"
    }
    Write-Host "WSL distro stopped"
}

function Remove-WslDistro {
    param(
        [Parameter(Mandatory=$true)]
        $Distroname 
    )

    & wsl "--unregister" "$Distroname"
    if($LASTEXITCODE -ne 0){
        throw "Unable to remove existing WSL distro '$Distroname'"
    } else {
        Write-Host "WSL distro deleted"
    }
}
