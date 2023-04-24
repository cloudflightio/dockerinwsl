.PHONY: msi msi-release image image-run image-build image-data-build
.SHELLFLAGS += -e

image-build: docker/Dockerfile
	docker build -t dockerinwsl:latest -f docker/Dockerfile docker/

image-data-build: docker/Dockerfile.data
	docker build -t dockerinwsl-data:latest -f docker/Dockerfile.data docker/

image.tar: build-image
	docker rm --force dockerinwsl || true
	docker run --name dockerinwsl dockerinwsl:latest || true
	docker export --output=image.tar dockerinwsl
	docker rm --force dockerinwsl

image-data.tar: build-image-data
	docker rm --force dockerinwsl-data || true
	docker run --name dockerinwsl-data dockerinwsl-data:latest || true
	docker export --output=image-data.tar dockerinwsl-data
	docker rm --force dockerinwsl-data

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
