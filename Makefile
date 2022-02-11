.PHONY: image msi package install uninstall
.ONESHELL:
.SHELLFLAGS += -e

image:
	cd docker
	docker build -t dockerinwsl:latest .
	docker rm --force dockerinwsl || true
	docker run --name dockerinwsl dockerinwsl:latest || true
	docker export --output=dockerinwsl.tar dockerinwsl
	docker rm --force dockerinwsl
	mv dockerinwsl.tar ../

msi:
	pwsh.exe -ExecutionPolicy ByPass ./msi/BuildInstaller.ps1
	pwsh.exe -ExecutionPolicy ByPass ./msi/SignInstaller.ps1
	mv msi/bin/Release/* ./

msi-release:
	pwsh.exe -ExecutionPolicy ByPass ./msi/BuildInstaller.ps1
	pwsh.exe -ExecutionPolicy ByPass ./msi/AzureSignInstaller.ps1
	mv msi/bin/Release/* ./
