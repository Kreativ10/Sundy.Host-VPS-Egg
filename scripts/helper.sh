#!/bin/sh
# ============================================================================
#  helper.sh — Sundy.Host VPS | Port parsing + PRoot launcher
#  Firewall is applied HERE (at container level, before PRoot)
# ============================================================================

# Source firewall (runs at container level where iptables CAN work)
. /common.sh
. /firewall.sh

# Ensure scripts exist
ensure_scripts() {
    for f in common.sh run.sh firewall.sh; do
        if [ ! -f "$HOME/$f" ]; then
            cp "/$f" "$HOME/$f"
            chmod +x "$HOME/$f"
        fi
    done
}

# Parse ports from vps.config
parse_ports() {
    config_file="$HOME/vps.config"
    port_args=""

    [ ! -f "$config_file" ] && return

    while IFS='=' read -r key value; do
        case "$key" in ""|"#"*) continue ;; esac

        key=$(echo "$key" | tr -d '[:space:]')
        value=$(echo "$value" | tr -d '[:space:]')

        [ "$key" = "internalip" ] && continue

        case "$key" in
            port|port[0-9]*)
                if [ -n "$value" ]; then
                    case "$value" in
                        *[!0-9]*) ;;
                        *) [ "$value" -ge 1 ] && [ "$value" -le 65535 ] && \
                           port_args="$port_args -p $value:$value" ;;
                    esac
                fi
            ;;
        esac
    done < "$config_file"

    echo "$port_args"
}

# Apply firewall at container level (before PRoot)
apply_firewall

# Launch PRoot
ensure_scripts
port_args=$(parse_ports)

exec /usr/local/bin/proot \
    --rootfs="${HOME}" \
    -0 -w "${HOME}" \
    -b /dev -b /sys -b /proc \
    $port_args \
    --kill-on-exit \
    /bin/sh "/run.sh"
