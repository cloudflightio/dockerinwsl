Set-StrictMode -Version 3

. "$PSScriptRoot\_common.ps1"

Add-Type -AssemblyName Microsoft.VisualBasic

# Hotfix for https://github.com/microsoft/WSL/issues/7767
$wslHelpText = (((& wsl --help) -join ' ').ToCharArray() | % {$result = ""} { $result += ($_ | Where-Object { $_ -imatch "[ -a-z_]" }) } { $result })
if($wslHelpText.IndexOf("--import") -lt 0) {
    [Microsoft.VisualBasic.Interaction]::MsgBox("WSL2 not initialized!`n`nTry running 'wsl --install --no-distribution' in an elevated shell, reboot and start this install again.", 'OKOnly,SystemModal,Critical', "DockerInWSL Installation Error") | Out-Null
    throw "WSL2 not initialized"
}

wsl --status | Out-Null
if(-not $?){
    [Microsoft.VisualBasic.Interaction]::MsgBox("WSL2 not working!`n`nTry to reboot and start this install again. Please create an issue on GitHub if you see this error after installing wsl and rebooting.", 'OKOnly,SystemModal,Critical', "DockerInWSL Installation Error") | Out-Null
    throw "WSL2 not working"
}
