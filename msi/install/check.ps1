Set-StrictMode -Version 3

. "$PSScriptRoot\_common.ps1"

Add-Type -AssemblyName Microsoft.VisualBasic
$wsl2kernelPath = "$env:WINDIR\system32\lxss\tools\kernel"
if(!(Test-Path -Path $wsl2kernelPath -PathType Leaf)) {
    [Microsoft.VisualBasic.Interaction]::MsgBox("WSL2 not installed!`n`nCheck your windows-updates and run 'wsl --install' in an elevated shell, reboot and start this install again.", 'OKOnly,SystemModal,Critical', "DockerInWSL Installation Error") | Out-Null
    throw "WSL2 not installed"
}

# Hotfix for https://github.com/microsoft/WSL/issues/7767
$wslHelpText = (((& wsl --help) -join ' ').ToCharArray() | % {$result = ""} { $result += ($_ | Where-Object { $_ -imatch "[ -a-z_]" }) } { $result })
if($wslHelpText.IndexOf("--import") -lt 0) {
    [Microsoft.VisualBasic.Interaction]::MsgBox("WSL2 not initialized!`n`nTry running 'wsl --install' in an elevated shell, reboot and start this install again.", 'OKOnly,SystemModal,Critical', "DockerInWSL Installation Error") | Out-Null
    throw "WSL2 not initialized"
}

if ((Get-WmiObject Win32_Product -filter "name like '%Windows Subsystem for Linux Update%'" | Measure-Object).Count -le 0) {
    [Microsoft.VisualBasic.Interaction]::MsgBox("No 'Windows Subsystem for Linux Update' found!`nPlease visit https://docs.microsoft.com/en-us/windows/wsl/install-manual and install the update if this installation fails.") | Out-Null
}
