
#!/bin/bash

container_name="$1"

if [ -z "$container_name" ]; then
    echo "❌ Error: container name not provided."
    exit 1
fi
#sudo chown -R user0:user0 /home/user0/workspaces
# Get container status
status=$(docker inspect --format='{{.State.Status}}' "$container_name" 2>/dev/null)
if [ "$status" != "running" ]; then
    echo "Starting container '$container_name'..."
    docker start "$container_name" 
fi

real_pwd="$(pwd -P)"

if ! docker exec "$container_name" test -d "$real_pwd"; then
    echo "⚠️  Warning: Current directory $real_pwd is NOT mounted in the container."
    echo "Falling back to container's default home directory..."
    docker exec -it "$container_name" /bin/bash
else
    # 5. Jump in at current path
    docker exec --user $(id -u):$(id -g) -it -w "$real_pwd" "$container_name" /bin/bash
fi





