#!/bin/sh
# ============================================================================
#  common.sh — Sundy.Host VPS | Colors, logging, banners
# ============================================================================

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

# Safe print for escape codes
P() {
    printf '%b\n' "$1"
}

log() {
    P "${3:-$NC}[$1]${NC} $2"
}

detect_architecture() {
    case "$(uname -m)" in
        x86_64)  echo "amd64" ;;
        aarch64) echo "arm64" ;;
        riscv64) echo "riscv64" ;;
        *) log "ERROR" "Unsupported CPU: $(uname -m)" "$RED" >&2; return 1 ;;
    esac
}

print_main_banner() {
    YEAR=$(date +%Y)
    printf '\033c'
    P "${ORANGE}╔════════════════════════════════════════════════════════════════╗${NC}"
    P "${ORANGE}║                                                                ║${NC}"
    P "${ORANGE}║     ${LIGHT_ORANGE}${BOLD}███████╗██╗   ██╗███╗   ██╗██████╗ ██╗   ██╗${NC}${ORANGE}             ║${NC}"
    P "${ORANGE}║     ${LIGHT_ORANGE}${BOLD}██╔════╝██║   ██║████╗  ██║██╔══██╗╚██╗ ██╔╝${NC}${ORANGE}             ║${NC}"
    P "${ORANGE}║     ${LIGHT_ORANGE}${BOLD}███████╗██║   ██║██╔██╗ ██║██║  ██║ ╚████╔╝ ${NC}${ORANGE}             ║${NC}"
    P "${ORANGE}║     ${LIGHT_ORANGE}${BOLD}╚════██║██║   ██║██║╚██╗██║██║  ██║  ╚██╔╝  ${NC}${ORANGE}             ║${NC}"
    P "${ORANGE}║     ${LIGHT_ORANGE}${BOLD}███████║╚██████╔╝██║ ╚████║██████╔╝   ██║   ${NC}${ORANGE}             ║${NC}"
    P "${ORANGE}║     ${LIGHT_ORANGE}${BOLD}╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝    ╚═╝   ${NC}${ORANGE}             ║${NC}"
    P "${ORANGE}║                                                                ║${NC}"
    P "${ORANGE}║          ${AMBER}${BOLD}Sundy.Host  ---  Secure VPS Environment${NC}${ORANGE}             ║${NC}"
    P "${ORANGE}║                                                                ║${NC}"
    P "${ORANGE}║            ${DIM}(c) ${YEAR} Sundy.Host. All rights reserved.${NC}${ORANGE}          ║${NC}"
    P "${ORANGE}║                                                                ║${NC}"
    P "${ORANGE}╚════════════════════════════════════════════════════════════════╝${NC}"
    P ""
}

print_help_banner() {
    P ""
    P "${DARK_ORANGE}╔════════════════════════════════════════════════════════════════╗${NC}"
    P "${DARK_ORANGE}║                                                                ║${NC}"
    P "${DARK_ORANGE}║              ${WHITE}${BOLD}SUNDY.HOST --- AVAILABLE COMMANDS${NC}${DARK_ORANGE}                 ║${NC}"
    P "${DARK_ORANGE}║                                                                ║${NC}"
    P "${DARK_ORANGE}╠════════════════════════════════════════════════════════════════╣${NC}"
    P "${DARK_ORANGE}║                                                                ║${NC}"
    P "${DARK_ORANGE}║  ${AMBER}${BOLD}help${NC}             ${ORANGE}>${NC}  Show this help message${DARK_ORANGE}                  ║${NC}"
    P "${DARK_ORANGE}║  ${AMBER}${BOLD}status${NC}           ${ORANGE}>${NC}  System status (Neofetch style)${DARK_ORANGE}          ║${NC}"
    P "${DARK_ORANGE}║  ${AMBER}${BOLD}procs${NC}            ${ORANGE}>${NC}  View all running processes${DARK_ORANGE}              ║${NC}"
    P "${DARK_ORANGE}║  ${AMBER}${BOLD}portcheck${NC}        ${ORANGE}>${NC}  Check what is using your ports${DARK_ORANGE}          ║${NC}"
    P "${DARK_ORANGE}║  ${AMBER}${BOLD}ports${NC}            ${ORANGE}>${NC}  Show your allocated ports${DARK_ORANGE}               ║${NC}"
    P "${DARK_ORANGE}║  ${AMBER}${BOLD}firewall${NC}         ${ORANGE}>${NC}  Sundy.Shield protection status${DARK_ORANGE}          ║${NC}"
    P "${DARK_ORANGE}║  ${AMBER}${BOLD}reinstall${NC}        ${ORANGE}>${NC}  Reinstall operating system${DARK_ORANGE}              ║${NC}"
    P "${DARK_ORANGE}║  ${AMBER}${BOLD}backup${NC}           ${ORANGE}>${NC}  Create full system backup${DARK_ORANGE}               ║${NC}"
    P "${DARK_ORANGE}║  ${AMBER}${BOLD}restore <file>${NC}   ${ORANGE}>${NC}  Restore from backup file${DARK_ORANGE}                ║${NC}"
    P "${DARK_ORANGE}║  ${AMBER}${BOLD}history${NC}          ${ORANGE}>${NC}  Show command history${DARK_ORANGE}                    ║${NC}"
    P "${DARK_ORANGE}║  ${AMBER}${BOLD}clear / cls${NC}      ${ORANGE}>${NC}  Clear terminal screen${DARK_ORANGE}                   ║${NC}"
    P "${DARK_ORANGE}║  ${AMBER}${BOLD}exit${NC}             ${ORANGE}>${NC}  Shutdown server${DARK_ORANGE}                         ║${NC}"
    P "${DARK_ORANGE}║                                                                ║${NC}"
    P "${DARK_ORANGE}╠════════════════════════════════════════════════════════════════╣${NC}"
    P "${DARK_ORANGE}║                                                                ║${NC}"
    P "${DARK_ORANGE}║  ${DIM}All standard Linux commands work as expected.${NC}${DARK_ORANGE}                 ║${NC}"
    P "${DARK_ORANGE}║  ${DIM}Tip: Press the 'Stop' button in Panel to interrupt a process.${NC}${DARK_ORANGE} ║${NC}"
    P "${DARK_ORANGE}║                                                                ║${NC}"
    P "${DARK_ORANGE}╚════════════════════════════════════════════════════════════════╝${NC}"
    P ""
}
