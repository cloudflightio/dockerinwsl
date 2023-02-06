param (
    [Switch]$Debug
)

$DebugPreference = "SilentlyContinue" 
if($Debug){
    $DebugPreference = "Continue"
}
$WarningPreference = "SilentlyContinue" 

function Write-Ok {
    param(
        $Object
    )
    Write-Host -ForegroundColor Green -BackgroundColor Black -NoNewline "[OK  ]" 
    Write-Host -NoNewline " " 
    Write-Host -Object $Object
}

function Write-Fail {
    param(
        $Object
    )
    Write-Host -ForegroundColor Red -BackgroundColor Black -NoNewline "[FAIL]"
    Write-Host -NoNewline " " 
    Write-Host -Object $Object
}

function Check-ExecutableExistsInPath {
    param(
        [Parameter(Position=0, ParameterSetName="single")]
        [string]$Command,
        [Parameter(Position=0, ParameterSetName="multi")]
        [object[]]$Commands
    )
    if($PSCmdlet.ParameterSetName -eq "single") {
        $Commands = @($Command)
    }
    $Commands | ForEach-Object {
        if ($c = Get-Command "$_" -ErrorAction SilentlyContinue) 
        {
            Write-Ok "$_ exists ($($c.Source))"
        } else {
            Write-Fail "$_ missing from path"
        }
    }
}

function Check-InvokeOutput {
    param(
        [string]$Command,
        [string[]]$Arguments,
        [ScriptBlock]$Check
    ) 
    $output = (& $Command $Arguments | Out-String)  -replace "`0" #wsl output sanitation
    Write-Debug $output
    if($Check.InvokeWithContext($null, (New-Object PSVariable '_',$output), $null)){
        Write-Ok "'$Command $Arguments' succeeded"
    } else {
        Write-Fail "'$Command $Arguments' failed!"
    }
}

function Check-Connectifity {
    param(
        [Parameter(Position=0, ParameterSetName="single")]
        $Target,
        [Parameter(Position=0, ParameterSetName="multi")]
        $Targets,
        $Port
    )
    if($PSCmdlet.ParameterSetName -eq "single") {
        $Targets = @($Target)
    }
    $Targets | ForEach-Object {
        if(Test-NetConnection -ComputerName $_ -Port $Port -InformationLevel Quiet -ErrorAction SilentlyContinue) {
            Write-Ok "${_}:${Port} reachable"
        } else {
            Write-Fail "${_}:${Port} unreachable!"
        }
    }
}

Check-ExecutableExistsInPath -Commands @("wsl", "docker","docker-wsl")
Check-InvokeOutput -Command wsl -Arguments @("-l") -Check { $_ -match "clf_dockerinwsl" }
Check-Connectifity -Targets @("localhost", "127.0.0.1", "[::1]") -Port 2375

# DNS Check from WSL
Check-InvokeOutput -Command wsl -Arguments @("-d", "clf_dockerinwsl","nslookup","one.one.one.one") -Check { $_ -match "Address: 1.1.1.1" } 
Check-InvokeOutput -Command wsl -Arguments @("-d", "clf_dockerinwsl","nslookup","host.docker.internal") -Check { $_ -match "Address: 192.168.67.2" }
Check-InvokeOutput -Command wsl -Arguments @("-d", "clf_dockerinwsl","nslookup","gateway.docker.internal") -Check { $_ -match "Address: 192.168.67.1" }
Check-InvokeOutput -Command wsl -Arguments @("-d", "clf_dockerinwsl","nslookup","host.internal") -Check { $_ -match "Address: 192.168.67.2" }
Check-InvokeOutput -Command wsl -Arguments @("-d", "clf_dockerinwsl","nslookup","wsl.internal") -Check { $_ -match "Address: 192.168.67.3" }

# DNS Check from Container
Check-InvokeOutput -Command docker -Arguments @("run", "--rm","-it", "alpine", "nslookup","one.one.one.one") -Check { $_ -match "Address: 1.1.1.1" } 
Check-InvokeOutput -Command docker -Arguments @("run", "--rm","-it", "alpine", "nslookup", "host.docker.internal") -Check { $_ -match "Address: 192.168.67.2" }
Check-InvokeOutput -Command docker -Arguments @("run", "--rm","-it", "alpine", "nslookup","gateway.docker.internal") -Check { $_ -match "Address: 192.168.67.1" }
Check-InvokeOutput -Command docker -Arguments @("run", "--rm","-it", "alpine", "nslookup","host.internal") -Check { $_ -match "Address: 192.168.67.2" }
Check-InvokeOutput -Command docker -Arguments @("run", "--rm","-it", "alpine", "nslookup","wsl.internal") -Check { $_ -match "Address: 192.168.67.3" }
