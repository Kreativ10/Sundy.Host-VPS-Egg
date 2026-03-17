#!/bin/sh
# ============================================================================
#  install.sh — Sundy.Host VPS | Interactive OS selection + version picker
# ============================================================================

# Source common functions
. /common.sh

# ── Configuration ───────────────────────────────────────────────────────────
ROOTFS_DIR="/home/container"
BASE_URL="https://images.linuxcontainers.org/images"

export PATH="$PATH:~/.local/usr/bin"

# ── Distribution list ───────────────────────────────────────────────────────
# Format: "number:display_name:distro_id:is_custom:post_config:icon"
distributions="
1:Debian:debian:false::🟥
2:Ubuntu:ubuntu:false::🟠
3:Alpine Linux:alpine:false::🔵
4:CentOS:centos:false::🟣
5:Rocky Linux:rockylinux:false::🟩
6:Fedora:fedora:false::🔷
7:Arch Linux:archlinux:false:archlinux:🔶
8:Kali Linux:kali:false::⬛
9:AlmaLinux:almalinux:false::🟤
10:Void Linux:voidlinux:true::🟢
11:openSUSE:opensuse:false::🟦
12:Gentoo Linux:gentoo:true::🟪
13:Devuan Linux:devuan:false::⬜
14:Oracle Linux:oracle:false::🔴
15:Slackware:slackware:false::⚫
16:Amazon Linux:amazonlinux:false::🟡
17:Linux Mint:mint:false::💚
18:Plamo Linux:plamo:false::🔘
"

num_distros=$(echo "$distributions" | grep -c "^[0-9]")

# ── Error handling ──────────────────────────────────────────────────────────
error_exit() {
    log "ERROR" "$1" "$RED"
    exit 1
}

# ── Architecture ────────────────────────────────────────────────────────────
ARCH=$(uname -m)
ARCH_ALT=$(detect_architecture)

# ── Network check ───────────────────────────────────────────────────────────
check_network() {
    if ! curl -s --head "$BASE_URL" >/dev/null; then
        error_exit "Unable to reach image server. Check your internet connection."
    fi
}

# ── Cleanup ─────────────────────────────────────────────────────────────────
cleanup() {
    log "INFO" "Cleaning up temporary files..." "$YELLOW"
    rm -f "$ROOTFS_DIR/rootfs.tar.xz" "$ROOTFS_DIR/rootfs.tar.gz"
    rm -rf /tmp/sbin
}

# ── Download & extract rootfs ──────────────────────────────────────────────
download_and_extract_rootfs() {
    distro_name="$1"
    version="$2"
    is_custom="$3"

    if [ "$is_custom" = "true" ]; then
        arch_url="${BASE_URL}/${distro_name}/current/"
        url="${BASE_URL}/${distro_name}/current/${ARCH_ALT}/${version}/"
    else
        arch_url="${BASE_URL}/${distro_name}/${version}/"
        url="${BASE_URL}/${distro_name}/${version}/${ARCH_ALT}/default/"
    fi

    # Check architecture support
    if ! curl -s "$arch_url" | grep -q "$ARCH_ALT"; then
        error_exit "This distro doesn't support $ARCH_ALT architecture."
    fi

    # Get latest build
    latest_version=$(curl -s "$url" | grep 'href="' | grep -o '[0-9]\{8\}_[0-9]\{2\}:[0-9]\{2\}/' | sort -r | head -n 1) ||
    error_exit "Failed to determine latest version"

    printf "\n"
    log "INFO" "Downloading rootfs..." "$ORANGE"
    mkdir -p "$ROOTFS_DIR"

    if ! curl -Ls "${url}${latest_version}rootfs.tar.xz" -o "$ROOTFS_DIR/rootfs.tar.xz"; then
        error_exit "Failed to download rootfs"
    fi

    log "INFO" "Extracting rootfs (this may take a moment)..." "$ORANGE"
    if ! tar -xf "$ROOTFS_DIR/rootfs.tar.xz" -C "$ROOTFS_DIR"; then
        error_exit "Failed to extract rootfs"
    fi

    rm -f "$ROOTFS_DIR/etc/resolv.conf"
    mkdir -p "$ROOTFS_DIR/home/container/"
}

# ── Install distro with version selection ──────────────────────────────────
install() {
    distro_name="$1"
    pretty_name="$2"
    is_custom="$3"

    if [ -z "$is_custom" ]; then
        is_custom="false"
    fi

    log "INFO" "Preparing ${pretty_name}..." "$ORANGE"

    if [ "$is_custom" = "true" ]; then
        url_path="${BASE_URL}/${distro_name}/current/${ARCH_ALT}/"
    else
        url_path="${BASE_URL}/${distro_name}/"
    fi

    # Fetch available versions
    image_names=$(curl -s "$url_path" | grep 'href="' | grep -o '"[^/"]*/"' | tr -d '"/' | grep -v '^\.\.$') ||
    error_exit "Failed to fetch versions for ${pretty_name}"

    temp_file="/tmp/install_versions.$$"
    echo "$image_names" > "$temp_file"
    version_count=$(grep -c . "$temp_file")

    if [ "$version_count" -eq 0 ]; then
        error_exit "No versions available for ${pretty_name}"
    fi

    if [ "$version_count" -eq 1 ]; then
        version=1
    else
        # ── Version selection menu ──────────────────────────────────────
        printf "\n"
        printf "${ORANGE}  ┌─────────────────────────────────────────────┐${NC}\n"
        printf "${ORANGE}  │  ${WHITE}${BOLD}Select ${pretty_name} version:${ORANGE}$(printf '%*s' $((27 - ${#pretty_name})) '')│${NC}\n"
        printf "${ORANGE}  └─────────────────────────────────────────────┘${NC}\n"
        printf "\n"

        counter=1
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                printf "    ${LIGHT_ORANGE}[${WHITE}${BOLD}%2d${NC}${LIGHT_ORANGE}]${NC}  %s ${AMBER}%s${NC}\n" "$counter" "$pretty_name" "$line"
                counter=$((counter + 1))
            fi
        done < "$temp_file"

        printf "    ${LIGHT_ORANGE}[${WHITE}${BOLD} 0${NC}${LIGHT_ORANGE}]${NC}  ${RED}← Go Back${NC}\n"
        printf "\n"

        version=""
        while true; do
            printf "${AMBER}  ☀️  Enter version (0-${version_count}): ${NC}\n"
            read -r version
            if [ "$version" = "0" ]; then
                rm -f "$temp_file"
                exec "$0"
            elif echo "$version" | grep -q '^[0-9]*$' && [ "$version" -ge 1 ] && [ "$version" -le "${version_count}" ]; then
                break
            fi
            log "ERROR" "Invalid selection. Try again." "$RED"
        done
    fi

    selected_version=$(sed -n "${version}p" "$temp_file")
    rm -f "$temp_file"

    log "INFO" "Selected: ${pretty_name} ${selected_version}" "$GREEN"

    download_and_extract_rootfs "$distro_name" "$selected_version" "$is_custom"
}

# ── Parse distro data ──────────────────────────────────────────────────────
get_distro_data() {
    selection="$1"
    echo "$distributions" | while IFS= read -r line; do
        if [ -n "$line" ]; then
            number=$(echo "$line" | cut -d: -f1)
            if [ "$number" = "$selection" ]; then
                echo "$line"
                break
            fi
        fi
    done
}

# ── Post-install config ────────────────────────────────────────────────────
post_install_config() {
    distro="$1"
    case "$distro" in
        "archlinux")
            log "INFO" "Configuring Arch Linux..." "$ORANGE"
            sed -i '/^#RootDir/s/^#//' "$ROOTFS_DIR/etc/pacman.conf" 2>/dev/null
            sed -i 's|/var/lib/pacman/|/var/lib/pacman|' "$ROOTFS_DIR/etc/pacman.conf" 2>/dev/null
            sed -i '/^#DBPath/s/^#//' "$ROOTFS_DIR/etc/pacman.conf" 2>/dev/null
        ;;
    esac
}

# ── Display distro menu ────────────────────────────────────────────────────
display_menu() {
    print_main_banner

    printf "${ORANGE}  ┌─────────────────────────────────────────────┐${NC}\n"
    printf "${ORANGE}  │    ${WHITE}${BOLD}☀️  Choose your operating system:${ORANGE}         │${NC}\n"
    printf "${ORANGE}  └─────────────────────────────────────────────┘${NC}\n"
    printf "\n"

    echo "$distributions" | while IFS= read -r line; do
        if [ -n "$line" ]; then
            number=$(echo "$line" | cut -d: -f1)
            display_name=$(echo "$line" | cut -d: -f2)
            icon=$(echo "$line" | cut -d: -f6)
            [ -z "$icon" ] && icon="🐧"
            printf "    ${icon}  ${LIGHT_ORANGE}[${WHITE}${BOLD}%2s${NC}${LIGHT_ORANGE}]${NC}  %-20s\n" "$number" "$display_name"
        fi
    done

    printf "\n"
    printf "${AMBER}  ☀️  Enter the distro number (1-${num_distros}): ${NC}\n"
}

# ═══════════════════════════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════════════════════════

check_network
display_menu

read -r selection

distro_data=$(get_distro_data "$selection")

if [ -z "$distro_data" ]; then
    error_exit "Invalid selection (1-${num_distros})"
fi

number=$(echo "$distro_data" | cut -d: -f1)
display_name=$(echo "$distro_data" | cut -d: -f2)
distro_id=$(echo "$distro_data" | cut -d: -f3)
flag=$(echo "$distro_data" | cut -d: -f4)
post_config=$(echo "$distro_data" | cut -d: -f5)

install "$distro_id" "$display_name" "$flag"

if [ -n "$post_config" ]; then
    post_install_config "$post_config"
fi

# Copy scripts into rootfs
cp /common.sh /run.sh /firewall.sh "$ROOTFS_DIR"
chmod +x "$ROOTFS_DIR/common.sh" "$ROOTFS_DIR/run.sh" "$ROOTFS_DIR/firewall.sh"

trap cleanup EXIT

log "SUCCESS" "Installation complete! Sundy.Host VPS is starting..." "$GREEN"
sleep 2
