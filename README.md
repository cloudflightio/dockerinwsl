# DockerInWSL

This Project is meant to be a minimal alternative to [Docker Desktop](https://docs.docker.com/desktop/windows/install/). It uses WSL2 and the official "Docker" Container-Image (docker:dind) as a lightweight replacement for the Moby-VM.

## How to install?

The easiest way is to use our private WinGet Repository. See https://github.com/cloudflightio/winget-pkgs for details. 

> **Please check if you have WSL2 installed and activated!** Check if you got a 5.x Linux Kernel Version (preferable 5.10.x or later) installed. Run `wsl --status` to gather info about your WSL version. Try `wsl --install` and `wsl --update` to get the latest WSL install. See https://docs.microsoft.com/en-us/windows/wsl/install for more information.

> :information_source: You can uninstall the default ubuntu-based disto after the install is done using `ẁsl --unregister ubuntu`, it is not needed for DockerInWSL to work.

If you are one of the eager kind just execute the following in a privileged PowerShell window:

```powershell
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/cloudflightio/winget-pkgs/main/cloudflight-code-signing-test.cer' -OutFile $env:temp\cloudflight-code-signing-test.cer; Import-Certificate -FilePath $env:temp\cloudflight-code-signing-test.cer  -CertStoreLocation 'Cert:\LocalMachine\Root' -Verbose
winget source add --name cloudflight https://cloudflightio.github.io/winget-pkgs
winget source update --name cloudflight
winget install dockerinwsl
```

> :warning: Currently, we are using self-signed certificates on the Installer and Repository. 
> This leads to some warning Messages and requires you to import/trust our Certificate.
> Please notice that this could pose a security risk to your machine. This Project is quite young so please use it with caution.

## How to use?

There are different ways to use docker on windows. 

### WSL

The easiest way to use this installation is to directly call docker using WSL:

* open a Powershell window (no "As Administrator" needed).
* navigate to the folder you want to use docker in.
* call `wsl -d clf_dockerinwsl -- docker ...` to call docker-cli directly or just  `wsl -d clf_dockerinwsl` to open a shell inside the docker-enabled WSL2 distro.

> :information_source: You can also use docker-compose this way.

### IntelliJ

If you are using IntelliJ (like we do) it is quite easy to enable docker with DockerInWSL:

* Press Services (Alt + 8) in the navigation bar at the bottom.
* Press Add Service (Alt + Insert) and select Docker Connection.
* Give the connection a name and select TCP socket as the connection method.
* Set tcp://localhost:2375 as the Engine API URL and hit OK.

Now you should be able to connect to Docker from within IntelliJ and control your Containers/Images/Networks/Volumes.

> :information_source: Make sure to call docker-compose up in the Linux environment with `wsl -d <Distro> docker-compose up -d`, using the Intellij Idea for creation would use the docker.exe and causes errors if you map volumes.

> :information_source: GUI actions for docker-compose up (e.g. run icon in docker-compose file editor) currently are not supported by IntelliJ if docker binaries are stored/executed within WSL.

### TestContainers

We are using [TestContainers](https://www.testcontainers.org/) quite a lot. After installing DockerInWSL the environment-veriable DOCKER_HOST should be set to `tcp://localhost:2375`.
To make this change visible to all applications it is recommended to restart your machine. A simple close and reopen of most Apps should be sufficient, but it's windows right ;)

After that TestContainers should recognize the installation and "just work".

## How does it work?

This project is a result of our internal dev setup which uses Docker and TestContainers to provide a convenient way to work with cloud-native environments.
We used "Docker Desktop" in the past but were forced to replace it due to the recent policy change (https://www.docker.com/blog/updating-product-subscriptions/).
Our new (this) setup uses WSL2 and Alpine-Linux with Docker to provide a simple replacement. Currently, it does miss some convenience features, like a management-gui but should also be more lightweight and easier to use.

The whole installation process is handled by MSI and Powershell. At its core the installer is performing the following steps:

* Check if a newer or the same version is installed => Abort install if so.
* Check if WSL is installed properly (currently not working) => Abort if no WSL2 install is found. (We decided to avoid installing it automatically because it can have some side-effects in complex environments)
* Copy all Scripts and a tar export of the [DockerInDocker-Image](https://hub.docker.com/_/docker) to `%PROGRAMFILES%\DockerInWSL`
* Create a directory at `%APPDATALOCAL%\DockerInWSL` and also a startup Shortcut in `shell:startup`.
* Set the `DOCKER_HOST` user environment-variable to `tcp://localhost:2375`
* Run the [install.ps1](msi/InstallScripts/install.ps1) Script
  * Check if a DockerInWSL distro is already installed in WSL2
    * If one is found we create a backup of /var/lib/docker and put it on the host-machine under `%APPDATALOCAL%\DockerInWSL\backup.tar.gz`. (For Win11, there is the possibility to use mounted VHDX files and therefore persist the docker-data between updates. We will try to integrate that in the future)
    * After that we delete the current distro using "wsl unregister <distro>". This deletes the entire docker-storage and leads to a complete wipe (from a docker point of view)
    * You might ask "why not just leave the distro be?": We are currently using the stock "dind" Image to reduce maintenance effort as much as possible. Using this makes in-place upgrades quite hard, we, therefore, decided to go "the docker way", using only destroy/recreate as update path. We might reconsider this in future versions but for now, it seems like the best approach.
  * Import the DockerInWSL tar package from `%APPDATALOCAL%\DockerInWSL\dockerinwsl.tar` to `%APPLOCALDATA\DockerInWSL\wsl` using `wsl --import ...`.
  * Check if there is a file at `%APPDATALOCAL%\DockerInWSL\backup.tar.gz` and extract it. If this fails we are NOT aborting the installation because the old distro is already gone. **If you find your WSL Docker empty after an update, look at the `%APPDATALOCAL%\DockerInWSL\backup.tar.gz`-file and try to extract it manually**
  * Finally, the startup-script [docker.bat](msi/docker.bat) is called to start docker.
* Additionally a Registry-Key is created to support proper updates/uninstalling using MSI.
