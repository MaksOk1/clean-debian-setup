#!/usr/bin/env zsh
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

URL=${1:-}

if [ -z "$URL" ]; then
    if [ "${AUTO:-0}" = "1" ]; then
    log_info "\e[31mSelected automatically: https://raw.github.com/MaksOk1/clean-debian-setup/main\e[0m"
        URL="https://raw.github.com/MaksOk1/clean-debian-setup/main"
    else
        read -p "Enter base config URL (default: https://raw.github.com/MaksOk1/clean-debian-setup/main): " URL
        URL=${URL:-https://raw.github.com/MaksOk1/clean-debian-setup/main}
    fi
fi


# Fetching needed data for script
log_info "Downloading '/etc/skel/.zshrc' from remote.."
curl -sSf "$URL/rs/etc/skel/.zshrc" > /etc/skel/.zshrc

# Clearing /etc/motd and /etc/issue
log_info "Clearing '/etc/issue' and '/etc/motd' (if exists, with backup creation).."
if [ -f /etc/issue ]; then
    log_warning "'/etc/issue' exists, moving to format '/etc/issue__*date*.bak"
    mv /etc/issue /etc/issue__$(date +"%F_%H-%M-%S").bak
else
    log_info "'/etc/issue' not exists, creating.."
    echo "" > /etc/issue && log_info "'/etc/issue' is created" || log_warning "Clearing failed"
    if [ -f /etc/motd ]; then
        log_warning "'/etc/motd' exists, moving to format '/etc/motd__*date*.bak"
        mv /etc/motd /etc/motd__$(date +"%F_%H-%M-%S").bak
    fi
    echo "" > /etc/motd && log_info "'/etc/motd' is created" || log_warning "Clearing failed"
fi

log_info "Creating '/etc/zsh' foulder if not exists.."
mkdir -vp /etc/zsh

log_info "ZSH config: backing-up the current '/etc/zsh/zshrc' and '/etc/zsh/zshenv"
if [ -f /etc/zsh/zshrc ]; then
    mv /etc/zsh/zshrc /etc/zsh/zshrc__$(date +"%F_%H-%M-%S").bak && log_info "'/etc/zsh/zshrc' is backed-up successfully." || log_warning "Backup failed"
fi
if [ -f /etc/zsh/zshenv ]; then
    mv /etc/zsh/zshenv /etc/zsh/zshenv__$(date +"%F_%H-%M-%S").bak && log_info "'/etc/zsh/zshenv' is backed-up successfully." || log_warning "Backup failed"
fi

log_success "SSH Fastfetch made changes to system!"