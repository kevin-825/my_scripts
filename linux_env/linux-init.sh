#!/usr/bin/env bash
set -euo pipefail

sudo apt update && sudo apt install \
pigz \
vim \
gcc \
make \
util-linux-extra \
python-is-python3 \
openssh-server \
apache2 \
clang-format \
jq \
git git-core git-gui gitweb cgit gitk git-daemon-run git-cvs git-svn gettext -y


#clang-format usage:
#clang-format -style=Linux -dump-config > .clang-format 

sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && sudo chmod +x /usr/bin/yq


GIT_USER_NAME="Kevin Aimaier"
GIT_USER_EMAIL="kflyn825@outlook.com"
GIT_DEFAULT_EDITOR="vim"

SSH_KEY_TYPE="rsa"
SSH_KEY_BITS="4096"
SSH_KEY_COMMENT="$GIT_USER_EMAIL"
SSH_KEY_PATH="$HOME/.ssh/id_rsa"


mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"


if [[ -f "$SSH_KEY_PATH" ]]; then
    echo "[SSH] Key already exists at $SSH_KEY_PATH — skipping generation"
else
    echo "[SSH] Generating new SSH key..."
    ssh-keygen -t "$SSH_KEY_TYPE" -b "$SSH_KEY_BITS" -C "$SSH_KEY_COMMENT" -f "$SSH_KEY_PATH" -N ""
    echo "[SSH] Key generated."
fi


echo "[SSH] Starting ssh-agent..."
eval "$(ssh-agent -s)"

echo "[SSH] Adding key to agent..."
ssh-add "$SSH_KEY_PATH"

###############################################
# ADD GITHUB + GITLAB HOST KEYS
###############################################

KNOWN_HOSTS="$HOME/.ssh/known_hosts"

touch "$KNOWN_HOSTS"
chmod 600 "$KNOWN_HOSTS"

echo "[SSH] Adding GitHub host key..."
ssh-keyscan github.com >> "$KNOWN_HOSTS" 2>/dev/null || true

echo "[SSH] Adding GitLab host key..."
ssh-keyscan gitlab.com >> "$KNOWN_HOSTS" 2>/dev/null || true

###############################################
# CONFIGURE GIT
###############################################

echo "[GIT] Configuring Git..."

git config --global user.name  "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"
git config --global core.editor "$GIT_DEFAULT_EDITOR"
#git config user.name "Another Genius"
#git config user.email "a_genius@linux.com"

# Optional: enable useful defaults
git config --global pull.rebase false
git config --global init.defaultBranch main

###############################################
# PRINT PUBLIC KEY FOR USER TO COPY
###############################################

echo
echo "========================================"
echo " Your SSH Public Key (add to GitHub/GitLab)"
echo "========================================"
cat "${SSH_KEY_PATH}.pub"
echo

echo "========================================"
echo " Initialization Complete"
echo "========================================"



# Configures Git to cache HTTPS credentials (like a GitHub PAT)
enable_git_credential_cache() {
    # Default timeout is 3600 seconds (1 hour) if no argument is passed
    local timeout_seconds="${1:-3600}" 
    
    echo "Configuring global Git credential cache for ${timeout_seconds} seconds..."
    git config --global credential.helper "cache --timeout=${timeout_seconds}"
    
    local current_helper
    current_helper=$(git config --global credential.helper)
    
    if [[ -n "$current_helper" ]]; then
        echo "Success: Credential helper set to '${current_helper}'"
    else
        echo "Error: Failed to set credential helper."
        return 1
    fi
}

# Execute (Caching for 86400 seconds = 24 hours)
enable_git_credential_cache 86400

ln -s /mnt/wsl/disk1 d1
ln -s /mnt/wsl/disk2 d2
ln -s /mnt/wsl/ramdisk5 rd5
ln -s /mnt/wsl/vhd0 vhd0
ln -s /mnt/wsl/vhd1 vhd1
