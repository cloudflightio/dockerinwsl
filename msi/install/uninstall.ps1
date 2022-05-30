Set-StrictMode -Version 3

. "$PSScriptRoot\_common.ps1"
$distroname = $InstallConfig.distroname
$distroname_data = $InstallConfig.distroname_data
$local_base = $InstallConfig.local_base

if (Test-Command wsl) {
    $wslList = wsl --list
    # Hotfix for https://github.com/microsoft/WSL/issues/7767
    $wslList = (($wslList -join ' ').ToCharArray() | % {$result = ""} { $result += ($_ | Where-Object { $_ -imatch "[ a-z_]" }) } { $result })
    if (!$wslList) {
        throw "Failed to execute wsl command (error: $LASTEXITCODE)."
    }
    if ($wslList -match $distroname) {
        Stop-WslDistro -Distroname $distroname 
        Remove-WslDistro -Distroname $distroname
        Remove-WslDistro -Distroname $distroname_data
        Remove-Item -Path $local_base -Force -Recurse
    }
    else {
        Write-Warning "DockerInWSL Distro has already been uninstalled by other means. (missing)"
    }
}
else {
    Write-Warning "DockerInWSL Distro has already been uninstalled by other means. (WSL not installed)"
}
