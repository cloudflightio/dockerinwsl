$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = 'https://github.com/cloudflightio/chocolatey-dockerinwsl/releases/download/v0.0.1/dockerinwsl.tar.z7' # download url, HTTPS preferred

$distroname = 'clf_dockerinwsl'

$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  unzipLocation = "$toolsDir"
  url           = $url

  checksum      = '4044FBBDFC8708A59E60F6CF56CC10DC06CB101290207A04C2B446CC9CA192EC'
  checksumType  = 'sha256' #default is md5, can also be sha1, sha256 or sha512
}

if ((Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux).State -ne "Enabled") {
  throw "No WSL installed. Please install Microsoft-Windows-Subsystem-Linux (version 2)."
}

$wslList = wsl --list
Write-Verbose "$wslList"
if(!$wslList) {
  throw "Failed to execute wsl command (error: $LASTEXITCODE)."
}
if ($wslList -contains $distroname) {
  Write-Warning "WSL distro '$distroname' already installed."
}

Install-ChocolateyZipPackage @packageArgs

New-Item -ItemType Directory -Force -Path "$env:LOCALAPPDATA\Cloudflight\DockerInWSL\wsl\"

Start-ChocolateyProcessAsAdmin "wsl --import $distroname `"$env:LOCALAPPDATA\Cloudflight\DockerInWSL\wsl\`" `"$toolsDir\dockerinwsl.tar`"" -validExitCodes @(0)

Install-ChocolateyShortcut `
  -shortcutFilePath "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\dockerinwsl.lnk" `
  -targetPath "$toolsDir\docker.bat" `
  -arguments "start $distroname"

Install-ChocolateyEnvironmentVariable -variableName "DOCKER_HOST" -variableValue "tcp://localhost:2375" -variableType 'User'

Start-ChocolateyProcessAsAdmin "$toolsDir\docker.bat start $distroname" -validExitCodes @(0)
