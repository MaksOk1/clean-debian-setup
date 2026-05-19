#!/usr/bin/env bash
set -euo pipefail

readonly SEP="--------------------------------------------------"
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log_info() { echo -e "${YELLOW}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_err() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
die() { log_err "$1"; exit 1; }

if [ "$EUID" -ne 0 ]; then
    log_err "Please, re-run script as root (sudo)."
    exit 1
fi

URL=${1:-}

if [ -z "$URL" ]; then
    read -rp "Enter base config URL (default: https://raw.githubusercontent.com/MaksOk1/clean-debian-setup/main): " URL
    URL=${URL:-https://raw.githubusercontent.com/MaksOk1/clean-debian-setup/main}
fi

log_info "Fetching package list..."

pkg_array=()

mapfile -t pkg_array < <(
    curl -sSfL --connect-timeout 10 "$URL/rs/apt/basic.list" | 
    sed -e 's/\r//g' -e '/^#/d' -e '/^$/d'
) || die "Failed to download or parse package list."

if [ ${#pkg_array[@]} -eq 0 ] || [ -z "${pkg_array[0]}" ]; then
    die "Package list is empty, invalid, or contains only comments/empty lines."
fi

log_info "Updating apt package index..."
apt update -y

log_info "Installing apps: ${pkg_array[*]}"
apt install "${pkg_array[@]}" -y

log_success "FULL-scope apps successfully installed!"
