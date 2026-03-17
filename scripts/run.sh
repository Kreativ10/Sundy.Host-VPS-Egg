#!/bin/sh
# ============================================================================
#  run.sh — Sundy.Host VPS | Interactive shell with custom commands
# ============================================================================

# Source common functions
. /common.sh

# Source firewall functions
. /firewall.sh

# ── Configuration ───────────────────────────────────────────────────────────
HOSTNAME="Sundy"
HISTORY_FILE="${HOME}/.shell_history"
MAX_HISTORY=1000

# ── First boot cleanup ─────────────────────────────────────────────────────
if [ ! -e "/.installed" ]; then
    rm -f "/rootfs.tar.xz" "/rootfs.tar.gz"
    rm -rf /tmp/sbin

    # DNS resolvers
    printf "nameserver 1.1.1.1\nnameserver 1.0.0.1\n" > /etc/resolv.conf

    touch "/.installed"
fi

# ── Autorun script ──────────────────────────────────────────────────────────
if [ ! -e "/autorun.sh" ]; then
    touch /autorun.sh
    chmod +x /autorun.sh
fi

# Clear and start
printf "\033c"
printf "${ORANGE}${BOLD}☀️  Starting Sundy.Host VPS...${NC}\n"
sleep 1
printf "\033c"

# ── Apply firewall ──────────────────────────────────────────────────────────
apply_firewall

# ── Cleanup handler ─────────────────────────────────────────────────────────
cleanup() {
    log "INFO" "Session ended. Thank you for using Sundy.Host!" "$ORANGE"
    exit 0
}

# ── Get formatted directory ────────────────────────────────────────────────
get_formatted_dir() {
    current_dir="$PWD"
    case "$current_dir" in
        "$HOME"*)
            printf "~${current_dir#$HOME}"
        ;;
        *)
            printf "$current_dir"
        ;;
    esac
}

# ── Print prompt (orange themed) ───────────────────────────────────────────
print_prompt() {
    user="$1"
    printf "\n${LIGHT_ORANGE}${user}@${HOSTNAME}${NC}:${AMBER}$(get_formatted_dir)${NC}# "
}

print_instructions() {
    log "INFO" "Type 'help' to view available commands." "$AMBER"
}

# ── History ─────────────────────────────────────────────────────────────────
save_to_history() {
    cmd="$1"
    if [ -n "$cmd" ] && [ "$cmd" != "exit" ]; then
        printf "$cmd\n" >> "$HISTORY_FILE"
        if [ -f "$HISTORY_FILE" ]; then
            tail -n "$MAX_HISTORY" "$HISTORY_FILE" > "$HISTORY_FILE.tmp"
            mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
        fi
    fi
}

# ── Reinstall ──────────────────────────────────────────────────────────────
reinstall() {
    printf "\n"
    printf "${DARK_ORANGE}${BOLD}╔══════════════════════════════════════════════╗${NC}\n"
    printf "${DARK_ORANGE}${BOLD}║  ⚠️  WARNING: THIS WILL WIPE ALL DATA!      ║${NC}\n"
    printf "${DARK_ORANGE}${BOLD}╚══════════════════════════════════════════════╝${NC}\n"
    printf "\n"
    printf "${AMBER}  Are you sure? (yes/no): ${NC}\n"
    read -r confirm

    if [ "$confirm" = "yes" ] || [ "$confirm" = "y" ]; then
        log "INFO" "Starting reinstallation..." "$ORANGE"

        rm -f "$HOME/.installed" "/.installed"

        find "$HOME" -mindepth 1 -maxdepth 1 \
            ! -name "run.sh" \
            ! -name "common.sh" \
            ! -name "firewall.sh" \
            ! -name "vps.config" \
            ! -name ".shell_history" \
            -exec rm -rf {} + 2>/dev/null

        log "SUCCESS" "Data wiped. Server will restart for OS selection." "$GREEN"
        sleep 2
        exit 2
    else
        log "INFO" "Reinstallation cancelled." "$AMBER"
    fi
}

# ── System status ──────────────────────────────────────────────────────────
show_system_status() {
    printf "\n"
    printf "${ORANGE}╔═══════════════════════════════════════════════════════════════╗${NC}\n"
    printf "${ORANGE}║         ${WHITE}${BOLD}📊  SUNDY.HOST — SYSTEM STATUS  📊${ORANGE}                 ║${NC}\n"
    printf "${ORANGE}╚═══════════════════════════════════════════════════════════════╝${NC}\n"
    printf "\n"

    printf "  ${AMBER}⏱️  Uptime:${NC}      "
    uptime 2>/dev/null | sed 's/.*up //' | sed 's/,.*load.*//' || echo "N/A"

    printf "  ${AMBER}🧠 Memory:${NC}\n"
    if command -v free >/dev/null 2>&1; then
        free -h 2>/dev/null | head -2 | while IFS= read -r line; do
            printf "       %s\n" "$line"
        done
    else
        cat /proc/meminfo 2>/dev/null | head -3 | while IFS= read -r line; do
            printf "       %s\n" "$line"
        done
    fi

    printf "  ${AMBER}💾 Disk:${NC}\n"
    df -h / 2>/dev/null | while IFS= read -r line; do
        printf "       %s\n" "$line"
    done

    printf "  ${AMBER}🐧 OS:${NC}          "
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$PRETTY_NAME"
    else
        uname -o 2>/dev/null || echo "Unknown"
    fi

    printf "  ${AMBER}🏗️  Arch:${NC}        "
    uname -m

    printf "  ${AMBER}📈 Top Processes:${NC}\n"
    if command -v ps >/dev/null 2>&1; then
        ps aux --sort=-%mem 2>/dev/null | head -6 | while IFS= read -r line; do
            printf "       %s\n" "$line"
        done
    fi

    printf "\n"
}

# ── Show ports ─────────────────────────────────────────────────────────────
show_ports() {
    printf "\n"
    printf "${ORANGE}╔═══════════════════════════════════════════════════════════════╗${NC}\n"
    printf "${ORANGE}║         ${WHITE}${BOLD}🌐  SUNDY.HOST — CONFIGURED PORTS  🌐${ORANGE}              ║${NC}\n"
    printf "${ORANGE}╚═══════════════════════════════════════════════════════════════╝${NC}\n"
    printf "\n"

    config_file="$HOME/vps.config"
    if [ -f "$config_file" ]; then
        port_found=0
        while IFS='=' read -r key value; do
            key=$(echo "$key" | tr -d '[:space:]')
            value=$(echo "$value" | tr -d '[:space:]')

            case "$key" in
                ""|"#"*) continue ;;
            esac

            case "$key" in
                port|port[0-9]*)
                    if [ -n "$value" ]; then
                        printf "  ${ORANGE}●${NC}  %-12s → ${WHITE}${BOLD}%s${NC}\n" "$key" "$value"
                        port_found=1
                    fi
                ;;
                internalip)
                    printf "  ${AMBER}🏠${NC} Internal IP  → ${WHITE}${BOLD}%s${NC}\n" "$value"
                ;;
            esac
        done < "$config_file"

        if [ "$port_found" -eq 0 ]; then
            printf "  ${AMBER}No additional ports configured.${NC}\n"
            printf "  ${DIM}Add ports in the Startup tab of your server settings.${NC}\n"
        fi
    else
        printf "  ${RED}Config file not found.${NC}\n"
    fi
    printf "\n"
}

# ── Backup ─────────────────────────────────────────────────────────────────
create_backup() {
    if ! command -v tar > /dev/null 2>&1; then
        log "ERROR" "tar is not installed." "$RED"
        return 1
    fi

    backup_file="/backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    exclude_file="/tmp/exclude-list.txt"

    cat > "$exclude_file" <<EOF
./${backup_file#/}
./proc
./tmp
./dev
./sys
./run
./vps.config
${exclude_file#/}
EOF

    log "INFO" "Creating backup..." "$ORANGE"
    (cd / && tar --numeric-owner -czf "$backup_file" -X "$exclude_file" .) > /dev/null 2>&1

    if [ -f "$backup_file" ]; then
        size=$(du -h "$backup_file" | cut -f1)
        log "SUCCESS" "Backup created: ${backup_file} (${size})" "$GREEN"
    else
        log "ERROR" "Backup failed." "$RED"
    fi

    rm -f "$exclude_file"
}

# ── Restore ────────────────────────────────────────────────────────────────
restore_backup() {
    backup_file="$1"

    if ! command -v tar > /dev/null 2>&1; then
        log "ERROR" "tar is not installed." "$RED"
        return 1
    fi

    if [ -z "$backup_file" ]; then
        log "INFO" "Usage: restore <backup_file>" "$AMBER"

        backups=$(ls /backup_*.tar.gz 2>/dev/null)
        if [ -n "$backups" ]; then
            printf "\n  ${AMBER}Available backups:${NC}\n"
            for f in /backup_*.tar.gz; do
                size=$(du -h "$f" | cut -f1)
                printf "    ${ORANGE}●${NC} %s (${size})\n" "$(basename "$f")"
            done
            printf "\n"
        fi
        return 1
    fi

    if [ -f "/$backup_file" ]; then
        log "INFO" "Restoring from ${backup_file}..." "$ORANGE"
        tar --numeric-owner -xzf "/$backup_file" -C / --exclude="$backup_file" > /dev/null 2>&1
        log "SUCCESS" "Backup restored from ${backup_file}" "$GREEN"
    else
        log "ERROR" "Backup file not found: ${backup_file}" "$RED"
    fi
}

# ── Command execution ──────────────────────────────────────────────────────
execute_command() {
    cmd="$1"
    user="$2"

    save_to_history "$cmd"

    case "$cmd" in
        "clear"|"cls")
            printf "\033c"
            return 0
        ;;
        "exit")
            cleanup
        ;;
        "history")
            if [ -f "$HISTORY_FILE" ]; then
                printf "\n  ${AMBER}📜 Command History:${NC}\n"
                nl -ba "$HISTORY_FILE" | tail -20 | while IFS= read -r line; do
                    printf "    ${DIM}%s${NC}\n" "$line"
                done
            else
                log "INFO" "No history yet." "$AMBER"
            fi
            return 0
        ;;
        "reinstall")
            reinstall
            return 0
        ;;
        "sudo"*|"su"*)
            log "INFO" "You are already running as root." "$AMBER"
            return 0
        ;;
        "status")
            show_system_status
            return 0
        ;;
        "ports")
            show_ports
            return 0
        ;;
        "firewall")
            show_firewall_status
            return 0
        ;;
        "backup")
            create_backup
            return 0
        ;;
        "restore")
            restore_backup ""
            return 0
        ;;
        "restore "*)
            backup_file=$(echo "$cmd" | cut -d' ' -f2-)
            restore_backup "$backup_file"
            return 0
        ;;
        "help")
            print_help_banner
            return 0
        ;;
        "")
            return 0
        ;;
        *)
            eval "$cmd"
            return 0
        ;;
    esac
}

# ── Run prompt ──────────────────────────────────────────────────────────────
run_prompt() {
    user="$1"
    print_prompt "$user"
    read -r cmd
    execute_command "$cmd" "$user"
}

# ═══════════════════════════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════════════════════════

touch "$HISTORY_FILE"

trap cleanup INT TERM

# Print Sundy.Host banner
print_main_banner
print_instructions

# Execute autorun
sh "/autorun.sh" 2>/dev/null

# Main loop
while true; do
    run_prompt "root"
done
