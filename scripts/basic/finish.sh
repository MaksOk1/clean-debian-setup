#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31mPlease, re-run script as root (sudo).\e[0m"
    exit 1
fi

USER=${1:-}

if [ -z "$USER" ]; then
    while true; do
        read -rp "Finish system set-up for user (enter username): " USER

        if [ -n "$USER" ]; then
            break
        fi

        echo -e "\e[31mSet 'USER' variable to continue.\e[0m"
    done
fi

read -rp "Restart 'systemd-logind' service? [y/N]: " restart_systemd_login_service
restart_systemd_login_service=${restart_systemd_login_service:-N}
if [[ "$restart_systemd_login_service" =~ ^[Yy]$ ]]; then
    echo "Restarting 'systemd-logind' service..."
    systemctl restart systemd-logind.service

    if systemctl is-active --quiet systemd-logind.service; then
        echo -e "\e[32mRestarted service successfully!\e[0m" # Need to make sure that it's correctly restarted. Maybe if pipe falls - echo will not be shown?
    else
        echo -e "\e[31mWarning: systemd-logind is not running properly!\e[0m"
    fi
fi

read -rp "Restart 'ssh' and 'sshd' services? [Y/n]: " restart_ssh_services
restart_ssh_services=${restart_ssh_services:-Y}
if [[ "$restart_ssh_services" =~ ^[Yy]$ ]]; then
    for service in ssh sshd; do
        if systemctl list-unit-files | grep -q "^${service}.service"; then
            systemctl restart "$service"
            echo "Service '$service' restarted."
        fi
    done
    echo -e "\e[32mSSH services restarted!\e[0m"
fi

echo "Copying '/etc/zsh/zshrc' to root's and user's ($USER's) home directories.."
if [ -f /etc/zsh/zshrc ]; then
    mkdir -vp /root /home/"$USER"
    cp /etc/zsh/zshrc /root/.zshrc
    cp /etc/zsh/zshrc /home/$USER/.zshrc
    chown "$USER":"$USER" /home/"$USER"/.zshrc
    echo -e "\e[32mCopied!\e[0m"
else
    echo -e "\e[33mWarning: /etc/zsh/zshrc not found. Skipping copy.\e[0m"
fi

# update-grub
# update-grub2
if command -v update-grub &>/dev/null; then
    update-grub
else
    echo "WARNING: 'update-grub' utility not found, try confirming changes to grub with: 'sudo grub-mkconfig -o /boot/grub/grub.cfg' or 'sudo grub2-mkconfig -o /boot/grub2/grub.cfg' or 'sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg'"
    read -rp "Set-up custom shortcut for 'update-grub' (debian)? [y/N]: " set_debian_shortcut
    set_debian_shortcut=${set_debian_shortcut:-N}

    if [[ "$set_debian_shortcut" =~ ^[Yy]$ ]]; then
        cat << 'EOF' > /usr/sbin/update-grub
#!/bin/sh
set -e
exec grub-mkconfig -o /boot/grub/grub.cfg "$@"
EOF
        chmod +x /usr/sbin/update-grub
        echo -e "\e[32mShortcut /usr/sbin/update-grub created (and 'chmod +x ...' executed)!\e[0m"
    fi
fi

read -rp "Change default shell to ZSH for root and user ($USER)? [Y/n]: " change_both_shell
change_both_shell=${change_both_shell:-Y}

ZSH_PATH=$(command -v zsh || echo "/usr/bin/zsh") # or /bin/zsh

if [[ "$change_both_shell" =~ ^[Yy]$ ]]; then
    chsh -s "$ZSH_PATH" "$USER"
    chsh -s "$ZSH_PATH" root
    echo -e "\e[32mChanged default shell for root and user ($USER)!\e[0m"
else
    read -rp "Change default shell to ZSH for user ($USER)? [Y/n]: " change_user_shell
    change_user_shell=${change_user_shell:-Y}
    if [[ "$change_user_shell" =~ ^[Yy]$ ]]; then
        chsh -s "$ZSH_PATH" "$USER"
        echo -e "\e[32mChanged default shell for user ($USER)!\e[0m"
    fi

    read -rp "Change default shell to ZSH for root (UID 0)? [Y/n]: " change_root_shell
    change_root_shell=${change_root_shell:-Y}
    if [[ "$change_root_shell" =~ ^[Yy]$ ]]; then
        chsh -s "$ZSH_PATH" root
        echo -e "\e[32mChanged default shell for root (UID 0)!\e[0m"
    fi
fi  

echo -e "\e[32mAlright! You have now configured: ZSH and system basics!\e[0m"
