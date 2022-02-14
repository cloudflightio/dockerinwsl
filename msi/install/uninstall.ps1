Set-StrictMode -Version 3

. "$PSScriptRoot\_common.ps1"
$distroname = $InstallConfig.distroname
$local_base = $InstallConfig.local_base

if (Test-Command wsl) {
    $wslList = wsl --list
    # Hotfix for https://github.com/microsoft/WSL/issues/7767
    $wslList = (($wslList -join ' ').ToCharArray() | % {$result = ""} { $result += ($_ | Where-Object { $_ -imatch "[ a-z_]" }) } { $result })
    if (!$wslList) {
        throw "Failed to execute wsl command (error: $LASTEXITCODE)."
    }
    if ($wslList -match $distroname) {
        & wsl "--shutdown" "$distroname"
        if($LASTEXITCODE -ne 0){
            throw "Unable to shutdown WSL distro '$distroname'!"
        }
        Write-Output "WSL distro stopped"

        Push-Location $InstallConfig.local_base
        & wsl -d "$distroname" tar -czpf backup.tar.gz /var/lib/docker
        if($LASTEXITCODE -ne 0){
            throw "Backup of existing WSL distro '$distroname' failed!"
        }
        Write-Output "WSL distro backup done"
        Pop-Location

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
