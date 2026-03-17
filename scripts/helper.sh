#!/bin/sh
# ============================================================================
#  helper.sh — Port parsing + PRoot execution
# ============================================================================

# Ensure scripts exist in container home
ensure_run_script_exists() {
    if [ ! -f "$HOME/common.sh" ]; then
        cp /common.sh "$HOME/common.sh"
        chmod +x "$HOME/common.sh"
    fi

    if [ ! -f "$HOME/run.sh" ]; then
        cp /run.sh "$HOME/run.sh"
        chmod +x "$HOME/run.sh"
    fi

    if [ ! -f "$HOME/firewall.sh" ]; then
        cp /firewall.sh "$HOME/firewall.sh"
        chmod +x "$HOME/firewall.sh"
    fi
}

# ── Parse port configuration from vps.config ───────────────────────────────
parse_ports() {
    config_file="$HOME/vps.config"
    port_args=""

    if [ ! -f "$config_file" ]; then
        return
    fi

    while IFS='=' read -r key value; do
        case "$key" in
            ""|"#"*)
                continue
            ;;
        esac

        key=$(echo "$key" | tr -d '[:space:]')
        value=$(echo "$value" | tr -d '[:space:]')

        # Skip internalip
        [ "$key" = "internalip" ] && continue

        # Match port pattern and validate
        case "$key" in
            port|port[0-9]*)
                if [ -n "$value" ]; then
                    case "$value" in
                        *[!0-9]*)
                            # Not a number, skip
                        ;;
                        *)
                            if [ "$value" -ge 1 ] && [ "$value" -le 65535 ]; then
                                port_args="$port_args -p $value:$value"
                            fi
                        ;;
                    esac
                fi
            ;;
        esac
    done < "$config_file"

    echo "$port_args"
}

# ── Execute PRoot environment ──────────────────────────────────────────────
exec_proot() {
    port_args=$(parse_ports)

    /usr/local/bin/proot \
    --rootfs="${HOME}" \
    -0 -w "${HOME}" \
    -b /dev -b /sys -b /proc \
    $port_args \
    --kill-on-exit \
    /bin/sh "/run.sh"
}

# ── Main ───────────────────────────────────────────────────────────────────
ensure_run_script_exists
exec_proot
