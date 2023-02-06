@echo off
setlocal
SET sp=%~dp0
powershell.exe -noninteractive -ExecutionPolicy ByPass "& '%sp%docker-wsl-test.ps1' %*"
endlocal
