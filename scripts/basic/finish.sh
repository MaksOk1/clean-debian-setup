#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31mPlease, run script as root (sudo).\e[0m"
    exit 1
fi

USER=${1:-}

if [ -z "$USER" ]; then
    read -p "Finish system for user (enter username): " USER
fi

systemctl restart systemd-logind.service
systemctl restart ssh
systemctl restart sshd
cp /etc/zsh/zshrc /root/.zshrc
cp /etc/zsh/zshrc /home/$USER/.zshrc

#update-grub
update-grub2

chsh -s $(which zsh) root
chsh -s $(which zsh) $USER

echo "You can now reboot your machine!"
