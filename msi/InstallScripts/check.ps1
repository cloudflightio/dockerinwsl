Set-StrictMode -Version 3

. "$PSScriptRoot\_common.ps1"

Add-Type -AssemblyName Microsoft.VisualBasic
if(((wsl --help) | Measure-Object).Count -lt 300){
    [Microsoft.VisualBasic.Interaction]::MsgBox("WSL2 not installed!`n`nTry running 'wsl --install' in an elevated shell, reboot and start this install again.", 'OKOnly,SystemModal,Critical', "DockerInWSL Installation Error") | Out-Null
    throw "WSL2 not installed"
}
