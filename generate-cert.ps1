$cert = New-SelfSignedCertificate `
    -Type CodeSigningCert `
    -Subject "CN=Cloudflight Operate Code Signing (TEST), O=Cloudflight Austria GmbH, C=AT" `
    -FriendlyName "Cloudflight Operate Code Signing (TEST)" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}")
if(Test-Path "passphrase.secret") {
    $CertPassword = ConvertTo-SecureString -String (Get-Content ".\passphrase.secret").Trim() -AsPlainText -Force
} else {
    $CertPassword = Read-Host 'Enter Export Password' -AsSecureString
}

Export-PfxCertificate -Cert "cert:\CurrentUser\My\$($cert.Thumbprint)" -FilePath "Certificate.pfx" -Password $CertPassword
