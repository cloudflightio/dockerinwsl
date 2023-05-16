@echo off
setlocal
SET sp=%~dp0
IF "%1"=="menu" (
START /B %sp%..\gui.exe %*
) ELSE (
%sp%..\gui.exe %*
)
endlocal
