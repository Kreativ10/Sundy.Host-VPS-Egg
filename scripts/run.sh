#!/bin/sh
# ============================================================================
#  run.sh — Sundy.Host VPS | Interactive shell
#  Commands run in FOREGROUND so interactive tools (apt, etc) work.
#  Use Ctrl+C or panel Stop button to interrupt running commands.
# ============================================================================

. /common.sh

HOSTNAME="Sundy.Host"
HISTORY_FILE="${HOME}/.shell_history"
MAX_HISTORY=500

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
    P ""
    log "INFO" "Sundy.Host VPS session ended." "$ORANGE"
    exit 0
}

trap cleanup TERM

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

# ── Neofetch-style status ─────────────────────────────────────────────────
show_status() {
    # Gather info
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        os_name="$PRETTY_NAME"
    else
        os_name=$(uname -o 2>/dev/null || printf 'Linux')
    fi

    kernel=$(uname -r 2>/dev/null)
    arch=$(uname -m 2>/dev/null)
    hostname_val=$(hostname 2>/dev/null || printf 'Sundy.Host')
    shell_val=$(basename "$SHELL" 2>/dev/null || printf 'sh')

    # Uptime
    uptime_str="N/A"
    if [ -f /proc/uptime ]; then
        raw=$(cut -d. -f1 /proc/uptime 2>/dev/null)
        if [ -n "$raw" ]; then
            d=$((raw / 86400))
            h=$(( (raw % 86400) / 3600 ))
            m=$(( (raw % 3600) / 60 ))
            if [ "$d" -gt 0 ]; then
                uptime_str="${d}d ${h}h ${m}m"
            elif [ "$h" -gt 0 ]; then
                uptime_str="${h}h ${m}m"
            else
                uptime_str="${m}m"
            fi
        fi
    fi

    # Memory
    mem_str="N/A"
    mem_bar=""
    if [ -f /proc/meminfo ]; then
        mt=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        ma=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        if [ -n "$mt" ] && [ -n "$ma" ] && [ "$mt" -gt 0 ]; then
            mu=$((mt - ma))
            mt_mb=$((mt / 1024))
            mu_mb=$((mu / 1024))
            mp=$((mu * 100 / mt))
            mem_str="${mu_mb}MB / ${mt_mb}MB (${mp}%)"
            fl=$((mp / 5)); el=$((20 - fl))
            bar=""; i=0; while [ $i -lt $fl ]; do bar="${bar}#"; i=$((i+1)); done
            i=0; while [ $i -lt $el ]; do bar="${bar}-"; i=$((i+1)); done
            mem_bar="[${bar}]"
        fi
    fi

    # Disk
    disk_str="N/A"
    disk_bar=""
    disk_info=$(df -h / 2>/dev/null | tail -1)
    if [ -n "$disk_info" ]; then
        du_val=$(printf '%s' "$disk_info" | awk '{print $3}')
        dt_val=$(printf '%s' "$disk_info" | awk '{print $2}')
        dp_val=$(printf '%s' "$disk_info" | awk '{print $5}' | tr -d '%')
        disk_str="${du_val} / ${dt_val} (${dp_val}%)"
        fl=$((dp_val / 5)); el=$((20 - fl))
        bar=""; i=0; while [ $i -lt $fl ]; do bar="${bar}#"; i=$((i+1)); done
        i=0; while [ $i -lt $el ]; do bar="${bar}-"; i=$((i+1)); done
        disk_bar="[${bar}]"
    fi

    # Load
    load_str="N/A"
    [ -f /proc/loadavg ] && load_str=$(cut -d' ' -f1-3 /proc/loadavg)

    # CPU
    cpu_str="N/A"
    if [ -f /proc/cpuinfo ]; then
        cpu_model=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | sed 's/^ //')
        cpu_cores=$(grep -c '^processor' /proc/cpuinfo 2>/dev/null)
        [ -n "$cpu_model" ] && cpu_str="${cpu_model} (${cpu_cores}c)"
    fi

    # Processes
    proc_count=0
    [ -d /proc ] && proc_count=$(ls -d /proc/[0-9]* 2>/dev/null | wc -l)

    # Packages (try multiple package managers)
    pkg_str=""
    if command -v dpkg >/dev/null 2>&1; then
        pkg_count=$(dpkg -l 2>/dev/null | grep -c '^ii')
        pkg_str="${pkg_count} (dpkg)"
    elif command -v apk >/dev/null 2>&1; then
        pkg_count=$(apk list --installed 2>/dev/null | wc -l)
        pkg_str="${pkg_count} (apk)"
    elif command -v rpm >/dev/null 2>&1; then
        pkg_count=$(rpm -qa 2>/dev/null | wc -l)
        pkg_str="${pkg_count} (rpm)"
    elif command -v pacman >/dev/null 2>&1; then
        pkg_count=$(pacman -Q 2>/dev/null | wc -l)
        pkg_str="${pkg_count} (pacman)"
    fi

    P ""
    P "${ORANGE}+========================================================+${NC}"
    P "${ORANGE}|                                                        |${NC}"
    P "${ORANGE}|         ${WHITE}${BOLD}SUNDY.HOST -- SYSTEM STATUS${NC}${ORANGE}                    |${NC}"
    P "${ORANGE}|                                                        |${NC}"
    P "${ORANGE}+--------------------------------------------------------+${NC}"
    P "${ORANGE}|                                                        |${NC}"
    P "${ORANGE}|  ${AMBER}${BOLD}Host${NC}        ${WHITE}${hostname_val}${NC}"
    P "${ORANGE}|  ${AMBER}${BOLD}OS${NC}          ${WHITE}${os_name}${NC}"
    P "${ORANGE}|  ${AMBER}${BOLD}Kernel${NC}      ${WHITE}${kernel}${NC}"
    P "${ORANGE}|  ${AMBER}${BOLD}Arch${NC}        ${WHITE}${arch}${NC}"
    P "${ORANGE}|  ${AMBER}${BOLD}Uptime${NC}      ${WHITE}${uptime_str}${NC}"
    P "${ORANGE}|  ${AMBER}${BOLD}Shell${NC}       ${WHITE}${shell_val}${NC}"
    [ -n "$pkg_str" ] && P "${ORANGE}|  ${AMBER}${BOLD}Packages${NC}    ${WHITE}${pkg_str}${NC}"
    P "${ORANGE}|  ${AMBER}${BOLD}CPU${NC}         ${WHITE}${cpu_str}${NC}"
    P "${ORANGE}|  ${AMBER}${BOLD}Processes${NC}   ${WHITE}${proc_count} running${NC}"
    P "${ORANGE}|  ${AMBER}${BOLD}Load${NC}        ${WHITE}${load_str}${NC}"
    P "${ORANGE}|                                                        |${NC}"
    P "${ORANGE}+--------------------------------------------------------+${NC}"
    P "${ORANGE}|                                                        |${NC}"
    P "${ORANGE}|  ${AMBER}${BOLD}Memory${NC}      ${GREEN}${mem_bar}${NC} ${mem_str}"
    P "${ORANGE}|  ${AMBER}${BOLD}Disk${NC}        ${GREEN}${disk_bar}${NC} ${disk_str}"
    P "${ORANGE}|                                                        |${NC}"
    P "${ORANGE}+========================================================+${NC}"
    P ""
}

# ── Ports ──────────────────────────────────────────────────────────────────
show_ports() {
    P ""
    P "${ORANGE}+========================================================+${NC}"
    P "${ORANGE}|                                                        |${NC}"
    P "${ORANGE}|         ${WHITE}${BOLD}SUNDY.HOST -- PORTS (30000-35000)${NC}${ORANGE}              |${NC}"
    P "${ORANGE}|                                                        |${NC}"
    P "${ORANGE}+--------------------------------------------------------+${NC}"
    P "${ORANGE}|                                                        |${NC}"

    config_file="$HOME/vps.config"
    port_found=0
    if [ -f "$config_file" ]; then
        while IFS='=' read -r key value; do
            key=$(printf '%s' "$key" | tr -d '[:space:]')
            value=$(printf '%s' "$value" | tr -d '[:space:]')
            case "$key" in ""|"#"*) continue ;; esac
            case "$key" in
                internalip)
                    P "${ORANGE}|  ${AMBER}IP${NC}     ${WHITE}${value}${NC}"
                ;;
                port|port[0-9]*)
                    if [ -n "$value" ]; then
                        # Check if port is in use
                        if command -v ss >/dev/null 2>&1; then
                            listener=$(ss -tlnp 2>/dev/null | grep ":${value} " | awk '{print $NF}' | head -1)
                        elif command -v netstat >/dev/null 2>&1; then
                            listener=$(netstat -tlnp 2>/dev/null | grep ":${value} " | awk '{print $NF}' | head -1)
                        else
                            listener=""
                        fi
                        if [ -n "$listener" ] && [ "$listener" != "-" ]; then
                            P "${ORANGE}|  ${GREEN}*${NC}  ${key} = ${WHITE}${value}${NC}  ${DIM}(${listener})${NC}"
                        else
                            P "${ORANGE}|  ${DIM}o${NC}  ${key} = ${WHITE}${value}${NC}  ${DIM}(free)${NC}"
                        fi
                        port_found=1
                    fi
                ;;
            esac
        done < "$config_file"
    fi

    if [ "$port_found" -eq 0 ]; then
        P "${ORANGE}|  ${DIM}No additional ports configured.${NC}"
        P "${ORANGE}|  ${DIM}Add ports in the Startup tab.${NC}"
    fi

    P "${ORANGE}|                                                        |${NC}"
    P "${ORANGE}+========================================================+${NC}"
    P ""
}

# ── Port check ─────────────────────────────────────────────────────────────
do_portcheck() {
    port="$1"
    if [ -z "$port" ]; then
        log "INFO" "Usage: portcheck <port>" "$AMBER"
        log "INFO" "Example: portcheck 30001" "$AMBER"
        return
    fi

    P ""
    P "${ORANGE}+--------------------------------------+${NC}"
    P "${ORANGE}|  ${WHITE}${BOLD}Port ${port} status${NC}"
    P "${ORANGE}+--------------------------------------+${NC}"

    found=0

    # TCP check
    if command -v ss >/dev/null 2>&1; then
        tcp_info=$(ss -tlnp 2>/dev/null | grep ":${port} ")
        udp_info=$(ss -ulnp 2>/dev/null | grep ":${port} ")
    elif command -v netstat >/dev/null 2>&1; then
        tcp_info=$(netstat -tlnp 2>/dev/null | grep ":${port} ")
        udp_info=$(netstat -ulnp 2>/dev/null | grep ":${port} ")
    else
        P "${ORANGE}|  ${RED}ss/netstat not available${NC}"
        P "${ORANGE}+--------------------------------------+${NC}"
        return
    fi

    if [ -n "$tcp_info" ]; then
        P "${ORANGE}|  ${GREEN}TCP LISTENING${NC}"
        printf '%s\n' "$tcp_info" | while IFS= read -r line; do
            proc=$(printf '%s' "$line" | awk '{print $NF}')
            addr=$(printf '%s' "$line" | awk '{print $4}')
            P "${ORANGE}|    ${WHITE}${addr}${NC}  ${DIM}${proc}${NC}"
        done
        found=1
    fi

    if [ -n "$udp_info" ]; then
        P "${ORANGE}|  ${GREEN}UDP LISTENING${NC}"
        printf '%s\n' "$udp_info" | while IFS= read -r line; do
            proc=$(printf '%s' "$line" | awk '{print $NF}')
            addr=$(printf '%s' "$line" | awk '{print $4}')
            P "${ORANGE}|    ${WHITE}${addr}${NC}  ${DIM}${proc}${NC}"
        done
        found=1
    fi

    if [ "$found" -eq 0 ]; then
        P "${ORANGE}|  ${DIM}Port ${port} is free (not in use)${NC}"
    fi

    P "${ORANGE}+--------------------------------------+${NC}"
    P ""
}

# ── Process list ───────────────────────────────────────────────────────────
show_procs() {
    P ""
    P "${ORANGE}+========================================================+${NC}"
    P "${ORANGE}|         ${WHITE}${BOLD}SUNDY.HOST -- PROCESSES${NC}${ORANGE}                        |${NC}"
    P "${ORANGE}+========================================================+${NC}"
    P ""
    if command -v ps >/dev/null 2>&1; then
        ps aux 2>/dev/null | head -25
    else
        ls -d /proc/[0-9]* 2>/dev/null | while read -r p; do
            pid=$(basename "$p")
            cmd=$(cat "$p/cmdline" 2>/dev/null | tr '\0' ' ')
            [ -n "$cmd" ] && P "  ${pid}  ${cmd}"
        done | head -25
    fi
    P ""
}

# ── Reinstall ──────────────────────────────────────────────────────────────
do_reinstall() {
    P ""
    P "${RED}${BOLD}WARNING: This will erase ALL data!${NC}"
    printf '%b' "${AMBER}Type 'yes' to confirm: ${NC}"
    read -r confirm
    if [ "$confirm" = "yes" ]; then
        log "INFO" "Wiping..." "$ORANGE"
        rm -f "$HOME/.installed" "/.installed"
        find "$HOME" -mindepth 1 -maxdepth 1 \
            ! -name "run.sh" ! -name "common.sh" ! -name "firewall.sh" \
            ! -name "vps.config" ! -name ".shell_history" \
            -exec rm -rf {} + 2>/dev/null
        log "SUCCESS" "Done. Restarting..." "$GREEN"
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
        log "ERROR" "Not found: ${file}" "$RED"
    fi
}

# ── Interactive program wrappers ───────────────────────────────────────────
wrap_interactive() {
    case "$1" in
        top)    top -b -n 1 2>/dev/null | head -30; return 0 ;;
        htop|btop|nload|iftop|bmon|nethogs|glances)
            log "INFO" "$1 not supported in panel console. Use 'status' or 'procs'." "$AMBER"
            return 0 ;;
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
        clear|cls)     printf '\033c' ;;
        exit)          cleanup ;;
        help)          print_help_banner ;;
        status)        show_status ;;
        ports)         show_ports ;;
        portcheck)     do_portcheck "$args" ;;
        procs)         show_procs ;;
        firewall)      . /firewall.sh; show_firewall_status ;;
        reinstall)     do_reinstall ;;
        backup)        do_backup ;;
        restore)       do_restore "$args" ;;
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
            wrap_interactive "$prog"
        ;;
        *)
            # Run in FOREGROUND so interactive tools (apt, etc) work
            eval "$cmd"
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
log "INFO" "Type 'help' for commands. Ctrl+C stops running commands." "$AMBER"

sh "/autorun.sh" 2>/dev/null

while true; do
    show_prompt
    read -r cmd || break
    execute "$cmd"
done
