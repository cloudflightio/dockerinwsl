Set-StrictMode -Version 3

. "$PSScriptRoot\_common.ps1"

$distroname = $InstallConfig.distroname
$wsl_import_to = Join-Path -Path $InstallConfig.local_base -ChildPath "wsl"
$wsl_import_from = "$PSScriptRoot\..\dockerinwsl.tar"

if (-not (Test-Command wsl)) {
    throw "No WSL installed. Please install Microsoft-Windows-Subsystem-Linux (version 2)."
}

$wslList = wsl --list
if (!$wslList) {
    throw "Failed to execute wsl command (error: $LASTEXITCODE)."
}
# Hotfix for https://github.com/microsoft/WSL/issues/7767
$wslList = (($wslList -join ' ').ToCharArray() | % {$result = ""} { $result += ($_ | Where-Object { $_ -imatch "[ a-z_]" }) } { $result })

if ($wslList -match $distroname) {
    Write-Warning "WSL distro '$distroname' already installed."
    & wsl "--unregister" "$distroname"
    if($LASTEXITCODE -ne 0){
        throw "Unable to remove existing WSL distro '$distroname'"
    }
}

New-Item -ItemType Directory -Force -Path $wsl_import_to
& wsl "--import" "$distroname" $wsl_import_to $wsl_import_from --version 2
if($LASTEXITCODE -ne 0){
    throw "Unable to import WSL distro from '$wsl_import_from' to '$wsl_import_to'"
}
Write-Output "WSL Distro '$distroname' imported"

& "$PSScriptRoot\..\docker.bat" start "$distroname"
if($LASTEXITCODE -ne 0){
    Write-Warning "Unable to start WSL distro from '$distroname'"
} else {
    Write-Output "WSL distro started"
}
