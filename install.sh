#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -eq 0 ]; then
    echo -e "\e[31m[ERROR]: Please, run this script as a REGULAR USER (without sudo).\e[0m"
    echo -e "\e[31mThe script will automatically ask for root privileges when needed.\e[0m"
    exit 1
fi

if ! command -v make >/dev/null 2>&1; then
    echo -e "\e[31m[ERROR]: 'make' utility is not installed on your system.\e[0m"
    echo -e "\e[33mPlease install it first. On Debian/Ubuntu run:\e[0m"
    echo -e "    sudo apt update && sudo apt install -y build-essential\e[0m"
    exit 1
fi

if [ "${1:-}" = "-y" ]; then
    # make run AUTO=1
    make run ARGS="-y"
else
    make run
fi