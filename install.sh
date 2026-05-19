#!/usr/bin/env bash
set -euo pipefail

IS_AUTO=0
if [ "${1:-}" = "-y" ]; then
    IS_AUTO=1
fi

if [ "$EUID" -eq 0 ]; then
    echo -e "\e[31m[ERROR]: Please, run this script as a REGULAR USER (without sudo).\e[0m"
    echo -e "\e[31mThe script will automatically ask for root privileges when needed.\e[0m"
    exit 1
fi

MISSING_DEPS=""
if ! command -v make >/dev/null 2>&1; then MISSING_DEPS="build-essential"; fi
if ! command -v git >/dev/null 2>&1; then MISSING_DEPS="${MISSING_DEPS} git"; fi

if [ -n "$MISSING_DEPS" ]; then
    echo -e "\e[33m[WARNING]: Required utilities are missing, but it is required to continue: ${MISSING_DEPS}.\e[0m"

    if [ "$IS_AUTO" = "1" ]; then
        install_make="Y"
    else
        read -rp "Do you want to install them now? [Y/n]: " install_deps
        install_deps=${install_deps:-Y}
    fi

    if [[ "$install_deps" =~ ^[Yy]$ ]]; then
        echo -e "\e[32mInstalling dependencies (${MISSING_DEPS})... Authentication required.\e[0m"
        if sudo apt-get update && sudo apt-get install -y $MISSING_DEPS; then
            echo -e "\e[32mDependencies successfully installed!\e[0m"
        else
            echo -e "\e[31m[ERROR]: Failed to install packages. Please install missing ones manually ($MISSING_DEPS).\e[0m\n"
            exit 1
        fi
    else
        echo -e "\e[31m[ERROR]: Core utilities are not installed on your system.\e[0m"
        echo -e "\e[33m    Please install it first. On Debian/Ubuntu run:\e[0m"
        echo -e "\e[33m        sudo apt update && sudo apt install -y $MISSING_DEPS\e[0m"
        echo -e "\e[31m[ERROR]: Dependencies are required to run the installer. Stopping.\e[0m"
        exit 1
    fi
fi

if [ "$IS_AUTO" = "1" ]; then
    # make run AUTO=1
    make run ARGS="-y"
else
    make run
fi