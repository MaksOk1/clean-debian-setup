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
    echo "Choosed user ($USER) not exists on system. Create?"
    
    useradd -m $USER

    if [ $? -eq 0]; then
        echo "User ($USER) created successfully!"
    else
        echo "User ($USER) creation failed."
        exit 1
    fi
fi

echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER
echo -e "\e[<32>New sudoer added (NOPASSWD)\e[0m"

