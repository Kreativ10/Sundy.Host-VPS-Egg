#!/bin/sh
# ============================================================================
#  firewall.sh — Sundy.Host VPS | DDoS protection + bandwidth limit
#  NOTE: Requires CAP_NET_ADMIN on the Docker container to work.
# ============================================================================

BANDWIDTH_LIMIT="100mbit"
BURST_LIMIT="15mbit"
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

# Safe print function (same as common.sh P)
_P() {
    printf '%b\n' "$1"
}

FW_BW_ACTIVE=0
FW_IPT_ACTIVE=0

safe_ipt() {
    if iptables "$@" 2>/dev/null; then
        return 0
    fi
    return 1
}

apply_firewall() {
    _P "${ORANGE}[SUNDY.SHIELD]${NC} Applying protection..."

    # Bandwidth limit
    if command -v tc >/dev/null 2>&1; then
        IFACE=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
        if [ -n "$IFACE" ]; then
            tc qdisc del dev "$IFACE" root 2>/dev/null
            if tc qdisc add dev "$IFACE" root handle 1: htb default 10 2>/dev/null && \
               tc class add dev "$IFACE" parent 1: classid 1:10 htb rate "$BANDWIDTH_LIMIT" burst "$BURST_LIMIT" 2>/dev/null; then
                _P "${GREEN}  [OK] Bandwidth: ${BANDWIDTH_LIMIT}${NC}"
                FW_BW_ACTIVE=1
            else
                _P "${AMBER}  [--] Bandwidth: needs CAP_NET_ADMIN${NC}"
            fi
        fi
    else
        _P "${AMBER}  [--] Bandwidth: tc not found${NC}"
    fi

    # iptables rules
    if iptables -L -n >/dev/null 2>&1; then
        FW_IPT_ACTIVE=1

        safe_ipt -F VPS_PROTECT
        safe_ipt -X VPS_PROTECT
        safe_ipt -N VPS_PROTECT

        safe_ipt -A VPS_PROTECT -i lo -j ACCEPT
        safe_ipt -A VPS_PROTECT -o lo -j ACCEPT
        safe_ipt -A VPS_PROTECT -m state --state ESTABLISHED,RELATED -j ACCEPT

        safe_ipt -A VPS_PROTECT -p tcp --dport ${PORT_RANGE_START}:${PORT_RANGE_END} -j ACCEPT
        safe_ipt -A VPS_PROTECT -p udp --dport ${PORT_RANGE_START}:${PORT_RANGE_END} -j ACCEPT
        safe_ipt -A VPS_PROTECT -p tcp --dport 0:$((PORT_RANGE_START - 1)) -j DROP
        safe_ipt -A VPS_PROTECT -p tcp --dport $((PORT_RANGE_END + 1)):65535 -j DROP
        safe_ipt -A VPS_PROTECT -p udp --dport 0:$((PORT_RANGE_START - 1)) -j DROP
        safe_ipt -A VPS_PROTECT -p udp --dport $((PORT_RANGE_END + 1)):65535 -j DROP
        _P "${GREEN}  [OK] Ports: ${PORT_RANGE_START}-${PORT_RANGE_END} only${NC}"

        safe_ipt -A VPS_PROTECT -p tcp --syn \
            -m hashlimit --hashlimit-name syn_flood \
            --hashlimit-above "$SYN_RATE" --hashlimit-burst "$SYN_BURST" \
            --hashlimit-mode srcip -j DROP
        _P "${GREEN}  [OK] SYN flood protection${NC}"

        safe_ipt -A VPS_PROTECT -p udp \
            -m hashlimit --hashlimit-name udp_flood \
            --hashlimit-above "$UDP_RATE" --hashlimit-burst "$UDP_BURST" \
            --hashlimit-mode srcip -j DROP
        _P "${GREEN}  [OK] UDP flood protection${NC}"

        safe_ipt -A VPS_PROTECT -p icmp --icmp-type echo-request \
            -m hashlimit --hashlimit-name icmp_flood \
            --hashlimit-above "$ICMP_RATE" --hashlimit-burst "$ICMP_BURST" \
            --hashlimit-mode srcip -j DROP
        safe_ipt -A VPS_PROTECT -p icmp --icmp-type redirect -j DROP
        _P "${GREEN}  [OK] ICMP flood protection${NC}"

        safe_ipt -A VPS_PROTECT -p tcp --tcp-flags ALL NONE -j DROP
        safe_ipt -A VPS_PROTECT -p tcp --tcp-flags ALL ALL -j DROP
        safe_ipt -A VPS_PROTECT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
        safe_ipt -A VPS_PROTECT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
        safe_ipt -A VPS_PROTECT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
        _P "${GREEN}  [OK] Port scan detection${NC}"

        safe_ipt -A VPS_PROTECT -p udp --dport 11211 -j DROP
        safe_ipt -A VPS_PROTECT -p udp --dport 19 -j DROP
        safe_ipt -A VPS_PROTECT -p udp --dport 1900 -j DROP
        safe_ipt -A VPS_PROTECT -p udp --dport 389 -j DROP
        _P "${GREEN}  [OK] Amplification block${NC}"

        safe_ipt -A VPS_PROTECT -p tcp --dport 25 -j DROP
        safe_ipt -A VPS_PROTECT -p tcp --dport 587 -j DROP
        safe_ipt -A VPS_PROTECT -p tcp --dport 465 -j DROP
        _P "${GREEN}  [OK] SMTP block${NC}"

        safe_ipt -A VPS_PROTECT -p tcp -m connlimit \
            --connlimit-above "$CONN_LIMIT_PER_IP" --connlimit-mask 32 -j DROP
        _P "${GREEN}  [OK] Connection limit (${CONN_LIMIT_PER_IP}/IP)${NC}"

        safe_ipt -A VPS_PROTECT -p tcp -m state --state NEW \
            -m hashlimit --hashlimit-name new_conn \
            --hashlimit-above "$NEW_CONN_RATE" --hashlimit-burst 200 \
            --hashlimit-mode srcip -j DROP
        _P "${GREEN}  [OK] New connection rate limit${NC}"

        safe_ipt -A VPS_PROTECT -m state --state INVALID -j DROP
        safe_ipt -A VPS_PROTECT -s 0.0.0.0/8 -j DROP
        safe_ipt -A VPS_PROTECT -s 224.0.0.0/4 -j DROP
        safe_ipt -A VPS_PROTECT -s 240.0.0.0/4 -j DROP
        _P "${GREEN}  [OK] Invalid + bogon block${NC}"

        safe_ipt -D INPUT -j VPS_PROTECT 2>/dev/null
        safe_ipt -D OUTPUT -j VPS_PROTECT 2>/dev/null
        safe_ipt -I INPUT -j VPS_PROTECT
        safe_ipt -I OUTPUT -j VPS_PROTECT
    else
        _P "${AMBER}  [--] iptables: needs CAP_NET_ADMIN${NC}"
        _P "${AMBER}  [--] Ask host admin to enable CAP_NET_ADMIN${NC}"
    fi

    _P "${ORANGE}[SUNDY.SHIELD]${NC} Done."
    _P ""
}

show_firewall_status() {
    _P ""
    _P "${DARK_ORANGE}╔════════════════════════════════════════════════════════╗${NC}"
    _P "${DARK_ORANGE}║                                                        ║${NC}"
    _P "${DARK_ORANGE}║      ${WHITE}${BOLD}SUNDY.SHIELD --- FIREWALL STATUS${NC}${DARK_ORANGE}               ║${NC}"
    _P "${DARK_ORANGE}║                                                        ║${NC}"
    _P "${DARK_ORANGE}╠════════════════════════════════════════════════════════╣${NC}"
    _P "${DARK_ORANGE}║                                                        ║${NC}"

    if [ "$FW_IPT_ACTIVE" = "1" ] && iptables -L VPS_PROTECT -n >/dev/null 2>&1; then
        _P "${DARK_ORANGE}║  ${GREEN}ACTIVE${NC}   iptables firewall"

        _cr() {
            if iptables -L VPS_PROTECT -n 2>/dev/null | grep -qi "$2"; then
                _P "${DARK_ORANGE}║    ${GREEN}+${NC} $1"
            else
                _P "${DARK_ORANGE}║    ${RED}-${NC} $1"
            fi
        }
        _cr "Port range 30000-35000" "${PORT_RANGE_START}"
        _cr "SYN flood protection"  "syn_flood"
        _cr "UDP flood protection"  "udp_flood"
        _cr "ICMP flood protection" "icmp_flood"
        _cr "Port scan detection"   "SYN,RST"
        _cr "Amplification block"   "dpt:11211"
        _cr "SMTP block"            "dpt:25"
        _cr "Connection limit"      "connlimit"
        _cr "Rate limit"            "new_conn"
        _cr "Invalid/bogon block"   "INVALID"
    else
        _P "${DARK_ORANGE}║  ${RED}INACTIVE${NC} iptables (no CAP_NET_ADMIN)"
    fi

    _P "${DARK_ORANGE}║                                                        ║${NC}"

    if [ "$FW_BW_ACTIVE" = "1" ]; then
        _P "${DARK_ORANGE}║  ${GREEN}ACTIVE${NC}   Bandwidth limit: ${BANDWIDTH_LIMIT}"
    else
        _P "${DARK_ORANGE}║  ${RED}INACTIVE${NC} Bandwidth limit (no CAP_NET_ADMIN)"
    fi

    _P "${DARK_ORANGE}║                                                        ║${NC}"
    _P "${DARK_ORANGE}╚════════════════════════════════════════════════════════╝${NC}"
    _P ""

    if [ "$FW_IPT_ACTIVE" = "0" ] && [ "$FW_BW_ACTIVE" = "0" ]; then
        _P "${AMBER}  NOTE: Protection requires CAP_NET_ADMIN capability.${NC}"
        _P "${AMBER}  Contact your hosting admin to enable it.${NC}"
        _P ""
    fi
}
