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

# ── SSH Setup ──────────────────────────────────────────────────────────────
do_ssh() {
    P ""
    P "${ORANGE}╔════════════════════════════════════════════════════════════════╗${NC}"
    P "${ORANGE}║           ${WHITE}${BOLD}SUNDY.HOST --- SSH SETUP${NC}${ORANGE}                             ║${NC}"
    P "${ORANGE}╚════════════════════════════════════════════════════════════════╝${NC}"
    P ""

    # Use PUBLIC_IP set by helper.sh at container level
    IP_ADDRESS="${PUBLIC_IP:-UNKNOWN}"

    # Get available ports
    AVAILABLE_PORTS=$(get_config_ports)

    if [ -z "$AVAILABLE_PORTS" ]; then
        P "${AMBER}Could not detect ports from vps.config.${NC}"
        P "${AMBER}Enter the port for SSH (from your Panel allocation):${NC}"
        read -r SSPORT
        [ -z "$SSPORT" ] && { P "${RED}Port cannot be empty!${NC}"; return; }
    else
        P "Your allocated ports: ${GREEN}${AVAILABLE_PORTS}${NC}"
        P ""
        P "${AMBER}Enter the port to use for SSH:${NC}"
        read -r SSPORT

        valid_port=0
        for p in $AVAILABLE_PORTS; do
            [ "$p" = "$SSPORT" ] && valid_port=1 && break
        done
        if [ "$valid_port" -eq 0 ]; then
            P "${RED}Error: Port ${SSPORT} is not in your allocation.${NC}"
            return
        fi
    fi

    P ""
    P "${AMBER}Enter SSH username (default: root):${NC}"
    read -r SSUSER
    [ -z "$SSUSER" ] && SSUSER="root"

    P ""
    P "${AMBER}Enter SSH password:${NC}"
    read -r SSPASS
    [ -z "$SSPASS" ] && { P "${RED}Password cannot be empty.${NC}"; return; }

    P ""
    P "${ORANGE}[Sundy.Host] Installing and configuring SSH...${NC}"

    # Auto-install openssh-server if missing
    if ! command -v sshd >/dev/null 2>&1; then
        P "${AMBER}OpenSSH Server not found. Installing...${NC}"
        if command -v apt-get >/dev/null; then
            apt-get update -qq && apt-get install -y -qq openssh-server 2>&1
        elif command -v apk >/dev/null; then
            apk update && apk add openssh openssh-server 2>&1
        elif command -v yum >/dev/null; then
            yum install -y openssh-server 2>&1
        elif command -v dnf >/dev/null; then
            dnf install -y openssh-server 2>&1
        elif command -v pacman >/dev/null; then
            pacman -Sy --noconfirm openssh 2>&1
        else
            P "${RED}Could not install OpenSSH. Install it manually: apt install openssh-server${NC}"
            return
        fi
    fi

    # Verify sshd was installed
    SSHD_BIN=$(command -v sshd 2>/dev/null)
    if [ -z "$SSHD_BIN" ]; then
        # Try common paths
        for path in /usr/sbin/sshd /usr/bin/sshd /sbin/sshd; do
            [ -x "$path" ] && SSHD_BIN="$path" && break
        done
    fi
    if [ -z "$SSHD_BIN" ]; then
        P "${RED}Error: sshd binary not found even after install.${NC}"
        return
    fi
    P "${GREEN}Found sshd at: ${SSHD_BIN}${NC}"

    # Create user / set password
    if [ "$SSUSER" != "root" ]; then
        if ! id "$SSUSER" >/dev/null 2>&1; then
            useradd -m -s /bin/bash "$SSUSER" 2>/dev/null || adduser -D -s /bin/sh "$SSUSER" 2>/dev/null
        fi
    fi

    # Set password
    echo "${SSUSER}:${SSPASS}" | chpasswd 2>/dev/null
    if [ $? -ne 0 ]; then
        # Some distros need different approach
        echo -e "${SSPASS}\n${SSPASS}" | passwd "$SSUSER" 2>/dev/null
    fi

    # Generate host keys
    mkdir -p /etc/ssh /run/sshd /var/run/sshd 2>/dev/null

    if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
        ssh-keygen -t rsa -b 2048 -N "" -f /etc/ssh/ssh_host_rsa_key >/dev/null 2>&1
        P "${GREEN}Generated RSA host key${NC}"
    fi
    if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
        ssh-keygen -t ed25519 -N "" -f /etc/ssh/ssh_host_ed25519_key >/dev/null 2>&1
        P "${GREEN}Generated ED25519 host key${NC}"
    fi
    if [ ! -f /etc/ssh/ssh_host_ecdsa_key ]; then
        ssh-keygen -t ecdsa -b 256 -N "" -f /etc/ssh/ssh_host_ecdsa_key >/dev/null 2>&1
        P "${GREEN}Generated ECDSA host key${NC}"
    fi

    # Write sshd_config — minimal, compatible with all distros
    SSHD_CONF="/etc/ssh/sshd_config"
    cat > "$SSHD_CONF" <<SSHEOF
Port ${SSPORT}
ListenAddress 0.0.0.0
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_ecdsa_key
PermitRootLogin yes
PasswordAuthentication yes
ChallengeResponseAuthentication no
UsePAM no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
SSHEOF

    # Kill any existing sshd then start fresh
    pkill sshd 2>/dev/null
    sleep 1

    # Start sshd and capture errors
    P "${ORANGE}Starting SSH daemon on port ${SSPORT}...${NC}"
    SSHD_OUTPUT=$($SSHD_BIN -f "$SSHD_CONF" -E /tmp/sshd.log 2>&1)

    sleep 1

    # Check if running
    if pgrep -x sshd >/dev/null 2>&1; then
        # Save config for autostart
        cat > /etc/ssh/sundy_ssh.conf <<CONFEOF
SSPORT=${SSPORT}
SSUSER=${SSUSER}
SSPASS=${SSPASS}
CONFEOF

        P ""
        P "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
        P "${GREEN}║              ${WHITE}${BOLD}SSH SERVER IS RUNNING${NC}${GREEN}                             ║${NC}"
        P "${GREEN}╠════════════════════════════════════════════════════════════════╣${NC}"
        P "${GREEN}║${NC}"
        P "${GREEN}║${NC}  ${AMBER}IP:${NC}        ${WHITE}${BOLD}${IP_ADDRESS}${NC}"
        P "${GREEN}║${NC}  ${AMBER}Port:${NC}      ${WHITE}${BOLD}${SSPORT}${NC}"
        P "${GREEN}║${NC}  ${AMBER}Username:${NC}  ${WHITE}${BOLD}${SSUSER}${NC}"
        P "${GREEN}║${NC}  ${AMBER}Password:${NC}  ${WHITE}${BOLD}${SSPASS}${NC}"
        P "${GREEN}║${NC}"
        P "${GREEN}╠════════════════════════════════════════════════════════════════╣${NC}"
        P "${GREEN}║${NC}"
        P "${GREEN}║${NC}  ${AMBER}Connect with:${NC}"
        P "${GREEN}║${NC}  ${WHITE}ssh ${SSUSER}@${IP_ADDRESS} -p ${SSPORT}${NC}"
        P "${GREEN}║${NC}"
        P "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
        P ""
        P "${DIM}Note: SSH will stop when the server restarts. Run 'ssh' again to re-enable.${NC}"
        P "${DIM}Note: systemctl does not work here. sshd runs directly.${NC}"
        P ""
    else
        P "${RED}Error: SSH server failed to start!${NC}"
        P "${RED}Debug log:${NC}"
        [ -f /tmp/sshd.log ] && cat /tmp/sshd.log
        [ -n "$SSHD_OUTPUT" ] && P "$SSHD_OUTPUT"
        P ""
        P "${AMBER}Common fixes:${NC}"
        P "  1. Make sure openssh-server is fully installed"
        P "  2. Try: ${WHITE}apt install -y openssh-server${NC}"
        P "  3. Check if port ${SSPORT} is allocated in Panel"
        P ""
    fi
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
        ssh)          do_ssh ;;
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

# Auto-restart SSH if it was configured before
if [ -f /etc/ssh/sundy_ssh.conf ]; then
    . /etc/ssh/sundy_ssh.conf
    SSHD_BIN=$(command -v sshd 2>/dev/null)
    [ -z "$SSHD_BIN" ] && for p in /usr/sbin/sshd /usr/bin/sshd /sbin/sshd; do [ -x "$p" ] && SSHD_BIN="$p" && break; done
    if [ -n "$SSHD_BIN" ] && [ -f /etc/ssh/sshd_config ]; then
        mkdir -p /run/sshd /var/run/sshd 2>/dev/null
        $SSHD_BIN -f /etc/ssh/sshd_config 2>/dev/null
        if pgrep -x sshd >/dev/null 2>&1; then
            log "INFO" "SSH auto-started on port ${SSPORT} (user: ${SSUSER})" "$GREEN"
        fi
    fi
fi

sh "/autorun.sh" 2>/dev/null

while true; do
    show_prompt
    if read -r cmd; then
        execute "$cmd"
    fi
done
