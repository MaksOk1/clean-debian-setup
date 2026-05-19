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

if ! command -v make >/dev/null 2>&1; then
    echo -e "\e[33m[WARNING]: 'make' utility is missing, but it is required to continue.\e[0m"

    if [ "$IS_AUTO" = "1" ]; then
        install_make="Y"
    else
        read -rp "Do you want to install 'build-essential' (includes 'make') now? [Y/n]: " install_make
        install_make=${install_make:-Y}
    fi

    if [[ "$install_make" =~ ^[Yy]$ ]]; then
        echo -e "\e[32mInstalling build-essential... Authentication required.\e[0m"
        # Використовуємо класичний sudo, бо Polkit (pkexec) на чистих серверах зазвичай немає
        if sudo apt-get update && sudo apt-get install -y build-essential; then
            echo -e "\e[32m'make' successfully installed!\e[0m"
        else
            echo -e "\e[31m[ERROR]: Failed to install packages. Please install 'make' manually.\e[0m\n"
            exit 1
        fi
    else
        echo -e "\e[31m[ERROR]: 'make' utility is not installed on your system.\e[0m"
        echo -e "\e[31m[ERROR]: 'make' is required to run the installer. Stopping.\e[0m"
        echo -e "\e[33m    Please install it first. On Debian/Ubuntu run:\e[0m"
        echo -e "\e[33m        sudo apt update && sudo apt install -y build-essential\e[0m"
        exit 1
    fi
fi

if ! command -v git >/dev/null 2>&1; then
    echo -e "\e[33m[WARNING]: 'git' utility is missing, but it is required to continue.\e[0m"

    if [ "$IS_AUTO" = "1" ]; then
        install_git="Y"
    else
        read -rp "Do you want to install 'git' now? [Y/n]: " install_git
        install_git=${install_git:-Y}
    fi

    if [[ "$install_git" =~ ^[Yy]$ ]]; then
        echo -e "\e[32mInstalling git... Authentication required.\e[0m"
        if sudo apt-get update && sudo apt-get install -y git; then
            echo -e "\e[32m'git' successfully installed!\e[0m"
        else
            echo -e "\e[31m[ERROR]: Failed to install packages. Please install 'git' manually.\e[0m\n"
            exit 1
        fi
    else
        echo -e "\e[31m[ERROR]: 'git' utility is not installed on your system.\e[0m"
        echo -e "\e[31m[ERROR]: 'git' is required to run the installer. Stopping.\e[0m"
        echo -e "\e[33m    Please install it first. On Debian/Ubuntu run:\e[0m"
        echo -e "\e[33m        sudo apt update && sudo apt install -y git\e[0m"
        exit 1
    fi
fi

if [ "$IS_AUTO" = "1" ]; then
    # make run AUTO=1
    make run ARGS="-y"
else
    make run
fi