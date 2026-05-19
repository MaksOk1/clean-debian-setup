#!/usr/bin/env bash
set -euo pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log_info() { echo -e "${YELLOW}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_err() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
die() { log_err "$1"; exit 1; }

[ "$EUID" -ne 0 ] && die "Please, re-run script as root (sudo)."

USER=${1:-}
URL=${2:-}

if [ -z "$USER" ]; then
    while true; do
        read -rp "Make system changes for user (enter username): " USER

        [ -n "$USER" ] && break

        log_err "Set 'USER' variable to continue."
    done
fi

if [ -z "$URL" ]; then
    read -rp "Enter base config URL (default: https://raw.githubusercontent.com/MaksOk1/clean-debian-setup/main): " URL
    URL=${URL:-https://raw.githubusercontent.com/MaksOk1/clean-debian-setup/main}
fi

readonly OMZ_DIR="/usr/share/oh-my-zsh"

download_file() {
    local src_url="$1"
    local dest_path="$2"
    log_info "Downloading: $src_url -> $dest_path"
    curl -sSf "$src_url" > "$dest_path" || die "Failed to download $src_url"
}

log_info "Downloading configurations..."


mkdir -vp /etc/skel
download_file "$URL/rs/etc/skel/.zshrc" /etc/skel/.zshrc

if [ -n "$USER" ]; then
    if id "$USER" &>/dev/null; then
        USER_HOME=$(getent passwd "$USER" | cut -d: -f6)
        cp /etc/skel/.zshrc "$USER_HOME/.zshrc" || die "Failed to copy .zshrc to $USER_HOME"
        chown "$USER:$USER" "$USER_HOME/.zshrc" || die "Failed to change owner of .zshrc for $USER"
        log_success ".zshrc configured for user $USER."
    else
        log_err "User $USER does not exist. Skipping user-specific .zshrc setup."
    fi
fi

mkdir -vp /etc/systemd/logind.conf.d/
download_file "$URL/rs/etc/systemd/logind.conf" /etc/systemd/logind.conf.d/custom.conf

mkdir -vp /etc/systemd/sleep.conf.d/
download_file "$URL/rs/etc/systemd/sleep.conf.d/nosuspend.conf" /etc/systemd/sleep.conf.d/nosuspend.conf

mkdir -vp /etc/ssh/sshd_config.d/
download_file "$URL/rs/etc/ssh/sshd_config.d/00-basic.conf" /etc/ssh/sshd_config.d/00-basic.conf

log_info "Setting up Oh My Zsh..."
if [ -d "$OMZ_DIR/.git" ]; then
    log_info "Oh My Zsh already exists. Pulling latest updates..."
    git -C "$OMZ_DIR" pull || die "Failed to pull OMZ updates."
else
    [ -d "$OMZ_DIR" ] && rm -rf "$OMZ_DIR"
    git clone https://github.com/ohmyzsh/ohmyzsh.git "$OMZ_DIR" || die "Failed to clone OMZ."
fi
log_success "Oh My Zsh is ready."

log_info "Updating GRUB timeout..."
while true; do
    if [ "${AUTO:-0}" = "1" ]; then
        grub_timeout=2
    else
        read -p "Enter GRUB timeout for system startup (default: 2): " grub_timeout
        grub_timeout=${grub_timeout:-2}
    fi

    if [[ "$grub_timeout" =~ ^[0-9]+$ ]]; then
        mkdir -vp /etc/default
        [ ! -f "/etc/default/grub" ] && touch /etc/default/grub
        
        if grep -q "^GRUB_TIMEOUT=" /etc/default/grub; then
            sed -i "s/GRUB_TIMEOUT=.*$/GRUB_TIMEOUT=$grub_timeout/" /etc/default/grub
        else
            echo "GRUB_TIMEOUT=$grub_timeout" >> /etc/default/grub
        fi

        log_info "Applying GRUB changes..."
        if command -v update-grub &>/dev/null; then
            update-grub || die "update-grub command failed."
        else
            grub-mkconfig -o /boot/grub/grub.cfg || die "grub-mkconfig command failed."
        fi

        log_success "GRUB timeout successfully set to '$grub_timeout' seconds."
        break
    else
        log_err "Please enter a valid number."
    fi
done

log_success "All system configurations successfully applied!"