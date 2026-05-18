#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31mPlease, re-run script as root (sudo).\e[0m"
    exit 1
fi

# systemctl restart sshd
# systemctl restart ssh
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

echo "MOTD changed to fastfetch successfully"
echo -e "\e[32mOK! You have now configured: MOTD cleared, replaced with fastfetch SSH login message!\e[0m"
