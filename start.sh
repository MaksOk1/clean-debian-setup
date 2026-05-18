#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31mPlease, re-run script as root (sudo).\e[0m"
    exit 1
fi

USER=${1:-}
PASSWD=${2:-}

if [ -z "$USER" ]; then
    while true; do
        read -rp "Enter username of user you want to configure (enter username): " USER

        if [ -n "$USER" ]; then
            break
		fi

        echo -e "\e[31mSet 'USER' variable to continue.\e[0m"
    done
fi

if id "$USER" &>/dev/null && [ -z "$PASSWD" ]; then
	read -rsp "Set password for user (press ENTER to skip): " PASSWD
	echo ""
fi

URL='https://raw.github.com/MaksOk1/clean-debian-setup/main'

# FEATURES rename !
FOLDER_BASIC='./scripts/basic'
FOLDER_FASTFETCH='./scripts/ssh-fastfetch'


# Base installation of packages and oh-my-zsh configuration
$(which bash) "$FOLDER_BASIC/base-install.sh" "$USER" "$PASSWD"
$(which bash) "$FOLDER_BASIC/full-install.sh"
$(which bash) "$FOLDER_BASIC/make-changes.sh" "$USER" "$URL"
$(which bash) "$FOLDER_BASIC/finish.sh" "$USER"

# Fastfetch set-up as motd message on login (ssh)
$(which bash) "$FOLDER_FASTFETCH/install.sh"
$(which bash) "$FOLDER_FASTFETCH/make-changes.sh" "$URL"
$(which bash) "$FOLDER_FASTFETCH/finish.sh"
