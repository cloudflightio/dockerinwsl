$winSdkFolder = if ($env:WINDOWS_SDK) { $env:WINDOWS_SDK_BIN_X64 } else { "C:\Program Files (x86)\Windows Kits\10\bin\10.0.20348.0\x64" }
$signToolPath = Join-Path $winSdkFolder -ChildPath signtool.exe

$pfxPassphrase = ($env:PFX_PASSPHRASE).Trim()
$pfxPath = "$PSScriptRoot\..\Certificate.pfx"
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$cert.Import(( Resolve-Path "$pfxPath"), $pfxPassphrase, "DefaultKeySet")

$thumbprint = $cert.Thumbprint

& $signToolPath sign /f "$pfxPath" /d "DockerInWSL" /p "$pfxPassphrase" /v /sha1 $thumbprint /t "http://timestamp.comodoca.com/authenticode" /fd SHA256 "$PSScriptRoot\Product.msi"
