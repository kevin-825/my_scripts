#!/bin/bash

set -u

img_name=""
container_name=""
create_container_cmd="" # Initialize globally
#default_cmd="${3:-/bin/bash}"

setup_env(){
  img_name=$1
  container_name=$2
  
  if [ -z "$container_name" ]; then
      echo ">>> [ERROR] Missing container name" >&2
      exit 1  # FIX 1: Stop execution
  fi
  if [ -z "$img_name" ]; then
      echo ">>> [ERROR] Missing image name" >&2
      exit 1  # FIX 1: Stop execution
  fi

  ContainerUSER=$(docker inspect -f '{{.Config.User}}' "$img_name" 2>/dev/null)
  
  # FIX 2: Fallback if the image does not define a user
  if [ -z "$ContainerUSER" ]; then
      echo ">>> [WARN] No user found in image. Defaulting to 'root'."
      ContainerUSER="root"
  else
      echo ">>> [INFO] Default user in image: $ContainerUSER"
  fi

  # 1. Remove everything up to the last slash (namespace)
  # ${var##*/} removes the longest prefix matching */
  local name="${img_name##*/}"
  
  # 2. Remove everything after the first colon (tag)
  # ${var%%:*} removes the longest suffix matching :*
  name="${name%%:*}"
  host_name_for_container="${name}__${container_name}"
  echo "host_name_for_container: $host_name_for_container"

  img_name_path="${img_name//:/_}"

  mkdir -p ~/Containers
  curdir="$(pwd -P)"
  host_dir_for_container=~/Containers/$img_name_path

  mkdir -p "$host_dir_for_container"

  # Source external variables
  #  $dockerVolumes define in .bash_aliases_1
  if [ -f ~/.bash_aliases_1 ]; then
      source ~/.bash_aliases_1
  fi

  # Safely create the .bash_history file
  touch "${host_dir_for_container}/.bash_history"
  touch "${host_dir_for_container}/.zsh_history"


  # FIX 4: Use ${dockerVolumes:-} to prevent set -u crashes if the variable is missing
  create_container_cmd="docker run -it --name $container_name    \
  --hostname "$host_name_for_container"     \
  -v /home/$USER:/workdir    \
  -v $host_dir_for_container/.bash_history:/home/$ContainerUSER/.bash_history     \
  -v $host_dir_for_container:/.history_dir      \
  -v /home/$USER/.ssh:/home/$ContainerUSER/.ssh     \
  -v /:/hst_root     \
  -v /home/$USER/.ssh/agent/sock:/ssh-agent     \
  -e SSH_AUTH_SOCK=/ssh-agent     \
  ${dockerVolumes:-}     \
  -P $img_name"
}

create_container(){
  echo "xxxxxxxxxxxxxxx"
  echo "Command to create and run container:"
  echo "$create_container_cmd" | sed -r 's/[[:space:]]{4,}/    \n  /g'
  echo "xxxxxxxxxxxxxxx"

  eval "$create_container_cmd"
  
  # Check exit status
  if [ $? -ne 0 ]; then
    echo "❌ Container failed to start."
    read -p "Do you want to delete and re-create it? [y/N]: " choice
    case "$choice" in
      y|Y )
        echo "🧨 Removing existing container (if any)..."
        docker rm -f "$container_name" 2>/dev/null
        echo "🔄 Recreating container..."
        eval "$create_container_cmd"  # FIX 3: Use eval here too
        ;;
      * )
        echo "🚪 Exit without re-creating container."
        exit 1
        ;;
    esac
  else
    echo "✅ Container started successfully."
  fi
}

main(){
  # Ensure we received at least two arguments before passing them
  if [ $# -lt 2 ]; then
      echo "Usage: $0 <image_name> <container_name>"
      exit 1
  fi

  setup_env "$1" "$2"
  create_container
}

main "$@"