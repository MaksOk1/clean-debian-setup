#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31mPlease, run script as root (sudo).\e[0m"
    exit 1
fi

USER=${1:-}
PASSWD=${2:-}

if [ -z "$USER" ]; then
	echo 'WARNING: $1 is empty (USER variable).'
    read -p "Enter username: " USER
fi

URL='https://raw.github.com/MaksOk1/clean-debian-setup/main'

# FEATURES rename !
FOLDER_BASIC='./scripts/basic'
FOLDER_FASTFETCH='./scripts/ssh-fastfetch'


# Base installation of packages and oh-my-zsh configuration
$(which bash) "$FOLDER_BASIC/base-install.sh" $USER $PASSWD
$(which bash) "$FOLDER_BASIC/full-install.sh"
$(which bash) "$FOLDER_BASIC/make-changes.sh" $USER $URL
$(which bash) "$FOLDER_BASIC/finish.sh" $USER

# Fastfetch set-up as motd message on login (ssh)
$(which bash) "$FOLDER_FASTFETCH/install.sh"
$(which bash) "$FOLDER_FASTFETCH/make-changes.sh" $URL
$(which bash) "$FOLDER_FASTFETCH/finish.sh"
