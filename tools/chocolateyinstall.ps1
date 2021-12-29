$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = 'https://onedrive.live.com/download?cid=6DCB03795CEC8D6E&resid=6DCB03795CEC8D6E%21104507&authkey=AMJvQ_5qnCm3c20' # download url, HTTPS preferred

$distroname = 'clf_dockerinwsl'

$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  fileFullPath = "$toolsDir\wsl-base.tar"
  url           = $url

  checksum      = 'E3D2E50E871F0426018DCA13DA6E9CBB3486569F9218F60DADBC803D47857E1A'
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

Get-ChocolateyWebFile @packageArgs

New-Item -ItemType Directory -Force -Path "$env:LOCALAPPDATA\Cloudflight\DockerInWSL\wsl\"

Start-ChocolateyProcessAsAdmin "wsl --import $distroname `"$env:LOCALAPPDATA\Cloudflight\DockerInWSL\wsl\`" `"$toolsDir\wsl-base.tar`"" -validExitCodes @(0)

Install-ChocolateyShortcut `
  -shortcutFilePath "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\dockerinwsl.lnk" `
  -targetPath "$toolsDir\docker.bat" `
  -arguments "start $distroname"

Install-ChocolateyEnvironmentVariable -variableName "DOCKER_HOST" -variableValue "tcp://localhost:2375" -variableType 'User'

Start-ChocolateyProcessAsAdmin "$toolsDir\docker.bat start $distroname" -validExitCodes @(0)
