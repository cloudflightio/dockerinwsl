@echo off
setlocal
SET sp=%~dp0
powershell.exe -noninteractive -ExecutionPolicy ByPass "& '%sp%docker-wsl-control.ps1' %*"
endlocal
