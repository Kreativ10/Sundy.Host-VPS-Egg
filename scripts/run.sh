#!/bin/sh
# ============================================================================
#  run.sh — Sundy.Host VPS | Interactive shell
# ============================================================================

. /common.sh

HOSTNAME="Sundy"
HISTORY_FILE="${HOME}/.shell_history"
MAX_HISTORY=500

# ── vps.config location ───────────────────────────────────────────────────
# Inside PRoot, rootfs=/home/container, so the real /home/container/vps.config
# becomes /vps.config inside PRoot. Try both paths.
VPS_CONFIG="/vps.config"
[ ! -f "$VPS_CONFIG" ] && VPS_CONFIG="$HOME/vps.config"
[ ! -f "$VPS_CONFIG" ] && VPS_CONFIG="/home/container/vps.config"

if [ ! -e "/.installed" ]; then
    rm -f "/rootfs.tar.xz" "/rootfs.tar.gz"
    rm -rf /tmp/sbin
    printf 'nameserver 1.1.1.1\nnameserver 1.0.0.1\n' > /etc/resolv.conf
    touch "/.installed"
fi

[ ! -e "/autorun.sh" ] && touch /autorun.sh && chmod +x /autorun.sh

# ── Signal handling ────────────────────────────────────────────────────────
trap 'P "\n${AMBER}[Sundy.Host] Process interrupted.${NC}"' INT
trap 'log "INFO" "Session ended. Goodbye!" "$ORANGE"; exit 0' TERM

# ── Prompt ─────────────────────────────────────────────────────────────────
get_dir() {
    case "$PWD" in
        "$HOME"*) printf '%s' "~${PWD#$HOME}" ;;
        *) printf '%s' "$PWD" ;;
    esac
}

show_prompt() {
    printf '%b' "\n${LIGHT_ORANGE}root@${HOSTNAME}${NC}:${PEACH}$(get_dir)${NC}# "
}

# ── History ────────────────────────────────────────────────────────────────
save_history() {
    [ -z "$1" ] && return
    printf '%s\n' "$1" >> "$HISTORY_FILE"
    tail -n "$MAX_HISTORY" "$HISTORY_FILE" > "$HISTORY_FILE.tmp" 2>/dev/null
    mv "$HISTORY_FILE.tmp" "$HISTORY_FILE" 2>/dev/null
}

# ── Parse vps.config ports ─────────────────────────────────────────────────
get_config_ports() {
    _ports=""
    [ ! -f "$VPS_CONFIG" ] && return
    while IFS='=' read -r key value; do
        key=$(printf '%s' "$key" | tr -d '[:space:]' | tr 'A-Z' 'a-z')
        value=$(printf '%s' "$value" | tr -d '[:space:]')
        case "$key" in ""|"#"*) continue ;; esac
        case "$key" in
            *port*)
                [ -n "$value" ] && _ports="$_ports $value"
            ;;
        esac
    done < "$VPS_CONFIG"
    printf '%s' "$_ports" | tr ' ' '\n' | sort -un | tr '\n' ' ' | sed 's/^ //;s/ $//'
}

# ── Status (Neofetch Style) ────────────────────────────────────────────────
show_status() {
    P ""

    OS_NAME="Linux"
    [ -f /etc/os-release ] && . /etc/os-release && OS_NAME="$PRETTY_NAME"

    KERNEL=$(uname -r)
    ARCH=$(uname -m)

    UPTIME_STR="N/A"
    if [ -f /proc/uptime ]; then
        raw=$(cut -d. -f1 /proc/uptime 2>/dev/null)
        if [ -n "$raw" ]; then
            days=$((raw / 86400))
            hours=$(( (raw % 86400) / 3600 ))
            mins=$(( (raw % 3600) / 60 ))
            [ "$days" -gt 0 ] && UPTIME_STR="${days} days, ${hours} hours, ${mins} mins" \
            || { [ "$hours" -gt 0 ] && UPTIME_STR="${hours} hours, ${mins} mins" || UPTIME_STR="${mins} mins"; }
        fi
    fi

    RAM_STR="N/A"
    if [ -f /proc/meminfo ]; then
        mt=$(grep -m1 MemTotal /proc/meminfo | awk '{print $2}')
        ma=$(grep -m1 MemAvailable /proc/meminfo | awk '{print $2}')
        if [ -n "$mt" ] && [ -n "$ma" ]; then
            mu=$((mt - ma))
            mt_mb=$((mt / 1024))
            mu_mb=$((mu / 1024))
            [ "$mt" -gt 0 ] && pct=$((mu * 100 / mt)) || pct=0
            RAM_STR="${mu_mb}MiB / ${mt_mb}MiB (${pct}%)"
        fi
    fi

    DISK_STR="N/A"
    disk_info=$(df -h / 2>/dev/null | tail -1)
    if [ -n "$disk_info" ]; then
        du_val=$(printf '%s' "$disk_info" | awk '{print $3}')
        dt_val=$(printf '%s' "$disk_info" | awk '{print $2}')
        dp=$(printf '%s' "$disk_info" | awk '{print $5}')
        DISK_STR="${du_val} / ${dt_val} (${dp})"
    fi

    proc_cnt=$(ls -d /proc/[0-9]* 2>/dev/null | wc -l)

    P "  ${ORANGE}███████╗${NC}   ${WHITE}${BOLD}root${NC}@${LIGHT_ORANGE}${HOSTNAME}${NC}"
    P "  ${ORANGE}██╔════╝${NC}   -------------------"
    P "  ${ORANGE}███████╗${NC}   ${AMBER}OS:${NC}       ${OS_NAME}"
    P "  ${ORANGE}╚════██║${NC}   ${AMBER}Kernel:${NC}   ${KERNEL}"
    P "  ${ORANGE}███████║${NC}   ${AMBER}Uptime:${NC}   ${UPTIME_STR}"
    P "  ${ORANGE}╚══════╝${NC}   ${AMBER}Arch:${NC}     ${ARCH}"
    P "             ${AMBER}RAM:${NC}      ${RAM_STR}"
    P "             ${AMBER}Disk:${NC}     ${DISK_STR}"
    P "             ${AMBER}Procs:${NC}    ${proc_cnt} running"
    P "             ${AMBER}IP:${NC}       ${PUBLIC_IP:-N/A}"
    P ""
}

# ── Ports & Network ────────────────────────────────────────────────────────
show_ports() {
    P ""
    P "${ORANGE}╔════════════════════════════════════════════════════════════════╗${NC}"
    P "${ORANGE}║                                                                ║${NC}"
    P "${ORANGE}║           ${WHITE}${BOLD}SUNDY.HOST --- PORTS (30000-35000)${NC}${ORANGE}                   ║${NC}"
    P "${ORANGE}║                                                                ║${NC}"
    P "${ORANGE}╠════════════════════════════════════════════════════════════════╣${NC}"
    P "${ORANGE}║                                                                ║${NC}"

    P "${ORANGE}║  ${AMBER}Public IP:${NC} ${PUBLIC_IP:-N/A}"
    P "${ORANGE}║${NC}"

    found_ports=$(get_config_ports)
    if [ -n "$found_ports" ]; then
        for p in $found_ports; do
            P "${ORANGE}║     ${GREEN}+${NC} Port ${BOLD}${p}${NC}"
        done
    else
        P "${ORANGE}║  ${DIM}No ports detected. Check vps.config or Panel > Startup tab.${NC}"
    fi

    P "${ORANGE}║                                                                ║${NC}"
    P "${ORANGE}╚════════════════════════════════════════════════════════════════╝${NC}"
    P ""

    P "${DIM}Config file: ${VPS_CONFIG}${NC}"
    if [ -f "$VPS_CONFIG" ]; then
        P "${DIM}Contents:${NC}"
        cat "$VPS_CONFIG"
    else
        P "${RED}File not found!${NC}"
    fi
    P ""
}

# ── System utilities ───────────────────────────────────────────────────────
do_procs() {
    P ""
    P "${ORANGE}=== Sundy.Host | Running Processes ===${NC}"
    if command -v ps >/dev/null; then
        ps aux
    else
        P "${RED}Command 'ps' not found.${NC}"
    fi
    P ""
}

do_portcheck() {
    P ""
    P "${ORANGE}=== Sundy.Host | Listening Ports ===${NC}"
    if command -v ss >/dev/null; then
        ss -tulnp
    elif command -v netstat >/dev/null; then
        netstat -tulnp
    else
        P "${RED}netstat or ss not found. Try 'apt install iproute2 net-tools'${NC}"
    fi
    P ""
}


# ── Reinstall ──────────────────────────────────────────────────────────────
do_reinstall() {
    P ""
    P "${RED}${BOLD}WARNING: This will erase ALL data!${NC}"
    P "${AMBER}Confirm? Type 'yes' to continue:${NC}"
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
    case "$prog" in
        top|htop|btop|nload|iftop|bmon|nethogs|glances)
            P ""
            P "${RED}Error: ${prog} is not supported in the Pterodactyl console.${NC}"
            P "Use ${AMBER}status${NC}, ${AMBER}procs${NC}, or ${AMBER}portcheck${NC} instead."
            P ""
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
        exit)         log "INFO" "Session ended. Goodbye!" "$ORANGE"; exit 0 ;;
        help)         print_help_banner ;;
        status)       show_status ;;
        ports)        show_ports ;;
        procs)        do_procs ;;
        portcheck)    do_portcheck ;;
        firewall)     . /firewall.sh; show_firewall_status ;;
        reinstall)    do_reinstall ;;
        backup)       do_backup ;;
        restore)      do_restore "$args" ;;
        history)
            if [ -f "$HISTORY_FILE" ]; then
                P "\n${AMBER}Recent commands:${NC}"
                tail -20 "$HISTORY_FILE" | nl -ba
                P ""
            fi
        ;;
        sudo|su)
            log "INFO" "Already running as root." "$AMBER"
        ;;
        top|htop|btop|nload|iftop|bmon|nethogs|glances)
            wrap_interactive "$prog"
        ;;
        *)
            eval "$cmd"
        ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════

printf '\033c'
P "${ORANGE}${BOLD}Starting Sundy.Host VPS...${NC}"
sleep 1
printf '\033c'

print_main_banner
log "INFO" "Type 'help' for commands." "$AMBER"

sh "/autorun.sh" 2>/dev/null

while true; do
    show_prompt
    if read -r cmd; then
        execute "$cmd"
    fi
done
