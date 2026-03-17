#!/bin/sh
# ============================================================================
#  install.sh — Sundy.Host VPS | Interactive OS selection + version picker
# ============================================================================

. /common.sh

ROOTFS_DIR="/home/container"
BASE_URL="https://images.linuxcontainers.org/images"

export PATH="$PATH:~/.local/usr/bin"

# Format: "number:display_name:distro_id:is_custom:post_config:icon"
distributions="
1:Debian:debian:false::
2:Ubuntu:ubuntu:false::
3:Alpine Linux:alpine:false::
4:CentOS:centos:false::
5:Rocky Linux:rockylinux:false::
6:Fedora:fedora:false::
7:Arch Linux:archlinux:false:archlinux:
8:Kali Linux:kali:false::
9:AlmaLinux:almalinux:false::
10:Void Linux:voidlinux:true::
11:openSUSE:opensuse:false::
12:Gentoo Linux:gentoo:true::
13:Devuan Linux:devuan:false::
14:Oracle Linux:oracle:false::
15:Slackware:slackware:false::
16:Amazon Linux:amazonlinux:false::
17:Linux Mint:mint:false::
18:Plamo Linux:plamo:false::
"

num_distros=$(printf '%s' "$distributions" | grep -c "^[0-9]")

error_exit() {
    log "ERROR" "$1" "$RED"
    exit 1
}

ARCH=$(uname -m)
ARCH_ALT=$(detect_architecture)

check_network() {
    if ! curl -s --head "$BASE_URL" >/dev/null; then
        error_exit "Unable to reach image server. Check your internet connection."
    fi
}

cleanup() {
    log "INFO" "Cleaning up..." "$YELLOW"
    rm -f "$ROOTFS_DIR/rootfs.tar.xz" "$ROOTFS_DIR/rootfs.tar.gz"
    rm -rf /tmp/sbin
}

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

    if ! curl -s "$arch_url" | grep -q "$ARCH_ALT"; then
        error_exit "This distro doesn't support ${ARCH_ALT} architecture."
    fi

    latest_version=$(curl -s "$url" | grep 'href="' | grep -o '[0-9]\{8\}_[0-9]\{2\}:[0-9]\{2\}/' | sort -r | head -n 1) ||
    error_exit "Failed to determine latest version"

    P ""
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

install() {
    distro_name="$1"
    pretty_name="$2"
    is_custom="$3"

    [ -z "$is_custom" ] && is_custom="false"

    log "INFO" "Preparing ${pretty_name}..." "$ORANGE"

    if [ "$is_custom" = "true" ]; then
        url_path="${BASE_URL}/${distro_name}/current/${ARCH_ALT}/"
    else
        url_path="${BASE_URL}/${distro_name}/"
    fi

    image_names=$(curl -s "$url_path" | grep 'href="' | grep -o '"[^/"]*/"' | tr -d '"/' | grep -v '^\.\.$') ||
    error_exit "Failed to fetch versions for ${pretty_name}"

    temp_file="/tmp/install_versions.$$"
    printf '%s\n' "$image_names" > "$temp_file"
    version_count=$(grep -c . "$temp_file")

    [ "$version_count" -eq 0 ] && error_exit "No versions available for ${pretty_name}"

    if [ "$version_count" -eq 1 ]; then
        version=1
    else
        P ""
        P "${ORANGE}  Select ${pretty_name} version:${NC}"
        P ""

        counter=1
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                P "    ${LIGHT_ORANGE}[${WHITE}${BOLD}${counter}${NC}${LIGHT_ORANGE}]${NC}  ${pretty_name} ${AMBER}${BOLD}${line}${NC}"
                counter=$((counter + 1))
            fi
        done < "$temp_file"

        P "    ${LIGHT_ORANGE}[${WHITE}${BOLD}0${NC}${LIGHT_ORANGE}]${NC}  ${RED}<- Go Back${NC}"

        version=""
        while true; do
            P ""
            printf '%b' "${AMBER}  Enter version (0-${version_count}): ${NC}"
            read -r version
            if [ "$version" = "0" ]; then
                rm -f "$temp_file"
                exec "$0"
            elif printf '%s' "$version" | grep -q '^[0-9]*$' && [ "$version" -ge 1 ] && [ "$version" -le "${version_count}" ]; then
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

get_distro_data() {
    selection="$1"
    printf '%s' "$distributions" | while IFS= read -r line; do
        if [ -n "$line" ]; then
            number=$(printf '%s' "$line" | cut -d: -f1)
            if [ "$number" = "$selection" ]; then
                printf '%s' "$line"
                break
            fi
        fi
    done
}

post_install_config() {
    case "$1" in
        "archlinux")
            log "INFO" "Configuring Arch Linux..." "$ORANGE"
            sed -i '/^#RootDir/s/^#//' "$ROOTFS_DIR/etc/pacman.conf" 2>/dev/null
            sed -i 's|/var/lib/pacman/|/var/lib/pacman|' "$ROOTFS_DIR/etc/pacman.conf" 2>/dev/null
            sed -i '/^#DBPath/s/^#//' "$ROOTFS_DIR/etc/pacman.conf" 2>/dev/null
        ;;
    esac
}

display_menu() {
    print_main_banner

    P "${ORANGE}  Choose your operating system:${NC}"
    P ""

    printf '%s\n' "$distributions" | while IFS= read -r line; do
        if [ -n "$line" ]; then
            number=$(printf '%s' "$line" | cut -d: -f1)
            display_name=$(printf '%s' "$line" | cut -d: -f2)
            P "    ${LIGHT_ORANGE}[${WHITE}${BOLD}${number}${NC}${LIGHT_ORANGE}]${NC}  ${display_name}"
        fi
    done

    P ""
    printf '%b' "${AMBER}  Enter distro number (1-${num_distros}): ${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════

check_network
display_menu

read -r selection

distro_data=$(get_distro_data "$selection")

if [ -z "$distro_data" ]; then
    error_exit "Invalid selection (1-${num_distros})"
fi

number=$(printf '%s' "$distro_data" | cut -d: -f1)
display_name=$(printf '%s' "$distro_data" | cut -d: -f2)
distro_id=$(printf '%s' "$distro_data" | cut -d: -f3)
flag=$(printf '%s' "$distro_data" | cut -d: -f4)
post_config=$(printf '%s' "$distro_data" | cut -d: -f5)

install "$distro_id" "$display_name" "$flag"

if [ -n "$post_config" ]; then
    post_install_config "$post_config"
fi

cp /common.sh /run.sh /firewall.sh "$ROOTFS_DIR"
chmod +x "$ROOTFS_DIR/common.sh" "$ROOTFS_DIR/run.sh" "$ROOTFS_DIR/firewall.sh"

trap cleanup EXIT

log "SUCCESS" "Installation complete! Sundy.Host VPS is starting..." "$GREEN"
sleep 2
