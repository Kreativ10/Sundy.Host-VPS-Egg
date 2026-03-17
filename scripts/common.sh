#!/bin/sh
# ============================================================================
#  common.sh — Sundy.Host VPS | Shared colors, logging, banners
# ============================================================================

# ── Orange-themed color palette ─────────────────────────────────────────────
ORANGE='\033[38;5;208m'
LIGHT_ORANGE='\033[38;5;214m'
DARK_ORANGE='\033[38;5;202m'
PEACH='\033[38;5;216m'
AMBER='\033[38;5;220m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── Logger ──────────────────────────────────────────────────────────────────
log() {
    level=$1
    message=$2
    color=$3

    if [ -z "$color" ]; then
        color="$NC"
    fi

    printf "${color}[${level}]${NC} ${message}\n"
}

# ── Architecture detection ─────────────────────────────────────────────────
detect_architecture() {
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)
            echo "amd64"
        ;;
        aarch64)
            echo "arm64"
        ;;
        riscv64)
            echo "riscv64"
        ;;
        *)
            log "ERROR" "Unsupported CPU architecture: $ARCH" "$RED" >&2
            return 1
        ;;
    esac
}

# ── Main banner (startup) ──────────────────────────────────────────────────
print_main_banner() {
    printf "\033c"
    printf "${ORANGE}╔═══════════════════════════════════════════════════════════════╗${NC}\n"
    printf "${ORANGE}║                                                               ║${NC}\n"
    printf "${ORANGE}║    ${LIGHT_ORANGE}${BOLD}███████╗██╗   ██╗███╗   ██╗██████╗ ██╗   ██╗${ORANGE}            ║${NC}\n"
    printf "${ORANGE}║    ${LIGHT_ORANGE}${BOLD}██╔════╝██║   ██║████╗  ██║██╔══██╗╚██╗ ██╔╝${ORANGE}            ║${NC}\n"
    printf "${ORANGE}║    ${LIGHT_ORANGE}${BOLD}███████╗██║   ██║██╔██╗ ██║██║  ██║ ╚████╔╝${ORANGE}             ║${NC}\n"
    printf "${ORANGE}║    ${LIGHT_ORANGE}${BOLD}╚════██║██║   ██║██║╚██╗██║██║  ██║  ╚██╔╝${ORANGE}              ║${NC}\n"
    printf "${ORANGE}║    ${LIGHT_ORANGE}${BOLD}███████║╚██████╔╝██║ ╚████║██████╔╝   ██║${ORANGE}               ║${NC}\n"
    printf "${ORANGE}║    ${LIGHT_ORANGE}${BOLD}╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝    ╚═╝${ORANGE}               ║${NC}\n"
    printf "${ORANGE}║                                                               ║${NC}\n"
    printf "${ORANGE}║               ${AMBER}${BOLD}☀️  Sundy.Host — VPS Panel  ☀️${ORANGE}                  ║${NC}\n"
    printf "${ORANGE}║                                                               ║${NC}\n"
    printf "${ORANGE}║        ${PEACH}${BOLD}🛡️  Secure • Fast • Protected • Reliable  🛡️${ORANGE}         ║${NC}\n"
    printf "${ORANGE}║                                                               ║${NC}\n"
    printf "${ORANGE}║               ${DIM}© $(date +%%Y) Sundy.Host — All Rights Reserved${ORANGE}       ║${NC}\n"
    printf "${ORANGE}║                                                               ║${NC}\n"
    printf "${ORANGE}╚═══════════════════════════════════════════════════════════════╝${NC}\n"
    printf "\n"
}

# ── Help banner ─────────────────────────────────────────────────────────────
print_help_banner() {
    printf "${DARK_ORANGE}╔═══════════════════════════════════════════════════════════════╗${NC}\n"
    printf "${DARK_ORANGE}║                                                               ║${NC}\n"
    printf "${DARK_ORANGE}║           ${WHITE}${BOLD}📋  SUNDY.HOST — AVAILABLE COMMANDS  📋${DARK_ORANGE}             ║${NC}\n"
    printf "${DARK_ORANGE}║                                                               ║${NC}\n"
    printf "${DARK_ORANGE}╠═══════════════════════════════════════════════════════════════╣${NC}\n"
    printf "${DARK_ORANGE}║                                                               ║${NC}\n"
    printf "${DARK_ORANGE}║  ${PEACH}🧹  ${AMBER}${BOLD}clear, cls${NC}       ${ORANGE}▶${NC}  Clear the terminal screen${DARK_ORANGE}           ║${NC}\n"
    printf "${DARK_ORANGE}║  ${RED}🔌  ${AMBER}${BOLD}exit${NC}             ${ORANGE}▶${NC}  Shutdown the server${DARK_ORANGE}                  ║${NC}\n"
    printf "${DARK_ORANGE}║  ${PEACH}📜  ${AMBER}${BOLD}history${NC}          ${ORANGE}▶${NC}  Show command history${DARK_ORANGE}                 ║${NC}\n"
    printf "${DARK_ORANGE}║  ${LIGHT_ORANGE}🔄  ${AMBER}${BOLD}reinstall${NC}        ${ORANGE}▶${NC}  Reinstall the operating system${DARK_ORANGE}       ║${NC}\n"
    printf "${DARK_ORANGE}║  ${ORANGE}📊  ${AMBER}${BOLD}status${NC}           ${ORANGE}▶${NC}  Show system status (CPU/RAM/Disk)${DARK_ORANGE}    ║${NC}\n"
    printf "${DARK_ORANGE}║  ${AMBER}💾  ${AMBER}${BOLD}backup${NC}           ${ORANGE}▶${NC}  Create full system backup${DARK_ORANGE}            ║${NC}\n"
    printf "${DARK_ORANGE}║  ${PEACH}📥  ${AMBER}${BOLD}restore <file>${NC}   ${ORANGE}▶${NC}  Restore from backup file${DARK_ORANGE}             ║${NC}\n"
    printf "${DARK_ORANGE}║  ${GREEN}🌐  ${AMBER}${BOLD}ports${NC}            ${ORANGE}▶${NC}  Show all configured ports${DARK_ORANGE}            ║${NC}\n"
    printf "${DARK_ORANGE}║  ${RED}🛡️  ${AMBER}${BOLD}firewall${NC}         ${ORANGE}▶${NC}  Show firewall & protection status${DARK_ORANGE}    ║${NC}\n"
    printf "${DARK_ORANGE}║  ${WHITE}❓  ${AMBER}${BOLD}help${NC}             ${ORANGE}▶${NC}  Display this help message${DARK_ORANGE}            ║${NC}\n"
    printf "${DARK_ORANGE}║                                                               ║${NC}\n"
    printf "${DARK_ORANGE}╠═══════════════════════════════════════════════════════════════╣${NC}\n"
    printf "${DARK_ORANGE}║                                                               ║${NC}\n"
    printf "${DARK_ORANGE}║           ${WHITE}${BOLD}🛡️  SUNDY.HOST PROTECTION SUITE  🛡️${DARK_ORANGE}              ║${NC}\n"
    printf "${DARK_ORANGE}║                                                               ║${NC}\n"
    printf "${DARK_ORANGE}╠═══════════════════════════════════════════════════════════════╣${NC}\n"
    printf "${DARK_ORANGE}║                                                               ║${NC}\n"
    printf "${DARK_ORANGE}║  ${GREEN}✅${NC}  Outbound bandwidth limit (50 Mbit/s)${DARK_ORANGE}                   ║${NC}\n"
    printf "${DARK_ORANGE}║  ${GREEN}✅${NC}  Port range enforcement (30000-35000 only)${DARK_ORANGE}                ║${NC}\n"
    printf "${DARK_ORANGE}║  ${GREEN}✅${NC}  SYN flood rate limiting${DARK_ORANGE}                                 ║${NC}\n"
    printf "${DARK_ORANGE}║  ${GREEN}✅${NC}  UDP flood protection${DARK_ORANGE}                                    ║${NC}\n"
    printf "${DARK_ORANGE}║  ${GREEN}✅${NC}  ICMP flood protection${DARK_ORANGE}                                   ║${NC}\n"
    printf "${DARK_ORANGE}║  ${GREEN}✅${NC}  Port scan detection & block${DARK_ORANGE}                             ║${NC}\n"
    printf "${DARK_ORANGE}║  ${GREEN}✅${NC}  DNS/NTP/Memcache amplification block${DARK_ORANGE}                    ║${NC}\n"
    printf "${DARK_ORANGE}║  ${GREEN}✅${NC}  SMTP (spam) outbound block${DARK_ORANGE}                              ║${NC}\n"
    printf "${DARK_ORANGE}║  ${GREEN}✅${NC}  Connection limit per IP${DARK_ORANGE}                                 ║${NC}\n"
    printf "${DARK_ORANGE}║                                                               ║${NC}\n"
    printf "${DARK_ORANGE}╠═══════════════════════════════════════════════════════════════╣${NC}\n"
    printf "${DARK_ORANGE}║                                                               ║${NC}\n"
    printf "${DARK_ORANGE}║  ${DIM}All standard Linux commands are available.${DARK_ORANGE}                  ║${NC}\n"
    printf "${DARK_ORANGE}║  ${DIM}Type any command as you would in a normal terminal.${DARK_ORANGE}         ║${NC}\n"
    printf "${DARK_ORANGE}║                                                               ║${NC}\n"
    printf "${DARK_ORANGE}╚═══════════════════════════════════════════════════════════════╝${NC}\n"
}
