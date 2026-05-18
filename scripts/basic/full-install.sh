#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31mPlease, run script as root (sudo).\e[0m"
    exit 1
fi

apt install sudo net-tools ca-certificates openssh-server vim zsh git curl wget 7zip zip python3 nginx-full htop python3-pip python3-venv -y

echo -e "\e[32mFULL-scope apps successfully installed!\e[0m"
