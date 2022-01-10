.PHONY: init image image_7z package install uninstall

init:
	choco install 7zip docker-cli wixtoolset

image:
	docker build -t dockerinwsl:latest .
	docker run --name dockerinwsl dockerinwsl:latest || true
	docker export --output=dockerinwsl.tar dockerinwsl
	docker rm --force dockerinwsl

image_7z: image
	rm dockerinwsl.tar.7z || true
	7z a dockerinwsl.tar.7z dockerinwsl.tar

package:
	choco pack

install: package
	choco install dockerinwsl --force -y -dv -pre -s .

uninstall:
	choco uninstall dockerinwsl -y
