# Quick SSH agent start function
start_ssh() {
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519 2>/dev/null
    ssh-add ~/.ssh/id_rsa 2>/dev/null
    ssh-add -l
}

# Start ssh-agent only if not already running
if ! pgrep -u "$USER" ssh-agent >/dev/null; then
    eval "$(ssh-agent -s)" >/dev/null
    ssh-add ~/.ssh/id_ed25519 >/dev/null 2>&1
fi

# Ensure stable symlink for Docker/devcontainers
if [ -n "$SSH_AUTH_SOCK" ]; then
    mkdir -p ~/.ssh/agent
    ln -sf "$SSH_AUTH_SOCK" ~/.ssh/agent/sock
fi


if [ -f ~/.bash_aliases_1 ]; then
    sed -i 's/\r$//' ~/.bash_aliases_1
    . ~/.bash_aliases_1
fi

if [ -f ~/.bash_aliases_2 ]; then
    . ~/.bash_aliases_2
fi

# --- WSL2 Proxy Environment (safe, no sudo) ---
# Always update gateway
export WIN_GATEWAY=$(ip route | awk '/default/ {print $3}')
export PROXY_PORT=10808
# Load proxy operations (on/off/auto/status)
if [ -f "$HOME/.wsl-proxy-env" ]; then
    source "$HOME/.wsl-proxy-env"
fi

#if [ -f /home/kflyn/vhd0/opt/path_config.sh ]; then
#    . /home/kflyn/vhd0/opt/path_config.sh
#fi


alias cd2rvdemo0='cd /mnt/wsl/disk2/OffRepos/FreeRTOS/FreeRTOS/Demo/RISC-V_RV32_QEMU_VIRT_GCC'
alias cd2k825Repos='cd /mnt/wsl/disk2/k825Repos'
alias cd2qemu-riscv-sdk='cd /mnt/wsl/disk2/k825Repos/qemu-riscv-sdk'
alias cd2MyProjects='cd /mnt/wsl/disk2/k825Repos/MyProjects'

alias chowndir="sudo chown -R kflyn:kflyn "

# Runs GDB using the rvdev image
alias riscv64-unknown-elf-gdb='docker run --rm -it \
    -v /mnt/wsl:/mnt/wsl \
    -v $(pwd):$(pwd) \
    -w $(pwd) \
    kflyn825/rvdev:latest riscv64-unknown-elf-gdb'



export PATH="$PATH\
:/mnt/wsl/vhd0/opt/riscv/rv_gnu_toolchain_relocated/bin\
:/mnt/wsl/vhd1/opt/riscv/rv_gnu_toolchain_newlib_std/bin\
:/home/kflyn/my_scripts\
:/home/kflyn/my_scripts/linux_env\
:/home/kflyn/my_scripts/docker\
"





# Remove duplicate entries in PATH, this must be at the end of the file 
# to ensure all PATH modifications are included
export PATH=$(echo -n $PATH | tr ':' '\n' | awk '!x[$0]++' | paste -sd ":" -)

ramdisk_owner=$(stat -c '%U' /mnt/wsl/ramdisk5/) 
if [ "$ramdisk_owner" != "$USER" ]; then
    echo "Changing ownership of /mnt/wsl/ramdisk5/ to $USER"
    sudo chown -R "$USER":"$USER" /mnt/wsl/ramdisk5/
fi



alias wrk="cd /mnt/wsl/ramdisk5/ && git clone git@github.com:kevin-825/QemuEmbeddedLinux.git \
&& cd QemuEmbeddedLinux && git submodule update --init --recursive && git submodule update --init --recursive \
&& mkdir /mnt/wsl/ramdisk5/linux && cd /mnt/wsl/disk2/OffRepos/linux && git archive HEAD | tar -x -C '/mnt/wsl/ramdisk5/linux' \
&& cd /mnt/wsl/ramdisk5/QemuEmbeddedLinux && ./restore_backup.sh -ra "
alias wrkl="mkdir /mnt/wsl/ramdisk5/linux && cd /mnt/wsl/disk2/OffRepos/linux && git archive HEAD | tar -x -C '/mnt/wsl/ramdisk5/linux'"
alias cd2wrk='cd /mnt/wsl/ramdisk5/QemuEmbeddedLinux'


# --- Build Environment Paths ---
export RD_OUT="/mnt/wsl/ramdisk5/out"
export BKP_OUT="/mnt/wsl/disk2/.br2_output"

# --- Modular Sync Functions ---

# Function to backup RAM -> Local
rd-backup() {
    if [ -d "$RD_OUT" ]; then
        echo "Mirroring $RD_OUT to $BKP_OUT..."
        rsync -ah --delete "$RD_OUT/" "$BKP_OUT/"
        echo "Done backing up $RD_OUT ==> $BKP_OUT."
    else
        echo "Error: Source directory $RD_OUT not found."
    fi
}

# Function to restore Local -> RAM
rd-restore() {
    if [ -d "$BKP_OUT" ]; then
        # Ensure the ramdisk folder exists before copying
        mkdir -p "$RD_OUT"
        echo "Restoring $BKP_OUT to $RD_OUT..."
        rsync -ah "$BKP_OUT/" "$RD_OUT/"
        echo "Done restoring $BKP_OUT ==> $RD_OUT."
    else
        echo "Error: Backup directory $BKP_OUT not found."
    fi
}

if [[ -f /mnt/wsl/ramdisk5/QemuEmbeddedLinux/setup_alias.sh ]]; then
    . /mnt/wsl/ramdisk5/QemuEmbeddedLinux/setup_alias.sh
fi
