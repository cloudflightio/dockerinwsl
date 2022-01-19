#!/bin/sh

$backup_path = "."

containers=$(docker ps -q | xargs -i docker inspect --format='{{.Name}}' {} | cut -f2 -d\/)
for container_name in containers; do 
    echo -n "$container_name - "
    container_image=$(docker inspect --format='{{.Config.Image}}' $container_name)
    mkdir -p $backup_path/$container_name
    docker save $container_image | gzip > "$backup_path/$container_name/$container_name-image.tar.gz" 
    docker export $container_image | gzip > "$backup_path/$container_name/$container_name.tar.gz"
    docker run --rm --userns=host \
        --volumes-from $container_name \
        -v $backup_path:/backup \
        -e TAR_OPTS="$tar_opts" \
        piscue/docker-backup \
            backup "$container_name/$container_name-volume.tar.xz"
done
