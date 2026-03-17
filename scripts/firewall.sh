#!/bin/sh
# ============================================================================
#  firewall.sh — Sundy.Host VPS | DDoS protection, anti-abuse, bandwidth
# ============================================================================

# ── Configuration ───────────────────────────────────────────────────────────
BANDWIDTH_LIMIT="50mbit"
BURST_LIMIT="10mbit"
PORT_RANGE_START="30000"
PORT_RANGE_END="35000"
SYN_RATE="50/s"
SYN_BURST="100"
UDP_RATE="100/s"
UDP_BURST="200"
ICMP_RATE="10/s"
ICMP_BURST="20"
CONN_LIMIT_PER_IP="50"
NEW_CONN_RATE="100/s"
PORTSCAN_SECONDS="60"
PORTSCAN_HITCOUNT="15"

# Colors fallback
if [ -z "$ORANGE" ]; then
    ORANGE='\033[38;5;208m'
    LIGHT_ORANGE='\033[38;5;214m'
    DARK_ORANGE='\033[38;5;202m'
    PEACH='\033[38;5;216m'
    AMBER='\033[38;5;220m'
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    WHITE='\033[1;37m'
    BOLD='\033[1m'
    DIM='\033[2m'
    NC='\033[0m'
fi

# ── Safe iptables ──────────────────────────────────────────────────────────
safe_ipt() {
    iptables "$@" 2>/dev/null
    return 0
}

# ── Apply all rules ───────────────────────────────────────────────────────
apply_firewall() {
    printf "${ORANGE}[☀️ SUNDY.SHIELD]${NC} Applying protection rules...\n"

    # 1. Bandwidth limit via tc
    if command -v tc >/dev/null 2>&1; then
        IFACE=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
        if [ -n "$IFACE" ]; then
            tc qdisc del dev "$IFACE" root 2>/dev/null
            tc qdisc add dev "$IFACE" root handle 1: htb default 10 2>/dev/null
            tc class add dev "$IFACE" parent 1: classid 1:10 htb \
                rate "$BANDWIDTH_LIMIT" burst "$BURST_LIMIT" 2>/dev/null
            if [ $? -eq 0 ]; then
                printf "${GREEN}  ✅  Bandwidth limit: ${BANDWIDTH_LIMIT}${NC}\n"
            else
                printf "${AMBER}  ⚠️  Bandwidth limit: skipped (tc error)${NC}\n"
            fi
        else
            printf "${AMBER}  ⚠️  Bandwidth limit: skipped (no interface)${NC}\n"
        fi
    else
        printf "${AMBER}  ⚠️  Bandwidth limit: skipped (tc unavailable)${NC}\n"
    fi

    # 2. Create chain
    safe_ipt -F VPS_PROTECT 2>/dev/null
    safe_ipt -X VPS_PROTECT 2>/dev/null
    safe_ipt -N VPS_PROTECT

    # 3. Port range enforcement (ONLY 30000-35000 allowed)
    # Allow loopback
    safe_ipt -A VPS_PROTECT -i lo -j ACCEPT
    safe_ipt -A VPS_PROTECT -o lo -j ACCEPT
    # Allow established/related connections
    safe_ipt -A VPS_PROTECT -m state --state ESTABLISHED,RELATED -j ACCEPT
    # Allow only ports in range 30000-35000
    safe_ipt -A VPS_PROTECT -p tcp --dport ${PORT_RANGE_START}:${PORT_RANGE_END} -j ACCEPT
    safe_ipt -A VPS_PROTECT -p udp --dport ${PORT_RANGE_START}:${PORT_RANGE_END} -j ACCEPT
    # Block everything outside the allowed port range
    safe_ipt -A VPS_PROTECT -p tcp --dport 0:$((PORT_RANGE_START - 1)) -j DROP
    safe_ipt -A VPS_PROTECT -p tcp --dport $((PORT_RANGE_END + 1)):65535 -j DROP
    safe_ipt -A VPS_PROTECT -p udp --dport 0:$((PORT_RANGE_START - 1)) -j DROP
    safe_ipt -A VPS_PROTECT -p udp --dport $((PORT_RANGE_END + 1)):65535 -j DROP
    printf "${GREEN}  ✅  Port range: ONLY ${PORT_RANGE_START}-${PORT_RANGE_END} allowed${NC}\n"

    # 4. SYN flood
    safe_ipt -A VPS_PROTECT -p tcp --syn \
        -m hashlimit --hashlimit-name syn_flood \
        --hashlimit-above "$SYN_RATE" --hashlimit-burst "$SYN_BURST" \
        --hashlimit-mode srcip -j DROP
    printf "${GREEN}  ✅  SYN flood protection (${SYN_RATE})${NC}\n"

    # 5. UDP flood
    safe_ipt -A VPS_PROTECT -p udp \
        -m hashlimit --hashlimit-name udp_flood \
        --hashlimit-above "$UDP_RATE" --hashlimit-burst "$UDP_BURST" \
        --hashlimit-mode srcip -j DROP
    printf "${GREEN}  ✅  UDP flood protection (${UDP_RATE})${NC}\n"

    # 6. ICMP flood
    safe_ipt -A VPS_PROTECT -p icmp --icmp-type echo-request \
        -m hashlimit --hashlimit-name icmp_flood \
        --hashlimit-above "$ICMP_RATE" --hashlimit-burst "$ICMP_BURST" \
        --hashlimit-mode srcip -j DROP
    safe_ipt -A VPS_PROTECT -p icmp --icmp-type redirect -j DROP
    printf "${GREEN}  ✅  ICMP flood protection (${ICMP_RATE})${NC}\n"

    # 7. Port scan detection
    safe_ipt -A VPS_PROTECT -p tcp --tcp-flags ALL NONE -j DROP
    safe_ipt -A VPS_PROTECT -p tcp --tcp-flags ALL ALL -j DROP
    safe_ipt -A VPS_PROTECT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
    safe_ipt -A VPS_PROTECT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
    safe_ipt -A VPS_PROTECT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
    safe_ipt -A VPS_PROTECT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
    safe_ipt -A VPS_PROTECT -p tcp -m state --state NEW \
        -m recent --name PORTSCAN --set
    safe_ipt -A VPS_PROTECT -p tcp -m state --state NEW \
        -m recent --name PORTSCAN --update \
        --seconds "$PORTSCAN_SECONDS" --hitcount "$PORTSCAN_HITCOUNT" -j DROP
    printf "${GREEN}  ✅  Port scan detection & block${NC}\n"

    # 8. Amplification block
    safe_ipt -A VPS_PROTECT -p udp --dport 11211 -j DROP
    safe_ipt -A VPS_PROTECT -p udp --sport 53 -m length --length 512: -j DROP
    safe_ipt -A VPS_PROTECT -p udp --dport 19 -j DROP
    safe_ipt -A VPS_PROTECT -p udp --dport 1900 -j DROP
    safe_ipt -A VPS_PROTECT -p udp --dport 389 -j DROP
    printf "${GREEN}  ✅  Amplification block (Memcache/DNS/SSDP/Chargen/LDAP)${NC}\n"

    # 9. SMTP block
    safe_ipt -A VPS_PROTECT -p tcp --dport 25 -j DROP
    safe_ipt -A VPS_PROTECT -p tcp --dport 587 -j DROP
    safe_ipt -A VPS_PROTECT -p tcp --dport 465 -j DROP
    printf "${GREEN}  ✅  SMTP outbound block (anti-spam)${NC}\n"

    # 10. Connection limit
    safe_ipt -A VPS_PROTECT -p tcp -m connlimit \
        --connlimit-above "$CONN_LIMIT_PER_IP" --connlimit-mask 32 -j DROP
    printf "${GREEN}  ✅  Connection limit per IP (max ${CONN_LIMIT_PER_IP})${NC}\n"

    # 11. New connection rate
    safe_ipt -A VPS_PROTECT -p tcp -m state --state NEW \
        -m hashlimit --hashlimit-name new_conn \
        --hashlimit-above "$NEW_CONN_RATE" --hashlimit-burst 200 \
        --hashlimit-mode srcip -j DROP
    printf "${GREEN}  ✅  New connection rate limit (${NEW_CONN_RATE})${NC}\n"

    # 12. Invalid packets
    safe_ipt -A VPS_PROTECT -m state --state INVALID -j DROP
    printf "${GREEN}  ✅  Invalid packet drop${NC}\n"

    # 13. Bogon sources
    safe_ipt -A VPS_PROTECT -s 0.0.0.0/8 -j DROP
    safe_ipt -A VPS_PROTECT -s 127.0.0.0/8 ! -i lo -j DROP
    safe_ipt -A VPS_PROTECT -s 224.0.0.0/4 -j DROP
    safe_ipt -A VPS_PROTECT -s 240.0.0.0/4 -j DROP
    printf "${GREEN}  ✅  Bogon/spoofed source block${NC}\n"

    # Attach chain
    safe_ipt -D INPUT -j VPS_PROTECT 2>/dev/null
    safe_ipt -D OUTPUT -j VPS_PROTECT 2>/dev/null
    safe_ipt -I INPUT -j VPS_PROTECT
    safe_ipt -I OUTPUT -j VPS_PROTECT

    printf "\n${ORANGE}[☀️ SUNDY.SHIELD]${NC} All protection rules applied.\n\n"
}

# ── Status display ─────────────────────────────────────────────────────────
show_firewall_status() {
    printf "\n"
    printf "${DARK_ORANGE}╔═══════════════════════════════════════════════════════════════╗${NC}\n"
    printf "${DARK_ORANGE}║                                                               ║${NC}\n"
    printf "${DARK_ORANGE}║          ${WHITE}${BOLD}🛡️  SUNDY.SHIELD — FIREWALL STATUS  🛡️${DARK_ORANGE}            ║${NC}\n"
    printf "${DARK_ORANGE}║                                                               ║${NC}\n"
    printf "${DARK_ORANGE}╠═══════════════════════════════════════════════════════════════╣${NC}\n"
    printf "${DARK_ORANGE}║                                                               ║${NC}\n"

    _check_rule() {
        label="$1"
        check="$2"
        if iptables -L VPS_PROTECT 2>/dev/null | grep -qi "$check"; then
            printf "${DARK_ORANGE}║  ${GREEN}● ACTIVE${NC}    %-46s${DARK_ORANGE}║${NC}\n" "$label"
        else
            printf "${DARK_ORANGE}║  ${RED}○ INACTIVE${NC}  %-46s${DARK_ORANGE}║${NC}\n" "$label"
        fi
    }

    _check_rule "Port Range (${PORT_RANGE_START}-${PORT_RANGE_END})"  "${PORT_RANGE_START}"
    _check_rule "SYN Flood Protection"         "syn_flood"
    _check_rule "UDP Flood Protection"         "udp_flood"
    _check_rule "ICMP Flood Protection"        "icmp_flood"
    _check_rule "Port Scan Detection"          "PORTSCAN"
    _check_rule "Amplification Block"          "dpt:11211"
    _check_rule "SMTP Block (Anti-Spam)"       "dpt:smtp"
    _check_rule "Connection Limit per IP"      "connlimit"
    _check_rule "New Connection Rate Limit"    "new_conn"
    _check_rule "Invalid Packet Drop"          "INVALID"
    _check_rule "Bogon Source Block"           "0.0.0.0"

    printf "${DARK_ORANGE}║                                                               ║${NC}\n"
    printf "${DARK_ORANGE}╠═══════════════════════════════════════════════════════════════╣${NC}\n"

    printf "${DARK_ORANGE}║                                                               ║${NC}\n"
    if command -v tc >/dev/null 2>&1; then
        IFACE=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
        if tc class show dev "$IFACE" 2>/dev/null | grep -q "htb"; then
            printf "${DARK_ORANGE}║  ${GREEN}● ACTIVE${NC}    Bandwidth Limit: %-25s${DARK_ORANGE}║${NC}\n" "$BANDWIDTH_LIMIT"
        else
            printf "${DARK_ORANGE}║  ${RED}○ INACTIVE${NC}  Bandwidth Limit${DARK_ORANGE}                              ║${NC}\n"
        fi
    else
        printf "${DARK_ORANGE}║  ${AMBER}⚠ N/A${NC}       Bandwidth Limit (tc unavailable)${DARK_ORANGE}            ║${NC}\n"
    fi

    printf "${DARK_ORANGE}║                                                               ║${NC}\n"
    printf "${DARK_ORANGE}╚═══════════════════════════════════════════════════════════════╝${NC}\n"
    printf "\n"

    dropped=$(iptables -L VPS_PROTECT -v -n 2>/dev/null | awk '/DROP/ {total+=$1} END {print total+0}')
    if [ "$dropped" -gt 0 ] 2>/dev/null; then
        printf "${AMBER}  📊 Total blocked packets: ${WHITE}${BOLD}${dropped}${NC}\n"
    fi
    printf "\n"
}
