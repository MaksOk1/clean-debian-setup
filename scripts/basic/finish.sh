#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31mPlease, run script as root (sudo).\e[0m"
    exit 1
fi

USER=${1:-}

if [ -z "$USER" ]; then
    while true; do
        read -rp "Finish system set-up for user (enter username): " USER

        if [ -n "$USER" ]; then
            break

        echo -e "\e[31mSet 'USER' variable to continue.\e[0m"
    done
fi

read -rp "Restart 'systemd-logind' service? [Y/n]: " restart_systemd_login_service
restart_systemd_login_service=${restart_systemd_login_service:-Y}
if [[ "$restart_systemd_login_service" =~ ^[Yy]$ ]]; then
    echo "Restarting 'systemd-logind' service..."
    systemctl restart systemd-logind.service
    echo -e "\e[31mRestarted service!\e[0m" # Need to make sure that it's correctly restarted. Maybe if pipe falls - echo will not be shown?
fi

read -rp "Restart 'ssh' and 'sshd' services? [Y/n]: " restart_ssh_services
restart_ssh_services=${restart_ssh_services:-Y}
if [[ "$restart_ssh_services" =~ ^[Yy]$ ]]; then
    systemctl restart ssh
    systemctl restart sshd
    echo -e "\e[31mRestarted services!\e[0m"
fi

echo "Copying '/etc/zsh/zshrc' to root's and user's ($USER's) home directories.."
cp /etc/zsh/zshrc /root/.zshrc
cp /etc/zsh/zshrc /home/$USER/.zshrc
echo -e "\e[31mCopied!\e[0m"

# update-grub
# update-grub2
if command -v update-grub &>/dev/null; then
    update-grub
else
    echo "WARNING: 'update-grub' utility not found, try confirming changes to grub with: 'sudo grub-mkconfig -o /boot/grub/grub.cfg' or 'sudo grub2-mkconfig -o /boot/grub2/grub.cfg' or 'sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg'"
    read -rp "Set-up custom shortcut for 'update-grub' (debian)? [y/N]: " set_debian_shortcut
    set_debian_shortcut=${set_debian_shortcut:-N}

    if [[ "$nopasswd_choice" =~ ^[Yy]$ ]]; then
        cat << 'EOF' > /usr/sbin/update-grub
#!/bin/sh
set -e
exec grub-mkconfig -o /boot/grub/grub.cfg "$@"
EOF
        chmod +x /usr/sbin/update-grub
    fi
fi

read -rp "Change default shell to ZSH for root and user ($USER)? [Y/n]: " change_both_shell
change_both_shell=${change_both_shell:-Y}
if [[ "$change_both_shell" =~ ^[Yy]$ ]]; then
    chsh -s $(which zsh) $USER
    chsh -s $(which zsh) root
    echo -e "\e[32mChanged default shell for root and user ($USER)!\e[0m"
else
    read -rp "Change default shell to ZSH for user ($USER)? [Y/n]: " change_user_shell
    change_user_shell=${change_user_shell:-Y}
    if [[ "$change_user_shell" =~ ^[Yy]$ ]]; then
        chsh -s $(which zsh) $USER
        echo -e "\e[32mChanged default shell for user ($USER)!\e[0m"
    fi

    read -rp "Change default shell to ZSH for root (UID 0)? [Y/n]: " change_root_shell
    change_root_shell=${change_root_shell:-Y}
    if [[ "$change_root_shell" =~ ^[Yy]$ ]]; then
        chsh -s $(which zsh) root
        echo -e "\e[32mChanged default shell for root (UID 0)!\e[0m"
    fi
fi  

echo -e "\e[32mAlright! You can now reboot your machine!\e[0m"
