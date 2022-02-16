$ValidationErrors = @()
if (-not (Test-Path env:PFX_THUMBPRINT)) { $ValidationErrors += @("PFX_THUMBPRINT envvar not set") }
if (-not (Test-Path env:PFX_PASSPHRASE)) { $ValidationErrors += @("PFX_PASSPHRASE envvar not set") }
if ($ValidationErrors.Count -gt 0) { 
    Write-Warning "Validation Failed!`n$($ValidationErrors -join "`n")"
    exit 0
}

$msbuild = &"${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -prerelease -products * -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe

Push-Location $PSScriptRoot
& $msbuild /p:Configuration=Release /t:SignMsi

if ($LASTEXITCODE -ne 0) {
    throw "Can't sign msi"
}
exit 0
