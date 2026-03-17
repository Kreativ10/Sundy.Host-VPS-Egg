#!/bin/sh
# ============================================================================
#  entrypoint.sh — Sundy.Host VPS | Container entrypoint
#  Runs as ROOT to apply firewall, then launches PRoot as container user
# ============================================================================

sleep 2

cd /home/container

# Make internal IP available
export INTERNAL_IP=$(ip route get 1 2>/dev/null | awk '{print $(NF-2); exit}')

# Parse startup command
MODIFIED_STARTUP=$(eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g'))

# First boot: install OS
if [ ! -e "/home/container/.installed" ]; then
    /usr/local/bin/proot \
        --rootfs="/" \
        -0 -w "/root" \
        -b /dev -b /sys -b /proc \
        --kill-on-exit \
        /bin/sh "/install.sh" || exit 1
fi

# Normal boot: apply firewall (as root!) then run VPS
sh /helper.sh
