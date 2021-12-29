$distroname = 'clf_dockerinwsl'

$ErrorActionPreference = 'Stop'; # stop on all errors

if ((Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux).State -eq "Enabled") {
  $wslList = $(wsl --list)
  if(!$wslList) {
    throw "Failed to execute wsl command (error: $LASTEXITCODE)."
  }
  if ($wslList -contains $distroname) {
    Remove-Item "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\dockerinwsl.lnk" -ErrorAction SilentlyContinue
    Uninstall-ChocolateyEnvironmentVariable -VariableName "DOCKER_HOST"
    Start-ChocolateyProcessAsAdmin "wsl --unregister $distroname" -validExitCodes @(0)
  } else {
    Write-Warning "$packageName has already been uninstalled by other means. (WSL distro missing)"
  }
} else {
  Write-Warning "$packageName has already been uninstalled by other means. (WSL not installed)"
}
