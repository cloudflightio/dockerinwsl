.PHONY: image image_7z package install uninstall
.ONESHELL:
.SHELLFLAGS += -e

image:
	cd docker
	docker build -t dockerinwsl:latest .
	docker run --name dockerinwsl dockerinwsl:latest || true
	docker export --output=dockerinwsl.tar dockerinwsl
	docker rm --force dockerinwsl
	mv dockerinwsl.tar ../

msi:
	powershell.exe -ExecutionPolicy ByPass ./msi/BuildInstaller.ps1
	mv msi/Product.msi ./DockerInWSL.msi

install_msi:
	msiexec.exe /i DockerInWSL.msi /L\*vx install.log.txt

repair_msi:
	msiexec.exe /fav ./DockerInWSL.msi /passive /qn /L\*vx repair.log.txt

uninstall_msi:
	msiexec.exe /x ./DockerInWSL.msi

package:
	cp DockerInWSL.msi chocolatey/tools/
	cd chocolatey 
	choco pack
	mv *.nupkg ../

install: package
	choco install dockerinwsl --force -y -dv -pre -s .

uninstall:
	choco uninstall dockerinwsl -y
