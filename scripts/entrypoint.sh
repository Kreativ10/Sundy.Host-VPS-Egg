#!/bin/sh
# ============================================================================
#  entrypoint.sh — Container entrypoint (first boot → install, else → run)
# ============================================================================

# Wait for container to be ready
sleep 2

cd /home/container

# Make internal Docker IP available
export INTERNAL_IP=$(ip route get 1 2>/dev/null | awk '{print $(NF-2); exit}')

# Parse startup command (replace {{VAR}} → ${VAR})
MODIFIED_STARTUP=$(eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g'))

# First boot: run installer via PRoot
if [ ! -e "$HOME/.installed" ]; then
    /usr/local/bin/proot \
    --rootfs="/" \
    -0 -w "/root" \
    -b /dev -b /sys -b /proc \
    --kill-on-exit \
    /bin/sh "/install.sh" || exit 1
fi

# Normal boot: run helper (which launches PRoot → run.sh)
sh /helper.sh
