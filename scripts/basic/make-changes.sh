#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31mPlease, re-run script as root (sudo).\e[0m"
    exit 1
fi

USER=${1:-}
URL=${2:-}

if [ -z "$USER" ]; then
    # if [ "${AUTO:-0}" = "1" ]; then

    # else

    # fi
    while true; do
        read -rp "Make system changes for user (enter username): " USER

        if [ -n "$USER" ]; then
            break
        fi

        echo -e "\e[31mSet 'USER' variable to continue.\e[0m"
    done
fi

if [ -z "$URL" ]; then
    read -p "Enter base config URL (default: https://raw.githubusercontent.com/MaksOk1/clean-debian-setup/main): " URL
    URL=${URL:-https://raw.githubusercontent.com/MaksOk1/clean-debian-setup/main}
fi

OMZ_DIR="/usr/share/oh-my-zsh"

echo "Downloading configurations..."

download_file() {
    local src_url="$1"
    local dest_path="$2"
    if ! curl -sSf "$src_url" > "$dest_path"; then
        echo -e "\e[31mERROR: Failed to download $src_url\e[0m"
        return 1
    fi
}

mkdir -vp /etc/skel
download_file "$URL/rs/etc/skel/.zshrc" /etc/skel/.zshrc

if [ -n "$USER" ] && id "$USER" &>/dev/null; then
    USER_HOME=$(eval echo "~$USER")
    cp /etc/skel/.zshrc "$USER_HOME/.zshrc"
    chown "$USER:$USER" "$USER_HOME/.zshrc"
fi

mkdir -vp /etc/systemd/logind.conf.d/
download_file "$URL/rs/etc/systemd/logind.conf" /etc/systemd/logind.conf.d/custom.conf

mkdir -vp /etc/systemd/sleep.conf.d/
download_file "$URL/rs/etc/systemd/sleep.conf.d/nosuspend.conf" /etc/systemd/sleep.conf.d/nosuspend.conf

mkdir -vp /etc/ssh/sshd_config.d/
download_file "$URL/rs/etc/ssh/sshd_config.d/00-basic.conf" /etc/ssh/sshd_config.d/00-basic.conf

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
    if [ "${AUTO:-0}" = "1" ]; then
        grub_timeout=2
    else
        read -p "Enter GRUB timeout for system startup (default: 2): " grub_timeout
        grub_timeout=${grub_timeout:-2}
    fi

    if [[ "$grub_timeout" =~ ^[0-9]+$ ]]; then
        mkdir -vp /etc/default
        if [ -n "/etc/default/grub" ]; then
            touch /etc/default/grub
        fi
        
        if grep -q "^GRUB_TIMEOUT=" /etc/default/grub; then
            sed -i "s/GRUB_TIMEOUT=.*$/GRUB_TIMEOUT=$grub_timeout/" /etc/default/grub
        else
            echo "GRUB_TIMEOUT=$grub_timeout" >> /etc/default/grub
        fi

        echo "GRUB timeout successfully set to '$grub_timeout' seconds."

        if command -v update-grub &>/dev/null; then
            update-grub
        else
            grub-mkconfig -o /boot/grub/grub.cfg
        fi

        break
            echo "GRUB timeout successfully set to '$grub_timeout' seconds."
    else
        echo "ERROR: Please enter a valid number."
    fi
done

echo -e "\e[32mAll system configurations successfully applied!\e[0m"