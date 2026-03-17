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

P() { printf '%b\n' "$1"; }

log() { P "${3:-$NC}[$1]${NC} $2"; }

detect_architecture() {
    case "$(uname -m)" in
        x86_64)  echo "amd64" ;;
        aarch64) echo "arm64" ;;
        riscv64) echo "riscv64" ;;
        *) log "ERROR" "Unsupported: $(uname -m)" "$RED" >&2; return 1 ;;
    esac
}

print_main_banner() {
    YEAR=$(date +%Y)
    printf '\033c'
    P "${ORANGE}+========================================================+${NC}"
    P "${ORANGE}|                                                        |${NC}"
    P "${ORANGE}|   ${LIGHT_ORANGE}${BOLD}  ___  _   _ _  _ ___  _   _   _  _ ___  ___ _____${NC}${ORANGE}  |${NC}"
    P "${ORANGE}|   ${LIGHT_ORANGE}${BOLD} / __|| | | | \| |   \\| | | | | || |/ _ \\/ __|_   _|${NC}${ORANGE} |${NC}"
    P "${ORANGE}|   ${LIGHT_ORANGE}${BOLD} \\__ \\| |_| | .\` | |) | |_| |_| __ | (_) \\__ \\ | |${NC}${ORANGE}  |${NC}"
    P "${ORANGE}|   ${LIGHT_ORANGE}${BOLD} |___/ \\___/|_|\\_|___/ \\___|_| |_||_|\\___/|___/ |_|${NC}${ORANGE}  |${NC}"
    P "${ORANGE}|                                                        |${NC}"
    P "${ORANGE}|            ${AMBER}${BOLD}Sundy.Host  --  VPS Panel${NC}${ORANGE}                 |${NC}"
    P "${ORANGE}|                                                        |${NC}"
    P "${ORANGE}|      ${PEACH}Secure  -  Fast  -  Protected  -  Reliable${NC}${ORANGE}     |${NC}"
    P "${ORANGE}|                                                        |${NC}"
    P "${ORANGE}|               ${DIM}(c) ${YEAR} Sundy.Host${NC}${ORANGE}                     |${NC}"
    P "${ORANGE}|                                                        |${NC}"
    P "${ORANGE}+========================================================+${NC}"
    P ""
}

print_help_banner() {
    P ""
    P "${DARK_ORANGE}+========================================================+${NC}"
    P "${DARK_ORANGE}|                                                        |${NC}"
    P "${DARK_ORANGE}|         ${WHITE}${BOLD}SUNDY.HOST -- AVAILABLE COMMANDS${NC}${DARK_ORANGE}              |${NC}"
    P "${DARK_ORANGE}|                                                        |${NC}"
    P "${DARK_ORANGE}+--------------------------------------------------------+${NC}"
    P "${DARK_ORANGE}|                                                        |${NC}"
    P "${DARK_ORANGE}|  ${AMBER}${BOLD}help${NC}              ${ORANGE}>${NC}  Show this help${DARK_ORANGE}                 |${NC}"
    P "${DARK_ORANGE}|  ${AMBER}${BOLD}status${NC}            ${ORANGE}>${NC}  System info (neofetch-style)${DARK_ORANGE}   |${NC}"
    P "${DARK_ORANGE}|  ${AMBER}${BOLD}ports${NC}             ${ORANGE}>${NC}  Show configured ports${DARK_ORANGE}          |${NC}"
    P "${DARK_ORANGE}|  ${AMBER}${BOLD}portcheck <port>${NC}  ${ORANGE}>${NC}  Check what uses a port${DARK_ORANGE}         |${NC}"
    P "${DARK_ORANGE}|  ${AMBER}${BOLD}procs${NC}             ${ORANGE}>${NC}  List all running processes${DARK_ORANGE}     |${NC}"
    P "${DARK_ORANGE}|  ${AMBER}${BOLD}firewall${NC}          ${ORANGE}>${NC}  Firewall status${DARK_ORANGE}                |${NC}"
    P "${DARK_ORANGE}|  ${AMBER}${BOLD}reinstall${NC}         ${ORANGE}>${NC}  Reinstall OS${DARK_ORANGE}                   |${NC}"
    P "${DARK_ORANGE}|  ${AMBER}${BOLD}backup${NC}            ${ORANGE}>${NC}  Create system backup${DARK_ORANGE}           |${NC}"
    P "${DARK_ORANGE}|  ${AMBER}${BOLD}restore <file>${NC}    ${ORANGE}>${NC}  Restore from backup${DARK_ORANGE}            |${NC}"
    P "${DARK_ORANGE}|  ${AMBER}${BOLD}history${NC}           ${ORANGE}>${NC}  Command history${DARK_ORANGE}                |${NC}"
    P "${DARK_ORANGE}|  ${AMBER}${BOLD}clear / cls${NC}       ${ORANGE}>${NC}  Clear terminal${DARK_ORANGE}                 |${NC}"
    P "${DARK_ORANGE}|  ${AMBER}${BOLD}exit${NC}              ${ORANGE}>${NC}  Shutdown server${DARK_ORANGE}                |${NC}"
    P "${DARK_ORANGE}|                                                        |${NC}"
    P "${DARK_ORANGE}+--------------------------------------------------------+${NC}"
    P "${DARK_ORANGE}|                                                        |${NC}"
    P "${DARK_ORANGE}|  ${DIM}All standard Linux commands work normally.${NC}${DARK_ORANGE}           |${NC}"
    P "${DARK_ORANGE}|  ${DIM}Use Ctrl+C or panel Stop to kill running commands.${NC}${DARK_ORANGE}  |${NC}"
    P "${DARK_ORANGE}|  ${DIM}Ports: 30000-35000. Bandwidth: 100 Mbit/s.${NC}${DARK_ORANGE}          |${NC}"
    P "${DARK_ORANGE}|                                                        |${NC}"
    P "${DARK_ORANGE}+========================================================+${NC}"
    P ""
}
