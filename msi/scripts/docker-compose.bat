@echo off
setlocal
wsl -d clf_dockerinwsl -- docker compose  %*
endlocal
