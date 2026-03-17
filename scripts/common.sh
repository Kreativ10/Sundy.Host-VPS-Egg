#!/bin/sh
# ============================================================================
#  common.sh — Sundy.Host VPS | Colors, logging, banners
# ============================================================================

# ── Orange palette ──────────────────────────────────────────────────────────
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
    level="$1"
    message="$2"
    color="${3:-$NC}"
    echo "${color}[${level}]${NC} ${message}"
}

# ── Architecture ────────────────────────────────────────────────────────────
detect_architecture() {
    case "$(uname -m)" in
        x86_64)  echo "amd64" ;;
        aarch64) echo "arm64" ;;
        riscv64) echo "riscv64" ;;
        *) log "ERROR" "Unsupported CPU: $(uname -m)" "$RED" >&2; return 1 ;;
    esac
}

# ── Main banner ─────────────────────────────────────────────────────────────
print_main_banner() {
    YEAR=$(date +%Y)
    echo "\033c"
    echo "${ORANGE}╔════════════════════════════════════════════════════════╗${NC}"
    echo "${ORANGE}║                                                        ║${NC}"
    echo "${ORANGE}║   ${LIGHT_ORANGE}${BOLD}███████╗██╗   ██╗███╗   ██╗██████╗ ██╗   ██╗${ORANGE}   ║${NC}"
    echo "${ORANGE}║   ${LIGHT_ORANGE}${BOLD}██╔════╝██║   ██║████╗  ██║██╔══██╗╚██╗ ██╔╝${ORANGE}   ║${NC}"
    echo "${ORANGE}║   ${LIGHT_ORANGE}${BOLD}███████╗██║   ██║██╔██╗ ██║██║  ██║ ╚████╔╝ ${ORANGE}   ║${NC}"
    echo "${ORANGE}║   ${LIGHT_ORANGE}${BOLD}╚════██║██║   ██║██║╚██╗██║██║  ██║  ╚██╔╝  ${ORANGE}   ║${NC}"
    echo "${ORANGE}║   ${LIGHT_ORANGE}${BOLD}███████║╚██████╔╝██║ ╚████║██████╔╝   ██║   ${ORANGE}   ║${NC}"
    echo "${ORANGE}║   ${LIGHT_ORANGE}${BOLD}╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝    ╚═╝   ${ORANGE}   ║${NC}"
    echo "${ORANGE}║                                                        ║${NC}"
    echo "${ORANGE}║          ${AMBER}${BOLD}Sundy.Host  ---  VPS Panel${ORANGE}                  ║${NC}"
    echo "${ORANGE}║                                                        ║${NC}"
    echo "${ORANGE}║      ${PEACH}Secure - Fast - Protected - Reliable${ORANGE}            ║${NC}"
    echo "${ORANGE}║                                                        ║${NC}"
    echo "${ORANGE}║            ${DIM}(c) ${YEAR} Sundy.Host${ORANGE}                        ║${NC}"
    echo "${ORANGE}║                                                        ║${NC}"
    echo "${ORANGE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ── Help banner ─────────────────────────────────────────────────────────────
print_help_banner() {
    echo ""
    echo "${DARK_ORANGE}╔════════════════════════════════════════════════════════╗${NC}"
    echo "${DARK_ORANGE}║                                                        ║${NC}"
    echo "${DARK_ORANGE}║       ${WHITE}${BOLD}SUNDY.HOST --- AVAILABLE COMMANDS${DARK_ORANGE}               ║${NC}"
    echo "${DARK_ORANGE}║                                                        ║${NC}"
    echo "${DARK_ORANGE}╠════════════════════════════════════════════════════════╣${NC}"
    echo "${DARK_ORANGE}║                                                        ║${NC}"
    echo "${DARK_ORANGE}║  ${AMBER}${BOLD}help${NC}             ${ORANGE}>${NC}  Show this help message${DARK_ORANGE}         ║${NC}"
    echo "${DARK_ORANGE}║  ${AMBER}${BOLD}status${NC}           ${ORANGE}>${NC}  System status (CPU/RAM/Disk)${DARK_ORANGE}    ║${NC}"
    echo "${DARK_ORANGE}║  ${AMBER}${BOLD}ports${NC}            ${ORANGE}>${NC}  Show configured ports${DARK_ORANGE}           ║${NC}"
    echo "${DARK_ORANGE}║  ${AMBER}${BOLD}firewall${NC}         ${ORANGE}>${NC}  Firewall & protection status${DARK_ORANGE}    ║${NC}"
    echo "${DARK_ORANGE}║  ${AMBER}${BOLD}reinstall${NC}        ${ORANGE}>${NC}  Reinstall operating system${DARK_ORANGE}      ║${NC}"
    echo "${DARK_ORANGE}║  ${AMBER}${BOLD}backup${NC}           ${ORANGE}>${NC}  Create system backup${DARK_ORANGE}            ║${NC}"
    echo "${DARK_ORANGE}║  ${AMBER}${BOLD}restore <file>${NC}   ${ORANGE}>${NC}  Restore from backup${DARK_ORANGE}             ║${NC}"
    echo "${DARK_ORANGE}║  ${AMBER}${BOLD}history${NC}          ${ORANGE}>${NC}  Show command history${DARK_ORANGE}            ║${NC}"
    echo "${DARK_ORANGE}║  ${AMBER}${BOLD}clear / cls${NC}      ${ORANGE}>${NC}  Clear terminal${DARK_ORANGE}                  ║${NC}"
    echo "${DARK_ORANGE}║  ${AMBER}${BOLD}stop${NC}             ${ORANGE}>${NC}  Stop current process (Ctrl+C)${DARK_ORANGE}   ║${NC}"
    echo "${DARK_ORANGE}║  ${AMBER}${BOLD}exit${NC}             ${ORANGE}>${NC}  Shutdown server${DARK_ORANGE}                 ║${NC}"
    echo "${DARK_ORANGE}║                                                        ║${NC}"
    echo "${DARK_ORANGE}╠════════════════════════════════════════════════════════╣${NC}"
    echo "${DARK_ORANGE}║                                                        ║${NC}"
    echo "${DARK_ORANGE}║  ${DIM}All standard Linux commands work as expected.${DARK_ORANGE}       ║${NC}"
    echo "${DARK_ORANGE}║  ${DIM}Ports: 30000-35000 only. Bandwidth: 100 Mbit/s.${DARK_ORANGE}     ║${NC}"
    echo "${DARK_ORANGE}║                                                        ║${NC}"
    echo "${DARK_ORANGE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
}
