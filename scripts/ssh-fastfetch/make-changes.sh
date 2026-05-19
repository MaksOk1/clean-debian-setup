#!/usr/bin/env zsh
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31mPlease, re-run script as root (sudo).\e[0m"
    exit 1
fi

URL=${1:-}

if [ -z "$URL" ]; then
    if [ "${AUTO:-0}" = "1" ]; then
    echo -e "\e[31mSelected automatically: https://raw.github.com/MaksOk1/clean-debian-setup/main\e[0m"
        URL="https://raw.github.com/MaksOk1/clean-debian-setup/main"
    else
        read -p "Enter base config URL (default: https://raw.github.com/MaksOk1/clean-debian-setup/main): " URL
        URL=${URL:-https://raw.github.com/MaksOk1/clean-debian-setup/main}
    fi
fi


# Fetching needed data for script
curl -sSf "$URL/rs/etc/skel/.zshrc" > /etc/skel/.zshrc

# Clearing /etc/motd and /etc/issue
if [ -f /etc/issue ]; then
    mv /etc/issue /etc/issue__$(date +"%F_%H-%M-%S").bak
else    
    echo "" > /etc/issue
    if [ -f /etc/motd ]; then
        mv /etc/motd /etc/motd__$(date +"%F_%H-%M-%S").bak
    fi
    echo "" > /etc/motd
fi

mkdir -vp /etc/zsh
if [ -f /etc/zsh/zshrc ]; then
    mv /etc/zsh/zshrc /etc/zsh/zshrc__$(date +"%F_%H-%M-%S").bak
fi
if [ -f /etc/zsh/zshenv ]; then
    mv /etc/zsh/zshenv /etc/zsh/zshenv__$(date +"%F_%H-%M-%S").bak
fi
