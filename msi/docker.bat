@echo off
setlocal

set USAGE="Usage: docker.bat (start | stop) <distro>"

set DOCKER_PID=/var/run/docker.pid
set DOCKER_LOG=/var/run/docker.log
set DOCKERD_OPTS=-H unix:///var/run/docker.sock -H tcp://127.0.0.1:2375
 
call :get_argument_count ARG_COUNT %*
 
if not %ARG_COUNT%==2 (
  goto :fail
)
if %1==start (
  call :start_docker %2
  goto :end
)
if %1==stop (
  call :stop_docker %2
  goto :end
)
 
:fail
  echo "invalid invocation" 1>&2
  echo %USAGE% 1>&2
  endlocal
  exit /B 1
 
:end
  endlocal
  exit /B %ERRORLEVEL%
 
:get_argument_count
  set /A "%~1 = -1"
  for %%x in (%*) do set /A "%~1 += 1"
  exit /B 0
 
:start_docker
  wsl -d %1 [ ! -f %DOCKER_PID% ]
  if %ERRORLEVEL%==0 (
    wsl -d %1 /bin/ash -cm "dockerd %DOCKERD_OPTS% < /dev/null > %DOCKER_LOG% 2>&1 &"
    exit /B 0
  ) else (
    echo "docker seems to be running already; %DOCKER_PID% found"
    exit /B 1
  )
 
:stop_docker
  wsl -d %1 [ -f %DOCKER_PID% ]
  if %ERRORLEVEL%==0 (
    wsl -d %1 /bin/ash -c "kill $(cat %DOCKER_PID%)"
    exit /B 0
  ) else (
    echo "docker seems to be stopped already; %DOCKER_PID% not found"
    exit /B 1
  )