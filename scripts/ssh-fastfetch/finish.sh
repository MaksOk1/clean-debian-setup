#!/usr/bin/bash

sudo systemctl restart sshd
sudo systemctl restart ssh

echo "motd changed to fastfetch successfully"
