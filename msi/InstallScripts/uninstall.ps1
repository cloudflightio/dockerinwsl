Set-StrictMode -Version 3

. "$PSScriptRoot\_common.ps1"
$distroname = $InstallConfig.distroname
$local_base = $InstallConfig.local_base

if (Test-Command wsl) {
    $wslList = wsl --list
    if (!$wslList) {
        throw "Failed to execute wsl command (error: $LASTEXITCODE)."
    }
    if ($wslList -contains $distroname) {
        & wsl --unregister "$distroname"
        if($LASTEXITCODE -ne 0){
            Write-Warning "Unable to unregister WSL distro $distroname"
        } else {
            Write-Output "WSL Distro $distroname removed"
        }
        Remove-Item -Path $local_base -Force -Recurse
    }
    else {
        Write-Warning "DockerInWSL Distro has already been uninstalled by other means. (missing)"
    }
}
else {
    Write-Warning "DockerInWSL Distro has already been uninstalled by other means. (WSL not installed)"
}
