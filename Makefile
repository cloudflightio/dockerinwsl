.PHONY: init image package install uninstall

init:
	choco install 7zip docker-cli

image:
	docker build -t dockerinwsl:latest .
	docker run --name dockerinwsl dockerinwsl:latest || true
	docker export --output=dockerinwsl.tar dockerinwsl
	docker rm --force dockerinwsl
	rm dockerinwsl.tar.7z || true
	7z a dockerinwsl.tar.7z dockerinwsl.tar

package:
	choco pack

install: package
	choco install dockerinwsl --force -y -dv -pre -s .

uninstall:
	choco uninstall dockerinwsl -y
