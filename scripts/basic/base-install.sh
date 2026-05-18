#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31mPlease, run script as root (sudo).\e[0m"
    exit 1
fi

USER=${1:-}
PASSWD=${2:-}

if [ -z "$USER" ]; then
    read -p "Enter username: " USER
fi

apt install sudo apt-transport-https -y
echo -e "\e[<32>BASE-scope apps successfully installed!\e[0m"

echo "Adding new sudoer ($USER)"

if id "$USER" &>/dev/null; then
    echo "Choosed user ($USER) exists. Skipping adding user."
else
    echo "Choosed user ($USER) does not exist on system."
    read -p "Create user ($USER)? [Y/n]: " create_user
    create_user=${create_user:-Y}

    if [[ "$create_user" =~ ^[Yy]$ ]]; then
        useradd -m "$USER"
        echo "User ($USER) created successfully!"

        if [ -not -z "$PASSWD" ]; then
            echo "$USER:$PASSWD" | chpasswd
        fi
    else
        echo "User ($USER) creation skipped."
        exit 0
    fi
fi

read -p "Make user ($USER) an admin (sudoer)? [Y/n]: " make_admin
make_admin=${make_admin:-Y}

if [[ "$make_admin" =~ ^[Yy]$ ]]; then
    read -p "Enable NOPASSWD for sudoer ($USER)? [y/N]: " nopasswd_choice
    nopasswd_choice=${nopasswd_choice:-N}

    if [[ "$nopasswd_choice" =~ ^[Yy]$ ]]; then
        echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER
        echo -e "\e[<32>New sudoer added ($USER). 'NOPASSWD' access.\e[0m"
    else
        echo "$USER ALL=(ALL:ALL) ALL" > "/etc/sudoers.d/$USER"
        echo -e "\e[<32>New sudoer added ($USER). 'PASSWD' access.\e[0m"
    fi

    chmod 440 "/etc/sudoers.d/$USER"
else
    echo "Skipping sudoer configuration."
fi

