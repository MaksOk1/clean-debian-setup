#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31mPlease, run script as root (sudo).\e[0m"
    exit 1
fi

USER=${1:-}
URL=${2:-}

if [ -z "$USER" ]; then
    read -p "Make system changes for user (enter username): " USER
fi

curl -s $URL/rs/etc/skel/.zshrc > /etc/skel/.zshrc
curl -s $URL/rs/etc/skel/.zshrc >> /etc/zsh/zshrc
curl -s $URL/rs/etc/systemd/logind.conf >> /etc/systemd/logind.conf
mkdir -vp /etc/systemd/sleep.conf.d/
curl -s $URL/rs/etc/systemd/sleep.conf.d/nosuspend.conf > /etc/systemd/sleep.conf.d/nosuspend.conf
curl -s $URL/rs/etc/ssh/sshd_config.d/00-basic.conf > /etc/ssh/sshd_config.d/00-basic.conf

git clone https://github.com/ohmyzsh/ohmyzsh.git /usr/share/oh-my-zsh

sed -i 's/GRUB_TIMEOUT=.*$/GRUB_TIMEOUT=2/' /etc/default/grub
