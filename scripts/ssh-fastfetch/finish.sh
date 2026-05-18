#!/usr/bin/env bash
set -euo pipefail

sudo systemctl restart sshd
sudo systemctl restart ssh

echo "motd changed to fastfetch successfully"
