Set-StrictMode -Version 3

$Global:InstallConfig = @{
    distroname   = 'clf_dockerinwsl'
    local_base    = "$env:LOCALAPPDATA\DockerInWSL"
}

$ErrorActionPreference = 'Stop'; # stop on all errors

function Test-Command($command) {
    Get-Command $command -ErrorAction SilentlyContinue | Out-Null;
    return $?
}
