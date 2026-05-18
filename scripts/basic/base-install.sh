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
        read -rp "Set-up system for user (enter username): " USER

        if [ -n "$USER" ]; then
            break
        fi

        echo -e "\e[31mSet 'USER' variable to continue.\e[0m"
    done
fi

apt install sudo apt-transport-https -y
echo -e "\e[32mBASE-scope apps (packages) successfully installed on system!\e[0m"

echo "Checking user ($USER) status..."

if id "$USER" &>/dev/null; then
    echo "Choosed user ($USER) exists. Skipping adding user."
else
    echo "Choosed user ($USER) does not exist on system."
    read -p "Create user ($USER)? [Y/n]: " create_user
    create_user=${create_user:-Y}

    if [[ "$create_user" =~ ^[Yy]$ ]]; then
        useradd -m "$USER"
        echo "User ($USER) created successfully!"

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
                        echo -e "\e[31mPasswords do not match. Try again.\e[0m"
                    fi
                done
            fi

            echo "$USER:$PASSWD" | chpasswd
            echo "Password for user ($USER) set successfully!"
        fi
    else
        echo "User ($USER) creation skipped."
        exit 0
    fi
fi

if [ -f "/etc/sudoers.d/$USER" ] || id -nG "$USER" | grep -qw "sudo"; then
    echo "User ($USER) is already an admin."
    read -p "Do you want to change sudo access type (passwd/nopasswd)? [y/N]: " change_admin
    make_admin=${change_admin:-N}
else
    read -p "Make user ($USER) admin (sudoer)? [Y/n]: " make_admin
    make_admin=${make_admin:-Y}
fi

if [[ "$make_admin" =~ ^[Yy]$ ]]; then
    read -p "Enable NOPASSWD for sudoer ($USER)? [y/N]: " nopasswd_choice
    nopasswd_choice=${nopasswd_choice:-N}

    if [[ "$nopasswd_choice" =~ ^[Yy]$ ]]; then
        echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" > "/etc/sudoers.d/$USER"
        echo -e "\e[32mSudoer configured ($USER). 'NOPASSWD' access mode.\e[0m"
    else
        echo "$USER ALL=(ALL:ALL) ALL" > "/etc/sudoers.d/$USER"
        echo -e "\e[32mSudoer configured ($USER). 'PASSWD' access mode.\e[0m"
    fi

    chmod 440 "/etc/sudoers.d/$USER"
else
    echo "Skipping sudoer configuration."
fi

