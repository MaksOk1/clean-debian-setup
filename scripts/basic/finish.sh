#!/usr/bin/env bash
set -euo pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_err()     { echo -e "${RED}[ERROR]${NC} $1" >&2; }
die()         { log_err "$1"; exit 1; }

[ "$EUID" -ne 0 ] && die "Please, re-run script as root (sudo)."

USER=${1:-}

if [ -z "$USER" ]; then
    while true; do
        read -rp "Finish system set-up for user (enter username): " USER

        if [ -n "$USER" ]; then
            break
        fi

        log_warning "Set 'USER' variable to continue."
    done
fi

if [ "${AUTO:-0}" = "1" ]; then
    restart_systemd_login_service="N"
else
    read -rp "Restart 'systemd-logind' service? [y/N]: " restart_systemd_login_service
    restart_systemd_login_service=${restart_systemd_login_service:-N}
fi

if [[ "$restart_systemd_login_service" =~ ^[Yy]$ ]]; then
    log_info "Restarting 'systemd-logind' service..."
    systemctl restart systemd-logind.service

    if systemctl is-active --quiet systemd-logind.service; then
        log_success "Restarted service successfully!" # Need to make sure that it's correctly restarted. Maybe if pipe falls - echo will not be shown?
    else
        log_warning "'systemd-logind' is not running properly!"
    fi
fi

if [ "${AUTO:-0}" = "1" ]; then
    restart_ssh_services="Y"
else
    read -rp "Restart 'ssh' and 'sshd' services? [Y/n]: " restart_ssh_services
    restart_ssh_services=${restart_ssh_services:-Y}
fi

if [[ "$restart_ssh_services" =~ ^[Yy]$ ]]; then
    for service in ssh sshd; do
        if systemctl is-active "$service" >/dev/null 2>&1 || systemctl is-enabled "$service" >/dev/null 2>&1; then
            systemctl restart "$service"
            log_info "Service '$service' restarted."
        fi
    done
        log_success "SSH services restarted!"
fi

log_info "Copying '/etc/zsh/zshrc' to root's and user's ($USER's) home directories.."
if [ -f /etc/zsh/zshrc ]; then
    mkdir -vp /root /home/"$USER"
    cp /etc/zsh/zshrc /root/.zshrc
    cp /etc/zsh/zshrc /home/$USER/.zshrc
    chown "$USER":"$USER" /home/"$USER"/.zshrc
    log_success "Copied!"
else
    log_warning "'/etc/zsh/zshrc' not found. Skipping copying..."
fi

# update-grub
# update-grub2
if command -v update-grub &>/dev/null; then
    update-grub
else
    log_warning "'update-grub' utility not found, try confirming changes to grub with: 'sudo grub-mkconfig -o /boot/grub/grub.cfg' or 'sudo grub2-mkconfig -o /boot/grub2/grub.cfg' or 'sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg'"
    log_warning "Shortcut adding option will be displayed..."

    if [ "${AUTO:-0}" = "1" ]; then
        set_debian_shortcut="N"
    else
        read -rp "Set-up custom shortcut for 'update-grub' (debian)? [y/N]: " set_debian_shortcut
        set_debian_shortcut=${set_debian_shortcut:-N}
    fi

    if [[ "$set_debian_shortcut" =~ ^[Yy]$ ]]; then
        cat << 'EOF' > /usr/sbin/update-grub
#!/bin/sh
set -e
exec grub-mkconfig -o /boot/grub/grub.cfg "$@"
EOF
        chmod +x /usr/sbin/update-grub
        log_success "Shortcut on '/usr/sbin/update-grub' created (and 'chmod +x ...' executed)!"
        log_warning "Maybe terminal restart will be needed, or try: 'hash -r'"
    fi
fi

if [ "${AUTO:-0}" = "1" ]; then
    change_both_shell="Y"
else
    read -rp "Change default shell to ZSH for root and user ($USER)? [Y/n]: " change_both_shell
    change_both_shell=${change_both_shell:-Y}
fi

ZSH_PATH=$(command -v zsh || echo "/usr/bin/zsh") # or /bin/zsh

if [[ "$change_both_shell" =~ ^[Yy]$ ]]; then
    chsh -s "$ZSH_PATH" "$USER"
    chsh -s "$ZSH_PATH" root
    log_success "Changed default shell for root and user ($USER)!"
else
    if [ "${AUTO:-0}" = "1" ]; then
        change_user_shell="Y"
    else
        read -rp "Change default shell to ZSH for user ($USER)? [Y/n]: " change_user_shell
        change_user_shell=${change_user_shell:-Y}
    fi
    if [[ "$change_user_shell" =~ ^[Yy]$ ]]; then
        chsh -s "$ZSH_PATH" "$USER"
        log_success "Changed default shell for user ($USER)!"
    fi

    if [ "${AUTO:-0}" = "1" ]; then
        change_root_shell="Y"
    else
        read -rp "Change default shell to ZSH for root (UID 0)? [Y/n]: " change_root_shell
        change_root_shell=${change_root_shell:-Y}
    fi
    if [[ "$change_root_shell" =~ ^[Yy]$ ]]; then
        chsh -s "$ZSH_PATH" root
        log_success "Changed default shell for root (UID 0)!"
    fi
fi  

log_success "Alright! You have now configured: ZSH and system basics!"
