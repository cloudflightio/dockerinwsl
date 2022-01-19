FROM docker:20.10.12-dind

COPY docker-backup.sh /usr/local/bin/docker-backup
RUN apk add --no-cache docker-compose \
 && chmod +x /usr/local/bin/docker-*
