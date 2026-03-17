#!/bin/sh
# ============================================================================
#  run.sh — Sundy.Host VPS | Interactive shell
# ============================================================================

. /common.sh

HOSTNAME="Sundy"
HISTORY_FILE="${HOME}/.shell_history"
MAX_HISTORY=500

if [ ! -e "/.installed" ]; then
    rm -f "/rootfs.tar.xz" "/rootfs.tar.gz"
    rm -rf /tmp/sbin
    printf 'nameserver 1.1.1.1\nnameserver 1.0.0.1\n' > /etc/resolv.conf
    touch "/.installed"
fi

[ ! -e "/autorun.sh" ] && touch /autorun.sh && chmod +x /autorun.sh

# ── Signal handling ────────────────────────────────────────────────────────
# Trap SIGINT (Ctrl+C / Panel Stop Button) so the shell doesn't exit,
# but child processes in foreground WILL get killed automatically.
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

# ── Status (Neofetch Style) ────────────────────────────────────────────────
show_status() {
    P ""
    
    # Gather Data
    OS_NAME="Linux"
    [ -f /etc/os-release ] && . /etc/os-release && OS_NAME="$PRETTY_NAME"
    
    KERNEL=$(uname -r)
    ARCH=$(uname -m)
    
    # Uptime
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
    
    # RAM
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
    
    # Disk
    DISK_STR="N/A"
    disk_info=$(df -h / 2>/dev/null | tail -1)
    if [ -n "$disk_info" ]; then
        du_val=$(printf '%s' "$disk_info" | awk '{print $3}')
        dt_val=$(printf '%s' "$disk_info" | awk '{print $2}')
        dp=$(printf '%s' "$disk_info" | awk '{print $5}')
        DISK_STR="${du_val} / ${dt_val} (${dp})"
    fi
    
    # Procs
    proc_cnt=$(ls -d /proc/[0-9]* 2>/dev/null | wc -l)

    # Print Neofetch-style layout
    P "  ${ORANGE}███████╗${NC}   ${WHITE}${BOLD}root${NC}@${LIGHT_ORANGE}${HOSTNAME}${NC}"
    P "  ${ORANGE}██╔════╝${NC}   -------------------"
    P "  ${ORANGE}███████╗${NC}   ${AMBER}OS:${NC}       ${OS_NAME}"
    P "  ${ORANGE}╚════██║${NC}   ${AMBER}Kernel:${NC}   ${KERNEL}"
    P "  ${ORANGE}███████║${NC}   ${AMBER}Uptime:${NC}   ${UPTIME_STR}"
    P "  ${ORANGE}╚══════╝${NC}   ${AMBER}Arch:${NC}     ${ARCH}"
    P "             ${AMBER}RAM:${NC}      ${RAM_STR}"
    P "             ${AMBER}Disk:${NC}     ${DISK_STR}"
    P "             ${AMBER}Procs:${NC}    ${proc_cnt} running"
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

    config_file="$HOME/vps.config"
    port_found=0
    if [ -f "$config_file" ]; then
        while IFS='=' read -r key value; do
            key=$(printf '%s' "$key" | tr -d '[:space:]')
            value=$(printf '%s' "$value" | tr -d '[:space:]')
            case "$key" in ""|"#"*) continue ;; esac
            case "$key" in
                internalip)
                    P "${ORANGE}║  ${AMBER}Internal IP:${NC} $value$(printf '%*s' $((46 - ${#value})) '') ${ORANGE}║${NC}"
                ;;
                port|port[0-9]*)
                    if [ -n "$value" ]; then
                        P "${ORANGE}║     ${GREEN}+${NC} Allocated Port = ${BOLD}${value}${NC}$(printf '%*s' $((39 - ${#value})) '') ${ORANGE}║${NC}"
                        port_found=1
                    fi
                ;;
            esac
        done < "$config_file"
    fi

    if [ "$port_found" -eq 0 ]; then
        P "${ORANGE}║  ${DIM}No additional ports. Add them in the Panel Startup tab.${NC}${ORANGE}       ║${NC}"
    fi

    P "${ORANGE}║                                                                ║${NC}"
    P "${ORANGE}╚════════════════════════════════════════════════════════════════╝${NC}"
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

# ── Interactive program wrappers ───────────────────────────────────────────
wrap_interactive() {
    prog="$1"
    case "$prog" in
        top|htop|btop|nload|iftop|bmon|nethogs|glances)
            P ""
            P "${RED}Error: ${prog} is not supported in the Pterodactyl console.${NC}"
            P "Console applications requiring full terminal control will freeze."
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
        history)
            if [ -f "$HISTORY_FILE" ]; then
                P "\n${AMBER}Recent commands:${NC}"
                tail -20 "$HISTORY_FILE" | nl -ba
                P ""
            fi
        ;;
        top|htop|btop|nload|iftop|bmon|nethogs|glances)
            wrap_interactive "$prog"
        ;;
        *)
            # Run normally in foreground. 
            # This fixes `apt install` prompts reading stdin!
            # If user wants to stop, Pterodactyl Stop button sends SIGINT (^C)
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
