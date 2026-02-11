
container_name=$1

if [ -z "$container_name" ]; then
    echo error in container name
    exit
fi
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container_name

