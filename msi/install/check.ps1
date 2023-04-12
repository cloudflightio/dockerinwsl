Set-StrictMode -Version 3

. "$PSScriptRoot\_common.ps1"

Add-Type -AssemblyName Microsoft.VisualBasic

if(((Get-ChildItem "HKCU:\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\SystemAppData") -match "MicrosoftCorporationII.WindowsSubsystemForLinux_8wekyb3d8bbwe").count -eq 0) {
    [Microsoft.VisualBasic.Interaction]::MsgBox("WSL2 not installed!`n`nCheck your windows-updates and run 'wsl --install -n' in an elevated shell, reboot and start this install again.", 'OKOnly,SystemModal,Critical', "DockerInWSL Installation Error") | Out-Null
    throw "WSL2 not installed"
}

# Hotfix for https://github.com/microsoft/WSL/issues/7767
$wslHelpText = (((& wsl --help) -join ' ').ToCharArray() | % {$result = ""} { $result += ($_ | Where-Object { $_ -imatch "[ -a-z_]" }) } { $result })
if($wslHelpText.IndexOf("--import") -lt 0) {
    [Microsoft.VisualBasic.Interaction]::MsgBox("WSL2 not initialized!`n`nTry running 'wsl --install -n' in an elevated shell, reboot and start this install again.", 'OKOnly,SystemModal,Critical', "DockerInWSL Installation Error") | Out-Null
    throw "WSL2 not initialized"
}

if((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ProductName -match "Windows 11"){
    # We skip checks because Win11 has wsl2 already installed.
} else {
    # Check if WSL Update is installed. (Not using Win32_Product to avoid WMI problems)
    $wslUpdatePackageName = "Windows Subsystem for Linux Update"
    $apps = @()
    $apps += Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" # 32 Bit
    $apps += Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"             # 64 Bit
    $appNames = $apps | Where-Object { $_.PSobject.Properties.Name.Contains("DisplayName") } | Select-Object -ExpandProperty DisplayName
    if (($appNames -match $wslUpdatePackageName | Measure-Object).Count -le 0) {
        [Microsoft.VisualBasic.Interaction]::MsgBox("No '$wslUpdatePackageName' found!`nPlease visit https://docs.microsoft.com/en-us/windows/wsl/install-manual and install the update if this installation fails.", 'OKOnly,SystemModal,Exclamation', "DockerInWSL Installation Warning") | Out-Null
    }
}
