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

# systemctl restart sshd
# systemctl restart ssh
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

log_success "MOTD changed to fastfetch successfully"
log_success "OK! You have now configured: MOTD changed to fastfetch, SSH login message changed!"
