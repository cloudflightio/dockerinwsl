$msbuild = &"${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -prerelease -products * -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe

Push-Location $PSScriptRoot
& $msbuild /p:Configuration=Release

if ($LASTEXITCODE -ne 0) {
    throw "Can't build msi"
}
