#!/usr/bin/env bash
set -euo pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_err()     { echo -e "${RED}[ERROR]${NC} $1" >&2; }
die()         { log_err "$1"; exit 1; }

[ "$EUID" -ne 0 ] && die "Please, re-run script as root (sudo)."

detect_os() {
    if [ -f /etc/os-release ]; then
        OS_TYPE=$(grep -E '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
    
    elif [ -f /etc/debian_version ]; then
        OS_TYPE="debian"
    elif [ -f /etc/redhat-release ]; then
        OS_TYPE="rhel"
    
    elif command -v uname >/dev/null 2>&1; then
        local uname_s
        uname_s=$(uname -s)
        case "$uname_s" in
            Darwin) OS_TYPE="macos" ;;
            FreeBSD) OS_TYPE="freebsd" ;;
            *) OS_TYPE="unknown" ;;
        esac
    else
        OS_TYPE="unknown"
    fi

    OS_TYPE=$(echo "$OS_TYPE" | tr '[:upper:]' '[:lower:]')
    
    readonly OS_TYPE
}

read_secure_password() {
    local prompt_msg=$1
    while true; do
        read -rsp "$prompt_msg" pass1
        echo ""
        read -rsp "Retype password to confirm: " pass2
        echo ""
        if [ "$pass1" = "$pass2" ]; then
            echo "$pass1"
            return 0
        fi
        log_err "Passwords do not match. Try again."
    done
}

detect_os
export AUTO="${AUTO:-0}"

USER="${1:-${ORIGINAL_USER:-${SUDO_USER:-root}}}"
PASSWD=${2:-}

if [ -z "$USER" ] || [ "$USER" = "root" ]; then
    USER="${SUDO_USER:-root}"
fi

MODE_TEXT="${CYAN}INTERACTIVE${NC}"
[ "$AUTO" = "1" ] && MODE_TEXT="${MAGENTA}AUTOMATIC${NC}"

log_info "Detected 'USER' - ($USER)."
log_info "Mode selected - ($MODE_TEXT)."

if [ -n "$USER" ] && [ "$AUTO" = "0" ]; then
    read -rp "[?] Continue for user ($USER)? [Y/n] (or choose other username): " continue_script
	if [[ ! "${continue_script:-Y}" =~ ^[Yy]$ ]]; then
		USER=""
	fi
fi

if [ -z "$USER" ]; then
	DEFAULT_USER=${SUDO_USER:-root}
    if [ "$AUTO" = "1" ]; then
		USER=$DEFAULT_USER
    else
        while true; do
            read -rp "[?] Enter username of user you want to configure [default: $DEFAULT_USER]: " INPUT_USER
            USER=${INPUT_USER:-$DEFAULT_USER}
            [ -n "$USER" ] && break
            log_err "Please enter a valid username (or set 'USER' variable) to continue."
        done
    fi
fi

if id "$USER" &>/dev/null; then
	log_info "Chosen user ($USER) exists. Skipping user creation."

    change_pwd="N"
    if [ "$AUTO" = "0" ]; then
        prompt_txt="Do you want to change password for existing user ($USER)? [y/N]: "
        [ -n "$PASSWD" ] && prompt_txt="Password given as argument. Change password for existing user ($USER) to it? [y/N]: "    
        read -rp "[?] $prompt_txt" change_pwd
        change_pwd=${change_pwd:-N}
    elif [ "$AUTO" = "1" ] && [ -n "$PASSWD" ]; then
        change_pwd="Y"
    fi

    if [[ "$change_pwd" =~ ^[Yy]$ ]]; then
        if [ -z "$PASSWD" ]; then
            [ "$AUTO" = "1" ] && die "Password change requested in AUTO mode but no password provided."
            PASSWD=$(read_secure_password "[!] Enter NEW password for user ($USER): ")
		fi
        echo "$USER:$PASSWD" | chpasswd || passwd "$USER"
        log_success "Password for user ($USER) updated successfully!"
	else
        PASSWD=""
        log_info "Password change skipped."
	fi
else
	log_warning "Chosen user ($USER) does not exist on the system."
    create_user="Y"
    [ "$AUTO" = "0" ] && read -rp "[?] Create user ($USER)? [Y/n]: " create_user

    if [[ "${create_user:-Y}" =~ ^[Yy]$ ]]; then
        useradd -m -s /bin/bash "$USER"
        log_success "User ($USER) created successfully!"

        set_password="Y"
        [ "$AUTO" = "0" ] && [ -z "$PASSWD" ] && read -rp "[?] Set password for user ($USER)? [Y/n]: " set_password

        if [[ "${set_password:-Y}" =~ ^[Yy]$ ]]; then
            if [ -n "$PASSWD" ] && [ "$AUTO" = "0" ]; then
                read -rp "[?] Password was given as argument. Use it for new user? [Y/n]: " use_arg_password
                [[ ! "${use_arg_password:-Y}" =~ ^[Yy]$ ]] && PASSWD=""
            fi

            if [ -z "$PASSWD" ]; then
                [ "$AUTO" = "1" ] && die "Error: Cannot set empty password for new user in AUTO mode."
                PASSWD=$(read_secure_password "Enter password for new user ($USER): ")
            fi

            if echo "$USER:$PASSWD" | chpasswd; then
                log_success "Password for user ($USER) set successfully!"
            else
                log_err "'chpasswd' failed. Trying fallback to interactive passwd. Enter password for user ($USER)..."
                passwd "$USER"
            fi
        fi
    else
        log_warning "User ($USER) creation skipped. Stopping script."
        exit 0
    fi
fi

URL='https://raw.githubusercontent.com/MaksOk1/clean-debian-setup/main'
# FEATURES rename !
FOLDER_BASE="$(pwd)/scripts"
BASH_PATH=$(which bash || command -v bash || echo "/usr/bin/bash") # or '/bin/bash'

FOLDER_BASIC="$FOLDER_BASE/basic"
FOLDER_FASTFETCH="$FOLDER_BASE/ssh-fastfetch"

# Automatically set 'chmod +x'
log_info "Making set-up scripts executable..."
chmod -R +x "$FOLDER_BASE/"

log_info "Executing features..."

# Base installation of packages and oh-my-zsh configuration
log_info "Set-up of: Basic system feature"
"$BASH_PATH" "$FOLDER_BASIC/base-install.sh" "$USER" "$PASSWD"
"$BASH_PATH" "$FOLDER_BASIC/full-install.sh" "$URL"
"$BASH_PATH" "$FOLDER_BASIC/make-changes.sh" "$USER" "$URL"
"$BASH_PATH" "$FOLDER_BASIC/finish.sh" "$USER"
log_success "Setted-up: Basic system feature!"

# Fastfetch set-up as motd message on login (ssh)
log_info "Set-up of: Fastfetch feature"
"$BASH_PATH" "$FOLDER_FASTFETCH/install.sh"
"$BASH_PATH" "$FOLDER_FASTFETCH/make-changes.sh" "$URL"
"$BASH_PATH" "$FOLDER_FASTFETCH/finish.sh"
log_success "Setted-up: Fastfetch feature!"

log_success "All features setted up!"

# Clean-up
log_info "Cleaning up..."
"$BASH_PATH" "$FOLDER_BASE/cleanup.sh"
log_success "Clean-up completed!"

log_warning "Now it is recommended to reboot the machine!"
log_success "All done!"