#!/bin/bash

# Input arguments
container_name=$1
image_name=$2


# Check if required arguments are provided
if [ -z "$container_name" ] || [ -z "$image_name" ]; then
    echo "Usage: ./container_squash.sh <container_name> <image_name> "
    exit 1
fi

echo "container_name: $container_name"
echo "given image_name: $image_name"

# Stop the container
sudo docker stop "$container_name"

# Get the container ID
cont_id=$(sudo docker ps -a --filter "name=$container_name" --format "{{.ID}}")
if [ -z "$cont_id" ]; then
    echo "Error: No container found with the name $container_name"
    exit 1
fi

echo "cont_id: $cont_id"

# Export the container filesystem to a tar file
sudo docker export "$cont_id" > "container_$container_name.tar"

# Remove the old image (force removal if necessary)
#sudo docker rmi --force "$image_name:$image_ver"
sudo docker rmi --force "$image_name"

# Import the tar file as a new image
cat "container_$container_name.tar" | sudo docker import - "$image_name"

# Cleanup tar file (optional)
rm -f "container_$container_name.tar"

echo "Container $container_name has been squashed into image $image_name"

