image:
	docker build -t dockerinwsl:latest .
	docker run --name dockerinwsl dockerinwsl:latest || true
	docker export --output=dockerinwsl.tar dockerinwsl
	docker rm --force dockerinwsl
	rm dockerinwsl.tar.z7 || true
	7z a dockerinwsl.tar.z7 dockerinwsl.tar
