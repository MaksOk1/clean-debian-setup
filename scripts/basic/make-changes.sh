#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31mPlease, run script as root (sudo).\e[0m"
    exit 1
fi

USER=${1:-}
URL=${2:-}

if [ -z "$USER" ]; then
    while true; do
        read -rp "Make system changes for user (enter username): " USER

        if [ -n "$USER" ]; then
            break

        echo -e "\e[31mSet 'USER' variable to continue.\e[0m"
    done
fi

if [ -z "$URL" ]; then
    read -p "Enter base config URL (default: https://raw.github.com/MaksOk1/clean-debian-setup/main): " URL
    URL=${URL:-https://raw.github.com/MaksOk1/clean-debian-setup/main}
fi

OMZ_DIR="/usr/share/oh-my-zsh"

echo "Downloading configurations..."
curl -s "$URL/rs/etc/skel/.zshrc" > /etc/skel/.zshrc
curl -s "$URL/rs/etc/skel/.zshrc" >> /etc/zsh/zshrc
curl -s "$URL/rs/etc/systemd/logind.conf" >> /etc/systemd/logind.conf

mkdir -vp /etc/systemd/sleep.conf.d/
curl -s "$URL/rs/etc/systemd/sleep.conf.d/nosuspend.conf" > /etc/systemd/sleep.conf.d/nosuspend.conf

mkdir -vp /etc/ssh/sshd_config.d/
curl -s "$URL/rs/etc/ssh/sshd_config.d/00-basic.conf" > /etc/ssh/sshd_config.d/00-basic.conf

echo "Setting up Oh My Zsh..."
if [ -d "$OMZ_DIR/.git" ]; then
    echo "Oh My Zsh already exists. Pulling latest updates..."
    git -C "$OMZ_DIR" pull
else
    if [ -d "$OMZ_DIR" ]; then
        rm -rf "$OMZ_DIR"
    fi
    git clone https://github.com/ohmyzsh/ohmyzsh.git "$OMZ_DIR"
fi

echo "Updating GRUB timeout..."
while true; do
    read -p "Enter GRUB timeout for system startup (default: 2): " grub_timeout
    grub_timeout=${grub_timeout:-2}

    if [[ "$grub_timeout" =~ ^[0-9]+$ ]]; then
        mkdir -vp /etc/default/grub
        sed -i "s/GRUB_TIMEOUT=.*$/GRUB_TIMEOUT=$grub_timeout/" /etc/default/grub
        echo "GRUB timeout successfully set to '$grub_timeout' seconds."
        break
    else
        echo "ERROR: Please enter a valid number."
    fi
done

echo -e "\e[32mAll system configurations successfully applied!\e[0m"