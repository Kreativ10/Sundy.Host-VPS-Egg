#!/bin/sh
# ============================================================================
#  run.sh — Sundy.Host VPS | Interactive shell
# ============================================================================

. /common.sh

HOSTNAME="Sundy"
HISTORY_FILE="${HOME}/.shell_history"
MAX_HISTORY=500
CHILD_PID=""

# ── First boot setup ───────────────────────────────────────────────────────
if [ ! -e "/.installed" ]; then
    rm -f "/rootfs.tar.xz" "/rootfs.tar.gz"
    rm -rf /tmp/sbin
    printf 'nameserver 1.1.1.1\nnameserver 1.0.0.1\n' > /etc/resolv.conf
    touch "/.installed"
fi

[ ! -e "/autorun.sh" ] && touch /autorun.sh && chmod +x /autorun.sh

# ── Signal handling ────────────────────────────────────────────────────────
cleanup() {
    [ -n "$CHILD_PID" ] && kill -INT "$CHILD_PID" 2>/dev/null
    log "INFO" "Session ended. Goodbye!" "$ORANGE"
    exit 0
}

interrupt_child() {
    if [ -n "$CHILD_PID" ]; then
        kill -INT "$CHILD_PID" 2>/dev/null
        kill -TERM "$CHILD_PID" 2>/dev/null
        CHILD_PID=""
    fi
}

trap cleanup TERM
trap interrupt_child INT

# ── Prompt ─────────────────────────────────────────────────────────────────
get_dir() {
    case "$PWD" in
        "$HOME"*) printf '%s' "~${PWD#$HOME}" ;;
        *) printf '%s' "$PWD" ;;
    esac
}

show_prompt() {
    printf '\n'
    printf '%b' "${LIGHT_ORANGE}root@${HOSTNAME}${NC}:${AMBER}$(get_dir)${NC}# "
}

# ── History ────────────────────────────────────────────────────────────────
save_history() {
    [ -z "$1" ] && return
    printf '%s\n' "$1" >> "$HISTORY_FILE"
    tail -n "$MAX_HISTORY" "$HISTORY_FILE" > "$HISTORY_FILE.tmp" 2>/dev/null
    mv "$HISTORY_FILE.tmp" "$HISTORY_FILE" 2>/dev/null
}

# ── System status ──────────────────────────────────────────────────────────
show_status() {
    P ""
    P "${ORANGE}╔════════════════════════════════════════════════════════╗${NC}"
    P "${ORANGE}║                                                        ║${NC}"
    P "${ORANGE}║        ${WHITE}${BOLD}SUNDY.HOST --- SYSTEM STATUS${NC}${ORANGE}                   ║${NC}"
    P "${ORANGE}║                                                        ║${NC}"
    P "${ORANGE}╠════════════════════════════════════════════════════════╣${NC}"
    P "${ORANGE}║                                                        ║${NC}"

    # OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME="$PRETTY_NAME"
    else
        OS_NAME=$(uname -o 2>/dev/null || printf 'Linux')
    fi
    P "${ORANGE}║  ${AMBER}OS${NC}         ${OS_NAME}${NC}"

    # Arch
    P "${ORANGE}║  ${AMBER}Arch${NC}       $(uname -m)"

    # Uptime
    if [ -f /proc/uptime ]; then
        raw=$(cut -d. -f1 /proc/uptime 2>/dev/null)
        if [ -n "$raw" ]; then
            days=$((raw / 86400))
            hours=$(( (raw % 86400) / 3600 ))
            mins=$(( (raw % 3600) / 60 ))
            if [ "$days" -gt 0 ]; then
                P "${ORANGE}║  ${AMBER}Uptime${NC}     ${days}d ${hours}h ${mins}m"
            elif [ "$hours" -gt 0 ]; then
                P "${ORANGE}║  ${AMBER}Uptime${NC}     ${hours}h ${mins}m"
            else
                P "${ORANGE}║  ${AMBER}Uptime${NC}     ${mins}m"
            fi
        fi
    fi

    P "${ORANGE}║                                                        ║${NC}"
    P "${ORANGE}╠════════════════════════════════════════════════════════╣${NC}"
    P "${ORANGE}║                                                        ║${NC}"

    # Memory
    if [ -f /proc/meminfo ]; then
        mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        mem_avail=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        if [ -n "$mem_total" ] && [ -n "$mem_avail" ]; then
            mem_used=$((mem_total - mem_avail))
            mem_total_mb=$((mem_total / 1024))
            mem_used_mb=$((mem_used / 1024))
            if [ "$mem_total" -gt 0 ]; then
                mem_pct=$((mem_used * 100 / mem_total))
            else
                mem_pct=0
            fi
            bar_len=20
            filled=$((mem_pct * bar_len / 100))
            empty=$((bar_len - filled))
            bar=""
            i=0; while [ $i -lt $filled ]; do bar="${bar}#"; i=$((i+1)); done
            i=0; while [ $i -lt $empty ]; do bar="${bar}-"; i=$((i+1)); done
            P "${ORANGE}║  ${AMBER}RAM${NC}        [${GREEN}${bar}${NC}] ${mem_used_mb}/${mem_total_mb} MB (${mem_pct}%)"
        fi
    fi

    # Disk
    disk_info=$(df -h / 2>/dev/null | tail -1)
    if [ -n "$disk_info" ]; then
        disk_used=$(printf '%s' "$disk_info" | awk '{print $3}')
        disk_total=$(printf '%s' "$disk_info" | awk '{print $2}')
        disk_pct=$(printf '%s' "$disk_info" | awk '{print $5}' | tr -d '%')
        bar_len=20
        filled=$((disk_pct * bar_len / 100))
        empty=$((bar_len - filled))
        bar=""
        i=0; while [ $i -lt $filled ]; do bar="${bar}#"; i=$((i+1)); done
        i=0; while [ $i -lt $empty ]; do bar="${bar}-"; i=$((i+1)); done
        P "${ORANGE}║  ${AMBER}Disk${NC}       [${GREEN}${bar}${NC}] ${disk_used}/${disk_total} (${disk_pct}%)"
    fi

    # CPU load
    if [ -f /proc/loadavg ]; then
        load=$(cut -d' ' -f1-3 /proc/loadavg 2>/dev/null)
        P "${ORANGE}║  ${AMBER}Load${NC}       ${load}"
    fi

    # Process count
    if [ -d /proc ]; then
        proc_count=$(ls -d /proc/[0-9]* 2>/dev/null | wc -l)
        P "${ORANGE}║  ${AMBER}Procs${NC}      ${proc_count} running"
    fi

    P "${ORANGE}║                                                        ║${NC}"
    P "${ORANGE}╚════════════════════════════════════════════════════════╝${NC}"
    P ""
}

# ── Ports ──────────────────────────────────────────────────────────────────
show_ports() {
    P ""
    P "${ORANGE}╔════════════════════════════════════════════════════════╗${NC}"
    P "${ORANGE}║                                                        ║${NC}"
    P "${ORANGE}║        ${WHITE}${BOLD}SUNDY.HOST --- PORTS (30000-35000)${NC}${ORANGE}             ║${NC}"
    P "${ORANGE}║                                                        ║${NC}"
    P "${ORANGE}╠════════════════════════════════════════════════════════╣${NC}"
    P "${ORANGE}║                                                        ║${NC}"

    config_file="$HOME/vps.config"
    port_found=0
    if [ -f "$config_file" ]; then
        while IFS='=' read -r key value; do
            key=$(printf '%s' "$key" | tr -d '[:space:]')
            value=$(printf '%s' "$value" | tr -d '[:space:]')
            case "$key" in ""|"#"*) continue ;; esac
            case "$key" in
                internalip)
                    P "${ORANGE}║  ${AMBER}IP${NC}    ${value}"
                ;;
                port|port[0-9]*)
                    if [ -n "$value" ]; then
                        P "${ORANGE}║  ${GREEN}+${NC}     ${key} = ${value}"
                        port_found=1
                    fi
                ;;
            esac
        done < "$config_file"
    fi

    if [ "$port_found" -eq 0 ]; then
        P "${ORANGE}║  ${DIM}No additional ports. Add in Startup tab.${NC}${ORANGE}            ║${NC}"
    fi

    P "${ORANGE}║                                                        ║${NC}"
    P "${ORANGE}╚════════════════════════════════════════════════════════╝${NC}"
    P ""
}

# ── Reinstall ──────────────────────────────────────────────────────────────
do_reinstall() {
    P ""
    P "${RED}${BOLD}WARNING: This will erase ALL data!${NC}"
    printf '%b' "${AMBER}Confirm? (yes/no): ${NC}"
    read -r confirm
    if [ "$confirm" = "yes" ] || [ "$confirm" = "y" ]; then
        log "INFO" "Wiping data..." "$ORANGE"
        rm -f "$HOME/.installed" "/.installed"
        find "$HOME" -mindepth 1 -maxdepth 1 \
            ! -name "run.sh" ! -name "common.sh" ! -name "firewall.sh" \
            ! -name "vps.config" ! -name ".shell_history" \
            -exec rm -rf {} + 2>/dev/null
        log "SUCCESS" "Done. Restarting for OS selection..." "$GREEN"
        sleep 1
        exit 2
    else
        log "INFO" "Cancelled." "$AMBER"
    fi
}

# ── Backup/Restore ────────────────────────────────────────────────────────
do_backup() {
    backup_file="/backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    log "INFO" "Creating backup..." "$ORANGE"
    (cd / && tar --numeric-owner -czf "$backup_file" \
        --exclude="./proc" --exclude="./tmp" --exclude="./dev" \
        --exclude="./sys" --exclude="./run" --exclude="./vps.config" \
        . ) >/dev/null 2>&1
    if [ -f "$backup_file" ]; then
        size=$(du -h "$backup_file" | cut -f1)
        log "SUCCESS" "Backup: ${backup_file} (${size})" "$GREEN"
    else
        log "ERROR" "Backup failed." "$RED"
    fi
}

do_restore() {
    file="$1"
    if [ -z "$file" ]; then
        log "INFO" "Usage: restore <filename>" "$AMBER"
        ls /backup_*.tar.gz 2>/dev/null | while read -r f; do
            size=$(du -h "$f" | cut -f1)
            P "  ${ORANGE}+${NC} $(basename "$f") (${size})"
        done
        return
    fi
    if [ -f "/$file" ]; then
        log "INFO" "Restoring..." "$ORANGE"
        tar --numeric-owner -xzf "/$file" -C / --exclude="$file" >/dev/null 2>&1
        log "SUCCESS" "Restored from ${file}" "$GREEN"
    else
        log "ERROR" "File not found: ${file}" "$RED"
    fi
}

# ── Interactive program wrappers ───────────────────────────────────────────
wrap_interactive() {
    prog="$1"
    shift
    case "$prog" in
        top)
            top -b -n 1 "$@" 2>/dev/null | head -30
            return 0
        ;;
        htop|btop|nload|iftop|bmon|nethogs|glances)
            log "INFO" "${prog} is not supported in Pterodactyl console." "$AMBER"
            log "INFO" "Use 'status' for system info." "$AMBER"
            return 0
        ;;
    esac
    return 1
}

# ── Execute command ────────────────────────────────────────────────────────
execute() {
    cmd="$1"
    [ -z "$cmd" ] && return 0

    save_history "$cmd"

    prog=$(printf '%s' "$cmd" | awk '{print $1}')
    args=$(printf '%s' "$cmd" | cut -d' ' -f2- -s)

    case "$prog" in
        clear|cls)    printf '\033c' ;;
        exit)         cleanup ;;
        stop)
            interrupt_child
            log "INFO" "Stopped." "$AMBER"
        ;;
        help)         print_help_banner ;;
        status)       show_status ;;
        ports)        show_ports ;;
        firewall)     . /firewall.sh; show_firewall_status ;;
        reinstall)    do_reinstall ;;
        backup)       do_backup ;;
        restore)      do_restore "$args" ;;
        history)
            if [ -f "$HISTORY_FILE" ]; then
                P ""
                P "${AMBER}Recent commands:${NC}"
                tail -20 "$HISTORY_FILE" | nl -ba
                P ""
            fi
        ;;
        sudo|su)
            log "INFO" "Already running as root." "$AMBER"
        ;;
        top|htop|btop|nload|iftop|bmon|nethogs|glances)
            wrap_interactive "$prog" $args
        ;;
        *)
            eval "$cmd" &
            CHILD_PID=$!
            wait $CHILD_PID 2>/dev/null
            CHILD_PID=""
        ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════════════════════════

touch "$HISTORY_FILE" 2>/dev/null

printf '\033c'
P "${ORANGE}${BOLD}Starting Sundy.Host VPS...${NC}"
sleep 1
printf '\033c'

print_main_banner
log "INFO" "Type 'help' for commands." "$AMBER"

sh "/autorun.sh" 2>/dev/null

while true; do
    show_prompt
    read -r cmd || break
    execute "$cmd"
done
