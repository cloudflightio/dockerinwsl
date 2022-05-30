.PHONY: msi msi-release image
.ONESHELL:
.SHELLFLAGS += -e

image.tar:
	cd docker
	docker build -t dockerinwsl:latest .
	docker rm --force dockerinwsl || true
	docker run --name dockerinwsl dockerinwsl:latest || true
	docker export --output=image.tar dockerinwsl
	docker rm --force dockerinwsl
	mv image.tar ../

image-data.tar:
	cd docker
	docker build -t dockerinwsl-data:latest -f Dockerfile.data .
	docker rm --force dockerinwsl-data || true
	docker run --name dockerinwsl-data dockerinwsl-data:latest || true
	docker export --output=image-data.tar dockerinwsl-data
	docker rm --force dockerinwsl-data
	mv image-data.tar ../

image: image.tar image-data.tar

DockerInWSL.msi: image.tar image-data.tar
	pwsh.exe -ExecutionPolicy ByPass ./msi/BuildInstaller.ps1
	pwsh.exe -ExecutionPolicy ByPass ./msi/SignInstaller.ps1
	mv msi/bin/Release/* ./

msi: DockerInWSL.msi

msi-release:
	pwsh.exe -ExecutionPolicy ByPass ./msi/BuildInstaller.ps1
	pwsh.exe -ExecutionPolicy ByPass ./msi/AzureSignInstaller.ps1
	mv msi/bin/Release/* ./
