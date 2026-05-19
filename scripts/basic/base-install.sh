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
PASSWD=${2:-}

if [ -z "$USER" ]; then
    while true; do
        read -rp "Set-up system for user (enter username): " USER

        if [ -n "$USER" ]; then
            break
        fi

        log_warning "Set 'USER' variable to continue."
    done
fi

# make prebasic feature apt list
apt install sudo apt-transport-https -y
log_success "BASE-scope apps (packages) successfully installed on system!"

log_info "Checking user ($USER) status..."

if id "$USER" &>/dev/null; then
    log_info "Choosed user ($USER) exists. Skipping adding user."
else
    log_info "Choosed user ($USER) does not exist on system."
    read -p "Create user ($USER)? [Y/n]: " create_user
    create_user=${create_user:-Y}

    if [[ "$create_user" =~ ^[Yy]$ ]]; then
        useradd -m "$USER"
        log_success "User ($USER) created successfully!"

        read -p "Set password for user ($USER)? [Y/n]: " set_password
        set_password=${set_password:-Y}

        if [[ "$set_password" =~ ^[Yy]$ ]]; then
            if [ -n "$PASSWD" ]; then
                read -p "Password was given as argument. Use it? [Y/n]: " use_arg_password
                use_arg_password=${use_arg_password:-Y}

                if [[ ! "$use_arg_password" =~ ^[Yy]$ ]]; then
                    PASSWD=""
                fi
            fi

            if [ -z "$PASSWD" ]; then
                while true; do
                    read -s -p "Enter new password for user ($USER): " PASSWD
                    echo ""
                    read -s -p "Retype new password: " PASSWD_CONFIRM
                    echo ""

                    if [ "$PASSWD" = "$PASSWD_CONFIRM" ]; then
                        break
                    else
                        log_warning "\e[31mPasswords do not match. Try again.\e[0m"
                    fi
                done
            fi

            echo "$USER:$PASSWD" | chpasswd
            log_success "Password for user ($USER) set successfully!"
        fi
    else
        log_info "User ($USER) creation skipped."
        exit 0
    fi
fi

if [ -f "/etc/sudoers.d/$USER" ] || id -nG "$USER" | grep -qw "sudo"; then
    log_info "User ($USER) is already an admin."
    if [ "$AUTO" = "1" ]; then
        make_admin="N"
    else
        read -p "Do you want to change sudo access type (passwd/nopasswd)? [y/N]: " change_admin
        make_admin=${change_admin:-N}
    fi
else
    if [ "$AUTO" = "1" ]; then
        make_admin="Y"
    else
        read -p "Make user ($USER) admin (sudoer)? [Y/n]: " make_admin
        make_admin=${make_admin:-Y}
    fi
fi

if [[ "$make_admin" =~ ^[Yy]$ ]]; then
    if [ "$AUTO" = "1" ]; then
        nopasswd_choice="N"
    else
        read -p "Enable NOPASSWD for sudoer ($USER)? [y/N]: " nopasswd_choice
        nopasswd_choice=${nopasswd_choice:-N}
    fi

    if [[ "$nopasswd_choice" =~ ^[Yy]$ ]]; then
        echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" > "/etc/sudoers.d/$USER"
        log_success "Sudoer configured ($USER). 'NOPASSWD' access mode."
    else
        echo "$USER ALL=(ALL:ALL) ALL" > "/etc/sudoers.d/$USER"
        log_success "Sudoer configured ($USER). 'PASSWD' access mode."
    fi

    chmod 440 "/etc/sudoers.d/$USER"
    log_success "File mode for sudoer file '440' setted!"
else
    log_info "Skipping sudoer configuration."
fi

