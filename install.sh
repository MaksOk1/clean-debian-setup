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

detect_os() {
    if [ -f /etc/os-release ]; then
        OS_TYPE=$(grep -E '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
    elif [ -f /etc/debian_version ]; then
        OS_TYPE="debian"
    elif [ -f /etc/redhat-release ]; then
        OS_TYPE="rhel"
    elif command -v uname >/dev/null 2>&1; then
        case "$(uname -s)" in
            Darwin) OS_TYPE="macos" ;;
            *) OS_TYPE="unknown" ;;
        esac
    else
        OS_TYPE="unknown"
    fi
    OS_TYPE=$(echo "$OS_TYPE" | tr '[:upper:]' '[:lower:]')
    readonly OS_TYPE
}

if [ "$EUID" -eq 0 ]; then
    log_err "Please, run this script as a REGULAR USER (without sudo)."
    log_err "The script will automatically ask for root privileges when needed."
    exit 1
fi

IS_AUTO=0
if [ "${1:-}" = "-y" ] || [ "${AUTO:-0}" = "1" ]; then
    IS_AUTO=1
fi

detect_os

MISSING_DEPS=""
command -v make >/dev/null 2>&1 || MISSING_DEPS="build-essential"; fi
command -v git >/dev/null 2>&1 || MISSING_DEPS="${MISSING_DEPS:+$MISSING_DEPS }git"; fi

if [ -n "$MISSING_DEPS" ]; then
    log_warning "Required utilities are missing, but it is required to continue: ${MISSING_DEPS}."

    install_deps="Y"
    if [ "$IS_AUTO" = "0" ]; then
        read -rp "Do you want to install them now? [Y/n]: " install_deps
        install_deps=${install_deps:-Y}
    fi

    if [[ "$install_deps" =~ ^[Yy]$ ]]; then
        log_info "Installing dependencies (${MISSING_DEPS})..."

        case "$OS_TYPE" in
            ubuntu|debian|mint|pop)
                APT_CMD="apt-get update && apt-get install -y $MISSING_DEPS"
                ;;
            *)
                if command -v apt-get >/dev/null 2>&1; then
                    APT_CMD="apt-get update && apt-get install -y $MISSING_DEPS"
                else
                    die "Your OS ($OS_TYPE) is not fully supported yet. Please install manually: $MISSING_DEPS"
                fi
                ;;
        esac

        if command -v sudo >/dev/null 2>&1; then
            log_info "Authentication via 'sudo' required."
            sudo bash -c "$APT_CMD" || die "Failed to install packages via 'sudo'."
        elif command -v su >/dev/null 2>&1; then
            log_warning "'sudo' is missing. Using 'su'. Root password required!"
            su -c "$APT_CMD" || die "Failed to install packages via 'su'."
        else
            log_err "Neither 'sudo' nor 'su' were found to elevate privileges. Cannot install dependencies."
            log_warning "Failed to install packages. Please install missing ones manually ($MISSING_DEPS).\n"
            exit 1
        fi
        log_success "Dependencies successfully installed!"
    else
        log_err "Core utilities are not installed on your system!"
        log_err "Dependencies are required to run the installer. Stopping..."
        log_warning "Please install it first. On Debian/Ubuntu run:\n    sudo apt update && sudo apt install -y $MISSING_DEPS"
        exit 1
    fi
fi

export ORIGINAL_USER="${SUDO_USER:-$(logname 2>/dev/null || whoami)}"

if [ "$IS_AUTO" = "1" ]; then
    make run AUTO=1 ARGS="-y"
else
    make run AUTO=0 ARGS=""
fi